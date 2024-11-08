// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_to_bram
        #(
            parameter           DEVICE     = "RTL"      ,
            parameter           SIMULATION = "false"    ,
            parameter           DEBUG      = "false"    
        )
        (
            jelly3_axi4l_if.s       s_axi4l ,
            jelly3_bram_if.m        m_bram  
        );

    jelly3_axi4_if
            #(
                .ID_BITS        (1                  ),
                .ADDR_BITS      (s_axi4l.ADDR_BITS  ),
                .DATA_BITS      (s_axi4l.DATA_BITS  ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              ), 
            )
        axi4
            (
                .aresetn        (s_axi4l.aresetn    ),
                .aclk           (s_axi4l.aclk       ),
                .aclken         (s_axi4l.aclken     ) 
            );
    
    jelly3_axi4l_to_axi4
          #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_axi4l_to_axi4
            (
                .s_axi4l        (s_axi4l            ),
                .m_axi4         (axi4               )
            );

    
    jelly3_axi4_to_bram
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              ) 
            )
        u_axi4_to_bram
            (
                .s_axi4         (axi4               ),
                .m_bram         (m_bram             )
            );
    

endmodule


`default_nettype wire


// end of file
