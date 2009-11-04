// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    UART
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// uart
module jelly_uart
		#(
			parameter							TX_FIFO_PTR_WIDTH = 4,
			parameter							RX_FIFO_PTR_WIDTH = 4,
			         
			parameter							WB_ADR_WIDTH  = 2,
			parameter							WB_DAT_WIDTH  = 32,
			parameter							WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			// UART
			input	wire						uart_clk,
			output	wire						uart_tx,
			input	wire						uart_rx,
			
			output	wire						irq_rx,
			output	wire						irq_tx,
			
			// control
			input	wire	[WB_ADR_WIDTH-1:0]	wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]	wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]	wb_dat_i,
			input	wire						wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]	wb_sel_i,
			input	wire						wb_stb_i,
			output	wire						wb_ack_o
		);

	localparam	TX_FIFO_SIZE = (1 << TX_FIFO_PTR_WIDTH);
	localparam	RX_FIFO_SIZE = (1 << RX_FIFO_PTR_WIDTH);
	
	
	// -------------------------
	//   Core
	// -------------------------
	
	wire							tx_en;
	wire	[7:0]					tx_data;
	wire							tx_ready;

	wire							rx_en;
	wire	[7:0]					rx_data;
	wire							rx_ready;
	
	wire	[TX_FIFO_PTR_WIDTH:0]	tx_fifo_free_num;
	wire	[RX_FIFO_PTR_WIDTH:0]	rx_fifo_data_num;
	
	jelly_uart_core
			#(
				.TX_FIFO_PTR_WIDTH	(TX_FIFO_PTR_WIDTH),
				.RX_FIFO_PTR_WIDTH	(RX_FIFO_PTR_WIDTH)
			)
		i_uart_core
			(
				.reset				(reset),
				.clk				(clk),
				
				.uart_clk			(uart_clk),
				.uart_tx			(uart_tx),
				.uart_rx			(uart_rx),
				
				.tx_en				(tx_en),
				.tx_data			(tx_data),
				.tx_ready			(tx_ready),
				
				.rx_en				(rx_en),
				.rx_data			(rx_data),
				.rx_ready			(rx_ready),
				
				.tx_fifo_free_num	(tx_fifo_free_num),
				.rx_fifo_data_num	(rx_fifo_data_num)
			);
	
	
	// irq
	assign irq_tx = (tx_fifo_free_num == TX_FIFO_SIZE);
	assign irq_rx = rx_en;
	
	
	// -------------------------
	//  register
	// -------------------------
	
	// TX
	assign tx_en    = wb_stb_i & wb_we_i & (wb_adr_i == 0);
	assign tx_data  = wb_dat_i[7:0];
	
	// RX
	assign rx_ready = wb_stb_i & !wb_we_i & (wb_adr_i == 0);
	
	
	assign wb_dat_o = (wb_stb_i && (wb_adr_i == 0)) ? rx_data           : 32'h00000000
					| (wb_stb_i && (wb_adr_i == 1)) ? {tx_ready, rx_en} : 32'h00000000;
	assign wb_ack_o = 1'b1;
	
	
endmodule

