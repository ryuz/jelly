// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   reverse
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// selecter
module jelly_reverse
		#(
			parameter	WIDTH = 8
		)
		(
			input	wire					reverse,
			
			input	wire	[WIDTH-1:0]		din,
			output	wire	[WIDTH-1:0]		dout
		);
	
	reg		[WIDTH-1:0]		rev_data;
	
	integer i;
	always @* begin
		rev_data = {WIDTH{1'b0}};
		for ( i = 0; i < WIDTH; i = i + 1 ) begin
			rev_data[i] = din[WIDTH-1-i];
		end
	end
	
	assign dout = reverse ? rev_data : din;
	
endmodule


// end of file
