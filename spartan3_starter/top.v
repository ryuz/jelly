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
			uart_tx, uart_rx,
			sram_ce0_n, sram_ce1_n, sram_we_n, sram_oe_n, sram_bls_n, sram_a, sram_d,
			ext, led
		);
	
	input				clk_in;
	input				reset_in;
	
	output				uart_tx;
	input				uart_rx;
	
	output				sram_ce0_n;
	output				sram_ce1_n;
	output				sram_we_n;
	output				sram_oe_n;
	output	[3:0]		sram_bls_n;
	output	[17:0]		sram_a;
	inout	[31:0]		sram_d;

	output	[30:0]		ext;
	output	[7:0]		led;


	// clock
	wire				clk;
	wire				clk_x2;
	wire				clk_uart;
	wire				locked;
	clkgen
		i_clkgen
			(
				.in_reset		(reset_in), 
				.in_clk			(clk_in), 
			
				.out_clk		(clk),
				.out_clk_x2		(clk_x2),
				.out_clk_uart	(clk_uart),
				.locked			(locked)
		);
	
	// system
	wire				reset;
	assign reset = reset_in | ~locked;
	
	// interrupt
	wire			cpu_irq;

	// cpu-bus (Whishbone)
	wire	[31:2]	wb_adr_o;
	reg		[31:0]	wb_dat_i;
	wire	[31:0]	wb_dat_o;
	wire			wb_we_o;
	wire	[3:0]	wb_sel_o;
	wire			wb_stb_o;
	wire			wb_ack_i;
	
	// CPU
	cpu_top
		i_cpu_top
			(
				.reset			(reset),
				.clk			(clk),
				.clk_x2			(clk_x2),

				.endian			(1'b1),
				
				.vect_reset		(32'h0000_0000),
				.vect_interrupt	(32'h0000_0018),
				.vect_exception	(32'h0000_001c),

				.interrupt_req	(cpu_irq),
				.interrupt_ack	(),
				
				.wb_adr_o		(wb_adr_o),
				.wb_dat_i		(wb_dat_i),
				.wb_dat_o		(wb_dat_o),
				.wb_we_o		(wb_we_o),
				.wb_sel_o		(wb_sel_o),
				.wb_stb_o		(wb_stb_o),
				.wb_ack_i		(wb_ack_i),
				
				.pause			(1'b0)
			);
	
	
	// boot rom
	wire	[31:0]		rom_wb_dat_o;
	boot_rom
		i_boot_rom
			(
				.clk			(~clk),
				.addr			(wb_adr_o),
				.data			(rom_wb_dat_o)
			);
	
	
	// sram
	wire	[31:0]		sram_wb_dat_o;
	assign sram_wb_dat_o = sram_d;
	
	assign sram_ce0_n  = ~(wb_stb_o & (wb_adr_o[31:24] == 8'h01));
	assign sram_ce1_n  = sram_ce0_n;
	assign sram_we_n   = ~(wb_we_o  & ~sram_ce0_n);
	assign sram_oe_n   = ~(~wb_we_o & ~sram_ce0_n);
	assign sram_bls_n  = ~wb_sel_o;
	assign sram_a      = wb_adr_o;
	assign sram_d      = (~sram_ce0_n & ~sram_we_n) ? wb_dat_o : 32'hzzzzzzzz;	
	
	
	
	// IRC
	wire	[31:0]		irc_wb_dat_o;
	irc
		i_irc
			(
				.clk			(clk),
				.reset			(reset),
				
				
				.wb_adr_i		(wb_adr_o[8:2]),
				.wb_dat_o		(irc_wb_dat_o),
				.wb_dat_i		(wb_dat_o),
				.wb_we_i		(wb_we_o),
				.wb_sel_i		(wb_sel_i),
				.wb_stb_i		(wb_stb_o & wb_adr_o[31:24] == 8'hf0),
				.wb_ack_o		()
			);
	
	
	// UART
	wire	[31:0]		timer0_wb_dat_o;
	timer
		i_timer0
			(
				.clk			(clk),
				.reset			(reset),
				
				.interrupt_req	(cpu_irq),

				.wb_adr_i		(wb_adr_o[4:2]),
				.wb_dat_o		(timer0_wb_dat_o),
				.wb_dat_i		(wb_dat_o),
				.wb_we_i		(wb_we_o),
				.wb_sel_i		(wb_sel_i),
				.wb_stb_i		(wb_stb_o & wb_adr_o[31:24] == 8'hf1),
				.wb_ack_o		()
			);
	
	
	// UART
	wire	[31:0]		uart0_wb_dat_o;
	uart
		i_uart0
			(
				.clk			(clk),
				.reset			(reset),
				
				.uart_clk		(clk_uart),
				.uart_tx		(uart_tx),
				.uart_rx		(uart_rx),
				
				.wb_adr_i		(wb_adr_o[4:2]),
				.wb_dat_o		(uart0_wb_dat_o),
				.wb_dat_i		(wb_dat_o),
				.wb_we_i		(wb_we_o),
				.wb_sel_i		(wb_sel_i),
				.wb_stb_i		(wb_stb_o & wb_adr_o[31:24] == 8'hf2),
				.wb_ack_o		()
			);
	
	
	// wb_dat_i
	always @* begin
		case ( wb_adr_o[31:24] )
		8'h00:		wb_dat_i <= rom_wb_dat_o;
		8'h01:		wb_dat_i <= sram_wb_dat_o;
		8'hf0:		wb_dat_i <= irc_wb_dat_o;
		8'hf1:		wb_dat_i <= timer0_wb_dat_o;
		8'hf2:		wb_dat_i <= uart0_wb_dat_o;
		default:	wb_dat_i <= 0;
		endcase
	end
	assign wb_ack_i = 1'b1;
	
	
	
	
	// LED
	reg		[31:0]		led_counter;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			led_counter <= 0;
		end
		else begin
			led_counter <= led_counter + 1;
		end
	end
	assign led[7:0] = led_counter[31:24];
	
	
	// debug port
	assign ext  = 0;
	
endmodule

