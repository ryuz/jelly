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
		(
			reset, clk,			
			uart_clk, uart_tx, uart_rx,
			tx_en, tx_data, tx_ready,
			rx_en, rx_data, rx_ready,
			tx_fifo_free_num, rx_fifo_data_num
		);
	
	parameter	TX_FIFO_PTR_WIDTH = 4;
	parameter	RX_FIFO_PTR_WIDTH = 4;
	localparam	TX_FIFO_SIZE = (1 << TX_FIFO_PTR_WIDTH);
	localparam	RX_FIFO_SIZE = (1 << RX_FIFO_PTR_WIDTH);
	
	
	input							reset;
	input							clk;
	
	input							uart_clk;
	output							uart_tx;
	input							uart_rx;
	
	input							tx_en;
	input	[7:0]					tx_data;
	output							tx_ready;
	
	output							rx_en;
	output	[7:0]					rx_data;
	input							rx_ready;
	
	output	[TX_FIFO_PTR_WIDTH:0]	tx_fifo_free_num;
	output	[RX_FIFO_PTR_WIDTH:0]	rx_fifo_data_num;
	
	
	
	// -------------------------
	//  TX
	// -------------------------
	
	// TX
	wire							tx_fifo_rd_en;
	wire	[7:0]					tx_fifo_rd_data;
	wire							tx_fifo_rd_ready;
	
	// FIFO
	pipeline_fifo_async
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
	uart_tx
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
	pipeline_fifo_async
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
	uart_rx
		i_uart_rx
			(
				.reset			(reset), 
				.clk			(uart_clk),
				
				.uart_rx		(uart_rx),
				
				.rx_en			(rx_fifo_wr_en),
				.rx_dout		(rx_fifo_wr_data)
			);
	
endmodule

