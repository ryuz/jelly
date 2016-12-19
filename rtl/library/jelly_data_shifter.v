// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_data_shifter
		#(
			parameter	SEL_WIDTH  = 5,
			parameter	NUM        = (1 << SEL_WIDTH),
			parameter	DATA_WIDTH = 8
		)
		(
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[SEL_WIDTH-1:0]		sel,
			input	wire	[DATA_WIDTH-1:0]	in_data,
			output	wire	[DATA_WIDTH-1:0]	out_data
		);
	
	genvar		i;
	
	generate
	for ( i = 0; i < DATA_WIDTH; i = i+1 ) begin : loop_shift
		jelly_shift_register
				#(
					.SEL_WIDTH		(SEL_WIDTH),
					.NUM			(NUM)
				)
			i_shift_register
				(
					.clk			(clk),
					.cke			(cke),
					
					.sel			(sel),
					.in_data		(in_data[i]),
					.out_data		(out_data[i])
				);
	end
	endgenerate
	
	
endmodule



`default_nettype wire


// end of file
