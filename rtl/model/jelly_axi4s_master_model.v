// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_axi4s_master_model
		#(
			parameter	AXI4S_DATA_WIDTH = 32,
			parameter	X_NUM            = 640,
			parameter	Y_NUM            = 480
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			output	wire	[0:0]					m_axi4s_tuser,
			output	wire							m_axi4s_tlast,
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	wire		cke = (!m_axi4s_tvalid || m_axi4s_tready);
	
	integer		x = 0;
	integer		y = 0;
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			x <= 0;
			y <= 0;
		end
		else if ( cke ) begin
			x <= x + 1;
			if ( x == (X_NUM-1) ) begin
				x <= 0;
				y <= y + 1;
				if ( y == (Y_NUM-1) ) begin
					y <= 0;
				end
			end
		end
	end
	
	assign m_axi4s_tuser = (x == 0) && (y == 0);
	assign m_axi4s_tlast = (x == X_NUM-1);
//	assign m_axi4s_tdata[AXI4S_DATA_WIDTH/2-1:0] = x;
//	assign m_axi4s_tdata[AXI4S_DATA_WIDTH-1:AXI4S_DATA_WIDTH/2] = y;
	assign m_axi4s_tdata[7:0]   = (x<<4) + 1;
	assign m_axi4s_tdata[15:8]  = (x<<4) + 2;
	assign m_axi4s_tdata[23:16] = (x<<4) + 3;
	assign m_axi4s_tvalid = 1'b1;
	
endmodule


`default_nettype wire


// end of file
