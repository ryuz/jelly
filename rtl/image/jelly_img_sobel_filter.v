// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_sobel_filter
		#(
			parameter	USER_WIDTH   = 0,
			parameter	DATA_WIDTH   = 8,
			parameter	GRAD_X_WIDTH = DATA_WIDTH,
			parameter	GRAD_Y_WIDTH = DATA_WIDTH,
			
			// local
			parameter	USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire									reset,
			input	wire									clk,
			input	wire									cke,
			
			input	wire									s_img_line_first,
			input	wire									s_img_line_last,
			input	wire									s_img_pixel_first,
			input	wire									s_img_pixel_last,
			input	wire									s_img_de,
			input	wire			[USER_BITS-1:0]			s_img_user,
			input	wire			[3*3*DATA_WIDTH-1:0]	s_img_data,
			input	wire									s_img_valid,
			
			output	wire									m_img_line_first,
			output	wire									m_img_line_last,
			output	wire									m_img_pixel_first,
			output	wire									m_img_pixel_last,
			output	wire									m_img_de,
			output	wire			[USER_BITS-1:0]			m_img_user,
			output	wire			[DATA_WIDTH-1:0]		m_img_data,
			output	wire	signed	[GRAD_X_WIDTH-1:0]		m_img_grad_x,
			output	wire	signed	[GRAD_Y_WIDTH-1:0]		m_img_grad_y,
			output	wire									m_img_valid
		);
	
	wire	signed	[GRAD_X_WIDTH-1:0]	grad_x_min = {1'b1, {(GRAD_X_WIDTH-1){1'b0}}};
	wire	signed	[GRAD_X_WIDTH-1:0]	grad_x_max = {1'b0, {(GRAD_X_WIDTH-1){1'b1}}};
	wire	signed	[GRAD_Y_WIDTH-1:0]	grad_y_min = {1'b1, {(GRAD_Y_WIDTH-1){1'b0}}};
	wire	signed	[GRAD_Y_WIDTH-1:0]	grad_y_max = {1'b0, {(GRAD_Y_WIDTH-1){1'b1}}};
	
	wire	signed	[DATA_WIDTH+1:0]	s_img_data00 = s_img_data[(3*0+0)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data01 = s_img_data[(3*0+1)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data02 = s_img_data[(3*0+2)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data10 = s_img_data[(3*1+0)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data11 = s_img_data[(3*1+1)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data12 = s_img_data[(3*1+2)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data20 = s_img_data[(3*2+0)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data21 = s_img_data[(3*2+1)*DATA_WIDTH +: DATA_WIDTH];
	wire	signed	[DATA_WIDTH+1:0]	s_img_data22 = s_img_data[(3*2+2)*DATA_WIDTH +: DATA_WIDTH];	
	
	
	reg									st0_line_first;
	reg									st0_line_last;
	reg									st0_pixel_first;
	reg									st0_pixel_last;
	reg									st0_de;
	reg				[USER_BITS-1:0]		st0_user;
	reg				[DATA_WIDTH-1:0]	st0_data;
	reg									st0_valid;
	reg		signed	[DATA_WIDTH+3:0]	st0_grad_x0;
	reg		signed	[DATA_WIDTH+3:0]	st0_grad_x1;
	reg		signed	[DATA_WIDTH+3:0]	st0_grad_x2;
	reg		signed	[DATA_WIDTH+3:0]	st0_grad_y0;
	reg		signed	[DATA_WIDTH+3:0]	st0_grad_y1;
	reg		signed	[DATA_WIDTH+3:0]	st0_grad_y2;
	
	reg									st1_line_first;
	reg									st1_line_last;
	reg									st1_pixel_first;
	reg									st1_pixel_last;
	reg									st1_de;
	reg				[USER_BITS-1:0]		st1_user;
	reg				[DATA_WIDTH-1:0]	st1_data;
	reg									st1_valid;
	reg		signed	[DATA_WIDTH+3:0]	st1_grad_x0;
	reg		signed	[DATA_WIDTH+3:0]	st1_grad_x1;
	reg		signed	[DATA_WIDTH+3:0]	st1_grad_y0;
	reg		signed	[DATA_WIDTH+3:0]	st1_grad_y1;
	
	reg									st2_line_first;
	reg									st2_line_last;
	reg									st2_pixel_first;
	reg									st2_pixel_last;
	reg									st2_de;
	reg				[USER_BITS-1:0]		st2_user;
	reg				[DATA_WIDTH-1:0]	st2_data;
	reg									st2_valid;
	reg		signed	[DATA_WIDTH+3:0]	st2_grad_x;
	reg		signed	[DATA_WIDTH+3:0]	st2_grad_y;
	
	reg									st3_line_first;
	reg									st3_line_last;
	reg									st3_pixel_first;
	reg									st3_pixel_last;
	reg									st3_de;
	reg				[USER_BITS-1:0]		st3_user;
	reg				[DATA_WIDTH-1:0]	st3_data;
	reg									st3_valid;
	reg		signed	[GRAD_X_WIDTH+3:0]	st3_grad_x;
	reg		signed	[GRAD_Y_WIDTH+3:0]	st3_grad_y;
	
	

	
	always @(posedge clk) begin
		if ( cke ) begin
			// stage0
			st0_grad_x0 <= s_img_data00 - s_img_data02;
			st0_grad_x1 <= s_img_data10 - s_img_data12;
			st0_grad_x2 <= s_img_data20 - s_img_data22;
			st0_grad_y0 <= s_img_data00 - s_img_data20;
			st0_grad_y1 <= s_img_data01 - s_img_data21;
			st0_grad_y2 <= s_img_data02 - s_img_data22;
			
			// stage1
			st1_grad_x0 <= st0_grad_x0 + st0_grad_x2;
			st1_grad_x1 <= (st0_grad_x1 <<< 1);
			st1_grad_y0 <= st0_grad_y0 + st0_grad_y2;
			st1_grad_y1 <= (st0_grad_y1 <<< 1);
			
			// stage2
			st2_grad_x  <= st1_grad_x0 + st1_grad_x1;
			st2_grad_y  <= st1_grad_y0 + st1_grad_y1;
			
			// stage3
			st3_grad_x  <= st2_grad_x;
			if ( st2_grad_x < grad_x_min ) begin st3_grad_x <= grad_x_min; end
			if ( st2_grad_x > grad_x_max ) begin st3_grad_x <= grad_x_max; end
			
			st3_grad_y  <= st2_grad_y;
			if ( st2_grad_y < grad_y_min ) begin st3_grad_y <= grad_y_min; end
			if ( st2_grad_y > grad_y_max ) begin st3_grad_y <= grad_y_max; end
		end
	end
	
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_line_first  <= 1'bx;
			st0_line_last   <= 1'bx;
			st0_pixel_first <= 1'bx;
			st0_pixel_last  <= 1'bx;
			st0_de          <= 1'bx;
			st0_user        <= {USER_BITS{1'bx}};
			st0_data        <= {DATA_WIDTH{1'bx}};
			st0_valid       <= 1'b0;
			
			st1_line_first  <= 1'bx;
			st1_line_last   <= 1'bx;
			st1_pixel_first <= 1'bx;
			st1_pixel_last  <= 1'bx;
			st1_de          <= 1'bx;
			st1_user        <= {USER_BITS{1'bx}};
			st1_data        <= {DATA_WIDTH{1'bx}};
			st1_valid       <= 1'b0;
			
			st2_line_first  <= 1'bx;
			st2_line_last   <= 1'bx;
			st2_pixel_first <= 1'bx;
			st2_pixel_last  <= 1'bx;
			st2_de          <= 1'bx;
			st2_user        <= {USER_BITS{1'bx}};
			st2_data        <= {DATA_WIDTH{1'bx}};
			st2_valid       <= 1'b0;
			
			st3_line_first  <= 1'b0;
			st3_line_last   <= 1'b0;
			st3_pixel_first <= 1'b0;
			st3_pixel_last  <= 1'b0;
			st3_de          <= 1'b0;
			st3_user        <= {USER_BITS{1'bx}};
			st3_data        <= {DATA_WIDTH{1'bx}};
			st3_valid       <= 1'b0;
		end
		else if ( cke ) begin
			st0_line_first  <= s_img_line_first;
			st0_line_last   <= s_img_line_last;
			st0_pixel_first <= s_img_pixel_first;
			st0_pixel_last  <= s_img_pixel_last;
			st0_de          <= s_img_de;
			st0_user        <= s_img_user;
			st0_data        <= s_img_data[(3*1+1)*DATA_WIDTH +: DATA_WIDTH];
			st0_valid       <= s_img_valid;
			
			st1_line_first  <= st0_line_first;
			st1_line_last   <= st0_line_last;
			st1_pixel_first <= st0_pixel_first;
			st1_pixel_last  <= st0_pixel_last;
			st1_de          <= st0_de;
			st1_user        <= st0_user;
			st1_data        <= st0_data;
			st1_valid       <= st0_valid;
			
			st2_line_first  <= st1_line_first;
			st2_line_last   <= st1_line_last;
			st2_pixel_first <= st1_pixel_first;
			st2_pixel_last  <= st1_pixel_last;
			st2_de          <= st1_de;
			st2_user        <= st1_user;
			st2_data        <= st1_data;
			st2_valid       <= st1_valid;
			
			st3_line_first  <= st2_line_first;
			st3_line_last   <= st2_line_last;
			st3_pixel_first <= st2_pixel_first;
			st3_pixel_last  <= st2_pixel_last;
			st3_de          <= st2_de;
			st3_user        <= st2_user;
			st3_data        <= st2_data;
			st3_valid       <= st2_valid;
		end
	end
	
	assign m_img_line_first  = st3_line_first;
	assign m_img_line_last   = st3_line_last;
	assign m_img_pixel_first = st3_pixel_first;
	assign m_img_pixel_last  = st3_pixel_last;
	assign m_img_de          = st3_de;
	assign m_img_data        = st3_data;
	assign m_img_grad_x      = st3_grad_x;
	assign m_img_grad_y      = st3_grad_y;
	
endmodule


`default_nettype wire


// end of file
