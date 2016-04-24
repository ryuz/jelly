// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   reciprocal
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_float_reciprocal
		#(
			parameter	EXP_WIDTH   = 8,
			parameter	EXP_OFFSET  = (1 << (EXP_WIDTH-1)) - 1,
			parameter	FRAC_WIDTH  = 23,
			parameter	FLOAT_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH,
			
			parameter	D_WIDTH     = 6,
			parameter	K_WIDTH     = FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH  = FRAC_WIDTH,
			
			parameter	RAM_TYPE    = "distributed",
			parameter	MAKE_TABLE  = 1,
			parameter	FILE_NAME   = "float_reciprocal.hex"
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[FLOAT_WIDTH-1:0]	s_float,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[FLOAT_WIDTH-1:0]	m_float,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	localparam	PIPELINE_STAGES = 5;
	
	wire	[PIPELINE_STAGES-1:0]	stage_cke;
	wire	[PIPELINE_STAGES-1:0]	stage_valid;
	
	wire							src_sign;
	wire	[EXP_WIDTH-1:0]			src_exp;
	wire	[FRAC_WIDTH-1:0]		src_frac;
	
	wire							sink_sign;
	wire	[EXP_WIDTH-1:0]			sink_exp;
	wire	[FRAC_WIDTH-1:0]		sink_frac;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(PIPELINE_STAGES),
				.S_DATA_WIDTH		(FLOAT_WIDTH),
				.M_DATA_WIDTH		(FLOAT_WIDTH),
				.AUTO_VALID			(1)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				(s_float),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				(m_float),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			({PIPELINE_STAGES{1'bx}}),
				.src_data			({src_sign, src_exp, src_frac}),
				.src_valid			(),
				.sink_data			({sink_sign, sink_exp, sink_frac}),
				.buffered			()
			);
	
	wire	[FRAC_WIDTH-1:0]	st1_frac;
	wire	[FRAC_WIDTH-1:0]	st1_grad;
	
	generate
	if ( MAKE_TABLE ) begin
		jelly_float_reciprocal_table
				#(
					.FRAC_WIDTH		(FRAC_WIDTH),
					.D_WIDTH		(D_WIDTH),
					.K_WIDTH		(K_WIDTH),
					.GRAD_WIDTH		(GRAD_WIDTH),
					.OUT_REGS		(1),
					.RAM_TYPE		(RAM_TYPE),
					.FILE_NAME		(FILE_NAME)
				)
			i_float_reciprocal_table
				(
					.clk			(clk),
					
					.cke			(stage_cke[1:0]),
					
					.in_d			(src_frac[FRAC_WIDTH-1 -: D_WIDTH]),
					
					.out_frac		(st1_frac),
					.out_grad		(st1_grad)
				);
	end
	else if ( FRAC_WIDTH == 23 && D_WIDTH == 6 && GRAD_WIDTH == 23 ) begin
		jelly_float_reciprocal_frac23_d6
			i_float_reciprocal_frac23_d6
				(
					.clk			(clk),
					
					.cke			(stage_cke[1:0]),
					
					.in_d			(src_frac[FRAC_WIDTH-1 -: D_WIDTH]),
					
					.out_frac		(st1_frac),
					.out_grad		(st1_grad)
				);
	end
	else begin
		jelly_ram_singleport
				#(
					.ADDR_WIDTH		(D_WIDTH),
					.DATA_WIDTH		(FRAC_WIDTH + GRAD_WIDTH),
					.RAM_TYPE		(RAM_TYPE),
					.DOUT_REGS		(1),
					
					.READMEMH		(1),
					.READMEM_FILE	(FILE_NAME)
				)
			i_ram_singleport
				(
					.clk			(clk),
					.en				(stage_cke[0]),
					.regcke			(stage_cke[1]),
					.we				(1'b0),
					.addr			(src_frac[FRAC_WIDTH-1 -: D_WIDTH]),
					.din			({(FRAC_WIDTH + GRAD_WIDTH){1'b0}}),
					.dout			({st1_frac, st1_grad})
				);
	end
	endgenerate
	
	reg							st0_sign;
	reg		[EXP_WIDTH-1:0]		st0_exp;
	reg							st0_frac_one;
	reg		[K_WIDTH-1:0]		st0_k;
	
	reg							st1_sign;
	reg		[EXP_WIDTH-1:0]		st1_exp;
	reg							st1_frac_one;
	reg		[K_WIDTH-1:0]		st1_k;
	
	reg							st2_sign;
	reg		[EXP_WIDTH-1:0]		st2_exp;
	reg		[FRAC_WIDTH-1:0]	st2_frac;
	reg		[K_WIDTH-1:0]		st2_k;
	reg		[GRAD_WIDTH-1:0]	st2_grad;

	reg							st3_sign;
	reg		[EXP_WIDTH-1:0]		st3_exp;
	reg		[FRAC_WIDTH-1:0]	st3_frac;
	reg		[GRAD_WIDTH-1:0]	st3_diff;
	
	reg							st4_sign;
	reg		[EXP_WIDTH-1:0]		st4_exp;
	reg		[FRAC_WIDTH-1:0]	st4_frac;
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			st0_sign     <= src_sign;
			st0_exp      <= src_exp;
			st0_frac_one <= (src_frac == {FRAC_WIDTH{1'b0}});
			st0_k        <= src_frac[0 +: K_WIDTH];
		end
		
		if ( stage_cke[1] ) begin
			st1_sign     <= st0_sign;
			st1_exp      <= -(st0_exp - EXP_OFFSET) + st0_frac_one + EXP_OFFSET - 1;
			st1_frac_one <= st0_frac_one;
			st1_k        <= st0_k;
		end
		
		if ( stage_cke[2] ) begin
			st2_sign <= st1_sign;
			st2_exp  <= st1_exp;
			st2_frac <= st1_frac;
			st2_grad <= st1_grad;
			st2_k    <= st1_k;
		end
		
		if ( stage_cke[3] ) begin
			st3_sign <= st2_sign;
			st3_exp  <= st2_exp;
			st3_frac <= st2_frac;
			st3_diff <= (({{GRAD_WIDTH{1'b0}}, st2_grad} * {{K_WIDTH{1'b0}}, st2_k}) >> K_WIDTH);
		end
		
		if ( stage_cke[4] ) begin
			st4_sign <= st3_sign;
			st4_exp  <= st3_exp;
			st4_frac <= st3_frac - st3_diff;
		end
	end
	
	assign sink_sign = st4_sign;
	assign sink_exp  = st4_exp;
	assign sink_frac = st4_frac;
	
endmodule



`default_nettype wire



// end of file
