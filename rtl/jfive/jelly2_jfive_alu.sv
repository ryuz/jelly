// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// レジスタファイル
module jelly2_jfive_alu
        #(
            parameter   int     DATA_WIDTH  = 32,
            parameter   int     SHIFT_WIDTH = $clog2(DATA_WIDTH)
        )
        (
            input   wire    [2:0]               op,

            input   wire    [DATA_WIDTH-1:0]    in_data0,
            input   wire    [DATA_WIDTH-1:0]    in_data1,
            input   wire    [SHIFT_WIDTH-1:0]   in_shamt,

            output  reg     [DATA_WIDTH-1:0]    out_data,

            output  reg                         cond_eq,
            output  reg                         cond_ne,
            output  reg                         cond_lt,
            output  reg                         cond_ge,
            output  reg                         cond_ltu,
            output  reg                         cond_geu,

            output  reg                         flag_carry,
            output  reg                         flag_zero,
            output  reg                         flag_overflow
        );

    // [op]
    // add 000
    // sub 010
    // sll 001
    // srl 101
    // sra 011
    // and 111
    // or  110
    // xor 100

    logic   [DATA_WIDTH-1:0]      adder_in_data0;
    logic   [DATA_WIDTH-1:0]      adder_in_data1;
    logic                         adder_in_carry;

    always_comb begin
        adder_in_data0 = 'x;
        adder_in_data1 = 'x;
        adder_in_carry = 'x;
        case ( op )
        3'b000: begin adder_in_data0 = in_data0; adder_in_data1 = in_data1;  adder_in_carry=1'b0; end
        3'b010: begin adder_in_data0 = in_data0; adder_in_data1 = ~in_data1; adder_in_carry=1'b1; end
        3'b111: begin adder_in_data0 = in_data0 & in_data1;   adder_in_data1 = '0; adder_in_carry=1'b0; end
        3'b110: begin adder_in_data0 = in_data0 | in_data1;   adder_in_data1 = '0; adder_in_carry=1'b0; end
        3'b100: begin adder_in_data0 = in_data0 ^ in_data1;   adder_in_data1 = '0; adder_in_carry=1'b0; end
        3'b001: begin adder_in_data0 = in_data0  << in_shamt; adder_in_data1 = '0; adder_in_carry=1'b0; end
        3'b101: begin adder_in_data0 = in_data0  >> in_shamt; adder_in_data1 = '0; adder_in_carry=1'b0; end
        3'b011: begin adder_in_data0 = in_data0 >>> in_shamt; adder_in_data1 = '0; adder_in_carry=1'b0; end
        default:;
        endcase
    end
    
    logic                       carry;
    logic                       overflow;
    logic                       zero;
    logic                       negative;

    jelly2_jfive_adder
            #(
                .DATA_WIDTH     (DATA_WIDTH)
            )
        jelly2_jfive_adder
            (
                .in_data0       (adder_in_data0),
                .in_data1       (adder_in_data1),
                .in_carry       (adder_in_carry),

                .out_data       (out_data),
                .out_carry      (carry),
                .out_overflow   (overflow),
                .out_zero       (zero),
                .out_negative   (negative)
            );



endmodule


`default_nettype wire


// End of file
