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
			asram_ce0_n, asram_ce1_n, asram_we_n, asram_oe_n, asram_bls_n, asram_a, asram_d,
			ext, led
		);
	
	input				clk_in;
	input				reset_in;
	
	output				uart_tx;
	input				uart_rx;
	
	output				asram_ce0_n;
	output				asram_ce1_n;
	output				asram_we_n;
	output				asram_oe_n;
	output	[3:0]		asram_bls_n;
	output	[17:0]		asram_a;
	inout	[31:0]		asram_d;

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
	reg				wb_ack_i;
	
	// CPU
	cpu_top
		i_cpu_top
			(
				.reset			(reset),
				.clk			(clk),
				.clk_x2			(clk_x2),

				.endian			(1'b1),
				
				.vect_reset		(32'h0000_0000),
				.vect_interrupt	(32'h0000_0180),
				.vect_exception	(32'h0000_0180),

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
	reg					rom_wb_stb_i;
	wire	[31:0]		rom_wb_dat_o;
	wire				rom_wb_ack_o;
	boot_rom
		i_boot_rom
			(
				.clk			(~clk),
				.addr			(wb_adr_o),
				.data			(rom_wb_dat_o)
			);
	assign rom_wb_ack_o = 1'b1;
	
		
	// asram
	reg					asram_wb_stb_i;
	wire	[31:0]		asram_wb_dat_o;
	wire				asram_wb_ack_o;
	
	wire				asram_cs_n;
	jelly_asram
			#(
				.WB_ADR_WIDTH	(18),
				.WB_DAT_WIDTH	(32)
			)
		i_asram
			(
				.reset			(reset),
				.clk			(clk),
				
				.asram_cs_n		(asram_cs_n),
				.asram_we_n		(asram_we_n),
				.asram_oe_n		(asram_oe_n),
				.asram_bls_n	(asram_bls_n),
				.asram_a		(asram_a),
				.asram_d		(asram_d),
				
				.wb_adr_i		(wb_adr_o),
				.wb_dat_o		(asram_wb_dat_o),
				.wb_dat_i		(wb_dat_o),
				.wb_we_i		(wb_we_o),
				.wb_sel_i		(wb_sel_o),
				.wb_stb_i		(asram_wb_stb_i),
				.wb_ack_o		(asram_wb_ack_o)
			);
	assign asram_ce0_n  = asram_cs_n;
	assign asram_ce1_n  = asram_cs_n;

	/*
	assign asram_wb_dat_o = asram_d;
	assign asram_wb_ack_o = 1'b1;
	
	assign asram_ce0_n  = ~(asram_wb_stb_i);
	assign asram_ce1_n  = asram_ce0_n;
	assign asram_we_n   = ~(wb_we_o  & ~asram_ce0_n);
	assign asram_oe_n   = ~(~wb_we_o & ~asram_ce0_n);
	assign asram_bls_n  = ~wb_sel_o;
	assign asram_a      = wb_adr_o;
	assign asram_d      = (~asram_ce0_n & ~asram_we_n) ? wb_dat_o : 32'hzzzzzzzz;	
	*/
	
	
	// IRC
	reg					irc_wb_stb_i;
	wire	[31:0]		irc_wb_dat_o;
	wire				irc_wb_ack_o;

	jelly_irc
		i_irc
			(
				.clk			(clk),
				.reset			(reset),
							
				.wb_adr_i		(wb_adr_o[8:2]),
				.wb_dat_o		(irc_wb_dat_o),
				.wb_dat_i		(wb_dat_o),
				.wb_we_i		(wb_we_o),
				.wb_sel_i		(wb_sel_o),
				.wb_stb_i		(irc_wb_stb_i),
				.wb_ack_o		(irc_wb_ack_o)
			);
	
	
	// Timer
	wire				timer0_irq;

	reg					timer0_wb_stb_i;
	wire	[31:0]		timer0_wb_dat_o;
	wire				timer0_wb_ack_o;

	jelly_timer
		i_timer0
			(
				.clk			(clk),
				.reset			(reset),
				
				.interrupt_req	(timer0_irq),

				.wb_adr_i		(wb_adr_o[4:2]),
				.wb_dat_o		(timer0_wb_dat_o),
				.wb_dat_i		(wb_dat_o),
				.wb_we_i		(wb_we_o),
				.wb_sel_i		(wb_sel_o),
				.wb_stb_i		(timer0_wb_stb_i),
				.wb_ack_o		(timer0_wb_ack_o)
			);
	
	reg		[7:0]	reg_irq;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			reg_irq <= 0;
		end
		else begin
			reg_irq <= {reg_irq, timer0_irq};
		end
	end
	
	assign cpu_irq = (reg_irq != 0);
	
	
	
	// UART
	reg					uart0_wb_stb_i;
	wire	[31:0]		uart0_wb_dat_o;
	wire				uart0_wb_ack_o;

	jelly_uart
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
				.wb_sel_i		(wb_sel_o),
				.wb_stb_i		(uart0_wb_stb_i),
				.wb_ack_o		(uart0_wb_ack_o)
			);
	
	
	
	// address decoder
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

