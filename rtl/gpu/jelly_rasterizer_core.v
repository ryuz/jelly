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
			input	wire	[PARAMS_REGION_SIZE*REGION_WIDTH-1:0]	params_region
			
			
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
	
	always @(posedge clk) begin
		if ( reset ) begin
			timgen_valid   <= 1'b0;
		end
		else if ( cke ) begin
			if ( !timgen_valid ) begin
				timgen_valid   <= start;
			end
			else begin
				if ( (timgen_x == param_width) && (timgen_y == param_height) ) begin
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
			if ( timgen_x  == param_width ) begin
				timgen_x       <= {X_WIDTH{1'b0}};
				timgen_y       <= timgen_y + 1'b1;
				timgen_x_first <= 1'b1;
				if ( timgen_y == param_height ) begin
					timgen_y       <= {Y_WIDTH{1'b0}};
					timgen_y_first <= 1'b1;
				end
			end
		end
	end
	
	
	// -----------------------------------------
	//  パラメータ計算
	// -----------------------------------------

	wire	[EDGE_NUM-1:0]										edge_sign;
	wire	[POLYGON_NUM*POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	polygon_value;
	reg															params_valid;
	
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
					.out_sign		(edge_sign[i])
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
						
						.out_value		(polygon_value[(i*POLYGON_PARAM_NUM+j)*POLYGON_WIDTH +: POLYGON_WIDTH]),
						.out_sign		()
					);
		end
	end
	endgenerate
	
	always @(posedge clk) begin
		if ( reset ) begin
			params_valid <= 1'b0;
		end
		else if ( cke ) begin
			params_valid <= timgen_valid;
		end
	end
	
	
	// -----------------------------------------
	//  領域判定
	// -----------------------------------------
	
	reg		[POLYGON_NUM-1:0]						region_enable;
	reg		[PARAMS_POLYGON_SIZE*POLYGON_WIDTH-1:0]	region_polygon_value;
	reg												region_valid;
	
	generate
	for ( i = 0; i < POLYGON_NUM; i = i+1 ) begin : loop_region
		wire	[REGION_WIDTH-1:0]	region_flag   = params_region[(i*2+0)*REGION_WIDTH +: REGION_WIDTH];
		wire	[REGION_WIDTH-1:0]	polarity_flag = params_region[(i*2+1)*REGION_WIDTH +: REGION_WIDTH];
		reg		[1:0]				en_flag;
		
		always @(posedge clk) begin
			if ( cke ) begin
				en_flag[0] =  (&((edge_sign ^ polarity_flag) | ~region_flag));
				en_flag[1] = !(|((edge_sign ^ polarity_flag) &  region_flag));
				
				region_enable[i] <= ((en_flag & param_culling) != 0);
			end
		end
	end
	endgenerate
	
	always @(posedge clk) begin
		if ( cke ) begin
			region_polygon_value <= region_polygon_value;
		end
	end

	always @(posedge clk) begin
		if ( reset ) begin
			region_valid <= 1'b0;
		end
		else if ( cke ) begin
			region_valid <= params_valid;
		end
	end
	
	
	
	// -----------------------------------------
	//  ソーティング
	// -----------------------------------------
	
	generate
	if ( CULLING_ONLY ) begin : blk_culling
		// カリングのみ
	end
	else begin
		// Zソート
	end
	endgenerate
	
	
	assign busy = timgen_valid;
	
	
	
endmodule


`default_nettype wire


// End of file
