// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//   DDR-SDRAM interface
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps

// MT46V32M16TG-6T

module ddr_sdram
		(
			reset, clk, clk90, endian,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o,
			ddr_sdram_ck_p, ddr_sdram_ck_n, ddr_sdram_cke, ddr_sdram_cs, ddr_sdram_ras, ddr_sdram_cas, ddr_sdram_we,
			ddr_sdram_ba, ddr_sdram_a, ddr_sdram_dm, ddr_sdram_dq, ddr_sdram_dqs
		);
	parameter	SIMULATION      = 1'b0;
	
	parameter	SDRAM_BA_WIDTH  = 2;
	parameter	SDRAM_A_WIDTH   = 13;
	parameter	SDRAM_DQ_WIDTH  = 16;
	parameter	SDRAM_DM_WIDTH  = SDRAM_DQ_WIDTH / 8;
	parameter	SDRAM_DQS_WIDTH = SDRAM_DQ_WIDTH / 8;
	
	parameter	SDRAM_COL_WIDTH = 10;
	parameter	SDRAM_ROW_WIDTH = 13;
	
	parameter	WB_ADR_WIDTH    = SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH+SDRAM_BA_WIDTH-1;
	parameter	WB_DAT_WIDTH    = (SDRAM_DQ_WIDTH * 2);
	localparam	WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8);

	parameter	CLK_RATE        =   10000;	// clock [ps]
	parameter	TRCD            =   15000;	// tRCD  [ps]
	parameter	TRC             =   60000;	// tRC   [ps]
	parameter	TRFC            =   72000;	// tRFC  [ps]
	parameter	TRAS            =   42000;	// tRAS  [ps]
	parameter	TRP             =   15000;	// tRP   [ps]
	parameter	TREFI           = 7800000;	// tREFI [ps]  
	
	parameter	INIT_WAIT_CYCLE = 200000000 / CLK_RATE;
	
	
	// system
	input							reset;
	input							clk;
	input							clk90;
	input							endian;
	
	// wishbone
	input	[WB_ADR_WIDTH-1:0]		wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]		wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]		wb_dat_i;
	input							wb_we_i;
	input	[WB_SEL_WIDTH-1:0]		wb_sel_i;
	input							wb_stb_i;
	output							wb_ack_o;
	
	// DDR-SDRAM
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
	
	
	
	// -----------------------------
	//  Initializer
	// -----------------------------
	
	wire							initializing;
	wire							init_cke;
	wire							init_cs;
	wire							init_ras;
	wire							init_cas;
	wire							init_we;
	wire		[1:0]				init_ba;
	wire		[12:0]				init_a;
	ddr_sdram_init
			#(
				.SIMULATION			(SIMULATION),
				.CLK_RATE			(CLK_RATE),
				.INIT_WAIT_CYCLE	(INIT_WAIT_CYCLE),
				.SDRAM_BA_WIDTH		(SDRAM_BA_WIDTH),
				.SDRAM_A_WIDTH		(SDRAM_A_WIDTH)
			)
		i_ddr_sdram_init
			(
				.reset				(reset),
				.clk				(clk),
				
				.initializing		(initializing),
				
				.ddr_sdram_cke		(init_cke),
				.ddr_sdram_cs		(init_cs),
				.ddr_sdram_ras		(init_ras),
				.ddr_sdram_cas		(init_cas),
				.ddr_sdram_we		(init_we),
				.ddr_sdram_ba		(init_ba),
				.ddr_sdram_a		(init_a)
		);
	

	
	// -----------------------------
	//  command
	// -----------------------------
	
	parameter	TRCD_CYCLE  = ((TRCD  - 1) / CLK_RATE);
	parameter	TRC_CYCLE   = ((TRC   - 1) / CLK_RATE);
	parameter	TRFC_CYCLE  = ((TRFC  - 1) / CLK_RATE);
	parameter	TRAS_CYCLE  = ((TRAS  - 1) / CLK_RATE);
	parameter	TRP_CYCLE   = ((TRP   - 1) / CLK_RATE);
	parameter	TREFI_CYCLE = ((TREFI - 1) / CLK_RATE);
	
	// state
	parameter	ST_IDLE       = 0;
	parameter	ST_REFRESH    = 1;
	parameter	ST_ACTIVATING = 2;
	parameter	ST_ACTIVE     = 3;
	parameter	ST_READ       = 4;
	parameter	ST_WRITE      = 5;
	parameter	ST_PRECHARGE  = 6;
	
	
	// adr mapping
	wire	[SDRAM_COL_WIDTH-1:0]	col_adr;
	wire	[SDRAM_ROW_WIDTH-1:0]	row_adr;
	wire	[SDRAM_BA_WIDTH-1:0]	ba_adr;
	
