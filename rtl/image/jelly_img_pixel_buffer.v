// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_img_pixel_buffer
		#(
			parameter	DATA_WIDTH   = 8,
			parameter	PIXEL_NUM    = 3,
			parameter	PIXEL_CENTER = PIXEL_NUM / 2,
			parameter	BORDER_MODE  = "REPLICATE",			// NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
			parameter	BORDER_VALUE = {DATA_WIDTH{1'b0}}	// BORDER_MODE == "CONSTANT"
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			// slave (input)
			input	wire								s_img_line_first,
			input	wire								s_img_line_last,
			input	wire								s_img_pixel_first,
			input	wire								s_img_pixel_last,
			input	wire	[DATA_WIDTH-1:0]			s_img_data,
			
			// master (output)
			output	wire								m_img_line_first,
			output	wire								m_img_line_last,
			output	wire								m_img_pixel_first,
			output	wire								m_img_pixel_last,
			output	wire	[PIXEL_NUM*DATA_WIDTH-1:0]	m_img_data
		);
	
	localparam	PIXEL_SEL = (PIXEL_NUM <=   2) ? 1 :
	                        (PIXEL_NUM <=   3) ? 2 :
	                        (PIXEL_NUM <=   7) ? 3 :
	                        (PIXEL_NUM <=  15) ? 4 :
	                        (PIXEL_NUM <=  31) ? 5 :
	                        (PIXEL_NUM <=  64) ? 6 :
	                        (PIXEL_NUM <= 128) ? 7 : 8;
	
	localparam	POS_WIDTH = (PIXEL_NUM <=   1) ?  1 :
	                        (PIXEL_NUM <=   3) ?  2 :
	                        (PIXEL_NUM <=   7) ?  3 :
	                        (PIXEL_NUM <=  15) ?  4 :
	                        (PIXEL_NUM <=  31) ?  5 :
	                        (PIXEL_NUM <=  63) ?  6 :
	                        (PIXEL_NUM <= 127) ?  7 :
	                        (PIXEL_NUM <= 255) ?  8 : 9;
	
	genvar								i;
	
	generate
	if ( PIXEL_NUM > 1 ) begin
		
		// control
		reg		[PIXEL_CENTER:0]			st0_line_first;
		reg		[PIXEL_CENTER:0]			st0_line_last;
		reg		[PIXEL_NUM-1:0]				st0_pixel_first;
		reg		[PIXEL_NUM-1:0]				st0_pixel_last;
		reg		[PIXEL_NUM*DATA_WIDTH-1:0]	st0_data;
		
		reg									st1_line_first;
		reg									st1_line_last;
		reg									st1_pixel_first;
		reg									st1_pixel_last;
		reg		[PIXEL_NUM*DATA_WIDTH-1:0]	st1_data;
		reg		[PIXEL_SEL-1:0]				st1_pos_first;
		reg		[PIXEL_SEL-1:0]				st1_pos_last;
		
		reg									st2_line_first;
		reg									st2_line_last;
		reg									st2_pixel_first;
		reg									st2_pixel_last;
		reg		[PIXEL_NUM*DATA_WIDTH-1:0]	st2_data;
		reg		[PIXEL_NUM*POS_WIDTH-1:0]	st2_pos_data;
		
		reg									st3_line_first;
		reg									st3_line_last;
		reg									st3_pixel_first;
		reg									st3_pixel_last;
		reg		[PIXEL_NUM*DATA_WIDTH-1:0]	st3_data;
		
		integer								x;
		
		always @(posedge clk) begin
			if ( reset ) begin
				st0_line_first    <= {(PIXEL_CENTER+1){1'b0}};
				st0_line_last     <= {(PIXEL_CENTER+1){1'b0}};
				st0_pixel_first   <= {PIXEL_NUM{1'b0}};
				st0_pixel_last    <= {PIXEL_NUM{1'b0}};
				st0_data          <= {PIXEL_NUM*DATA_WIDTH{1'bx}};
				
				st1_line_first    <= 1'b0;
				st1_line_last     <= 1'b0;
				st1_pixel_first   <= 1'b0;
				st1_pixel_last    <= 1'b0;
				st1_data          <= {PIXEL_NUM*DATA_WIDTH{1'bx}};
				st1_pos_first     <= {PIXEL_SEL{1'bx}};
				st1_pos_last      <= {PIXEL_SEL{1'bx}};
				
				st2_line_first    <= 1'b0;
				st2_line_last     <= 1'b0;
				st2_pixel_first   <= 1'b0;
				st2_pixel_last    <= 1'b0;
				st2_data          <= {PIXEL_NUM*DATA_WIDTH{1'bx}};
				st2_pos_data      <= {(PIXEL_NUM*POS_WIDTH){1'bx}};
				
				st3_line_first    <= 1'b0;
				st3_line_last     <= 1'b0;
				st3_pixel_first   <= 1'b0;
				st3_pixel_last    <= 1'b0;
				st3_data          <= {PIXEL_NUM*DATA_WIDTH{1'bx}};
			end
			else if ( cke ) begin
				// stage 0
				st0_line_first           <= (st0_line_first  << 1);
				st0_line_last            <= (st0_line_last   << 1);
				st0_pixel_first          <= (st0_pixel_first << 1);
				st0_pixel_last           <= (st0_pixel_last  << 1);
				st0_data                 <= (st0_data        << DATA_WIDTH);
				
				st0_line_first[0]        <= s_img_line_first;
				st0_line_last[0]         <= s_img_line_last;
				st0_pixel_first[0]       <= s_img_pixel_first;
				st0_pixel_last[0]        <= s_img_pixel_last;
				st0_data[DATA_WIDTH-1:0] <= s_img_data;
				
				
				// stage1
				st1_line_first  <= st0_line_first[PIXEL_CENTER];
				st1_line_last   <= st0_line_last[PIXEL_CENTER];
				st1_pixel_first <= st0_pixel_first[PIXEL_CENTER];
				st1_pixel_last  <= st0_pixel_last[PIXEL_CENTER];
				st1_data        <= st0_data;
				
				begin : search_first
					for ( x = PIXEL_CENTER; x < PIXEL_NUM; x = x+1 ) begin
						if ( st0_pixel_first[x] ) begin
							st1_pos_first <= x;
							disable search_first;
						end
					end
				end
				
				begin : search_last
				for ( x = PIXEL_CENTER; x >= 0; x = x-1 ) begin
					if ( st0_pixel_last[x] ) begin
							st1_pos_last <= x;
							disable search_last;
						end
					end
				end
				
				
				// stage2
				st2_line_first  <= st1_line_first;
				st2_line_last   <= st1_line_last;
				st2_pixel_first <= st1_pixel_first;
				st2_pixel_last  <= st1_pixel_last;
				st2_data        <= st1_data;
				
				for ( x = 0; x < PIXEL_NUM; x = x+1 ) begin
					st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= x;
					if ( x > PIXEL_CENTER ) begin
						if ( x > st1_pos_first ) begin
							if      ( BORDER_MODE == "CONSTANT"    ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= PIXEL_NUM;               end
							else if ( BORDER_MODE == "REPLICATE"   ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= st1_pos_first;           end
							else if ( BORDER_MODE == "REFLECT"     ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= st1_pos_first*2 - x;     end
							else if ( BORDER_MODE == "REFLECT_101" ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= st1_pos_first*2 - x - 1; end
						end
					end
					else if ( x < PIXEL_CENTER ) begin
						if ( x < st1_pos_last ) begin
							if      ( BORDER_MODE == "CONSTANT"    ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= PIXEL_NUM;               end
							else if ( BORDER_MODE == "REPLICATE"   ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= st1_pos_last;            end
							else if ( BORDER_MODE == "REFLECT"     ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= st1_pos_last*2 - x;      end
							else if ( BORDER_MODE == "REFLECT_101" ) begin st2_pos_data[x*POS_WIDTH +: POS_WIDTH] <= st1_pos_last*2 - x + 1;  end
						end
					end
				end
				
				// stage3
				st3_line_first  <= st2_line_first;
				st3_line_last   <= st2_line_last;
				st3_pixel_first <= st2_pixel_first;
				st3_pixel_last  <= st2_pixel_last;
				st3_data        <= st2_data;
				for ( x = 0; x < PIXEL_NUM; x = x+1 ) begin
					st3_data[x*DATA_WIDTH +: DATA_WIDTH] <= ({BORDER_VALUE, st2_data} >> (DATA_WIDTH * st2_pos_data[x*POS_WIDTH +: POS_WIDTH]));
				end
			end
		end
		
		if ( BORDER_MODE == "NONE" ) begin
			assign m_img_line_first  = st0_line_first[PIXEL_CENTER];
			assign m_img_line_last   = st0_line_last[PIXEL_CENTER];
			assign m_img_pixel_first = st0_pixel_first[PIXEL_CENTER];
			assign m_img_pixel_last  = st0_pixel_last[PIXEL_CENTER];
			assign m_img_data        = st0_data;
		end
		else begin
			assign m_img_line_first  = st3_line_first;
			assign m_img_line_last   = st3_line_last;
			assign m_img_pixel_first = st3_pixel_first;
			assign m_img_pixel_last  = st3_pixel_last;
			assign m_img_data        = st3_data;
		end
	end
	else begin
		assign m_img_line_first  = s_img_line_first;
		assign m_img_line_last   = s_img_line_last;
		assign m_img_pixel_first = s_img_pixel_first;
		assign m_img_pixel_last  = s_img_pixel_last;
		assign m_img_data        = s_img_data;
	end
	endgenerate
	
	
endmodule


`default_nettype wire


// end of file
