// ----------------------------------------------------------------------------
//  Common components
//   Binary to Graycode
//
//                                  Copyright (C) 2007-2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


//   Binary to Graycode
module binary_to_graycode(
			binary,
			graycode
		);
	
	parameter WIDTH = 4;
	
	input	[WIDTH-1:0]	binary;
	output	[WIDTH-1:0]	graycode;
	
	
	function [WIDTH-1:0] gray_out;
	input	[WIDTH-1:0]	bin_in;
	integer i;
		begin
			gray_out[WIDTH-1] = bin_in[WIDTH-1];
			for ( i = WIDTH-2; i >= 0; i = i-1 ) begin
				gray_out[i] = bin_in[i+1] ^ bin_in[i];
            end
        end
    endfunction
	
    assign graycode = gray_out(binary);
	
endmodule


// End of file
