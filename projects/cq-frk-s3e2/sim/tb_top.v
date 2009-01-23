`timescale 1ns / 1ps


module tb_top;
	parameter	SIMULATION = 1'b1;

	parameter	RATE       = 20;
	parameter	UART_RATE  = (1000000000 / 115200);
	
	
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
	
	top
		i_top
			(
				.clk_in				(clk),
				.reset_in_n			(!reset),
				
				.uart0_tx			(),
				.uart0_rx			(1'b1),
				
				.uart1_tx			(),
				.uart1_rx			(1'b1),
				
				.led				()
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

	// Interrupt monitor
	always @ ( posedge i_top.i_cpu_top.clk ) begin
		if ( i_top.i_cpu_top.interrupt_ack ) begin
			$display("%t  interrupt_ack",  $time);
		end
	end
	
	
	initial begin
	#(RATE*200);
				$display("--- START ---");

	#(RATE*100000);
				$finish;
	end	
	
endmodule

