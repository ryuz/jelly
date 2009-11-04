// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// wishbone_arbiter
module jelly_wishbone_arbiter
		#(
			parameter							WB_ADR_WIDTH = 30,
			parameter							WB_DAT_WIDTH = 32,
			parameter							WB_SEL_WIDTH = (WB_DAT_WIDTH / 8)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			
			// cpu side port 0
			input	wire	[WB_ADR_WIDTH-1:0]	wb_slave0_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_slave0_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_slave0_dat_o,
			input	wire						wb_slave0_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_slave0_sel_i,
			input	wire						wb_slave0_stb_i,
			output	wire						wb_slave0_ack_o,
			
			// cpu side port 1
			input	wire	[WB_ADR_WIDTH-1:0]	wb_slave1_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_slave1_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_slave1_dat_o,
			input	wire						wb_slave1_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_slave1_sel_i,
			input	wire						wb_slave1_stb_i,
			output	wire						wb_slave1_ack_o,
			
			// memory side port
			output	wire	[WB_ADR_WIDTH-1:0]	wb_master_adr_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_master_dat_o,
			output	wire						wb_master_we_o,
			output	wire	[WB_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire						wb_master_stb_o,
			input	wire						wb_master_ack_i
		);
	
	
	// arbiter
	reg			reg_busy;
	reg			reg_sw;
	wire		sw;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			reg_busy <= 1'b0;
			reg_sw   <= 1'bx;
		end
		else begin
			reg_busy <= wb_master_stb_o & !wb_master_ack_i;
			
			if ( !reg_busy ) begin
				reg_sw <= sw;
			end
		end
	end
	assign sw = reg_busy ? reg_sw : wb_slave1_stb_i;
	
	
	assign wb_master_adr_o = sw ? wb_slave1_adr_i : wb_slave0_adr_i;
	assign wb_master_dat_o = sw ? wb_slave1_dat_i : wb_slave0_dat_i;
	assign wb_master_we_o  = sw ? wb_slave1_we_i  : wb_slave0_we_i;
	assign wb_master_sel_o = sw ? wb_slave1_sel_i : wb_slave0_sel_i;
	assign wb_master_stb_o = sw ? wb_slave1_stb_i : wb_slave0_stb_i;
	
	assign wb_slave0_dat_o = wb_master_dat_i;
	assign wb_slave0_ack_o = !sw ? wb_master_ack_i : 1'b0;
	
	assign wb_slave1_dat_o = wb_master_dat_i;
	assign wb_slave1_ack_o = sw ? wb_master_ack_i : 1'b0;
	
endmodule
