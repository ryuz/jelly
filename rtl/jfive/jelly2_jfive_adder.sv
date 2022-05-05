// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_jfive_adder
        #(
            parameter   int     DATA_WIDTH  = 32
        )
        (
            input   wire    [DATA_WIDTH-1:0]            in_data0,
            input   wire    [DATA_WIDTH-1:0]            in_data1,
            input   wire                                in_carry,

            output  reg     [DATA_WIDTH-1:0]            out_data,
            output  reg                                 out_carry,
            output  reg                                 out_overflow,
            output  reg                                 out_zero,
            output  reg                                 out_negative
        );

    // add
    always_comb begin
        automatic   logic   msb_carry;
        
        {msb_carry, out_data[DATA_WIDTH-2:0]} = {1'b0, in_data0[DATA_WIDTH-2:0]} + {1'b0, in_data1[DATA_WIDTH-2:0]} + DATA_WIDTH'(in_carry);
        {out_carry, out_data[DATA_WIDTH-1]}   = in_data0[DATA_WIDTH-1] + in_data1[DATA_WIDTH-1] + msb_carry;

        out_overflow = (msb_carry != out_carry);
        out_zero     = (out_data == '0);
        out_negative = out_data[DATA_WIDTH-1];
    end
    
endmodule


`default_nettype wire


// end of file
