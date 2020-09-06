// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 2パラメータのパッキング
module jelly_func_pack2
        #(
            parameter   N         = 4,
            parameter   W0        = 8,
            parameter   W1        = 32,
            
            // local
            parameter   IN0_WIDTH = N * W0,
            parameter   IN1_WIDTH = N * W1,
            parameter   OUT_WIDTH = N * (W0 + W1)
        )
        (
            input   wire    [IN0_WIDTH-1:0] in0,
            input   wire    [IN1_WIDTH-1:0] in1,
            output  wire    [OUT_WIDTH-1:0] out
        );
    
    localparam  OW = W0 + W1;
    
    genvar  i;
    
    generate
    for ( i = 0; i < N; i = i+1 ) begin : loop_pack
        assign out[i*OW +: OW] = {in1[i*W1 +: W1], in0[i*W0 +: W0]};
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
