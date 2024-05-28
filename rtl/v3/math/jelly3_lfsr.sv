// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// linear feedback shift register
module jelly3_lfsr
        #(
            parameter   int     DATA_BITS   = 16                    ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter   data_t  INIT        = 16'hace1              
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,
            
            input   var logic   update      ,
            input   var logic   clear       ,
            input   var data_t  clear_value ,
            input   var data_t  polynomial  ,
            
            output  var data_t  dout        
        );
    
    data_t  lfsr;
    always_ff @ (posedge clk) begin
        if ( reset ) begin
            lfsr <= INIT;
        end
        else if ( cke ) begin
            if ( clear ) begin
                lfsr <= clear_value;
            end
            else if ( update ) begin
                lfsr <= {^(lfsr & polynomial), lfsr[$bits(lfsr)-1:1]};
            end
        end
    end

    assign dout = lfsr;

endmodule


`default_nettype wire


// end of file
