// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    MIPS like CPU core
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



module jelly_cpu_unified_cache
		#(
			parameter	LINE_SIZE         = 2,		// 2^n (0:1words, 1:2words, 2:4words ...)
			parameter	ARRAY_SIZE        = 8,		// 2^n (1:2lines, 2:4lines 3:8lines ...)
			parameter	LINE_WORDS        = (1 << LINE_SIZE),
			
			parameter	SLAVE_ADDR_WIDTH  = 24,
			parameter	SLAVE_DATA_SIZE   = 2,		// 2^n (0:8bit, 1:16bit, 2:32bit ...)
			parameter	SLAVE_DATA_WIDTH  = (8 << SLAVE_DATA_SIZE),
			parameter	SLAVE_SEL_WIDTH   = (1 << SLAVE_DATA_SIZE),
			
			parameter	MASTER_ADR_WIDTH  = SLAVE_ADDR_WIDTH - LINE_SIZE,
			parameter	MASTER_DAT_SIZE   = SLAVE_DATA_SIZE + LINE_SIZE,
			parameter	MASTER_DAT_WIDTH  = (8 << MASTER_DAT_SIZE),
			parameter	MASTER_SEL_WIDTH  = (1 << MASTER_DAT_SIZE),
						
			parameter	CACHE_OFFSET_WIDTH = LINE_SIZE,
			parameter	CACHE_INDEX_WIDTH  = ARRAY_SIZE,
			parameter	CACHE_TAGADR_WIDTH = SLAVE_ADDR_WIDTH - (CACHE_INDEX_WIDTH + CACHE_OFFSET_WIDTH),
			parameter	CACHE_DATA_WIDTH   = MASTER_DAT_WIDTH,

			parameter	RAM_ADDR_WIDTH     = CACHE_INDEX_WIDTH,
			parameter	RAM_DATA_WIDTH     = 1 + CACHE_TAGADR_WIDTH + CACHE_DATA_WIDTH
		)
		(
			// system
			input	wire							reset,
			input	wire							clk,
			
			// endian
			input	wire							endian,
			
			// slave port0
			input	wire							jbus_slave0_en,
			input	wire	[SLAVE_ADDR_WIDTH-1:0]	jbus_slave0_addr,
			input	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave0_wdata,
			output	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave0_rdata,
			input	wire							jbus_slave0_we,
			input	wire	[SLAVE_SEL_WIDTH-1:0]	jbus_slave0_sel,
			input	wire							jbus_slave0_valid,
			output	wire							jbus_slave0_ready,
			
			// slave port1
			input	wire							jbus_slave1_en,
			input	wire	[SLAVE_ADDR_WIDTH-1:0]	jbus_slave1_addr,
			input	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave1_wdata,
			output	wire	[SLAVE_DATA_WIDTH-1:0]	jbus_slave1_rdata,
			input	wire							jbus_slave1_we,
			input	wire	[SLAVE_SEL_WIDTH-1:0]	jbus_slave1_sel,
			input	wire							jbus_slave1_valid,
			output	wire							jbus_slave1_ready,
			
			// master port0
			output	wire	[MASTER_ADR_WIDTH-1:0]	wb_master_adr_o,
			input	wire	[MASTER_DAT_WIDTH-1:0]	wb_master_dat_i,
			output	wire	[MASTER_DAT_WIDTH-1:0]	wb_master_dat_o,
			output	wire							wb_master_we_o,
			output	wire	[MASTER_SEL_WIDTH-1:0]	wb_master_sel_o,
			output	wire							wb_master_stb_o,
			input	wire							wb_master_ack_i
		);
	
	wire	[MASTER_ADR_WIDTH-1:0]	wb_master0_adr_o;
	wire	[MASTER_DAT_WIDTH-1:0]	wb_master0_dat_i;
	wire	[MASTER_DAT_WIDTH-1:0]	wb_master0_dat_o;
	wire							wb_master0_we_o;
	wire	[MASTER_SEL_WIDTH-1:0]	wb_master0_sel_o;
	wire							wb_master0_stb_o;
	wire							wb_master0_ack_i;

	wire	[MASTER_ADR_WIDTH-1:0]	wb_master1_adr_o;
	wire	[MASTER_DAT_WIDTH-1:0]	wb_master1_dat_i;
	wire	[MASTER_DAT_WIDTH-1:0]	wb_master1_dat_o;
	wire							wb_master1_we_o;
	wire	[MASTER_SEL_WIDTH-1:0]	wb_master1_sel_o;
	wire							wb_master1_stb_o;
	wire							wb_master1_ack_i;
	
	wire							ram0_en;
	wire							ram0_we;
	wire	[RAM_ADDR_WIDTH-1:0]	ram0_addr;
	wire	[RAM_DATA_WIDTH-1:0]	ram0_wdata;
	wire	[RAM_DATA_WIDTH-1:0]	ram0_rdata;

	wire							ram1_en;
	wire							ram1_we;
	wire	[RAM_ADDR_WIDTH-1:0]	ram1_addr;
	wire	[RAM_DATA_WIDTH-1:0]	ram1_wdata;
	wire	[RAM_DATA_WIDTH-1:0]	ram1_rdata;
	
	// cache0
	jelly_wishbone_cache
			#(
				.LINE_SIZE			(LINE_SIZE),
				.ARRAY_SIZE			(ARRAY_SIZE),
				.SLAVE_ADDR_WIDTH	(SLAVE_ADDR_WIDTH),
				.SLAVE_DATA_SIZE	(SLAVE_DATA_SIZE)
			)
		i_wishbone_cache_0
			(
				.clk				(clk),
				.reset				(reset),
				.endian				(endian),
				
				.jbus_slave_en		(jbus_slave0_en),
				.jbus_slave_addr	(jbus_slave0_addr),
				.jbus_slave_wdata	(jbus_slave0_wdata),
				.jbus_slave_rdata	(jbus_slave0_rdata),
				.jbus_slave_we		(jbus_slave0_we),
				.jbus_slave_sel		(jbus_slave0_sel),
				.jbus_slave_valid	(jbus_slave0_valid),
				.jbus_slave_ready	(jbus_slave0_ready),
				
				.wb_master_adr_o	(wb_master0_adr_o),
				.wb_master_dat_o	(wb_master0_dat_o),
				.wb_master_dat_i	(wb_master0_dat_i),
				.wb_master_we_o		(wb_master0_we_o),
				.wb_master_sel_o	(wb_master0_sel_o),
				.wb_master_stb_o	(wb_master0_stb_o),
				.wb_master_ack_i	(wb_master0_ack_i),
				
				.ram_en				(ram0_en),
				.ram_we				(ram0_we),
				.ram_addr			(ram0_addr),
				.ram_wdata			(ram0_wdata),
				.ram_rdata			(ram0_rdata)
			);
	
	// cache1
	jelly_wishbone_cache
			#(
				.LINE_SIZE			(LINE_SIZE),
				.ARRAY_SIZE			(ARRAY_SIZE),
				.SLAVE_ADDR_WIDTH	(SLAVE_ADDR_WIDTH),
				.SLAVE_DATA_SIZE	(SLAVE_DATA_SIZE)
			)
		i_wishbone_cache_1
			(
				.clk				(clk),
				.reset				(reset),
				.endian				(endian),
				
				.jbus_slave_en		(jbus_slave1_en),
				.jbus_slave_addr	(jbus_slave1_addr),
				.jbus_slave_wdata	(jbus_slave1_wdata),
				.jbus_slave_rdata	(jbus_slave1_rdata),
				.jbus_slave_we		(jbus_slave1_we),
				.jbus_slave_sel		(jbus_slave1_sel),
				.jbus_slave_valid	(jbus_slave1_valid),
				.jbus_slave_ready	(jbus_slave1_ready),
				
				.wb_master_adr_o	(wb_master1_adr_o),
				.wb_master_dat_o	(wb_master1_dat_o),
				.wb_master_dat_i	(wb_master1_dat_i),
				.wb_master_we_o		(wb_master1_we_o),
				.wb_master_sel_o	(wb_master1_sel_o),
				.wb_master_stb_o	(wb_master1_stb_o),
				.wb_master_ack_i	(wb_master1_ack_i),
				
				.ram_en				(ram1_en),
				.ram_we				(ram1_we),
				.ram_addr			(ram1_addr),
				.ram_wdata			(ram1_wdata),
				.ram_rdata			(ram1_rdata)
			);
	
	// ram
	jelly_ram_dualport
			#(
				.DATA_WIDTH			(RAM_DATA_WIDTH),
				.ADDR_WIDTH			(RAM_ADDR_WIDTH)
			)
		i_ram_dualport
			(
				.clk0				(clk),
				.en0				(ram0_en),
				.we0				(ram0_we),
				.addr0				(ram0_addr),
				.din0				(ram0_wdata),
				.dout0				(ram0_rdata),

				.clk1				(clk),
				.en1				(ram1_en),
				.we1				(ram1_we),
				.addr1				(ram1_addr),
				.din1				(ram1_wdata),
				.dout1				(ram1_rdata)
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
				
				.wb_slave0_adr_i	(wb_master0_adr_o),
				.wb_slave0_dat_i	(wb_master0_dat_o),
				.wb_slave0_dat_o	(wb_master0_dat_i),
				.wb_slave0_we_i		(wb_master0_we_o),
				.wb_slave0_sel_i	(wb_master0_sel_o),
				.wb_slave0_stb_i	(wb_master0_stb_o),
				.wb_slave0_ack_o	(wb_master0_ack_i),
				
				.wb_slave1_adr_i	(wb_master1_adr_o),
				.wb_slave1_dat_i	(wb_master1_dat_o),
				.wb_slave1_dat_o	(wb_master1_dat_i),
				.wb_slave1_we_i		(wb_master1_we_o),
				.wb_slave1_sel_i	(wb_master1_sel_o),
				.wb_slave1_stb_i	(wb_master1_stb_o),
				.wb_slave1_ack_o	(wb_master1_ack_i),
				
				.wb_master_adr_o	(wb_master_adr_o),
				.wb_master_dat_i	(wb_master_dat_i),
				.wb_master_dat_o	(wb_master_dat_o),
				.wb_master_we_o		(wb_master_we_o),
				.wb_master_sel_o	(wb_master_sel_o),
				.wb_master_stb_o	(wb_master_stb_o),
				.wb_master_ack_i	(wb_master_ack_i)
			);
	
endmodule


// end of file
