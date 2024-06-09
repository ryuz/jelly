// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// multiplexer
module jelly2_multiplexer
        #(
            parameter   NUM        = 4,
            parameter   SEL_WIDTH  = $clog2(NUM) > 0 ? $clog2(NUM) : 1,
            parameter   DATA_WIDTH = 8
        )
        (
            input   wire                                endian,
            input   wire    [SEL_WIDTH-1:0]             sel,
            input   wire    [NUM-1:0][DATA_WIDTH-1:0]   din,
            output  reg              [DATA_WIDTH-1:0]   dout
        );
    
    always_comb begin
        if ( SEL_WIDTH > 0 ) begin
            if ( endian ) begin
                dout = din[SEL_WIDTH'(NUM - 1) - sel];
            end
            else begin
                dout = din[sel];
            end
        end
        else begin
            dout = din[0];
        end
    end
    
endmodule


`default_nettype wire


// end of file
