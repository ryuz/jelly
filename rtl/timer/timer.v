// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    Timmer
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly_timer
		(
			reset, clk,
			interrupt_req,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	WB_ADR_WIDTH  = 2;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	// system
	input						clk;
	input						reset;
	
	// irq
	output						interrupt_req;
	
	// control port (wishbone)
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	reg		[31:0]		reg_counter;
	reg		[31:0]		reg_compare;
	
	wire				compare_match;
	assign compare_match = (reg_counter == reg_compare);
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_counter <= 0;
			reg_compare <= 50000 - 1;
		end
		else begin
			if ( compare_match ) begin
				reg_counter <= 0;
			end
			else begin
				reg_counter <= reg_counter + 1;
			end
		end
	end
	
	assign interrupt_req = compare_match;


	assign wb_dat_o = 0;
	assign wb_ack_o = 1'b1;

endmodule

