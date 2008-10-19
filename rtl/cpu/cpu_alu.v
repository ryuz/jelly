// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


`define	ALU_ADDER_FUNC_ADD	1'b0
`define	ALU_ADDER_FUNC_SUB	1'b1

`define	ALU_LOGIC_FUNC_AND	2'b00
`define	ALU_LOGIC_FUNC_OR	2'b01
`define	ALU_LOGIC_FUNC_XOR	2'b10
`define	ALU_LOGIC_FUNC_NOR	2'b11

`define	ALU_SHIFT_FUNC_SLL	2'b00
`define	ALU_SHIFT_FUNC_SRL	2'b01
`define	ALU_SHIFT_FUNC_SRA	2'b11

`define	ALU_COMP_FUNC_SLT	1'b1
`define	ALU_COMP_FUNC_SLTU	1'b0



// Arithmetic Logic Unit
module cpu_alu
		(
			op_adder_en, op_adder_func,
			op_logic_en, op_logic_func,
			op_comp_en, op_comp_func,
			
			in_data0, in_data1,
			out_data, out_carry, out_overflow, out_negative, out_zero
		);
	parameter DATA_SIZE  = 5;  					// 3:8bit, 4:16bit, 5:32bit, ...
	parameter DATA_WIDTH = (1 << DATA_SIZE);

	input						op_adder_en;
	input	[1:0]				op_adder_func;

	input						op_logic_en;
	input	[1:0]				op_logic_func;
	
	input						op_comp_en;
	input	[1:0]				op_comp_func;
	
	input	[DATA_WIDTH-1:0]	in_data0;
	input	[DATA_WIDTH-1:0]	in_data1;
	
	output	[DATA_WIDTH-1:0]	out_data;
	output						out_carry;
	output						out_overflow;
	output						out_negative;
	output						out_zero;
	
	
	// adder
	wire	[DATA_WIDTH-1:0]	adder_in_data0;
	wire	[DATA_WIDTH-1:0]	adder_in_data1;
	wire						adder_in_carry;
	wire	[DATA_WIDTH-1:0]	adder_out_data;
	
	assign adder_in_data0 = in_data0;
	assign adder_in_data1 = (op_adder_func[0] ? ~in_data1 : in_data1) &
							(op_adder_func[1] ? {DATA_WIDTH{1'b0}} : {DATA_WIDTH{1'b1}});
	
	assign adder_in_carry = (op_adder_func == `ALU_ADDER_FUNC_SUB) ? 1'b1 : 1'b0;
	
	cpu_adder
		i_cpu_adder
			(
				.in_data0		(adder_in_data0),
				.in_data1		(adder_in_data1),
				.in_carry		(adder_in_carry),
			
				.out_data		(adder_out_data),
			
				.out_carry		(out_carry),
				.out_overflow	(out_overflow),
				.out_negative	(out_negative),
				.out_zero		(out_zero)
			);
	
	
	// logic
	wire	[DATA_WIDTH-1:0]	logic_out_data;
	assign logic_out_data = (op_logic_func == `ALU_LOGIC_FUNC_AND) ?  (in_data0 & in_data1) : {DATA_WIDTH{1'b0}}
							| (op_logic_func == `ALU_LOGIC_FUNC_OR)  ?  (in_data0 | in_data1) : {DATA_WIDTH{1'b0}}
							| (op_logic_func == `ALU_LOGIC_FUNC_XOR) ?  (in_data0 ^ in_data1) : {DATA_WIDTH{1'b0}}
							| (op_logic_func == `ALU_LOGIC_FUNC_NOR) ? ~(in_data0 | in_data1) : {DATA_WIDTH{1'b0}};
	
	// compare
	wire	[DATA_WIDTH-1:0]	comp_out_data;
	assign comp_out_data[0] = (op_comp_func == `ALU_COMP_FUNC_SLT) ? (out_negative != out_overflow) : ~out_carry;
	assign comp_out_data[DATA_WIDTH-1:1] = 0;
	
	// output
	assign out_data = op_adder_en ? adder_out_data : {DATA_WIDTH{1'b0}}
					| op_logic_en ? logic_out_data : {DATA_WIDTH{1'b0}}
					| op_comp_en  ? comp_out_data  : {DATA_WIDTH{1'b0}};
	
	
endmodule

