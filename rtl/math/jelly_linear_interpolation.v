// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_linear_interpolation
		#(
			parameter	USER_WIDTH    = 0,
			parameter	RATE_WIDTH    = 4,
			parameter	S_DATA0_WIDTH = 8,
			parameter	S_DATA1_WIDTH = S_DATA0_WIDTH,
			parameter	DATA0_SIGNED  = 1,
			parameter	DATA1_SIGNED  = 1,
			parameter	M_DATA_WIDTH  = S_DATA0_WIDTH > S_DATA1_WIDTH ? S_DATA0_WIDTH : S_DATA1_WIDTH,
			
			// local
			parameter	USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[USER_BITS-1:0]			s_user,
			input	wire	[RATE_WIDTH-1:0]		s_rate,
			input	wire	[S_DATA0_WIDTH-1:0]		s_data0,
			input	wire	[S_DATA1_WIDTH-1:0]		s_data1,
			input	wire							s_valid,
			
			output	wire	[USER_BITS-1:0]			m_user,
			output	wire	[M_DATA_WIDTH-1:0]		m_data,
			output	wire							m_valid
		);
	
	localparam	DATA_WIDTH = M_DATA_WIDTH + 1;
	
	// 符号拡張
	wire	signed	[S_DATA0_WIDTH:0]	tmp_data0 = DATA0_SIGNED ? {s_data0[S_DATA0_WIDTH-1], s_data0} : {1'b0, s_data0};
	wire	signed	[S_DATA1_WIDTH:0]	tmp_data1 = DATA1_SIGNED ? {s_data1[S_DATA1_WIDTH-1], s_data1} : {1'b0, s_data1};
	wire	signed	[DATA_WIDTH-1:0]	signed_data0 = tmp_data0;
	wire	signed	[DATA_WIDTH-1:0]	signed_data1 = tmp_data1;
	
	// パイプライン構成
	wire	[(RATE_WIDTH+1)*USER_BITS-1:0]		pipeline_user;
	wire	[(RATE_WIDTH+1)*RATE_WIDTH-1:0]		pipeline_rate;
	wire	[(RATE_WIDTH+1)*DATA_WIDTH-1:0]		pipeline_data0;
	wire	[(RATE_WIDTH+1)*DATA_WIDTH-1:0]		pipeline_data1;
	wire	[(RATE_WIDTH+1)-1:0]				pipeline_valid;
	
	assign pipeline_user [0*USER_BITS  +: USER_BITS]  = USER_WIDTH > 0 ? s_user : 1'bx;
	assign pipeline_rate [0*RATE_WIDTH +: RATE_WIDTH] = s_rate;
	assign pipeline_data0[0*DATA_WIDTH +: DATA_WIDTH] = signed_data0;
	assign pipeline_data1[0*DATA_WIDTH +: DATA_WIDTH] = signed_data1;
	assign pipeline_valid[0]                          = s_valid;
	
	
	genvar	i;
	generate
	for ( i = 0; i < RATE_WIDTH; i = i+1 ) begin : loop_rate
		jelly_linear_interpolation_unit
				#(
					.USER_WIDTH		(USER_BITS),
					.RATE_WIDTH		(RATE_WIDTH),
					.DATA_WIDTH		(DATA_WIDTH)
				)
			i_linear_interpolation_unit
				(
					.reset			(reset),
					.clk			(clk),
					.cke			(cke),
					                 
					.s_user			(pipeline_user [i*USER_BITS  +: USER_BITS]),
					.s_rate			(pipeline_rate [i*RATE_WIDTH +: RATE_WIDTH]),
					.s_data0		(pipeline_data0[i*DATA_WIDTH +: DATA_WIDTH]),
					.s_data1		(pipeline_data1[i*DATA_WIDTH +: DATA_WIDTH]),
					.s_valid		(pipeline_valid[i]),
					                 
					.m_user			(pipeline_user [(i+1)*USER_BITS  +: USER_BITS]),
					.m_rate			(pipeline_rate [(i+1)*RATE_WIDTH +: RATE_WIDTH]),
					.m_data0		(pipeline_data0[(i+1)*DATA_WIDTH +: DATA_WIDTH]),
					.m_data1		(pipeline_data1[(i+1)*DATA_WIDTH +: DATA_WIDTH]),
					.m_valid		(pipeline_valid[(i+1)])
				);
	end
	endgenerate
	
	assign m_user  = USER_WIDTH > 0 ? pipeline_user [RATE_WIDTH*USER_BITS +: USER_BITS] : 1'b1;
	assign m_data  = pipeline_data0[RATE_WIDTH*DATA_WIDTH +: DATA_WIDTH];
	assign m_valid = pipeline_valid[RATE_WIDTH];
	
	
endmodule


module jelly_linear_interpolation_unit
		#(
			parameter	USER_WIDTH    = 1,
			parameter	RATE_WIDTH    = 8,
			parameter	DATA_WIDTH    = 0
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire			[USER_WIDTH-1:0]	s_user,
			input	wire			[RATE_WIDTH-1:0]	s_rate,
			input	wire	signed	[DATA_WIDTH-1:0]	s_data0,
			input	wire	signed	[DATA_WIDTH-1:0]	s_data1,
			input	wire								s_valid,
			
			output	wire			[USER_WIDTH-1:0]	m_user,
			output	wire			[RATE_WIDTH-1:0]	m_rate,
			output	wire	signed	[DATA_WIDTH-1:0]	m_data0,
			output	wire	signed	[DATA_WIDTH-1:0]	m_data1,
			output	wire								m_valid
		);
	
	reg				[USER_WIDTH-1:0]	reg_user;
	reg				[RATE_WIDTH-1:0]	reg_rate;
	reg		signed	[DATA_WIDTH-1:0]	reg_data0;
	reg		signed	[DATA_WIDTH-1:0]	reg_data1;
	reg									reg_valid;
	
	reg		signed	[DATA_WIDTH-1:0]	tmp_data;
	
	always @(posedge clk) begin
		if ( cke ) begin
			tmp_data = ((s_data0 + s_data1) >> 1);
			
			reg_rate  <= (s_rate << 1);
			reg_data0 <= (s_rate[RATE_WIDTH-1] == 1'b0) ? s_data0 : tmp_data;
			reg_data1 <= (s_rate[RATE_WIDTH-1] == 1'b1) ? s_data1 : tmp_data;
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_valid <= 1'b0;
		end
		else if ( cke ) begin
			reg_valid <= s_valid;
		end
	end
	
	assign m_user  = reg_user;
	assign m_rate  = reg_rate;
	assign m_data0 = reg_data0;
	assign m_data1 = reg_data1;
	assign m_valid = reg_valid;
	
endmodule


`default_nettype wire



// end of file
