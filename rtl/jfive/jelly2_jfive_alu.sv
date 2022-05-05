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

            output  reg     [DATA_WIDTH-1:0]    out_data
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

    logic   [SHIFT_WIDTH-1:0]   shamt;
    assign shamt = in_data1[SHIFT_WIDTH-1:0];

    logic   [DATA_WIDTH-1:0]      adder_data0;
    logic   [DATA_WIDTH-1:0]      adder_data1;
    logic                         adder_carry;

    always_comb begin
        adder_data0 = 'x;
        adder_data1 = 'x;
        adder_carry = 'x;
        case ( op )
        3'b000: begin adder_data0 = in_data0; adder_data1 = in_data1;  adder_carry=1'b0; end
        3'b010: begin adder_data0 = in_data0; adder_data1 = ~in_data1; adder_carry=1'b1; end
        3'b111: begin adder_data0 = in_data0 & in_data1; adder_data1 = '0; adder_carry = 1'b0; end
        3'b110: begin adder_data0 = in_data0 | in_data1; adder_data1 = '0; adder_carry = 1'b0; end
        3'b100: begin adder_data0 = in_data0 ^ in_data1; adder_data1 = '0; adder_carry = 1'b0; end
        3'b001: begin adder_data0 = in_data0  << shamt;  adder_data1 = '0; adder_carry = 1'b0; end
        3'b101: begin adder_data0 = in_data0  >> shamt;  adder_data1 = '0; adder_carry = 1'b0; end
        3'b011: begin adder_data0 = in_data0 >>> shamt;  adder_data1 = '0; adder_carry = 1'b0; end
        default:;
        endcase

        out_data = adder_data0 + adder_data1 + DATA_WIDTH'(adder_carry);
    end
    
endmodule


`default_nettype wire


// End of file
