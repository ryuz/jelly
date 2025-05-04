
`timescale 1ps/1ps
`default_nettype none


module mipi_dphy_clk_gen
    (
        input   var logic   reset               ,
        input   var logic   clk50               ,

        output  var logic   core_reset          ,
        output  var logic   core_clk            ,
        output  var logic   system_reset        ,
        output  var logic   txbyteclkhs         ,   // BUFR  (div4 from oserdes_clk90)
        output  var logic   txclkesc            ,   // BUFG
        output  var logic   oserdes_clkdiv      ,   // BUFR  (div4 from oserdes_clk)
        output  var logic   oserdes_clk         ,   // BUFIO
        output  var logic   oserdes_clk90           // BUFIO
    );


    // -----------------------------
    //  Core clock
    // -----------------------------

    logic       core_locked;
    clk_mipi_core
        u_clk_mipi_core
            (
                .reset      (reset          ),
                .clk_in1    (clk50          ),
                .clk_out1   (core_clk       ),
                .locked     (core_locked    )
            );
    
    // -----------------------------
    //  Serial clock
    // -----------------------------

    logic    serial_clk         ;
    logic    serial_clk90       ;
    logic    serial_clkfb       ;
    logic    serial_clkfb_bufg  ;
    logic    serial_locked      ;
    clk_mipi_serial
        u_clk_mipi_serial
            (
                .reset      (reset              ),
                .clk_in1    (clk50              ),

                .clk_out1   (serial_clk         ),
                .clk_out2   (serial_clk90       ),
                .clk_out3   (txclkesc           ),
                .clkfb_out  (serial_clkfb       ),
                .clkfb_in   (serial_clkfb_bufg  ),
                .locked     (serial_locked      )
            );

    BUFG
        u_bufg_clkfb
            (
                .I      (serial_clkfb       ),
                .O      (serial_clkfb_bufg  )
            );
    
    BUFIO
        u_bufio_clk
            (
                .I      (serial_clk         ),
                .O      (oserdes_clk        )
            );

    BUFIO
        u_bufio_clk90
            (
                .I      (serial_clk90       ),
                .O      (oserdes_clk90      )
            );

    BUFR
            #(
                .SIM_DEVICE     ("7SERIES"          ),
                .BUFR_DIVIDE    ("4"                )
            )
        u_bufr_clkdiv
            (
                .I              (serial_clk         ),
                .CE             (1'b1               ),
                .CLR            (1'b0               ),
                .O              (oserdes_clkdiv     )
            );

    BUFR
            #(
                .SIM_DEVICE     ("7SERIES"          ),
                .BUFR_DIVIDE    ("4"                )
            )
        u_bufr_txbyteclkhs
            (
                .I              (serial_clk90       ),
                .CE             (1'b1               ),
                .CLR            (1'b0               ),
                .O              (txbyteclkhs        )
            );

    // -----------------------------
    //  Serial clock
    // -----------------------------

    jelly_reset
        u_reset_core
            (
                .clk            (core_clk               ),
                .in_reset       (reset || ~core_locked  ),
                .out_reset      (core_reset             )
            );

    jelly_reset
            #(
                .COUNTER_WIDTH  (6                                      )
            )
        u_reset_system
            (
                .clk            (core_clk                               ),
                .in_reset       (reset || ~core_locked || ~serial_locked),
                .out_reset      (system_reset                           )
            );

endmodule

