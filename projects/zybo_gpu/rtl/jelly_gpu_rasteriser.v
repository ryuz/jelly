// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//   GPU用ラスタライザ部分
//
//                                 Copyright (C) 2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// ラスタライズ実行部
module jelly_gpu_rasteriser
		#(
			// XY座標の幅
			parameter	X_WIDTH          = 12,
			parameter	Y_WIDTH          = 12,
			
			// 領域判定式の個数と精度
			parameter	EVAL_NUM         = 3,
			parameter	EVAL_INT_WIDTH   = 28,
			parameter	EVAL_FRAC_WIDTH  = 4,
			parameter	EVAL_DATA_WIDTH  = EVAL_INT_WIDTH + EVAL_FRAC_WIDTH,
			
			// グーローシェーディング計算用の固定小数パラメータの個数と精度
			parameter	FIXED_NUM        = 3,
			parameter	FIXED_INT_WIDTH  = 28,
			parameter	FIXED_FRAC_WIDTH = 4,
			parameter	FIXED_DATA_WIDTH = FIXED_INT_WIDTH + FIXED_FRAC_WIDTH,
			
			// グーローシェーディング計算用の浮動小数点パラメータの個数と精度
			parameter	FLOAT_NUM        = 3,
			parameter	FLOAT_EXP_WIDTH  = 8,
			parameter	FLOAT_FRAC_WIDTH = 23,
			parameter	FLOAT_DATA_WIDTH = 1 + FLOAT_EXP_WIDTH + FLOAT_FRAC_WIDTH,
			
			// 出力のFF挿入
			parameter	MASTER_REGS      = 1
		)
		(
			input	wire										reset,
			input	wire										clk,
			input	wire										cke,
			
			input	wire	[X_WIDTH-1:0]						param_x_init,
			input	wire	[Y_WIDTH-1:0]						param_y_init,
			
			input	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		param_eval_init,
			input	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		param_eval_xstep,
			input	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		param_eval_ystep,
			
			input	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	param_fiexd_init,
			input	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	param_fiexd_xstep,
			input	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	param_fiexd_ystep,
			
			input	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	param_float_init,
			input	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	param_float_xstep,
			input	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	param_float_ystep,
			
			input	wire										s_initial,
			input	wire										s_newline,
			input	wire										s_valid,
			output	wire										s_ready,
			
			output	wire	[X_WIDTH-1:0]						m_x,
			output	wire	[Y_WIDTH-1:0]						m_y,
			output	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	m_fiexd_data,
			output	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	m_float_data,
			output	wire										m_valid,
			input	wire										m_ready
		);
	
	genvar	i;
	integer	j;
	
	// パイプライン制御
	wire	[11:0]								stage_cke;
	wire	[11:0]								stage_valid;
	wire	[11:0]								next_valid;
	
	wire										src_initial;
	wire										src_newline;
	wire										src_valid;
	
	wire	[X_WIDTH-1:0]						sink_x;
	wire	[Y_WIDTH-1:0]						sink_y;
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	sink_fiexd_data;
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	sink_float_data;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(12),
				.S_DATA_WIDTH		(2),
				.M_DATA_WIDTH		(X_WIDTH + Y_WIDTH + (FIXED_NUM*FIXED_DATA_WIDTH) + (FLOAT_NUM*FLOAT_DATA_WIDTH)),
				.AUTO_VALID			(0),
				.INIT_DATA			(1),
				.MASTER_REGS		(MASTER_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({s_initial, s_newline}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_x, m_y, m_fiexd_data, m_float_data}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			(next_valid),
				
				.src_data			({src_initial, src_newline}),
				.src_valid			(src_valid),
				.sink_data			({sink_x, sink_y, sink_fiexd_data, sink_float_data}),
				
				.buffered			()
			);
	
	assign next_valid[0]  = src_valid;
	assign next_valid[1]  = stage_valid[0];
	assign next_valid[2]  = stage_valid[1];
	assign next_valid[3]  = stage_valid[2];
	assign next_valid[4]  = stage_valid[3];
	assign next_valid[5]  = stage_valid[4];
	assign next_valid[6]  = stage_valid[5];
	assign next_valid[7]  = stage_valid[6];
	assign next_valid[8]  = stage_valid[7];
	assign next_valid[9]  = stage_valid[8];
	assign next_valid[10] = stage_valid[9];
	assign next_valid[11] = stage_valid[10];
	
	// 制御信号
	reg		[10:0]	stage_initial;
	reg		[10:0]	stage_newline;
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			stage_initial[0] <= src_initial & src_valid;
			stage_newline[0] <= src_newline & src_valid;
		end
		for ( j = 1; j < 11; j = j+1 ) begin
			if ( stage_cke[j] ) begin
				stage_initial[j] <= stage_initial[j-1];
				stage_newline[j] <= stage_newline[j-1];
			end
		end
	end
	
	
	// 領域判別式
	generate
	for ( i = 0; i < EVAL_NUM; i = i+1 ) begin : eval_loop
//		reg		
		
	end
	endgenerate
	
	
	// 浮動小数点補間
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st5_float_data;
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st11_float_data;
	
	generate
	for ( i = 0; i < FLOAT_NUM; i = i+1 ) begin : float_loop
		// Y座標 float 
		jelly_float_step
				#(
					.EXP_WIDTH		(FLOAT_EXP_WIDTH),
					.FRAC_WIDTH		(FLOAT_FRAC_WIDTH)
				)
			i_float_step_y
				(
					.clk			(clk),
					.stage_cke		(stage_cke[5:0]),
					
					.param_init		(param_float_init [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
					.param_step		(param_float_ystep[i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
					
					.set_param		(src_valid & src_initial),
					.increment		(src_valid & src_newline),
					
					.out_data		(st5_float_data   [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH])
				);
		
		// X座標 float 
		jelly_float_step
				#(
					.EXP_WIDTH		(FLOAT_EXP_WIDTH),
					.FRAC_WIDTH		(FLOAT_FRAC_WIDTH)
				)
			i_float_step_x
				(
					.clk			(clk),
					.stage_cke		(stage_cke[11:6]),
					
					.param_init		(st5_float_data   [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
					.param_step		(param_float_xstep[i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
					
					.set_param		(stage_newline[5]),
					.increment		(stage_valid[5]),
					
					.out_data		(st11_float_data  [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH])
				);
	end
	endgenerate
	
	assign sink_float_data = st11_float_data;
	
endmodule


`default_nettype wire


// end of file
