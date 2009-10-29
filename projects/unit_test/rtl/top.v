// ----------------------------------------------------------------------------
//  Jelly -- The computing system for FPGA
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


// top module
module top
		(
			clk_in, reset_in,
			
			uart0_tx, uart0_rx,
			uart1_tx, uart1_rx
		);
	
	// system
	input				clk_in;
	input				reset_in;
	
	// uart
	output				uart0_tx;
	input				uart0_rx;
	
	output				uart1_tx;
    input				uart1_rx;
	
	
	
	// -------------------------
	//  system
	// -------------------------
	
	// endian
	wire				endian;
	assign endian = 1'b1;			// 0:little, 1:big
	
	
	// clock
	wire				clk;
	wire				clk_uart;
	assign clk      = clk_in;
	assign clk_uart = clk;
	
	// reset
	wire				reset;
	assign reset = reset_in;
	


	// UART assign
	wire				uart_tx;
	wire				uart_rx;
	wire				dbg_uart_tx;
	wire				dbg_uart_rx;
	
	assign uart0_tx    = uart_tx;
	assign uart_rx     = uart0_rx;

	assign uart1_tx    = dbg_uart_tx;
	assign dbg_uart_rx = uart1_rx;
	
	
	
	// -------------------------
	//  cpu
	// -------------------------
	
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
				.GPR_TYPE			(2)
			)
		i_cpu_top
			(
				.reset				(reset),
				.clk				(clk),
				.clk_x2				(1'b0),
				
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
	
	
	// -------------------------
	//  memory
	// -------------------------
	
	reg					ram_wb_stb_i;
	wire	[31:0]		ram_wb_dat_o;
	wire				ram_wb_ack_o;
	ram_model
			#(
				.WB_ADR_WIDTH		(20),
				.WB_DAT_WIDTH		(32)
			)
		i_ram_model
			(
				.reset				(reset),
				.clk				(clk),

				.wb_adr_i			(wb_cpu_adr_o[21:2]),
				.wb_dat_o			(ram_wb_dat_o),
				.wb_dat_i			(wb_cpu_dat_o),
				.wb_we_i			(wb_cpu_we_o),
				.wb_sel_i			(wb_cpu_sel_o),
				.wb_stb_i			(wb_cpu_stb_o),
				.wb_ack_o			(ram_wb_ack_o)
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
		ram_wb_stb_i  = 1'b0;
		peri_wb_stb_i = 1'b0;
		
		casex ( {wb_cpu_adr_o[31:2], 2'b00} )
		32'h0xxx_xxxx:	// ram
			begin
				ram_wb_stb_i = wb_cpu_stb_o;
				wb_cpu_dat_i = ram_wb_dat_o;
				wb_cpu_ack_i = ram_wb_ack_o;
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
				.TX_FIFO_PTR_WIDTH	(9),
				.RX_FIFO_PTR_WIDTH	(9)
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
	
	
endmodule

