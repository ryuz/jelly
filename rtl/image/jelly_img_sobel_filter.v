// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_img_sobel_filter
		#(
			parameter	DATA_WIDTH = 8
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire							s_img_line_first,
			input	wire							s_img_line_last,
			input	wire							s_img_pixel_first,
			input	wire							s_img_pixel_last,
			input	wire	[3*3*DATA_WIDTH-1:0]	s_img_data,
			
			output	wire							m_img_line_first,
			output	wire							m_img_line_last,
			output	wire							m_img_pixel_first,
			output	wire							m_img_pixel_last,
			output	wire	[DATA_WIDTH-1:0]		m_img_data
		);
	
	
	reg									st0_line_first,
	reg									st0_line_last,
	reg									st0_pixel_first,
	reg									st0_pixel_last,
	reg		signed	[DATA_WIDTH+3:0]	st0_h_data0;
	reg		signed	[DATA_WIDTH+3:0]	st0_h_data1;
	reg		signed	[DATA_WIDTH+3:0]	st0_h_data2;
	reg		signed	[DATA_WIDTH+3:0]	st0_v_data0;
	reg		signed	[DATA_WIDTH+3:0]	st0_v_data1;
	reg		signed	[DATA_WIDTH+3:0]	st0_v_data2;
	
	reg									st1_line_first,
	reg									st1_line_last,
	reg									st1_pixel_first,
	reg									st1_pixel_last,
	reg		signed	[DATA_WIDTH+3:0]	st1_h_data0;
	reg		signed	[DATA_WIDTH+3:0]	st1_h_data1;
	reg		signed	[DATA_WIDTH+3:0]	st1_v_data0;
	reg		signed	[DATA_WIDTH+3:0]	st1_v_data1;
	
	reg									st2_line_first,
	reg									st2_line_last,
	reg									st2_pixel_first,
	reg									st2_pixel_last,
	reg		signed	[DATA_WIDTH+3:0]	st2_h_data;
	reg		signed	[DATA_WIDTH+3:0]	st2_v_data;
	
	reg									st3_line_first,
	reg									st3_line_last,
	reg									st3_pixel_first,
	reg									st3_pixel_last,
	reg		signed	[DATA_WIDTH+3:0]	st3_h_data;
	reg		signed	[DATA_WIDTH+3:0]	st3_v_data;
	
	reg									st4_line_first,
	reg									st4_line_last,
	reg									st4_pixel_first,
	reg									st4_pixel_last,
	reg		signed	[DATA_WIDTH+3:0]	st4_h_data;
	
	always @(posedge clk) begin
		if ( cke ) begin
			st0_h_data0 <= s_img_data[((3*0+0)*DATA_WIDTH +: DATA_WIDTH] - s_img_data[((3*0+2)*DATA_WIDTH +: DATA_WIDTH];
			st0_h_data1 <= s_img_data[((3*1+0)*DATA_WIDTH +: DATA_WIDTH] - s_img_data[((3*1+2)*DATA_WIDTH +: DATA_WIDTH];
			st0_h_data2 <= s_img_data[((3*2+0)*DATA_WIDTH +: DATA_WIDTH] - s_img_data[((3*2+2)*DATA_WIDTH +: DATA_WIDTH];
			st0_v_data0 <= s_img_data[((3*0+0)*DATA_WIDTH +: DATA_WIDTH] - s_img_data[((3*2+0)*DATA_WIDTH +: DATA_WIDTH];
			st0_v_data1 <= s_img_data[((3*0+1)*DATA_WIDTH +: DATA_WIDTH] - s_img_data[((3*2+1)*DATA_WIDTH +: DATA_WIDTH];
			st0_v_data2 <= s_img_data[((3*0+2)*DATA_WIDTH +: DATA_WIDTH] - s_img_data[((3*2+2)*DATA_WIDTH +: DATA_WIDTH];
			
			st1_h_data0 <= st0_h_data0 + st0_h_data2;
			st1_h_data1 <= (st0_h_data1 <<< 1);
			st1_v_data0 <= st0_v_data0 + st0_v_data2;
			st1_v_data1 <= (st0_v_data1 <<< 1);
			
			st2_h_data  <= st1_h_data0 + st1_h_data1;
			st2_v_data  <= st1_v_data0 + st1_v_data1;
			
			st3_h_data  <= (st2_h_data >= 0) ? st2_h_data : -st2_h_data;
			st3_v_data  <= (st2_v_data >= 0) ? st2_v_data : -st2_v_data;;
			
			st4_data    <= st3_h_data + st3_v_data;
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_line_first  <= 1'b0;
			st0_line_last   <= 1'b0;
			st0_pixel_first <= 1'b0;
			st0_pixel_last  <= 1'b0;
			
			st1_line_first  <= 1'b0;
			st1_line_last   <= 1'b0;
			st1_pixel_first <= 1'b0;
			st1_pixel_last  <= 1'b0;
			
			st2_line_first  <= 1'b0;
			st2_line_last   <= 1'b0;
			st2_pixel_first <= 1'b0;
			st2_pixel_last  <= 1'b0;
			
			st3_line_first  <= 1'b0;
			st3_line_last   <= 1'b0;
			st3_pixel_first <= 1'b0;
			st3_pixel_last  <= 1'b0;
			
			st4_line_first  <= 1'b0;
			st4_line_last   <= 1'b0;
			st4_pixel_first <= 1'b0;
			st4_pixel_last  <= 1'b0;
		end
		else if ( cke ) begin
			st0_line_first  <= s_img_line_first;
			st0_line_last   <= s_img_line_last;
			st0_pixel_first <= s_img_pixel_first;
			st0_pixel_last  <= s_img_pixel_last;
			
			st1_line_first  <= st0_line_first;
			st1_line_last   <= st0_line_last;
			st1_pixel_first <= st0_pixel_first;
			st1_pixel_last  <= st0_pixel_last;
			
			st2_line_first  <= st1_line_first;
			st2_line_last   <= st1_line_last;
			st2_pixel_first <= st1_pixel_first;
			st2_pixel_last  <= st1_pixel_last;
			
			st3_line_first  <= st2_line_first;
			st3_line_last   <= st2_line_last;
			st3_pixel_first <= st2_pixel_first;
			st3_pixel_last  <= st2_pixel_last;
			
			st4_line_first  <= st3_line_first;
			st4_line_last   <= st3_line_last;
			st4_pixel_first <= st3_pixel_first;
			st4_pixel_last  <= st3_pixel_last;
		end
	end
	
	assign m_img_line_first  = st4_line_first;
	assign m_img_line_last   = st4_line_last;
	assign m_img_pixel_first = st4_pixel_first;
	assign m_img_pixel_last  = st4_pixel_last;
	assign m_img_data        = st4_data;
	
endmodule


`default_nettype wire


// end of file
