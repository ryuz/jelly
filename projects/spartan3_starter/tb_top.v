`timescale 1ns / 1ps


module tb_top;
	parameter	RATE      = 20;
	parameter	UART_RATE = (1000000000 / 115200);
	
	
	initial begin
		$dumpfile("tb_top.vcd");
		$dumpvars(0, tb_top);
	end
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
	end
	
	// clock
	reg		clk;
	initial begin
		clk    = 1'b1;
	end
	always #(RATE/2) begin
		clk = ~clk;
	end
	
	
	reg					uart_rx;
	
	wire				sram_ce0_n;
	wire				sram_ce1_n;
	wire				sram_we_n;
	wire				sram_oe_n;
	wire	[3:0]		sram_bls_n;
	wire	[17:0]		sram_a;
	wire	[31:0]		sram_d;
	
	top i_top
		(
			.clk_in			(clk),
			.reset_in		(reset),
			
			.uart0_tx		(),
			.uart0_rx		(uart_rx),
			
			.uart1_tx		(),
			.uart1_rx		(1'b1),
			
			.asram_ce0_n	(sram_ce0_n),
			.asram_ce1_n	(sram_ce1_n),
			.asram_we_n		(sram_we_n),
			.asram_oe_n		(sram_oe_n),
			.asram_bls_n	(sram_bls_n),
			.asram_a		(sram_a),
			.asram_d		(sram_d),
			
			.led			(),
			.sw				(8'b0000_0000),
			.ext			()
		);
	
	// SRAM
	sram i_sram0 (.ce_n(sram_ce0_n), .we_n(sram_we_n | sram_bls_n[0]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[7:0]));
	sram i_sram1 (.ce_n(sram_ce0_n), .we_n(sram_we_n | sram_bls_n[1]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[15:8]));
	sram i_sram2 (.ce_n(sram_ce1_n), .we_n(sram_we_n | sram_bls_n[2]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[23:16]));
	sram i_sram3 (.ce_n(sram_ce1_n), .we_n(sram_we_n | sram_bls_n[3]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[31:24]));
	
	
	
	// PC trace
	integer pc_trace;
	initial begin
		pc_trace = $fopen("pc_trace.txt");
	end
	always @ ( posedge i_top.i_cpu_top.i_cpu_core.clk ) begin
		if ( !i_top.i_cpu_top.i_cpu_core.interlock & !i_top.i_cpu_top.i_cpu_core.ex_out_stall ) begin
			$fdisplay(pc_trace, "%t : %h %h",
						$time, i_top.i_cpu_top.i_cpu_core.ex_out_pc, i_top.i_cpu_top.i_cpu_core.ex_out_instruction);
		end
	end

	// Interrupt monitor
	always @ ( posedge i_top.i_cpu_top.clk ) begin
	//	if ( i_top.i_cpu_top.interrupt_req ) begin
	//		$display("%t  interrupt_req",  $time);
	//	end
		if ( i_top.i_cpu_top.interrupt_ack ) begin
			$display("%t  interrupt_ack",  $time);
		end
	end

	
	// UART monitor
	always @ ( posedge i_top.i_uart0.clk ) begin
		if ( i_top.i_uart0.tx_en ) begin
			$display("%t UART-TX:%h %c", $time, i_top.i_uart0.tx_data, i_top.i_uart0.tx_data);
		end
		if ( i_top.i_uart0.rx_en & i_top.i_uart0.rx_ready ) begin
			$display("%t UART-RX:%h %c", $time, i_top.i_uart0.rx_data, i_top.i_uart0.rx_data);
		end
	end


	// dbg_uart monitor
	always @ ( posedge i_top.i_dbg_uart.i_uart_core.clk ) begin
		if ( i_top.i_dbg_uart.i_uart_core.tx_en ) begin
			$display("%t dbg_uart [TX]:%h", $time, i_top.i_dbg_uart.i_uart_core.tx_data);
		end
		if ( i_top.i_dbg_uart.i_uart_core.rx_en & i_top.i_dbg_uart.i_uart_core.rx_ready ) begin
			$display("%t dbg_uart [RX]:%h", $time, i_top.i_dbg_uart.i_uart_core.rx_data);
		end
	end
	
	
	// write_dbg_uart_rx_fifo
	task write_dbg_uart_rx_fifo;
		input	[7:0]	data;
		begin
			@(negedge i_top.i_dbg_uart.i_uart_core.uart_clk);
				force i_top.i_dbg_uart.i_uart_core.rx_fifo_wr_en   = 1'b1;
				force i_top.i_dbg_uart.i_uart_core.rx_fifo_wr_data = data;
			@(posedge i_top.i_dbg_uart.i_uart_core.uart_clk);
				release i_top.i_dbg_uart.i_uart_core.rx_fifo_wr_en;
				release i_top.i_dbg_uart.i_uart_core.rx_fifo_wr_data;
		end
	endtask


	// write_dbg_uart_rx_fifo
	task write_uart_rx_fifo;
		input	[7:0]	data;
		begin
			@(negedge i_top.i_uart0.i_uart_core.uart_clk);
				force i_top.i_uart0.i_uart_core.rx_fifo_wr_en   = 1'b1;
				force i_top.i_uart0.i_uart_core.rx_fifo_wr_data = data;
			@(posedge i_top.i_uart0.i_uart_core.uart_clk);
				release i_top.i_uart0.i_uart_core.rx_fifo_wr_en;
				release i_top.i_uart0.i_uart_core.rx_fifo_wr_data;
		end
	endtask
	
	
	
	initial begin
		while ( 1 ) begin
		#(RATE*20000);
			write_uart_rx_fifo("X");
		#(RATE*20000);
			write_uart_rx_fifo("Y");
		end
		
/*
	#(RATE*20);
		$display("--- NOP ---");
		write_dbg_uart_rx_fifo(8'h00);		// nop
		
	#(RATE*20);
		$display("\n\n--- STATUS ---");
		write_dbg_uart_rx_fifo(8'h01);		// status

	#(RATE*20);
		$display("\n\n--- GO DEBUG MODE ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf0);		// dbgctl
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h01);		// dat3

	#(RATE*20);
		$display("\n\n--- MEM READ ---");
		write_dbg_uart_rx_fifo(8'h05);		// mem read
		write_dbg_uart_rx_fifo(8'h10);		// size
		write_dbg_uart_rx_fifo(8'h00);		// adr0
		write_dbg_uart_rx_fifo(8'h00);		// adr1
		write_dbg_uart_rx_fifo(8'h00);		// adr2
		write_dbg_uart_rx_fifo(8'h00);		// adr3
*/
	end
	
endmodule

