// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rasterizer_core
		#(
			parameter	X_WIDTH             = 12,
			parameter	Y_WIDTH             = 12,
			
			parameter	EDGE_NUM            = 12,
			parameter	EDGE_WIDTH          = 32,
			
			parameter	POLYGON_NUM         = 6,
			parameter	POLYGON_PARAM_NUM   = 3,
			parameter	POLYGON_WIDTH       = 32,
			
			parameter	REGION_NUM          = POLYGON_NUM,
			parameter	REGION_WIDTH        = EDGE_NUM,
			
			parameter	INDEX_WIDTH         = POLYGON_NUM <=     2 ?  1 :
	                                          POLYGON_NUM <=     4 ?  2 :
	                                          POLYGON_NUM <=     8 ?  3 :
	                                          POLYGON_NUM <=    16 ?  4 :
	                                          POLYGON_NUM <=    32 ?  5 :
	                                          POLYGON_NUM <=    64 ?  6 :
	                                          POLYGON_NUM <=   128 ?  7 :
	                                          POLYGON_NUM <=   256 ?  8 :
	                                          POLYGON_NUM <=   512 ?  9 :
	                                          POLYGON_NUM <=  1024 ? 10 :
	                                          POLYGON_NUM <=  2048 ? 11 :
	                                          POLYGON_NUM <=  4096 ? 12 :
	                                          POLYGON_NUM <=  8192 ? 13 :
	                                          POLYGON_NUM <= 16384 ? 14 :
	                                          POLYGON_NUM <= 32768 ? 15 : 16,
			
			parameter	CULLING_ONLY        = 1,
			
			
			// local
			parameter	PARAMS_EDGE_SIZE    = EDGE_NUM*3,
			parameter	PARAMS_POLYGON_SIZE = POLYGON_NUM*POLYGON_PARAM_NUM*3,
			parameter	PARAMS_REGION_SIZE  = REGION_NUM*2
		)
		(
			input	wire											reset,
			input	wire											clk,
			input	wire											cke,
			
			input	wire											start,
			output	wire											busy,
			
			input	wire	[X_WIDTH-1:0]							param_width,
			input	wire	[Y_WIDTH-1:0]							param_height,
			input	wire	[1:0]									param_culling,
			
			input	wire	[PARAMS_EDGE_SIZE*EDGE_WIDTH-1:0]		params_edge,
			input	wire	[PARAMS_POLYGON_SIZE*POLYGON_WIDTH-1:0]	params_polygon,
			input	wire	[PARAMS_REGION_SIZE*REGION_WIDTH-1:0]	params_region,
			
			output	wire											m_frame_start,
			output	wire											m_line_end,
			output	wire											m_polygon_enable,
			output	wire	[INDEX_WIDTH-1:0]						m_polygon_index,
			output	wire	[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	m_polygon_params,
			output	wire											m_valid
		);
	
	
	genvar	i, j;
	
	
	// -----------------------------------------
	//  タイミング生成
	// -----------------------------------------
	
	reg		[X_WIDTH-1:0]		timgen_x;
	reg		[Y_WIDTH-1:0]		timgen_y;
	reg							timgen_x_first;
	reg							timgen_y_first;
	reg							timgen_valid;
	
	wire						timgen_frame_start = ((timgen_x == 0)           && (timgen_y == 0));
	wire						timgen_frame_end   = ((timgen_x == param_width) && (timgen_y == param_height));
	wire						timgen_line_end    = (timgen_x == param_width);
	
	always @(posedge clk) begin
		if ( reset ) begin
			timgen_valid   <= 1'b0;
		end
		else if ( cke ) begin
			if ( !timgen_valid ) begin
				timgen_valid   <= start;
			end
			else begin
				if ( timgen_frame_end ) begin
					timgen_valid <= 1'b0;
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( !timgen_valid ) begin
			timgen_x       <= {X_WIDTH{1'b0}};
			timgen_y       <= {Y_WIDTH{1'b0}};
			timgen_x_first <= 1'b1;
			timgen_y_first <= 1'b1;
		end
		else if ( cke ) begin
			timgen_x       <= timgen_x + 1'b1;
			timgen_x_first <= 1'b0;
			timgen_y_first <= 1'b0;
			if ( timgen_line_end ) begin
				timgen_x       <= {X_WIDTH{1'b0}};
				timgen_y       <= timgen_y + 1'b1;
				timgen_x_first <= 1'b1;
				if ( timgen_frame_end ) begin
					timgen_y       <= {Y_WIDTH{1'b0}};
					timgen_y_first <= 1'b1;
				end
			end
		end
	end
	
	
	// -----------------------------------------
	//  パラメータ計算
	// -----------------------------------------

	wire	[EDGE_NUM-1:0]										calc_edge_sign;
	wire	[POLYGON_NUM*POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	calc_polygon_params;
	reg															calc_frame_start;
	reg															calc_line_end;
	reg															calc_valid;
	
	// エッジ判定回路
	generate
	for ( i = 0; i < EDGE_NUM; i = i+1 ) begin : loop_edge
		jelly_rasterizer_plane_calc
				#(
					.WIDTH			(EDGE_WIDTH)
				)
			i_rasterizer_plane_calc_edge
				(
					.reset			(reset),
					.clk			(clk),
					.cke			(cke),
					
					.x_first		(timgen_x_first),
					.y_first		(timgen_y_first),
					
					.dx				(params_edge[(i*3+0)*EDGE_WIDTH +: EDGE_WIDTH]),
					.dy_stride		(params_edge[(i*3+1)*EDGE_WIDTH +: EDGE_WIDTH]),
					.offset			(params_edge[(i*3+2)*EDGE_WIDTH +: EDGE_WIDTH]),
					
					.out_value		(),
					.out_sign		(calc_edge_sign[i])
				);
	end
	endgenerate
	
	// ポリゴンパラメータ判定回路
	generate
	for ( i = 0; i < POLYGON_NUM; i = i+1 ) begin : loop_polygon
		for ( j = 0; j < POLYGON_PARAM_NUM; j = j+1 ) begin : loop_polygon_param
			jelly_rasterizer_plane_calc
					#(
						.WIDTH			(POLYGON_WIDTH)
					)
				i_rasterizer_plane_calc_polygon
					(
						.reset			(reset),
						.clk			(clk),
						.cke			(cke),
						
						.x_first		(timgen_x_first),
						.y_first		(timgen_y_first),
						
						.dx				(params_polygon[((i*POLYGON_PARAM_NUM+j)*3+0)*POLYGON_WIDTH +: POLYGON_WIDTH]),
						.dy_stride		(params_polygon[((i*POLYGON_PARAM_NUM+j)*3+1)*POLYGON_WIDTH +: POLYGON_WIDTH]),
						.offset			(params_polygon[((i*POLYGON_PARAM_NUM+j)*3+2)*POLYGON_WIDTH +: POLYGON_WIDTH]),
						
						.out_value		(calc_polygon_params[(i*POLYGON_PARAM_NUM+j)*POLYGON_WIDTH +: POLYGON_WIDTH]),
						.out_sign		()
					);
		end
	end
	endgenerate
	
	always @(posedge clk) begin
		if ( cke ) begin
			calc_frame_start <= timgen_frame_start;
			calc_line_end    <= timgen_line_end;
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			calc_valid <= 1'b0;
		end
		else if ( cke ) begin
			calc_valid <= timgen_valid;
		end
	end
	
	
	// -----------------------------------------
	//  領域判定
	// -----------------------------------------
	
	reg															region_frame_start;
	reg															region_line_end;
	reg		[POLYGON_NUM-1:0]									region_polygon_enables;
	reg		[POLYGON_NUM*POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	region_polygon_params;
	reg															region_valid;
	
	generate
	for ( i = 0; i < POLYGON_NUM; i = i+1 ) begin : loop_region
		wire	[REGION_WIDTH-1:0]	region_flag   = params_region[(i*2+0)*REGION_WIDTH +: REGION_WIDTH];
		wire	[REGION_WIDTH-1:0]	polarity_flag = params_region[(i*2+1)*REGION_WIDTH +: REGION_WIDTH];
		reg		[1:0]				en_flag;
		
		always @(posedge clk) begin
			if ( cke ) begin
				region_frame_start <= calc_frame_start;
				region_line_end    <= calc_line_end;
				
				
				en_flag[0] =  (&((~calc_edge_sign ^ polarity_flag) | ~region_flag));
				en_flag[1] = !(|((~calc_edge_sign ^ polarity_flag) &  region_flag));
				
				region_polygon_enables[i] <= ((en_flag & param_culling) != 0);
			end
		end
	end
	endgenerate
	
	always @(posedge clk) begin
		if ( cke ) begin
			region_polygon_params <= calc_polygon_params;
		end
	end

	always @(posedge clk) begin
		if ( reset ) begin
			region_valid <= 1'b0;
		end
		else if ( cke ) begin
			region_valid <= calc_valid;
		end
	end
	
	
	
	// -----------------------------------------
	//  ソーティング
	// -----------------------------------------
	
	wire											select_frame_start;
	wire											select_line_end;
	wire											select_polygon_enable;
	wire	[INDEX_WIDTH-1:0]						select_polygon_index;
	wire	[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	select_polygon_params;
	wire											select_valid;
	
	generate
	if ( CULLING_ONLY ) begin : blk_culling
		// カリングのみ
		wire	[INDEX_WIDTH-1:0]	region_polygon_index;
		jelly_bit_encoder
				#(
					.DATA_WIDTH		(POLYGON_NUM),
					.SEL_WIDTH		(INDEX_WIDTH),
					.PRIORITYT		(1),
					.LSB_FIRST		(1)
				)
			jelly_bit_encoder
				(
					.in_data		(region_polygon_enables),
					.out_sel		(region_polygon_index)
				);
		
		reg															sel0_frame_start;
		reg															sel0_line_end;
		reg															sel0_polygon_enable;
		reg		[INDEX_WIDTH-1:0]									sel0_polygon_index;
		reg		[POLYGON_NUM*POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	sel0_polygon_params;
		reg															sel0_valid;
		
		reg															sel1_frame_start;
		reg															sel1_line_end;
		reg															sel1_polygon_enable;
		reg		[INDEX_WIDTH-1:0]									sel1_polygon_index;
		reg		[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]				sel1_polygon_params;
		reg															sel1_valid;
		
		always @(posedge clk) begin
			if ( cke ) begin
				// stage 0
				sel0_frame_start    <= region_frame_start;
				sel0_line_end       <= region_line_end;
				sel0_polygon_enable <= |region_polygon_enables;
				sel0_polygon_index  <= region_polygon_index;
				sel0_polygon_params <= region_polygon_params;
				
				// stage 1
				sel1_frame_start    <= sel0_frame_start;
				sel1_line_end       <= sel0_line_end;
				sel1_polygon_enable <= sel0_polygon_enable;
				sel1_polygon_index  <= sel0_polygon_index;
				sel1_polygon_params <= sel0_polygon_params[sel0_polygon_index*POLYGON_PARAM_NUM*POLYGON_WIDTH +: POLYGON_PARAM_NUM*POLYGON_WIDTH];
			end
		end
		
		always @(posedge clk) begin
			if ( reset ) begin
				sel0_valid <= 1'b0;
				sel1_valid <= 1'b0;
			end
			else if ( cke ) begin
				sel0_valid <= region_valid;
				sel1_valid <= sel0_valid;
			end
		end
		
		assign select_frame_start    = sel1_frame_start;
		assign select_line_end       = sel1_line_end;
		assign select_polygon_enable = sel1_polygon_enable;
		assign select_polygon_index  = sel1_polygon_index;
		assign select_polygon_params = sel1_polygon_params;
		assign select_valid          = sel1_valid;
	end
	else begin
		// Zソート
		
	end
	endgenerate
	
	
	assign m_frame_start    = select_frame_start;
	assign m_line_end       = select_line_end;
	assign m_polygon_enable = select_polygon_enable;
	assign m_polygon_index  = select_polygon_index;
	assign m_polygon_params = select_polygon_params;
	assign m_valid          = select_valid;
	
	
	assign busy = timgen_valid | m_valid;
	
endmodule


`default_nettype wire


// End of file
