// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    block sram interface
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_sram
		(
			reset, clk,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	WB_ADR_WIDTH  = 10;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	input						clk;
	input						reset;
	
	// wishbone
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	
	generate
	genvar	i;
	for ( i = 0; i < WB_SEL_WIDTH; i = i + 1 ) begin : ram
		ram_dualport
				#(
					.DATA_WIDTH	(8),
					.ADDR_WIDTH	(WB_ADR_WIDTH)
				)
			i_ram_dualport
				(
					.clk0		(~clk),
					.en0		(wb_stb_i),
					.we0		(wb_we_i & wb_sel_i[i]),
					.addr0		(wb_adr_i),
					.din0		(wb_dat_i[i*8 +: 8]),
					.dout0		(wb_dat_o[i*8 +: 8]),
					
					.clk1		(1'b0),
					.en1		(1'b0),
					.we1		(1'b0),
					.addr1		({WB_ADR_WIDTH{1'b0}}),
					.din1		(8'h00),
					.dout1		()
				);
	end
	endgenerate
	
	assign wb_ack_o = 1'b1;
	
endmodule

