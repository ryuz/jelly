
module graycode_to_binary(
			graycode,
			binary
		);
	
	parameter WIDTH = 4;
	
	input	[WIDTH-1:0]	graycode;
	output	[WIDTH-1:0]	binary;
	
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
	
endmodule

