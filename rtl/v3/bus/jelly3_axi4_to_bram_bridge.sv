// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_to_bram_bridge
        #(
            parameter   bit     ASYNC          = 1              ,
            parameter   int     CFIFO_PTR_BITS = ASYNC ? 5 : 0  ,
            parameter           CFIFO_RAM_TYPE = "distributed"  ,
            parameter   int     RFIFO_PTR_BITS = ASYNC ? 5 : 0  ,
            parameter           RFIFO_RAM_TYPE = "distributed"  ,
            parameter           DEVICE         = "RTL"          ,
            parameter           SIMULATION     = "false"        ,
            parameter           DEBUG          = "false"        
        )
        (
            jelly3_axi4_if.s        s_axi4  ,
            jelly3_bram_if.m        m_bram  
        );

    localparam  int     BRAM_ID_BITS   = s_axi4.ID_BITS;
    localparam  int     BRAM_STRB_BITS = s_axi4.STRB_BITS;
    localparam  int     BRAM_ADDR_BITS = s_axi4.ADDR_BITS - $clog2(BRAM_STRB_BITS);
    localparam  int     BRAM_DATA_BITS = s_axi4.DATA_BITS;

    jelly3_bram_if
            #(
                .USE_ID         (1                  ),
                .USE_STRB       (1                  ),
                .USE_LAST       (1                  ),
                .ID_BITS        (BRAM_ID_BITS       ),
                .ADDR_BITS      (BRAM_ADDR_BITS     ),
                .DATA_BITS      (BRAM_DATA_BITS     ),
                .STRB_BITS      (BRAM_STRB_BITS     )
            )
        bram_internal
            (
                .reset          (~s_axi4.aresetn    ),
                .clk            (s_axi4.aclk        ),
                .cke            (s_axi4.aclken      )
            );

    jelly3_axi4_to_bram
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_axi4_to_bram
            (
                .s_axi4         (s_axi4             ),
                .m_bram         (bram_internal.m    )
            );

    
    jelly3_bram_async
            #(
                .ASYNC          (ASYNC              ),
                .CFIFO_PTR_BITS (CFIFO_PTR_BITS     ),
                .CFIFO_RAM_TYPE (CFIFO_RAM_TYPE     ),
                .RFIFO_PTR_BITS (RFIFO_PTR_BITS     ),
                .RFIFO_RAM_TYPE (RFIFO_RAM_TYPE     ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_bram_async
            (
                .s_bram         (bram_internal.s    ),
                .m_bram         (m_bram             )
            );

endmodule


`default_nettype wire


// end of file
