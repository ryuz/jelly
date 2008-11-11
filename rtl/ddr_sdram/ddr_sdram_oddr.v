// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//   DDR-SDRAM interface
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module ddr_sdram_io
		(
			reset, clk, clk90,
			cke, cs, ras, cas, we, ba, a,
			dq_write_next_en, dq_write_even, dq_write_odd,
			dq_read_even, dq_read_odd,
			dm_write_even, dm_write_odd,
			dqs_write_next_en,
			
			ddr_sdram_ck_p, ddr_sdram_ck_n, ddr_sdram_cke, ddr_sdram_cs, ddr_sdram_ras, ddr_sdram_cas, ddr_sdram_we,
			ddr_sdram_ba, ddr_sdram_a, ddr_sdram_dm, ddr_sdram_dq, ddr_sdram_dqs
		);
	parameter	INIT   = 1'0;
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
					.D0					(dm_write_even[i]),
					.D1					(dm_write_odd[i]),
					.R					(1'b0),
					.S					(1'b0)
				);
	end
	endgenerate
	
endmodule

