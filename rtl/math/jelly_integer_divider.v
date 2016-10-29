// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_integer_divider
		#(
			parameter	USER_WIDTH       = 0,
			parameter	S_DIVIDEND_WIDTH = 32,
			parameter	S_DIVISOR_WIDTH  = 32,
			parameter	MASTER_IN_REGS   = 1,
			parameter	MASTER_OUT_REGS  = 1,
			parameter	DEVICE           = "RTL",
			
			parameter	USER_BITS        = USER_WIDTH > 0 ? USER_WIDTH : 1,
			parameter	M_QUOTIENT       = S_DIVIDEND_WIDTH,
			parameter	M_REMAINDER      = S_DIVISOR_WIDTH
		)
		(
			input	wire									reset,
			input	wire									clk,
			input	wire									cke,
			
			input	wire			[USER_BITS-1:0]			s_user,
			input	wire	signed	[S_DIVIDEND_WIDTH-1:0]	s_dividend,
			input	wire	signed	[S_DIVISOR_WIDTH-1:0]	s_divisor,
			input	wire									s_valid,
			output	wire									s_ready,
			
			output	wire			[USER_BITS-1:0]			m_user,
			output	wire	signed	[M_QUOTIENT-1:0]		m_quotient,
			output	wire			[M_REMAINDER-1:0]		m_remainder,
			output	wire									m_valid,
			input	wire									m_ready
		);
	
	
	localparam	PIPELINE_STAGES = S_DIVIDEND_WIDTH + 1;
	
	wire			[PIPELINE_STAGES-1:0]		stage_cke;
	wire			[PIPELINE_STAGES-1:0]		stage_valid;
	
	
	wire			[USER_BITS-1:0]				src_user;
	wire	signed	[S_DIVIDEND_WIDTH-1:0]		src_dividend;
	wire	signed	[S_DIVISOR_WIDTH-1:0]		src_divisor;
	
	wire			[USER_BITS-1:0]				sink_user;
	wire	signed	[M_QUOTIENT-1:0]			sink_quotient;
	wire			[M_REMAINDER-1:0]			sink_remainder;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+S_DIVIDEND_WIDTH+S_DIVISOR_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+M_QUOTIENT+M_REMAINDER),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(MASTER_IN_REGS),
				.MASTER_OUT_REGS	(MASTER_OUT_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({s_user, s_dividend, s_divisor}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_quotient, m_remainder}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_dividend, src_divisor}),
				.src_valid			(),
				.sink_data			({sink_user, sink_quotient, sink_remainder}),
				.buffered			()
			);
	
	genvar	i;
	
	localparam	N = S_DIVIDEND_WIDTH;
	
	wire	[(N+1)*S_DIVIDEND_WIDTH-1:0]	stages_dividend;
	wire	[(N+1)*S_DIVISOR_WIDTH-1:0]		stages_divisor;
	wire	[(N+1)*M_QUOTIENT-1:0]			stages_quotient;
	wire	[(N+1)*M_REMAINDER-1:0]			stages_remainder;
	wire	[(N+1)*USER_BITS-1:0]			stages_user;
	
	assign stages_dividend [0*S_DIVIDEND_WIDTH +: S_DIVIDEND_WIDTH] = src_dividend;
	assign stages_divisor  [0*S_DIVISOR_WIDTH  +: S_DIVISOR_WIDTH]  = src_divisor;
	assign stages_quotient [0*M_QUOTIENT       +: M_QUOTIENT]       = {M_QUOTIENT{1'b0}};
	assign stages_remainder[0*M_REMAINDER      +: M_REMAINDER]      = {M_REMAINDER{src_dividend[S_DIVIDEND_WIDTH-1]}};
	assign stages_user     [0*USER_BITS        +: USER_BITS]        = src_user;
	
	generate
	for ( i = 0; i < N; i = i+1 ) begin : loop_div
		wire			[USER_BITS-1:0]			in_user      = stages_user     [i*USER_BITS        +: USER_BITS];
		wire	signed	[S_DIVIDEND_WIDTH-1:0]	in_dividend  = stages_dividend [i*S_DIVIDEND_WIDTH +: S_DIVIDEND_WIDTH];
		wire	signed	[S_DIVISOR_WIDTH-1:0]	in_divisor   = stages_divisor  [i*S_DIVISOR_WIDTH  +: S_DIVISOR_WIDTH];
		wire	signed	[M_QUOTIENT-1:0]		in_quotient  = stages_quotient [i*M_QUOTIENT       +: M_QUOTIENT];
		wire	signed	[M_REMAINDER-1:0]		in_remainder = stages_remainder[i*M_REMAINDER      +: M_REMAINDER];
		
		
		wire	signed	[S_DIVIDEND_WIDTH-1:0]	tmp_dividend;
		wire	signed	[M_REMAINDER-1:0]		tmp_remainder;
		assign {tmp_remainder, tmp_dividend} = ({in_remainder, in_dividend} <<< 1);
		
		reg				[USER_BITS-1:0]			reg_user;
		reg		signed	[S_DIVIDEND_WIDTH-1:0]	reg_dividend;
		reg		signed	[S_DIVISOR_WIDTH-1:0]	reg_divisor;
		reg		signed	[M_QUOTIENT-1:0]		reg_quotient;
		reg		signed	[M_REMAINDER-1:0]		reg_remainder;
		
		always @(posedge clk) begin
			if ( stage_cke[i] ) begin
				reg_user      <= in_user;
				reg_dividend  <= tmp_dividend;
				reg_divisor   <= in_divisor;
				
				if ( tmp_remainder[M_REMAINDER-1] == in_divisor[S_DIVISOR_WIDTH-1] ) begin
					reg_remainder <= tmp_remainder - in_divisor;
					reg_quotient  <= {in_quotient, 1'b1};
				end
				else begin
					reg_remainder <= tmp_remainder + in_divisor;
					reg_quotient  <= {in_quotient, 1'b0};
				end
			end
		end
		
		
		assign stages_user     [(i+1)*USER_BITS        +: USER_BITS]        = reg_user;
		assign stages_dividend [(i+1)*S_DIVIDEND_WIDTH +: S_DIVIDEND_WIDTH] = reg_dividend;
		assign stages_divisor  [(i+1)*S_DIVISOR_WIDTH  +: S_DIVISOR_WIDTH]  = reg_divisor;
		assign stages_quotient [(i+1)*M_QUOTIENT       +: M_QUOTIENT]       = reg_quotient;
		assign stages_remainder[(i+1)*M_REMAINDER      +: M_REMAINDER]      = reg_remainder;
	end
	endgenerate
	
	
	wire			[USER_BITS-1:0]			last_user      = stages_user     [N*USER_BITS        +: USER_BITS];
	wire	signed	[S_DIVIDEND_WIDTH-1:0]	last_dividend  = stages_dividend [N*S_DIVIDEND_WIDTH +: S_DIVIDEND_WIDTH];
	wire	signed	[S_DIVISOR_WIDTH-1:0]	last_divisor   = stages_divisor  [N*S_DIVISOR_WIDTH  +: S_DIVISOR_WIDTH];
	wire	signed	[M_QUOTIENT-1:0]		last_quotient  = stages_quotient [N*M_QUOTIENT       +: M_QUOTIENT];
	wire	signed	[M_REMAINDER-1:0]		last_remainder = stages_remainder[N*M_REMAINDER      +: M_REMAINDER];
	
	reg				[USER_BITS-1:0]			reg_user;
	reg		signed	[M_QUOTIENT-1:0]		reg_quotient;
	reg		signed	[M_REMAINDER-1:0]		reg_remainder;
	
	always @(posedge clk) begin
		if ( stage_cke[N] ) begin
			reg_user      <= last_user;
			reg_quotient  <= (1'b1 << N) + {last_quotient[N-1:0], 1'b1};
			reg_remainder <= last_remainder;
		end
	end
	
	
	assign sink_user      = reg_user;
	assign sink_quotient  = reg_quotient;
	assign sink_remainder = reg_remainder;
	
endmodule



`default_nettype wire



// end of file
