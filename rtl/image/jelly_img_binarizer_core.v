// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_binarizer_core
		#(
			parameter	USER_WIDTH = 0,
			parameter	DATA_WIDTH = 8,
			
			parameter	USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[DATA_WIDTH-1:0]		param_th,
			input	wire							param_inv,
			
			input	wire							s_img_line_first,
			input	wire							s_img_line_last,
			input	wire							s_img_pixel_first,
			input	wire							s_img_pixel_last,
			input	wire							s_img_de,
			input	wire	[USER_BITS-1:0]			s_img_user,
			input	wire	[DATA_WIDTH-1:0]		s_img_data,
			input	wire							s_img_valid,
			
			output	wire							m_img_line_first,
			output	wire							m_img_line_last,
			output	wire							m_img_pixel_first,
			output	wire							m_img_pixel_last,
			output	wire							m_img_de,
			output	wire	[USER_BITS-1:0]			m_img_user,
			output	wire	[DATA_WIDTH-1:0]		m_img_data,
			output	wire							m_img_binary,
			output	wire							m_img_valid
		);
	
	
	reg								st0_line_first;
	reg								st0_line_last;
	reg								st0_pixel_first;
	reg								st0_pixel_last;
	reg								st0_de;
	reg		[USER_BITS-1:0]			st0_user;
	reg		[DATA_WIDTH-1:0]		st0_data;
	reg								st0_binary;
	reg								st0_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_line_first  <= 1'bx;
			st0_line_last   <= 1'bx;
			st0_pixel_first <= 1'bx;
			st0_pixel_last  <= 1'bx;
			st0_de          <= 1'bx;
			st0_user        <= {USER_BITS{1'bx}};
			st0_data        <= {DATA_WIDTH{1'bx}};
			st0_binary      <= 1'bx;
			st0_valid       <= 1'b0;
		end
		else if ( cke ) begin
			st0_line_first  <= s_img_line_first;
			st0_line_last   <= s_img_line_last;
			st0_pixel_first <= s_img_pixel_first;
			st0_pixel_last  <= s_img_pixel_last;
			st0_de          <= s_img_de;
			st0_user        <= s_img_user;
			st0_data        <= s_img_data;
			if ( s_img_data > param_th ) begin
				st0_binary <= 1'b1 ^ param_inv;
			end
			else begin
				st0_binary <= 1'b0 ^ param_inv;
			end
			st0_valid       <= s_img_valid;
		end
	end
	
	assign m_img_line_first  = st0_line_first;
	assign m_img_line_last   = st0_line_last;
	assign m_img_pixel_first = st0_pixel_first;
	assign m_img_pixel_last  = st0_pixel_last;
	assign m_img_de          = st0_de;
	assign m_img_user        = st0_user;
	assign m_img_data        = st0_data;
	assign m_img_binary      = st0_binary;
	assign m_img_valid       = st0_valid;
	
	
endmodule


`default_nettype wire


// end of file
