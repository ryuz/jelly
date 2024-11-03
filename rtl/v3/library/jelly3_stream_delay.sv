// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// stream streal
module jelly3_stream_delay
        #(
            parameter   int     LATENCY    = 1                      ,
            parameter   int     DATA_BITS  = 8                      ,
            parameter   type    data_t     = logic  [DATA_BITS-1:0] ,
            parameter   data_t  DATA_INIT  = 'x                     
        )
        (
            input   var logic       reset       ,
            input   var logic       clk         ,
            input   var logic       cke         ,
            
            input   var data_t      s_data      ,
            input   var logic       s_valid     ,
            
            output  var data_t      m_data      ,
            output  var logic       m_valid     
        );
    

    jelly3_data_delay
            #(
                .LATENCY    (LATENCY    ),
                .DATA_BITS  (DATA_BITS  ),
                .data_t     (data_t     ),
                .DATA_INIT  (DATA_INIT  )
            )
        u_delay_data
            (
                .reset      ,
                .clk        ,
                .cke        ,
                
                .s_data     ,
                
                .m_data    
            );
    
    jelly3_data_delay
            #(
                .LATENCY    (LATENCY    ),
                .DATA_BITS  (1          ),
                .DATA_INIT  (1'b0       )
            )
        u_delay_valid
            (
                .reset      ,
                .clk        ,
                .cke        ,
                
                .s_data     (s_valid    ),
                
                .m_data     (m_valid    )
            );
    
endmodule


`default_nettype wire


// end of file
