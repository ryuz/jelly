
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// サイズ8x8 の DCT メモリ to メモリ で計算
module jelly2_llm_dct_8x8
        #(
            parameter   int     DATA_WIDTH = 18,
            parameter   int     DATA_Q     = 12,
            parameter           RAM_TYPE   = "distributed"
        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            input   var logic                       cke,

            input   var logic                       start,
            output  var logic                       ready,
            output  var logic                       done,

            output  var logic                       in_re,
            output  var logic   [2:0]               in_addrx,
            output  var logic   [2:0]               in_addry,
            input   var logic   [DATA_WIDTH-1:0]    in_rdata,

            output  var logic                       out_we,
            output  var logic   [2:0]               out_addrx,
            output  var logic   [2:0]               out_addry,
            output  var logic   [DATA_WIDTH-1:0]    out_wdata
        );

    // -----------------------------------------
    //  buffer
    // -----------------------------------------

    logic                       wr_en;
    logic   [5:0]               wr_addr;
    logic   [DATA_WIDTH-1:0]    wr_din;

    logic                       rd_en;
    logic   [5:0]               rd_addr;
    logic   [DATA_WIDTH-1:0]    rd_dout;
    
    logic                       wr_last;
    logic                       wr_bank;
    logic                       rd_bank;

    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH     (7                  ),
                .DATA_WIDTH     (DATA_WIDTH         ),
                .MEM_SIZE       (2*8*8              ),
                .RAM_TYPE       (RAM_TYPE           ),
                .DOUT_REGS      (0                  )
            )
        u_ram_simple_dualport
            (
                .wr_clk         (clk                ),
                .wr_en          (wr_en              ), // dont' care cke
                .wr_addr        ({wr_bank, wr_addr} ),
                .wr_din         (wr_din             ),
                
                .rd_clk         (clk                ),
                .rd_en          (cke                ),
                .rd_regcke      (1'b0               ),
                .rd_addr        ({rd_bank, rd_addr} ),
                .rd_dout        (rd_dout            )
            );
    
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            wr_bank <= 1'b0;
            rd_bank <= 1'b0;
        end
        else if ( cke ) begin
            if ( wr_en && wr_last ) begin
                rd_bank <= wr_bank;
                wr_bank <= wr_bank + 1'b1;
            end
        end
    end
    

    // -----------------------------------------
    //  Horizontal DCT
    // -----------------------------------------

    logic                       h_start;
    logic                       h_ready;
    logic                       h_done;

    logic                       h_in_re;
    logic   [2:0]               h_in_addrx;
    logic   [2:0]               h_in_addry;
    logic   [DATA_WIDTH-1:0]    h_in_rdata;

    logic                       h_out_we;
    logic   [2:0]               h_out_addrx;
    logic   [2:0]               h_out_addry;
    logic   [DATA_WIDTH-1:0]    h_out_wdata;

    jelly2_llm_dct_8
            #(
                .DATA_WIDTH     (DATA_WIDTH ),
                .DATA_Q         (DATA_Q     )
            )
        u_llm_dct_8_h
            (
                .reset,
                .clk,
                .cke,

                .start          (h_start    ),
                .ready          (h_ready    ),
                .done           (h_done     ),
                
                .in_re          (h_in_re    ),
                .in_addr        (h_in_addrx ),
                .in_rdata       (h_in_rdata),
                
                .out_we         (h_out_we   ),
                .out_addr       (h_out_addrx),
                .out_wdata      (h_out_wdata)
            );
    
    assign in_re      = h_in_re;
    assign in_addrx   = h_in_addrx;
    assign in_addry   = h_in_addry;
    assign h_in_rdata = in_rdata;
   

    // input
    logic   h_busy;
    logic   h_in_last;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            h_busy      <= 1'b0;
            h_in_addry  <= 'x;
        end
        else if ( cke ) begin
            if ( ready ) begin
                h_busy     <= start;
                h_in_last  <= 1'b0;
                h_in_addry <= '0;
            end
            else if ( h_busy ) begin
                if ( h_ready ) begin
                    if ( h_in_last ) begin
                        h_busy     <= 1'b0;
                        h_in_last  <= 1'bx;
                        h_in_addry <= 'x;
                    end
                    else begin
                        h_busy     <= 1'b1;
                        h_in_last  <= (h_in_addry == 3'd6);
                        h_in_addry <= h_in_addry + 3'd1;
                    end
                end
            end
        end
    end

    assign ready   = !h_busy || (h_in_last && h_ready);
    assign h_start = (h_busy && !h_in_last) || start;

    // output
    logic   h_out_last;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            h_out_last  <= 1'b0;
            h_out_addry <= '0;
        end
        else if ( cke ) begin
            if ( h_done ) begin
                h_out_last  <= (h_out_addry == 3'd6);
                h_out_addry <= h_out_addry + 3'd1;
            end
        end
    end

    assign wr_en    = h_out_we;
    assign wr_last  = h_done && h_out_last;
    assign wr_addr  = {h_out_addry, h_out_addrx};
    assign wr_din   = h_out_wdata;



    // -----------------------------------------
    //  Vertical DCT
    // -----------------------------------------

    logic                       v_start;
    logic                       v_ready;
    logic                       v_done;

    logic                       v_in_re;
    logic   [2:0]               v_in_addrx;
    logic   [2:0]               v_in_addry;
    logic   [DATA_WIDTH-1:0]    v_in_rdata;

    logic                       v_out_we;
    logic   [2:0]               v_out_addrx;
    logic   [2:0]               v_out_addry;
    logic   [DATA_WIDTH-1:0]    v_out_wdata;

    jelly2_llm_dct_8
            #(
                .DATA_WIDTH     (DATA_WIDTH ),
                .DATA_Q         (DATA_Q     )
            )
        u_llm_dct_8_v
            (
                .reset,
                .clk,
                .cke,

                .start          (v_start    ),
                .ready          (v_ready    ),
                .done           (v_done     ),
                
                .in_re          (v_in_re    ),
                .in_addr        (v_in_addry ),
                .in_rdata       (v_in_rdata),
                
                .out_we         (v_out_we   ),
                .out_addr       (v_out_addry),
                .out_wdata      (v_out_wdata)
            );

    // input
    logic   v_busy;
    logic   v_in_last;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            v_busy      <= 1'b0;
            v_in_addrx  <= 'x;
        end
        else if ( cke ) begin
            if (  h_done && h_out_last ) begin
                v_busy     <= 1'b1;
                v_in_last  <= 1'b0;
                v_in_addrx <= '0;
            end
            else if ( v_busy ) begin
                if ( v_ready ) begin
                    if ( v_in_last ) begin
                        v_busy     <= 1'b0;
                        v_in_last  <= 1'bx;
                        v_in_addrx <= 'x;
                    end
                    else begin
                        v_busy     <= 1'b1;
                        v_in_last  <= (v_in_addrx == 3'd6);
                        v_in_addrx <= v_in_addrx + 3'd1;
                    end
                end
            end
        end
    end

    assign v_start = (v_busy && !v_in_last) || (h_done && h_out_last);

    assign rd_en      = v_in_re;
    assign rd_addr    = {v_in_addry, v_in_addrx};
    assign v_in_rdata = rd_dout;


    // output
    logic   v_out_last;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            v_out_last  <= 1'b0;
            v_out_addrx <= '0;
        end
        else if ( cke ) begin
            if ( v_done ) begin
                v_out_last  <= (v_out_addrx ==  3'd6);
                v_out_addrx <= v_out_addrx + 3'd1;
            end
        end
    end

    assign done      = v_done && v_out_last;

    assign out_we    = v_out_we;
    assign out_addrx = v_out_addrx;
    assign out_addry = v_out_addry;
    assign out_wdata = v_out_wdata;

endmodule


`default_nettype wire


// end of file
