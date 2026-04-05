// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Delay
module jelly3_data_delay
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
            
            output  var data_t      m_data    
        );
    
    
    if ( LATENCY == 0 ) begin : bypass
        assign m_data = s_data;
    end
    else begin : delay
        data_t  que_data    [0:LATENCY-1];
        always_ff @(posedge clk) begin
            if ( reset ) begin
                for ( int i = 0; i < LATENCY; i++ ) begin
                    que_data[i] <= DATA_INIT;
                end
            end
            else if ( cke ) begin
                que_data[0] <= s_data;
                for ( int i = 1; i < LATENCY; i++ ) begin
                    que_data[i] <= que_data[i-1];
                end
            end
        end
        assign m_data = que_data[LATENCY-1];
    end
    
endmodule


`default_nettype wire


// end of file
