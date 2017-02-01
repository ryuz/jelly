// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// fixed_to_float
module jelly_fixed_to_float
		#(
			parameter	FIXED_SIGNED     = 1,
			parameter	FIXED_INT_WIDTH  = 32,
			parameter	FIXED_FRAC_WIDTH = 0,
			parameter	FIXED_WIDTH      = FIXED_INT_WIDTH + FIXED_FRAC_WIDTH,
			parameter	FIXED_EXP_WIDTH  = 0,
			parameter	FIXED_EXP_BITS   = FIXED_EXP_WIDTH > 0 ? FIXED_EXP_WIDTH                : 1,
			parameter	FIXED_EXP_OFFSET = FIXED_EXP_WIDTH > 0 ? (1 << (FIXED_EXP_WIDTH-1)) - 1 : 0,
			
			parameter	FLOAT_EXP_WIDTH  = 8,
			parameter	FLOAT_EXP_OFFSET = (1 << (FLOAT_EXP_WIDTH-1)) - 1,
			parameter	FLOAT_FRAC_WIDTH = 23,
			parameter	FLOAT_WIDTH      = 1 + FLOAT_EXP_WIDTH + FLOAT_FRAC_WIDTH,	// sign + exp + frac
			
			parameter	USE_FIXED_EXP    = (FIXED_EXP_WIDTH > 0),
			
			parameter	USER_WIDTH       = 0,
			parameter	USER_BITS        = USER_WIDTH > 0 ? USER_WIDTH : 1,
			
			parameter	MASTER_IN_REGS   = 1,
			parameter	MASTER_OUT_REGS  = 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[USER_BITS-1:0]			s_user,
			input	wire	[FIXED_WIDTH-1:0]		s_fixed,
			input	wire	[FIXED_EXP_BITS-1:0]	s_exp,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[USER_BITS-1:0]			m_user,
			output	wire	[FLOAT_WIDTH-1:0]		m_float,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	localparam	PIPELINE_STAGES = 3;
	
	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	
	wire	[USER_BITS-1:0]			src_user;
	wire	[FIXED_WIDTH-1:0]		src_fixed;
	wire	[FIXED_EXP_BITS-1:0]	src_exp;
	
	wire	[USER_BITS-1:0]			sink_user;
	wire	[FLOAT_WIDTH-1:0]		sink_float;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+FIXED_EXP_BITS+FIXED_WIDTH),
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
				
				.s_data				({s_user, s_exp, s_fixed}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_float}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_user, src_exp, src_fixed}),
				.src_valid			(),
				.sink_data			({sink_user, sink_float}),
				.buffered			()
			);
	
	localparam	UNSIGNED_WIDTH   = FIXED_SIGNED ? FIXED_WIDTH - 1 : FIXED_INT_WIDTH;
	localparam	ZERO_COUNT_WIDTH = UNSIGNED_WIDTH <=   2 ? 1 :
	                               UNSIGNED_WIDTH <=   4 ? 2 :
	                               UNSIGNED_WIDTH <=   8 ? 3 :
	                               UNSIGNED_WIDTH <=  16 ? 4 :
	                               UNSIGNED_WIDTH <=  32 ? 5 :
	                               UNSIGNED_WIDTH <=  64 ? 6 :
	                               UNSIGNED_WIDTH <= 127 ? 7 : 8;
	
	integer										i;
	reg											tmp_flag;
	
	reg		[USER_BITS-1:0]						st0_user;
	reg											st0_zero;
	reg											st0_sign;
	reg		[UNSIGNED_WIDTH-1:0]				st0_fixed;
	reg		[FIXED_EXP_BITS-1:0]				st0_exp;
	
	reg		[USER_BITS-1:0]						st1_user;
	reg											st1_zero;
	reg											st1_sign;
	reg		[ZERO_COUNT_WIDTH-1:0]				st1_clz;
	reg		[UNSIGNED_WIDTH-1:0]				st1_fixed;
	reg		[FIXED_EXP_BITS-1:0]				st1_exp;
	
	reg		[USER_BITS-1:0]						st2_user;
	reg											st2_sign;
	reg		[FLOAT_EXP_WIDTH-1:0]				st2_exp;
	reg		[FLOAT_FRAC_WIDTH-1:0]				st2_frac;
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_user <= src_user;
			st0_zero <= (src_fixed == {FIXED_WIDTH{1'b0}});
			st0_exp  <= src_exp;
			if ( FIXED_SIGNED ) begin
				st0_sign  <= src_fixed[FIXED_WIDTH-1];
				st0_fixed <= src_fixed[FIXED_WIDTH-1] ? -src_fixed : src_fixed;
			end
			else begin
				st0_sign  <= 1'b0;
				st0_fixed <= src_fixed;
			end
		end
		
		if ( stage_cke[1] ) begin
			st1_user  <= st0_user;
			st1_zero  <= st0_zero;
			st1_sign  <= st0_sign;
			st1_fixed <= st0_fixed;
			st1_exp   <= st0_exp;
			
			// count leading zero
			st1_clz <= UNSIGNED_WIDTH - 1;
	//		begin : block_clz
				tmp_flag = 1'b0;
				for ( i = 0; i < UNSIGNED_WIDTH-1; i = i+1 ) begin
					if ( st0_fixed[UNSIGNED_WIDTH-1-i] != 1'b0 && !tmp_flag ) begin
						st1_clz  <= i;
						tmp_flag  = 1'b1;
	//					disable block_clz;
					end
				end
	//		end
		end
		
		if ( stage_cke[2] ) begin
			st2_user  <= st1_user;
			if ( st1_zero ) begin
				st2_sign <= 1'b0;
				st2_exp  <= {FLOAT_EXP_WIDTH{1'b0}};
			end
			else begin
				st2_sign <= st1_sign;
				if ( USE_FIXED_EXP ) begin
					st2_exp  <= FLOAT_EXP_OFFSET + (UNSIGNED_WIDTH-1 - FIXED_FRAC_WIDTH) - st1_clz + (st1_exp - FIXED_EXP_OFFSET);
				end
				else begin
					st2_exp  <= FLOAT_EXP_OFFSET + (UNSIGNED_WIDTH-1 - FIXED_FRAC_WIDTH) - st1_clz;
				end
			end
			
			if ( FLOAT_FRAC_WIDTH > UNSIGNED_WIDTH ) begin
				st2_frac <= ((st1_fixed << (st1_clz+1)) << (FLOAT_FRAC_WIDTH - UNSIGNED_WIDTH));
			end
			else begin
				st2_frac <= ((st1_fixed << (st1_clz+1)) >> (UNSIGNED_WIDTH - FLOAT_FRAC_WIDTH));
			end
		end
	end
	
	assign sink_user  = st2_user;
	assign sink_float = {st2_sign, st2_exp, st2_frac};
	
	
endmodule



`default_nettype wire



// end of file
