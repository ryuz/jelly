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
			dq_write_en, dq_write_even, dq_write_odd,
			dq_read_even, dq_read_odd,
			dm_write_even, dm_write_odd,
			dqs_write_en,
			ddr_sdram_ck_p, ddr_sdram_ck_n, ddr_sdram_cke, ddr_sdram_cs, ddr_sdram_ras, ddr_sdram_cas, ddr_sdram_we,
			ddr_sdram_ba, ddr_sdram_a, ddr_sdram_dm, ddr_sdram_dq, ddr_sdram_dqs
		);
	
	parameter	SDRAM_BA_WIDTH  = 2;
	parameter	SDRAM_A_WIDTH   = 13;
	parameter	SDRAM_DQ_WIDTH  = 16;
	parameter	SDRAM_DM_WIDTH  = SDRAM_DQ_WIDTH / 8;
	parameter	SDRAM_DQS_WIDTH = SDRAM_DQ_WIDTH / 8;
	
	input							reset;
	input							clk;
	input							clk90;
	
	input							cke;
	input							cs;
	input							ras;
	input							cas;
	input							we;
	input	[SDRAM_BA_WIDTH-1:0]	ba;
	input	[SDRAM_A_WIDTH-1:0]		a;
	
	input							dq_write_en;
	input	[SDRAM_DQ_WIDTH-1:0]	dq_write_even;
	input	[SDRAM_DQ_WIDTH-1:0]	dq_write_odd;
	
	output	[SDRAM_DQ_WIDTH-1:0]	dq_read_even;
	output	[SDRAM_DQ_WIDTH-1:0]	dq_read_odd;
	
	input	[SDRAM_DM_WIDTH-1:0]	dm_write_even;
	input	[SDRAM_DM_WIDTH-1:0]	dm_write_odd;
	
	input							dqs_write_en;
	
	output							ddr_sdram_ck_p;
	output							ddr_sdram_ck_n;
	output							ddr_sdram_cke;
	output							ddr_sdram_cs;
	output							ddr_sdram_ras;
	output							ddr_sdram_cas;
	output							ddr_sdram_we;
	output	[SDRAM_BA_WIDTH-1:0]	ddr_sdram_ba;
	output	[SDRAM_A_WIDTH-1:0]		ddr_sdram_a;
	output	[SDRAM_DQ_WIDTH-1:0]	ddr_sdram_dm;
	inout	[SDRAM_DQ_WIDTH-1:0]	ddr_sdram_dq;
	inout	[SDRAM_DQS_WIDTH-1:0]	ddr_sdram_dqs;
	
	
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_read;
	reg		[SDRAM_DQ_WIDTH-1:0]	dq_read_dly;
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_write;
	wire	[SDRAM_DM_WIDTH-1:0]	dm_write;
	wire	[SDRAM_DQS_WIDTH-1:0]	dqs_write;


	
	assign ddr_sdram_cke  = cke;
	assign ddr_sdram_cs   = cs;
	assign ddr_sdram_ras  = ras;
	assign ddr_sdram_cas  = cas;
	assign ddr_sdram_we   = we;
	assign ddr_sdram_ba   = ba;
	assign ddr_sdram_a    = a;
	


