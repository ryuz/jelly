
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2023 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// サイズ8のDCT メモリ to メモリ で計算
module jelly2_llm_dct_8
        #(
            parameter   int     DATA_WIDTH = 18,
            parameter   int     DATA_Q     = 12
        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            input   var logic                       cke,

            input   var logic                       start,
            output  var logic                       ready,
            output  var logic                       done,

            output  var logic                       in_re,
            output  var logic   [2:0]               in_addr,
            input   var logic   [DATA_WIDTH-1:0]    in_rdata,

            output  var logic                       out_we,
            output  var logic   [2:0]               out_addr,
            output  var logic   [DATA_WIDTH-1:0]    out_wdata
        );

    typedef logic   signed  [DATA_WIDTH-1:0]    calc_t;
    typedef logic   signed  [DATA_WIDTH*2-1:0]  mul_t;

    function    calc_t mul(input calc_t a, input calc_t b);
        return calc_t'((mul_t'(a) * mul_t'(b) + (mul_t'(1) << (DATA_Q - 1))) >>> DATA_Q);
    endfunction


    // 1 / sqrt(2)
    calc_t  RSQRT2;
    assign RSQRT2 = calc_t'(int'(1.0 / $sqrt(2.0) * (1 << DATA_Q)));

    // 0.5 / sqrt(2)
    calc_t  RSQRT2H;
    assign RSQRT2H = calc_t'(int'(0.5 / $sqrt(2.0) * (1 << DATA_Q)));

    // cos(pi * i/16) * sqrt(2)
    calc_t  R   [0:7];
    localparam  real    PI = 3.14159265358979323846;
    assign  R[0] = calc_t'(int'($cos(PI * 0 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[1] = calc_t'(int'($cos(PI * 1 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[2] = calc_t'(int'($cos(PI * 2 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[3] = calc_t'(int'($cos(PI * 3 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[4] = calc_t'(int'($cos(PI * 4 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[5] = calc_t'(int'($cos(PI * 5 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[6] = calc_t'(int'($cos(PI * 6 / 16) * $sqrt(2.0) * (1 << DATA_Q)));
    assign  R[7] = calc_t'(int'($cos(PI * 7 / 16) * $sqrt(2.0) * (1 << DATA_Q)));

    
    
    // -----------------------------------------
    //  stage0
    // -----------------------------------------

    // buffer
    logic                       st0_wr_en;
    logic   [2:0]               st0_wr_addr;
    logic   [DATA_WIDTH-1:0]    st0_wr_din;

    logic                       st0_rd_en;
    logic   [2:0]               st0_rd_addr;
    logic   [DATA_WIDTH-1:0]    st0_rd_dout;

    logic                       st0_wr_last;
    logic                       st0_wr_bank;
    logic                       st0_rd_bank;

    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH     (4),
                .DATA_WIDTH     (DATA_WIDTH),
                .MEM_SIZE       (16),
                .RAM_TYPE       ("distributed"),
                .DOUT_REGS      (0)
            )
        u_ram_simple_dualport_0
            (
                .wr_clk         (clk),
                .wr_en          (st0_wr_en), // dont' care cke
                .wr_addr        ({st0_wr_bank, st0_wr_addr}),
                .wr_din         (st0_wr_din),
                
                .rd_clk         (clk),
                .rd_en          (cke),
                .rd_regcke      (1'b0),
                .rd_addr        ({st0_rd_bank, st0_rd_addr}),
                .rd_dout        (st0_rd_dout)
            );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_wr_bank <= 1'b0;
            st0_rd_bank <= 1'b0;
        end
        else if ( cke ) begin
            if ( st0_wr_en && st0_wr_last ) begin
                st0_rd_bank <= st0_wr_bank;
                st0_wr_bank <= st0_wr_bank + 1'b1;
            end
        end
    end


    // pipeline
    logic           st0_0_valid;
    logic           st0_0_last;
    logic   [2:0]   st0_0_addr;

    logic           st0_1_valid;
    logic   [2:0]   st0_1_addr;

    logic           st0_2_valid;
    logic   [2:0]   st0_2_addr;
    calc_t          st0_2_data0;
    calc_t          st0_2_data1;

    logic           st0_3_valid;
    logic           st0_3_last;
    logic   [2:0]   st0_3_addr;
    calc_t          st0_3_data;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_0_valid <= 1'b0;
            st0_0_last  <= 1'b0;
            st0_0_addr  <= 'x;
            st0_1_valid <= 1'b0;
            st0_1_addr  <= 'x;
            st0_2_valid <= 1'b0;
            st0_2_data0 <= 'x;
            st0_2_data1 <= 'x;
            st0_3_valid <= 1'b0;
            st0_3_last  <= 'x;
            st0_3_data  <= 'x;
        end
        else if ( cke ) begin
            // stage0-0
            if ( ready ) begin
                st0_0_valid <= start;
                st0_0_last  <= 1'b0;
                st0_0_addr  <= 3'd0;
            end
            else begin
                st0_0_last <= (st0_0_addr == 3'd3);
                case (st0_0_addr)
                3'd0: st0_0_addr <= 3'd7;
                3'd7: st0_0_addr <= 3'd1;
                3'd1: st0_0_addr <= 3'd6;
                3'd6: st0_0_addr <= 3'd2;
                3'd2: st0_0_addr <= 3'd5;
                3'd5: st0_0_addr <= 3'd3;
                3'd3: st0_0_addr <= 3'd4;
                3'd4: st0_0_addr <= 3'd0;
                endcase
            end

            // stage0-1
            st0_1_valid  <= st0_0_valid;
            st0_1_addr   <= st0_0_addr;

            // stage0-2
            st0_2_valid  <= st0_1_valid;
            st0_2_addr   <= st0_1_addr;
            st0_2_data0  <= in_rdata;
            st0_2_data1  <= st0_2_data0;

            // stage0-3
            st0_3_valid  <= st0_2_valid;
            st0_3_last   <= st0_2_addr == 3'd4;
            st0_3_addr   <= st0_2_addr;
            st0_3_data   <= st0_2_addr[2] == 1'b0 ? st0_2_data0 + in_rdata : st0_2_data1 - st0_2_data0;
        end
    end
    
    assign ready = !st0_0_valid || st0_0_last;

    assign in_re   = st0_0_valid;
    assign in_addr = st0_0_addr;

    assign st0_wr_last = st0_3_last;
    assign st0_wr_en   = st0_3_valid;
    assign st0_wr_addr = st0_3_addr;
    assign st0_wr_din  = st0_3_data;
    


    // -----------------------------------------
    //  stage1
    // -----------------------------------------

    // buffer
    logic                       st1_wr_en;
    logic   [2:0]               st1_wr_addr;
    logic   [DATA_WIDTH-1:0]    st1_wr_din;

    logic                       st1_rd_en;
    logic   [2:0]               st1_rd_addr;
    logic   [DATA_WIDTH-1:0]    st1_rd_dout;

    logic                       st1_wr_last;
    logic                       st1_wr_bank;
    logic                       st1_rd_bank;

    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH     (4),
                .DATA_WIDTH     (DATA_WIDTH),
                .MEM_SIZE       (16),
                .RAM_TYPE       ("distributed"),
                .DOUT_REGS      (0)
            )
        u_ram_simple_dualport_1
            (
                .wr_clk         (clk),
                .wr_en          (st1_wr_en), // dont' care cke
                .wr_addr        ({st1_wr_bank, st1_wr_addr}),
                .wr_din         (st1_wr_din),
                
                .rd_clk         (clk),
                .rd_en          (cke),
                .rd_regcke      (1'b0),
                .rd_addr        ({st1_rd_bank, st1_rd_addr}),
                .rd_dout        (st1_rd_dout)
            );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_wr_bank <= 1'b0;
            st1_rd_bank <= 1'b0;
        end
        else if ( cke ) begin
            if ( st1_wr_en && st1_wr_last ) begin
                st1_rd_bank <= st1_wr_bank;
                st1_wr_bank <= st1_wr_bank + 1'b1;
            end
        end
    end


    // pipeline
    logic           st1_0_valid;
    logic   [2:0]   st1_0_addr;

    logic           st1_1_valid;
    logic   [2:0]   st1_1_addr;

    logic           st1_2_valid;
    logic   [2:0]   st1_2_addr;
    calc_t          st1_2_data0;
    calc_t          st1_2_data1;

    logic           st1_3_valid;
    logic           st1_3_last;
    logic   [2:0]   st1_3_addr;
    calc_t          st1_3_data;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_0_valid <= 1'b0;
            st1_0_addr  <= 'x;
            st1_1_valid <= 1'b0;
            st1_1_addr  <= 'x;
            st1_2_valid <= 1'b0;
            st1_2_data0 <= 'x;
            st1_2_data1 <= 'x;
            st1_3_valid <= 1'b0;
            st1_3_last  <= 'x;
            st1_3_data  <= 'x;
        end
        else if ( cke ) begin
            // stage1-0
            if ( st0_wr_en && st0_wr_last ) begin
                st1_0_valid <= 1'b1;
                st1_0_addr  <= '0;
            end
            else if ( st1_0_valid ) begin
                st1_0_valid <= (st1_0_addr != 3'd7);
                case (st1_0_addr)
                3'd0: st1_0_addr <= 3'd3;
                3'd3: st1_0_addr <= 3'd1;
                3'd1: st1_0_addr <= 3'd2;
                3'd2: st1_0_addr <= 3'd4;
                3'd4: st1_0_addr <= 3'd5;
                3'd5: st1_0_addr <= 3'd6;
                3'd6: st1_0_addr <= 3'd7;
                3'd7: st1_0_addr <= 3'd0;
                endcase
            end
            
            // stage1-1
            st1_1_valid  <= st1_0_valid;
            st1_1_addr   <= st1_0_addr;

            // stage1-2
            st1_2_valid  <= st1_1_valid;
            st1_2_addr   <= st1_1_addr;
            st1_2_data0  <= st0_rd_dout;
            st1_2_data1  <= st1_2_data0;

            // stage1-3
            st1_3_valid  <= st1_2_valid;
            st1_3_last   <= st1_2_addr == 3'd7;
            st1_3_addr   <= st1_2_addr;
            if ( st1_2_addr[2] == 1'b0 ) begin
                st1_3_data <= st1_2_addr[1] == 1'b0 ? st1_2_data0 + st0_rd_dout : st1_2_data1 - st1_2_data0;
            end
            else begin
                st1_3_data <= st1_2_data0;
            end
        end
    end
    
    assign st0_rd_en   = st1_0_valid;
    assign st0_rd_addr = st1_0_addr;

    assign st1_wr_en   = st1_3_valid;
    assign st1_wr_last = st1_3_last;
    assign st1_wr_addr = st1_3_addr;
    assign st1_wr_din  = st1_3_data;



    // -----------------------------------------
    //  stage2
    // -----------------------------------------

    // buffer
    logic                       st2_wr_en;
    logic   [2:0]               st2_wr_addr;
    logic   [DATA_WIDTH-1:0]    st2_wr_din;

    logic                       st2_rd_en;
    logic   [2:0]               st2_rd_addr;
    logic   [DATA_WIDTH-1:0]    st2_rd_dout;

    logic                       st2_wr_last;
    logic                       st2_wr_bank;
    logic                       st2_rd_bank;

    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH     (4),
                .DATA_WIDTH     (DATA_WIDTH),
                .MEM_SIZE       (16),
                .RAM_TYPE       ("distributed"),
                .DOUT_REGS      (0)
            )
        u_ram_simple_dualport_2
            (
                .wr_clk         (clk),
                .wr_en          (st2_wr_en), // dont' care cke
                .wr_addr        ({st2_wr_bank, st2_wr_addr}),
                .wr_din         (st2_wr_din),
                
                .rd_clk         (clk),
                .rd_en          (cke),
                .rd_regcke      (1'b0),
                .rd_addr        ({st2_rd_bank, st2_rd_addr}),
                .rd_dout        (st2_rd_dout)
            );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_wr_bank <= 1'b0;
            st2_rd_bank <= 1'b0;
        end
        else if ( cke ) begin
            if ( st2_wr_en && st2_wr_last ) begin
                st2_rd_bank <= st2_wr_bank;
                st2_wr_bank <= st2_wr_bank + 1'b1;
            end
        end
    end

    
    // pipeline
    logic           st2_0_valid;
    logic   [2:0]   st2_0_addr;

    logic           st2_1_valid;
    logic   [2:0]   st2_1_addr;

    logic           st2_2_valid;
    logic   [2:0]   st2_2_addr;
    calc_t          st2_2_data;

    logic           st2_3_valid;
    logic   [2:0]   st2_3_addr;
    calc_t          st2_3_data0;
    calc_t          st2_3_data1;
    calc_t          st2_3_r0;
    calc_t          st2_3_r1;

    logic           st2_4_valid;
    logic   [2:0]   st2_4_addr;
    calc_t          st2_4_data0;
    calc_t          st2_4_data1;
    calc_t          st2_4_r0;
    calc_t          st2_4_r1;

    logic           st2_5_valid;
    logic   [2:0]   st2_5_addr;
    calc_t          st2_5_data0;
    calc_t          st2_5_data1;

    logic           st2_6_valid;
    logic           st2_6_last;
    logic   [2:0]   st2_6_addr;
    calc_t          st2_6_data;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st2_0_valid <= 1'b0;
            st2_0_addr  <= 'x;
            st2_1_valid <= 1'b0;
            st2_1_addr  <= 'x;
            st2_2_valid <= 1'b0;
            st2_2_data  <= 'x;
            st2_3_valid <= 1'b0;
            st2_3_data0 <= 'x;
            st2_3_data1 <= 'x;
            st2_3_r0    <= 'x;
            st2_3_r1    <= 'x;
            st2_4_valid <= 1'b0;
            st2_4_addr  <= 'x;
            st2_4_data0 <= 'x;
            st2_4_data1 <= 'x;
            st2_4_r0    <= 'x;
            st2_4_r1    <= 'x;
            st2_5_valid <= 1'b0;
            st2_5_addr  <= 'x;
            st2_5_data0 <= 'x;
            st2_5_data1 <= 'x;
            st2_6_valid <= 1'b0;
            st2_6_last  <= 'x;
            st2_6_addr  <= 'x;
            st2_6_data  <= 'x;
        end
        else if ( cke ) begin
            // stage2-0
            if ( st1_wr_en && st1_wr_last ) begin
                st2_0_valid <= 1'b1;
                st2_0_addr  <= 3'd1;
            end
            else if ( st2_0_valid ) begin
                st2_0_valid <= (st2_0_addr != 3'd6);
                case (st2_0_addr)
                3'd1: st2_0_addr <= 3'd0;
                3'd0: st2_0_addr <= 3'd2;
                3'd2: st2_0_addr <= 3'd3;
                3'd3: st2_0_addr <= 3'd7;
                3'd7: st2_0_addr <= 3'd4;
                3'd4: st2_0_addr <= 3'd5;
                3'd5: st2_0_addr <= 3'd6;
                3'd6: st2_0_addr <= 3'd1;
                endcase
            end
            
            // stage2-1
            st2_1_valid  <= st2_0_valid;
            st2_1_addr   <= st2_0_addr;
            case (st2_0_addr)
            3'd1: st2_1_addr <= 3'd0;
            3'd0: st2_1_addr <= 3'd1;
            3'd2: st2_1_addr <= 3'd2;
            3'd3: st2_1_addr <= 3'd3;
            3'd7: st2_1_addr <= 3'd4;
            3'd4: st2_1_addr <= 3'd7;
            3'd5: st2_1_addr <= 3'd6;
            3'd6: st2_1_addr <= 3'd5;
            endcase

            // stage2-2
            st2_2_valid  <= st2_1_valid;
            st2_2_addr   <= st2_1_addr;
            st2_2_data   <= st1_rd_dout;

            // stage2-3
            st2_3_valid  <= st2_2_valid;
            st2_3_addr   <= st2_2_addr;
            if ( st2_2_addr[0] == 1'b0 ) begin
                st2_3_data0 <= st2_2_data;
                st2_3_data1 <= st1_rd_dout;
            end
            else begin
                st2_3_data0 <= st2_3_data1;
                st2_3_data1 <= st2_3_data0;
            end
            case ( st2_2_addr )
            3'd0: begin st2_3_r0 <= R[4]; st2_3_r1 <= R[4]; end
            3'd1: begin st2_3_r0 <= R[4]; st2_3_r1 <= R[4]; end
            3'd2: begin st2_3_r0 <= R[6]; st2_3_r1 <= R[2]; end
            3'd3: begin st2_3_r0 <= R[6]; st2_3_r1 <= R[2]; end
            3'd4: begin st2_3_r0 <= R[3]; st2_3_r1 <= -R[5]; end
            3'd7: begin st2_3_r0 <= R[3]; st2_3_r1 <= -R[5]; end
            3'd6: begin st2_3_r0 <= R[1]; st2_3_r1 <= R[7]; end
            3'd5: begin st2_3_r0 <= R[1]; st2_3_r1 <= R[7]; end
            endcase

            // stage2-4
            st2_4_valid  <= st2_3_valid;
            st2_4_addr   <= st2_3_addr;
            st2_4_data0  <= st2_3_data0;
            st2_4_data1  <= st2_3_data1;
            st2_4_r0     <= st2_3_r0;
            st2_4_r1     <= st2_3_r1;

            // stage2-5
            st2_5_valid  <= st2_4_valid;
            st2_5_addr   <= st2_4_addr;
            st2_5_data0  <= mul(st2_4_data0, st2_4_r0);
            st2_5_data1  <= mul(st2_4_data1, st2_4_r1);

            // stage2-6
            st2_6_valid  <= st2_5_valid;
            st2_6_last   <= st2_5_addr == 3'd5;
            st2_6_addr   <= st2_5_addr;
            st2_6_data   <= st2_5_addr[0] == 1'b0 ? st2_5_data0 + st2_5_data1 : st2_5_data0 - st2_5_data1;
        end
    end
    

    assign st1_rd_en   = st2_0_valid;
    assign st1_rd_addr = st2_0_addr;

    assign st2_wr_en   = st2_6_valid;
    assign st2_wr_last = st2_6_last;
    assign st2_wr_addr = st2_6_addr;
    assign st2_wr_din  = st2_6_data;



    // -----------------------------------------
    //  stage3
    // -----------------------------------------

    // pipeline
    logic           st3_0_valid;
    logic   [2:0]   st3_0_addr;

    logic           st3_1_valid;
    logic   [2:0]   st3_1_addr;

    logic           st3_2_valid;
    logic   [2:0]   st3_2_addr;
    calc_t          st3_2_data;

    logic           st3_3_valid;
    logic   [2:0]   st3_3_addr;
    calc_t          st3_3_data;
    calc_t          st3_3_data0;
    calc_t          st3_3_data1;

    logic           st3_4_valid;
    logic   [2:0]   st3_4_addr;
    calc_t          st3_4_data;
    calc_t          st3_4_data0;
    calc_t          st3_4_data1;

    logic           st3_5_valid;
    logic   [2:0]   st3_5_addr;
    calc_t          st3_5_data;
    calc_t          st3_5_add;
    calc_t          st3_5_sub;

    logic           st3_6_valid;
    logic   [2:0]   st3_6_addr;
    calc_t          st3_6_data;
    calc_t          st3_6_mul;
    calc_t          st3_6_sub0;
    calc_t          st3_6_sub1;
 
    logic           st3_7_valid;
    logic   [2:0]   st3_7_addr;
    calc_t          st3_7_data;
    calc_t          st3_7_mul0;
    calc_t          st3_7_mul1;

    logic           st3_8_valid;
    logic   [2:0]   st3_8_addr;
    calc_t          st3_8_data;
    calc_t          st3_8_data0;
    calc_t          st3_8_data1;

    logic           st3_9_valid;
    logic   [2:0]   st3_9_addr;
    calc_t          st3_9_data;

    logic           st3_10_valid;
    logic   [2:0]   st3_10_addr;
    calc_t          st3_10_data;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st3_0_valid  <= 1'b0;
            st3_0_addr   <= 'x;
            st3_1_valid  <= 1'b0;
            st3_1_addr   <= 'x;
            st3_2_valid  <= 1'b0;
            st3_2_data   <= 'x;
            st3_3_valid  <= 1'b0;
            st3_3_data   <= 'x;
            st3_3_data0  <= 'x;
            st3_3_data1  <= 'x;
            st3_4_valid  <= 1'b0;
            st3_4_addr   <= 'x;
            st3_4_data   <= 'x;
            st3_4_data0  <= 'x;
            st3_4_data1  <= 'x;
            st3_5_valid  <= 1'b0;
            st3_5_addr   <= 'x;
            st3_5_data   <= 'x;
            st3_5_add    <= 'x;
            st3_5_sub    <= 'x;
            st3_6_valid  <= 1'b0;
            st3_6_addr   <= 'x;
            st3_6_data   <= 'x;
            st3_6_mul    <= 'x;
            st3_6_sub0   <= 'x;
            st3_6_sub1   <= 'x;
            st3_7_valid  <= 1'b0;
            st3_7_addr   <= 'x;
            st3_7_data   <= 'x;
            st3_7_mul0   <= 'x;
            st3_7_mul1   <= 'x;
            st3_8_valid  <= 1'b0;
            st3_8_addr   <= 'x;
            st3_8_data   <= 'x;
            st3_8_data0  <= 'x;
            st3_8_data1  <= 'x;
            st3_9_valid  <= 1'b0;
            st3_9_addr   <= 'x;
            st3_9_data   <= 'x;
            st3_10_valid <= 1'b0;
            st3_10_addr  <= 'x;
            st3_10_data  <= 'x;
        end
        else if ( cke ) begin
            // stage3-0
            if ( st2_wr_en && st2_wr_last ) begin
                st3_0_valid <= 1'b1;
                st3_0_addr  <= 3'd0;
            end
            else if ( st3_0_valid ) begin
                st3_0_valid <= (st3_0_addr != 3'd6);
                case (st3_0_addr)
                3'd0: st3_0_addr <= 3'd1;
                3'd1: st3_0_addr <= 3'd2;
                3'd2: st3_0_addr <= 3'd3;
                3'd3: st3_0_addr <= 3'd7;
                3'd7: st3_0_addr <= 3'd5;
                3'd5: st3_0_addr <= 3'd4;
                3'd4: st3_0_addr <= 3'd6;
                3'd6: st3_0_addr <= 3'd0;
                endcase
            end
            
            // stage3-1
            st3_1_valid <= st3_0_valid;
            st3_1_addr  <= st3_0_addr;
            case (st3_0_addr)
            3'd0: st3_1_addr <= 3'd0;
            3'd1: st3_1_addr <= 3'd4;
            3'd2: st3_1_addr <= 3'd2;
            3'd3: st3_1_addr <= 3'd6;
            3'd7: st3_1_addr <= 3'd5;
            3'd5: st3_1_addr <= 3'd3;
            3'd4: st3_1_addr <= 3'd1;
            3'd6: st3_1_addr <= 3'd7;
            endcase

            // stage3-2
            st3_2_valid  <= st3_1_valid;
            st3_2_addr   <= st3_1_addr;
            st3_2_data   <= st2_rd_dout;

            // stage3-3
            st3_3_valid  <= st3_2_valid;
            st3_3_addr   <= st3_2_addr;
            st3_3_data   <= st3_2_data;
            if ( st3_2_addr == 3'd5 || st3_2_addr == 3'd1 ) begin
                st3_3_data0 <= st3_2_data;
                st3_3_data1 <= st2_rd_dout;
            end

            // stage3-4
            st3_4_valid  <= st3_3_valid;
            st3_4_addr   <= st3_3_addr;
            st3_4_data   <= st3_3_data;
            st3_4_data0  <= st3_3_data0;
            st3_4_data1  <= st3_3_data1;

            // stage3-5
            st3_5_valid  <= st3_4_valid;
            st3_5_addr   <= st3_4_addr;
            st3_5_data   <= st3_4_data;
            st3_5_add    <= st3_4_data0 + st3_4_data1;
            st3_5_sub    <= st3_4_data0 - st3_4_data1;

            // stage3-6
            st3_6_valid  <= st3_5_valid;
            st3_6_addr   <= st3_5_addr;
            st3_6_data   <= st3_5_data;
            st3_6_mul    <= mul(st3_5_add, RSQRT2);
            if ( st3_5_addr == 3'd5 ) st3_6_sub0 <= st3_5_sub;
            if ( st3_5_addr == 3'd1 ) st3_6_sub1 <= st3_5_sub;

            // stage3-7
            st3_7_valid  <= st3_6_valid;
            st3_7_addr   <= st3_6_addr;
            st3_7_data   <= st3_6_data;
            if ( st3_6_addr == 3'd5 ) st3_7_mul0 <= st3_6_mul;
            if ( st3_6_addr == 3'd1 ) st3_7_mul1 <= st3_6_mul;

            // stage3-8
            st3_8_valid  <= st3_7_valid;
            st3_8_addr   <= st3_7_addr;
            case ( st3_7_addr )
            3'd0: st3_8_data <= st3_7_data;
            3'd4: st3_8_data <= st3_7_data;
            3'd2: st3_8_data <= st3_7_data;
            3'd6: st3_8_data <= st3_7_data;
            3'd5: st3_8_data <= st3_6_sub0;
            3'd3: st3_8_data <= st3_6_sub1;
            3'd1: st3_8_data <= st3_7_mul1 + st3_7_mul0;
            3'd7: st3_8_data <= st3_7_mul1 - st3_7_mul0;
            endcase

            // stage3-9
            st3_9_valid <= st3_8_valid;
            st3_9_addr  <= st3_8_addr;
            st3_9_data  <= st3_8_data;

            // stage3-10
            st3_10_valid <= st3_9_valid;
            st3_10_addr  <= st3_9_addr;
            st3_10_data  <= mul(st3_9_data, RSQRT2H);
        end
    end

    assign st2_rd_en   = st3_0_valid;
    assign st2_rd_addr = st3_0_addr;

    assign out_we    = st3_10_valid;
    assign out_addr  = st3_10_addr;
    assign out_wdata = st3_10_data;

    assign done = st3_10_valid && st3_10_addr == 3'd7;

endmodule


`default_nettype wire


// end of file
