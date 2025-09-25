// ---------------------------------------------------------------------------
//  RTC-lab  PYTHON300 + Spartan7 MIPI Global shutter camera
//
//                                 Copyright (C) 2024-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// MIPI CSI2
module mipi_csi2_tx
        #(
            parameter           DEVICE     = "7SERIES"  ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            input   var logic   [7:0]   param_dt        ,
            input   var logic   [15:0]  param_wc        ,

            input   var logic           frame_start     ,
            input   var logic           frame_end       ,

            jelly3_axi4s_if.s           s_axi4s         ,
            jelly3_axi4s_if.m           m_axi4s          
        );

    // Convert to 2byte lane
    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (2*8                ),
                .USER_BITS      (s_axi4s.USER_BITS  ),
                .DEBUG          (DEBUG              )
            )
        axi4s_2byte
            (
                .aresetn        (s_axi4s.aresetn    ),
                .aclk           (s_axi4s.aclk       ),
                .aclken         (s_axi4s.aclken     )
            );

    jelly3_mipi_csi2_tx_4raw10_to_2byte
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_mipi_csi2_tx_4raw10_to_2byte
            (
                .s_axi4s        (s_axi4s            ),
                .m_axi4s        (axi4s_2byte        )
            );

    // MIPI-CSI2 TX
    jelly3_mipi_csi2_tx_packet_2lane
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_mipi_csi2_tx_packet_2lane2
            (
                .param_dt       (param_dt           ),
                .param_wc       (param_wc           ),

                .frame_start    (frame_start        ),
                .frame_end      (frame_end          ),

                .s_axi4s        (axi4s_2byte        ),
                .m_axi4s        (m_axi4s            )
            );

endmodule


`default_nettype wire


// end of file
