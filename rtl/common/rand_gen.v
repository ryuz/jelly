// ---------------------------------------------------------------------------
//  Common components
//   random generator
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// random generator
module jelly_rand_gen
		(
			input			clk,
			input			reset,
			input	[15:0]	seed,
			output			out
		);
	
	reg		[15:0]	lfsr;
	
	always @(posedge clk) begin
		if ( reset ) begin
			lfsr <= seed;
		end
		else begin
			lfsr[15:1] <= lfsr[14:0];
			lfsr[0]    <= lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
		end
	end
	
	assign out = lfsr[0];
	
endmodule


// end of file
