// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//   DDR-SDRAM interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module ddr_sdram_out
		(
			clk, in, out
		);
	
	parameter	WIDTH = 1;
	parameter	INIT  = 0;
		
	input							clk;
	
	input	[WIDTH-1:0]				in;
	output	[WIDTH-1:0]				out;
	
	generate
	genvar	i;
	for ( i = 0; i < WIDTH; i = i + 1 ) begin : oddr2
		ODDR2
				#(
					.DDR_ALIGNMENT		("NONE"),
					.INIT				(INIT),
					.SRTYPE				("SYNC")
				)
			i_oddr2
				(
					.Q					(out[i]),
					.C0					(clk),
					.C1					(1'b0),
					.CE					(1'b1),
					.D0					(in[i]),
					.D1					(in[i]),
					.R					(1'b0),
					.S					(1'b0)
				);
	end
	endgenerate
	
endmodule

