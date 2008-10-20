`timescale 1ns / 1ps


module timer
		(
			reset, clk,
			
			interrupt_req,
			
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	WB_ADR_WIDTH  = 2;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	input						clk;
	input						reset;
	
	
	// control port (wishbone)
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	
	
	
	// -------------------------
	//  TX & RX
	// -------------------------
	
	// TX
	uart_tx
		i_uart_tx
			(
				.reset			(reset),
				.clk			(uart_clk_dv),
				
				.uart_tx		(uart_tx),
				
				.tx_en			(tx_fifo_rd_en),
				.tx_din			(tx_fifo_rd_data), 
				.tx_ready		(tx_fifo_rd_ready)
			);
	
	uart_rx
		i_uart_rx
			(
				.reset			(reset), 
				.clk			(uart_clk_dv),
				
				.uart_rx		(uart_rx),
				
				.rx_en			(rx_fifo_wr_en),
				.rx_dout		(rx_fifo_wr_data)
			);
	
	
	
	
	
endmodule

