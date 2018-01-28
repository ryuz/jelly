// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rasterizer
		#(
			parameter	X_WIDTH             = 12,
			parameter	Y_WIDTH             = 12,
			
			parameter	WB_ADR_WIDTH        = 14,
			parameter	WB_DAT_WIDTH        = 32,
			parameter	WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8),
			
			parameter	BANK_NUM            = 2,
			parameter	BANK_ADDR_WIDTH     = 12,
			parameter	PARAMS_ADDR_WIDTH   = 10,
			
			parameter	EDGE_NUM            = 12,
			parameter	EDGE_WIDTH          = 32,
			parameter	EDGE_RAM_TYPE       = "distributed",
			
			parameter	POLYGON_NUM         = 6,
			parameter	POLYGON_PARAM_NUM   = 3,
			parameter	POLYGON_WIDTH       = 32,
			parameter	POLYGON_RAM_TYPE    = "distributed",
			
			parameter	REGION_NUM          = POLYGON_NUM,
			parameter	REGION_WIDTH        = EDGE_NUM,
			parameter	REGION_RAM_TYPE     = "distributed",
			
			parameter	INIT_CTL_ENABLE     = 1'b0,
			parameter	INIT_CTL_BANK       = 0,
			parameter	INIT_PARAM_WIDTH    = 640-1,
			parameter	INIT_PARAM_HEIGHT   = 480-1
		)
		(
			input	wire											reset,
			input	wire											clk,
			input	wire											cke,
			
			input	wire											s_wb_rst_i,
			input	wire											s_wb_clk_i,
			input	wire	[WB_ADR_WIDTH-1:0]						s_wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]						s_wb_dat_i,
			input	wire											s_wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]						s_wb_sel_i,
			input	wire											s_wb_stb_i,
			output	wire											s_wb_ack_o,
			
			output	wire											m_frame_first,
			output	wire	[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	m_params,
			output	wire											m_valid
		);
	
	// local
	localparam	PARAMS_EDGE_SIZE    = EDGE_NUM*3;
	localparam	PARAMS_POLYGON_SIZE = POLYGON_NUM*POLYGON_PARAM_NUM*3;
	localparam	PARAMS_REGION_SIZE  = REGION_NUM*2;
	
	
	// parameters
	wire											start;
	wire											busy;
	
	wire	[X_WIDTH-1:0]							param_width;
	wire	[Y_WIDTH-1:0]							param_height;
	
	wire	[PARAMS_EDGE_SIZE*EDGE_WIDTH-1:0]		params_edge;
	wire	[PARAMS_POLYGON_SIZE*POLYGON_WIDTH-1:0]	params_polygon;
	wire	[PARAMS_REGION_SIZE*REGION_WIDTH-1:0]	params_region;
	
	jelly_rasterizer_params
			#(
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH),
				
				.WB_ADR_WIDTH		(WB_ADR_WIDTH),
				.WB_DAT_WIDTH		(WB_DAT_WIDTH),
				.WB_SEL_WIDTH		(WB_SEL_WIDTH),
				
				.BANK_NUM			(BANK_NUM),
				.BANK_ADDR_WIDTH	(BANK_ADDR_WIDTH),
				.PARAMS_ADDR_WIDTH	(PARAMS_ADDR_WIDTH),
				
				.EDGE_NUM			(EDGE_NUM),
				.EDGE_WIDTH			(EDGE_WIDTH),
				.EDGE_RAM_TYPE		(EDGE_RAM_TYPE),
				
				.POLYGON_NUM		(POLYGON_NUM),
				.POLYGON_PARAM_NUM	(POLYGON_PARAM_NUM),
				.POLYGON_WIDTH		(POLYGON_WIDTH),
				.POLYGON_RAM_TYPE	(POLYGON_RAM_TYPE),
				
				.REGION_NUM			(REGION_NUM),
				.REGION_WIDTH		(REGION_WIDTH),
				.REGION_RAM_TYPE	(REGION_RAM_TYPE),
				
				.INIT_CTL_ENABLE	(INIT_CTL_ENABLE),
				.INIT_CTL_BANK		(INIT_CTL_BANK),
				.INIT_PARAM_WIDTH	(INIT_PARAM_WIDTH),
				.INIT_PARAM_HEIGHT	(INIT_PARAM_HEIGHT)
			)
		i_rasterizer_params
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.start				(start),
				.busy				(busy),
				
				.param_width		(param_width),
				.param_height		(param_height),
				
				.params_edge		(params_edge),
				.params_polygon		(params_polygon),
				.params_region		(params_region),
				
				.s_wb_rst_i			(s_wb_rst_i),
				.s_wb_clk_i			(s_wb_clk_i),
				.s_wb_adr_i			(s_wb_adr_i),
				.s_wb_dat_o			(s_wb_dat_o),
				.s_wb_dat_i			(s_wb_dat_i),
				.s_wb_we_i			(s_wb_we_i),
				.s_wb_sel_i			(s_wb_sel_i),
				.s_wb_stb_i			(s_wb_stb_i),
				.s_wb_ack_o			(s_wb_ack_o)
			);
	
	// core
	jelly_rasterizer_core
			#(
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH),
				
				.EDGE_NUM			(EDGE_NUM),
				.EDGE_WIDTH			(EDGE_WIDTH),
				
				.POLYGON_NUM		(POLYGON_NUM),
				.POLYGON_PARAM_NUM	(POLYGON_PARAM_NUM),
				.POLYGON_WIDTH		(POLYGON_WIDTH),
				
				.REGION_NUM			(REGION_NUM),
				.REGION_WIDTH		(REGION_WIDTH)
			)
		i_rasterizer_core
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.start				(start),
				.busy				(busy),
				
				.param_width		(param_width),
				.param_height		(param_height),
				.param_culling		(2'b01),
				
				.params_edge		(params_edge),
				.params_polygon		(params_polygon),
				.params_region		(params_region)
				
			
			
			);
	
	
endmodule


`default_nettype wire


// End of file