//	assign ddr_sdram_ck_p = ~clk;
//	assign ddr_sdram_ck_n = clk;
	
	ODDR2
			#(
				.DDR_ALIGNMENT		("NONE"),
				.INIT				(1'b0),
				.SRTYPE				("SYNC")
			)
		i_oddr_ck_p
			(
				.Q					(ddr_sdram_ck_p),
				.C0					(clk),
				.C1					(~clk),
				.CE					(1'b1),
				.D0					(1'b0),
				.D1					(1'b1),
				.R					(1'b0),
				.S					(1'b0)
			);

	ODDR2
			#(
				.DDR_ALIGNMENT		("NONE"),
				.INIT				(1'b0),
				.SRTYPE				("SYNC")
			)
		i_oddr_ck_n
			(
				.Q					(ddr_sdram_ck_n),
				.C0					(clk),
				.C1					(~clk),
				.CE					(1'b1),
				.D0					(1'b1),
				.D1					(1'b0),
				.R					(1'b0),
				.S					(1'b0)
			);

	
	// simulation
	always @* begin
		dq_read_dly <= #2 dq_read;
	end
	
	
	generate
	genvar	i;
	
	// dq
	for ( i = 0; i < SDRAM_DQ_WIDTH; i = i + 1 ) begin : dq
		// IO
		IOBUF
		/*		#(
					.DRIVE				(12),
					.IBUF_DELAY_VALUE	("6"), 
					.IFD_DELAY_VALUE	("6"),
					.IOSTANDARD			("SSTL2_I"),
					.SLEW				("SLOW")
				)*/
			i_iobuf_dq
				(
					.O					(dq_read[i]),
					.IO					(ddr_sdram_dq[i]),
					.I					(dq_write[i]),
					.T					(~dq_write_en)
				);
		
		// OUT
		ODDR2
				#(
					.DDR_ALIGNMENT		("NONE"),
					.INIT				(1'b0),
					.SRTYPE				("SYNC")
				)
			i_oddr_dq
				(
					.Q					(dq_write[i]),
					.C0					(clk),
					.C1					(~clk),
					.CE					(1'b1),
					.D0					(dq_write_even[i]),
					.D1					(dq_write_odd[i]),
					.R					(1'b0),
					.S					(1'b0)
				);
		
		// IN
		IDDR2
				#(
					.DDR_ALIGNMENT		("NONE"),
					.INIT_Q0			(1'b0),
					.INIT_Q1			(1'b0),
					.SRTYPE				("SYNC")
				)
			i_iddr2_dq
				(
					.Q0					(dq_read_even[i]),
					.Q1					(dq_read_odd[i]),
					.C0					(clk),
					.C1					(~clk),
					.CE					(1'b1),
					.D					(dq_read_dly[i]),
					.R					(1'b0),
					.S					(1'b0)	
				);
	end

	// dm
	for ( i = 0; i < SDRAM_DM_WIDTH; i = i + 1 ) begin : dm
		OBUF
				#(
					.DRIVE				(12),
					.IOSTANDARD			("SSTL2_I"),
					.SLEW				("SLOW")
				)
			i_obuf
				(
					.O					(ddr_sdram_dm[i]),
					.I					(dm_write[i])
				);
		
		ODDR2
				#(
					.DDR_ALIGNMENT		("NONE"),
					.INIT				(1'b0),
					.SRTYPE				("SYNC")
				)
			i_oddr_dq
				(
					.Q					(dm_write[i]),
					.C0					(clk),
					.C1					(~clk),
					.CE					(1'b1),
					.D0					(dm_write_even[i]),
					.D1					(dm_write_odd[i]),
					.R					(1'b0),
					.S					(1'b0)
				);
	end
	
	// dqs
	for ( i = 0; i < SDRAM_DQS_WIDTH; i = i + 1 ) begin : dqs
		ODDR2
				#(
					.DDR_ALIGNMENT		("NONE"),
					.INIT				(1'b0),
					.SRTYPE				("SYNC")
				)
			i_oddr_dq
				(
					.Q					(dqs_write[i]),
					.C0					(clk90),
					.C1					(~clk90),
					.CE					(1'b1),
					.D0					(dq_write_en),
					.D1					(1'b0),
					.R					(1'b0),
					.S					(1'b0)
				);
	
	
		OBUFT
				#(
					.DRIVE				(12),
					.IOSTANDARD			("SSTL2_I"),
					.SLEW				("SLOW")
				)
			i_obuf
				(
					.O					(ddr_sdram_dqs[i]),
					.I					(dqs_write[i]),
					.T					(~dqs_write_en)
				);
	end
	endgenerate
	
endmodule

