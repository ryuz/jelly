// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   WB_ADR_WIDTH = 37,
            parameter   WB_DAT_WIDTH = 64,
            parameter   WB_SEL_WIDTH = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
    
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_peri_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_peri_sel_i,
            input   wire                        s_wb_peri_we_i,
            input   wire                        s_wb_peri_stb_i,
            output  wire                        s_wb_peri_ack_o
        );
    

    
    // -----------------------------------------
    //  DUT
    // -----------------------------------------
    
    kr260_udmabuf_sample
       i_top
            (
                .fan_en     (),
                .led        ()
            );
    
    // force の挙動が verilator で異なるため always で実施
    always @* force i_top.i_design_1.reset  = reset;
    always @* force i_top.i_design_1.clk    = clk;

    always @* force i_top.i_design_1.wb_peri_adr_i = s_wb_peri_adr_i;
    always @* force i_top.i_design_1.wb_peri_dat_i = s_wb_peri_dat_i;
    always @* force i_top.i_design_1.wb_peri_sel_i = s_wb_peri_sel_i;
    always @* force i_top.i_design_1.wb_peri_we_i  = s_wb_peri_we_i;
    always @* force i_top.i_design_1.wb_peri_stb_i = s_wb_peri_stb_i;

    assign s_wb_peri_dat_o = i_top.i_design_1.wb_peri_dat_o;
    assign s_wb_peri_ack_o = i_top.i_design_1.wb_peri_ack_o;
    
endmodule


`default_nettype wire


// end of file
