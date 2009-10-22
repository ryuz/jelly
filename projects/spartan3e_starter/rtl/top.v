// ---------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                 Copyright (C) 2008-2009 by Ryuji Fuchikami 
//                                 http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// top module
module top
		#(
			parameter					SIMULATION = 1'b0
		)
		(
			// system
			input	wire				clk_in,
			input	wire				reset_in,
			
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
	wire				clk;
	wire				clk_x2;
	wire				clk_uart;
	wire				clk_sdram;
	wire				clk90_sdram;
	wire				locked;
	
	// reset
	wire				reset;

	clkgen
		i_clkgen
			(
				.in_reset			(reset_in), 
				.in_clk				(clk_in), 
			
				.out_sys_clk		(clk),
				.out_sys_clk_x2		(clk_x2),
				.out_sys_reset		(reset),
				
				.out_uart_clk		(clk_uart),
				
				.out_sdram_clk		(clk_sdram),
				.out_sdram_clk90	(clk90_sdram),
				
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
	
	
	// cpu-bus (Whishbone)
	wire	[31:2]	wb_cpu_adr_o;
	reg		[31:0]	wb_cpu_dat_i;
	wire	[31:0]	wb_cpu_dat_o;
	wire			wb_cpu_we_o;
	wire	[3:0]	wb_cpu_sel_o;
	wire			wb_cpu_stb_o;
	reg				wb_cpu_ack_i;
	
	// cpu debug port
	wire	[3:0]	wb_dbg_adr_o;
	wire	[31:0]	wb_dbg_dat_i;
	wire	[31:0]	wb_dbg_dat_o;
	wire			wb_dbg_we_o;
	wire	[3:0]	wb_dbg_sel_o;
	wire			wb_dbg_stb_o;
	wire			wb_dbg_ack_i;
	
	// peripheral-bus
	wire	[31:2]	wb_peri_adr_o;
	reg		[31:0]	wb_peri_dat_i;
	wire	[31:0]	wb_peri_dat_o;
	wire			wb_peri_we_o;
	wire	[3:0]	wb_peri_sel_o;
	wire			wb_peri_stb_o;
	reg				wb_peri_ack_i;
	
	
	// CPU
	jelly_cpu_top_simple
			#(
				.USE_DBUGGER		(1'b1),
				.USE_EXC_SYSCALL	(1'b1),
				.USE_EXC_BREAK		(1'b1),
				.USE_EXC_RI			(1'b1),
				.GPR_TYPE			(1)
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
				
				.wb_adr_o			(wb_cpu_adr_o),
				.wb_dat_i			(wb_cpu_dat_i),
				.wb_dat_o			(wb_cpu_dat_o),
				.wb_we_o			(wb_cpu_we_o),
				.wb_sel_o			(wb_cpu_sel_o),
				.wb_stb_o			(wb_cpu_stb_o),
				.wb_ack_i			(wb_cpu_ack_i),
				
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
	
	reg					rom_wb_stb_i;
	wire	[31:0]		rom_wb_dat_o;
	wire				rom_wb_ack_o;
	boot_rom
		i_boot_rom
			(
				.clk				(~clk),
				.addr				(wb_cpu_adr_o[13:2]),
				.data				(rom_wb_dat_o)
			);
	assign rom_wb_ack_o = 1'b1;
	

	
	// -----------------------------
	//  internal sram
	// -----------------------------

	reg					sram_wb_stb_i;
	wire	[31:0]		sram_wb_dat_o;
	wire				sram_wb_ack_o;
	
	jelly_sram
			#(
				.WB_ADR_WIDTH		(12),
				.WB_DAT_WIDTH		(32)
			)
		i_sram
			(
				.reset				(reset),
				.clk				(clk),
				
				.wb_adr_i			(wb_cpu_adr_o[13:2]),
				.wb_dat_o			(sram_wb_dat_o),
				.wb_dat_i			(wb_cpu_dat_o),
				.wb_we_i			(wb_cpu_we_o),
				.wb_sel_i			(wb_cpu_sel_o),
				.wb_stb_i			(sram_wb_stb_i),
				.wb_ack_o			(sram_wb_ack_o)
		);
	
	
	
	// -----------------------------
	//  DDR-SDRAM (MT46V32M16TG-6T)
	// -----------------------------

	reg				dram_wb_stb_i;
	wire	[31:0]	dram_wb_dat_o;
	wire			dram_wb_ack_o;

	wire	[25:2]	wb_dram_adr_o;
	wire	[31:0]	wb_dram_dat_i;
	wire	[31:0]	wb_dram_dat_o;
	wire			wb_dram_we_o;
	wire	[3:0]	wb_dram_sel_o;
	wire			wb_dram_stb_o;
	wire			wb_dram_ack_i;
	
	jelly_wishbone_clk2x
			#(
				.WB_ADR_WIDTH		(24),
				.WB_DAT_WIDTH		(32)
			)
		i_wishbone_clk2x
			(
				.reset				(reset),
				.clk				(clk),
				.clk2x				(clk_sdram),
				
				.wb_adr_i			(wb_cpu_adr_o[25:2]),
				.wb_dat_o			(dram_wb_dat_o),
				.wb_dat_i			(wb_cpu_dat_o),
				.wb_we_i			(wb_cpu_we_o),
				.wb_sel_i			(wb_cpu_sel_o),
				.wb_stb_i			(dram_wb_stb_i),
				.wb_ack_o			(dram_wb_ack_o),

				.wb_2x_adr_o		(wb_dram_adr_o),
				.wb_2x_dat_o		(wb_dram_dat_o),
				.wb_2x_dat_i		(wb_dram_dat_i),
				.wb_2x_we_o			(wb_dram_we_o),
				.wb_2x_sel_o		(wb_dram_sel_o),
				.wb_2x_stb_o		(wb_dram_stb_o),
				.wb_2x_ack_i		(wb_dram_ack_i)
			);

	jelly_ddr_sdram
			#(
				.SIMULATION			(SIMULATION)
			)
		i_ddr_sdram
			(
				.reset				(reset),
				.clk				(clk_sdram),
				.clk90				(clk90_sdram),
				.endian				(endian),
				
				.wb_adr_i			(wb_dram_adr_o),
				.wb_dat_o			(wb_dram_dat_i),
				.wb_dat_i			(wb_dram_dat_o),
				.wb_we_i			(wb_dram_we_o),
				.wb_sel_i			(wb_dram_sel_o),
				.wb_stb_i			(wb_dram_stb_o),
				.wb_ack_o			(wb_dram_ack_i),
				
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
	
	
	
	// -------------------------
	//  peripheral bus
	// -------------------------

	reg				peri_wb_stb_i;
	wire	[31:0]	peri_wb_dat_o;
	wire			peri_wb_ack_o;
	
	jelly_wishbone_bridge
			#(
				.WB_ADR_WIDTH		(30),
				.WB_DAT_WIDTH		(32)
			)
		i_wishbone_bridge
			(
				.reset				(reset),
				.clk				(clk),
				
				.wb_in_adr_i		(wb_cpu_adr_o),
				.wb_in_dat_o		(peri_wb_dat_o),
				.wb_in_dat_i		(wb_cpu_dat_o),
				.wb_in_we_i			(wb_cpu_we_o),
				.wb_in_sel_i		(wb_cpu_sel_o),
				.wb_in_stb_i		(peri_wb_stb_i),
				.wb_in_ack_o		(peri_wb_ack_o),
				
				.wb_out_adr_o		(wb_peri_adr_o),
				.wb_out_dat_i		(wb_peri_dat_i),
				.wb_out_dat_o		(wb_peri_dat_o),
				.wb_out_we_o		(wb_peri_we_o),
				.wb_out_sel_o		(wb_peri_sel_o),
				.wb_out_stb_o		(wb_peri_stb_o),
				.wb_out_ack_i		(wb_peri_ack_i)
			);
	
	
	
	// -------------------------
	//  cpu bus address decoder
	// -------------------------
	
	always @* begin
		rom_wb_stb_i  = 1'b0;
		sram_wb_stb_i = 1'b0;
		dram_wb_stb_i = 1'b0;
		peri_wb_stb_i = 1'b0;
		
		casex ( {wb_cpu_adr_o[31:2], 2'b00} )
		32'h00xx_xxxx:
			begin
				if ( sw[1] ) begin 
					// boot rom
					rom_wb_stb_i = wb_cpu_stb_o;
					wb_cpu_dat_i = rom_wb_dat_o;
					wb_cpu_ack_i = rom_wb_ack_o;
				end
				else begin
					// dram
					dram_wb_stb_i = wb_cpu_stb_o;
					wb_cpu_dat_i = dram_wb_dat_o;
					wb_cpu_ack_i = dram_wb_ack_o;
				end
			end
		
		32'h01xx_xxxx:	// dram
			begin
				dram_wb_stb_i = wb_cpu_stb_o;
				wb_cpu_dat_i = dram_wb_dat_o;
				wb_cpu_ack_i = dram_wb_ack_o;
			end

		32'h02xx_xxxx:	// sram
			begin
				sram_wb_stb_i = wb_cpu_stb_o;
				wb_cpu_dat_i = sram_wb_dat_o;
				wb_cpu_ack_i = sram_wb_ack_o;
			end

		32'hfxxx_xxxx:	// peri
			begin
				peri_wb_stb_i = wb_cpu_stb_o;
				wb_cpu_dat_i  = peri_wb_dat_o;
				wb_cpu_ack_i  = peri_wb_ack_o;
			end
			
		default:
			begin
				wb_cpu_dat_i = {32{1'b0}};
				wb_cpu_ack_i = 1'b1;
			end
		endcase
	end
	
	
	
	
	// -------------------------
	//  IRC
	// -------------------------
	
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
	reg					irc_wb_stb_i;
	wire	[31:0]		irc_wb_dat_o;
	wire				irc_wb_ack_o;
	
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
											
				.wb_adr_i			(wb_peri_adr_o[15:2]),
				.wb_dat_o			(irc_wb_dat_o),
				.wb_dat_i			(wb_peri_dat_o),
				.wb_we_i			(wb_peri_we_o),
				.wb_sel_i			(wb_peri_sel_o),
				.wb_stb_i			(irc_wb_stb_i),
				.wb_ack_o			(irc_wb_ack_o)
			);
	
	
	// -------------------------
	//  Timer0
	// -------------------------
	
	reg					timer0_wb_stb_i;
	wire	[31:0]		timer0_wb_dat_o;
	wire				timer0_wb_ack_o;

	jelly_timer
		i_timer0
			(
				.clk				(clk),
				.reset				(reset),
				
				.interrupt_req		(timer0_irq),

				.wb_adr_i			(wb_peri_adr_o[3:2]),
				.wb_dat_o			(timer0_wb_dat_o),
				.wb_dat_i			(wb_peri_dat_o),
				.wb_we_i			(wb_peri_we_o),
				.wb_sel_i			(wb_peri_sel_o),
				.wb_stb_i			(timer0_wb_stb_i),
				.wb_ack_o			(timer0_wb_ack_o)
			);
	
	
	// -------------------------
	//  UART
	// -------------------------
	
	reg					uart0_wb_stb_i;
	wire	[31:0]		uart0_wb_dat_o;
	wire				uart0_wb_ack_o;

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
				
				.wb_adr_i			(wb_peri_adr_o[3:2]),
				.wb_dat_o			(uart0_wb_dat_o),
				.wb_dat_i			(wb_peri_dat_o),
				.wb_we_i			(wb_peri_we_o),
				.wb_sel_i			(wb_peri_sel_o),
				.wb_stb_i			(uart0_wb_stb_i),
				.wb_ack_o			(uart0_wb_ack_o)
			);
	
	

	// -------------------------
	//  GPIO A
	// -------------------------

	reg					gpioa_wb_stb_i;
	wire	[31:0]		gpioa_wb_dat_o;
	wire				gpioa_wb_ack_o;
	
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

				.wb_adr_i			(wb_peri_adr_o[3:2]),
				.wb_dat_o			(gpioa_wb_dat_o),
				.wb_dat_i			(wb_peri_dat_o),
				.wb_we_i			(wb_peri_we_o),
				.wb_sel_i			(wb_peri_sel_o),
				.wb_stb_i			(gpioa_wb_stb_i),
				.wb_ack_o			(gpioa_wb_ack_o)	
			);
	

	// -------------------------
	//  GPIO B
	// -------------------------

	reg					gpiob_wb_stb_i;
	wire	[31:0]		gpiob_wb_dat_o;
	wire				gpiob_wb_ack_o;
	
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

				.wb_adr_i			(wb_peri_adr_o[3:2]),
				.wb_dat_o			(gpiob_wb_dat_o),
				.wb_dat_i			(wb_peri_dat_o),
				.wb_we_i			(wb_peri_we_o),
				.wb_sel_i			(wb_peri_sel_o),
				.wb_stb_i			(gpiob_wb_stb_i),
				.wb_ack_o			(gpiob_wb_ack_o)	
			);
	
	
	
	// -------------------------
	//  peri bus address decoder
	// -------------------------
	
	always @* begin
		irc_wb_stb_i    = 1'b0;
		timer0_wb_stb_i = 1'b0;
		uart0_wb_stb_i  = 1'b0;
		
		casex ( {wb_peri_adr_o[31:2], 2'b00} )
		32'hf0xx_xxxx:	// irc
			begin
				irc_wb_stb_i = wb_peri_stb_o;
				wb_peri_dat_i = irc_wb_dat_o;
				wb_peri_ack_i = irc_wb_ack_o;
			end
			
		32'hf1xx_xxxx:	// timer0
			begin
				timer0_wb_stb_i = wb_peri_stb_o;
				wb_peri_dat_i = timer0_wb_dat_o;
				wb_peri_ack_i = timer0_wb_ack_o;
			end
		
		32'hf2xx_xxxx:	// uart0
			begin
				uart0_wb_stb_i = wb_peri_stb_o;
				wb_peri_dat_i = uart0_wb_dat_o;
				wb_peri_ack_i = uart0_wb_ack_o;
			end

		32'hf300_000x:	// gpio-a
			begin
				gpioa_wb_stb_i = wb_peri_stb_o;
				wb_peri_dat_i = gpioa_wb_dat_o;
				wb_peri_ack_i = gpioa_wb_ack_o;
			end

		32'hf300_001x:	// gpio-b
			begin
				gpiob_wb_stb_i = wb_peri_stb_o;
				wb_peri_dat_i = gpiob_wb_dat_o;
				wb_peri_ack_i = gpiob_wb_ack_o;
			end
			
		default:
			begin
				wb_peri_dat_i = {32{1'b0}};
				wb_peri_ack_i = 1'b1;
			end
		endcase
	end
	
	
	
	// -------------------------
	//  LED
	// -------------------------
	
	reg		[23:0]		led_counter;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			led_counter <= 0;
		end
		else begin
			led_counter <= led_counter + 1;
		end
	end
	assign led[7:0] = led_counter[23:16];
	
endmodule

