// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    Asyncronus sram interface
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_asram
		(
			reset, clk,
			asram_cs_n, asram_we_n, asram_oe_n, asram_bls_n, asram_a, asram_d,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	WB_ADR_WIDTH  = 18;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	input						clk;
	input						reset;
	
	// asram
	output						asram_cs_n;
	output						asram_we_n;
	output						asram_oe_n;
	output	[WB_SEL_WIDTH-1:0]	asram_bls_n;
	output	[WB_ADR_WIDTH-1:0]	asram_a;
	inout	[WB_DAT_WIDTH-1:0]	asram_d;
	
	// wishbone
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	

	reg							asram_cs_n;
	reg							asram_we_n;
	reg							asram_oe_n;
	reg		[WB_SEL_WIDTH-1:0]	asram_bls_n;
	reg		[WB_ADR_WIDTH-1:0]	asram_a;
	reg		[WB_DAT_WIDTH-1:0]	asram_wdata;
	
	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o;
	
	parameter	ACCESS_CYCLE = 1;
	reg							st_idle;
	reg		[ACCESS_CYCLE-1:0]	st_access;
	reg							st_end;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			st_idle     <= 1'b1;
			st_access   <= {ACCESS_CYCLE{1'b0}};
			st_end      <= 1'b0;
			
			asram_cs_n  <= 1'b1;
			asram_we_n  <= 1'b1;
			asram_oe_n  <= 1'b1;
			asram_bls_n <= {WB_SEL_WIDTH{1'b1}};
			asram_a     <= {WB_DAT_WIDTH{1'b0}};
		end
		else begin
			// state
			if ( wb_stb_i ) begin
				st_idle   <= st_end;
				st_access <= {st_access, st_idle};
				st_end    <= st_access[ACCESS_CYCLE-1];
			end
						
			// asram_cs_n
			if ( st_idle & wb_stb_i ) begin
				asram_cs_n <= 1'b0;
			end
			else if ( st_access[ACCESS_CYCLE-1] ) begin
				asram_cs_n <= 1'b1;
			end
			
			// asram_we_n
			if ( st_idle & wb_stb_i & wb_we_i ) begin
				asram_we_n <= 1'b0;
			end
			else if ( st_access[ACCESS_CYCLE-1] ) begin
				asram_we_n <= 1'b1;
			end
			
			// asram_oe_n
			if ( st_idle & wb_stb_i & ~wb_we_i ) begin
				asram_oe_n <= 1'b0;
			end
			else if ( st_access[ACCESS_CYCLE-1] ) begin
				asram_oe_n <= 1'b1;
			end
			
			// asram_bls_n
			asram_bls_n <= ~wb_sel_i;
			
			// asram_a
			asram_a <= wb_adr_i;
			
			// asram_wdata
			asram_wdata <= wb_dat_i;
			
			// wb_dat_o
			wb_dat_o <= asram_d;
		end
	end
	
	assign asram_d = ~asram_we_n ? asram_wdata : {WB_DAT_WIDTH{1'bz}};
	
	assign wb_ack_o = st_end;

	
	/*
	reg							busy;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			busy  <= 1'b0;
		end
		else begin
			if ( wb_stb_i & ~wb_ack_o ) begin
				busy  <= 1'b1;
			end
			else begin
				busy  <= 1'b0;
			end
		end
	end
	
	assign asram_cs_n  = ~wb_stb_i;
	assign asram_we_n  = ~(wb_stb_i &  wb_we_i & ~busy);
	assign asram_oe_n  = ~(wb_stb_i & ~wb_we_i);
	assign asram_bls_n = ~wb_sel_i;
	assign asram_a     = wb_adr_i;
	assign asram_d     = ~asram_we_n ? wb_dat_i : {WB_DAT_WIDTH{1'bz}};

	assign wb_dat_o    = asram_d;
	assign wb_ack_o    = ~(wb_stb_i & ~busy);
	*/
	
endmodule

