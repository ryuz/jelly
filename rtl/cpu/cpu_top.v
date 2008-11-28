// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// CPU top
module cpu_top
		(
			reset, clk, clk_x2,
			endian,
			vect_reset, vect_interrupt, vect_exception,
			interrupt_req, interrupt_ack,
			wb_adr_o, wb_dat_i, wb_dat_o, wb_we_o, wb_sel_o, wb_stb_o, wb_ack_i,
			wb_dbg_adr_i, wb_dbg_dat_i, wb_dbg_dat_o, wb_dbg_we_i, wb_dbg_sel_i, wb_dbg_stb_i, wb_dbg_ack_o,
			pause
		);
	parameter	USE_DBUGGER     = 1'b1;
	parameter	USE_EXC_SYSCALL = 1'b1;
	parameter	USE_EXC_BREAK   = 1'b1;
	parameter	USE_EXC_RI      = 1'b1;
	parameter	GPR_TYPE        = 0;

	
	// system
	input			reset;
	input			clk;
	input			clk_x2;

	// endian
	input			endian;
	
	// vector
	input	[31:0]	vect_reset;
	input	[31:0]	vect_interrupt;
	input	[31:0]	vect_exception;

	// interrupt
	input			interrupt_req;
	output			interrupt_ack;
	
	// bus (wishbone)
	output	[31:2]	wb_adr_o;
	input	[31:0]	wb_dat_i;
	output	[31:0]	wb_dat_o;
	output			wb_we_o;
	output	[3:0]	wb_sel_o;
	output			wb_stb_o;
	input			wb_ack_i;
	
	// debug port (wishbone)
	input	[3:0]	wb_dbg_adr_i;
	input	[31:0]	wb_dbg_dat_i;
	output	[31:0]	wb_dbg_dat_o;
	input			wb_dbg_we_i;
	input	[3:0]	wb_dbg_sel_i;
	input			wb_dbg_stb_i;
	output			wb_dbg_ack_o;
	
	// control
	input			pause;
	
	
	
	// Instruction bus (Whishbone)
	wire	[31:2]	wb_inst_adr_o;
	wire	[31:0]	wb_inst_dat_i;
	wire	[31:0]	wb_inst_dat_o;
	wire			wb_inst_we_o;
	wire	[3:0]	wb_inst_sel_o;
	wire			wb_inst_stb_o;
	wire			wb_inst_ack_i;
	
	// Data bus (Whishbone)
	wire	[31:2]	wb_data_adr_o;
	wire	[31:0]	wb_data_dat_i;
	wire	[31:0]	wb_data_dat_o;
	wire			wb_data_we_o;
	wire	[3:0]	wb_data_sel_o;
	wire			wb_data_stb_o;
	wire			wb_data_ack_i;
	
	
	cpu_core
			#(
				.USE_DBUGGER    	(USE_DBUGGER),
				.USE_EXC_SYSCALL	(USE_EXC_SYSCALL),
				.USE_EXC_BREAK		(USE_EXC_BREAK),
				.USE_EXC_RI			(USE_EXC_RI),
				.GPR_TYPE			(GPR_TYPE)
			)
		i_cpu_core
			(
				.reset				(reset),
				.clk				(clk),
				.clk_x2				(clk_x2),

				.endian				(endian),
                              
				.vect_reset			(vect_reset),
				.vect_interrupt		(vect_interrupt),
				.vect_exception		(vect_exception),

				.interrupt_req		(interrupt_req),
				.interrupt_ack		(interrupt_ack),
				
				.wb_inst_adr_o		(wb_inst_adr_o),
				.wb_inst_dat_i		(wb_inst_dat_i),
				.wb_inst_dat_o		(wb_inst_dat_o),
				.wb_inst_we_o		(wb_inst_we_o),
				.wb_inst_sel_o		(wb_inst_sel_o),
				.wb_inst_stb_o		(wb_inst_stb_o),
				.wb_inst_ack_i		(wb_inst_ack_i),
				                
				.wb_data_adr_o		(wb_data_adr_o),
				.wb_data_dat_i		(wb_data_dat_i),
				.wb_data_dat_o		(wb_data_dat_o),
				.wb_data_we_o		(wb_data_we_o),
				.wb_data_sel_o		(wb_data_sel_o),
				.wb_data_stb_o		(wb_data_stb_o),
				.wb_data_ack_i		(wb_data_ack_i),

				.wb_dbg_adr_i		(wb_dbg_adr_i),
				.wb_dbg_dat_i		(wb_dbg_dat_i),
				.wb_dbg_dat_o		(wb_dbg_dat_o),
				.wb_dbg_we_i		(wb_dbg_we_i),
				.wb_dbg_sel_i		(wb_dbg_sel_i),
				.wb_dbg_stb_i		(wb_dbg_stb_i),
				.wb_dbg_ack_o		(wb_dbg_ack_o),
				
				.pause				(pause)
			);
	
	
	// arbiter
	reg		reg_busy;
	reg		reg_sw;
	wire	sw;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_busy <= 1'b0;
			reg_sw   <= 1'bx;
		end
		else begin
			reg_busy <= wb_stb_o & !wb_ack_i;
			
			if ( !reg_busy ) begin
				reg_sw <= sw;
			end
		end
	end
	assign sw = reg_busy ? reg_sw : wb_data_stb_o;
	
	
	assign wb_adr_o = sw ? wb_data_adr_o : wb_inst_adr_o;
	assign wb_dat_o = sw ? wb_data_dat_o : wb_inst_dat_o;
	assign wb_we_o  = sw ? wb_data_we_o  : wb_inst_we_o;
	assign wb_sel_o = sw ? wb_data_sel_o : wb_inst_sel_o;
	assign wb_stb_o = sw ? wb_data_stb_o : wb_inst_stb_o;
	
	assign wb_inst_dat_i = wb_dat_i;
	assign wb_inst_ack_i = !sw ? wb_ack_i : 1'b0;
	
	assign wb_data_dat_i = wb_dat_i;
	assign wb_data_ack_i = sw ? wb_ack_i : 1'b0;
	
	
endmodule
