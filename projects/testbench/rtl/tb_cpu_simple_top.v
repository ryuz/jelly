// ----------------------------------------------------------------------------
//  Jelly -- The computing system for Spartan-3 Starter Kit
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------


`timescale       1ns / 1ps
`default_nettype none


// top module
module tb_cpu_simple_top
		#(
			parameter	ROM_HEX_FILE    = "hosv4a_sample_ram.hex",
			
			parameter	RATE            = 20,	// 50MHz			
			parameter	USE_DBUGGER     = 1'b0,
			parameter	USE_EXC_SYSCALL = 1'b0,
			parameter	USE_EXC_BREAK   = 1'b0,
			parameter	USE_EXC_RI      = 1'b0,
			parameter	GPR_TYPE        = 0,
			parameter	MUL_CYCLE       = 0,
			parameter	DBBP_NUM        = 0,
			parameter	SIMULATION      = 0
		);
	
	// -------------------------
	//  system
	// -------------------------
	
	initial begin
		$dumpfile("tb_cpu_simple_top.vcd");
		$dumpvars(0, tb_cpu_simple_top);
	end
	
	// clock
	reg		clk    = 1'b1;
	reg		clk_x2 = 1'b1;
	always #(RATE/2) begin
		clk    = ~clk;
	end
	always #(RATE/4) begin
		clk_x2 = ~clk_x2;
	end
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
	end
	
	
	
	// -------------------------
	//  system
	// -------------------------
	
	// endian
	wire				endian;
	assign endian = 1'b1;			// 0:little, 1:big

	// uart
	wire				clk_uart;
	assign clk_uart = clk;
	
	wire				uart0_tx;
	reg					uart0_rx = 1'b1;
	
	wire				uart1_tx;
	reg					uart1_rx = 1'b1;
	
	
	
	
	// -------------------------
	//  cpu
	// -------------------------
	
	// interrupt
	wire			cpu_irq;
	wire			cpu_irq_ack;
		
	//  cpu-bus (WISHBONE)
	wire	[31:2]	wb_cpu_adr_o;
	wire	[31:0]	wb_cpu_dat_i;
	wire	[31:0]	wb_cpu_dat_o;
	wire			wb_cpu_we_o;
	wire	[3:0]	wb_cpu_sel_o;
	wire			wb_cpu_stb_o;
	wire			wb_cpu_ack_i;
	
	// cpu debug port (WISHBONE)
	wire	[3:0]	wb_dbg_adr_o;
	wire	[31:0]	wb_dbg_dat_i;
	wire	[31:0]	wb_dbg_dat_o;
	wire			wb_dbg_we_o;
	wire	[3:0]	wb_dbg_sel_o;
	wire			wb_dbg_stb_o;
	wire			wb_dbg_ack_i;
	
	// CPU
	jelly_cpu_simple_top
			#(
				.CPU_USE_DBUGGER   	(USE_DBUGGER),
				.CPU_USE_EXC_SYSCALL(USE_EXC_SYSCALL),
				.CPU_USE_EXC_BREAK	(USE_EXC_BREAK),
				.CPU_USE_EXC_RI		(USE_EXC_RI),
				.CPU_GPR_TYPE		(GPR_TYPE),
				.CPU_MUL_CYCLE		(MUL_CYCLE),
				.CPU_DBBP_NUM		(DBBP_NUM),
				.SIMULATION 		(SIMULATION)
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

				.pause				(1'b0),
				
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
				.wb_dbg_ack_o		(wb_dbg_ack_i)				
			);
	
	generate
	if ( USE_DBUGGER ) begin
		jelly_uart_debugger
				#(
					.TX_FIFO_PTR_WIDTH	(2),
					.RX_FIFO_PTR_WIDTH	(2)
				)
			i_uart_debugger
				(
					.reset				(reset),
					.clk				(clk),
					.endian				(endian),
					
					.uart_clk			(clk_uart),
					.uart_tx			(uart1_tx),
					.uart_rx			(uart1_rx),
					
					.wb_dbg_adr_o		(wb_dbg_adr_o),
					.wb_dbg_dat_i		(wb_dbg_dat_i),
					.wb_dbg_dat_o		(wb_dbg_dat_o),
					.wb_dbg_we_o		(wb_dbg_we_o),
					.wb_dbg_sel_o		(wb_dbg_sel_o),
					.wb_dbg_stb_o		(wb_dbg_stb_o),
					.wb_dbg_ack_i		(wb_dbg_ack_i)
				);
	end
	else begin
		assign uart1_tx  = 1'b1;
		
		assign wb_dbg_adr_o = 4'h0;
		assign wb_dbg_dat_o = 32'h0000_0000;
		assign wb_dbg_we_o  = 1'b0;
		assign wb_dbg_sel_o = 4'b0000;
		assign wb_dbg_stb_o = 1'b0;
	end
	endgenerate
		
	
	
	
	// -------------------------
	//  ROM (boot)
	// -------------------------

	wire	[31:2]		wb_rom_adr_i;
	wire	[31:0]		wb_rom_dat_i;
	wire	[31:0]		wb_rom_dat_o;
	wire	[3:0]		wb_rom_sel_i;
	wire				wb_rom_we_i;
	wire				wb_rom_stb_i;
	wire				wb_rom_ack_o;
	
	jelly_sram
			#(
				.WB_ADR_WIDTH	(16),
				.WB_DAT_WIDTH	(32),
				.READMEMH		(1),
				.READMEM_FILE	(ROM_HEX_FILE)
			)
		i_sram_rom
			(
				.reset			(reset),
				.clk			(clk),
				
				.wb_adr_i		(wb_rom_adr_i[17:2]),
				.wb_dat_o		(wb_rom_dat_o),
				.wb_dat_i		(wb_rom_dat_i),
				.wb_we_i		(wb_rom_we_i),
				.wb_sel_i		(wb_rom_sel_i),
				.wb_stb_i		(wb_rom_stb_i),
				.wb_ack_o		(wb_rom_ack_o)
			);

	
	// -------------------------
	//  RAM
	// -------------------------

	wire	[31:2]		wb_ram_adr_i;
	wire	[31:0]		wb_ram_dat_i;
	wire	[31:0]		wb_ram_dat_o;
	wire	[3:0]		wb_ram_sel_i;
	wire				wb_ram_we_i;
	wire				wb_ram_stb_i;
	wire				wb_ram_ack_o;
	
	jelly_sram
			#(
				.WB_ADR_WIDTH	(16),
				.WB_DAT_WIDTH	(32),
				.READMEMH		(0),
				.READMEM_FILE	("")
			)
		i_sram_ram
			(
				.reset			(reset),
				.clk			(clk),
				
				.wb_adr_i		(wb_ram_adr_i[17:2]),
				.wb_dat_o		(wb_ram_dat_o),
				.wb_dat_i		(wb_ram_dat_i),
				.wb_we_i		(wb_ram_we_i),
				.wb_sel_i		(wb_ram_sel_i),
				.wb_stb_i		(wb_ram_stb_i),
				.wb_ack_o		(wb_ram_ack_o)
			);
	
	
	// -----------------------------
	//  IRC
	// -----------------------------
	
	// irq
	wire				timer0_irq;
	wire				timer1_irq;
	wire				uart0_irq_rx;
	wire				uart0_irq_tx;
	
	// irq map
	wire	[3:0]		irc_interrupt;
	assign irc_interrupt[0] = timer0_irq;
	assign irc_interrupt[1] = uart0_irq_rx;
	assign irc_interrupt[2] = uart0_irq_tx;
	assign irc_interrupt[3] = timer1_irq;
	

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
				.FACTOR_NUM			(4),
				.PRIORITY_WIDTH		(2),
	
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
											
				.wb_adr_i			(wb_irc_adr_i[9:2]),
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
	//  Timer1
	// -----------------------------
	
	wire	[31:2]		wb_timer1_adr_i;
	wire	[31:0]		wb_timer1_dat_i;
	wire	[31:0]		wb_timer1_dat_o;
	wire	[3:0]		wb_timer1_sel_i;
	wire				wb_timer1_we_i;
	wire				wb_timer1_stb_i;
	wire				wb_timer1_ack_o;
	
	jelly_timer
		i_timer1
			(
				.clk				(clk),
				.reset				(reset),
				
				.interrupt_req		(timer1_irq),

				.wb_adr_i			(wb_timer1_adr_i[3:2]),
				.wb_dat_o			(wb_timer1_dat_o),
				.wb_dat_i			(wb_timer1_dat_i),
				.wb_we_i			(wb_timer1_we_i),
				.wb_sel_i			(wb_timer1_sel_i),
				.wb_stb_i			(wb_timer1_stb_i),
				.wb_ack_o			(wb_timer1_ack_o)
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
				.uart_tx			(uart0_tx),
				.uart_rx			(uart0_rx),
				
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
	//  address decoder
	// -----------------------------

	assign wb_rom_adr_i    = wb_cpu_adr_o;
	assign wb_rom_dat_i    = wb_cpu_dat_o;
	assign wb_rom_sel_i    = wb_cpu_sel_o;
	assign wb_rom_we_i     = wb_cpu_we_o;
	assign wb_rom_stb_i    = wb_cpu_stb_o & (wb_cpu_adr_o[31:24] == 8'h00);
	
	assign wb_ram_adr_i    = wb_cpu_adr_o;
	assign wb_ram_dat_i    = wb_cpu_dat_o;
	assign wb_ram_sel_i    = wb_cpu_sel_o;
	assign wb_ram_we_i     = wb_cpu_we_o;
	assign wb_ram_stb_i    = wb_cpu_stb_o & (wb_cpu_adr_o[31:24] == 8'h01);
	
	assign wb_irc_adr_i    = wb_cpu_adr_o;
	assign wb_irc_dat_i    = wb_cpu_dat_o;
	assign wb_irc_sel_i    = wb_cpu_sel_o;
	assign wb_irc_we_i     = wb_cpu_we_o;
	assign wb_irc_stb_i    = wb_cpu_stb_o & (wb_cpu_adr_o[31:16] == 16'hf000);
	
	assign wb_timer0_adr_i = wb_cpu_adr_o;
	assign wb_timer0_dat_i = wb_cpu_dat_o;
	assign wb_timer0_sel_i = wb_cpu_sel_o;
	assign wb_timer0_we_i  = wb_cpu_we_o;
	assign wb_timer0_stb_i = wb_cpu_stb_o & (wb_cpu_adr_o[31:16] == 16'hf100);
	
	assign wb_timer1_adr_i = wb_cpu_adr_o;
	assign wb_timer1_dat_i = wb_cpu_dat_o;
	assign wb_timer1_sel_i = wb_cpu_sel_o;
	assign wb_timer1_we_i  = wb_cpu_we_o;
	assign wb_timer1_stb_i = wb_cpu_stb_o & (wb_cpu_adr_o[31:16] == 16'hf101);
	
	assign wb_uart0_adr_i  = wb_cpu_adr_o;
	assign wb_uart0_dat_i  = wb_cpu_dat_o;
	assign wb_uart0_sel_i  = wb_cpu_sel_o;
	assign wb_uart0_we_i   = wb_cpu_we_o;
	assign wb_uart0_stb_i  = wb_cpu_stb_o & (wb_cpu_adr_o[31:24] == 8'hf2);
	
	assign wb_cpu_dat_i    = wb_rom_stb_i    ? wb_rom_dat_o    :
						     wb_ram_stb_i    ? wb_ram_dat_o    :
						     wb_irc_stb_i    ? wb_irc_dat_o    :
						     wb_timer0_stb_i ? wb_timer0_dat_o :
						     wb_timer1_stb_i ? wb_timer1_dat_o :
						     wb_uart0_stb_i  ? wb_uart0_dat_o  :
							 32'hxxxx_xxxx;       

	assign wb_cpu_ack_i    = wb_rom_stb_i    ? wb_rom_ack_o    :
						     wb_ram_stb_i    ? wb_ram_ack_o    :
						     wb_irc_stb_i    ? wb_irc_ack_o    :
						     wb_timer0_stb_i ? wb_timer0_ack_o :
						     wb_timer1_stb_i ? wb_timer1_ack_o :
						     wb_uart0_stb_i  ? wb_uart0_ack_o  :
							 1'b1;
	
		
endmodule


`default_nettype wire


// end of file

