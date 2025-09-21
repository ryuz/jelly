
`timescale 1ps/1ps
`default_nettype none


module mipi_dphy_clk_gen
    (
        input   var logic   reset               ,
        input   var logic   clk50               ,

        jelly3_axi4l_if.s   s_axi4l_mmcm        ,
//      jelly3_axi4l_if.s   s_axi4l_pll         ,

        input   var logic   mmcm_rst            ,
        input   var logic   mmcm_pwrdwn         ,
        input   var logic   pll_rst             ,
        input   var logic   pll_pwrdwn          ,

        output  var logic   core_reset          ,
        output  var logic   core_clk            ,
        output  var logic   system_reset        ,
//      output  var logic   dphy_reset          ,
        output  var logic   dphy_clk            ,   // BUFR  (div4 from oserdes_clk90)
        output  var logic   txclkesc            ,   // BUFG
        output  var logic   oserdes_clkdiv      ,   // BUFR  (div4 from oserdes_clk)
        output  var logic   oserdes_clk         ,   // BUFIO
        output  var logic   oserdes_clk90           // BUFIO
    );


    // -----------------------------
    //  Core clock
    // -----------------------------

    logic       core_clk200     ;
    logic       core_clk20      ;
    logic       core_clkfb      ;
    logic       core_clkfb_bufg ;
    logic       core_locked     ;
//  clk_mipi_core
    mipi_dphy_clk_gen_core
        u_clk_mipi_core
            (
                .reset              (reset              ),
                .clk_in1            (clk50              ),

//              .s_axi4l            (s_axi4l_pll        ),

                .pll_rst            (pll_rst            ),
                .pll_pwrdwn         (pll_pwrdwn         ),

                .clk_out1           (core_clk200        ),
                .clk_out2           (core_clk20         ),
                .clkfb_out          (core_clkfb         ),
                .clkfb_in           (core_clkfb_bufg    ),
                .locked             (core_locked        )
            );

    BUFG
        u_bufg_core_clkfb
            (
                .I                  (core_clkfb     ),
                .O                  (core_clkfb_bufg)
            );

    BUFG
        u_bufg_core_clk
            (
                .I                  (core_clk200    ),
                .O                  (core_clk       )
            );

    BUFG
        u_bufg_txclkesc
            (
                .I                  (core_clk20     ),
                .O                  (txclkesc       )
            );

    jelly3_reset
        u_reset_core
            (
                .clk                (core_clk               ),
                .cke                (1'b1                   ),
                .in_reset           (reset || ~core_locked  ),
                .out_reset          (core_reset             )
            );


    // -----------------------------
    //  Serial clock
    // -----------------------------

    logic    serial_clk         ;
    logic    serial_clk90       ;
    logic    serial_clkesc      ;
    logic    serial_clkfb       ;
    logic    serial_clkfb_bufg  ;
    logic    serial_locked      ;
//  clk_mipi_serial
    mipi_dphy_clk_gen_serial
        u_mipi_dphy_clk_gen_serial
            (
                .reset              (reset              ),
                .clk_in1            (clk50              ),

                .s_axi4l            (s_axi4l_mmcm       ),

                .mmcm_rst           (mmcm_rst           ),
                .mmcm_pwrdwn        (mmcm_pwrdwn        ),

                .clk_out1           (serial_clk         ),
                .clk_out2           (serial_clk90       ),
//              .clk_out3           (serial_clkesc      ),
                .clkfb_out          (serial_clkfb       ),
                .clkfb_in           (serial_clkfb_bufg  ),
                .locked             (serial_locked      )
            );

    /*
    BUFG
        u_bufg_txclkesc
            (
                .I                  (serial_clkesc      ),
                .O                  (txclkesc           )
            );
    */

    BUFG
        u_bufg_clkfb
            (
                .I                  (serial_clkfb       ),
                .O                  (serial_clkfb_bufg  )
            );
    
    BUFIO
        u_bufio_clk
            (
                .I                  (serial_clk         ),
                .O                  (oserdes_clk        )
            );

    BUFIO
        u_bufio_clk90
            (
                .I                  (serial_clk90       ),
                .O                  (oserdes_clk90      )
            );

    BUFR
            #(
                .SIM_DEVICE         ("7SERIES"          ),
                .BUFR_DIVIDE        ("4"                )
            )
        u_bufr_clkdiv
            (
                .I                  (serial_clk         ),
                .CE                 (1'b1               ),
                .CLR                (1'b0               ),
                .O                  (oserdes_clkdiv     )
            );

    BUFR
            #(
                .SIM_DEVICE         ("7SERIES"          ),
                .BUFR_DIVIDE        ("4"                )
            )
        u_bufr_dphy
            (
                .I                  (serial_clk90       ),
                .CE                 (1'b1               ),
                .CLR                (1'b0               ),
                .O                  (dphy_clk           )
            );

    // -----------------------------
    //  Serial clock
    // -----------------------------

    jelly3_reset
            #(
                .ADDITIONAL_CYCLE   (64                                     )
            )
        u_reset_system
            (
                .clk                (core_clk                               ),
                .cke                (1'b1                                   ),
                .in_reset           (reset || ~core_locked || ~serial_locked),
                .out_reset          (system_reset                           )
            );

    /*
    jelly3_reset
        u_reset_dphy
            (
                .clk                (dphy_clk               ),
                .cke                (1'b1                   ),
                .in_reset           (system_reset           ),
                .out_reset          (dphy_reset             )
            );
    */

endmodule


`default_nettype wire


// end of file
