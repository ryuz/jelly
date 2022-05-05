// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_jfive_conditions
        #(
            parameter   int     DATA_WIDTH  = 32
        )
        (
            input   wire    [DATA_WIDTH-1:0]    in_data0,
            input   wire    [DATA_WIDTH-1:0]    in_data1,

            output  reg                         out_eq,
            output  reg                         out_ne,
            output  reg                         out_lt,
            output  reg                         out_ge,
            output  reg                         out_ltu,
            output  reg                         out_geu
        );

    logic       carry;
    logic       overflow;
    logic       zero;
    logic       negative;

    jelly2_jfive_adder
            #(
                .DATA_WIDTH     (DATA_WIDTH)
            )
        i_jfive_adder
            (
                .in_data0       (in_data0),
                .in_data1       (~in_data1),
                .in_carry       (1'b1),

                .out_data       (),
                .out_carry      (carry),
                .out_overflow   (overflow),
                .out_zero       (zero),
                .out_negative   (negative)
            );
    
    always_comb begin
        out_eq  = zero;
        out_ne  = !zero;
        out_lt  = (overflow != negative);
        out_ge  = (overflow == negative);
        out_ltu = !carry;
        out_geu = carry;
    end

    /* この書き方だと少し大きくなった
    always_comb begin
        eq  = (in_data0 == in_data1);
        ne  = (in_data0 != in_data1);
        lt  = (in_data0  < in_data1);
        ge  = (in_data0 >= in_data1);
        ltu = ($unsigned(in_data0)  < $unsigned(in_data1));
        geu = ($unsigned(in_data0) >= $unsigned(in_data1));
    end
    */

endmodule


`default_nettype wire


// end of file
