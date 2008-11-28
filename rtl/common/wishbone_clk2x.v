// ---------------------------------------------------------------------------
//  Common components
//   whishbone x2 clock bridge
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// whishbone x2 clock bridge
module wishbone_clk2x
		(
			reset, clk, clk2x,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o,
			wb_2x_adr_o, wb_2x_dat_o, wb_2x_dat_i, wb_2x_we_o, wb_2x_sel_o, wb_2x_stb_o, wb_2x_ack_i
		);
	
	parameter	WB_ADR_WIDTH  = 30;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	input						clk;
	input						clk2x;
	input						reset;
	
	// wishbone
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	// wishbone
	output	[WB_ADR_WIDTH-1:0]	wb_2x_adr_o;
	output	[WB_DAT_WIDTH-1:0]	wb_2x_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_2x_dat_i;
	output						wb_2x_we_o;
	output	[WB_SEL_WIDTH-1:0]	wb_2x_sel_o;
	output						wb_2x_stb_o;
	input						wb_2x_ack_i;
	
	
	reg		[WB_DAT_WIDTH-1:0]	wb_dat_o;
	reg							wb_ack_o;
	
	reg		[WB_ADR_WIDTH-1:0]	wb_2x_adr_o;
	reg		[WB_DAT_WIDTH-1:0]	wb_2x_dat_o;
	reg							wb_2x_we_o;
	reg		[WB_SEL_WIDTH-1:0]	wb_2x_sel_o;
	reg							wb_2x_stb_o;
	
	
	reg							st_idle;
	reg							st_busy;
	reg							st_end;

	always @( posedge clk or posedge reset ) begin
		if ( reset ) begin
			wb_ack_o <= 1'b0;
		end
		else begin
			if ( wb_stb_i & ~wb_ack_o & st_end ) begin
				wb_ack_o <= 1'b1;
			end
			else begin
				wb_ack_o <= 1'b0;
			end
		end
	end
	
	
	always @( posedge clk2x or posedge reset ) begin
		if ( reset ) begin
			st_idle <= 1'b1;
			st_busy <= 1'b0;
			st_end  <= 1'b0;
			
			wb_2x_stb_o <= 1'b0;
		end
		else begin
			if ( st_idle ) begin
				if ( wb_stb_i & ~wb_ack_o ) begin
					wb_2x_adr_o <= wb_adr_i;
					wb_2x_dat_o <= wb_dat_i;
					wb_2x_we_o  <= wb_we_i;
					wb_2x_sel_o <= wb_sel_i;
					wb_2x_stb_o <= 1'b1;
					
					st_idle <= 1'b0;
					st_busy <= 1'b1;
				end
			end
			else if ( st_busy ) begin
				wb_dat_o <= wb_2x_dat_i;
				if ( wb_2x_ack_i ) begin
					wb_2x_stb_o <= 1'b0;
					st_busy     <= 1'b0;
					st_end      <= 1'b1;
				end
			end
			else if ( st_end ) begin
				if ( wb_ack_o ) begin
					st_end  <= 1'b0;
					st_idle <= 1'b1;
				end
			end
		end
	end
	
endmodule


// End of file
