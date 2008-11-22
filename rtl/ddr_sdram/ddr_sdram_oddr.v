// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//   DDR-SDRAM interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module ddr_sdram_oddr
		(
			clk, in_even, in_odd, out
		);
	
	parameter	INIT   = 1'b0;
	parameter	WIDTH  = 1;
	
	input					clk;
	
	input	[WIDTH-1:0]		in_even;
	input	[WIDTH-1:0]		in_odd;
	output	[WIDTH-1:0]		out;
	
	wire	[WIDTH-1:0]		ddr_q;
	
	
	generate
	genvar	i;
	for ( i = 0; i < WIDTH; i = i + 1 ) begin : oddr
		OBUF
				#(
					.IOSTANDARD			("SSTL2_I")
				)
			i_obuf
				(
					.O					(out[i]),
					.I					(ddr_q[i])
				);
		
		ODDR2
				#(
					.DDR_ALIGNMENT		("NONE"),
					.INIT				(INIT),
					.SRTYPE				("SYNC")
				)
			i_oddr_dq
				(
					.Q					(ddr_q[i]),
					.C0					(clk),
					.C1					(~clk),
					.CE					(1'b1),
					.D0					(in_even[i]),
					.D1					(in_odd[i]),
					.R					(1'b0),
					.S					(1'b0)
				);
	end
	endgenerate
	
endmodule


