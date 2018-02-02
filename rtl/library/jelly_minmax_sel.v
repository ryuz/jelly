// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// min/max selecter
module jelly_minmax_sel
		#(
			parameter	NUM               = 32,
			parameter	INDEX_WIDTH       = NUM <=     2 ?  1 :
	                                        NUM <=     4 ?  2 :
	                                        NUM <=     8 ?  3 :
	                                        NUM <=    16 ?  4 :
	                                        NUM <=    32 ?  5 :
	                                        NUM <=    64 ?  6 :
	                                        NUM <=   128 ?  7 :
	                                        NUM <=   256 ?  8 :
	                                        NUM <=   512 ?  9 :
	                                        NUM <=  1024 ? 10 :
	                                        NUM <=  2048 ? 11 :
	                                        NUM <=  4096 ? 12 :
	                                        NUM <=  8192 ? 13 :
	                                        NUM <= 16384 ? 14 :
	                                        NUM <= 32768 ? 15 : 16,
			parameter	COMMON_USER_WIDTH = 32,
			parameter	USER_WIDTH        = 32,
			parameter	DATA_WIDTH        = 32,
			parameter	DATA_SIGNED       = 1,
			parameter	CMP_MIN           = 0,		// minかmaxか
			parameter	CMP_EQ            = 0,		// 同値のとき data0 と data1 どちらを優先するか
			
			parameter	COMMON_USER_BITS  = COMMON_USER_WIDTH > 0 ? COMMON_USER_WIDTH : 1,
			parameter	USER_BITS         = USER_WIDTH        > 0 ? USER_WIDTH        : 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[COMMON_USER_BITS-1:0]	s_common_user,
			input	wire	[NUM*USER_BITS-1:0]		s_user,
			input	wire	[NUM*DATA_WIDTH-1:0]	s_data,
			input	wire	[NUM-1:0]				s_en,
			input	wire							s_valid,
			
			output	wire	[COMMON_USER_BITS-1:0]	m_common_user,
			output	wire	[USER_BITS-1:0]			m_user,
			output	wire	[DATA_WIDTH-1:0]		m_data,
			output	wire	[INDEX_WIDTH-1:0]		m_index,
			output	wire							m_en,
			output	wire							m_valid
		);
	
	genvar							i;
	
	
	// 1サイクルパイプラインが深くなるが、先にindexを求めてから、
	// マルチプレクサを入れた方がXILINXアーキテクチャに
	// フィットしないか実験
	
	
	// index作成
	wire	[NUM*INDEX_WIDTH-1:0]	s_index;
	generate
	for ( i = 0; i < NUM; i = i+1 ) begin : loop_s_index
		assign s_index[i*INDEX_WIDTH +: INDEX_WIDTH] = i;
	end
	endgenerate
	
	
	// min-max探索
	wire	[COMMON_USER_BITS-1:0]	minmax_common_user;
	wire	[NUM*USER_BITS-1:0]		minmax_user;
	wire	[NUM*DATA_WIDTH-1:0]	minmax_data;
	wire	[INDEX_WIDTH-1:0]		minmax_index;
	wire							minmax_en;
	wire							minmax_valid;
	
	jelly_minmax
			#(
				.NUM				(NUM),
				.COMMON_USER_WIDTH	(COMMON_USER_WIDTH + NUM*USER_BITS + NUM*DATA_WIDTH),
				.USER_WIDTH			(INDEX_WIDTH),
				.DATA_WIDTH			(DATA_WIDTH),
				.DATA_SIGNED		(DATA_SIGNED),
				.CMP_MIN			(CMP_MIN),
				.CMP_EQ				(CMP_EQ)
			)
		i_minmax
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_common_user		({s_common_user, s_user, s_data}),
				.s_user				(s_index),
				.s_data				(s_data),
				.s_en				(s_en),
				.s_valid			(s_valid),
				
				.m_common_user		({minmax_common_user, minmax_user, minmax_data}),
				.m_user				(minmax_index),
				.m_data				(),
				.m_en				(minmax_en),
				.m_valid			(minmax_valid)
			);
	
	
	// マルチプレクサ
	reg		[COMMON_USER_BITS-1:0]	mux_common_user;
	reg		[USER_BITS-1:0]			mux_user;
	reg		[DATA_WIDTH-1:0]		mux_data;
	reg		[INDEX_WIDTH-1:0]		mux_index;
	reg								mux_en;
	reg								mux_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			mux_common_user <= {COMMON_USER_BITS{1'bx}};
			mux_user        <= {USER_BITS{1'bx}};
			mux_data        <= {DATA_WIDTH{1'bx}};
			mux_index       <= {INDEX_WIDTH{1'bx}};
			mux_en          <= 1'bx;
			mux_valid       <= 1'b0;
		end
		else if ( cke ) begin
			mux_common_user <= minmax_common_user;
			mux_user        <= minmax_user[minmax_index*USER_BITS  +: USER_BITS];
			mux_data        <= minmax_data[minmax_index*DATA_WIDTH +: DATA_WIDTH];
			mux_index       <= minmax_index;
			mux_en          <= minmax_en;
			mux_valid       <= minmax_valid;
		end
	end
	
	assign m_common_user = mux_common_user;
	assign m_user        = mux_user;
	assign m_data        = mux_data;
	assign m_en          = mux_en;
	assign m_valid       = mux_valid;
	
endmodule


`default_nettype wire


// end of file
