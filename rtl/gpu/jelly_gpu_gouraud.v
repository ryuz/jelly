// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// グーローシェーディング版
module jelly_gpu_gouraud
		#(
			parameter	WB_ADR_WIDTH        = 14,
			parameter	WB_DAT_WIDTH        = 32,
			parameter	WB_SEL_WIDTH        = (WB_DAT_WIDTH / 8),
			
			parameter	COMPONENT_NUM       = 3,
			parameter	DATA_WIDTH          = 8,
			
			parameter	AXI4S_TUSER_WIDTH   = 1,
			parameter	AXI4S_TDATA_WIDTH   = COMPONENT_NUM*DATA_WIDTH,

			parameter	X_WIDTH             = 12,
			parameter	Y_WIDTH             = 12,
			
			parameter	BANK_NUM            = 2,
			parameter	BANK_ADDR_WIDTH     = 12,
			parameter	PARAMS_ADDR_WIDTH   = 10,
			
			parameter	EDGE_NUM            = 12,
			parameter	EDGE_WIDTH          = 32,
			parameter	EDGE_RAM_TYPE       = "distributed",
			
			parameter	POLYGON_NUM         = 6,
			parameter	POLYGON_PARAM_NUM   = COMPONENT_NUM,
			parameter	POLYGON_WIDTH       = 32,
			parameter	POLYGON_RAM_TYPE    = "distributed",
			parameter	POLYGON_Q           = 20,
			
			parameter	REGION_NUM          = POLYGON_NUM,
			parameter	REGION_WIDTH        = EDGE_NUM,
			parameter	REGION_RAM_TYPE     = "distributed",
			
			parameter	CULLING_ONLY        = 1,
			
			parameter	INIT_CTL_ENABLE     = 1'b0,
			parameter	INIT_CTL_BANK       = 0,
			parameter	INIT_PARAM_WIDTH    = 640-1,
			parameter	INIT_PARAM_HEIGHT   = 480-1
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire								s_wb_rst_i,
			input	wire								s_wb_clk_i,
			input	wire	[WB_ADR_WIDTH-1:0]			s_wb_adr_i,
			output	wire	[WB_DAT_WIDTH-1:0]			s_wb_dat_o,
			input	wire	[WB_DAT_WIDTH-1:0]			s_wb_dat_i,
			input	wire								s_wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]			s_wb_sel_i,
			input	wire								s_wb_stb_i,
			output	wire								s_wb_ack_o,
			
			output	wire	[AXI4S_TUSER_WIDTH-1:0]		m_axi4s_tuser,
			output	wire								m_axi4s_tlast,
			output	wire	[AXI4S_TDATA_WIDTH-1:0]		m_axi4s_tdata,
			output	wire								m_axi4s_tvalid,
			input	wire								m_axi4s_tready
		);
	
	
	localparam	INDEX_WIDTH         = POLYGON_NUM <=     2 ?  1 :
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
	
	integer											i;
	
	
	wire											cke;
	
	
	// ラスタライザ
	wire											rasterizer_frame_start;
	wire											rasterizer_line_end;
	wire											rasterizer_polygon_enable;
	wire	[INDEX_WIDTH-1:0]						rasterizer_polygon_index;
	wire	[POLYGON_PARAM_NUM*POLYGON_WIDTH-1:0]	rasterizer_polygon_params;
	wire											rasterizer_valid;
	
	jelly_rasterizer
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
		i_rasterizer
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.m_frame_start		(rasterizer_frame_first),
				.m_line_end			(rasterizer_line_end),
				.m_polygon_enable	(rasterizer_polygon_enable),
				.m_polygon_index	(rasterizer_polygon_index),
				.m_polygon_params	(rasterizer_polygon_params),
				.m_valid			(rasterizer_valid),
				
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
	
	
	// ピクセルシェーディング
	reg				[AXI4S_TUSER_WIDTH-1:0]	pixel_frame_start;
	reg										pixel_line_end;
	reg				[AXI4S_TDATA_WIDTH-1:0]	pixel_data;
	reg										pixel_valid;
	
	reg		signed	[POLYGON_WIDTH-1:0]		tmp_param;
	
	always @(posedge clk) begin
		if ( cke ) begin
			pixel_frame_start <= rasterizer_frame_first;
			pixel_line_end    <= rasterizer_line_end;
			
			if ( rasterizer_polygon_enable ) begin
				for ( i = 0; i < COMPONENT_NUM; i = i+1 ) begin
					tmp_param = rasterizer_polygon_params[i*POLYGON_WIDTH +: POLYGON_WIDTH];
					tmp_param = (tmp_param >>> (POLYGON_Q - DATA_WIDTH));
					if ( tmp_param < 0 ) begin tmp_param = {DATA_WIDTH{1'b0}}; end
					if ( tmp_param < 0 ) begin tmp_param = {DATA_WIDTH{1'b1}}; end
					pixel_data[i*DATA_WIDTH +: DATA_WIDTH] <= tmp_param;
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			pixel_valid <= 1'b0;
		end
		else if ( cke ) begin
			pixel_valid <= rasterizer_valid;
		end
	end
	
	
	// 出力(ckeにFF挿入)
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH		(AXI4S_TUSER_WIDTH + 1 + AXI4S_TDATA_WIDTH),
				.SLAVE_REGS		(1),
				.MASTER_REGS	(1)
			)
		i_pipeline_insert_ff
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(1'b1),
				
				.s_data			({
									pixel_frame_start,
									pixel_line_end,
									pixel_data
								}),
				.s_valid		(pixel_valid),
				.s_ready		(cke),
				
				.m_data			({
									m_axi4s_tuser,
									m_axi4s_tlast,
									m_axi4s_tdata
								}),
				.m_valid		(m_axi4s_tvalid),
				.m_ready		(m_axi4s_tready),
				
				.buffered		(),
				.s_ready_next	()
			);
	
	
endmodule


`default_nettype wire


// End of file
