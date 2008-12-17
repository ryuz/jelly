// ---------------------------------------------------------------------------
//  Common components
//   Graycode to Binary 
//
//                                 Copyright (C) 2007-2008 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



//   Graycode to Binary 
module graycode_to_binary
		#(
			parameter						WIDTH = 4
		)
		(
			input	wire	[WIDTH-1:0]		graycode,
			output	reg		[WIDTH-1:0]		binary
		);
	
	integer i;
	always @* begin
		binary[WIDTH-1] = graycode[WIDTH-1];
		for ( i = WIDTH - 2; i >= 0; i = i - 1 ) begin
			binary[i] = binary[i+1] ^ graycode[i];
		end		
	end
	
	/*
	function [WIDTH-1:0] bin_out;
	input	[WIDTH-1:0]	gray_in;
	integer i;
		begin
			bin_out[WIDTH-1] = gray_in[WIDTH-1];
			for ( i = WIDTH-2; i >= 0; i = i - 1 ) begin
				bin_out[i] = bin_out[i+1] ^ gray_in[i];
			end
		end
    endfunction
	
    assign binary = bin_out(graycode);
	*/
	
endmodule


// End of file
