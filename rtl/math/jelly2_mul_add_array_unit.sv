
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_mul_add_array_unit
        #(
            parameter   int     MUL0_WIDTH = 18,
            parameter   int     MUL1_WIDTH = 18,
            parameter   int     MAC_WIDTH  = 48
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,

            input   wire    signed  [MUL0_WIDTH-1:0]    in_mul0,
            input   wire    signed  [MUL1_WIDTH-1:0]    in_mul1,
            input   wire    signed  [MAC_WIDTH-1:0]     in_add,

            output  reg     signed  [MAC_WIDTH-1:0]     out_data
        );

    logic   signed  [MUL0_WIDTH-1:0]    st0_mul0;
    logic   signed  [MUL1_WIDTH-1:0]    st0_mul1;
    logic   signed  [MAC_WIDTH-1:0]     st1_mul;

    always @(posedge clk) begin
        if ( reset ) begin
            st0_mul0 <= '0;
            st0_mul1 <= '0;
            st1_mul  <= '0;
            out_data <= '0;
        end
        else if ( cke ) begin
            st0_mul0 <= in_mul0;
            st0_mul1 <= in_mul1;
            st1_mul  <= st0_mul0 * st0_mul1;
            out_data <= st1_mul + in_add;
        end
    end

endmodule


`default_nettype wire


// end of file
