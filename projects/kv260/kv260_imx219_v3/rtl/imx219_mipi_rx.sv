


`timescale 1ns / 1ps
`default_nettype none


module imx219_mipi_rx
        #(
            parameter           DEVICE      = "ULTRASCALE_PLUS" ,
            parameter           SIMULATION  = "false"           ,
            parameter           DEBUG       = "false"           
        )
        (
            input   var logic           core_reset      ,
            input   var logic           core_clk        ,

            input   var logic   [7:0]   param_data_type ,

            input   var logic           cam_clk_p       ,
            input   var logic           cam_clk_n       ,
            input   var logic   [1:0]   cam_data_p      ,
            input   var logic   [1:0]   cam_data_n      ,
            
            jelly3_axi4s_if.m           m_axi4s         
        );
    


    // ----------------------------------------
    //  MIPI D-PHY RX
    // ----------------------------------------
    
    (* KEEP = "true" *)     logic               rxbyteclkhs             ;
                            logic               clkoutphy_out           ;
                            logic               pll_lock_out            ;
                            logic               system_rst_out          ;
                            logic               init_done               ;
    
                            logic               cl_rxclkactivehs        ;
                            logic               cl_stopstate            ;
                            logic               cl_enable               ;
                            logic               cl_rxulpsclknot         ;
                            logic               cl_ulpsactivenot        ;
    
    (* mark_debug=DEBUG *)  logic   [7:0]       dl0_rxdatahs            ;
    (* mark_debug=DEBUG *)  logic               dl0_rxvalidhs           ;
    (* mark_debug=DEBUG *)  logic               dl0_rxactivehs          ;
    (* mark_debug=DEBUG *)  logic               dl0_rxsynchs            ;
    
                            logic               dl0_forcerxmode         ;
                            logic               dl0_stopstate           ;
                            logic               dl0_enable              ;
                            logic               dl0_ulpsactivenot       ;
    
                            logic               dl0_rxclkesc            ;
                            logic               dl0_rxlpdtesc           ;
                            logic               dl0_rxulpsesc           ;
                            logic   [3:0]       dl0_rxtriggeresc        ;
                            logic   [7:0]       dl0_rxdataesc           ;
                            logic               dl0_rxvalidesc          ;
    
                            logic               dl0_errsoths            ;
                            logic               dl0_errsotsynchs        ;
                            logic               dl0_erresc              ;
                            logic               dl0_errsyncesc          ;
                            logic               dl0_errcontrol          ;
    
    (* mark_debug=DEBUG *)  logic   [7:0]       dl1_rxdatahs            ;
    (* mark_debug=DEBUG *)  logic               dl1_rxvalidhs           ;
    (* mark_debug=DEBUG *)  logic               dl1_rxactivehs          ;
    (* mark_debug=DEBUG *)  logic               dl1_rxsynchs            ;
    
                            logic               dl1_forcerxmode         ;
                            logic               dl1_stopstate           ;
                            logic               dl1_enable              ;
                            logic               dl1_ulpsactivenot       ;
                            
                            logic               dl1_rxclkesc            ;
                            logic               dl1_rxlpdtesc           ;
                            logic               dl1_rxulpsesc           ;
                            logic   [3:0]       dl1_rxtriggeresc        ;
                            logic   [7:0]       dl1_rxdataesc           ;
                            logic               dl1_rxvalidesc          ;
                            
                            logic               dl1_errsoths            ;
                            logic               dl1_errsotsynchs        ;
                            logic               dl1_erresc              ;
                            logic               dl1_errsyncesc          ;
                            logic               dl1_errcontrol          ;
    

    assign cl_enable         = 1;
    assign dl0_forcerxmode   = 0;
    assign dl0_enable        = 1;
    assign dl1_forcerxmode   = 0;
    assign dl1_enable        = 1;
    
    mipi_dphy_cam
        u_mipi_dphy_cam
            (
                .core_clk           (core_clk           ),
                .core_rst           (core_reset         ),
                .rxbyteclkhs        (rxbyteclkhs        ),
                
                .clkoutphy_out      (clkoutphy_out      ),
                .pll_lock_out       (pll_lock_out       ),
                .system_rst_out     (system_rst_out     ),
                .init_done          (init_done          ),
                
                .cl_rxclkactivehs   (cl_rxclkactivehs   ),
                .cl_stopstate       (cl_stopstate       ),
                .cl_enable          (cl_enable          ),
                .cl_rxulpsclknot    (cl_rxulpsclknot    ),
                .cl_ulpsactivenot   (cl_ulpsactivenot   ),
                
                .dl0_rxdatahs       (dl0_rxdatahs       ),
                .dl0_rxvalidhs      (dl0_rxvalidhs      ),
                .dl0_rxactivehs     (dl0_rxactivehs     ),
                .dl0_rxsynchs       (dl0_rxsynchs       ),
                
                .dl0_forcerxmode    (dl0_forcerxmode    ),
                .dl0_stopstate      (dl0_stopstate      ),
                .dl0_enable         (dl0_enable         ),
                .dl0_ulpsactivenot  (dl0_ulpsactivenot  ),
                
                .dl0_rxclkesc       (dl0_rxclkesc       ),
                .dl0_rxlpdtesc      (dl0_rxlpdtesc      ),
                .dl0_rxulpsesc      (dl0_rxulpsesc      ),
                .dl0_rxtriggeresc   (dl0_rxtriggeresc   ),
                .dl0_rxdataesc      (dl0_rxdataesc      ),
                .dl0_rxvalidesc     (dl0_rxvalidesc     ),
                
                .dl0_errsoths       (dl0_errsoths       ),
                .dl0_errsotsynchs   (dl0_errsotsynchs   ),
                .dl0_erresc         (dl0_erresc         ),
                .dl0_errsyncesc     (dl0_errsyncesc     ),
                .dl0_errcontrol     (dl0_errcontrol     ),
                
                .dl1_rxdatahs       (dl1_rxdatahs       ),
                .dl1_rxvalidhs      (dl1_rxvalidhs      ),
                .dl1_rxactivehs     (dl1_rxactivehs     ),
                .dl1_rxsynchs       (dl1_rxsynchs       ),
                
                .dl1_forcerxmode    (dl1_forcerxmode    ),
                .dl1_stopstate      (dl1_stopstate      ),
                .dl1_enable         (dl1_enable         ),
                .dl1_ulpsactivenot  (dl1_ulpsactivenot  ),
                
                .dl1_rxclkesc       (dl1_rxclkesc       ),
                .dl1_rxlpdtesc      (dl1_rxlpdtesc      ),
                .dl1_rxulpsesc      (dl1_rxulpsesc      ),
                .dl1_rxtriggeresc   (dl1_rxtriggeresc   ),
                .dl1_rxdataesc      (dl1_rxdataesc      ),
                .dl1_rxvalidesc     (dl1_rxvalidesc     ),
                
                .dl1_errsoths       (dl1_errsoths       ),
                .dl1_errsotsynchs   (dl1_errsotsynchs   ),
                .dl1_erresc         (dl1_erresc         ),
                .dl1_errsyncesc     (dl1_errsyncesc     ),
                .dl1_errcontrol     (dl1_errcontrol     ),
                
                .clk_rxp            (cam_clk_p          ),
                .clk_rxn            (cam_clk_n          ),
                .data_rxp           (cam_data_p         ),
                .data_rxn           (cam_data_n         )
           );
    
    wire    logic   dphy_clk   = rxbyteclkhs;
    wire    logic   dphy_reset = system_rst_out;
    

    // ----------------------------------------
    //  DPHY Recv
    // ----------------------------------------

    localparam LANES = 2;

    jelly3_axi4s_if
            #(
                .DATA_BITS  (2*8            ),
                .DEBUG      (DEBUG          )
            )
        axi4s_rx_dphy
            (
                .aresetn    (~dphy_reset    ),
                .aclk       (dphy_clk       ),
                .aclken     (1'b1           )
            );

    jelly3_mipi_dphy_recv
            #(
                .LANES      (LANES          ),
                .DEVICE     (DEVICE         ),
                .SIMULATION (SIMULATION     ),
                .DEBUG      (DEBUG          )
            )
        u_mipi_dphy_recv
            (
                .rxdatahs   ({dl1_rxdatahs  , dl0_rxdatahs  }   ),
                .rxvalidhs  ({dl1_rxvalidhs , dl0_rxvalidhs }   ),
                .rxactivehs ({dl1_rxactivehs, dl0_rxactivehs}   ),
                .rxsynchs   ({dl1_rxsynchs  , dl0_rxsynchs  }   ),
                
                .m_axi4s    (axi4s_rx_dphy.m                    )
            );

    // ----------------------------------------
    //  DPHY Recv
    // ----------------------------------------

    // rx_fifo
    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (LANES*8            )
            )
        axi4s_rx_fifo
            (
                .aresetn        (m_axi4s.aresetn    ),
                .aclk           (m_axi4s.aclk       ),
                .aclken         (m_axi4s.aclken     )
            );

    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (9                  ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REG       (1                  ),
                .S_REG          (1                  ),
                .M_REG          (1                  )
            )
        u_axi4s_fifo_rx
            (
                .s_axi4s        (axi4s_rx_dphy.s    ),
                .m_axi4s        (axi4s_rx_fifo.m    ),

                .s_free_size    (                   ),
                .m_data_size    (                   )
            );
    

    // ----------------------------------------
    //  CSI-2 RX
    // ----------------------------------------

    jelly3_axi4s_if
            #(
                .USER_BITS      (1                  ),
                .DATA_BITS      (LANES*8            )
            )
        axi4s_rx_packet
            (
                .aresetn        (m_axi4s.aresetn    ),
                .aclk           (m_axi4s.aclk       ),
                .aclken         (m_axi4s.aclken     )
            );
    
    logic           rx_frame_start      ;
    logic           rx_frame_end        ;
    logic           rx_ecc_corrected    ;
    logic           rx_ecc_error        ;
    logic           rx_ecc_valid        ;
    logic           rx_crc_error        ;
    logic           rx_crc_valid        ;
    logic           rx_packet_lost      ;

    jelly3_mipi_csi2_rx_packet_2lane
        u_mipi_csi2_rx_packet_2lane
            (
                .param_data_type    (param_data_type    ),
                
                .out_frame_start    (rx_frame_start     ),
                .out_frame_end      (rx_frame_end       ),
                .out_ecc_corrected  (rx_ecc_corrected   ),
                .out_ecc_error      (rx_ecc_error       ),
                .out_ecc_valid      (rx_ecc_valid       ),
                .out_crc_error      (rx_crc_error       ),
                .out_crc_valid      (rx_crc_valid       ),
                .out_packet_lost    (rx_packet_lost     ),

                .s_axi4s            (axi4s_rx_fifo.s    ),
                .m_axi4s            (axi4s_rx_packet.m  )
            );

    // to RAW10
    jelly3_mipi_csi2_rx_byte_to_raw10
        u_mipi_csi2_rx_byte_to_raw10
            (
                .s_axi4s        (axi4s_rx_packet.s  ),
                .m_axi4s        (m_axi4s            )
            );
        
endmodule

`default_nettype wire

