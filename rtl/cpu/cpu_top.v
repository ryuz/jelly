// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// CPU top
module cpu_top
		(
			reset, clk, clk_x2,
			endian,
			vect_reset, vect_interrupt, vect_exception,
			interrupt_req, interrupt_ack,
			wb_adr_o, wb_dat_i, wb_dat_o, wb_we_o, wb_sel_o, wb_stb_o, wb_ack_i,
			pause
		);
	
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
	
	// bus (Whishbone)
	output	[31:2]	wb_adr_o;
	input	[31:0]	wb_dat_i;
	output	[31:0]	wb_dat_o;
	output			wb_we_o;
	output	[3:0]	wb_sel_o;
	output			wb_stb_o;
	input			wb_ack_i;
		
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
		i_cpu_core
			(
				.reset			(reset),
				.clk			(clk),
				.clk_x2			(clk_x2),

				.endian			(endian),
                              
				.vect_reset		(vect_reset),
				.vect_interrupt	(vect_interrupt),
				.vect_exception	(vect_exception),

				.interrupt_req	(interrupt_req),
				.interrupt_ack	(interrupt_ack),
				
				.wb_inst_adr_o	(wb_inst_adr_o),
				.wb_inst_dat_i	(wb_inst_dat_i),
				.wb_inst_dat_o	(wb_inst_dat_o),
				.wb_inst_we_o	(wb_inst_we_o),
				.wb_inst_sel_o	(wb_inst_sel_o),
				.wb_inst_stb_o	(wb_inst_stb_o),
				.wb_inst_ack_i	(wb_inst_ack_i),
				                
				.wb_data_adr_o	(wb_data_adr_o),
				.wb_data_dat_i	(wb_data_dat_i),
				.wb_data_dat_o	(wb_data_dat_o),
				.wb_data_we_o	(wb_data_we_o),
				.wb_data_sel_o	(wb_data_sel_o),
				.wb_data_stb_o	(wb_data_stb_o),
				.wb_data_ack_i	(wb_data_ack_i),
								
				.pause			(1'b0)
			);
	
	
	// arbiter
	reg		reg_busy;
	reg		reg_sw;
	wire	sw;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_busy <= 1'b0;
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
