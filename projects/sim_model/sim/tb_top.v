`timescale 1ns / 1ps


module tb_top;
	parameter	RATE       = 10;
	parameter	RATE_UART = (1000000000 / (115200*16));
		
	
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
	
	reg		uart_clk;
	initial begin
		uart_clk    = 1'b1;
	end
	always #(RATE_UART/2) begin
		uart_clk = ~uart_clk;
	end

	
	reg					uart_rx;

	
	top
		i_top
			(
				.clk_in				(clk),
				.reset_in			(reset),
				
				.uart_clk			(uart_clk),
				
				.uart0_tx			(),
				.uart0_rx			(uart_rx),
				
				.uart1_tx			(),
				.uart1_rx			(1'b1)
			);
	
	
	
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
	
	
	// bus_trace
	integer bus_trace;
	initial begin
		bus_trace = $fopen("bus_trace.txt");
	end
	always @ ( posedge i_top.i_cpu_top.i_cpu_core.clk ) begin
		if ( i_top.i_cpu_top.i_cpu_core.wb_data_stb_o & i_top.i_cpu_top.i_cpu_core.wb_data_ack_i ) begin
			if ( i_top.i_cpu_top.i_cpu_core.wb_data_we_o ) begin
				$fdisplay(bus_trace, "w %t : %h %h",
						$time, i_top.i_cpu_top.i_cpu_core.wb_data_adr_o, i_top.i_cpu_top.i_cpu_core.wb_data_dat_o);
			end
			else begin
				$fdisplay(bus_trace, "r %t : %h %h",
						$time, i_top.i_cpu_top.i_cpu_core.wb_data_adr_o, i_top.i_cpu_top.i_cpu_core.wb_data_dat_i);
			end
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
	integer uart_monitor;
	initial begin
		uart_monitor = $fopen("uart_monitor.txt");
	end
	always @ ( posedge i_top.i_uart0.clk ) begin
		if ( i_top.i_uart0.tx_en ) begin
			$display("%t UART-TX:%h %c", $time, i_top.i_uart0.tx_data, i_top.i_uart0.tx_data);
			$fdisplay(uart_monitor, "%t UART-TX:%h %c", $time, i_top.i_uart0.tx_data, i_top.i_uart0.tx_data);
		end
		else if ( i_top.i_uart0.rx_en & i_top.i_uart0.rx_ready ) begin
			$display("%t UART-RX:%h %c", $time, i_top.i_uart0.rx_data, i_top.i_uart0.rx_data);
			$fdisplay(uart_monitor, "%t UART-RX:%h %c", $time, i_top.i_uart0.rx_data, i_top.i_uart0.rx_data);
		end
	end


	// dbg_uart monitor
	always @ ( posedge i_top.i_dbg_uart.i_uart_core.clk ) begin
		if ( i_top.i_dbg_uart.i_uart_core.tx_en & i_top.i_dbg_uart.i_uart_core.tx_ready ) begin
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
	
	
	initial begin
		$readmemh("soft.hex", i_top.i_ram_model.mem);
	end
	
	
endmodule

