// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// CPU top
module jelly_cpu_top
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
			
			// L1 Cache
			parameter	CACHE_ENABLE     = 0,
			parameter	CACHE_ADDR_MASK  = 30'b1111_0000_0000_0000__0000_0000_0000_00,
			parameter	CACHE_ADDR_VALUE = 30'b0000_0000_0000_0000__0000_0000_0000_00,
			parameter	CACHE_ADDR_WIDTH = 24,
			parameter	CACHE_LINE_SIZE  = 2,		// 2^n (0:1words, 1:2words, 2:4words ...)
			parameter	CACHE_ARRAY_SIZE = 9,		// 2^n (1:2lines, 2:4lines 3:8lines ...)
			
			// memory bus (WISHBONE)
			parameter	WB_MEM_ADR_WIDTH    = 30 - CACHE_LINE_SIZE,
			parameter	WB_MEM_DAT_SIZE     = 2 + CACHE_LINE_SIZE,
			parameter	WB_MEM_DAT_WIDTH    = (8 << MEM_DAT_SIZE),
			parameter	WB_MEM_SEL_WIDTH    = (1 << MEM_DAT_SIZE),
			
			// simulation
			parameter	SIMULATION       = 0
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
			
			// control
			input	wire						pause,
			
			// WISHBONE memory bus (cached)
			output	wire	[31:MEM_DAT_SIZE]	wb_mem_adr_o,
			input	wire	[MEM_DAT_WIDTH-1:0]	wb_mem_dat_i,
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
			
			
			// WISHBONE debug port
			input	wire	[3:0]				wb_dbg_adr_i,
			input	wire	[31:0]				wb_dbg_dat_i,
			output	wire	[31:0]				wb_dbg_dat_o,
			input	wire						wb_dbg_we_i,
			input	wire	[3:0]				wb_dbg_sel_i,
			input	wire						wb_dbg_stb_i,
			output	wire						wb_dbg_ack_o			
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
				.DBBP_NUM			(DBBP_NUM),
				.SIMULATION 		(SIMULATION)
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
	//  Tightly Coupled Memory
	// ---------------------------------

	// non-TCM instruction bus
	wire				jbus_inst0_en;
	wire	[31:2]		jbus_inst0_addr;
	wire	[31:0]		jbus_inst0_wdata;
	wire	[31:0]		jbus_inst0_rdata;
	wire				jbus_inst0_we;
	wire	[3:0]		jbus_inst0_sel;
	wire				jbus_inst0_valid;
	wire				jbus_inst0_ready;
	
	// non-TCM data bus
	wire				jbus_data0_en;
	wire	[31:2]		jbus_data0_addr;
	wire	[31:0]		jbus_data0_wdata;
	wire	[31:0]		jbus_data0_rdata;
	wire				jbus_data0_we;
	wire	[3:0]		jbus_data0_sel;
	wire				jbus_data0_valid;
	wire				jbus_data0_ready;
	
	generate
	if ( TCM_ENABLE ) begin
		// TCM instruction bus
		wire							jbus_itcm_en;
		wire	[TCM_ADDR_WIDTH-1:0]	jbus_itcm_addr;
		wire	[31:0]					jbus_itcm_wdata;
		wire	[31:0]					jbus_itcm_rdata;
		wire							jbus_itcm_we;
		wire	[3:0]					jbus_itcm_sel;
		wire							jbus_itcm_valid;
		wire							jbus_itcm_ready;
	
		// TCM data bus
		wire							jbus_dtcm_en;
		wire	[TCM_ADDR_WIDTH-1:0]	jbus_dtcm_addr;
		wire	[31:0]					jbus_dtcm_wdata;
		wire	[31:0]					jbus_dtcm_rdata;
		wire							jbus_dtcm_we;
		wire	[3:0]					jbus_dtcm_sel;
		wire							jbus_dtcm_valid;
		wire							jbus_dtcm_ready;
		
		// instructuon address decode
		jelly_jbus_decoder
				#(
					.SLAVE_ADDR_WIDTH	(30),
					.SLAVE_DATA_SIZE	(2),	// 0:8bit, 1:16bit, 2:32bit ...
					.DEC_ADDR_MASK		(TCM_ADDR_MASK),
					.DEC_ADDR_VALUE		(TCM_ADDR_VALUE),
					.DEC_ADDR_WIDTH		(TCM_ADDR_WIDTH)
				)
			i_jbus_decoder_tcm_inst
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
									   
					.jbus_master_en		(jbus_inst0_en),
					.jbus_master_addr	(jbus_inst0_addr),
					.jbus_master_wdata	(jbus_inst0_wdata),
					.jbus_master_rdata	(jbus_inst0_rdata),
					.jbus_master_we		(jbus_inst0_we),
					.jbus_master_sel	(jbus_inst0_sel),
					.jbus_master_valid	(jbus_inst0_valid),
					.jbus_master_ready	(jbus_inst0_ready),
									          
					.jbus_decode_en		(jbus_itcm_en),
					.jbus_decode_addr	(jbus_itcm_addr),
					.jbus_decode_wdata	(jbus_itcm_wdata),
					.jbus_decode_rdata	(jbus_itcm_rdata),
					.jbus_decode_we		(jbus_itcm_we),
					.jbus_decode_sel	(jbus_itcm_sel),
					.jbus_decode_valid	(jbus_itcm_valid),
					.jbus_decode_ready	(jbus_itcm_ready)
				);                         
		
		// data address decode
		jelly_jbus_decoder
				#(
					.SLAVE_ADDR_WIDTH	(30),
					.SLAVE_DATA_SIZE	(2),	// 0:8bit, 1:16bit, 2:32bit ...
					.DEC_ADDR_MASK		(TCM_ADDR_MASK),
					.DEC_ADDR_VALUE		(TCM_ADDR_VALUE),
					.DEC_ADDR_WIDTH		(TCM_ADDR_WIDTH)
				)
			jbus_decoder_tcm_data
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
					
					.jbus_master_en		(jbus_data0_en),
					.jbus_master_addr	(jbus_data0_addr),
					.jbus_master_wdata	(jbus_data0_wdata),
					.jbus_master_rdata	(jbus_data0_rdata),
					.jbus_master_we		(jbus_data0_we),
					.jbus_master_sel	(jbus_data0_sel),
					.jbus_master_valid	(jbus_data0_valid),
					.jbus_master_ready	(jbus_data0_ready),
					                       
					.jbus_decode_en		(jbus_dtcm_en),
					.jbus_decode_addr	(jbus_dtcm_addr),
					.jbus_decode_wdata	(jbus_dtcm_wdata),
					.jbus_decode_rdata	(jbus_dtcm_rdata),
					.jbus_decode_we		(jbus_dtcm_we),
					.jbus_decode_sel	(jbus_dtcm_sel),
					.jbus_decode_valid	(jbus_dtcm_valid),
					.jbus_decode_ready	(jbus_dtcm_ready)
				);                         
		
		jelly_jbus_to_ram
				#(
				);
			i_jbus_to_ram_inst
				(
				);
	
		jelly_jbus_to_ram
				#(
				);
			i_jbus_to_ram_data
				(
				);
	
		jelly_ram_dualport
			i_ram_dualport_tcm
				(
				);
	end
	else begin
		assign jbus_inst0_en    = jbus_inst_en;
		assign jbus_inst0_addr  = jbus_inst_addr;
		assign jbus_inst0_wdata = jbus_inst_wdata;
		assign jbus_inst_rdata  = jbus_inst0_rdata;
		assign jbus_inst0_we    = jbus_inst_we;
		assign jbus_inst0_sel   = jbus_inst_sel;
		assign jbus_inst0_valid = jbus_inst_valid;
		assign jbus_inst_ready  = jbus_inst0_ready;
        
		assign jbus_data0_en    = jbus_data_en;
		assign jbus_data0_addr  = jbus_data_addr;
		assign jbus_data0_wdata = jbus_data_wdata;
		assign jbus_data_rdata  = jbus_data0_rdata;
		assign jbus_data0_we    = jbus_data_we;
		assign jbus_data0_sel   = jbus_data_sel;
		assign jbus_data0_valid = jbus_data_valid;
		assign jbus_data_ready  = jbus_data0_ready;
	end                         
	endgenerate
	
	
	
	// ---------------------------------
	// L1 Cache
	// ---------------------------------
	
	// non-Cacheinstruction bus
	wire				jbus_inst1_en;
	wire	[31:2]		jbus_inst1_addr;
	wire	[31:0]		jbus_inst1_wdata;
	wire	[31:0]		jbus_inst1_rdata;
	wire				jbus_inst1_we;
	wire	[3:0]		jbus_inst1_sel;
	wire				jbus_inst1_valid;
	wire				jbus_inst1_ready;
	
	// non-Cache data bus
	wire				jbus_data1_en;
	wire	[31:2]		jbus_data1_addr;
	wire	[31:0]		jbus_data1_wdata;
	wire	[31:0]		jbus_data1_rdata;
	wire				jbus_data1_we;
	wire	[3:0]		jbus_data1_sel;
	wire				jbus_data1_valid;
	wire				jbus_data1_ready;
	
	generate
	if ( CACHE_ENABLE ) begin
		// Cache instruction bus
		wire							jbus_icache_en;
		wire	[CACHE_ADDR_WIDTH-1:0]	jbus_icache_addr;
		wire	[31:0]					jbus_icache_wdata;
		wire	[31:0]					jbus_icache_rdata;
		wire							jbus_icache_we;
		wire	[3:0]					jbus_icache_sel;
		wire							jbus_icache_valid;
		wire							jbus_icache_ready;

		// Cache data bus
		wire							jbus_dcache_en;
		wire	[CACHE_ADDR_WIDTH-1:0]	jbus_dcache_addr;
		wire	[31:0]					jbus_dcache_wdata;
		wire	[31:0]					jbus_dcache_rdata;
		wire							jbus_dcache_we;
		wire	[3:0]					jbus_dcache_sel;
		wire							jbus_dcache_valid;
		wire							jbus_dcache_ready;
	
		// instructuon address decode
		jelly_jbus_decoder
				#(
					.SLAVE_ADDR_WIDTH	(30),
					.SLAVE_DATA_SIZE	(2),	// 0:8bit, 1:16bit, 2:32bit ...
					.DEC_ADDR_MASK		(CACHE_ADDR_MASK),
					.DEC_ADDR_VALUE		(CACHE_ADDR_VALUE),
					.DEC_ADDR_WIDTH		(CACHE_ADDR_WIDTH)
				)
			i_jbus_decoder_cache_inst
				(
					.reset				(reset),
					.clk				(clk),
					
					.jbus_slave_en		(jbus_inst0_en),
					.jbus_slave_addr	(jbus_inst0_addr),
					.jbus_slave_wdata	(jbus_inst0_wdata),
					.jbus_slave_rdata	(jbus_inst0_rdata),
					.jbus_slave_we		(jbus_inst0_we),
					.jbus_slave_sel		(jbus_inst0_sel),
					.jbus_slave_valid	(jbus_inst0_valid),
					.jbus_slave_ready	(jbus_inst0_ready),
									   
					.jbus_master_en		(jbus_inst1_en),
					.jbus_master_addr	(jbus_inst1_addr),
					.jbus_master_wdata	(jbus_inst1_wdata),
					.jbus_master_rdata	(jbus_inst1_rdata),
					.jbus_master_we		(jbus_inst1_we),
					.jbus_master_sel	(jbus_inst1_sel),
					.jbus_master_valid	(jbus_inst1_valid),
					.jbus_master_ready	(jbus_inst1_ready),
									          
					.jbus_decode_en		(jbus_icache_en),
					.jbus_decode_addr	(jbus_icache_addr),
					.jbus_decode_wdata	(jbus_icache_wdata),
					.jbus_decode_rdata	(jbus_icache_rdata),
					.jbus_decode_we		(jbus_icache_we),
					.jbus_decode_sel	(jbus_icache_sel),
					.jbus_decode_valid	(jbus_icache_valid),
					.jbus_decode_ready	(jbus_icache_ready)
				);                         
		
		// data address decode
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
					
					.jbus_slave_en		(jbus_data0_en),
					.jbus_slave_addr	(jbus_data0_addr),
					.jbus_slave_wdata	(jbus_data0_wdata),
					.jbus_slave_rdata	(jbus_data0_rdata),
					.jbus_slave_we		(jbus_data0_we),
					.jbus_slave_sel		(jbus_data0_sel),
					.jbus_slave_valid	(jbus_data0_valid),
					.jbus_slave_ready	(jbus_data0_ready),
									   
					.jbus_master_en		(jbus_data1_en),
					.jbus_master_addr	(jbus_data1_addr),
					.jbus_master_wdata	(jbus_data1_wdata),
					.jbus_master_rdata	(jbus_data1_rdata),
					.jbus_master_we		(jbus_data1_we),
					.jbus_master_sel	(jbus_data1_sel),
					.jbus_master_valid	(jbus_data1_valid),
					.jbus_master_ready	(jbus_data1_ready),
									          
					.jbus_decode_en		(jbus_dcache_en),
					.jbus_decode_addr	(jbus_dcache_addr),
					.jbus_decode_wdata	(jbus_dcache_wdata),
					.jbus_decode_rdata	(jbus_dcache_rdata),
					.jbus_decode_we		(jbus_dcache_we),
					.jbus_decode_sel	(jbus_dcache_sel),
					.jbus_decode_valid	(jbus_dcache_valid),
					.jbus_decode_ready	(jbus_dcache_ready)
				);
		
		// Cache
		jelly_cache_unified
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
					
					.jbus_slave0_en		(jbus_icache_en),
					.jbus_slave0_addr	(jbus_icache_addr),
					.jbus_slave0_wdata	(jbus_icache_wdata),
					.jbus_slave0_rdata	(jbus_icache_rdata),
					.jbus_slave0_we		(jbus_icache_we),
					.jbus_slave0_sel	(jbus_icache_sel),
					.jbus_slave0_valid	(jbus_icache_valid),
					.jbus_slave0_ready	(jbus_icache_ready),
					
					.jbus_slave1_en		(jbus_dcache_en),
					.jbus_slave1_addr	(jbus_dcache_addr),
					.jbus_slave1_wdata	(jbus_dcache_wdata),
					.jbus_slave1_rdata	(jbus_dcache_rdata),
					.jbus_slave1_we		(jbus_dcache_we),
					.jbus_slave1_sel	(jbus_dcache_sel),
					.jbus_slave1_valid	(jbus_dcache_valid),
					.jbus_slave1_ready	(jbus_dcache_ready),
					
					.wb_master_adr_o	(wb_mem_adr_o),
					.wb_master_dat_i	(wb_mem_dat_i),
					.wb_master_dat_o	(wb_mem_dat_o),
					.wb_master_we_o		(wb_mem_we_o),
					.wb_master_sel_o	(wb_mem_sel_o),
					.wb_master_stb_o	(wb_mem_stb_o),
					.wb_master_ack_i	(wb_mem_ack_i)
				);                     
	end
	else begin
		assign jbus_inst1_en    = jbus_inst0_en;
		assign jbus_inst1_addr  = jbus_inst0_addr;
		assign jbus_inst1_wdata = jbus_inst0_wdata;
		assign jbus_inst0_rdata = jbus_inst1_rdata;
		assign jbus_inst1_we    = jbus_inst0_we;
		assign jbus_inst1_sel   = jbus_inst0_sel;
		assign jbus_inst1_valid = jbus_inst0_valid;
		assign jbus_inst0_ready = jbus_inst1_ready;
        
		assign jbus_data1_en    = jbus_data0_en;
		assign jbus_data1_addr  = jbus_data0_addr;
		assign jbus_data1_wdata = jbus_data0_wdata;
		assign jbus_data0_rdata = jbus_data1_rdata;
		assign jbus_data1_we    = jbus_data0_we;
		assign jbus_data1_sel   = jbus_data0_sel;
		assign jbus_data1_valid = jbus_data0_valid;
		assign jbus_data0_ready = jbus_data1_ready;
		
		assign wb_mem_adr_o     = {WB_MEM_ADR_WIDTH{1'b0}};
		assign wb_mem_dat_o     = {WB_MEM_DAT_WIDTH{1'b0}}; 
		assign wb_mem_we_o      = 1'b0;
		assign wb_mem_sel_o     = {WB_MEM_SEL_WIDTH{1'b0}};
		assign wb_mem_stb_o     = 1'b0;
	end
	endgenerate
	
		
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
		i_jbus_to_wishbone_peri_inst
			(
				.reset				(reset),
				.clk				(clk),
				
				.jbus_slave_en		(jbus_inst1_en),
				.jbus_slave_addr	(jbus_inst1_addr),
				.jbus_slave_wdata	(jbus_inst1_wdata),
				.jbus_slave_rdata	(jbus_inst1_rdata),
				.jbus_slave_we		(jbus_inst1_we),
				.jbus_slave_sel		(jbus_inst1_sel),
				.jbus_slave_valid	(jbus_inst1_valid),
				.jbus_slave_ready	(jbus_inst1_ready),

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
		i_jbus_to_wishbone_peri_data
			(
				.reset				(reset),
				.clk				(clk),
				
				.jbus_slave_en		(jbus_data1_en),
				.jbus_slave_addr	(jbus_data1_addr),
				.jbus_slave_wdata	(jbus_data1_wdata),
				.jbus_slave_rdata	(jbus_data1_rdata),
				.jbus_slave_we		(jbus_data1_we),
				.jbus_slave_sel		(jbus_data1_sel),
				.jbus_slave_valid	(jbus_data1_valid),
				.jbus_slave_ready	(jbus_data1_ready),

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
		i_wishbone_arbiter_peri
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
				
				.wb_master_adr_o	(wb_peri_adr_o),
				.wb_master_dat_i	(wb_peri_dat_i),
				.wb_master_dat_o	(wb_peri_dat_o),
				.wb_master_we_o		(wb_peri_we_o),
				.wb_master_sel_o	(wb_peri_sel_o),
				.wb_master_stb_o	(wb_peri_stb_o),
				.wb_master_ack_i	(wb_peri_ack_i)
			);
	
endmodule
