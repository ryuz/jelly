// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        in_reset_n,
            input   wire                        in_clk,
            input   wire                        clk,
            input   wire                        clk_x5
        );
    
    
    // -----------------------------------------
    //  top
    // -----------------------------------------

    logic           dvi_tx_clk_p;
    logic           dvi_tx_clk_n;
    logic   [2:0]   dvi_tx_data_p;
    logic   [2:0]   dvi_tx_data_n;

    logic   [4:0]   led_n;

    tang_nano_9k_hdmi_sample
        u_top
            (
                in_reset_n,
                in_clk,

                dvi_tx_clk_p,
                dvi_tx_clk_n,
                dvi_tx_data_p,
                dvi_tx_data_n,

                led_n
            );


    // for verilator
    always_comb force u_top.u_clkgen_clkdiv.clk_out = clk;
    always_comb force u_top.u_clkgen_pll.clk_out    = clk_x5;


endmodule


`default_nettype wire


// end of file
