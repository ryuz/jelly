// ---------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    UART
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// uart
module jelly_uart
		(
			reset, clk,			
			uart_clk, uart_tx, uart_rx,
			irq_rx, irq_tx,
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	parameter	TX_FIFO_PTR_WIDTH = 4;
	parameter	RX_FIFO_PTR_WIDTH = 4;
	localparam	TX_FIFO_SIZE = (1 << TX_FIFO_PTR_WIDTH);
	localparam	RX_FIFO_SIZE = (1 << RX_FIFO_PTR_WIDTH);
	
	parameter	WB_ADR_WIDTH  = 2;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	input						clk;
	input						reset;
	
	// UART
	input						uart_clk;
	output						uart_tx;
	input						uart_rx;
	
	output						irq_rx;
	output						irq_tx;
	
	// control
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	
	
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

