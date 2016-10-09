// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// Denormalized number to Floating point number
module jelly_denorm_to_float
		#(
			parameter	DENORM_SIGNED     = 1,
			parameter	DENORM_INT_WIDTH  = 16,
			parameter	DENORM_FRAC_WIDTH = 8,
			parameter	DENORM_WIDTH      = DENORM_INT_WIDTH + DENORM_FRAC_WIDTH,
			parameter	DENORM_EXP_WIDTH  = 0,
			parameter	DENORM_EXP_BITS   = DENORM_EXP_WIDTH > 0 ? DENORM_EXP_WIDTH                : 1,
			parameter	DENORM_EXP_OFFSET = DENORM_EXP_WIDTH > 0 ? (1 << (DENORM_EXP_WIDTH-1)) - 1 : 0,
			
			parameter	FIXED_INT_WIDTH   = 16,
			parameter	FIXED_FRAC_WIDTH  = 8,
			parameter	FIXED_WIDTH       = DENORM_INT_WIDTH + DENORM_FRAC_WIDTH,
			
			parameter	USER_WIDTH        = 0,
			parameter	USER_BITS         = USER_WIDTH > 0 ? USER_WIDTH : 1,
			
			parameter	MASTER_IN_REGS    = 1,
			parameter	MASTER_OUT_REGS   = 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[USER_BITS-1:0]			s_user,
			input	wire	[DENORM_WIDTH-1:0]		s_denorm,
			input	wire	[DENORM_EXP_BITS-1:0]	s_exp,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[USER_BITS-1:0]			m_user,
			output	wire	[FIXED_WIDTH-1:0]		m_fixed,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	localparam	PIPELINE_STAGES = 1;
	
	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	
	wire	[USER_BITS-1:0]			src_user;
	wire	[DENORM_WIDTH-1:0]		src_denorm;
	wire	[DENORM_EXP_BITS-1:0]	src_exp;
	
	wire	[USER_BITS-1:0]			sink_user;
	wire	[FIXED_WIDTH-1:0]		sink_fixed;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+DENORM_EXP_BITS+DENORM_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+FIXED_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(MASTER_IN_REGS),
				.MASTER_OUT_REGS	(MASTER_OUT_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({s_user, s_exp, s_denorm}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_fixed}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_exp, src_denorm}),
				.src_valid			(),
				.sink_data			({sink_user, sink_fixed}),
				.buffered			()
			);
	
	wire	signed	[DENORM_WIDTH-1:0]		src_denorm_signed = src_denorm;
	
	reg				[USER_BITS-1:0]			st0_user;
	reg				[FIXED_WIDTH-1:0]		st0_fixed;
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_user <= src_user;
			if ( DENORM_SIGNED ) begin
				if ( src_exp + FIXED_FRAC_WIDTH >= DENORM_EXP_OFFSET + DENORM_FRAC_WIDTH ) begin
					st0_fixed <= (src_denorm_signed <<< ((src_exp + FIXED_FRAC_WIDTH) - (DENORM_EXP_OFFSET + DENORM_FRAC_WIDTH)));
				end
				else begin
					st0_fixed <= (src_denorm_signed >>> ((DENORM_EXP_OFFSET + DENORM_FRAC_WIDTH) - (src_exp + FIXED_FRAC_WIDTH)));
				end
			end
			else begin
				if ( src_exp + FIXED_FRAC_WIDTH >= DENORM_EXP_OFFSET + DENORM_FRAC_WIDTH ) begin
					st0_fixed <= (src_denorm << ((src_exp + FIXED_FRAC_WIDTH) - (DENORM_EXP_OFFSET + DENORM_FRAC_WIDTH)));
				end
				else begin
					st0_fixed <= (src_denorm >> ((DENORM_EXP_OFFSET + DENORM_FRAC_WIDTH) - (src_exp + FIXED_FRAC_WIDTH)));
				end
			end
		end
	end
	
	assign sink_user  = st0_user;
	assign sink_fixed = st0_fixed;
	
endmodule



`default_nettype wire



// end of file
