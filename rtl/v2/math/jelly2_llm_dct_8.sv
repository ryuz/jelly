
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
        return calc_t'((mul_t'(a) * mul_t'(b)) >>> DATA_Q);
    endfunction

    

    // stage0
    logic           st0_0_valid;
    logic   [2:0]   st0_0_addr;

    logic           st0_1_valid;
    logic   [2:0]   st0_1_addr;

    logic           st0_2_valid;
    logic   [2:0]   st0_2_addr;
    calc_t          st0_2_data0;
    calc_t          st0_2_data1;

    logic           st0_3_valid;
    logic   [2:0]   st0_3_addr;
    calc_t          st0_3_data;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_0_valid <= 1'b0;
            st0_0_addr  <= 'x;
            st0_1_valid <= 1'b0;
            st0_2_valid <= 1'b0;
            st0_2_data0 <= 'x;
            st0_2_data1 <= 'x;
            st0_3_valid <= 1'b0;
            st0_3_data  <= 'x;
        end
        else if ( cke ) begin
            // stage0-0
            if ( !st0_0_valid || st0_0_addr == 3'd4 ) begin
                st0_0_valid <= start;
                st0_0_addr  <= '0;
            end
            else begin
                st0_0_addr <= ~st0_0_addr + {2'b00, st0_0_addr[2]};
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
            st0_3_addr   <= st0_2_addr;
            st0_3_data   <= st0_2_addr[2] == 1'b0 ? st0_2_data0 + in_rdata : st0_2_data1 - st0_2_data0;
        end
    end
    
    assign in_re   = st0_0_valid;
    assign in_addr = st0_0_addr;
   
    // buffer
    logic                       st0_wr_bank;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_wr_bank <= 1'b0;
        end
        else if ( cke ) begin
            if ( st0_3_valid && st0_3_addr == 3'd4 ) begin
                st0_wr_bank <= st0_wr_bank + 1'b1;
            end
        end
    end

    logic                       st0_rd_en;
    logic   [3:0]               st0_rd_addr;
    logic   [DATA_WIDTH-1:0]    st0_rd_dout;

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
                .wr_en          (st0_3_valid), // dont' care cke
                .wr_addr        ({st0_wr_bank, st0_3_addr}),
                .wr_din         (st0_3_data),
                
                .rd_clk         (clk),
                .rd_en          (cke),
                .rd_regcke      (1'b0),
                .rd_addr        (),
                .rd_dout        ()
            );


endmodule


`default_nettype wire


// end of file
