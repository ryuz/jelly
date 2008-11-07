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
			ddr_sdram_a, ddr_sdram_dq, ddr_sdram_ba, ddr_sdram_cas, ddr_sdram_ck_n, ddr_sdram_ck_p, ddr_sdram_cke, ddr_sdram_cs,
			ddr_sdram_dm, ddr_sdram_dqs, ddr_sdram_ras, ddr_sdram_we
		);
	parameter	CLK_RATE        = 10.0;
	parameter	INIT_WAIT_CYCLE = (200000 + (CLK_RATE - 1)) / CLK_RATE;
	
	parameter	SDRAM_BA_WIDTH  = 2;
	parameter	SDRAM_A_WIDTH   = 13;
	parameter	SDRAM_DQ_WIDTH  = 16;
	parameter	SDRAM_DM_WIDTH  = SDRAM_DQ_WIDTH / 8;
	parameter	SDRAM_DQS_WIDTH = SDRAM_DQ_WIDTH / 8;
	
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
	inout	[SDRAM_DQ_WIDTH-1:0]	ddr_sdram_dq;
	output	[SDRAM_DQ_WIDTH-1:0]	ddr_sdram_dm;
	inout	[SDRAM_DQS_WIDTH-1:0]	ddr_sdram_dqs;
	
	
	// initial state
	parameter	ST_INIT_WAIT     = 0;
	parameter	ST_INIT_CKE      = 1;
	parameter	ST_INIT_PALL1    = 2;
	parameter	ST_INIT_EMRS     = 3;
	parameter	ST_INIT_MRS1     = 4;
	parameter	ST_INIT_PALL2    = 5;
	parameter	ST_INIT_REFRESH1 = 6;
	parameter	ST_INIT_REFRESH2 = 7;
	parameter	ST_INIT_MRS2     = 8;
	
	reg							init;
	reg		[3:0]				init_state;
	reg		[15:0]				init_counter;
	reg							init_count_end;

	reg							init_cke;
	reg							init_cs;
	reg							init_ras;
	reg							init_cas;
	reg							init_we;
	reg		[1:0]				init_ba;
	reg		[12:0]				init_a;

	always @( posedge clk or posedge reset ) begin
		if ( reset ) begin
			init           <= 1'b1;
			init_state     <= ST_INIT_WAIT;
			init_counter   <= INIT_WAIT_CYCLE;
			init_count_end <= 1'b0;

			init_cke       <= 1'b0;
			init_cs        <= 1'b1;
			init_ras       <= 1'b1;
			init_cas       <= 1'b1;
			init_we        <= 1'b1;
			init_ba        <= {SDRAM_BA_WIDTH{1'b0}};
			init_a         <= {SDRAM_A_WIDTH{1'b0}};
		end
		else begin
			init_counter   <= init_counter - 1;
			init_count_end <= (init_counter == 0);
			
			case ( init_state )
			ST_INIT_WAIT:
				begin
					if ( init_count_end ) begin
						init_counter <= 40;
						init_cke     <= 1'b1;
						init_state   <= ST_INIT_CKE ;
					end
				end
			
			ST_INIT_CKE:
				begin
					if ( init_count_end ) begin
						// PALL
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b1;
						init_we      <= 1'b0;
						init_a[10]   <= 1'b1;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_PALL1;						
					end
				end
			
			ST_INIT_PALL1:
				begin
					if ( init_count_end ) begin
						// EMRS
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b0;
						init_we      <= 1'b0;
						init_ba[1:0] <= 2'b01;
						init_a[10]   <= 1'b0;
						init_a[9:0]  <= 10'b00_000_0_000;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_EMRS;
					end
					else begin
						// DSEL
						init_cs      <= 1'b1;
					end
				end

			ST_INIT_EMRS:
				begin
					if ( init_count_end ) begin
						// MRS (DLL reset)
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b0;
						init_we      <= 1'b0;
						init_ba[1:0] <= 2'b01;
						init_a[10]   <= 1'b0;
						init_a[9:0]  <= 10'b10_010_0_001;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_MRS1;
					end
					else begin
						// DSEL
						init_cs      <= 1'b1;
					end
				end
			
			ST_INIT_MRS1:
				begin
					if ( init_count_end ) begin
						// PALL
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b1;
						init_we      <= 1'b0;
						init_a[10]   <= 1'b1;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_PALL2;
					end
					else begin
						// DSEL
						init_cs      <= 1'b1;
					end
				end
				
			ST_INIT_PALL2:
				begin
					if ( init_count_end ) begin
						// REF
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b0;
						init_we      <= 1'b1;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_REFRESH1;
					end
					else begin
						// DSEL
						init_cs      <= 1'b1;
					end
				end

			ST_INIT_REFRESH1:
				begin
					if ( init_count_end ) begin
						// REF
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b0;
						init_we      <= 1'b1;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_REFRESH2;
					end
					else begin
						// DSEL
						init_cs      <= 1'b1;
					end
				end

			ST_INIT_REFRESH2:
				begin
					if ( init_count_end ) begin
						// MRS
						init_cs      <= 1'b0;
						init_ras     <= 1'b0;
						init_cas     <= 1'b0;
						init_we      <= 1'b0;
						init_ba[1:0] <= 2'b01;
						init_a[10]   <= 1'b0;
						init_a[9:0]  <= 10'b00_010_0_001;
						
						// next state
						init_counter <= 40;
						init_state   <= ST_INIT_MRS2;
					end
					else begin
						// DSEL
						init_cs      <= 1'b1;
					end
				end

			ST_INIT_MRS2:
				begin
					if ( init_count_end ) begin
						init    <= 1'b0;
					end
					else begin
						// DSEL
						init_cs <= 1'b1;
					end
				end
				
			default:
				begin
					init           <= 1'bx;
					init_state     <= 3'bxxx;
					init_counter   <= 16'hxxxx;
					init_count_end <= 1'bx;
					init_cke       <= 1'bx;
					init_cs        <= 1'bx;
					init_ras       <= 1'bx;
					init_cas       <= 1'bx;
					init_we        <= 1'bx;
					init_ba        <= {SDRAM_BA_WIDTH{1'bx}};
					init_a         <= {SDRAM_A_WIDTH{1'bx}};
				end
			endcase
		end
	end

		
	// state
	parameter	ST_IDLE       = 0;
	parameter	ST_REFRESH    = 1;
	parameter	ST_ACTIVATING = 2;
	parameter	ST_ACTIVE     = 3;
	parameter	ST_READ       = 4;
	parameter	ST_WRITE      = 5;
	parameter	ST_PRECHARGE  = 6;
	
	reg							init;
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
			reg_cke       <= 1'b0;
			reg_cs        <= 1'b1;
			reg_ras       <= 1'b1;
			reg_cas       <= 1'b1;
			reg_we        <= 1'b1;
			reg_ba        <= {SDRAM_BA_WIDTH{1'b0}};
			reg_a         <= {SDRAM_A_WIDTH{1'b0}};
		end
		else begin
			if ( init ) begin
				reg_cke <= init_cke;
				reg_cs  <= init_cs;
				reg_ras <= init_ras;
				reg_cas <= init_cas;
				reg_we  <= init_we;
				reg_ba  <= init_ba;
				reg_a   <= init_a;
			end
			else begin
				reg_cke <= 1'b1;
				
			end
		end
	end


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

