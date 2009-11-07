// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    block sram interface
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



module jelly_wishbone_to_ram
		#(
			parameter	WB_ADR_WIDTH  = 12,
			parameter	WB_DAT_WIDTH  = 32,
			parameter	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			// wishbone
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o,
			
			// ram
			output	wire						ram_en,
			output	wire						ram_we,
			output	wire	[WB_ADR_WIDTH-1:0]	ram_addr,
			output	wire	[WB_DAT_WIDTH-1:0]	ram_wdata,
			input	wire	[WB_DAT_WIDTH-1:0]	ram_rdata
		);
	
	
	// write mask
	function [WB_DAT_WIDTH-1:0] make_write_mask;
	input	[WB_SEL_WIDTH-1:0]	sel;
	integer					i, j;
	begin
		for ( i = 0; i < SEL_WIDTH; i = i + 1 ) begin
			for ( j = 0; j < 8; j = j + 1 ) begin
				make_write_mask[i*8 + j] = sel[i];
			end
		end
	end
	endfunction
	
	wire	write_mask;
	assign write_mask = make_write_mask(wb_sel_i);
	
	
	reg			reg_ack;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_ack <= 1'b0;
		end
		else begin
			reg_ack <= !reg_ack & wb_stb_i;
		end
	end
	
	assign wb_dat_o  = ram_rdata;
	assign wb_ack_o  = reg_ack;
	
	assign ram_en    = wb_stb_i;
	assign ram_we    = wb_we_i & reg_ack;
	assign ram_addr  = wb_adr_i;
	assign ram_wdata = (ram_rdata & ~write_mask) | (wb_dat_i & write_mask);
	
	
endmodule


// end of file
