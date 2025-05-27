// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2025 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   in_reset    ,
            input   var logic   in_clk      ,
            input   var logic   clk         ,
            input   var logic   clk_x5      
        );
    
    
    // -----------------------------------------
    //  top
    // -----------------------------------------

    logic           dvi_tx_clk_p    ;
    logic           dvi_tx_clk_n    ;
    logic   [2:0]   dvi_tx_data_p   ;
    logic   [2:0]   dvi_tx_data_n   ;

    logic   [3:0]   push_sw_n       ;
    logic   [5:0]   led_n           ;

    tang_mega_138k_pro_hdmi_720p
        u_top
            (
                .in_reset       ,
                .in_clk         ,

                .dvi_tx_clk_p   ,
                .dvi_tx_clk_n   ,
                .dvi_tx_data_p  ,
                .dvi_tx_data_n  ,

                .push_sw_n      ,
                .led_n          
            );


    // for verilator
    always_comb force u_top.u_pll.clkout0 = clk     ;
    always_comb force u_top.u_pll.clkout1 = clk_x5  ;

    logic                           dvi_tx_vsync    ;
    logic                           dvi_tx_hsync    ;
    logic                           dvi_tx_de       ;
    logic   [23:0]                  dvi_tx_data     ;
    logic                           dvi_tx_fs       ;
    logic                           dvi_tx_le       ;
    assign dvi_tx_vsync = u_top.draw_vsync;
    assign dvi_tx_hsync = u_top.draw_hsync;
    assign dvi_tx_de    = u_top.draw_de   ;
    assign dvi_tx_data  = u_top.draw_rgb  ;
    assign dvi_tx_fs    = u_top.draw_fs   ;
    assign dvi_tx_le    = u_top.draw_le   ;

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3      ),
                .DATA_WIDTH         (8      ),
                .INIT_FRAME_NUM     (0      ),
                .FORMAT             ("P3"   ),
                .FILE_NAME          ("img_" ),
                .FILE_EXT           (".ppm" ),
                .SEQUENTIAL_FILE    (1      ),
                .ENDIAN             (1      )
            )
        u_axi4s_slave_model
            (
                .aresetn            (~u_top.reset   ),
                .aclk               (clk            ),
                .aclken             (1'b1           ),

                .param_width        (1280           ),
                .param_height       (720            ),
                .frame_num          (               ),
                
                .s_axi4s_tuser      (dvi_tx_fs      ),
                .s_axi4s_tlast      (dvi_tx_le      ),
                .s_axi4s_tdata      (dvi_tx_data    ),
                .s_axi4s_tvalid     (dvi_tx_de      ),
                .s_axi4s_tready     (               )
        );
    

endmodule


`default_nettype wire


// end of file
