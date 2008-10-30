// ----------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps



// top module
module top
		(
			clk_in, reset_in,
			asram_ce0_n, asram_ce1_n, asram_we_n, asram_oe_n, asram_bls_n, asram_a, asram_d,
			uart0_tx, uart0_rx,
			uart1_tx, uart1_rx,
			ext, led, sw
		);
	
	// system
	input				clk_in;
	input				reset_in;
	
	// asram
	output				asram_ce0_n;
	output				asram_ce1_n;
	output				asram_we_n;
	output				asram_oe_n;
	output	[3:0]		asram_bls_n;
	output	[17:0]		asram_a;
	inout	[31:0]		asram_d;

	// uart
	output				uart0_tx;
	input				uart0_rx;
	
	output				uart1_tx;
    input				uart1_rx;
	
	output	[30:0]		ext;
	output	[7:0]		led;
	input	[7:0]		sw;

	
	
	wire				uart_tx;
	wire				uart_rx;
	
	wire				dbg_uart_tx;
	wire				dbg_uart_rx;

	assign uart0_tx    = ~sw[0] ? uart_tx  : dbg_uart_tx;
	assign uart1_tx    =  sw[0] ? uart_tx  : dbg_uart_tx;
	assign uart_rx     = ~sw[0] ? uart0_rx : uart1_rx;
	assign dbg_uart_rx = ~sw[0] ? uart1_rx : uart0_rx;
	
	
	// -------------------------
	//  system
	// -------------------------
	
	// endian
	wire				endian;
	assign endian = 1'b1;			// 0:little, 1:big
	
	
	// clock
	wire				clk;
	wire				clk_x2;
	wire				clk_uart;
	wire				locked;
	clkgen
		i_clkgen
			(
				.in_reset			(reset_in), 
				.in_clk				(clk_in), 
			
				.out_clk			(clk),
				.out_clk_x2			(clk_x2),
				.out_clk_uart		(clk_uart),
				.locked				(locked)
		);
	
	// reset
	wire				reset;
	assign reset = reset_in | ~locked;
	
	
	
	// -------------------------
	//  cpu
	// -------------------------
	
	// interrupt
	wire			cpu_irq;
	wire			cpu_irq_ack;
	
	
	// cpu-bus (Whishbone)
	wire	[31:2]	wb_adr_o;
	reg		[31:0]	wb_dat_i;
	wire	[31:0]	wb_dat_o;
	wire			wb_we_o;
	wire	[3:0]	wb_sel_o;
	wire			wb_stb_o;
	reg				wb_ack_i;
	
	// cpu debug port
	wire	[3:0]	wb_dbg_adr_o;
	wire	[31:0]	wb_dbg_dat_i;
	wire	[31:0]	wb_dbg_dat_o;
	wire			wb_dbg_we_o;
	wire	[3:0]	wb_dbg_sel_o;
	wire			wb_dbg_stb_o;
	wire			wb_dbg_ack_i;
	
	// CPU
	cpu_top
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
				
				.wb_adr_o			(wb_adr_o),
				.wb_dat_i			(wb_dat_i),
				.wb_dat_o			(wb_dat_o),
				.wb_we_o			(wb_we_o),
				.wb_sel_o			(wb_sel_o),
				.wb_stb_o			(wb_stb_o),
				.wb_ack_i			(wb_ack_i),

				.wb_dbg_adr_i		(wb_dbg_adr_o),
				.wb_dbg_dat_i		(wb_dbg_dat_o),
				.wb_dbg_dat_o		(wb_dbg_dat_i),
				.wb_dbg_we_i		(wb_dbg_we_o),
				.wb_dbg_sel_i		(wb_dbg_sel_o),
				.wb_dbg_stb_i		(wb_dbg_stb_o),
				.wb_dbg_ack_o		(wb_dbg_ack_i),
				
				.pause				(1'b0)
			);
	
	/*
	assign wb_dbg_adr_o = 4'h0;
	assign wb_dbg_dat_o = 32'h0000_0000;
	assign wb_dbg_we_o  = 1'b0;
	assign wb_dbg_sel_o = 4'b0000;
	assign wb_dbg_stb_o = 1'b0;
	*/
	
	wire	dbg_uart_clk;
	jelly_dbg_uart
		i_dbg_uart
			(
				.reset				(reset),
				.clk				(clk),
				.endian				(endian),
				
				.uart_clk			(dbg_uart_clk),
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
											
				.wb_adr_i			(wb_adr_o[15:2]),
				.wb_dat_o			(irc_wb_dat_o),
				.wb_dat_i			(wb_dat_o),
				.wb_we_i			(wb_we_o),
				.wb_sel_i			(wb_sel_o),
				.wb_stb_i			(irc_wb_stb_i),
				.wb_ack_o			(irc_wb_ack_o)
			);
	
	
	
	// -------------------------
	//  boot rom
	// -------------------------
	
	reg					rom_wb_stb_i;
	wire	[31:0]		rom_wb_dat_o;
	wire				rom_wb_ack_o;
	boot_rom
		i_boot_rom
			(
				.clk				(~clk),
				.addr				(wb_adr_o[13:2]),
				.data				(rom_wb_dat_o)
			);
	assign rom_wb_ack_o = 1'b1;
	

		
	// -------------------------
	//  asram
	// -------------------------

	reg					asram_wb_stb_i;
	wire	[31:0]		asram_wb_dat_o;
	wire				asram_wb_ack_o;
	
	wire				asram_cs_n;
	jelly_asram
			#(
				.WB_ADR_WIDTH		(18),
				.WB_DAT_WIDTH		(32)
			)
		i_asram
			(
				.reset				(reset),
				.clk				(clk),
				
				.asram_cs_n			(asram_cs_n),
				.asram_we_n			(asram_we_n),
				.asram_oe_n			(asram_oe_n),
				.asram_bls_n		(asram_bls_n),
				.asram_a			(asram_a),
				.asram_d			(asram_d),
				
				.wb_adr_i			(wb_adr_o[19:2]),
				.wb_dat_o			(asram_wb_dat_o),
				.wb_dat_i			(wb_dat_o),
				.wb_we_i			(wb_we_o),
				.wb_sel_i			(wb_sel_o),
				.wb_stb_i			(asram_wb_stb_i),
				.wb_ack_o			(asram_wb_ack_o)
			);
	assign asram_ce0_n  = asram_cs_n;
	assign asram_ce1_n  = asram_cs_n;
	
	
	
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

				.wb_adr_i			(wb_adr_o[3:2]),
				.wb_dat_o			(timer0_wb_dat_o),
				.wb_dat_i			(wb_dat_o),
				.wb_we_i			(wb_we_o),
				.wb_sel_i			(wb_sel_o),
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
				.uart_clk_dv		(dbg_uart_clk),
				
				.irq_rx				(uart0_irq_rx),
				.irq_tx				(uart0_irq_tx),
				
				.wb_adr_i			(wb_adr_o[3:2]),
				.wb_dat_o			(uart0_wb_dat_o),
				.wb_dat_i			(wb_dat_o),
				.wb_we_i			(wb_we_o),
				.wb_sel_i			(wb_sel_o),
				.wb_stb_i			(uart0_wb_stb_i),
				.wb_ack_o			(uart0_wb_ack_o)
			);
	
	
	// -------------------------
	//  address decoder
	// -------------------------
	
	always @* begin
		rom_wb_stb_i    = 1'b0;
		asram_wb_stb_i  = 1'b0;
		irc_wb_stb_i    = 1'b0;
		timer0_wb_stb_i = 1'b0;
		uart0_wb_stb_i  = 1'b0;
		
		casex ( {wb_adr_o[31:2], 2'b00} )
		32'h00xx_xxxx:	// boot rom
			begin
				rom_wb_stb_i = wb_stb_o;
				wb_dat_i = rom_wb_dat_o;
				wb_ack_i = rom_wb_ack_o;
			end
		
		32'h01xx_xxxx:	// asram
			begin
				asram_wb_stb_i = wb_stb_o;
				wb_dat_i = asram_wb_dat_o;
				wb_ack_i = asram_wb_ack_o;
			end
		
		32'hf0xx_xxxx:	// irc
			begin
				irc_wb_stb_i = wb_stb_o;
				wb_dat_i = irc_wb_dat_o;
				wb_ack_i = irc_wb_ack_o;
			end
			
		32'hf1xx_xxxx:	// timer0
			begin
				timer0_wb_stb_i = wb_stb_o;
				wb_dat_i = timer0_wb_dat_o;
				wb_ack_i = timer0_wb_ack_o;
			end
			
		32'hf2xx_xxxx:	// uart0
			begin
				uart0_wb_stb_i = wb_stb_o;
				wb_dat_i = uart0_wb_dat_o;
				wb_ack_i = uart0_wb_ack_o;
			end
			
		default:
			begin
				wb_dat_i = {32{1'b0}};
				wb_ack_i = 1'b1;
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
	
	// debug port
	assign ext  = 0;
	
endmodule

