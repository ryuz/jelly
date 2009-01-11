// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    WISHBONE bus arbiter
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// wishbone_arbiter
module jelly_cpu_wishbone_arbiter
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
			input	wire	[WB_ADR_WIDTH-1:0]	wb_cpu0_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_cpu0_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_cpu0_dat_o,
			input	wire						wb_cpu0_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_cpu0_sel_i,
			input	wire						wb_cpu0_stb_i,
			output	wire						wb_cpu0_ack_o,
			
			// cpu side port 1
			input	wire	[WB_ADR_WIDTH-1:0]	wb_cpu1_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_cpu1_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_cpu1_dat_o,
			input	wire						wb_cpu1_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_cpu1_sel_i,
			input	wire						wb_cpu1_stb_i,
			output	wire						wb_cpu1_ack_o,
			
			// memory side port
			output	wire	[WB_ADR_WIDTH-1:0]	wb_mem_adr_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_mem_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_mem_dat_o,
			output	wire						wb_mem_we_o,
			output	wire	[WB_SEL_WIDTH-1:0]	wb_mem_sel_o,
			output	wire						wb_mem_stb_o,
			input	wire						wb_mem_ack_i
		);
	
	
	// arbiter
	reg			reg_busy;
	reg			reg_sw;
	wire		sw;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_busy <= 1'b0;
			reg_sw   <= 1'bx;
		end
		else begin
			reg_busy <= wb_mem_stb_o & !wb_mem_ack_i;
			
			if ( !reg_busy ) begin
				reg_sw <= sw;
			end
		end
	end
	assign sw = reg_busy ? reg_sw : wb_cpu1_stb_i;
	
	
	assign wb_mem_adr_o = sw ? wb_cpu1_adr_i : wb_cpu0_adr_i;
	assign wb_mem_dat_o = sw ? wb_cpu1_dat_i : wb_cpu0_dat_i;
	assign wb_mem_we_o  = sw ? wb_cpu1_we_i  : wb_cpu0_we_i;
	assign wb_mem_sel_o = sw ? wb_cpu1_sel_i : wb_cpu0_sel_i;
	assign wb_mem_stb_o = sw ? wb_cpu1_stb_i : wb_cpu0_stb_i;
	
	assign wb_cpu0_dat_o = wb_mem_dat_i;
	assign wb_cpu0_ack_o = !sw ? wb_mem_ack_i : 1'b0;
	
	assign wb_cpu1_dat_o = wb_mem_dat_i;
	assign wb_cpu1_ack_o = sw ? wb_mem_ack_i : 1'b0;
	
endmodule
