// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 2パラメータのアンパック
module jelly_func_unpack2
        #(
            parameter   N         = 4,
            parameter   W0        = 8,
            parameter   W1        = 32,
            
            // local
            parameter   IN_WIDTH   = N * (W0 + W1),
            parameter   OUT0_WIDTH = N * W0,
            parameter   OUT1_WIDTH = N * W1
        )
        (
            input   wire    [IN_WIDTH-1:0]      in,
            output  wire    [OUT0_WIDTH-1:0]    out0,
            output  wire    [OUT1_WIDTH-1:0]    out1
        );
    
    localparam  IW = W0 + W1;
    
    genvar  i;
    
    generate
    for ( i = 0; i < N; i = i+1 ) begin : loop_umpack
        assign {out1[i*W1 +: W1], out0[i*W0 +: W0]} = in[i*IW +: IW];
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
