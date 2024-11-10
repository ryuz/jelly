// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_bram_accessor
        #(
            parameter   int     WLATENCY    = 1                         ,
            parameter   int     RLATENCY    = 2                         ,
            parameter   type    en_t        = logic [RLATENCY-1:0]      ,
            parameter   int     ADDR_BITS   = 10                        ,
            parameter   type    addr_t      = logic [ADDR_BITS-1:0]     ,
            parameter   int     DATA_BITS   = 32                        ,
            parameter   type    data_t      = logic [DATA_BITS-1:0]     ,
            parameter   int     BYTE_BITS   = 8                         ,
            parameter   int     WE_BITS     = DATA_BITS / BYTE_BITS     ,
            parameter   type    we_t        = logic [WE_BITS-1:0]       
        )
        (
            jelly3_axi4l_if.s   s_axi4l ,

            output  var en_t    en      ,
            output  var we_t    we      ,
            output  var addr_t  addr    ,
            output  var data_t  wdata   ,
            input   var data_t  rdata   
        );

    jelly3_bram_if
            #(
                .USE_ID         (0                  ),
                .USE_STRB       (1                  ),
                .USE_LAST       (0                  ),

                .ID_BITS        (1                  ),
                .ADDR_BITS      (ADDR_BITS          ),
                .DATA_BITS      (DATA_BITS          ),
                .DEVICE         (s_axi4l.DEVICE     ),
                .SIMULATION     (s_axi4l.SIMULATION ),
                .DEBUG          (s_axi4l.DEBUG      ) 
            )
        bram
            (
                .reset          (~s_axi4l.aresetn   ),
                .clk            (s_axi4l.aclk       ),
                .cke            (s_axi4l.aclken     ) 
            );

    jelly3_axi4l_to_bram
            #(
                .DEVICE         (s_axi4l.DEVICE     ),
                .SIMULATION     (s_axi4l.SIMULATION ),
                .DEBUG          (s_axi4l.DEBUG      ) 
            )
        u_axi4l_to_bram
            (
                .s_axi4l        (s_axi4l            ),
                .m_bram         (bram               )
            );


    jelly3_bram_accessor
            #(
                .WLATENCY       (WLATENCY           ),
                .RLATENCY       (RLATENCY           ),
                .en_t           (en_t               ),
                .ADDR_BITS      (ADDR_BITS          ),
                .addr_t         (addr_t             ),
                .DATA_BITS      (DATA_BITS          ),
                .data_t         (data_t             ),
                .BYTE_BITS      (BYTE_BITS          ),
                .WE_BITS        (WE_BITS            ),
                .we_t           (we_t               )
            )
        u_bram_accessor
            (
                .s_bram         (bram               ),

                .en             ,
                .we             ,
                .addr           ,
                .wdata          ,
                .rdata          
            );

endmodule


`default_nettype wire


// end of file
