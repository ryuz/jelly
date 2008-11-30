// ---------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami 
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// top module
module top
		(
			clk_in, reset_in,
			
			uart0_tx, uart0_rx,
			uart1_tx, uart1_rx,

			ddr_sdram_ck_p, ddr_sdram_ck_n, ddr_sdram_cke, ddr_sdram_cs, ddr_sdram_ras, ddr_sdram_cas, ddr_sdram_we,
			ddr_sdram_ba, ddr_sdram_a, ddr_sdram_udm, ddr_sdram_ldm, ddr_sdram_udqs, ddr_sdram_ldqs, ddr_sdram_dq, ddr_sdram_ck_fb,

			led, sw
		);
	parameter	SIMULATION      = 1'b0;
	
	// system
	input				clk_in;
	input				reset_in;
	
	// uart
	output				uart0_tx;
	input				uart0_rx;
	
	output				uart1_tx;
    input				uart1_rx;
	
	// DDR-SDRAM
	output				ddr_sdram_ck_p;
	output				ddr_sdram_ck_n;
	output				ddr_sdram_cke;
	output				ddr_sdram_cs;
	output				ddr_sdram_ras;
	output				ddr_sdram_cas;
	output				ddr_sdram_we;
	output	[1:0]		ddr_sdram_ba;
	output	[12:0]		ddr_sdram_a;
	inout	[15:0]		ddr_sdram_dq;
	output				ddr_sdram_udm;
	output				ddr_sdram_ldm;
	inout				ddr_sdram_udqs;
	inout				ddr_sdram_ldqs;
	input				ddr_sdram_ck_fb;
	
	// UI
	output	[7:0]		led;
	input	[3:0]		sw;

	

	
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
	clkgen
		i_clkgen
			(
				.in_reset			(reset_in), 
				.in_clk				(clk_in), 
			
				.out_clk			(clk),
				.out_clk_x2			(clk_x2),
				
				.out_clk_uart		(clk_uart),
				
				.out_clk_sdram		(clk_sdram),
				.out_clk90_sdram	(clk90_sdram),
				
				.locked				(locked)
		);
	
	// reset
	wire				reset;
	assign reset = reset_in | ~locked;
	


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
	cpu_top
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
	wire	dbg_uart_clk;
	jelly_dbg_uart
		i_dbg_uart
			(
				.reset				(reset),
				.clk				(clk),
				.endian				(endian),
				
				.uart_clk			(clk_uart),
				.uart_tx			(dbg_uart_tx),
				.uart_rx			(dbg_uart_rx),
				
				.wb_dbg_adr_o		(wb_dbg_adr_o),
				.wb_dbg_dat_i		(wb_dbg_dat_i),
				.wb_dbg_dat_o		(wb_dbg_dat_o),
				.wb_dbg_we_o		(wb_dbg_we_o),
				.wb_dbg_sel_o		(wb_dbg_sel_o),
				.wb_dbg_stb_o		(wb_dbg_stb_o),
				.wb_dbg_ack_i		(wb_dbg_ack_i)
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
				.WB_ADR_WIDTH	(12),
				.WB_DAT_WIDTH	(32)
			)
		i_sram
			(
				.reset			(reset),
				.clk			(clk),
				
				.wb_adr_i		(wb_cpu_adr_o[13:2]),
				.wb_dat_o		(sram_wb_dat_o),
				.wb_dat_i		(wb_cpu_dat_o),
				.wb_we_i		(wb_cpu_we_o),
				.wb_sel_i		(wb_cpu_sel_o),
				.wb_stb_i		(sram_wb_stb_i),
				.wb_ack_o		(sram_wb_ack_o)
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
	
	wishbone_clk2x
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

	ddr_sdram
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
	
	wishbone_bridge
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
				.PRIORITY_WIDTH		(1),
	
				.WB_ADR_WIDTH		(8),
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

