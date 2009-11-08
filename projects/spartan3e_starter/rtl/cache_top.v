// ---------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                 Copyright (C) 2008-2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// top module
module cache_top
		#(
			parameter					SIMULATION = 1'b0
		)
		(
			// system
			input	wire				in_clk,
			input	wire				in_reset,
			
			// GPIO
			inout	wire	[3:0]		gpio_a,
			inout	wire	[3:0]		gpio_b,
			
			// uart
			output	wire				uart0_tx,
			input	wire				uart0_rx,
			
			output	wire				uart1_tx,
			input	wire				uart1_rx,
			
			// DDR-SDRAM
			output	wire				ddr_sdram_ck_p,
			output	wire				ddr_sdram_ck_n,
			output	wire				ddr_sdram_cke,
			output	wire				ddr_sdram_cs,
			output	wire				ddr_sdram_ras,
			output	wire				ddr_sdram_cas,
			output	wire				ddr_sdram_we,
			output	wire	[1:0]		ddr_sdram_ba,
			output	wire	[12:0]		ddr_sdram_a,
			inout	wire	[15:0]		ddr_sdram_dq,
			output	wire				ddr_sdram_udm,
			output	wire				ddr_sdram_ldm,
			inout	wire				ddr_sdram_udqs,
			inout	wire				ddr_sdram_ldqs,
			input	wire				ddr_sdram_ck_fb,
			
			// UI
			output	wire	[7:0]		led,
			input	wire	[3:0]		sw
		);
	
	
	
	// -----------------------------
	//  system
	// -----------------------------
	
	// endian
	wire				endian;
	assign endian = 1'b1;			// 0:little, 1:big
	
	
	// clock
	wire				reset;
	wire				clk;
	wire				clk_x2;
	wire				clk_x2_90;
	wire				clk_uart;
	
	wire				locked;
	
	// reset

	clkgen
		i_clkgen
			(
				.in_reset			(in_reset), 
				.in_clk				(in_clk), 
			
				.out_clk			(clk),
				.out_clk_x2			(clk_x2),
				.out_clk_x2_90		(clk_x2_90),
				.out_clk_uart		(clk_uart),
				.out_reset			(reset),
				
				.locked				(locked)
		);
	
	
	
	// UART switch
	wire				uart_tx;
	wire				uart_rx;
	wire				dbg_uart_tx;
	wire				dbg_uart_rx;
	
	assign uart0_tx    = ~sw[0] ? uart_tx  : dbg_uart_tx;
	assign uart1_tx    =  sw[0] ? uart_tx  : dbg_uart_tx;
	assign uart_rx     = ~sw[0] ? uart0_rx : uart1_rx;
	assign dbg_uart_rx = ~sw[0] ? uart1_rx : uart0_rx;
	
	
	
	// -----------------------------
	//  cpu
	// -----------------------------
	
	// interrupt
	wire			cpu_irq;
	wire			cpu_irq_ack;
		
	// memory bus (cached)
	wire	[31:3]	wb_mem_adr_o;
	wire	[63:0]	wb_mem_dat_i;
	wire	[63:0]	wb_mem_dat_o;
	wire			wb_mem_we_o;
	wire	[7:0]	wb_mem_sel_o;
	wire			wb_mem_stb_o;
	wire			wb_mem_ack_i;
	
	// peripheral bus (non-cache)
	wire	[31:2]	wb_peri_adr_o;
	wire	[31:0]	wb_peri_dat_i;
	wire	[31:0]	wb_peri_dat_o;
	wire			wb_peri_we_o;
	wire	[3:0]	wb_peri_sel_o;
	wire			wb_peri_stb_o;
	wire			wb_peri_ack_i;
	
	// cpu debug port
	wire	[3:0]	wb_dbg_adr_o;
	wire	[31:0]	wb_dbg_dat_i;
	wire	[31:0]	wb_dbg_dat_o;
	wire			wb_dbg_we_o;
	wire	[3:0]	wb_dbg_sel_o;
	wire			wb_dbg_stb_o;
	wire			wb_dbg_ack_i;
		
	// CPU
	jelly_cpu_cache_top
			#(
				.USE_DBUGGER		(1'b1),
				.USE_EXC_SYSCALL	(1'b1),
				.USE_EXC_BREAK		(1'b1),
				.USE_EXC_RI			(1'b1),
				.GPR_TYPE			(1),
				.MUL_CYCLE			(0),
				.DBBP_NUM			(4),
				
				.CACHE_LINE_SIZE	(1),	// 2^n (0:1words, 1:2words, 2:4words ...)
				.CACHE_ARRAY_SIZE	(9),	// 2^n (1:2lines, 2:4lines 3:8lines ...)
				
				.CACHE_ADDR_MASK	(30'b1110_0000_0000_0000__0000_0000_0000_00),
				.CACHE_ADDR_VALUE	(30'b0000_0000_0000_0000__0000_0000_0000_00),
				.CACHE_ADDR_WIDTH	(30),
				
				.MEM_ADR_WIDTH		(25),
				
				.SIMULATION			(SIMULATION)
			)
		i_cpu_top
			(
				.reset				(reset),
				.clk				(clk),
				.clk_x2				(clk_x2),
				
				.endian				(endian),
				
				.vect_reset			(32'h0000_0000),
				.vect_interrupt		(32'h0000_0180),
				.vect_exception		(32'h0000_0180),
				
				.interrupt_req		(cpu_irq),
				.interrupt_ack		(cpu_irq_ack),
				
				.wb_mem_adr_o		(wb_mem_adr_o),
				.wb_mem_dat_i		(wb_mem_dat_i),
				.wb_mem_dat_o		(wb_mem_dat_o),
				.wb_mem_we_o		(wb_mem_we_o),
				.wb_mem_sel_o		(wb_mem_sel_o),
				.wb_mem_stb_o		(wb_mem_stb_o),
				.wb_mem_ack_i		(wb_mem_ack_i),
				
				.wb_peri_adr_o		(wb_peri_adr_o),
				.wb_peri_dat_i		(wb_peri_dat_i),
				.wb_peri_dat_o		(wb_peri_dat_o),
				.wb_peri_we_o		(wb_peri_we_o),
				.wb_peri_sel_o		(wb_peri_sel_o),
				.wb_peri_stb_o		(wb_peri_stb_o),
				.wb_peri_ack_i		(wb_peri_ack_i),
				
				.wb_dbg_adr_i		(wb_dbg_adr_o),
				.wb_dbg_dat_i		(wb_dbg_dat_o),
				.wb_dbg_dat_o		(wb_dbg_dat_i),
				.wb_dbg_we_i		(wb_dbg_we_o),
				.wb_dbg_sel_i		(wb_dbg_sel_o),
				.wb_dbg_stb_i		(wb_dbg_stb_o),
				.wb_dbg_ack_o		(wb_dbg_ack_i),
				
				.pause				(1'b0)
			);
	
	// Debug Interface (UART)
	jelly_uart_debugger
			#(
				.TX_FIFO_PTR_WIDTH	(10),
				.RX_FIFO_PTR_WIDTH	(10)
			)
		i_uart_debugger
			(
				.reset				(reset),
				.clk				(clk),
				.endian				(endian),
				
				.uart_clk			(clk_uart),
				.uart_tx			(dbg_uart_tx),
				.uart_rx			(dbg_uart_rx),
				
				.wb_adr_o			(wb_dbg_adr_o),
				.wb_dat_i			(wb_dbg_dat_i),
				.wb_dat_o			(wb_dbg_dat_o),
				.wb_we_o			(wb_dbg_we_o),
				.wb_sel_o			(wb_dbg_sel_o),
				.wb_stb_o			(wb_dbg_stb_o),
				.wb_ack_i			(wb_dbg_ack_i)
			);
	
	
	// -----------------------------
	//  boot rom
	// -----------------------------
	
	wire	[31:3]		wb_rom_adr_i;
	wire	[63:0]		wb_rom_dat_o;
	wire	[63:0]		wb_rom_dat_i;
	wire	[7:0]		wb_rom_sel_i;
	wire				wb_rom_we_i;
	wire				wb_rom_stb_i;
	wire				wb_rom_ack_o;
	
	
	wire	[31:2]		wb_rom32_adr_o;
	wire	[31:0]		wb_rom32_dat_i;
	wire	[31:0]		wb_rom32_dat_o;
	wire	[3:0]		wb_rom32_sel_o;
	wire				wb_rom32_we_o;
	wire				wb_rom32_stb_o;
	wire				wb_rom32_ack_i;
	
	jelly_wishbone_width_converter
			#(
				.SLAVE_DAT_SIZE		(3),	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.MASTER_DAT_SIZE	(2),	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.SLAVE_ADR_WIDTH	(29)
			)
		i_wishbone_width_converter_rom
			(
				.clk				(clk),
				.reset				(reset),

				.endian				(endian),

				.wb_slave_adr_i		(wb_rom_adr_i),
				.wb_slave_dat_o		(wb_rom_dat_o),
				.wb_slave_dat_i		(wb_rom_dat_i),
				.wb_slave_we_i		(wb_rom_we_i),
				.wb_slave_sel_i		(wb_rom_sel_i),
				.wb_slave_stb_i		(wb_rom_stb_i),
				.wb_slave_ack_o		(wb_rom_ack_o),
                                 
				.wb_master_adr_o	(wb_rom32_adr_o),
				.wb_master_dat_o	(wb_rom32_dat_o),
				.wb_master_dat_i	(wb_rom32_dat_i),
				.wb_master_we_o		(wb_rom32_we_o),
				.wb_master_sel_o	(wb_rom32_sel_o),
				.wb_master_stb_o	(wb_rom32_stb_o),
				.wb_master_ack_i	(wb_rom32_ack_i)
			);
	
	jelly_sram
			#(
				.WB_ADR_WIDTH		(12),
				.WB_DAT_WIDTH		(32),
				.READMEMH			(1),
				.READMEM_FILE		("sample.hex")
			)
		i_sram_rom
			(
				.reset				(reset),
				.clk				(clk),
				
				.wb_adr_i			(wb_rom32_adr_o[17:2]), // [13:2]),
				.wb_dat_o			(wb_rom32_dat_i),
				.wb_dat_i			(wb_rom32_dat_o),
				.wb_we_i			(wb_rom32_we_o),
				.wb_sel_i			(wb_rom32_sel_o),
				.wb_stb_i			(wb_rom32_stb_o),
				.wb_ack_o			(wb_rom32_ack_i)
			);
	
	/*
	boot_rom
		i_boot_rom
			(
				.clk				(~clk),
				.addr				(wb_rom32_adr_o[13:2]),
				.data				(wb_rom32_dat_i)
			);
	assign wb_rom32_ack_i = 1'b1;
	*/
	
	
	// -----------------------------
	//  DDR-SDRAM (MT46V32M16TG-6T)
	// -----------------------------
	
	wire	[31:3]		wb_dram_adr_i;
	wire	[63:0]		wb_dram_dat_o;
	wire	[63:0]		wb_dram_dat_i;
	wire	[7:0]		wb_dram_sel_i;
	wire				wb_dram_we_i;
	wire				wb_dram_stb_i;
	wire				wb_dram_ack_o;
		
	wire	[31:3]		wb_dram2x_adr_o;
	wire	[63:0]		wb_dram2x_dat_i;
	wire	[63:0]		wb_dram2x_dat_o;
	wire	[7:0]		wb_dram2x_sel_o;
	wire				wb_dram2x_we_o;
	wire				wb_dram2x_stb_o;
	wire				wb_dram2x_ack_i;
	
	jelly_wishbone_clk2x
			#(
				.WB_ADR_WIDTH		(29),
				.WB_DAT_WIDTH		(64)
			)
		i_wishbone_clk2x
			(
				.reset				(reset),
				.clk				(clk),
				.clk2x				(clk_x2),
				
				.wb_adr_i			(wb_dram_adr_i),
				.wb_dat_o			(wb_dram_dat_o),
				.wb_dat_i			(wb_dram_dat_i),
				.wb_we_i			(wb_dram_we_i),
				.wb_sel_i			(wb_dram_sel_i),
				.wb_stb_i			(wb_dram_stb_i),
				.wb_ack_o			(wb_dram_ack_o),
                
				.wb_2x_adr_o		(wb_dram2x_adr_o),
				.wb_2x_dat_o		(wb_dram2x_dat_o),
				.wb_2x_dat_i		(wb_dram2x_dat_i),
				.wb_2x_we_o			(wb_dram2x_we_o),
				.wb_2x_sel_o		(wb_dram2x_sel_o),
				.wb_2x_stb_o		(wb_dram2x_stb_o),
				.wb_2x_ack_i		(wb_dram2x_ack_i)
			);
	
	
	wire	[31:2]		wb_dram32_adr_o;
	wire	[31:0]		wb_dram32_dat_i;
	wire	[31:0]		wb_dram32_dat_o;
	wire	[3:0]		wb_dram32_sel_o;
	wire				wb_dram32_we_o;
	wire				wb_dram32_stb_o;
	wire				wb_dram32_ack_i;
	
	jelly_wishbone_width_converter
			#(
				.SLAVE_DAT_SIZE		(3),	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.MASTER_DAT_SIZE	(2),	// 2^n (0:8bit, 1:16bit, 2:32bit ...)
				.SLAVE_ADR_WIDTH	(29)
			)
		i_wishbone_width_converter_sdram
			(
				.clk				(clk_x2),
				.reset				(reset),

				.endian				(endian),

				.wb_slave_adr_i		(wb_dram2x_adr_o),
				.wb_slave_dat_o		(wb_dram2x_dat_i),
				.wb_slave_dat_i		(wb_dram2x_dat_o),
				.wb_slave_we_i		(wb_dram2x_we_o),
				.wb_slave_sel_i		(wb_dram2x_sel_o),
				.wb_slave_stb_i		(wb_dram2x_stb_o),
				.wb_slave_ack_o		(wb_dram2x_ack_i),
                                        
				.wb_master_adr_o	(wb_dram32_adr_o),
				.wb_master_dat_o	(wb_dram32_dat_o),
				.wb_master_dat_i	(wb_dram32_dat_i),
				.wb_master_we_o		(wb_dram32_we_o),
				.wb_master_sel_o	(wb_dram32_sel_o),
				.wb_master_stb_o	(wb_dram32_stb_o),
				.wb_master_ack_i	(wb_dram32_ack_i)
			);                       
	
	jelly_ddr_sdram
			#(
				.SIMULATION			(SIMULATION)
			)
		i_ddr_sdram
			(
				.reset				(reset),
				.clk				(clk_x2),
				.clk90				(clk_x2_90),
				
				.endian				(endian),
				
				.wb_adr_i			(wb_dram32_adr_o[25:2]),
				.wb_dat_o			(wb_dram32_dat_i),
				.wb_dat_i			(wb_dram32_dat_o),
				.wb_we_i			(wb_dram32_we_o),
				.wb_sel_i			(wb_dram32_sel_o),
				.wb_stb_i			(wb_dram32_stb_o),
				.wb_ack_o			(wb_dram32_ack_i),
				
				.ddr_sdram_ck_p		(ddr_sdram_ck_p),
				.ddr_sdram_ck_n		(ddr_sdram_ck_n),
				.ddr_sdram_cke		(ddr_sdram_cke),
				.ddr_sdram_cs		(ddr_sdram_cs),
				.ddr_sdram_ras		(ddr_sdram_ras),
				.ddr_sdram_cas		(ddr_sdram_cas),
				.ddr_sdram_we		(ddr_sdram_we),
				.ddr_sdram_ba		(ddr_sdram_ba),
				.ddr_sdram_a		(ddr_sdram_a),
				.ddr_sdram_dm		({ddr_sdram_udm, ddr_sdram_ldm}),
				.ddr_sdram_dq		(ddr_sdram_dq),
				.ddr_sdram_dqs		({ddr_sdram_udqs, ddr_sdram_ldqs})
			);
	
	
	// -----------------------------
	//  memory bus address decoder
	// -----------------------------
	
	assign wb_rom_adr_i   = wb_mem_adr_o;
	assign wb_rom_dat_i   = wb_mem_dat_o;
	assign wb_rom_sel_i   = wb_mem_sel_o;
	assign wb_rom_we_i    = wb_mem_we_o;
	assign wb_rom_stb_i   = wb_mem_stb_o & (wb_mem_adr_o[31:24] == 8'h00) & sw[1];

	assign wb_dram_adr_i = wb_mem_adr_o;
	assign wb_dram_dat_i = wb_mem_dat_o;
	assign wb_dram_sel_i = wb_mem_sel_o;
	assign wb_dram_we_i  = wb_mem_we_o;
	assign wb_dram_stb_i = wb_mem_stb_o & !wb_rom_stb_i; // (wb_mem_adr_o[31:24] == 8'h01);
	
	assign wb_mem_dat_i  = wb_rom_stb_i  ? wb_rom_dat_o  :
						   wb_dram_stb_i ? wb_dram_dat_o :
						   64'hxxxx_xxxx_xxxx_xxxx;

	assign wb_mem_ack_i  = wb_rom_stb_i  ? wb_rom_ack_o  :
						   wb_dram_stb_i ? wb_dram_ack_o :
						   1'b1;
	
	
	
	
	// -----------------------------
	//  IRC
	// -----------------------------
	
	// irq
	wire				timer0_irq;
	wire				uart0_irq_rx;
	wire				uart0_irq_tx;
	
	// irq map
	wire	[2:0]		irc_interrupt;
	assign irc_interrupt[0] = timer0_irq;
	assign irc_interrupt[1] = uart0_irq_rx;
	assign irc_interrupt[2] = uart0_irq_tx;
	
	
	// irc
	wire	[31:2]		wb_irc_adr_i;
	wire	[31:0]		wb_irc_dat_i;
	wire	[31:0]		wb_irc_dat_o;
	wire	[3:0]		wb_irc_sel_i;
	wire				wb_irc_we_i;
	wire				wb_irc_stb_i;
	wire				wb_irc_ack_o;
	
	jelly_irc
			#(
				.FACTOR_ID_WIDTH	(2),
				.FACTOR_NUM			(3),
				.PRIORITY_WIDTH		(2),
	
				.WB_ADR_WIDTH		(14),
				.WB_DAT_WIDTH		(32)
			)
		i_irc
			(
				.clk				(clk),
				.reset				(reset),

				.in_interrupt		(irc_interrupt),

				.cpu_irq			(cpu_irq),
				.cpu_irq_ack		(cpu_irq_ack),
											
				.wb_adr_i			(wb_irc_adr_i[15:2]),
				.wb_dat_o			(wb_irc_dat_o),
				.wb_dat_i			(wb_irc_dat_i),
				.wb_we_i			(wb_irc_we_i),
				.wb_sel_i			(wb_irc_sel_i),
				.wb_stb_i			(wb_irc_stb_i),
				.wb_ack_o			(wb_irc_ack_o)
			);                     
	
	
	// -----------------------------
	//  Timer0
	// -----------------------------
	
	wire	[31:2]		wb_timer0_adr_i;
	wire	[31:0]		wb_timer0_dat_i;
	wire	[31:0]		wb_timer0_dat_o;
	wire	[3:0]		wb_timer0_sel_i;
	wire				wb_timer0_we_i;
	wire				wb_timer0_stb_i;
	wire				wb_timer0_ack_o;
	
	jelly_timer
		i_timer0
			(
				.clk				(clk),
				.reset				(reset),
				
				.interrupt_req		(timer0_irq),

				.wb_adr_i			(wb_timer0_adr_i[3:2]),
				.wb_dat_o			(wb_timer0_dat_o),
				.wb_dat_i			(wb_timer0_dat_i),
				.wb_we_i			(wb_timer0_we_i),
				.wb_sel_i			(wb_timer0_sel_i),
				.wb_stb_i			(wb_timer0_stb_i),
				.wb_ack_o			(wb_timer0_ack_o)
			);                     
	
	
	// -----------------------------
	//  UART
	// -----------------------------
	
	wire	[31:2]		wb_uart0_adr_i;
	wire	[31:0]		wb_uart0_dat_i;
	wire	[31:0]		wb_uart0_dat_o;
	wire	[3:0]		wb_uart0_sel_i;
	wire				wb_uart0_we_i;
	wire				wb_uart0_stb_i;
	wire				wb_uart0_ack_o;

	jelly_uart
			#(
				.TX_FIFO_PTR_WIDTH	(2),
				.RX_FIFO_PTR_WIDTH	(2)
			)
		i_uart0
			(
				.clk				(clk),
				.reset				(reset),
				
				.uart_clk			(clk_uart),
				.uart_tx			(uart_tx),
				.uart_rx			(uart_rx),
				
				.irq_rx				(uart0_irq_rx),
				.irq_tx				(uart0_irq_tx),
				
				.wb_adr_i			(wb_uart0_adr_i[3:2]),
				.wb_dat_o			(wb_uart0_dat_o),
				.wb_dat_i			(wb_uart0_dat_i),
				.wb_we_i			(wb_uart0_we_i),
				.wb_sel_i			(wb_uart0_sel_i),
				.wb_stb_i			(wb_uart0_stb_i),
				.wb_ack_o			(wb_uart0_ack_o)
			);                     
	
	

	// -----------------------------
	//  GPIO A
	// -----------------------------

	wire	[31:2]		wb_gpioa_adr_i;
	wire	[31:0]		wb_gpioa_dat_i;
	wire	[31:0]		wb_gpioa_dat_o;
	wire	[3:0]		wb_gpioa_sel_i;
	wire				wb_gpioa_we_i;
	wire				wb_gpioa_stb_i;
	wire				wb_gpioa_ack_o;
	
	jelly_gpio
			#(
				.PORT_WIDTH			(4),
				.INIT_DIRECTION		(4'b0000),
				.INIT_OUTPUT		(4'b0000)
			)
		i_gpio_a
			(
				.reset				(reset),
				.clk				(clk),
				
				.port				(gpio_a),
				
				.wb_adr_i			(wb_gpioa_adr_i[3:2]),
				.wb_dat_o			(wb_gpioa_dat_o),
				.wb_dat_i			(wb_gpioa_dat_i),
				.wb_we_i			(wb_gpioa_we_i),
				.wb_sel_i			(wb_gpioa_sel_i),
				.wb_stb_i			(wb_gpioa_stb_i),
				.wb_ack_o			(wb_gpioa_ack_o)
			);                     
	

	// -----------------------------
	//  GPIO B
	// -----------------------------

	wire	[31:2]		wb_gpiob_adr_i;
	wire	[31:0]		wb_gpiob_dat_i;
	wire	[31:0]		wb_gpiob_dat_o;
	wire	[3:0]		wb_gpiob_sel_i;
	wire				wb_gpiob_we_i;
	wire				wb_gpiob_stb_i;
	wire				wb_gpiob_ack_o;
	
	jelly_gpio
			#(
				.PORT_WIDTH			(4),
				.INIT_DIRECTION		(4'b0000),
				.INIT_OUTPUT		(4'b0000)
			)
		i_gpio_b
			(
				.reset				(reset),
				.clk				(clk),

				.port				(gpio_b),


				.wb_adr_i			(wb_gpiob_adr_i[3:2]),
				.wb_dat_o			(wb_gpiob_dat_o),
				.wb_dat_i			(wb_gpiob_dat_i),
				.wb_we_i			(wb_gpiob_we_i),
				.wb_sel_i			(wb_gpiob_sel_i),
				.wb_stb_i			(wb_gpiob_stb_i),
				.wb_ack_o			(wb_gpiob_ack_o)	
			);
		
	
	// -----------------------------
	//  peri bus address decoder
	// -----------------------------

	assign wb_irc_adr_i    = wb_peri_adr_o;
	assign wb_irc_dat_i    = wb_peri_dat_o;
	assign wb_irc_sel_i    = wb_peri_sel_o;
	assign wb_irc_we_i     = wb_peri_we_o;
	assign wb_irc_stb_i    = wb_peri_stb_o & (wb_peri_adr_o[31:24] == 8'hf0);

	assign wb_timer0_adr_i = wb_peri_adr_o;
	assign wb_timer0_dat_i = wb_peri_dat_o;
	assign wb_timer0_sel_i = wb_peri_sel_o;
	assign wb_timer0_we_i  = wb_peri_we_o;
	assign wb_timer0_stb_i = wb_peri_stb_o & (wb_peri_adr_o[31:24] == 8'hf1);

	assign wb_uart0_adr_i  = wb_peri_adr_o;
	assign wb_uart0_dat_i  = wb_peri_dat_o;
	assign wb_uart0_sel_i  = wb_peri_sel_o;
	assign wb_uart0_we_i   = wb_peri_we_o;
	assign wb_uart0_stb_i  = wb_peri_stb_o & (wb_peri_adr_o[31:24] == 8'hf2);

	assign wb_gpioa_adr_i  = wb_peri_adr_o;
	assign wb_gpioa_dat_i  = wb_peri_dat_o;
	assign wb_gpioa_sel_i  = wb_peri_sel_o;
	assign wb_gpioa_we_i   = wb_peri_we_o;
	assign wb_gpioa_stb_i  = wb_peri_stb_o & (wb_peri_adr_o[31:8] == 28'hf300_000);

	assign wb_gpiob_adr_i  = wb_peri_adr_o;
	assign wb_gpiob_dat_i  = wb_peri_dat_o;
	assign wb_gpiob_sel_i  = wb_peri_sel_o;
	assign wb_gpiob_we_i   = wb_peri_we_o;
	assign wb_gpiob_stb_i  = wb_peri_stb_o & (wb_peri_adr_o[31:8] == 28'hf300_001);
	
	assign wb_peri_dat_i   = wb_irc_stb_i    ? wb_irc_dat_o    :
						     wb_timer0_stb_i ? wb_timer0_dat_o :
						     wb_uart0_stb_i  ? wb_uart0_dat_o  :
						     wb_gpioa_stb_i  ? wb_gpioa_dat_o  :
						     wb_gpiob_stb_i  ? wb_gpiob_dat_o  :
							 32'hxxxx_xxxx;       

	assign wb_peri_ack_i   = wb_irc_stb_i    ? wb_irc_ack_o    :
						     wb_timer0_stb_i ? wb_timer0_ack_o :
						     wb_uart0_stb_i  ? wb_uart0_ack_o  :
						     wb_gpioa_stb_i  ? wb_gpioa_ack_o  :
						     wb_gpiob_stb_i  ? wb_gpiob_ack_o  :
							 1'b1;
	
	
	
	// -----------------------------
	//  LED
	// -----------------------------
	
	reg		[23:0]		led_counter;
	always @ ( posedge clk ) begin
		if ( reset ) begin
			led_counter <= 0;
		end
		else begin
			led_counter <= led_counter + 1;
		end
	end
	assign led[7:0] = led_counter[23:16];
	
endmodule

