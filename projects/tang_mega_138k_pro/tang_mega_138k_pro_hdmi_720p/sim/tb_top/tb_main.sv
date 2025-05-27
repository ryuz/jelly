// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
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

    logic                           dvi_tx_vsync;
    logic                           dvi_tx_hsync;
    logic                           dvi_tx_de;
    logic   [23:0]                  dvi_tx_data;
    logic   [10:0]                  x;
    logic   [10:0]                  y;
    assign dvi_tx_vsync = u_top.draw_vsync;
    assign dvi_tx_hsync = u_top.draw_hsync;
    assign dvi_tx_de    = u_top.draw_de   ;
    assign dvi_tx_data  = u_top.draw_rgb  ;
    assign x            = u_top.syncgen_x ;
    assign y            = u_top.syncgen_y ;

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("img_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (1)
            )
        u_axi4s_slave_model
            (
                .aresetn            (~u_top.reset),
                .aclk               (clk),
                .aclken             (1'b1),

                .param_width        (640),
                .param_height       (480),
                .frame_num          (),
                
                .s_axi4s_tuser      (x==3 && y==0),
                .s_axi4s_tlast      (x==3+639),
                .s_axi4s_tdata      (dvi_tx_data),
                .s_axi4s_tvalid     (dvi_tx_de),
                .s_axi4s_tready     ()
        );
    

endmodule


`default_nettype wire


// end of file
