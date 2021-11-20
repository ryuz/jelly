

`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        #(
            parameter int   WB_ADR_WIDTH = 16,
            parameter int   WB_DAT_WIDTH = 32,
            parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8
        )
        (
            input   wire                        reset,
            input   wire                        clk,

            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );

    logic       cke = 1'b1;
    logic       irq;
    
    jelly_rtos
            #(
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH)
            )
        i_rtos
            (
                .*
            );

endmodule


//`default_nettype wire


// end of file
