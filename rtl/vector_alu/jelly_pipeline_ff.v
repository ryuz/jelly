// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none



// pipeline flip-flop
module jelly_pipeline_ff
		#(
			parameter	REG   = 0,
			parameter	WIDTH = 32,
			parameter	INIT  = 0
		)
		(
			input	wire					reset,
			input	wire					enable,
			input	wire					clk,
			
			input	wire	[WIDTH-1:0]		in_data,
			output	wire	[WIDTH-1:0]		out_data
		);
	
	// input
	generate
	if ( REG > 0 ) begin
		reg		[WIDTH-1:0]		reg_data	[0:REG-1];
		integer					i;
		always @(posedge clk) begin
			if ( enable ) begin
				if ( reset ) begin
					for ( i = 0; i < REG; i = i + 1 ) begin
						reg_data[i] <= INIT;
					end
				end
				else begin
					reg_data[0] <= in_data;
					for ( i = 1; i < REG; i = i + 1 ) begin
						reg_data[i] <= reg_data[i-1];
					end
				end
			end
		end
		assign out_data = reg_data[REG-1];
	end
	else begin
		assign out_data = in_data;
	end
	endgenerate
	
	
endmodule


`default_nettype wire


// end of file
