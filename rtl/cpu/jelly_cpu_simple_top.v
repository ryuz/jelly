// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// CPU top
module jelly_cpu_simple_top
		#(
			// CPU core
			parameter	USE_DBUGGER      = 1'b1,
			parameter	USE_EXC_SYSCALL  = 1'b1,
			parameter	USE_EXC_BREAK    = 1'b1,
			parameter	USE_EXC_RI       = 1'b1,
			parameter	GPR_TYPE         = 0,
			parameter	MUL_CYCLE        = 0,
			parameter	DBBP_NUM         = 4,
			
			// Tightly Coupled Memory
			parameter	TCM_ENABLE       = 0,
			parameter	TCM_ADDR_MASK    = 30'b1111_1111_1111_1111__1111_1100_0000_00,
			parameter	TCM_ADDR_VALUE   = 30'b0000_0000_0000_0000__0000_0000_0000_00,
			parameter	TCM_ADDR_WIDTH   = 8,
			parameter	TCM_MEM_SIZE     = (1 << TCM_ADDR_WIDTH),
			parameter	TCM_READMEMH     = 0,
			parameter	TCM_READMEM_FIlE = "",

			// simulation
			parameter	SIMULATION       = 0
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
	
	jelly_cpu_top
			#(
				.USE_DBUGGER		(USE_DBUGGER),
				.USE_EXC_SYSCALL	(USE_EXC_SYSCALL),
				.USE_EXC_BREAK		(USE_EXC_BREAK),
				.USE_EXC_RI			(USE_EXC_RI),
				.GPR_TYPE			(GPR_TYPE),
				.MUL_CYCLE			(MUL_CYCLE),
				.DBBP_NUM			(DBBP_NUM),
				
				.TCM_ENABLE			(TCM_ENABLE),
				.TCM_ADDR_MASK		(TCM_ADDR_MASK),
				.TCM_ADDR_VALUE		(TCM_ADDR_VALUE),
				.TCM_ADDR_WIDTH		(TCM_ADDR_WIDTH),
				.TCM_MEM_SIZE		(TCM_MEM_SIZE),
				.TCM_READMEMH		(TCM_READMEMH),
				.TCM_READMEM_FIlE	(TCM_READMEM_FIlE),
				
				.CACHE_ENABLE		(0),
				
				.SIMULATION			(SIMULATION)
			)
		i_cpu_top
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
									 
				.pause				(pause),
								   
				.wb_mem_adr_o		(),
				.wb_mem_dat_i		({64{1'b0}}),
				.wb_mem_dat_o		(),
				.wb_mem_we_o		(),
				.wb_mem_sel_o		(),
				.wb_mem_stb_o		(),
				.wb_mem_ack_i		(1'b1),
				
				.wb_peri_adr_o		(wb_adr_o),
				.wb_peri_dat_i		(wb_dat_i),
				.wb_peri_dat_o		(wb_dat_o),
				.wb_peri_we_o		(wb_we_o),
				.wb_peri_sel_o		(wb_sel_o),
				.wb_peri_stb_o		(wb_stb_o),
				.wb_peri_ack_i		(wb_ack_i),
									 
				.wb_dbg_adr_i		(wb_dbg_adr_i),
				.wb_dbg_dat_i		(wb_dbg_dat_i),
				.wb_dbg_dat_o		(wb_dbg_dat_o),
				.wb_dbg_we_i		(wb_dbg_we_i),
				.wb_dbg_sel_i		(wb_dbg_sel_i),
				.wb_dbg_stb_i		(wb_dbg_stb_i),
				.wb_dbg_ack_o		(wb_dbg_ack_o)			
			);
	
endmodule


// end of file
