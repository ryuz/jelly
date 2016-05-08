// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// fixed_to_float
module jelly_fixed_to_float
		#(
			parameter	FIXED_SIGNED     = 0,
			parameter	FIXED_INT_WIDTH  = 32,
			parameter	FIXED_FRAC_WIDTH = 0,
			parameter	FIXED_WIDTH      = FIXED_INT_WIDTH + FIXED_FRAC_WIDTH,
			
			parameter	FLOAT_EXP_WIDTH  = 8,
			parameter	FLOAT_EXP_OFFSET = (1 << (FLOAT_EXP_WIDTH-1)) - 1,
			parameter	FLOAT_FRAC_WIDTH = 23,
			parameter	FLOAT_WIDTH      = 1 + FLOAT_EXP_WIDTH + FLOAT_FRAC_WIDTH,	// sign + exp + frac
			
			
			parameter	USER_WIDTH       = 0,
			parameter	USER_BITS        = USER_WIDTH > 0 ? USER_WIDTH : 1,
			
			parameter	MASTER_IN_REGS   = 1,
			parameter	MASTER_OUT_REGS  = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[USER_BITS-1:0]		s_user,
			input	wire	[FIXED_WIDTH-1:0]	s_fixed,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[USER_BITS-1:0]		m_user,
			output	wire	[FLOAT_WIDTH-1:0]	m_float,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	localparam	PIPELINE_STAGES = 3;
	
	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	
	wire	[USER_BITS-1:0]			src_user;
	wire	[FIXED_WIDTH-1:0]		src_fixed;
	
	wire	[USER_BITS-1:0]			sink_user;
	wire	[FLOAT_WIDTH-1:0]		sink_float;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+FIXED_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+FLOAT_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(MASTER_IN_REGS),
				.MASTER_OUT_REGS	(MASTER_OUT_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({s_user, s_fixed}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_float}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_fixed}),
				.src_valid			(),
				.sink_data			({sink_user, sink_float}),
				.buffered			()
			);
	
	
	reg		[USER_BITS-1:0]						st0_user;
	reg		[FIXED_WIDTH-1:0]					st0_fixed;
	reg											st0_sign;
	reg											st0_zero;

	reg		[FLOAT_EXP_WIDTH-1:0]				tmp_exp;
	reg		[FLOAT_FRAC_WIDTH+FIXED_WIDTH:0]	tmp_frac;
	
	reg		[USER_BITS-1:0]						st1_user;
	reg											st1_sign;
	reg											st1_zero;
	reg		[FLOAT_EXP_WIDTH-1:0]				st1_exp;
	reg		[FLOAT_FRAC_WIDTH-1:0]				st1_frac;
		
	reg		[USER_BITS-1:0]						st2_user;
	reg		[FLOAT_WIDTH-1:0]					st2_float;
	
	integer										i;
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_user  <= src_user;
			st0_sign  <= 1'b0;
			st0_zero  <= (src_fixed == {FIXED_WIDTH{1'b0}});
			st0_fixed <= src_fixed;
			if ( FIXED_SIGNED && src_fixed[FIXED_WIDTH-1] ) begin
				st0_sign  <= src_fixed[FIXED_WIDTH-1];
				st0_fixed <= -src_fixed;
			end
		end
		
		if ( stage_cke[1] ) begin
			tmp_exp  = FLOAT_EXP_OFFSET + (FLOAT_FRAC_WIDTH + FIXED_INT_WIDTH);
			tmp_frac = {{(1 + FLOAT_FRAC_WIDTH){1'b0}}, st0_fixed};
			for ( i = 0; i < (FLOAT_FRAC_WIDTH + FIXED_WIDTH); i = i+1 ) begin
				if ( tmp_frac[FLOAT_FRAC_WIDTH + FIXED_WIDTH] == 1'b0 ) begin
					tmp_exp  = tmp_exp - 1'b1;
					tmp_frac = (tmp_frac << 1);
				end
			end
			st1_exp  <= tmp_exp;
			st1_frac <= tmp_frac[FIXED_WIDTH +: FLOAT_FRAC_WIDTH];
			st1_sign <= st0_sign;
			st1_zero <= st0_zero;
			st1_user <= st0_user;
		end
		
		if ( stage_cke[2] ) begin
			st2_user  <= st1_user;
			if ( st1_zero ) begin
				st2_float <= {FLOAT_WIDTH{1'b0}};
			end
			else begin
				st2_float <= {st1_sign, st1_exp, st1_frac};
			end
		end
	end
	
	assign sink_user  = st2_user;
	assign sink_float = st2_float;
	
endmodule



`default_nettype wire



// end of file
