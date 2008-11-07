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
	parameter	SIMULATION      = 1'b1;
	parameter	CLK_RATE        = 10.0;
	parameter	INIT_WAIT_CYCLE = (200000 + (CLK_RATE - 1)) / CLK_RATE;
	
	parameter	SDRAM_BA_WIDTH  = 2;
	parameter	SDRAM_A_WIDTH   = 13;
	parameter	SDRAM_DQ_WIDTH  = 16;
	parameter	SDRAM_DM_WIDTH  = SDRAM_DQ_WIDTH / 8;
	parameter	SDRAM_DQS_WIDTH = SDRAM_DQ_WIDTH / 8;
	
	parameter	SDRAM_COL_WIDTH = 10;
	parameter	SDRAM_ROW_WIDTH = 13;
	
	parameter	WB_ADR_WIDTH    = 10;
	parameter	WB_DAT_WIDTH    = (SDRAM_DQ_WIDTH * 2);
	localparam	WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8);
	
	
	// system
	input							clk;
	input							clk90;
	input							reset;
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
	
	
	
	// initializer
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
	
	
	
	parameter	TRCD_CYCLE = 2 - 1;	//	15ns
		
	// state
	parameter	ST_IDLE       = 0;
	parameter	ST_REFRESH    = 1;
	parameter	ST_ACTIVATING = 2;
	parameter	ST_ACTIVE     = 3;
	parameter	ST_READ       = 4;
	parameter	ST_WRITE      = 5;
	parameter	ST_PRECHARGE  = 6;
	
	wire						refresh_req;
	
	reg		[3:0]				state;
	reg		[3:0]				counter;
	reg							count_end;

	reg							reg_cke;
	reg							reg_cs;
	reg							reg_ras;
	reg							reg_cas;
	reg							reg_we;
	reg		[1:0]				reg_ba;
	reg		[12:0]				reg_a;
	
	always @( posedge clk or posedge reset ) begin
		if ( reset ) begin
			state     <= ST_IDLE;
			counter   <= 0;
			count_end <= 1'b0;
			
			reg_cke       <= 1'b0;
			reg_cs        <= 1'b1;
			reg_ras       <= 1'b1;
			reg_cas       <= 1'b1;
			reg_we        <= 1'b1;
			reg_ba        <= {SDRAM_BA_WIDTH{1'b0}};
			reg_a         <= {SDRAM_A_WIDTH{1'b0}};
		end
		else begin
			if ( initializing ) begin
				reg_cke <= init_cke;
				reg_cs  <= init_cs;
				reg_ras <= init_ras;
				reg_cas <= init_cas;
				reg_we  <= init_we;
				reg_ba  <= init_ba;
				reg_a   <= init_a;
			end
			else begin
			end
		end
	end
	
	/*
				reg_cke   <= 1'b1;
				counter   <= counter - 1;
				count_end <= (counter == 1);
				
				case ( state )
				ST_IDLE; begin
					counter <= 0;
					if ( refresh_req ) begin
						// REF
						reg_cs      <= 1'b0;
						reg_ras     <= 1'b0;
						reg_cas     <= 1'b0;
						reg_we      <= 1'b1;
						
						// next state
						counter <= 40;
						state   <= ST_REFRESH;
					end
					else if ( wb_stb_i ) begin
						// ACT
						reg_cs      <= 1'b0;
						reg_ras     <= 1'b0;
						reg_cas     <= 1'b1;
						reg_we      <= 1'b1;
						reg_ba      <= wb_adr_i[SDRAM_BA_WIDTH+SDRAM_ROW_WIDTH+SDRAM_COL_WIDTH-2:SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH-1];
						reg_a       <= wb_adr_i[SDRAM_COL_WIDTH+SDRAM_ROW_WIDTH-2:SDRAM_COL_WIDTH-1];
						
						// next state
						counter <= TRCD_CYCLE;
						state   <= ST_REFRESH;
					end
					else begin
						reg_cs      <= 1'b1;
					end
				end
				
				ST_REFRESH: begin
					reg_cs <= 1'b1;
					if ( 
				end
				
				
				ST_ACTIVATING
				ST_ACTIVE    
				ST_READ      
				ST_WRITE     
				ST_PRECHARGE 
				
				
				
				
				
					
			end
		end
	end
	*/
	

	assign ddr_sdram_ck_p = ~clk;
	assign ddr_sdram_ck_n = clk;
	assign ddr_sdram_cke  = reg_cke;
	assign ddr_sdram_cs   = reg_cs;
	assign ddr_sdram_ras  = reg_ras;
	assign ddr_sdram_cas  = reg_cas;
	assign ddr_sdram_we   = reg_we;
	assign ddr_sdram_ba   = reg_ba;
	assign ddr_sdram_a    = reg_a;
	
	assign ddr_sdram_dm   = 0;
	assign ddr_sdram_dq   = {SDRAM_DQ_WIDTH{1'bz}};
	assign ddr_sdram_dqs  = {SDRAM_DQS_WIDTH{1'bz}};

	
	
	
endmodule

