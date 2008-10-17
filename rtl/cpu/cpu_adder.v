// ----------------------------------------------------------------------------
//  MIPS like CPU for FPGA                                                     
//                                                                             
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------

`timescale 1ns / 1ps


// adder
module cpu_adder
		(
			in_data0, in_data1, in_carry,
			out_data,
			
			out_carry,
			out_overflow,
			out_negative,
			out_zero
		);
	
	parameter DATA_WIDTH = 32;
	
	
	input	[DATA_WIDTH-1:0]	in_data0;
	input	[DATA_WIDTH-1:0]	in_data1;
	input						in_carry;
	
	output	[DATA_WIDTH-1:0]	out_data;
	
	output						out_carry;
	output						out_overflow;
	output						out_negative;
	output						out_zero;
	
	
	// add
	wire						msb_carry;
	assign {msb_carry, out_data[DATA_WIDTH-2:0]} = in_data0[DATA_WIDTH-2:0] + in_data1[DATA_WIDTH-2:0] + in_carry;
	
	// add MSB
	assign {out_carry, out_data[DATA_WIDTH-1]} = in_data0[DATA_WIDTH-1] + in_data1[DATA_WIDTH-1] + msb_carry;
	
	// overflow
	assign out_overflow = (msb_carry != out_carry);
	
	// negative
	assign out_negative = out_data[DATA_WIDTH-1];
	
	// zero
	assign out_zero = (out_data == {DATA_WIDTH{1'b0}});
	
endmodule

