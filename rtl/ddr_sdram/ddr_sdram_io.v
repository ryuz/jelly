// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//   DDR-SDRAM interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


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
	parameter	SIM_DQ_DELAY    = 2.0;
	
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
	
	input							dq_write_next_en;
	input	[SDRAM_DQ_WIDTH-1:0]	dq_write_even;
	input	[SDRAM_DQ_WIDTH-1:0]	dq_write_odd;
	
	output	[SDRAM_DQ_WIDTH-1:0]	dq_read_even;
	output	[SDRAM_DQ_WIDTH-1:0]	dq_read_odd;
	
	input	[SDRAM_DM_WIDTH-1:0]	dm_write_even;
	input	[SDRAM_DM_WIDTH-1:0]	dm_write_odd;
	
	input							dqs_write_next_en;

	output							ddr_sdram_ck_p;
	output							ddr_sdram_ck_n;
	output							ddr_sdram_cke;
	output							ddr_sdram_cs;
	output							ddr_sdram_ras;
	output							ddr_sdram_cas;
	output							ddr_sdram_we;
	output	[SDRAM_BA_WIDTH-1:0]	ddr_sdram_ba;
	output	[SDRAM_A_WIDTH-1:0]		ddr_sdram_a;
	output	[SDRAM_DM_WIDTH-1:0]	ddr_sdram_dm;
	inout	[SDRAM_DQ_WIDTH-1:0]	ddr_sdram_dq;
	inout	[SDRAM_DQS_WIDTH-1:0]	ddr_sdram_dqs;
	

	wire	[SDRAM_DQ_WIDTH-1:0]	dq_write_t;
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_read;
	reg		[SDRAM_DQ_WIDTH-1:0]	dq_read_dly;
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_write;
	wire	[SDRAM_DM_WIDTH-1:0]	dm_write;
	wire	[SDRAM_DQS_WIDTH-1:0]	dqs_write_t;
	wire	[SDRAM_DQS_WIDTH-1:0]	dqs_write;


	// simulation
	always @* begin
		dq_read_dly <= #SIM_DQ_DELAY dq_read;
	end
	
	
	// ck
	ddr_sdram_oddr	#(.INIT(1'b0), .WIDTH(1)) i_ddr_sdram_oddr_cl_p (.clk(clk), .in_even(1'b0), .in_odd (1'b1), .out(ddr_sdram_ck_p));
	ddr_sdram_oddr	#(.INIT(1'b1), .WIDTH(1)) i_ddr_sdram_oddr_cl_n (.clk(clk), .in_even(1'b1), .in_odd (1'b0), .out(ddr_sdram_ck_n));
	
	// command
	ddr_sdram_out #(.WIDTH(1))				i_out_cke	(.clk(clk), .in(cke), .out(ddr_sdram_cke));
	ddr_sdram_out #(.WIDTH(1))				i_out_cs 	(.clk(clk), .in(cs),  .out(ddr_sdram_cs));
	ddr_sdram_out #(.WIDTH(1))				i_out_ras	(.clk(clk), .in(ras), .out(ddr_sdram_ras));
	ddr_sdram_out #(.WIDTH(1))				i_out_cas	(.clk(clk), .in(cas), .out(ddr_sdram_cas));
	ddr_sdram_out #(.WIDTH(1))				i_out_we 	(.clk(clk), .in(we),  .out(ddr_sdram_we));
	ddr_sdram_out #(.WIDTH(SDRAM_BA_WIDTH))	i_out_ba 	(.clk(clk), .in(ba),  .out(ddr_sdram_ba));
	ddr_sdram_out #(.WIDTH(SDRAM_A_WIDTH))	i_out_a 	(.clk(clk), .in(a),   .out(ddr_sdram_a));

	// dm
	ddr_sdram_oddr
			#(
				.INIT		(1'b0),
				.WIDTH		(SDRAM_DM_WIDTH)
			)
		i_ddr_sdram_oddr_dm
			(
				.clk		(clk),
				.in_even	(dm_write_even),
				.in_odd		(dm_write_odd),
				.out		(ddr_sdram_dm)
			);
	
	
	generate
	genvar	i;
	
	// dq
	for ( i = 0; i < SDRAM_DQ_WIDTH; i = i + 1 ) begin : dq
		// IO
		IOBUF
				#(
					.IOSTANDARD			("SSTL2_I")
				)
			i_iobuf_dq
				(
					.O					(dq_read[i]),
					.IO					(ddr_sdram_dq[i]),
					.I					(dq_write[i]),
					.T					(dq_write_t[i])		// (~dq_write_en)
				);
		
		// T
		(* IOB = "TRUE" *) FD
			i_fd_t
				(
					.D					(~dq_write_next_en),
					.Q					(dq_write_t[i]),
					.C					(clk)
				)/* synthesis syn_useioff = 1 */;	
		
		// O
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
		
		// I
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
	
	
	// dqs
	for ( i = 0; i < SDRAM_DQS_WIDTH; i = i + 1 ) begin : dqs
		// T
		(* IOB = "TRUE" *) FD
			i_fd_t
				(
					.D					(~dqs_write_next_en),
					.Q					(dqs_write_t[i]),
					.C					(~clk90)
				)/* synthesis syn_useioff = 1 */;	
		
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
					.D0					(1'b1),
					.D1					(1'b0),
					.R					(1'b0),
					.S					(1'b0)
				);
		
		
		OBUFT
				#(
					.IOSTANDARD			("SSTL2_I")
				)
			i_obuf
				(
					.O					(ddr_sdram_dqs[i]),
					.I					(dqs_write[i]),
					.T					(dqs_write_t[i])
				);
	end
	endgenerate
	
endmodule

