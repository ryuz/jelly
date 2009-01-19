// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    UART
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// uart
module jelly_uart_core
		#(
			parameter	TX_FIFO_PTR_WIDTH = 4,
			parameter	RX_FIFO_PTR_WIDTH = 4,
			parameter	DEBUG             = 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							uart_clk,
			output	wire							uart_tx,
			input	wire							uart_rx,
			
			input	wire							tx_en,
			input	wire	[7:0]					tx_data,
			output	wire							tx_ready,
			
			output	wire							rx_en,
			output	wire	[7:0]					rx_data,
			input	wire							rx_ready,
			
			output	wire	[TX_FIFO_PTR_WIDTH:0]	tx_fifo_free_num,
			output	wire	[RX_FIFO_PTR_WIDTH:0]	rx_fifo_data_num
		);
	
	localparam	TX_FIFO_SIZE = (1 << TX_FIFO_PTR_WIDTH);
	localparam	RX_FIFO_SIZE = (1 << RX_FIFO_PTR_WIDTH);
	
	
	
	// -------------------------
	//  TX
	// -------------------------
	
	// TX
	wire							tx_fifo_rd_en;
	wire	[7:0]					tx_fifo_rd_data;
	wire							tx_fifo_rd_ready;
	
	// FIFO
	jelly_fifo_fwtf_async
			#(
				.DATA_WIDTH		(8),
				.PTR_WIDTH		(TX_FIFO_PTR_WIDTH)
			)
		i_fifo_tx
			(
				.reset			(reset),
				
				.in_clk			(clk),
				.in_en			(tx_en),
				.in_data		(tx_data),
				.in_ready		(tx_ready),
				.in_free_num	(tx_fifo_free_num),
				
				.out_clk		(uart_clk),
				.out_en			(tx_fifo_rd_en),
				.out_data		(tx_fifo_rd_data),
				.out_ready		(tx_fifo_rd_ready),
				.out_data_num	()
			);
	
	// transmitter
	jelly_uart_tx
		i_uart_tx
			(
				.reset			(reset),
				.clk			(uart_clk),
				
				.uart_tx		(uart_tx),
				
				.tx_en			(tx_fifo_rd_en),
				.tx_din			(tx_fifo_rd_data), 
				.tx_ready		(tx_fifo_rd_ready)
			);
	
	
	
	
	// -------------------------
	//  RX
	// -------------------------
	
	wire							rx_fifo_wr_en;
	wire	[7:0]					rx_fifo_wr_data;
	wire							rx_fifo_wr_ready;
	
	// FIFO
	jelly_fifo_fwtf_async
			#(
				.DATA_WIDTH		(8),
				.PTR_WIDTH		(RX_FIFO_PTR_WIDTH)
			)
		i_fifo_rx
			(
				.reset			(reset),
				
				.in_clk			(uart_clk),
				.in_en			(rx_fifo_wr_en),
				.in_data		(rx_fifo_wr_data),
				.in_ready		(rx_fifo_wr_ready),
				.in_free_num	(),
				
				.out_clk		(clk),
				.out_en			(rx_en),
				.out_data		(rx_data),
				.out_ready		(rx_ready),
				.out_data_num	(rx_fifo_data_num)
			);
	
	// receiver
	jelly_uart_rx
		i_uart_rx
			(
				.reset			(reset), 
				.clk			(uart_clk),
				
				.uart_rx		(uart_rx),
				
				.rx_en			(rx_fifo_wr_en),
				.rx_dout		(rx_fifo_wr_data)
			);
	
	
	// -------------------------
	//  Debug
	// -------------------------

	always @ ( posedge clk ) begin
		if ( DEBUG ) begin
			if ( rx_en & rx_ready ) begin
				$display("%m : [UART-RX] %h %c", rx_data, rx_data);
			end			
			if ( tx_en & tx_ready ) begin
				$display("%m : [UART-TX] %h %c", tx_data, tx_data);
			end			
		end
	end
	
endmodule

