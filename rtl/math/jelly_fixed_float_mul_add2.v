// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// f <= a*x + b*x + c
// 
// a, b, c : floating point number
// x, y    : fixed point number
// f       : denormalized number
module jelly_fixed_float_mul_add2
		#(
			parameter	S_FIXED_INT_WIDTH    = 12,
			parameter	S_FIXED_FRAC_WIDTH   = 0,
			parameter	S_FIXED_WIDTH        = S_FIXED_INT_WIDTH + S_FIXED_FRAC_WIDTH,
			
			parameter	S_FLOAT_EXP_WIDTH    = 8,
			parameter	S_FLOAT_EXP_OFFSET   = (1 << (S_FLOAT_EXP_WIDTH-1)) - 1,
			parameter	S_FLOAT_FRAC_WIDTH   = 23,
			parameter	S_FLOAT_WIDTH        = 1 + S_FLOAT_EXP_WIDTH + S_FLOAT_FRAC_WIDTH,	// sign + exp + frac
			
			parameter	M_DENORM_EXP_WIDTH   = S_FLOAT_EXP_WIDTH,
			parameter	M_DENORM_EXP_OFFSET  = (1 << (M_DENORM_EXP_WIDTH-1)) - 1,
			parameter	M_DENORM_INT_WIDTH   = 40,
			parameter	M_DENORM_FRAC_WIDTH  = 8,
			parameter	M_DENORM_FIXED_WIDTH = M_DENORM_INT_WIDTH + M_DENORM_FRAC_WIDTH,
			
			parameter	INT_WIDTH            = 48,
			
			parameter	USER_WIDTH           = 0,
			parameter	USER_BITS            = USER_WIDTH > 0 ? USER_WIDTH : 1,
			
			parameter	MASTER_IN_REGS       = 1,
			parameter	MASTER_OUT_REGS      = 1,
			
			parameter	DEVICE               = "RTL" // "7SERIES"
		)
		(
			input	wire										reset,
			input	wire										clk,
			input	wire										cke,
			
			input	wire			[USER_BITS-1:0]				s_user,
			input	wire	signed	[S_FIXED_WIDTH-1:0]			s_fixed_x,
			input	wire	signed	[S_FIXED_WIDTH-1:0]			s_fixed_y,
			input	wire			[S_FLOAT_WIDTH-1:0]			s_float_a,
			input	wire			[S_FLOAT_WIDTH-1:0]			s_float_b,
			input	wire			[S_FLOAT_WIDTH-1:0]			s_float_c,
			input	wire										s_valid,
			output	wire										s_ready,
			
			output	wire			[USER_BITS-1:0]				m_user,
			output	wire			[M_DENORM_EXP_WIDTH-1:0]	m_denorm_exp,
			output	wire	signed	[M_DENORM_FIXED_WIDTH-1:0]	m_denorm_fixed,
			output	wire										m_valid,
			input	wire										m_ready
		);
	
	
	localparam	PIPELINE_STAGES = 5;
	
	wire			[PIPELINE_STAGES-1:0]		stage_cke;
	wire			[PIPELINE_STAGES-1:0]		stage_valid;
	
	
	wire			[USER_BITS-1:0]				src_user;
	wire	signed	[S_FIXED_WIDTH-1:0]			src_x;
	wire	signed	[S_FIXED_WIDTH-1:0]			src_y;
	wire										src_a_sign;
	wire			[S_FLOAT_EXP_WIDTH-1:0]		src_a_exp;
	wire			[S_FLOAT_FRAC_WIDTH-1:0]	src_a_frac;
	wire										src_b_sign;
	wire			[S_FLOAT_EXP_WIDTH-1:0]		src_b_exp;
	wire			[S_FLOAT_FRAC_WIDTH-1:0]	src_b_frac;
	wire										src_c_sign;
	wire			[S_FLOAT_EXP_WIDTH-1:0]		src_c_exp;
	wire			[S_FLOAT_FRAC_WIDTH-1:0]	src_c_frac;
	
	wire			[USER_BITS-1:0]				sink_user;
	wire			[M_DENORM_EXP_WIDTH-1:0]	sink_denorm_exp;
	wire	signed	[M_DENORM_FIXED_WIDTH-1:0]	sink_denorm_fixed;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(USER_BITS+2*S_FIXED_WIDTH+3*S_FLOAT_WIDTH),
				.M_DATA_WIDTH		(USER_BITS+M_DENORM_EXP_WIDTH+M_DENORM_FIXED_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(MASTER_IN_REGS),
				.MASTER_OUT_REGS	(MASTER_OUT_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({
										s_user,
										s_fixed_x,
										s_fixed_y,
										s_float_a,
										s_float_b,
										s_float_c
									}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_user, m_denorm_exp, m_denorm_fixed}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({
										src_user,
										src_x,
										src_y,
										src_a_sign,
										src_a_exp,
										src_a_frac,
										src_b_sign,
										src_b_exp,
										src_b_frac,
										src_c_sign,
										src_c_exp,
										src_c_frac
									}),
				.src_valid			(),
				.sink_data			({sink_user, sink_denorm_exp, sink_denorm_fixed}),
				.buffered			()
			);
	
	
	
	localparam	S_FLOAT_INT_WIDTH = S_FLOAT_FRAC_WIDTH + 2;
	
	wire										src_a_one = (src_a_exp != 0);
	wire										src_b_one = (src_b_exp != 0);
	wire										src_c_one = (src_c_exp != 0);

	wire	signed	[S_FLOAT_INT_WIDTH-1:0]		src_a_int = src_a_sign ? -{1'b0, src_a_one, src_a_frac} : {1'b0, src_a_one, src_a_frac};
	wire	signed	[S_FLOAT_INT_WIDTH-1:0]		src_b_int = src_b_sign ? -{1'b0, src_b_one, src_b_frac} : {1'b0, src_b_one, src_b_frac};
	wire	signed	[S_FLOAT_INT_WIDTH-1:0]		src_c_int = src_c_sign ? -{1'b0, src_c_one, src_c_frac} : {1'b0, src_c_one, src_c_frac};
	
	reg				[USER_BITS-1:0]				st0_user;
	reg				[S_FLOAT_EXP_WIDTH-1:0]		st0_max_exp;
	reg				[S_FLOAT_EXP_WIDTH-1:0]		st0_a_shift;
	reg		signed	[S_FLOAT_INT_WIDTH-1:0]		st0_a_int;
	reg		signed	[S_FIXED_WIDTH-1:0]			st0_x;
	reg		signed	[S_FLOAT_INT_WIDTH-1:0]		st0_b_int;
	reg		signed	[S_FIXED_WIDTH-1:0]			st0_y;
	reg		signed	[S_FLOAT_EXP_WIDTH:0]		st0_c_exp;
	reg		signed	[S_FLOAT_INT_WIDTH-1:0]		st0_c_int;
	
	reg				[USER_BITS-1:0]				st1_user;
	reg				[S_FLOAT_EXP_WIDTH-1:0]		st1_exp;
	reg		signed	[S_FLOAT_INT_WIDTH-1:0]		st1_a_int;
	reg		signed	[S_FIXED_WIDTH-1:0]			st1_x;
	reg		signed	[INT_WIDTH-1:0]				st1_c_int;
	
	reg				[USER_BITS-1:0]				st2_user;
	reg				[S_FLOAT_EXP_WIDTH-1:0]		st2_exp;
	
	reg				[USER_BITS-1:0]				st3_user;
	reg				[S_FLOAT_EXP_WIDTH-1:0]		st3_exp;
	
	reg				[USER_BITS-1:0]				st4_user;
	reg				[S_FLOAT_EXP_WIDTH-1:0]		st4_exp;
	wire	signed	[INT_WIDTH-1:0]				st4_int;
	
	always @(posedge clk) begin
		// stage 0
		if ( stage_cke[0] ) begin
			st0_user <= src_user;
			if ( src_a_exp < src_b_exp ) begin
				st0_max_exp <= src_b_exp;
				
				st0_a_shift <= src_b_exp - src_a_exp;
				st0_a_int   <= src_a_int;
				st0_x       <= src_x;
				
				st0_b_int   <= src_b_int;
				st0_y       <= src_y;
				
				st0_c_exp   <= src_c_exp - src_b_exp;
				st0_c_int   <= src_c_int;
			end
			else begin
				// swap a*x <=> b*y
				st0_max_exp <= src_a_exp;
				
				st0_a_shift <= src_a_exp - src_b_exp;
				st0_a_int   <= src_b_int;
				st0_x       <= src_y;
				
				st0_b_int   <= src_a_int;
				st0_y       <= src_x;
				
				st0_c_exp   <= src_c_exp - src_a_exp;
				st0_c_int   <= src_c_int;
			end
		end
		
		// stage 1
		if ( stage_cke[1] ) begin
			st1_user  <= st0_user;
			st1_exp   <= st0_max_exp + (M_DENORM_EXP_OFFSET - S_FLOAT_EXP_OFFSET);
			
			st1_a_int <= (st0_a_int >>> st0_a_shift);
			st1_x     <= st0_x;
			
			if ( st0_c_exp >= 0 ) begin
				st1_c_int <= (st0_c_int <<< st0_c_exp);
			end
			else begin
				st1_c_int <= (st0_c_int >>> -st0_c_exp);
			end
		end
		
		// stage 2
		if ( stage_cke[2] ) begin
			st2_user <= st1_user;
			st2_exp  <= st1_exp;
		end
		
		// stage 3
		if ( stage_cke[3] ) begin
			st3_user <= st2_user;
			st3_exp  <= st2_exp;
		end
		
		// stage 4
		if ( stage_cke[4] ) begin
			st4_user <= st3_user;
			st4_exp  <= st3_exp;
		end
	end
	
	assign sink_user       = st4_user;
	assign sink_denorm_exp = st4_exp;
	
	generate
	if ( (S_FIXED_FRAC_WIDTH + S_FLOAT_FRAC_WIDTH) > M_DENORM_FRAC_WIDTH ) begin
		assign sink_denorm_fixed = (st4_int >>> ((S_FIXED_FRAC_WIDTH + S_FLOAT_FRAC_WIDTH) - M_DENORM_FRAC_WIDTH));
	end
	else begin
		assign sink_denorm_fixed = (st4_int >>> (M_DENORM_FRAC_WIDTH - (S_FIXED_FRAC_WIDTH + S_FLOAT_FRAC_WIDTH)));
	end
	endgenerate
	
	
	parameter	PC_WIDTH   = INT_WIDTH >= 48 ? INT_WIDTH : 48;
	
	wire	[PC_WIDTH-1:0]		y_pcout;
	
	jelly_mul_add_dsp48e1
				#(
					.A_WIDTH		(S_FLOAT_INT_WIDTH),
					.B_WIDTH		(S_FIXED_WIDTH),
					.C_WIDTH		(INT_WIDTH),
					.P_WIDTH		(INT_WIDTH),
					
					.OPMODEREG		(0),
					.ALUMODEREG		(0),
					.AREG			(1),
					.BREG			(1),
					.CREG			(0),
					.MREG			(1),
					.PREG			(1),
					
					.USE_PCIN		(1),
					.USE_PCOUT		(0),
					
					.DEVICE			(DEVICE)
				)
			i_mul_add_dsp48_x
				(
					.reset			(reset),
					.clk			(clk),
					
					.cke_ctrl		(1'b0),
					.cke_alumode	(1'b0),
					.cke_a0			(1'b0),
					.cke_b0			(1'b0),
					.cke_a1			(stage_cke[2]),
					.cke_b1			(stage_cke[2]),
					.cke_c			(1'b0),
					.cke_m			(stage_cke[3]),
					.cke_p			(stage_cke[4]),
					
					.op_load		(1'b1),
					.alu_sub		(1'b0),
					
					.a				(st1_a_int),
					.b				(st1_x),
					.c				({INT_WIDTH{1'b0}}),
					.p				(st4_int),
					
					.pcin			(y_pcout),
					.pcout			()
				);
		
		jelly_mul_add_dsp48e1
				#(
					.A_WIDTH		(S_FLOAT_INT_WIDTH),
					.B_WIDTH		(S_FIXED_WIDTH),
					.C_WIDTH		(INT_WIDTH),
					.P_WIDTH		(INT_WIDTH),
					
					.OPMODEREG		(0),
					.ALUMODEREG		(0),
					.AREG			(1),
					.BREG			(1),
					.CREG			(1),
					.MREG			(1),
					.PREG			(1),
					
					.USE_PCIN		(0),
					.USE_PCOUT		(1),
					
					.DEVICE			(DEVICE)
				)
			i_mul_add_dsp48_y
				(
					.reset			(reset),
					.clk			(clk),
					
					.cke_ctrl		(1'b0),
					.cke_alumode	(1'b0),
					.cke_a0			(1'b0),
					.cke_b0			(1'b0),
					.cke_a1			(stage_cke[1]),
					.cke_b1			(stage_cke[1]),
					.cke_c			(stage_cke[2]),
					.cke_m			(stage_cke[2]),
					.cke_p			(stage_cke[3]),
					
					.op_load		(1'b1),
					.alu_sub		(1'b0),
					
					.a				(st0_b_int),
					.b				(st0_y),
					.c				(st1_c_int),
					.p				(),
					
					.pcin			(),
					.pcout			(y_pcout)
				);
	
	
	
endmodule



`default_nettype wire



// end of file
