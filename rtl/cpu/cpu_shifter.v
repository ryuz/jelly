// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



`define	SHIFT_FUNC_SLL		2'b00
`define	SHIFT_FUNC_SRL		2'b01
`define	SHIFT_FUNC_SRA		2'b11


module cpu_shifter
		(
			op_func,
			
			in_data, in_sa,
			out_data
		);
	parameter SA_WIDTH   = 5;
	parameter DATA_WIDTH = (1 << SA_WIDTH);

	input	[1:0]				op_func;
	
	input	[DATA_WIDTH-1:0]	in_data;
	input	[SA_WIDTH-1:0]		in_sa;
	
	output	[DATA_WIDTH-1:0]	out_data;
	
	
	// shifter
	wire	[DATA_WIDTH-1:0]	data_extend;
	assign data_extend = op_func[1] ? {DATA_WIDTH{in_data[DATA_WIDTH-1]}} : {DATA_WIDTH{1'b0}};
	assign out_data    = op_func[0] ? ({data_extend, in_data} >> in_sa) : (in_data << in_sa);

endmodule


