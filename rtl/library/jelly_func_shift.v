// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// この手の演算することが多いので定式化する
module jelly_func_shift
        #(
            parameter   IN_WIDTH    = 32,
            parameter   OUT_WIDTH   = 32,
            parameter   SHIFT_LEFT  = 0,    // 負の値もOK
            parameter   SHIFT_RIGHT = 0,    // 負の値もOK
            parameter   ARITHMETIC  = 0
        )
        (
            input   wire    [IN_WIDTH-1:0]  in,
            output  wire    [OUT_WIDTH-1:0] out
        );
    
    localparam  VAL = SHIFT_RIGHT - SHIFT_LEFT;
    
    generate
    if ( ARITHMETIC ) begin
        if ( VAL >= 0 ) begin : blk_sar
            assign out = (in >>> VAL);
        end
        else begin : blk_sal
            assign out = (in <<< (-VAL));
        end
    end
    else begin
        if ( VAL >= 0 ) begin : blk_slr
            assign out = (in >> VAL);
        end
        else begin : blk_sll
            assign out = (in << (-VAL));
        end
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
