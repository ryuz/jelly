// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    UART
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
//                                       http://homepage3.nifty.com/ryuz
// ----------------------------------------------------------------------------



`timescale 1ns / 1ps


module uart_rx
		(
			reset, clk,
			uart_rx,
			rx_en, rx_dout
		);
	
	// system
	input						reset;
	input						clk;
	
	// UART
	input						uart_rx;
	
	// control
	output						rx_en;
	output	[7:0]				rx_dout;
	
		
	// recv
	reg							rx_ff_data;
	reg		[8:0]				rx_data;
	reg							rx_busy;
	reg		[7:0]				rx_count;
	reg							rx_wr_en;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			rx_ff_data <= 1'b1;
			rx_data    <= {9{1'bx}};
			rx_busy    <= 1'b0;
			rx_count   <= 0;
			rx_wr_en   <= 1'b0;
		end
		else begin
			rx_ff_data <= uart_rx;
			
			if ( !rx_busy ) begin
				rx_wr_en <= 1'b0;
				if ( rx_ff_data == 1'b0 ) begin
					rx_busy  <= 1'b1;
					rx_count <= 0;
				end
			end
			else begin
				rx_count <= rx_count + 1;
				if ( rx_count[2:0] == 3'h3 ) begin
					rx_data <= {rx_ff_data, rx_data[8:1]};
					if ( rx_count[6:3] == 9 ) begin
						rx_busy  <= 1'b0;
						rx_wr_en <= 1'b1;
					end
				end
			end
		end
	end
	
	assign rx_en   = rx_wr_en;
	assign rx_dout = rx_data[7:0];
		
endmodule