//	assign col_adr = {wb_adr_i[0 +: SDRAM_COL_WIDTH-1], 1'b0};
//	assign row_adr = wb_adr_i[SDRAM_COL_WIDTH-1 +: SDRAM_ROW_WIDTH];
//	assign ba_adr  = wb_adr_i[SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH-1 +: SDRAM_BA_WIDTH];

	assign col_adr = {wb_adr_i[SDRAM_COL_WIDTH-2:0], 1'b0};
	assign row_adr =  wb_adr_i[SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH-2:SDRAM_COL_WIDTH-1];
	assign ba_adr  =  wb_adr_i[SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH+SDRAM_BA_WIDTH-2:SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH-1];
	
	
	localparam	REG_WRITE_WIDTH = 2;
	localparam	REG_READ_WIDTH  = 6;
	
	
	reg		[3:0]					state;
	reg		[3:0]					counter;
	reg								count_end;

	reg								ref_req;
	reg		[15:0]					ref_counter;
	
	reg								reg_cke;
	reg								reg_cs;
	reg								reg_ras;
	reg								reg_cas;
	reg								reg_we;
	reg		[SDRAM_BA_WIDTH-1:0]	reg_ba;
	reg		[SDRAM_A_WIDTH-1:0]		reg_a;
	
	reg		[REG_WRITE_WIDTH-1:0]	reg_write;
	reg		[REG_READ_WIDTH-1:0]	reg_read;
	
	localparam	STATE_WIDTH   = 4;
	localparam	COUNTER_WIDTH = 4;
	
	reg		[STATE_WIDTH-1:0]		next_state;
	reg		[COUNTER_WIDTH-1:0]		next_counter;
	reg								next_count_end;	

	reg								next_ref_req;
	reg		[15:0]					next_ref_counter;

	reg								next_cs;
	reg								next_ras;
	reg								next_cas;
	reg								next_we;
	reg		[SDRAM_BA_WIDTH-1:0]	next_ba;
	reg		[SDRAM_A_WIDTH-1:0]		next_a;
	
	reg		[REG_WRITE_WIDTH-1:0]	next_write;
	reg		[REG_READ_WIDTH-1:0]	next_read;
	
	always @( posedge clk or posedge reset ) begin
		if ( reset ) begin
			state         <= ST_IDLE;
						
			reg_cke       <= 1'b0;
			reg_cs        <= 1'b1;
			reg_ras       <= 1'b1;
			reg_cas       <= 1'b1;
			reg_we        <= 1'b1;
			reg_ba        <= {SDRAM_BA_WIDTH{1'b0}};
			reg_a         <= {SDRAM_A_WIDTH{1'b0}};
			
			reg_write     <= 0;
			reg_read      <= 0;
		end
		else begin
			if ( initializing ) begin
				state       <= ST_IDLE;
				counter     <= {COUNTER_WIDTH{1'bx}};
				count_end   <= 1'bx;

				ref_req     <= 1'b0;
				ref_counter <= TREFI_CYCLE;
				
				reg_cke     <= init_cke;
				reg_cs      <= init_cs;
				reg_ras     <= init_ras;
				reg_cas     <= init_cas;
				reg_we      <= init_we;
				reg_ba      <= init_ba;
				reg_a       <= init_a;

				reg_write   <= 0;
				reg_read    <= 0;
			end
			else begin
				state       <= next_state;
				counter     <= next_counter;
				count_end   <= next_count_end;

				ref_req     <= next_ref_req;
				ref_counter <= next_ref_counter;
				
				reg_cke     <= 1'b1;
				reg_cs      <= next_cs;
				reg_ras     <= next_ras;
				reg_cas     <= next_cas;
				reg_we      <= next_we;
				reg_ba      <= next_ba;
				reg_a       <= next_a;
				
				reg_write   <= next_write;
				reg_read    <= next_read;
			end
		end
	end
	
	always @* begin
		next_state   = state;
		next_counter = counter - 1;
		
		next_ref_counter = (ref_counter == 0) ? TREFI_CYCLE : ref_counter - 1;
		
		next_cs  = 1'b1;
		next_ras = 1'bx;
		next_cas = 1'bx;   
		next_we  = 1'bx;
		next_ba  = {SDRAM_BA_WIDTH{1'bx}};
		next_a   = {SDRAM_A_WIDTH{1'bx}};
		
		next_write = (reg_write >> 1);
		next_read  = (reg_read >> 1);
		
		case ( state )
		ST_IDLE: begin
			if ( ref_req ) begin				
				// REF
				next_cs  = 1'b0;
				next_ras = 1'b0;
				next_cas = 1'b0;
				next_we  = 1'b1;
				
				next_ref_req = 1'b0;
				
				// next state
				next_counter = TRFC_CYCLE;
				next_state   = ST_REFRESH;
			end
			else if ( wb_stb_i ) begin
				// ACT
				next_cs  = 1'b0;
				next_ras = 1'b0;
				next_cas = 1'b1;
				next_we  = 1'b1;
				next_ba  = ba_adr;
				next_a   = col_adr;
				
				// next state
				next_counter = TRCD_CYCLE;
				next_state   = ST_ACTIVE;
			end
		end
		
		ST_REFRESH: begin
			if ( count_end ) begin
				next_state = ST_IDLE;
			end
		end
		
		ST_ACTIVE: begin
			if ( count_end ) begin
				if ( wb_we_i ) begin
					// WRITEA
					next_cs    = 1'b0;
					next_ras   = 1'b1;
					next_cas   = 1'b0;
					next_we    = 1'b0;
					next_ba    = ba_adr;
					next_a     = row_adr;
					next_a[10] = 1'b1;
					
					next_write[1] = 1'b1;
					
					// next state
					next_counter = TRAS_CYCLE + TRP_CYCLE + 1;
					next_state   = ST_PRECHARGE;
				end
				else begin
					// READA
					next_cs    = 1'b0;
					next_ras   = 1'b1;
					next_cas   = 1'b0;
					next_we    = 1'b1;
					next_ba    = ba_adr;
					next_a     = row_adr;
					next_a[10] = 1'b1;

					next_read[REG_READ_WIDTH-1] = 1'b1;
					
					// next state
					next_counter = TRAS_CYCLE + TRP_CYCLE + 1;
					next_state   = ST_PRECHARGE;				
				end
			end
		end
		
		ST_PRECHARGE: begin
			if ( count_end ) begin
				next_state   = ST_IDLE;	
			end
		end
		endcase
		
		next_ref_req   = (next_ref_counter == 0);
		next_count_end = (next_counter == 0);
	end
	

	
	// -----------------------------
	//  write
	// -----------------------------
	
	// dq
	wire							dq_write_en;
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_write_even;
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_write_odd;
	assign dq_write_en   = reg_write[0];
//	assign dq_write_even = wb_dat_i[SDRAM_DQ_WIDTH +: SDRAM_DQ_WIDTH];
//	assign dq_write_odd  = wb_dat_i[0              +: SDRAM_DQ_WIDTH];
	assign dq_write_even = wb_dat_i[(SDRAM_DQ_WIDTH*2)-1:SDRAM_DQ_WIDTH*1];
	assign dq_write_odd  = wb_dat_i[(SDRAM_DQ_WIDTH*1)-1:SDRAM_DQ_WIDTH*0];
	
	// dm
	wire	[SDRAM_DM_WIDTH-1:0]	dm_write_even;
	wire	[SDRAM_DM_WIDTH-1:0]	dm_write_odd;
//	assign dm_write_even = ~wb_sel_i[SDRAM_DM_WIDTH +: SDRAM_DM_WIDTH];
//	assign dm_write_odd  = ~wb_sel_i[0              +: SDRAM_DM_WIDTH];
	assign dm_write_even = ~wb_sel_i[(SDRAM_DM_WIDTH*2)-1:SDRAM_DM_WIDTH*1];
	assign dm_write_odd  = ~wb_sel_i[(SDRAM_DM_WIDTH*1)-1:SDRAM_DM_WIDTH*0];
	
	// dqs
	reg								dqs_write_en;
	reg								dqs_write_end;
	always @( negedge clk or posedge reset ) begin
		if ( reset ) begin
			dqs_write_en  <= 1'b0;
			dqs_write_end <= 1'b0;
		end
		else begin
			dqs_write_en  <= (reg_write != 0);
			dqs_write_end <= reg_write[0];
		end
	end
		
	
	
	// -----------------------------
	//  Read
	// -----------------------------

	wire	[SDRAM_DQ_WIDTH-1:0]	dq_read_even;
	wire	[SDRAM_DQ_WIDTH-1:0]	dq_read_odd;
	
	reg		[WB_DAT_WIDTH-1:0]		wb_dat_o;
	always @( posedge clk ) begin
//		wb_dat_o[SDRAM_DQ_WIDTH +: SDRAM_DQ_WIDTH] <= dq_read_even;
//		wb_dat_o[0              +: SDRAM_DQ_WIDTH] <= dq_read_odd;
		wb_dat_o[(SDRAM_DQ_WIDTH*2)-1:SDRAM_DQ_WIDTH*1] <= dq_read_even;
		wb_dat_o[(SDRAM_DQ_WIDTH*1)-1:SDRAM_DQ_WIDTH*0] <= dq_read_odd;
	end
	
	assign wb_ack_o = reg_read[0] | reg_write[0];
	
	
	
	// -----------------------------
	//  I/O
	// -----------------------------

	ddr_sdram_io
			#(
				.SDRAM_BA_WIDTH		(SDRAM_BA_WIDTH),
				.SDRAM_A_WIDTH		(SDRAM_A_WIDTH), 
				.SDRAM_DQ_WIDTH		(SDRAM_DQ_WIDTH),
				.SDRAM_DM_WIDTH		(SDRAM_DM_WIDTH),
				.SDRAM_DQS_WIDTH	(SDRAM_DQS_WIDTH)
			)
		i_ddr_sdram_io
			(
				.reset				(reset),
				.clk				(clk),
				.clk90				(clk90),
				
				.cke				(reg_cke),
				.cs					(reg_cs),
				.ras				(reg_ras),
				.cas				(reg_cas),
				.we					(reg_we),
				.ba					(reg_ba),
				.a					(reg_a),
				.dq_write_en		(dq_write_en),
				.dq_write_even		(dq_write_even),
				.dq_write_odd		(dq_write_odd),
				.dq_read_even		(dq_read_even),
				.dq_read_odd		(dq_read_odd),
				.dm_write_even		(dm_write_even),
				.dm_write_odd		(dm_write_odd),
				.dqs_write_en		(dqs_write_en),
				.dqs_write_end		(dqs_write_end),
				
				.ddr_sdram_ck_p		(ddr_sdram_ck_p),
				.ddr_sdram_ck_n		(ddr_sdram_ck_n),
				.ddr_sdram_cke		(ddr_sdram_cke),
				.ddr_sdram_cs		(ddr_sdram_cs),
				.ddr_sdram_ras		(ddr_sdram_ras),
				.ddr_sdram_cas		(ddr_sdram_cas),
				.ddr_sdram_we		(ddr_sdram_we),
				                   
				.ddr_sdram_ba		(ddr_sdram_ba),
				.ddr_sdram_a		(ddr_sdram_a),
				.ddr_sdram_dm		(ddr_sdram_dm),
				.ddr_sdram_dq		(ddr_sdram_dq),
				.ddr_sdram_dqs		(ddr_sdram_dqs)
			);
	
	
endmodule

