// ----------------------------------------------------------------------------
//  Jelly  -- The computing system on FPGA
//    UART
//
//                                       Copyright (C) 2008 by Ryuji Fuchikami
//                                       http://homepage3.nifty.com/ryuz
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


module uart_tx
		(
			reset, clk,
			uart_tx,
			tx_en, tx_din, tx_ready
		);
	
	// system
	input						reset;
	input						clk;
	
	// UART
	output						uart_tx;
	
	// control
	input						tx_en;
	input	[7:0]				tx_din;
	output						tx_ready;
	
	
	// TX
	reg							tx_busy;
	reg		[6:0]				tx_count;
	reg		[8:0]				tx_data;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			tx_busy    <= 1'b0;
			tx_count   <= {7{1'bx}};
			tx_data[0] <= 1'b1;
		end
		else begin
			if ( !tx_busy ) begin
				if ( tx_en ) begin
					tx_busy      <= 1'b1;
					tx_data[0]   <= 1'b0;
					tx_data[8:1] <= tx_din;
					tx_count     <= 7'h00;
				end
			end
			else begin
				tx_count <= tx_count + 1;
				if ( tx_count[2:0] == 4'h7 ) begin
					tx_data <= {1'b1, tx_data[8:1]};
					if ( tx_count[6:3] == 4'ha ) begin
						tx_busy <= 1'b0;
					end
				end
			end
		end
	end
	
	assign tx_ready = ~tx_busy;
	assign uart_tx  = tx_data[0];
	
endmodule

