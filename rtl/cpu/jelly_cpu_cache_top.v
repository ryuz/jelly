// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// CPU top
module jelly_cpu_cache_top
		#(
			parameter	USE_DBUGGER      = 1'b1,
			parameter	USE_EXC_SYSCALL  = 1'b1,
			parameter	USE_EXC_BREAK    = 1'b1,
			parameter	USE_EXC_RI       = 1'b1,
			parameter	GPR_TYPE         = 0,
			parameter	MUL_CYCLE        = 0,
			parameter	DBBP_NUM         = 4,

			parameter	CACHE_LINE_SIZE  = 2,		// 2^n (0:1words, 1:2words, 2:4words ...)
			parameter	CACHE_ARRAY_SIZE = 9,		// 2^n (1:2lines, 2:4lines 3:8lines ...)
			
			parameter	CACHE_ADDR_MASK  = 30'b1111_0000_0000_0000__0000_0000_0000_00,
			parameter	CACHE_ADDR_VALUE = 30'b0000_0000_0000_0000__0000_0000_0000_00,
			parameter	CACHE_ADDR_WIDTH = 24,
			
			parameter	MEM_ADR_WIDTH    = 30 - CACHE_LINE_SIZE,
			parameter	MEM_DAT_SIZE     = 2 + CACHE_LINE_SIZE,
			parameter	MEM_DAT_WIDTH    = (8 << MEM_DAT_SIZE),
			parameter	MEM_SEL_WIDTH    = (1 << MEM_DAT_SIZE)
		)
		(
			// system
			input	wire						reset,
			input	wire						clk,
			input	wire						clk_x2,
			
			// endian
			input	wire						endian,
			
			// vector
			input	wire	[31:0]				vect_reset,
			input	wire	[31:0]				vect_interrupt,
			input	wire	[31:0]				vect_exception,
			
			// interrupt
			input	wire						interrupt_req,
			output	wire						interrupt_ack,
			
			// WISHBONE memory bus (cached)
			output	wire	[31:MEM_DAT_SIZE]	wb_mem_adr_o,
			input	wire	[MEM_DAT_SIZE-1:0]	wb_mem_dat_i,
			output	wire	[MEM_DAT_WIDTH-1:0]	wb_mem_dat_o,
			output	wire						wb_mem_we_o,
			output	wire	[MEM_SEL_WIDTH-1:0]	wb_mem_sel_o,
			output	wire						wb_mem_stb_o,
			input	wire						wb_mem_ack_i,
			
			// WISHBONE peripheral bus (non-cached)
			output	wire	[31:2]				wb_peri_adr_o,
			input	wire	[31:0]				wb_peri_dat_i,
			output	wire	[31:0]				wb_peri_dat_o,
			output	wire						wb_peri_we_o,
			output	wire	[3:0]				wb_peri_sel_o,
			output	wire						wb_peri_stb_o,
			input	wire						wb_peri_ack_i,
			
			
			// WISHBONE debug port (wishbone)
			input	wire	[3:0]				wb_dbg_adr_i,
			input	wire	[31:0]				wb_dbg_dat_i,
			output	wire	[31:0]				wb_dbg_dat_o,
			input	wire						wb_dbg_we_i,
			input	wire	[3:0]				wb_dbg_sel_i,
			input	wire						wb_dbg_stb_i,
			output	wire						wb_dbg_ack_o,
			
			// control
			input	wire						pause
		);
	
	
	// ---------------------------------
	//  CPU core
	// ---------------------------------
	
	// instruction bus
	wire				jbus_inst_en;
	wire	[31:2]		jbus_inst_addr;
	wire	[31:0]		jbus_inst_wdata;
	wire	[31:0]		jbus_inst_rdata;
	wire				jbus_inst_we;
	wire	[3:0]		jbus_inst_sel;
	wire				jbus_inst_valid;
	wire				jbus_inst_ready;
	
	// data bus
	wire				jbus_data_en;
	wire	[31:2]		jbus_data_addr;
	wire	[31:0]		jbus_data_wdata;
	wire	[31:0]		jbus_data_rdata;
	wire				jbus_data_we;
	wire	[3:0]		jbus_data_sel;
	wire				jbus_data_valid;
	wire				jbus_data_ready;
	
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
				
				.jbus_inst_en		(jbus_inst_en),
				.jbus_inst_addr		(jbus_inst_addr),
				.jbus_inst_wdata	(jbus_inst_wdata),
				.jbus_inst_rdata	(jbus_inst_rdata),
				.jbus_inst_we		(jbus_inst_we),
				.jbus_inst_sel		(jbus_inst_sel),
				.jbus_inst_valid	(jbus_inst_valid),
				.jbus_inst_ready	(jbus_inst_ready),
                
				.jbus_data_en		(jbus_data_en),
				.jbus_data_addr		(jbus_data_addr),
				.jbus_data_wdata	(jbus_data_wdata),
				.jbus_data_rdata	(jbus_data_rdata),
				.jbus_data_we		(jbus_data_we),
				.jbus_data_sel		(jbus_data_sel),
				.jbus_data_valid	(jbus_data_valid),
				.jbus_data_ready	(jbus_data_ready),
				
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
	//  Address decode
	// ---------------------------------
	
	wire							jbus_imem_en;
	wire	[CACHE_ADDR_WIDTH-1:0]	jbus_imem_addr;
	wire	[31:0]					jbus_imem_wdata;
	wire	[31:0]					jbus_imem_rdata;
	wire							jbus_imem_we;
	wire	[3:0]					jbus_imem_sel;
	wire							jbus_imem_valid;
	wire							jbus_imem_ready;
	
	wire							jbus_iperi_en;
	wire	[29:0]					jbus_iperi_addr;
	wire	[31:0]					jbus_iperi_wdata;
	wire	[31:0]					jbus_iperi_rdata;
	wire							jbus_iperi_we;
	wire	[3:0]					jbus_iperi_sel;
	wire							jbus_iperi_valid;
	wire							jbus_iperi_ready;
		
	wire							jbus_dmem_en;
	wire	[CACHE_ADDR_WIDTH-1:0]	jbus_dmem_addr;
	wire	[31:0]					jbus_dmem_wdata;
	wire	[31:0]					jbus_dmem_rdata;
	wire							jbus_dmem_we;
	wire	[3:0]					jbus_dmem_sel;
	wire							jbus_dmem_valid;
	wire							jbus_dmem_ready;
	
	wire							jbus_dperi_en;
	wire	[29:0]					jbus_dperi_addr;
	wire	[31:0]					jbus_dperi_wdata;
	wire	[31:0]					jbus_dperi_rdata;
	wire							jbus_dperi_we;
	wire	[3:0]					jbus_dperi_sel;
	wire							jbus_dperi_valid;
	wire							jbus_dperi_ready;
	
	jelly_jbus_decoder
			#(
				.SLAVE_ADDR_WIDTH	(30),
				.SLAVE_DATA_SIZE	(2),	// 0:8bit, 1:16bit, 2:32bit ...
				.DEC_ADDR_MASK		(CACHE_ADDR_MASK),
				.DEC_ADDR_VALUE		(CACHE_ADDR_VALUE),
				.DEC_ADDR_WIDTH		(CACHE_ADDR_WIDTH)
			)
		jbus_decoder_inst
			(
				.reset				(reset),
				.clk				(clk),
				
				.jbus_slave_en		(jbus_inst_en),
				.jbus_slave_addr	(jbus_inst_addr),
				.jbus_slave_wdata	(jbus_inst_wdata),
				.jbus_slave_rdata	(jbus_inst_rdata),
				.jbus_slave_we		(jbus_inst_we),
				.jbus_slave_sel		(jbus_inst_sel),
				.jbus_slave_valid	(jbus_inst_valid),
				.jbus_slave_ready	(jbus_inst_ready),
				                   
				.jbus_master_en		(jbus_iperi_en),
				.jbus_master_addr	(jbus_iperi_addr),
				.jbus_master_wdata	(jbus_iperi_wdata),
				.jbus_master_rdata	(jbus_iperi_rdata),
				.jbus_master_we		(jbus_iperi_we),
				.jbus_master_sel	(jbus_iperi_sel),
				.jbus_master_valid	(jbus_iperi_valid),
				.jbus_master_ready	(jbus_iperi_ready),
				                   
				.jbus_decode_en		(jbus_imem_en),
				.jbus_decode_addr	(jbus_imem_addr),
				.jbus_decode_wdata	(jbus_imem_wdata),
				.jbus_decode_rdata	(jbus_imem_rdata),
				.jbus_decode_we		(jbus_imem_we),
				.jbus_decode_sel	(jbus_imem_sel),
				.jbus_decode_valid	(jbus_imem_valid),
				.jbus_decode_ready	(jbus_imem_ready)
			);
	
	jelly_jbus_decoder
			#(
				.SLAVE_ADDR_WIDTH	(30),
				.SLAVE_DATA_SIZE	(2),	// 0:8bit, 1:16bit, 2:32bit ...
				.DEC_ADDR_MASK		(CACHE_ADDR_MASK),
				.DEC_ADDR_VALUE		(CACHE_ADDR_VALUE),
				.DEC_ADDR_WIDTH		(CACHE_ADDR_WIDTH)
			)
		jbus_decoder_data
			(
				.reset				(reset),
				.clk				(clk),
				
				.jbus_slave_en		(jbus_data_en),
				.jbus_slave_addr	(jbus_data_addr),
				.jbus_slave_wdata	(jbus_data_wdata),
				.jbus_slave_rdata	(jbus_data_rdata),
				.jbus_slave_we		(jbus_data_we),
				.jbus_slave_sel		(jbus_data_sel),
				.jbus_slave_valid	(jbus_data_valid),
				.jbus_slave_ready	(jbus_data_ready),
				                   
				.jbus_master_en		(jbus_dperi_en),
				.jbus_master_addr	(jbus_dperi_addr),
				.jbus_master_wdata	(jbus_dperi_wdata),
				.jbus_master_rdata	(jbus_dperi_rdata),
				.jbus_master_we		(jbus_dperi_we),
				.jbus_master_sel	(jbus_dperi_sel),
				.jbus_master_valid	(jbus_dperi_valid),
				.jbus_master_ready	(jbus_dperi_ready),
				                   
				.jbus_decode_en		(jbus_dmem_en),
				.jbus_decode_addr	(jbus_dmem_addr),
				.jbus_decode_wdata	(jbus_dmem_wdata),
				.jbus_decode_rdata	(jbus_dmem_rdata),
				.jbus_decode_we		(jbus_dmem_we),
				.jbus_decode_sel	(jbus_dmem_sel),
				.jbus_decode_valid	(jbus_dmem_valid),
				.jbus_decode_ready	(jbus_dmem_ready)
			);
	
	
	
	// ---------------------------------
	//  Cache
	// ---------------------------------
	
	jelly_cpu_unified_cache
			#(
				.LINE_SIZE			(CACHE_LINE_SIZE),		// 2^n (0:1words, 1:2words, 2:4words ...)
				.ARRAY_SIZE			(CACHE_ARRAY_SIZE),		// 2^n (1:2lines, 2:4lines 3:8lines ...)
				.SLAVE_ADDR_WIDTH	(CACHE_ADDR_WIDTH),
				.SLAVE_DATA_SIZE	(2)						// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			)
		i_cache_unified
			(
				.reset				(reset),
				.clk				(clk),
				
				.endian				(endian),
				
				.jbus_slave0_en		(jbus_imem_en),
				.jbus_slave0_addr	(jbus_imem_addr),
				.jbus_slave0_wdata	(jbus_imem_wdata),
				.jbus_slave0_rdata	(jbus_imem_rdata),
				.jbus_slave0_we		(jbus_imem_we),
				.jbus_slave0_sel	(jbus_imem_sel),
				.jbus_slave0_valid	(jbus_imem_valid),
				.jbus_slave0_ready	(jbus_imem_ready),
				
				.jbus_slave1_en		(jbus_dmem_en),
				.jbus_slave1_addr	(jbus_dmem_addr),
				.jbus_slave1_wdata	(jbus_dmem_wdata),
				.jbus_slave1_rdata	(jbus_dmem_rdata),
				.jbus_slave1_we		(jbus_dmem_we),
				.jbus_slave1_sel	(jbus_dmem_sel),
				.jbus_slave1_valid	(jbus_dmem_valid),
				.jbus_slave1_ready	(jbus_dmem_ready),
				                   
				.wb_master_adr_o	(wb_mem_adr_o),
				.wb_master_dat_i	(wb_mem_dat_i),
				.wb_master_dat_o	(wb_mem_dat_o),
				.wb_master_we_o		(wb_mem_we_o),
				.wb_master_sel_o	(wb_mem_sel_o),
				.wb_master_stb_o	(wb_mem_stb_o),
				.wb_master_ack_i	(wb_mem_ack_i)
			);                     
	
	
	// ---------------------------------
	//  Peripheral
	// ---------------------------------
	
	wire	[31:2]				wb_iperi_adr_o;
	wire	[31:0]				wb_iperi_dat_i;
	wire	[31:0]				wb_iperi_dat_o;
	wire						wb_iperi_we_o;
	wire	[3:0]				wb_iperi_sel_o;
	wire						wb_iperi_stb_o;
	wire						wb_iperi_ack_i;

	wire	[31:2]				wb_dperi_adr_o;
	wire	[31:0]				wb_dperi_dat_i;
	wire	[31:0]				wb_dperi_dat_o;
	wire						wb_dperi_we_o;
	wire	[3:0]				wb_dperi_sel_o;
	wire						wb_dperi_stb_o;
	wire						wb_dperi_ack_i;
	
	jelly_jbus_to_wishbone
			#(
				.ADDR_WIDTH			(30),
				.DATA_SIZE			(2) 	// 0:8bit, 1:16bit, 2:32bit ...
			)
		i_jbus_to_wishbone_inst
			(
				.reset				(reset),
				.clk				(clk),
				
				.jbus_slave_en		(jbus_iperi_en),
				.jbus_slave_addr	(jbus_iperi_addr),
				.jbus_slave_wdata	(jbus_iperi_wdata),
				.jbus_slave_rdata	(jbus_iperi_rdata),
				.jbus_slave_we		(jbus_iperi_we),
				.jbus_slave_sel		(jbus_iperi_sel),
				.jbus_slave_valid	(jbus_iperi_valid),
				.jbus_slave_ready	(jbus_iperi_ready),

				.wb_master_adr_o	(wb_iperi_adr_o),
				.wb_master_dat_i	(wb_iperi_dat_i),
				.wb_master_dat_o	(wb_iperi_dat_o),
				.wb_master_we_o		(wb_iperi_we_o),
				.wb_master_sel_o	(wb_iperi_sel_o),
				.wb_master_stb_o	(wb_iperi_stb_o),
				.wb_master_ack_i	(wb_iperi_ack_i)
			);                       

	jelly_jbus_to_wishbone
			#(
				.ADDR_WIDTH			(30),
				.DATA_SIZE			(2) 	// 0:8bit, 1:16bit, 2:32bit ...
			)
		i_jbus_to_wishbone_data
			(
				.reset				(reset),
				.clk				(clk),
				
				.jbus_slave_en		(jbus_dperi_en),
				.jbus_slave_addr	(jbus_dperi_addr),
				.jbus_slave_wdata	(jbus_dderi_wdata),
				.jbus_slave_rdata	(jbus_dperi_rdata),
				.jbus_slave_we		(jbus_dperi_we),
				.jbus_slave_sel		(jbus_dperi_sel),
				.jbus_slave_valid	(jbus_dperi_valid),
				.jbus_slave_ready	(jbus_dperi_ready),

				.wb_master_adr_o	(wb_dperi_adr_o),
				.wb_master_dat_i	(wb_dperi_dat_i),
				.wb_master_dat_o	(wb_dperi_dat_o),
				.wb_master_we_o		(wb_dperi_we_o),
				.wb_master_sel_o	(wb_dperi_sel_o),
				.wb_master_stb_o	(wb_dperi_stb_o),
				.wb_master_ack_i	(wb_dperi_ack_i)
			);                       
	
	// arbiter
	jelly_wishbone_arbiter
			#(
				.WB_ADR_WIDTH		(30),
				.WB_DAT_WIDTH		(32)
			)
		i_wishbone_arbiter
			(
				.reset				(reset),
				.clk				(clk),
				
				.wb_slave0_adr_i	(wb_iperi_adr_o),
				.wb_slave0_dat_i	(wb_iperi_dat_o),
				.wb_slave0_dat_o	(wb_iperi_dat_i),
				.wb_slave0_we_i		(wb_iperi_we_o),
				.wb_slave0_sel_i	(wb_iperi_sel_o),
				.wb_slave0_stb_i	(wb_iperi_stb_o),
				.wb_slave0_ack_o	(wb_iperi_ack_i),
				
				.wb_slave1_adr_i	(wb_dperi_adr_o),
				.wb_slave1_dat_i	(wb_dperi_dat_o),
				.wb_slave1_dat_o	(wb_dperi_dat_i),
				.wb_slave1_we_i		(wb_dperi_we_o),
				.wb_slave1_sel_i	(wb_dperi_sel_o),
				.wb_slave1_stb_i	(wb_dperi_stb_o),
				.wb_slave1_ack_o	(wb_dperi_ack_i),
				
				.wb_master_adr_o	(wb_master_adr_o),
				.wb_master_dat_i	(wb_master_dat_i),
				.wb_master_dat_o	(wb_master_dat_o),
				.wb_master_we_o		(wb_master_we_o),
				.wb_master_sel_o	(wb_master_sel_o),
				.wb_master_stb_o	(wb_master_stb_o),
				.wb_master_ack_i	(wb_master_ack_i)
			);
	
endmodule
