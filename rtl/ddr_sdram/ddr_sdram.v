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

	parameter	SDRAM_BA_WIDTH = 2;
	parameter	SDRAM_A_WIDTH  = 13;
	parameter	SDRAM_DQ_WIDTH = 16;
	
	parameter	WB_ADR_WIDTH   = 10;
	parameter	WB_DAT_WIDTH   = (SDRAM_DQ_WIDTH * 2);
	localparam	WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8);
	
	
	// system
	input						clk;
	input						clk90;
	input						reset;
	input						endian;
	
	// wishbone
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	// DDR-SDRAM
	output	[12:0]				ddr_sdram_a;
	inout	[15:0]				ddr_sdram_dq;
	output	[1:0]				ddr_sdram_ba;
	output						ddr_sdram_cas;
	output						ddr_sdram_ck_n;
	output						ddr_sdram_ck_p;
	output						ddr_sdram_cke;
	output						ddr_sdram_cs;
	output	[1:0]				ddr_sdram_dm;
	inout	[1:0]				ddr_sdram_dqs;
	output						ddr_sdram_ras;
	output						ddr_sdram_we;

	// state
	parameter	ST_INIT_WAIT     = 0;
	parameter	ST_INIT_PALL     = 0;
	parameter	ST_INIT_REFRESH1 = 0;
	parameter	ST_INIT_REFRESH2 = 0;
	parameter	ST_INIT_MRS      = 0;
	
	parameter	ST_IDLE       = 0;
	parameter	ST_REFRESH    = 1;
	parameter	ST_ACTIVATING = 2;
	parameter	ST_ACTIVE     = 3;
	parameter	ST_READ       = 4;
	parameter	ST_WRITE      = 5;
	parameter	ST_PRECHARGE  = 6;
	
	
	
	
endmodule

