// ----------------------------------------------------------------------------
//  Jelly -- simulation model
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------



`timescale 1ns / 1ps


module ram_model
		(
			reset, clk,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	parameter	WB_ADR_WIDTH  = 18;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	parameter	MEM_SIZE = (1 << WB_ADR_WIDTH);
	
	
	// system
	input						reset;
	input						clk;
	
	// wishbone
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	
	reg		[WB_DAT_WIDTH-1:0]	mem		[0:MEM_SIZE-1];
	
		
	integer		i;
	always @( posedge clk ) begin
		if ( wb_stb_i ) begin
			if ( wb_we_i ) begin
				for ( i = 0; i < WB_SEL_WIDTH; i = i + 1 ) begin
					if ( wb_sel_i[i] ) begin
						mem[wb_adr_i][i*8 +: 8] <= wb_dat_i[i*8 +: 8];
					end
				end
			end
		end				
	end
	
	assign wb_dat_o = mem[wb_adr_i];
	assign wb_ack_o = 1'b1;
	
endmodule

