// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// ring bus unit
module jelly_ring_bus_unit
		#(
			parameter	ID_WIDTH   = 8,
			parameter	DATA_WIDTH = 32,
			parameter	UNIT_ID    = 0
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[ID_WIDTH-1:0]		s_id,
			input	wire	[DATA_WIDTH-1:0]	s_data,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[DATA_WIDTH-1:0]	m_data,
			output	wire						m_valid,
			input	wire						m_ready,
			
			input	wire	[ID_WIDTH-1:0]		src_id,
			input	wire	[DATA_WIDTH-1:0]	src_data,
			input	wire						src_valid,
			
			output	wire	[ID_WIDTH-1:0]		dst_id,
			output	wire	[DATA_WIDTH-1:0]	dst_data,
			output	wire						dst_valid
		);
	
	reg		[ID_WIDTH-1:0]		reg_dst_id;
	reg		[DATA_WIDTH-1:0]	reg_dst_data;
	reg							reg_dst_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_dst_id    <= {ID_WIDTH{1'bx}};
			reg_dst_data  <= {DATA_WIDTH{1'bx}};
			reg_dst_valid <= 1'b0;
		end
		else if ( cke ) begin
			// データ転送
			reg_dst_id    <= src_id;
			reg_dst_data  <= src_data;
			reg_dst_valid <= src_valid;
			
			// データ取り出し
			if ( m_valid && m_ready ) begin
				reg_dst_id    <= {ID_WIDTH{1'bx}};
				reg_dst_data  <= {DATA_WIDTH{1'bx}};
				reg_dst_valid <= 1'b0;
			end
			
			// データ挿入
			if ( s_valid && s_ready ) begin
				reg_dst_id    <= s_id;
				reg_dst_data  <= s_data;
				reg_dst_valid <= s_valid;
			end
		end
	end
	
	
	// 制御
	assign s_ready   = (!src_valid || (m_valid && m_ready));
	
	assign m_data    = src_data;
	assign m_valid   = (src_valid && (src_id == UNIT_ID));
	
	assign dst_id    = reg_dst_id;
	assign dst_data  = reg_dst_data;
	assign dst_valid = reg_dst_valid;
	
	
endmodule



`default_nettype wire


// end of file
