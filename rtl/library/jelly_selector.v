// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   selecter
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// selecter
module jelly_selector
		#(
			parameter	SEL_WIDTH = 2,
			parameter	OUT_WIDTH = 8,
			parameter	IN_WIDTH  = (OUT_WIDTH * SEL_WIDTH)
		)
		(
			input	wire	[SEL_WIDTH-1:0]		sel,
			input	wire	[IN_WIDTH-1:0]		din,
			output	reg		[OUT_WIDTH-1:0]		dout
		);
	
	integer i;
	integer j;
	always @* begin
		dout = {OUT_WIDTH{1'b0}};
		for ( i = 0; i < SEL_WIDTH; i = i + 1 ) begin
			if ( sel[i] ) begin
				for ( j = 0; j < OUT_WIDTH; j = j + 1 ) begin
					dout[j] = dout[j] | din[OUT_WIDTH*i + j];
				end
			end
		end
	end
	
endmodule


// end of file
