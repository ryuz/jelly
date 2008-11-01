// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// CPU Core
module cpu_core
		(
			reset, clk, clk_x2,
			endian,
			vect_reset, vect_interrupt, vect_exception,
			interrupt_req, interrupt_ack,
			wb_inst_adr_o, wb_inst_dat_i, wb_inst_dat_o, wb_inst_we_o, wb_inst_sel_o, wb_inst_stb_o, wb_inst_ack_i,
			wb_data_adr_o, wb_data_dat_i, wb_data_dat_o, wb_data_we_o, wb_data_sel_o, wb_data_stb_o, wb_data_ack_i,
			wb_dbg_adr_i, wb_dbg_dat_i, wb_dbg_dat_o, wb_dbg_we_i, wb_dbg_sel_i, wb_dbg_stb_i, wb_dbg_ack_o,
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
	
	// Instruction bus (wishbone)
	output	[29:0]	wb_inst_adr_o;
	input	[31:0]	wb_inst_dat_i;
	output	[31:0]	wb_inst_dat_o;
	output			wb_inst_we_o;
	output	[3:0]	wb_inst_sel_o;
	output			wb_inst_stb_o;
	input			wb_inst_ack_i;
	
	// Data bus (wishbone)
	output	[29:0]	wb_data_adr_o;
	input	[31:0]	wb_data_dat_i;
	output	[31:0]	wb_data_dat_o;
	output			wb_data_we_o;
	output	[3:0]	wb_data_sel_o;
	output			wb_data_stb_o;
	input			wb_data_ack_i;

	// Debug port (wishbone)
	input	[3:0]	wb_dbg_adr_i;
	input	[31:0]	wb_dbg_dat_i;
	output	[31:0]	wb_dbg_dat_o;
	input			wb_dbg_we_i;
	input	[3:0]	wb_dbg_sel_i;
	input			wb_dbg_stb_i;
	output			wb_dbg_ack_o;
	
	// control
	input			pause;
	
	

	// -----------------------------
	//  Debug signals
	// -----------------------------
	
	// debug status
	wire			dbg_enable;
	wire			dbg_break_req;
	wire			dbg_break;
	
	// d-bus control
	wire	[31:2]	dbg_wb_data_adr_o;
	wire	[31:0]	dbg_wb_data_dat_i;
	wire	[31:0]	dbg_wb_data_dat_o;
	wire			dbg_wb_data_we_o;
	wire	[3:0]	dbg_wb_data_sel_o;
	wire			dbg_wb_data_stb_o;
	wire			dbg_wb_data_ack_i;

	// i-bus control
	wire	[31:2]	dbg_wb_inst_adr_o;
	wire	[31:0]	dbg_wb_inst_dat_i;
	wire	[3:0]	dbg_wb_inst_sel_o;
	wire			dbg_wb_inst_stb_o;
	wire			dbg_wb_inst_ack_i;
	
	// PC control
	wire			dbg_pc_we;
	wire	[31:0]	dbg_pc_wdata;
	wire	[31:0]	dbg_pc_rdata;
	
	// gpr control
	wire			dbg_gpr_en;
	wire			dbg_gpr_we;
	wire	[4:0]	dbg_gpr_addr;
	wire	[31:0]	dbg_gpr_wdata;
	wire	[31:0]	dbg_gpr_rdata;
	
	// hi/lo control
	wire			dbg_hilo_en;
	wire			dbg_hilo_we;
	wire	[0:0]	dbg_hilo_addr;
	wire	[31:0]	dbg_hilo_wdata;
	wire	[31:0]	dbg_hilo_rdata;
	
	// cop0 control
	wire			dbg_cop0_en;
	wire			dbg_cop0_we;
	wire	[4:0]	dbg_cop0_addr;
	wire	[31:0]	dbg_cop0_wdata;
	wire	[31:0]	dbg_cop0_rdata;
	
	
	
	
	// -----------------------------
	//  Instruction Fetch stage
	// -----------------------------

	wire			interlock;
	
	
	
	// -----------------------------
	//  Instruction Fetch stage
	// -----------------------------

	// IF stage input
	wire			if_in_stall;
	wire			if_in_branch_en;
	wire	[31:0]	if_in_branch_pc;
	
	// IF stage output
	wire			if_out_hazard;
	
	reg				if_out_stall;
	wire	[31:0]	if_out_instruction;
	reg		[31:0]	if_out_pc;
	
	
	// PC
	reg		[31:0]	if_pc;
	wire			if_branch;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			if_pc <= vect_reset;
		end
		else begin
			if ( dbg_pc_we ) begin
				if_pc <= dbg_pc_wdata;	// debugger hook
			end
			else if ( !interlock ) begin
				if_pc <= if_in_branch_en ? if_in_branch_pc : (if_pc + 4);
			end
		end
	end
	
	
	// load instruction
	wire	[29:0]	if_wb_inst_adr_o;
	wire	[31:0]	if_wb_inst_dat_i;
	wire	[3:0]	if_wb_inst_sel_o;
	wire			if_wb_inst_stb_o;
	wire			if_wb_inst_ack_i;
	cpu_lsu
			#(
				.ADDR_WIDTH	(32),
				.DATA_SIZE	(2) 	// 0:8bit, 1:16bit, 2:32bit ...
			)
		i_cpu_lsu_inst
			(
				.reset		(reset),
				.clk		(clk),
			
				.interlock	(interlock),
				.busy		(if_out_hazard),
			
				.in_en		(1'b1),
				.in_we		(1'b0),
				.in_sel		(4'b1111),
				.in_addr	(if_pc),
				.in_data	({32{1'b0}}),
				
				.out_data	(if_out_instruction),
				
				.wb_adr_o	(if_wb_inst_adr_o),
				.wb_dat_i	(if_wb_inst_dat_i),
				.wb_dat_o	(),
				.wb_we_o	(),
				.wb_sel_o	(if_wb_inst_sel_o),
				.wb_stb_o	(if_wb_inst_stb_o),
				.wb_ack_i	(if_wb_inst_ack_i)
			);
	
	// debugger hook
	assign wb_inst_adr_o = dbg_enable ? dbg_wb_inst_adr_o : if_wb_inst_adr_o;
	assign wb_inst_dat_o = 32'h0000_0000;
	assign wb_inst_we_o  = 1'b0;
	assign wb_inst_sel_o = dbg_enable ? dbg_wb_inst_sel_o : if_wb_inst_sel_o;
	assign wb_inst_stb_o = dbg_enable ? dbg_wb_inst_stb_o : if_wb_inst_stb_o;
	
	assign if_wb_inst_dat_i  = wb_inst_dat_i;
	assign if_wb_inst_ack_i  = wb_inst_ack_i;
	
	assign dbg_wb_inst_dat_i = wb_inst_dat_i;
	assign dbg_wb_inst_ack_i = wb_inst_ack_i;
	
	
	// IF output
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			if_out_stall <= 1'b1;
			if_out_pc    <= 32'h00000000;
		end
		else begin
			if ( !interlock ) begin
				if_out_stall <= if_in_stall;
				if_out_pc    <= if_pc;
			end
		end
	end
	
	
	
	// -----------------------------
	//  Instruction Decode stage
	// -----------------------------
	
	// ID stage input
	wire			id_in_stall;
	
	wire			id_in_dst_reg_en;
	wire	[4:0]	id_in_dst_reg_addr;
	wire	[31:0]	id_in_dst_reg_data;
	
	
	// ID stage output
	reg				id_out_stall;
	reg				id_out_delay;
	reg		[31:0]	id_out_instruction;
	reg		[31:0]	id_out_pc;
	
	reg		[4:0]	id_out_rs_addr;
	reg		[4:0]	id_out_rt_addr;
	reg		[4:0]	id_out_rd_addr;
	reg		[31:0]	id_out_immediate_data;
	
	wire	[31:0]	id_out_rs_data;
	wire	[31:0]	id_out_rt_data;
	
	reg				id_out_branch_en;
	reg		[3:0]	id_out_branch_func;
	reg		[27:0]	id_out_branch_index;
	reg				id_out_branch_index_en;
	reg				id_out_branch_imm_en;
	reg				id_out_branch_rs_en;

	reg				id_out_alu_adder_en;
	reg		[1:0]	id_out_alu_adder_func;
	reg				id_out_alu_logic_en;
	reg		[1:0]	id_out_alu_logic_func;
	reg				id_out_alu_comp_en;
	reg		[1:0]	id_out_alu_comp_func;
	reg				id_out_alu_imm_en;

	reg				id_out_shifter_en;
	reg		[1:0]	id_out_shifter_func;
	reg				id_out_shifter_sa_en;
	reg		[4:0]	id_out_shifter_sa_data;

	reg				id_out_muldiv_en;
	reg				id_out_muldiv_mul;
	reg				id_out_muldiv_div;
	reg				id_out_muldiv_mthi;
	reg				id_out_muldiv_mtlo;
	reg				id_out_muldiv_mfhi;
	reg				id_out_muldiv_mflo;
	reg				id_out_muldiv_signed;

	reg				id_out_cop0_mfc0;
	reg				id_out_cop0_mtc0;
	reg				id_out_cop0_rfe;
	
	reg				id_out_exc_syscall;
	reg				id_out_exc_break;
	reg				id_out_exc_ri;
	
	reg				id_out_mem_en;
	reg				id_out_mem_we;
	reg		[1:0]	id_out_mem_size;
	reg				id_out_mem_unsigned;
			              
	reg				id_out_dst_reg_en;
	reg		[4:0]	id_out_dst_reg_addr;
	reg				id_out_dst_src_alu;
	reg				id_out_dst_src_shifter;
	reg				id_out_dst_src_mem;
	reg				id_out_dst_src_pc;
	reg				id_out_dst_src_hi;
	reg				id_out_dst_src_lo;
	reg				id_out_dst_src_cop0;

	// stall
	wire			id_stall;
	assign id_stall = if_out_stall | id_in_stall;


	// register file
	wire			if_gpr_w0_en;
	wire	[4:0]	if_gpr_w0_addr;
	wire	[31:0]	if_gpr_w0_data;
	
	wire			if_gpr_r0_en;
	wire	[4:0]	if_gpr_r0_addr;
	wire	[31:0]	if_gpr_r0_data;
	
	wire			if_gpr_r1_en;
	wire	[4:0]	if_gpr_r1_addr;
	wire	[31:0]	if_gpr_r1_data;
	
	cpu_gpr
		i_cpu_gpr
			(
				.reset			(reset),
				.clk			(clk),
				.clk_x2			(clk_x2),
				
				.interlock 		(interlock),

				
				.w0_en			(if_gpr_w0_en),
				.w0_addr		(if_gpr_w0_addr),
				.w0_data		(if_gpr_w0_data),
				
				.w1_en			(1'b0),
				.w1_addr		(5'b00000),
				.w1_data		(32'h0000_0000),
				
				.r0_en			(if_gpr_r0_en),
				.r0_addr		(if_gpr_r0_addr),
				.r0_data		(if_gpr_r0_data),
				
				.r1_en			(if_gpr_r1_en),
				.r1_addr		(if_gpr_r1_addr),
				.r1_data		(if_gpr_r1_data)
			);
	
	assign if_gpr_w0_en   = dbg_gpr_en ? (dbg_gpr_en & dbg_gpr_we)  : (id_in_dst_reg_en & !interlock);
	assign if_gpr_w0_addr = dbg_gpr_en ? dbg_gpr_addr               : id_in_dst_reg_addr;
	assign if_gpr_w0_data = dbg_gpr_en ? dbg_gpr_wdata              : id_in_dst_reg_data;
	
	assign if_gpr_r0_en   = 1'b1;
	assign if_gpr_r0_addr = dbg_gpr_en ? dbg_gpr_addr               : if_out_instruction[25:21];	//rs
	assign id_out_rs_data = if_gpr_r0_data;
	assign dbg_gpr_rdata  = if_gpr_r0_data;
		
	assign if_gpr_r1_en   = 1'b1;
	assign if_gpr_r1_addr = if_out_instruction[20:16];	// rt
	assign id_out_rt_data = if_gpr_r1_data;
	
	
	// opecode decode
	wire	[4:0]	id_dec_rs_addr;
	wire	[4:0]	id_dec_rt_addr;
	wire	[4:0]	id_dec_rd_addr;
	wire	[31:0]	id_dec_immediate_data;
	
	wire			id_dec_branch_en;
	wire	[3:0]	id_dec_branch_func;
	wire	[27:0]	id_dec_branch_index;
	wire			id_dec_branch_index_en;
	wire			id_dec_branch_imm_en;
	wire			id_dec_branch_rs_en;
				
	wire			id_dec_alu_adder_en;
	wire	[1:0]	id_dec_alu_adder_func;
	wire			id_dec_alu_logic_en;
	wire	[1:0]	id_dec_alu_logic_func;
	wire			id_dec_alu_comp_en;
	wire			id_dec_alu_comp_func;
	wire			id_dec_alu_imm_en;

	wire			id_dec_shifter_en;
	wire	[1:0]	id_dec_shifter_func;
	wire			id_dec_shifter_sa_en;
	wire	[4:0]	id_dec_shifter_sa_data;
	
	wire			id_dec_muldiv_en;
	wire			id_dec_muldiv_mul;
	wire			id_dec_muldiv_div;
	wire			id_dec_muldiv_mthi;
	wire			id_dec_muldiv_mtlo;
	wire			id_dec_muldiv_mfhi;
	wire			id_dec_muldiv_mflo;
	wire			id_dec_muldiv_signed;
	
	wire			id_dec_cop0_mfc0;
	wire			id_dec_cop0_mtc0;
	wire			id_dec_cop0_rfe;
	
	wire			id_dec_exc_syscall;
	wire			id_dec_exc_break;
	wire			id_dec_exc_ri;
	
	wire			id_dec_mem_en;
	wire			id_dec_mem_we;
	wire	[1:0]	id_dec_mem_size;
	wire			id_dec_mem_unsigned;
			                  
	wire			id_dec_dst_reg_en;
	wire	[4:0]	id_dec_dst_reg_addr;
	wire			id_dec_dst_src_alu;
	wire			id_dec_dst_src_shifter;
	wire			id_dec_dst_src_mem;
	wire			id_dec_dst_src_pc;
	wire			id_dec_dst_src_hi;
	wire			id_dec_dst_src_lo;
	wire			id_dec_dst_src_cop0;
	
	cpu_idu
		i_cpu_idu
			(
				.instruction		(if_out_instruction),
				
				.rs_addr			(id_dec_rs_addr),
				.rt_addr			(id_dec_rt_addr),
				.rd_addr			(id_dec_rd_addr),
				.immediate_data		(id_dec_immediate_data),
				
				.branch_en			(id_dec_branch_en),
				.branch_func		(id_dec_branch_func),
				.branch_index		(id_dec_branch_index),
				.branch_index_en	(id_dec_branch_index_en),
				.branch_imm_en		(id_dec_branch_imm_en),
				.branch_rs_en		(id_dec_branch_rs_en),
				
				.alu_adder_en		(id_dec_alu_adder_en),
				.alu_adder_func		(id_dec_alu_adder_func),
				.alu_logic_en		(id_dec_alu_logic_en),
				.alu_logic_func		(id_dec_alu_logic_func),
				.alu_comp_en		(id_dec_alu_comp_en),
				.alu_comp_func		(id_dec_alu_comp_func),
				.alu_imm_en			(id_dec_alu_imm_en),
				
				.shifter_en			(id_dec_shifter_en),
				.shifter_func		(id_dec_shifter_func),
				.shifter_sa_en		(id_dec_shifter_sa_en),
				.shifter_sa_data	(id_dec_shifter_sa_data),
				
				.muldiv_en			(id_dec_muldiv_en),
				.muldiv_mul			(id_dec_muldiv_mul),
				.muldiv_div			(id_dec_muldiv_div),
				.muldiv_mthi		(id_dec_muldiv_mthi),
				.muldiv_mtlo		(id_dec_muldiv_mtlo),
				.muldiv_mfhi		(id_dec_muldiv_mfhi),
				.muldiv_mflo		(id_dec_muldiv_mflo),
				.muldiv_signed		(id_dec_muldiv_signed),

				.cop0_mfc0			(id_dec_cop0_mfc0),
				.cop0_mtc0			(id_dec_cop0_mtc0),
				.cop0_rfe			(id_dec_cop0_rfe),
               
				.exc_syscall		(id_dec_exc_syscall),
				.exc_break			(id_dec_exc_break),
				.exc_ri				(id_dec_exc_ri),
				
				.mem_en				(id_dec_mem_en),
				.mem_we				(id_dec_mem_we),
				.mem_size			(id_dec_mem_size),
				.mem_unsigned		(id_dec_mem_unsigned),
				
				.dst_reg_en			(id_dec_dst_reg_en),
				.dst_reg_addr		(id_dec_dst_reg_addr),
				.dst_src_alu		(id_dec_dst_src_alu),
				.dst_src_shifter	(id_dec_dst_src_shifter),
				.dst_src_mem		(id_dec_dst_src_mem),
				.dst_src_pc			(id_dec_dst_src_pc),
				.dst_src_hi			(id_dec_dst_src_hi),
				.dst_src_lo			(id_dec_dst_src_lo),
				.dst_src_cop0		(id_dec_dst_src_cop0)
			);
	
	
	// ID
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			id_out_stall       <= 1'b1;
			id_out_delay       <= 1'b0;
			
			id_out_branch_en   <= 1'b0;
			id_out_muldiv_en   <= 1'b0;
			id_out_mem_en      <= 1'b0;

			id_out_cop0_mfc0   <= 1'b0;
			id_out_cop0_mtc0   <= 1'b0;
			id_out_cop0_rfe    <= 1'b0;

			id_out_muldiv_div  <= 1'b0;
			id_out_muldiv_mthi <= 1'b0;
			id_out_muldiv_mtlo <= 1'b0;
               
			id_out_exc_syscall <= 1'b0;
			id_out_exc_break   <= 1'b0;
			id_out_exc_ri      <= 1'b0;
			
			id_out_dst_reg_en  <= 1'b0;
		end
		else begin
			if ( !interlock ) begin
				id_out_stall           <= id_stall;
				id_out_pc              <= if_out_pc;
				id_out_instruction     <= if_out_instruction;
				
				id_out_rs_addr         <= id_dec_rs_addr;
				id_out_rt_addr         <= id_dec_rt_addr;
				id_out_rd_addr         <= id_dec_rd_addr;
				id_out_immediate_data  <= id_dec_immediate_data;
				
				id_out_branch_en       <= id_dec_branch_en & ~id_stall;
				id_out_branch_func     <= id_dec_branch_func;  
				id_out_branch_index    <= id_dec_branch_index; 
				id_out_branch_index_en <= id_dec_branch_index_en;
				id_out_branch_imm_en   <= id_dec_branch_imm_en;
				id_out_branch_rs_en    <= id_dec_branch_rs_en;
			
				id_out_alu_adder_en    <= id_dec_alu_adder_en;
				id_out_alu_adder_func  <= id_dec_alu_adder_func;
				id_out_alu_logic_en    <= id_dec_alu_logic_en;
				id_out_alu_logic_func  <= id_dec_alu_logic_func;
				id_out_alu_comp_en     <= id_dec_alu_comp_en;
				id_out_alu_comp_func   <= id_dec_alu_comp_func;
				id_out_alu_imm_en      <= id_dec_alu_imm_en;
				
				id_out_shifter_en      <= id_dec_shifter_en;
				id_out_shifter_func    <= id_dec_shifter_func;
				id_out_shifter_sa_en   <= id_dec_shifter_sa_en;
				id_out_shifter_sa_data <= id_dec_shifter_sa_data;

				id_out_muldiv_en       <= id_dec_muldiv_en;
				id_out_muldiv_mul      <= id_dec_muldiv_mul;
				id_out_muldiv_div      <= id_dec_muldiv_div;
				id_out_muldiv_mthi     <= id_dec_muldiv_mthi;
				id_out_muldiv_mtlo     <= id_dec_muldiv_mtlo;
				id_out_muldiv_mfhi     <= id_dec_muldiv_mfhi;
				id_out_muldiv_mflo     <= id_dec_muldiv_mflo;
				id_out_muldiv_signed   <= id_dec_muldiv_signed;
				
				id_out_cop0_mfc0       <= id_dec_cop0_mfc0;
				id_out_cop0_mtc0       <= id_dec_cop0_mtc0;
				id_out_cop0_rfe        <= id_dec_cop0_rfe;
                
				id_out_exc_syscall     <= id_dec_exc_syscall;
				id_out_exc_break       <= id_dec_exc_break;
				id_out_exc_ri          <= id_dec_exc_ri;
				
				id_out_mem_en          <= id_dec_mem_en  & ~id_stall;
				id_out_mem_we          <= id_dec_mem_we;
				id_out_mem_size        <= id_dec_mem_size;
				id_out_mem_unsigned    <= id_dec_mem_unsigned;
			                        
				id_out_dst_reg_en      <= id_dec_dst_reg_en & ~id_stall;
				id_out_dst_reg_addr    <= id_dec_dst_reg_addr;
				id_out_dst_src_alu     <= id_dec_dst_src_alu;
				id_out_dst_src_shifter <= id_dec_dst_src_shifter;
				id_out_dst_src_mem     <= id_dec_dst_src_mem;
				id_out_dst_src_pc      <= id_dec_dst_src_pc;
				id_out_dst_src_hi      <= id_dec_dst_src_hi;
				id_out_dst_src_lo      <= id_dec_dst_src_lo;
				id_out_dst_src_cop0    <= id_dec_dst_src_cop0;
			end
		end
	end
	
	
	// -----------------------------
	//  Execution stage
	// -----------------------------
	
	// EX stage input
	wire			ex_in_stall;
	
	// EX stage output
	wire			ex_out_hazard;
	reg				ex_out_stall;
	reg		[31:0]	ex_out_instruction;
	reg		[31:0]	ex_out_pc;
	
	reg				ex_out_mem_en;
	reg				ex_out_mem_we;
	reg		[1:0]	ex_out_mem_size;
	reg				ex_out_mem_unsigned;
	reg		[3:0]	ex_out_mem_sel;
	reg		[31:0]	ex_out_mem_addr;
	reg		[31:0]	ex_out_mem_wdata;
	
	reg				ex_out_dst_reg_en;
	reg		[4:0]	ex_out_dst_reg_addr;
	reg		[31:0]	ex_out_dst_reg_data;
	reg				ex_out_dst_src_mem;
	
	reg				ex_out_branch_en;
	reg		[31:0]	ex_out_branch_pc;

	reg				ex_out_exception_en;
	reg		[31:0]	ex_out_exception_pc;
	

	// stall
	wire				ex_stall;
	assign ex_stall = id_out_stall | ex_in_stall;
	
	// debugger break
	wire ex_break;
	
	// interrupt;
	wire ex_interrupt;
	
	// ex_exception
	wire ex_exception;
	
	
	// fowarding
	reg		[31:0]	ex_fwd_rs_data;
	reg		[31:0]	ex_fwd_rt_data;
	
	
	// ALU
	wire	[31:0]	ex_alu_in_data0;
	wire	[31:0]	ex_alu_in_data1;
	wire	[31:0]	ex_alu_out_data;
	wire			ex_alu_out_carry;
	wire			ex_alu_out_overflow;
	wire			ex_alu_out_negative;
	wire			ex_alu_out_zero;
	
	assign ex_alu_in_data0 = ex_fwd_rs_data; 
	assign ex_alu_in_data1 = id_out_alu_imm_en ? id_out_immediate_data : ex_fwd_rt_data;
	
	cpu_alu
		i_cpu_alu
			(
				.op_adder_en		(id_out_alu_adder_en),
				.op_adder_func		(id_out_alu_adder_func),
				.op_logic_en		(id_out_alu_logic_en),
				.op_logic_func		(id_out_alu_logic_func),
				.op_comp_en			(id_out_alu_comp_en),
				.op_comp_func		(id_out_alu_comp_func),
			
				.in_data0			(ex_alu_in_data0),
				.in_data1			(ex_alu_in_data1),
				
				.out_data			(ex_alu_out_data),
				
				.out_carry			(ex_alu_out_carry),
				.out_overflow		(ex_alu_out_overflow),
				.out_negative		(ex_alu_out_negative),
				.out_zero			(ex_alu_out_zero)

			);
	
	
	// Shifter
	wire	[31:0]		ex_shifter_in_data;
	wire	[4:0]		ex_shifter_in_sa;
	wire	[31:0]		ex_shifter_out_data;
	
	assign ex_shifter_in_data = ex_fwd_rt_data;
	assign ex_shifter_in_sa   = id_out_shifter_sa_en ? id_out_shifter_sa_data : ex_fwd_rs_data[4:0];
	
	cpu_shifter
		i_cpu_shifter
			(
				.op_func		(id_out_shifter_func),
				
				.in_data		(ex_shifter_in_data),
				.in_sa			(ex_shifter_in_sa),
				
				.out_data		(ex_shifter_out_data)
			);
	
	
	
	// MULT&DIV
	wire	[31:0]				ex_muldiv_out_hi;
	wire	[31:0]				ex_muldiv_out_lo;
	wire						ex_muldiv_busy;
	
	cpu_muldiv
		i_cpu_muldiv
			(
				.reset			(reset),
				.clk			(clk),
				
				.op_mul			(id_out_muldiv_mul & ~ex_stall & ~ex_exception),
				.op_div			(id_out_muldiv_div & ~ex_stall & ~ex_exception),
				.op_mthi		(id_out_muldiv_mthi & ~ex_stall & ~ex_exception),
				.op_mtlo		(id_out_muldiv_mtlo & ~ex_stall & ~ex_exception),
				.op_signed		(id_out_muldiv_signed),
				
				.in_data0		(ex_fwd_rs_data),
				.in_data1		(ex_fwd_rt_data),
				
				.out_hi			(ex_muldiv_out_hi),
				.out_lo			(ex_muldiv_out_lo),
				
				.busy			(ex_muldiv_busy)
		);
	
	
	
	
	// COP0
	wire	[31:0]				ex_cop0_exception_pc;
	wire	[31:0]				ex_cop0_out_data;
	wire	[31:0]				ex_cop0_cause;
	wire	[31:0]				ex_cop0_status;
	
	
	// debugger break;
	assign ex_break  = dbg_break_req & ~(interlock | ex_stall);
	assign dbg_break = ex_break;
	
	// interrupt
	assign ex_interrupt  = (interrupt_req & ex_cop0_status[0])
								& ~(interlock | ex_stall | ex_break | id_out_exc_break | id_out_exc_syscall | id_out_exc_ri);
	assign interrupt_ack = ex_interrupt;
	
	// exception
	assign ex_exception = (id_out_exc_break | id_out_exc_syscall | id_out_exc_ri | ex_interrupt)
								& ~(interlock | ex_stall | ex_break);
	
	
	// cause
	assign ex_cop0_cause[31]   = ex_out_branch_en;					// Branch Delay
	assign ex_cop0_cause[30:7] = 0;
	assign ex_cop0_cause[6:2]  = (id_out_exc_ri      ? 5'd10 : 5'd0) |
								(id_out_exc_break   ? 5'd9  : 5'd0) |
								(id_out_exc_syscall ? 5'd8  : 5'd0) |
								(ex_interrupt       ? 5'd0  : 5'd0);	// ExcCode
	assign ex_cop0_cause[1:0]  = 0;
	
	// EPC
	assign ex_cop0_exception_pc = ex_out_branch_en ? id_out_pc - 4 : id_out_pc;
	

	
	cpu_cop0
		i_cpu_cop0
			(
				.reset			(reset),
				.clk			(clk),
				
				.interlock		(interlock),
				
				.rd_addr		(id_out_rd_addr),
				.sel			(3'b000),
				
				.in_en			(id_out_cop0_mtc0 & ~ex_stall & ~ex_exception),
				.in_data		(ex_fwd_rt_data),
				
				.out_data		(ex_cop0_out_data),
				
				.exception_en	(ex_exception),
				.exception_rfe	(id_out_cop0_rfe & ~ex_stall & ~ex_exception),
				.exception_cause(ex_cop0_cause),
				.exception_pc	(ex_cop0_exception_pc),
				
				.status			(ex_cop0_status),
				.cause			(),
				.epc			()
			);
	
	
	
	
	
	
	
	// hazard
	assign ex_out_hazard = id_out_muldiv_en & ex_muldiv_busy;
	
	
	// FF
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			ex_out_stall        <= 1'b1;
			ex_out_instruction  <= 0;
			ex_out_pc           <= 0;
			
			ex_out_mem_en       <= 1'b0;
			ex_out_mem_we       <= 1'b0;
			ex_out_mem_sel      <= 0;
			ex_out_mem_addr     <= 0;
			ex_out_mem_wdata    <= 0;
			
			ex_out_dst_reg_en   <= 1'b0;
			ex_out_dst_reg_addr <= 0;
			ex_out_dst_src_mem  <= 1'b0;
			
			ex_out_branch_en    <= 1'b0;
			ex_out_exception_en <= 1'b0;
		end
		else begin
			if ( !interlock ) begin
				// control
				ex_out_stall        <= ex_stall | ex_exception;
				ex_out_instruction  <= id_out_instruction;
				ex_out_pc           <= id_out_pc;
				
				// MEM
				if ( id_out_mem_en ) begin
					ex_out_mem_en       <= 1'b1 & ~ex_stall;
					ex_out_mem_we       <= id_out_mem_we;
					ex_out_mem_addr     <= ex_alu_out_data;
					ex_out_mem_size     <= id_out_mem_size;
					ex_out_mem_unsigned <= id_out_mem_unsigned;
					if ( id_out_mem_size == 2'b00 ) begin
						ex_out_mem_sel[0] <= (ex_alu_out_data[1:0] == (2'b00 ^ {2{endian}}));
						ex_out_mem_sel[1] <= (ex_alu_out_data[1:0] == (2'b01 ^ {2{endian}}));
						ex_out_mem_sel[2] <= (ex_alu_out_data[1:0] == (2'b10 ^ {2{endian}}));
						ex_out_mem_sel[3] <= (ex_alu_out_data[1:0] == (2'b11 ^ {2{endian}}));
						ex_out_mem_wdata  <= {4{ex_fwd_rt_data[7:0]}};
					end
					else if ( id_out_mem_size == 2'b01 ) begin
						ex_out_mem_sel[0] <= (ex_alu_out_data[1] == (1'b0 ^ {1{endian}}));
						ex_out_mem_sel[1] <= (ex_alu_out_data[1] == (1'b0 ^ {1{endian}}));
						ex_out_mem_sel[2] <= (ex_alu_out_data[1] == (1'b1 ^ {1{endian}}));
						ex_out_mem_sel[3] <= (ex_alu_out_data[1] == (1'b1 ^ {1{endian}}));
						ex_out_mem_wdata  <= {2{ex_fwd_rt_data[15:0]}};
					end
					else begin
						ex_out_mem_sel   <= 4'b1111;
						ex_out_mem_wdata <= ex_fwd_rt_data;
					end
				end
				else begin
					ex_out_mem_en  <= 1'b0;
					ex_out_mem_we  <= 1'b0;
					ex_out_mem_sel <= 4'b0000;
				end
				
				// branch
				ex_out_branch_en <= id_out_branch_en & ~ex_stall & 
									(
										(id_out_branch_func[2:0]  ==  3'b000) |													// JALR
										(id_out_branch_func[2:0]  ==  3'b010) |													// J
										(id_out_branch_func[2:0]  ==  3'b011) |													// JAL
										((id_out_branch_func[2:0] ==  3'b100) & ( ex_alu_out_zero)) |							// BEQ
										((id_out_branch_func[2:0] ==  3'b101) & (!ex_alu_out_zero)) |							// BNE
										((id_out_branch_func[2:0] ==  3'b110) & ( ex_alu_out_negative |  ex_alu_out_zero)) |	// BLEZ (rs <= 0)
										((id_out_branch_func[2:0] ==  3'b111) & (!ex_alu_out_negative & !ex_alu_out_zero)) |	// BGTZ (rs > 0)
										((id_out_branch_func[3:0] == 4'b0001) & ( ex_alu_out_negative & !ex_alu_out_zero)) |	// BLTZ, BLTZAL (rs < 0)
 										((id_out_branch_func[3:0] == 4'b1001) & (!ex_alu_out_negative |  ex_alu_out_zero))		// BGEZ, BGEZAL (rs >= 0)
									);
				ex_out_branch_pc <= (id_out_branch_index_en ? {id_out_pc[31:28], id_out_branch_index}  : 0) |
									(id_out_branch_imm_en   ? if_out_pc + (id_out_immediate_data << 2) : 0) |
									(id_out_branch_rs_en    ? ex_fwd_rs_data                           : 0);
				
				
				// exception
				ex_out_exception_en <= ex_exception;
				ex_out_exception_pc <= interrupt_req ? vect_interrupt : vect_exception;
				
				// destination
				ex_out_dst_reg_en   <= id_out_dst_reg_en;
				ex_out_dst_reg_addr <= id_out_dst_reg_addr;
				ex_out_dst_reg_data <=	(id_out_dst_src_alu     ? ex_alu_out_data     : 32'h00000000) |
										(id_out_dst_src_shifter ? ex_shifter_out_data : 32'h00000000) | 
										(id_out_dst_src_pc      ? if_out_pc + 4       : 32'h00000000) | 
										(id_out_dst_src_hi      ? ex_muldiv_out_hi    : 32'h00000000) |
										(id_out_dst_src_lo      ? ex_muldiv_out_lo    : 32'h00000000) |
										(id_out_dst_src_cop0    ? ex_cop0_out_data    : 32'h00000000);
				ex_out_dst_src_mem  <= id_out_dst_src_mem;
			end
		end
	end
	
	// brench
	assign if_in_branch_en = ex_out_exception_en | ex_out_branch_en;
	assign if_in_branch_pc = ex_out_exception_en ? ex_out_exception_pc : ex_out_branch_pc;
	
	
	
	// -----------------------------
	//  Memory stage
	// -----------------------------
	
	wire				mem_in_stall;
	
	reg					mem_out_stall;
	reg		[31:0]		mem_out_instruction;
	reg		[31:0]		mem_out_pc;
	
	wire				mem_out_hazard;
	
	reg					mem_out_dst_reg_en;
	reg		[4:0]		mem_out_dst_reg_addr;
	wire	[31:0]		mem_out_dst_reg_data;
	
	
	// stall
	wire				mem_stall;
	assign mem_stall = ex_out_stall | mem_in_stall;
	
	
	// memory access
	wire	[31:0]	mem_read_data;
	
	wire	[29:0]	mem_wb_data_adr_o;
	wire	[31:0]	mem_wb_data_dat_i;
	wire	[31:0]	mem_wb_data_dat_o;
	wire			mem_wb_data_we_o;
	wire	[3:0]	mem_wb_data_sel_o;
	wire			mem_wb_data_stb_o;
	wire			mem_wb_data_ack_i;
	cpu_lsu
			#(
				.ADDR_WIDTH	(32),
				.DATA_SIZE	(2) 	// 0:8bit, 1:16bit, 2:32bit ...

			)
		i_cpu_lsu_data
			(
				.reset		(reset),
				.clk		(clk),
			
				.interlock	(interlock),
				.busy		(mem_out_hazard),
			
				.in_en		(ex_out_mem_en & ~mem_stall),
				.in_we		(ex_out_mem_we),
				.in_sel		(ex_out_mem_sel),
				.in_addr	(ex_out_mem_addr),
				.in_data	(ex_out_mem_wdata),
				
				.out_data	(mem_read_data),
				
				.wb_adr_o	(mem_wb_data_adr_o),
				.wb_dat_i	(mem_wb_data_dat_i),
				.wb_dat_o	(mem_wb_data_dat_o),
				.wb_we_o	(mem_wb_data_we_o),
				.wb_sel_o	(mem_wb_data_sel_o),
				.wb_stb_o	(mem_wb_data_stb_o),
				.wb_ack_i	(mem_wb_data_ack_i)
			);
	
	// debugger hook
	assign wb_data_adr_o = dbg_enable ? dbg_wb_data_adr_o : mem_wb_data_adr_o;
	assign wb_data_dat_o = dbg_enable ? dbg_wb_data_dat_o : mem_wb_data_dat_o;
	assign wb_data_we_o  = dbg_enable ? dbg_wb_data_we_o  : mem_wb_data_we_o;
	assign wb_data_sel_o = dbg_enable ? dbg_wb_data_sel_o : mem_wb_data_sel_o;
	assign wb_data_stb_o = dbg_enable ? dbg_wb_data_stb_o : mem_wb_data_stb_o;
	
	assign mem_wb_data_dat_i = wb_data_dat_i;
	assign mem_wb_data_ack_i = wb_data_ack_i;
	
	assign dbg_wb_data_dat_i = wb_data_dat_i;
	assign dbg_wb_data_ack_i = wb_data_ack_i;
	
	
	// FF
	reg					mem_dst_src_mem;
	reg		[1:0]		mem_addr;
	reg		[1:0]		mem_size;
	reg					mem_unsigned;
	reg		[31:0]		mem_ex_data;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			mem_out_stall        <= 1'b0;
			mem_out_instruction  <= 0;
			mem_out_pc           <= 0;

			mem_out_dst_reg_en   <= 1'b1;
			mem_out_dst_reg_addr <= 0;

			mem_dst_src_mem      <= 1'b0;
			mem_ex_data          <= 0;
		end
		else begin
			if ( !interlock ) begin
				mem_out_stall        <= mem_stall;
				mem_out_instruction  <= ex_out_instruction;
				mem_out_pc           <= ex_out_pc;
				
				mem_out_dst_reg_en   <= ex_out_dst_reg_en & ~mem_stall;
				mem_out_dst_reg_addr <= ex_out_dst_reg_addr;
				
				mem_dst_src_mem      <= ex_out_dst_src_mem;
				mem_addr             <= ex_out_mem_addr[1:0];
				mem_size             <= ex_out_mem_size;
				mem_unsigned         <= ex_out_mem_unsigned;
				
				mem_ex_data          <= ex_out_dst_reg_data;
			end
		end
	end
	
	
	// Read data extension
	wire	[7:0]		mem_rdata_b;
	wire	[15:0]		mem_rdata_h;
	assign mem_rdata_b = (mem_addr[1:0] == (2'b00 ^ {2{endian}})) ? mem_read_data[7:0]   :
						 (mem_addr[1:0] == (2'b01 ^ {2{endian}})) ? mem_read_data[15:8]  :
						 (mem_addr[1:0] == (2'b10 ^ {2{endian}})) ? mem_read_data[23:16] : mem_read_data[31:24];
	
	assign mem_rdata_h = (mem_addr[1] == (1'b0 ^ {1{endian}})) ? mem_read_data[15:0] : mem_read_data[31:16];
	
	reg		[31:0]		mem_rdata;
	always @* begin
		if ( mem_size == 2'b00 ) begin
			mem_rdata[7:0]   <= mem_rdata_b;
			mem_rdata[31:8]  <= mem_unsigned ? {24{1'b0}} : {24{mem_rdata_b[7]}};
		end
		else if ( mem_size == 2'b01 ) begin
			mem_rdata[15:0]  <= mem_rdata_h;
			mem_rdata[31:16] <= mem_unsigned ? {16{1'b0}} : {16{mem_rdata_h[15]}};
		end
		else begin
			mem_rdata[31:0]  <= mem_read_data;
		end
	end
	
	assign mem_out_dst_reg_data = mem_dst_src_mem ? mem_rdata : mem_ex_data;
	
		
	
	// -----------------------------
	//  Writeback stage
	// -----------------------------
	
	assign id_in_dst_reg_en   = mem_out_dst_reg_en;
	assign id_in_dst_reg_addr = mem_out_dst_reg_addr;
	assign id_in_dst_reg_data = mem_out_dst_reg_data;
	
	
	
	// -----------------------------
	//  Fowarding control
	// -----------------------------
	
	reg				fwd_rs_hit_ex;
	reg				fwd_rs_hit_mem;
	reg				fwd_rt_hit_ex;
	reg				fwd_rt_hit_mem;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			fwd_rs_hit_ex  <= 1'b0;
	        fwd_rs_hit_mem <= 1'b0;
	        fwd_rt_hit_ex  <= 1'b0;
	        fwd_rt_hit_mem <= 1'b0;
		end
		else begin
			if ( !interlock ) begin
				fwd_rs_hit_ex  <= (if_out_instruction[25:21] == id_out_dst_reg_addr) & id_out_dst_reg_en;
				fwd_rs_hit_mem <= (if_out_instruction[25:21] == ex_out_dst_reg_addr) & ex_out_dst_reg_en;
				fwd_rt_hit_ex  <= (if_out_instruction[20:16] == id_out_dst_reg_addr) & id_out_dst_reg_en;
				fwd_rt_hit_mem <= (if_out_instruction[20:16] == ex_out_dst_reg_addr) & ex_out_dst_reg_en;
			end
		end
	end
	
	always @* begin
		if ( fwd_rs_hit_ex ) begin
			ex_fwd_rs_data <= ex_out_dst_reg_data;
		end
		else if ( fwd_rs_hit_mem ) begin
			ex_fwd_rs_data <= mem_out_dst_reg_data;
		end
		else begin
			ex_fwd_rs_data <= id_out_rs_data;
		end
	end

	always @* begin
		if ( fwd_rt_hit_ex ) begin
			ex_fwd_rt_data <= ex_out_dst_reg_data;
		end
		else if ( fwd_rt_hit_mem ) begin
			ex_fwd_rt_data <= mem_out_dst_reg_data;
		end
		else begin
			ex_fwd_rt_data <= id_out_rt_data;
		end
	end
	
	
	
	// -----------------------------
	//  Pipeline control
	// -----------------------------
	
	// interlock
	assign interlock    = if_out_hazard | ex_out_hazard | mem_out_hazard | pause;
	
	// stall
	assign if_in_stall  = ex_out_exception_en | ex_out_branch_en;
	assign id_in_stall  = ex_out_exception_en | ex_out_branch_en;
	assign ex_in_stall  = ex_out_exception_en;
	assign mem_in_stall = 1'b0;




	// -----------------------------
	//  Debug unit
	// -----------------------------
	
	cpu_dbu
		i_cpu_dbu
			(
				.reset			(reset),
				.clk			(clk),
				.endian			(endian),
				
				.wb_adr_i		(wb_dbg_adr_i),
				.wb_dat_i		(wb_dbg_dat_i),
				.wb_dat_o		(wb_dbg_dat_o),
				.wb_we_i		(wb_dbg_we_i),
				.wb_sel_i		(wb_dbg_sel_i),
				.wb_stb_i		(wb_dbg_stb_i),
				.wb_ack_o		(wb_dbg_ack_o),
				
				.dbg_enable		(dbg_enable),
				.dbg_break_req	(dbg_break_req),
				.dbg_break		(dbg_break),
				
				.wb_data_adr_o	(dbg_wb_data_adr_o),
				.wb_data_dat_i	(dbg_wb_data_dat_i),
				.wb_data_dat_o	(dbg_wb_data_dat_o),
				.wb_data_we_o	(dbg_wb_data_we_o),
				.wb_data_sel_o	(dbg_wb_data_sel_o),
				.wb_data_stb_o	(dbg_wb_data_stb_o),
				.wb_data_ack_i	(dbg_wb_data_ack_i),
				
				.wb_inst_adr_o	(dbg_wb_inst_adr_o),
				.wb_inst_dat_i	(dbg_wb_inst_dat_i),
				.wb_inst_sel_o	(dbg_wb_inst_sel_o),
				.wb_inst_stb_o	(dbg_wb_inst_stb_o),
				.wb_inst_ack_i	(dbg_wb_inst_ack_i),
				
				.pc_we			(dbg_pc_we),
				.pc_wdata		(dbg_pc_wdata),
				.pc_rdata		(dbg_pc_rdata),
				
				.gpr_en			(dbg_gpr_en),
				.gpr_we			(dbg_gpr_we),
				.gpr_addr		(dbg_gpr_addr),
				.gpr_wdata		(dbg_gpr_wdata),
				.gpr_rdata		(dbg_gpr_rdata),
				
				.hilo_en		(dbg_hilo_en),
				.hilo_we		(dbg_hilo_we),
				.hilo_addr		(dbg_hilo_addr),
				.hilo_wdata		(dbg_hilo_wdata),
				.hilo_rdata		(dbg_hilo_rdata),
				
				.cop0_en		(cop0_en),
				.cop0_we		(cop0_we),
				.cop0_addr		(cop0_addr),
				.cop0_wdata		(cop0_wdata),
				.cop0_rdata		(cop0_rdata)
			);

endmodule
