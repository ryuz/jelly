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
		
	reg					uart_rx;

	parameter	DDR_WIRE_DELAY = 1.0;

	wire			#DDR_WIRE_DELAY		ddr_sdram_ck_p;
	wire			#DDR_WIRE_DELAY		ddr_sdram_ck_n;
	wire			#DDR_WIRE_DELAY		ddr_sdram_cke;
	wire			#DDR_WIRE_DELAY		ddr_sdram_cs;
	wire			#DDR_WIRE_DELAY		ddr_sdram_ras;
	wire			#DDR_WIRE_DELAY		ddr_sdram_cas;
	wire			#DDR_WIRE_DELAY		ddr_sdram_we;
	wire	[1:0]	#DDR_WIRE_DELAY		ddr_sdram_ba;
	wire	[12:0]	#DDR_WIRE_DELAY		ddr_sdram_a;
	wire	[15:0]	#DDR_WIRE_DELAY		ddr_sdram_dq;
	wire			#DDR_WIRE_DELAY		ddr_sdram_udm;
	wire			#DDR_WIRE_DELAY		ddr_sdram_ldm;
	wire			#DDR_WIRE_DELAY		ddr_sdram_udqs;
	wire			#DDR_WIRE_DELAY		ddr_sdram_ldqs;
	wire			#DDR_WIRE_DELAY		ddr_sdram_ck_fb;
	
	top
			#(
				.SIMULATION	(SIMULATION)
			)
		i_top
			(
				.in_clk				(clk),
				.in_reset			(reset),
				
				.uart0_tx			(),
				.uart0_rx			(uart_rx),
				.uart1_tx			(),
				.uart1_rx			(1'b1),

				.gpio_a				(),
				.gpio_b				(),
				
				.ddr_sdram_ck_p		(ddr_sdram_ck_p),
				.ddr_sdram_ck_n		(ddr_sdram_ck_n),
				.ddr_sdram_cke		(ddr_sdram_cke),
				.ddr_sdram_cs		(ddr_sdram_cs),
				.ddr_sdram_ras		(ddr_sdram_ras),
				.ddr_sdram_cas		(ddr_sdram_cas),
				.ddr_sdram_we		(ddr_sdram_we),
				.ddr_sdram_ba		(ddr_sdram_ba),
				.ddr_sdram_a		(ddr_sdram_a),
				.ddr_sdram_udm		(ddr_sdram_udm),
				.ddr_sdram_ldm		(ddr_sdram_ldm),
				.ddr_sdram_udqs		(ddr_sdram_udqs),
				.ddr_sdram_ldqs		(ddr_sdram_ldqs),
				.ddr_sdram_dq		(ddr_sdram_dq),
				.ddr_sdram_ck_fb	(ddr_sdram_ck_fb),
				
				.led				(),
				.sw					(4'b0010)
			);
	
	// DDR
	ddr
			#(
				.DEBUG			(0)
			)
		i_ddr
			(
				.Clk			(ddr_sdram_ck_p),
				.Clk_n			(ddr_sdram_ck_n),
				.Cke			(ddr_sdram_cke),
				.Cs_n			(ddr_sdram_cs),
				.Ras_n			(ddr_sdram_ras),
				.Cas_n			(ddr_sdram_cas),
				.We_n			(ddr_sdram_we),
				.Ba				(ddr_sdram_ba),
				.Addr			(ddr_sdram_a),
				.Dm				({ddr_sdram_udm, ddr_sdram_ldm}),
				.Dq				(ddr_sdram_dq),
				.Dqs			({ddr_sdram_udqs, ddr_sdram_ldqs})
			);

	

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
	/*
	integer uart_monitor;
	initial begin
		uart_monitor = $fopen("uart_monitor.txt");
	end
	always @ ( posedge i_top.i_uart0.clk ) begin
		if ( i_top.i_uart0.tx_en ) begin
			$display("%t UART-TX:%h %c", $time, i_top.i_uart0.tx_data, i_top.i_uart0.tx_data);
			$fdisplay(uart_monitor, "%t UART-TX:%h %c", $time, i_top.i_uart0.tx_data, i_top.i_uart0.tx_data);
		end
	end
	*/
	
	
	// write_dbg_uart_rx_fifo
	task write_dbg_uart_rx_fifo;
		input	[7:0]	data;
		begin
			@(negedge i_top.i_uart_debugger.i_uart_core.uart_clk);
				force i_top.i_uart_debugger.i_uart_core.rx_fifo_wr_en   = 1'b1;
				force i_top.i_uart_debugger.i_uart_core.rx_fifo_wr_data = data;
			@(posedge i_top.i_uart_debugger.i_uart_core.uart_clk);
				release i_top.i_uart_debugger.i_uart_core.rx_fifo_wr_en;
				release i_top.i_uart_debugger.i_uart_core.rx_fifo_wr_data;
		end
	endtask

	
	initial begin
	#(RATE*200);
	
				$display("--- START ---");

	#(RATE*1000);

			#(RATE*1234);
	//	end

	end


	
	task dbg_restart;
	begin
		$display("--- NOP ---");
		write_dbg_uart_rx_fifo(8'h00);		// nop
	#(RATE*200);

		$display("\n\n--- STATUS ---");
		write_dbg_uart_rx_fifo(8'h01);		// status
	#(RATE*200);

		$display("\n\n--- DEBUG BREAK ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf0);		// dbgctl
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h01);		// dat3
	#(RATE*200);

		$display("\n\n--- DEBUG BREAK READ  ---");
		write_dbg_uart_rx_fifo(8'h03);		// read
		write_dbg_uart_rx_fifo(8'hf0);		// dbgctl
	#(RATE*200);

		$display("\n\n--- MEM WRITE  ---");
		write_dbg_uart_rx_fifo(8'h04);		// read
		write_dbg_uart_rx_fifo(8'h03);		// size
		write_dbg_uart_rx_fifo(8'h00);		// adr0
		write_dbg_uart_rx_fifo(8'h00);		// adr1
		write_dbg_uart_rx_fifo(8'h00);		// adr2
		write_dbg_uart_rx_fifo(8'h00);		// adr3
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h00);		// dat3
	#(RATE*200);

		$display("\n\n--- R8 READ  ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf2);		// dbgaddr
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'ha0);		// dat3
	#(RATE*200);
		write_dbg_uart_rx_fifo(8'h03);		// read
		write_dbg_uart_rx_fifo(8'hf4);		// reg_data
	#(RATE*200);

		$display("\n\n--- R9 READ  ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf2);		// dbgaddr
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'ha4);		// dat3
	#(RATE*200);
		write_dbg_uart_rx_fifo(8'h03);		// read
		write_dbg_uart_rx_fifo(8'hf4);		// reg_data
	#(RATE*200);

		$display("\n\n--- HI  ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf2);		// dbgaddr
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h40);		// dat3
	#(RATE*200);
		write_dbg_uart_rx_fifo(8'h03);		// read
		write_dbg_uart_rx_fifo(8'hf4);		// reg_data
	#(RATE*200);


		$display("\n\n--- MEM READ ---");
		write_dbg_uart_rx_fifo(8'h05);		// mem read
		write_dbg_uart_rx_fifo(8'h10);		// size
		write_dbg_uart_rx_fifo(8'h01);		// adr0
		write_dbg_uart_rx_fifo(8'h00);		// adr1
		write_dbg_uart_rx_fifo(8'h00);		// adr2
		write_dbg_uart_rx_fifo(8'h00);		// adr3
	#(RATE*1000);



		$display("\n\n--- COP_DEPC SET ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf2);		// dbgaddr
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h01);		// dat2
		write_dbg_uart_rx_fifo(8'h60);		// dat3
	#(RATE*200);
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf4);		// reg_data
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h00);		// dat3
	#(RATE*200);

		$display("\n\n--- COP_STATUS SET ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf2);		// dbgaddr
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h01);		// dat2
		write_dbg_uart_rx_fifo(8'h30);		// dat3
	#(RATE*200);
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf4);		// reg_data
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h00);		// dat3
	#(RATE*200);


		$display("\n\n--- RESTART ---");
		write_dbg_uart_rx_fifo(8'h02);		// write
		write_dbg_uart_rx_fifo(8'hf0);		// dbgctl
		write_dbg_uart_rx_fifo(8'h00);		// dat0
		write_dbg_uart_rx_fifo(8'h00);		// dat1
		write_dbg_uart_rx_fifo(8'h00);		// dat2
		write_dbg_uart_rx_fifo(8'h00);		// dat3
	#(RATE*100);
	end
	endtask	
	

endmodule

