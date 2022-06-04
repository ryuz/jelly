

`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   int     WB_ADR_WIDTH = 27,
            parameter   int     WB_DAT_WIDTH = 32,
            parameter   int     WB_SEL_WIDTH = WB_DAT_WIDTH / 8
        )
        (
            input   wire                        reset,
            input   wire                        clk,

            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  reg     [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_we_i,
            input   wire                        s_wb_stb_i,
            output  reg                         s_wb_ack_o
        );

    logic   [7:0]   pmod;
    
    kv260_stepper_motor_rpu
        i_top
            (
                .pmod       (pmod)
            );
    
    always_comb force i_top.i_design_1.reset = reset;
    always_comb force i_top.i_design_1.clk   = clk;

    always_comb force i_top.i_design_1.wb_adr_i = s_wb_adr_i;
    always_comb force i_top.i_design_1.wb_dat_i = s_wb_dat_i;
    always_comb force i_top.i_design_1.wb_we_i  = s_wb_we_i;
    always_comb force i_top.i_design_1.wb_sel_i = s_wb_sel_i;
    always_comb force i_top.i_design_1.wb_stb_i = s_wb_stb_i;

    always_comb s_wb_dat_o = i_top.i_design_1.wb_dat_o;
    always_comb s_wb_ack_o = i_top.i_design_1.wb_ack_o;

endmodule


`default_nettype wire


// end of file
