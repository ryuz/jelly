// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none



module tb_main
        #(
            parameter   int WB_ADR_WIDTH = 16,
            parameter   int WB_DAT_WIDTH = 32,
            parameter   int WB_SEL_WIDTH = WB_DAT_WIDTH / 8
        )
        (
            input   wire                        reset,
            input   wire                        clk,

            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_we_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );
    
    int     cycle = 0;
    always_ff @(posedge clk) begin
        cycle <= cycle + 1;
    end

    logic   [WB_DAT_WIDTH-1:0]      counter;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= '0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

    assign s_wb_dat_o = counter;
    assign s_wb_ack_o = s_wb_stb_i;

endmodule


`default_nettype wire


// end of file
