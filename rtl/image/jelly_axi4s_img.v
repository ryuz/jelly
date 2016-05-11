// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


//   フレーム期間中のデータ入力の無い期間は cke を落とすことを
// 前提としてデータ稠密で、メモリを READ_FIRST モードで最適化
//   フレーム末尾で吐き出しのためにブランクデータを入れる際は
// line_first と line_last は正しく制御が必要

module jelly_axi4s_img
		#(
			parameter	DATA_WIDTH     = 8,
			parameter	IMG_X_WIDTH    = 10,
			parameter	IMG_Y_WIDTH    = 9,
			parameter	IMG_Y_NUM      = 480,
			parameter	BLANK_Y_WIDTH  = 8,
			parameter	INIT_Y_NUM     = IMG_Y_NUM,
			parameter	FIFO_PTR_WIDTH = 9,
			parameter	FIFO_RAM_TYPE  = "block",
			parameter	IMG_CKE_BUFG   = 0
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire	[BLANK_Y_WIDTH-1:0]			param_blank_num,
			
			input	wire	[DATA_WIDTH-1:0]			s_axi4s_tdata,
			input	wire								s_axi4s_tlast,
			input	wire	[0:0]						s_axi4s_tuser,
			input	wire								s_axi4s_tvalid,
			output	wire								s_axi4s_tready,
			
			output	wire	[DATA_WIDTH-1:0]			m_axi4s_tdata,
			output	wire								m_axi4s_tlast,
			output	wire	[0:0]						m_axi4s_tuser,
			output	wire								m_axi4s_tvalid,
			input	wire								m_axi4s_tready,
			
			
			output	wire								img_cke,
			
			output	wire								src_img_line_first,
			output	wire								src_img_line_last,
			output	wire								src_img_pixel_first,
			output	wire								src_img_pixel_last,
			output	wire	[DATA_WIDTH-1:0]			src_img_data,
			output	wire								src_img_de,
			
			input	wire								sink_img_line_first,
			input	wire								sink_img_line_last,
			input	wire								sink_img_pixel_first,
			input	wire								sink_img_pixel_last,
			input	wire	[DATA_WIDTH-1:0]			sink_img_data
		);
	
	
	// ブランキング追加中に次フレームが来てしまった場合の吸収用FIFO
	wire	[DATA_WIDTH-1:0]	axi4s_fifo_tdata;
	wire						axi4s_fifo_tlast;
	wire	[0:0]				axi4s_fifo_tuser;
	wire						axi4s_fifo_tvalid;
	wire						axi4s_fifo_tready;
	
	jelly_fifo_fwtf
			#(
				.DATA_WIDTH		(2+DATA_WIDTH),
				.PTR_WIDTH		(FIFO_PTR_WIDTH),
				.RAM_TYPE		(FIFO_RAM_TYPE)
			)
		i_fifo_fwtf
			(
				.reset			(reset),
				.clk			(clk),
				
				.s_data			({s_axi4s_tlast, s_axi4s_tuser, s_axi4s_tdata}),
				.s_valid		(s_axi4s_tvalid),
				.s_ready		(s_axi4s_tready),
				.s_free_count	(),
				
				.m_data			({axi4s_fifo_tlast, axi4s_fifo_tuser, axi4s_fifo_tdata}),
				.m_valid		(axi4s_fifo_tvalid),
				.m_ready		(axi4s_fifo_tready),
				.m_data_count	()
			);

	
	// ブロック処理吐き出し用にブランキングをフレーム末尾に追加
	wire	[DATA_WIDTH-1:0]	axi4s_blank_tdata;
	wire						axi4s_blank_tlast;
	wire	[0:0]				axi4s_blank_tuser;
	wire						axi4s_blank_tvalid;
	wire						axi4s_blank_tready;
	
	wire	[IMG_Y_WIDTH-1:0]	param_y_num;
	
	jelly_axi4s_insert_blank
			#(
				.DATA_WIDTH			(DATA_WIDTH),
				.IMG_X_WIDTH		(IMG_X_WIDTH),
				.IMG_Y_WIDTH		(IMG_Y_WIDTH),
				.BLANK_Y_WIDTH		(BLANK_Y_WIDTH),
				.INIT_Y_NUM			(INIT_Y_NUM)
			)
		i_axi4s_insert_blank
			(
				.reset				(reset),
				.clk				(clk),
				
				.param_blank_num	(param_blank_num),
				
				.monitor_x_num		(),
				.monitor_y_num		(param_y_num),
				

				.s_axi4s_tdata		(axi4s_fifo_tdata),
				.s_axi4s_tlast		(axi4s_fifo_tlast),
				.s_axi4s_tuser		(axi4s_fifo_tuser),
				.s_axi4s_tvalid		(axi4s_fifo_tvalid),
				.s_axi4s_tready		(axi4s_fifo_tready),
				
				.m_axi4s_tdata		(axi4s_blank_tdata),
				.m_axi4s_tlast		(axi4s_blank_tlast),
				.m_axi4s_tuser		(axi4s_blank_tuser),
				.m_axi4s_tvalid		(axi4s_blank_tvalid),
				.m_axi4s_tready		(axi4s_blank_tready)
			);
	
	
	// 画像処理用のフォーマットに変換
	wire						cke;
	
	jelly_axi4s_to_img
			#(
				.DATA_WIDTH			(DATA_WIDTH),
				.IMG_Y_WIDTH		(IMG_Y_WIDTH),
				.IMG_Y_NUM			(IMG_Y_NUM),
				.IMG_CKE_BUFG		(IMG_CKE_BUFG)
			)
		i_axi4s_to_img
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.param_y_num		(param_y_num),
				
				.s_axi4s_tdata		(axi4s_blank_tdata),
				.s_axi4s_tlast		(axi4s_blank_tlast),
				.s_axi4s_tuser		(axi4s_blank_tuser),
				.s_axi4s_tvalid		(axi4s_blank_tvalid),
				.s_axi4s_tready		(axi4s_blank_tready),
				
				.m_img_cke			(img_cke),
				.m_img_line_first	(src_img_line_first),
				.m_img_line_last	(src_img_line_last),
				.m_img_pixel_first	(src_img_pixel_first),
				.m_img_pixel_last	(src_img_pixel_last),
				.m_img_data			(src_img_data),
				.m_img_de			(src_img_de)
			);
	
	wire	[DATA_WIDTH-1:0]	axi4s_0_tdata;
	wire						axi4s_0_tlast;
	wire	[0:0]				axi4s_0_tuser;
	wire						axi4s_0_tvalid;
	
	jelly_img_to_axi4s
			#(
				.DATA_WIDTH		(DATA_WIDTH)
			)
		i_img_to_axi4s
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(img_cke),
				
				.s_img_line_first	(sink_img_line_first),
				.s_img_line_last	(sink_img_line_last),
				.s_img_pixel_first	(sink_img_pixel_first),
				.s_img_pixel_last	(sink_img_pixel_last),
				.s_img_data			(sink_img_data),
				
				.m_axi4s_tdata		(axi4s_0_tdata),
				.m_axi4s_tlast		(axi4s_0_tlast),
				.m_axi4s_tuser		(axi4s_0_tuser),
				.m_axi4s_tvalid		(axi4s_0_tvalid)
			);
	
	wire	[DATA_WIDTH-1:0]	axi4s_1_tdata;
	wire						axi4s_1_tlast;
	wire	[0:0]				axi4s_1_tuser;
	wire						axi4s_1_tvalid;
	wire						axi4s_1_tready;
	
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(2+DATA_WIDTH)
			)
		i_pipeline_insert_ff_0
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({axi4s_0_tlast, axi4s_0_tuser, axi4s_0_tdata}),
				.s_valid			(axi4s_0_tvalid),
				.s_ready			(),
				
				.m_data				({axi4s_1_tlast, axi4s_1_tuser, axi4s_1_tdata}),
				.m_valid			(axi4s_1_tvalid),
				.m_ready			(axi4s_1_tready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(2+DATA_WIDTH)
			)
		i_pipeline_insert_ff_1
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({axi4s_1_tlast, axi4s_1_tuser, axi4s_1_tdata}),
				.s_valid			(axi4s_1_tvalid),
				.s_ready			(axi4s_1_tready),
				
				.m_data				({m_axi4s_tlast, m_axi4s_tuser, m_axi4s_tdata}),
				.m_valid			(m_axi4s_tvalid),
				.m_ready			(m_axi4s_tready),
				
				.buffered			(),
				.s_ready_next		(cke)
			);
	
	
	/*
	reg		[DATA_WIDTH-1:0]		reg_buf_tdata;
	reg								reg_buf_tlast;
	reg		[0:0]					reg_buf_tuser;
	reg								reg_buf_tvalid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_buf_tdata  <= {DATA_WIDTH{1'bx}};
			reg_buf_tlast  <= 1'bx;
			reg_buf_tuser  <= 1'bx;
			reg_buf_tvalid <= 1'b0;
		end
		else begin
			if ( !m_axi4s_tready && axi4s_tvalid ) begin
				reg_buf_tdata  <= axi4s_tdata;
				reg_buf_tlast  <= axi4s_tlast;
				reg_buf_tuser  <= axi4s_tuser;
				reg_buf_tvalid <= 1'b1;
			end
			else if ( m_axi4s_tready ) begin
				reg_buf_tdata  <= {DATA_WIDTH{1'bx}};
				reg_buf_tlast  <= 1'bx;
				reg_buf_tuser  <= 1'bx;
				reg_buf_tvalid <= 1'b0;
			end
		end
	end
	
	assign cke            = !(reg_buf_tvalid || (m_axi4s_tvalid && !m_axi4s_tready));
	
	assign m_axi4s_tdata  = reg_buf_tvalid ? reg_buf_tdata : axi4s_tdata;
	assign m_axi4s_tlast  = reg_buf_tvalid ? reg_buf_tlast : axi4s_tlast;
	assign m_axi4s_tuser  = reg_buf_tvalid ? reg_buf_tuser : axi4s_tuser;
	assign m_axi4s_tvalid = reg_buf_tvalid ? 1'b1          : axi4s_tvalid;
	*/
	
	
endmodule


`default_nettype wire


// end of file
