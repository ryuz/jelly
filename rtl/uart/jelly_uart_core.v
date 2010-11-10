// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    UART
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// uart
module jelly_uart_core
		#(
			parameter	TX_FIFO_PTR_WIDTH = 4,
			parameter	RX_FIFO_PTR_WIDTH = 4,
			parameter	SIMULATION        = 0,
			parameter	DEBUG             = 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							uart_clk,
			output	wire							uart_tx,
			input	wire							uart_rx,
			
			input	wire	[7:0]					tx_data,
			input	wire							tx_valid,
			output	wire							tx_ready,
			
			output	wire	[7:0]					rx_data,
			output	wire							rx_valid,
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
	wire	[7:0]					tx_fifo_rd_data;
	wire							tx_fifo_rd_valid;
	wire							tx_fifo_rd_ready;
	
	// FIFO
	jelly_fifo_async_fwtf
			#(
				.DATA_WIDTH		(8),
				.PTR_WIDTH		(TX_FIFO_PTR_WIDTH)
			)
		i_fifo_tx
			(
				.wr_reset		(reset),				
				.wr_clk			(clk),
				.wr_data		(tx_data),
				.wr_valid		(tx_valid),
				.wr_ready		(tx_ready),
				.wr_free_num	(tx_fifo_free_num),
				
				.rd_reset		(reset),
				.rd_clk			(uart_clk),
				.rd_data		(tx_fifo_rd_data),
				.rd_valid		(tx_fifo_rd_valid),
				.rd_ready		(tx_fifo_rd_ready),
				.rd_data_num	()
			);
	
	// transmitter
	jelly_uart_tx
		i_uart_tx
			(
				.reset			(reset),
				.clk			(uart_clk),
				
				.uart_tx		(uart_tx),
				
				.tx_valid		(tx_fifo_rd_valid),
				.tx_data		(tx_fifo_rd_data), 
				.tx_ready		(tx_fifo_rd_ready)
			);
	
	
	
	
	// -------------------------
	//  RX
	// -------------------------
	
	wire	[7:0]					rx_fifo_wr_data;
	wire							rx_fifo_wr_valid;
	wire							rx_fifo_wr_ready;
	
	// FIFO
	jelly_fifo_async_fwtf
			#(
				.DATA_WIDTH		(8),
				.PTR_WIDTH		(RX_FIFO_PTR_WIDTH)
			)
		i_fifo_rx
			(
				.wr_reset		(reset),
				.wr_clk			(uart_clk),
				.wr_data		(rx_fifo_wr_data),
				.wr_valid		(rx_fifo_wr_valid),
				.wr_ready		(rx_fifo_wr_ready),
				.wr_free_num	(),
				
				.rd_reset		(reset),
				.rd_clk			(clk),
				.rd_data		(rx_data),
				.rd_valid		(rx_valid),
				.rd_ready		(rx_ready),
				.rd_data_num	(rx_fifo_data_num)
			);
	
	// receiver
	jelly_uart_rx
		i_uart_rx
			(
				.reset			(reset), 
				.clk			(uart_clk),
				
				.uart_rx		(uart_rx),
				
				.rx_valid		(rx_fifo_wr_valid),
				.rx_data		(rx_fifo_wr_data)
			);
	
	
	// -------------------------
	//  Debug
	// -------------------------
	
	generate
	if ( SIMULATION & DEBUG ) begin
		always @ ( posedge clk ) begin
			if ( rx_valid & rx_ready ) begin
				if ( rx_data >= 8'h20 && rx_data <= 8'h7e ) begin
					$display("%m : [UART-RX] %h %c", rx_data, rx_data);
				end
				else begin
					$display("%m : [UART-RX] %h", rx_data);
				end
			end
			
			if ( tx_valid & tx_ready ) begin
				if ( tx_data >= 8'h20 && tx_data <= 8'h7e ) begin
					$display("%m : [UART-TX] %h %c", tx_data, tx_data);
				end
				else begin
					$display("%m : [UART-TX] %h", tx_data);
				end
			end
		end
	end
	endgenerate
	
endmodule


`default_nettype wire


// end of file

