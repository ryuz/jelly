`timescale 1ns / 1ps


module tb_uart_dbg;
	parameter	RATE      = 20;
	parameter	UART_RATE = 205;
	
	
	initial begin
		$dumpfile("tb_uart_dbg.vcd");
		$dumpvars(0, tb_uart_dbg);
	end
	
	wire			endian;
	assign endian = 1'b1;
	
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

	// uart clock
	reg		uart_clk;
	initial begin
		uart_clk    = 1'b1;
	end
	always #(UART_RATE/2) begin
		uart_clk = ~uart_clk;
	end


	// debug port (whishbone)
	wire	[6:0]		wb_dbg_adr_o;
	wire	[31:0]		wb_dbg_dat_i;
	wire	[31:0]		wb_dbg_dat_o;
	wire				wb_dbg_we_o;
	wire	[3:0]		wb_dbg_sel_o;
	wire				wb_dbg_stb_o;
	wire				wb_dbg_ack_i;
	
	// debuger
	jelly_dbg_uart
		i_dbg_uart
			(
				.reset			(reset),
				.clk			(clk),
				.endian			(endian),
				
				.uart_clk		(uart_clk),
				.uart_tx		(uart_tx),
				.uart_rx		(uart_rx),
				
				.wb_dbg_adr_o	(wb_dbg_adr_o),
				.wb_dbg_dat_i	(wb_dbg_dat_i),
				.wb_dbg_dat_o	(wb_dbg_dat_o),
				.wb_dbg_we_o	(wb_dbg_we_o),
				.wb_dbg_sel_o	(wb_dbg_sel_o),
				.wb_dbg_stb_o	(wb_dbg_stb_o),
				.wb_dbg_ack_i	(wb_dbg_ack_i)
		);
	
	cpu_dbu
		i_cpu_dbu
			(
				.reset			(reset),
				.clk			(clk),
				.endian			(endian),
				
				.wb_adr_i		(wb_dbg_adr_o),
				.wb_dat_i		(wb_dbg_dat_o),
				.wb_dat_o		(wb_dbg_dat_i),
				.wb_we_i		(wb_dbg_we_o),
				.wb_sel_i		(wb_dbg_sel_o),
				.wb_stb_i		(wb_dbg_stb_o),
				.wb_ack_o		(wb_dbg_ack_i),
				
				.dbg_enable		(),
				.in_break		(1'b0),
				
				.wb_data_adr_o	(),
				.wb_data_dat_i	(32'h0a0b0c0d),
				.wb_data_dat_o	(),
				.wb_data_we_o	(),
				.wb_data_sel_o	(),
				.wb_data_stb_o	(),
				.wb_data_ack_i	(1'b1),
				
				.wb_inst_adr_o	(),
				.wb_inst_dat_i	(32'h1a1b1c1d),
				.wb_inst_sel_o	(),
				.wb_inst_stb_o	(),
				.wb_inst_ack_i	(1'b1),
				
				.pc_we			(),
				.pc_wdata		(),
				.pc_rdata		(5),
				
				.gpr_en			(),
				.gpr_we			(),
				.gpr_addr		(),
				.gpr_wdata		(),
				.gpr_rdata		(6),
				
				.hilo_en		(),
				.hilo_we		(),
				.hilo_addr		(),
				.hilo_wdata		(),
				.hilo_rdata		(7),
				
				.cop0_en		(),
				.cop0_we		(),
				.cop0_addr		(),
				.cop0_wdata		(),
				.cop0_rdata		(8)
			);
	
	
	// UART monitor
	always @ ( posedge i_dbg_uart.i_uart_core.clk ) begin
		if ( i_dbg_uart.i_uart_core.tx_en ) begin
			$display("%t UART-TX:%h", $time, i_dbg_uart.i_uart_core.tx_data);
		end
		if ( i_dbg_uart.i_uart_core.rx_en & i_dbg_uart.i_uart_core.rx_ready ) begin
			$display("%t UART-RX:%h", $time, i_dbg_uart.i_uart_core.rx_data);
		end
	end
	
	// monitor debug port
	always @ ( posedge clk ) begin
		if ( wb_dbg_stb_o & wb_dbg_ack_i ) begin
			if ( wb_dbg_we_o ) begin
				$display("%t wb_dbg(write) : sel:%b adr:%h dat:%h", $time, wb_dbg_sel_o, wb_dbg_adr_o, wb_dbg_dat_o);
			end                                                     
			else begin                                               
				$display("%t wb_dbg(read)  : sel:%b adr:%h dat:%h", $time, wb_dbg_sel_o, wb_dbg_adr_o, wb_dbg_dat_i);
			end
		end
	end
	
	
	// read
	task write_uart_rx_fifo;
		input	[7:0]	data;
		begin
			@(negedge i_dbg_uart.i_uart_core.uart_clk);
				force i_dbg_uart.i_uart_core.rx_fifo_wr_en   = 1'b1;
				force i_dbg_uart.i_uart_core.rx_fifo_wr_data = data;
			@(posedge i_dbg_uart.i_uart_core.uart_clk);
				release i_dbg_uart.i_uart_core.rx_fifo_wr_en;
				release i_dbg_uart.i_uart_core.rx_fifo_wr_data;
		end
	endtask
	
	
	
	initial begin
	#(RATE*20);
		$display("--- NOP ---");
		write_uart_rx_fifo(8'h00);		// nop
		
	#(RATE*20);
		$display("\n\n--- STATUS ---");
		write_uart_rx_fifo(8'h01);

	#(RATE*20);
		$display("\n\n--- DBG WRITE (ADR <- R1 )---");
		write_uart_rx_fifo(8'h02);		// dbg write
		write_uart_rx_fifo(8'hf2);		// sel + adr
		write_uart_rx_fifo(8'h00);		// dat0
		write_uart_rx_fifo(8'h00);		// dat1
		write_uart_rx_fifo(8'h00);		// dat2
		write_uart_rx_fifo(8'h21);		// dat3	(r1)

	#(RATE*20);
		$display("\n\n--- DBG READ (read r1) ---");
		write_uart_rx_fifo(8'h03);		// dbg read
		write_uart_rx_fifo(8'hf4);		// sel + adr

	#(RATE*20);
		$display("\n\n--- DBG WRITE (write r1)---");
		write_uart_rx_fifo(8'h02);		// dbg write
		write_uart_rx_fifo(8'hf4);		// sel + adr
		write_uart_rx_fifo(8'hab);		// dat0
		write_uart_rx_fifo(8'hcd);		// dat1
		write_uart_rx_fifo(8'hef);		// dat2
		write_uart_rx_fifo(8'h89);		// dat3
	
	#(RATE*20);
		$display("\n\n--- DBG WRITE (ADR <- PC )---");
		write_uart_rx_fifo(8'h02);		// dbg write
		write_uart_rx_fifo(8'hf4);		// sel + adr
		write_uart_rx_fifo(8'h00);		// dat0
		write_uart_rx_fifo(8'h00);		// dat1
		write_uart_rx_fifo(8'h00);		// dat2
		write_uart_rx_fifo(8'h00);		// dat3	(pc)

	#(RATE*20);
		$display("\n\n--- DBG READ (read pc) ---");
		write_uart_rx_fifo(8'h03);		// dbg read
		write_uart_rx_fifo(8'hf4);		// sel + adr

	#(RATE*20);
		$display("\n\n--- DBG WRITE (write pc)---");
		write_uart_rx_fifo(8'h02);		// dbg write
		write_uart_rx_fifo(8'hf4);		// sel + adr
		write_uart_rx_fifo(8'h11);		// dat0
		write_uart_rx_fifo(8'h12);		// dat1
		write_uart_rx_fifo(8'h13);		// dat2
		write_uart_rx_fifo(8'h14);		// dat3
	
	#(RATE*20);
		$display("\n\n--- MEM WRITE ---");
		write_uart_rx_fifo(8'h04);		// mem write
		write_uart_rx_fifo(8'h04);		// size - 1
		write_uart_rx_fifo(8'h87);		// addr0
		write_uart_rx_fifo(8'h65);		// addr1
		write_uart_rx_fifo(8'h43);		// addr2
		write_uart_rx_fifo(8'h21);		// addr3
		write_uart_rx_fifo(8'haa);		// data0
		write_uart_rx_fifo(8'h55);		// data1
		write_uart_rx_fifo(8'h12);		// data2
		write_uart_rx_fifo(8'h34);		// data3
		write_uart_rx_fifo(8'h56);		// data4

	#(RATE*20);
		$display("\n\n--- NOP ---");
		write_uart_rx_fifo(8'h00);		// nop

	#(RATE*20);
		$display("\n\n--- MEM READ ---");
		write_uart_rx_fifo(8'h05);		// mem read
		write_uart_rx_fifo(8'h08);		// size - 1
		write_uart_rx_fifo(8'h99);		// addr0
		write_uart_rx_fifo(8'h88);		// addr1
		write_uart_rx_fifo(8'h43);		// addr2
		write_uart_rx_fifo(8'h23);		// addr3
	#(RATE*100);
	
	#(RATE*20);
		$display("\n\n--- NOP ---");
		write_uart_rx_fifo(8'h00);		// nop
		
	#(RATE*50);
		$finish;
	end
	
endmodule

