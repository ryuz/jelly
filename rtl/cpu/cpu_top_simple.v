// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// CPU top
module jelly_cpu_top_simple
		#(
			parameter					USE_DBUGGER     = 1'b1,
			parameter					USE_EXC_SYSCALL = 1'b1,
			parameter					USE_EXC_BREAK   = 1'b1,
			parameter					USE_EXC_RI      = 1'b1,
			parameter					GPR_TYPE        = 0,
			parameter					MUL_CYCLE       = 0,
			parameter					DBBP_NUM        = 4
		)
		(
			// system
			input	wire				reset,
			input	wire				clk,
			input	wire				clk_x2,
			
			// endian
			input	wire				endian,
			
			// vector
			input	wire	[31:0]		vect_reset,
			input	wire	[31:0]		vect_interrupt,
			input	wire	[31:0]		vect_exception,
			
			// interrupt
			input	wire				interrupt_req,
			output	wire				interrupt_ack,
			
			// bus (wishbone)
			output	wire	[31:2]		wb_adr_o,
			input	wire	[31:0]		wb_dat_i,
			output	wire	[31:0]		wb_dat_o,
			output	wire				wb_we_o,
			output	wire	[3:0]		wb_sel_o,
			output	wire				wb_stb_o,
			input	wire				wb_ack_i,
			
			// debug port (wishbone)
			input	wire	[3:0]		wb_dbg_adr_i,
			input	wire	[31:0]		wb_dbg_dat_i,
			output	wire	[31:0]		wb_dbg_dat_o,
			input	wire				wb_dbg_we_i,
			input	wire	[3:0]		wb_dbg_sel_i,
			input	wire				wb_dbg_stb_i,
			output	wire				wb_dbg_ack_o,
			
			// control
			input	wire				pause
		);
	
	
	// ---------------------------------
	//  CPU core
	// ---------------------------------
	
	// instruction bus
	wire				ibus_interlock;
	wire				ibus_en;
	wire				ibus_we;
	wire	[3:0]		ibus_sel;
	wire	[31:0]		ibus_addr;
	wire	[31:0]		ibus_wdata;
	wire	[31:0]		ibus_rdata;
	wire				ibus_busy;
			
	// data bus
	wire				dbus_interlock;
	wire				dbus_en;
	wire				dbus_we;
	wire	[3:0]		dbus_sel;
	wire	[31:0]		dbus_addr;
	wire	[31:0]		dbus_wdata;
	wire	[31:0]		dbus_rdata;
	wire				dbus_busy;
	
	// CPU core
	jelly_cpu_core
			#(
				.USE_DBUGGER    	(USE_DBUGGER),
				.USE_EXC_SYSCALL	(USE_EXC_SYSCALL),
				.USE_EXC_BREAK		(USE_EXC_BREAK),
				.USE_EXC_RI			(USE_EXC_RI),
				.GPR_TYPE			(GPR_TYPE),
				.MUL_CYCLE			(MUL_CYCLE),
				.DBBP_NUM			(DBBP_NUM)
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
				
				.ibus_interlock		(ibus_interlock),
				.ibus_en			(ibus_en),
				.ibus_we			(ibus_we),
				.ibus_sel			(ibus_sel),
				.ibus_addr			(ibus_addr),
				.ibus_wdata			(ibus_wdata),
				.ibus_rdata			(ibus_rdata),
				.ibus_busy			(ibus_busy),
                                 
				.dbus_interlock		(dbus_interlock),
				.dbus_en			(dbus_en),
				.dbus_we			(dbus_we),
				.dbus_sel			(dbus_sel),
				.dbus_addr			(dbus_addr),
				.dbus_wdata			(dbus_wdata),
				.dbus_rdata			(dbus_rdata),
				.dbus_busy			(dbus_busy),
				
				.wb_dbg_adr_i		(wb_dbg_adr_i),
				.wb_dbg_dat_i		(wb_dbg_dat_i),
				.wb_dbg_dat_o		(wb_dbg_dat_o),
				.wb_dbg_we_i		(wb_dbg_we_i),
				.wb_dbg_sel_i		(wb_dbg_sel_i),
				.wb_dbg_stb_i		(wb_dbg_stb_i),
				.wb_dbg_ack_o		(wb_dbg_ack_o),
				
				.pause				(pause)
			);
	
	
	// ---------------------------------
	//  WISHBONE
	// ---------------------------------
	
	// Instruction bus (WISHBONE)
	wire	[31:2]	wb_inst_adr_o;
	wire	[31:0]	wb_inst_dat_i;
	wire	[31:0]	wb_inst_dat_o;
	wire			wb_inst_we_o;
	wire	[3:0]	wb_inst_sel_o;
	wire			wb_inst_stb_o;
	wire			wb_inst_ack_i;
	
	// Data bus (WISHBONE)
	wire	[31:2]	wb_data_adr_o;
	wire	[31:0]	wb_data_dat_i;
	wire	[31:0]	wb_data_dat_o;
	wire			wb_data_we_o;
	wire	[3:0]	wb_data_sel_o;
	wire			wb_data_stb_o;
	wire			wb_data_ack_i;
		
	jelly_cpu_wishbone
			#(
				.ADDR_WIDTH			(32),
				.DATA_SIZE			(2) 	// 0:8bit, 1:16bit, 2:32bit ...
			)
		i_cpu_wishbone_inst
			(
				.reset				(reset),
				.clk				(clk),
							
				.cpubus_interlock	(ibus_interlock),
				.cpubus_en			(ibus_en),
				.cpubus_we			(ibus_we),
				.cpubus_sel			(ibus_sel),
				.cpubus_addr		(ibus_addr),
				.cpubus_wdata		(ibus_wdata),
				.cpubus_rdata		(ibus_rdata),
				.cpubus_busy		(ibus_busy),

				.wb_adr_o			(wb_inst_adr_o),
				.wb_dat_i			(wb_inst_dat_i),
				.wb_dat_o			(wb_inst_dat_o),
				.wb_we_o			(wb_inst_we_o),
				.wb_sel_o			(wb_inst_sel_o),
				.wb_stb_o			(wb_inst_stb_o),
				.wb_ack_i			(wb_inst_ack_i)
		);

	jelly_cpu_wishbone
			#(
				.ADDR_WIDTH			(32),
				.DATA_SIZE			(2) 	// 0:8bit, 1:16bit, 2:32bit ...
			)
		i_cpu_wishbone_data
			(
				.reset				(reset),
				.clk				(clk),
							
				.cpubus_interlock	(dbus_interlock),
				.cpubus_en			(dbus_en),
				.cpubus_we			(dbus_we),
				.cpubus_sel			(dbus_sel),
				.cpubus_addr		(dbus_addr),
				.cpubus_wdata		(dbus_wdata),
				.cpubus_rdata		(dbus_rdata),
				.cpubus_busy		(dbus_busy),

				.wb_adr_o			(wb_data_adr_o),
				.wb_dat_i			(wb_data_dat_i),
				.wb_dat_o			(wb_data_dat_o),
				.wb_we_o			(wb_data_we_o),
				.wb_sel_o			(wb_data_sel_o),
				.wb_stb_o			(wb_data_stb_o),
				.wb_ack_i			(wb_data_ack_i)
		);
	
	
	// ---------------------------------
	//  arbiter
	// ---------------------------------
	
	// arbiter
	jelly_cpu_wishbone_arbiter
			#(
				.WB_ADR_WIDTH		(30),
				.WB_DAT_WIDTH		(32)
			)
		i_cpu_wishbone_arbiter
			(
				.reset				(reset),
				.clk				(clk),

				.wb_cpu0_adr_i		(wb_inst_adr_o),
				.wb_cpu0_dat_i		(wb_inst_dat_o),
				.wb_cpu0_dat_o		(wb_inst_dat_i),
				.wb_cpu0_we_i		(wb_inst_we_o),
				.wb_cpu0_sel_i		(wb_inst_sel_o),
				.wb_cpu0_stb_i		(wb_inst_stb_o),
				.wb_cpu0_ack_o		(wb_inst_ack_i),

				.wb_cpu1_adr_i		(wb_data_adr_o),
				.wb_cpu1_dat_i		(wb_data_dat_o),
				.wb_cpu1_dat_o		(wb_data_dat_i),
				.wb_cpu1_we_i		(wb_data_we_o),
				.wb_cpu1_sel_i		(wb_data_sel_o),
				.wb_cpu1_stb_i		(wb_data_stb_o),
				.wb_cpu1_ack_o		(wb_data_ack_i),

				.wb_mem_adr_o		(wb_adr_o),
				.wb_mem_dat_i		(wb_dat_i),
				.wb_mem_dat_o		(wb_dat_o),
				.wb_mem_we_o		(wb_we_o),
				.wb_mem_sel_o		(wb_sel_o),
				.wb_mem_stb_o		(wb_stb_o),
				.wb_mem_ack_i		(wb_ack_i)
			);
	
	/*
	reg		reg_busy;
	reg		reg_sw;
	wire	sw;
	always @ ( posedge clk ) begin
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
	*/
	
endmodule
