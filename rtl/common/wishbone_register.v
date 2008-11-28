// --------------------------------------------------------------------------
//  Common components
//   Register for wishbone
//
//                                 Copyright (C) 2007-2008 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// register
module wishbone_register
		(
			reset, clk,
			wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i,
			data_in, data_sel, data_out
		);
	
	parameter	DATA_WIDTH    = 32;	
	parameter	INITIAL_VALUE = 0;
	parameter	READONLY_MASK = 0;
	
	localparam	WB_DAT_WIDTH = DATA_WIDTH;
	localparam	WB_SEL_WIDTH = WB_DAT_WIDTH / 8;
	
	
	// system
	input						clk;
	input						reset;
	
	// wishbone
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	
	
	// data port
	input	[WB_DAT_WIDTH-1:0]	data_in;
	input	[WB_DAT_WIDTH-1:0]	data_sel;
	output	[WB_DAT_WIDTH-1:0]	data_out;
	
	
	// register
	reg		[DATA_WIDTH-1:0]	reg_data;
	
	
	
	// wb_mask
	wire	[WB_DAT_WIDTH-1:0]	wb_mask;
	integer						i, j;
	always @* begin
		for ( i = 0; i < WB_SEL_WIDTH; i = i + 1 ) begin
			for ( j = 0; j < 8; j = j + 1 ) begin
				wb_mask[i*8+j] = wb_sel_i[i];
			end
		end
	end
	
	
	// register
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_data <= INITIAL_VALUE;
		end
		else begin
			if ( wb_stb_i & wb_we_i ) begin
				reg_data <= (reg_data & ~wb_mask & READONLY_MASK) | (wb_dat_i & wb_mask & ~READONLY_MASK);
			end
			else begin
				reg_data <= (reg_data & ~data_sel) | (data_in & data_sel);
			end
		end
	end
	
	assign data_out = (wb_stb_i & ~wb_we_i) ? reg_data : {WB_DAT_WIDTH{1'b0}};
	
endmodule


// End of file
