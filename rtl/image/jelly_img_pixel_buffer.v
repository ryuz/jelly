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
			parameter	BORDER_CARE  = 1
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[1:0]						param_border_type,
			input	wire	[DATA_WIDTH-1:0]			param_border_constant,
			
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
	
	
	localparam	[1:0]	BORDER_TYPE_CONSTANT    = 2'd00;
	localparam	[1:0]	BORDER_TYPE_REPLICATE   = 2'd01;
	localparam	[1:0]	BORDER_TYPE_REFLECT     = 2'd10;
	localparam	[1:0]	BORDER_TYPE_REFLECT_101 = 2'd11;
	
	
	genvar								i;
	
	generate
	if ( PIXEL_NUM > 1 ) begin
		
		// control
		reg		[PIXEL_NUM-1:0]				st0_line_first;
		reg		[PIXEL_NUM-1:0]				st0_line_last;
		reg		[PIXEL_NUM-1:0]				st0_pixel_first;
		reg		[PIXEL_NUM-1:0]				st0_pixel_last;
		reg		[PIXEL_NUM*DATA_WIDTH-1:0]	st0_data;
		
		integer								x0, x1;
		reg									border_flag;

		reg		[PIXEL_NUM-1:0]				st1_line_first;
		reg		[PIXEL_NUM-1:0]				st1_line_last;
		reg		[PIXEL_NUM-1:0]				st1_pixel_first;
		reg		[PIXEL_NUM-1:0]				st1_pixel_last;
		reg		[PIXEL_NUM*DATA_WIDTH-1:0]	st1_data;
				
		always @(posedge clk) begin
			if ( reset ) begin
				st0_line_first    <= {PIXEL_NUM{1'b0}};
				st0_line_last     <= {PIXEL_NUM{1'b0}};
				st0_pixel_first   <= {PIXEL_NUM{1'b0}};
				st0_pixel_last    <= {PIXEL_NUM{1'b0}};
				st0_data          <= {PIXEL_NUM*DATA_WIDTH{1'bx}};
				
				st1_line_first    <= {PIXEL_NUM{1'b0}};
				st1_line_last     <= {PIXEL_NUM{1'b0}};
				st1_pixel_first   <= {PIXEL_NUM{1'b0}};
				st1_pixel_last    <= {PIXEL_NUM{1'b0}};
				st1_data          <= {PIXEL_NUM*DATA_WIDTH{1'bx}};
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
				st1_line_first  <= st0_line_first;
				st1_line_last   <= st0_line_last;
				st1_pixel_first <= st0_pixel_first;
				st1_pixel_last  <= st0_pixel_last;
				st1_data        <= st0_data;
				
				border_flag = 1'b0;
				for ( x0 = PIXEL_CENTER; x0 < PIXEL_NUM; x0 = x0+1 ) begin
					if ( !border_flag ) begin
						if ( st0_pixel_first[x0] ) begin
							border_flag = 1'b1;
							x1          = x0;
							if ( param_border_type == BORDER_TYPE_REFLECT_101 ) begin
								x1 = x0 - 1;
							end
						end
					end
					else begin
						if ( param_border_type == BORDER_TYPE_CONSTANT ) begin
							st1_data[x0*DATA_WIDTH +: DATA_WIDTH] <= param_border_constant;
						end
						else begin
							st1_data[x0*DATA_WIDTH +: DATA_WIDTH] <= st0_data[x1*DATA_WIDTH +: DATA_WIDTH];
							if ( param_border_constant == BORDER_TYPE_REFLECT || param_border_constant == BORDER_TYPE_REFLECT_101 ) begin
								x1 = x1 - 1;
							end
						end
					end
				end
				
				border_flag = 1'b0;
				for ( x0 = PIXEL_CENTER; x0 >= 0; x0 = x0-1 ) begin
					if ( !border_flag ) begin
						if ( st0_pixel_last[x0] ) begin
							border_flag = 1'b1;
							x1          = x0;
							if ( param_border_type == BORDER_TYPE_REFLECT_101 ) begin
								x1 = x0 + 1;
							end
						end
					end
					else begin
						if ( param_border_type == BORDER_TYPE_CONSTANT ) begin
							st1_data[x0*DATA_WIDTH +: DATA_WIDTH] <= param_border_constant;
						end
						else begin
							st1_data[x0*DATA_WIDTH +: DATA_WIDTH] <= st0_data[x1*DATA_WIDTH +: DATA_WIDTH];
							if ( param_border_constant == BORDER_TYPE_REFLECT || param_border_constant == BORDER_TYPE_REFLECT_101 ) begin
								x1 = x1 + 1;
							end
						end
					end
				end
			end
		end
		
		if ( BORDER_CARE ) begin
			assign m_img_line_first  = st1_line_first[PIXEL_CENTER];
			assign m_img_line_last   = st1_line_last[PIXEL_CENTER];
			assign m_img_pixel_first = st1_pixel_first[PIXEL_CENTER];
			assign m_img_pixel_last  = st1_pixel_last[PIXEL_CENTER];
			assign m_img_data        = st1_data;
		end
		else begin
			assign m_img_line_first  = st2_line_first[PIXEL_CENTER];
			assign m_img_line_last   = st2_line_last[PIXEL_CENTER];
			assign m_img_pixel_first = st2_pixel_first[PIXEL_CENTER];
			assign m_img_pixel_last  = st2_pixel_last[PIXEL_CENTER];
			assign m_img_data        = st2_data;
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
