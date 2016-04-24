// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   reciprocal
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 
module jelly_float_reciprocal
		#(
			parameter	EXP_WIDTH   = 8,
			parameter	EXP_OFFSET  = (1 << (EXP_WIDTH-1)) - 1,
			parameter	FRAC_WIDTH  = 23,
			parameter	FLOAT_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH,
			
			parameter	D_WIDTH    = 8,
			parameter	K_WIDTH    = FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH = FRAC_WIDTH
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
	
	jelly_float_reciprocal_table
			#(
				.FRAC_WIDTH		(FRAC_WIDTH),
				.D_WIDTH		(D_WIDTH),
				.K_WIDTH		(K_WIDTH),
				.GRAD_WIDTH		(GRAD_WIDTH),
				.OUT_REGS		(1)
			)
		i_float_reciprocal_table
			(
				.clk			(clk),
				
				.cke			(stage_cke[1:0]),
				
				.in_d			(src_frac[FRAC_WIDTH-1 -: D_WIDTH]),
				
				.out_frac		(st1_frac),
				.out_grad		(st1_grad)
			);
	
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



module jelly_float_reciprocal_table
		#(
			parameter	FRAC_WIDTH = 23,
			parameter	D_WIDTH    = 8,
			parameter	K_WIDTH    = FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH = FRAC_WIDTH,
			parameter	OUT_REGS   = 1
		)
		(
			input							reset,
			input							clk,
			input		[1:0]				cke,
			
			input		[D_WIDTH-1:0]		in_d,
			
			input		[FRAC_WIDTH-1:0]	out_frac,
			input		[GRAD_WIDTH-1:0]	out_grad
		);
	
	
	// Realから仮数部取り出し
	function [FRAC_WIDTH:0] get_frac(input real r);
	reg		[63:0]	b;
	reg		[52:0]	f;
	begin
		b        = $realtobits(r);
		f        = {1'b0, b[51:0]};
		f        = f + (52'h8_0000_0000_0000 >> FRAC_WIDTH);	// 四捨五入
		get_frac = f[52 -: (FRAC_WIDTH+1)];
	end
	endfunction
	
	// 指数部/仮数部から Real 生成
	function real make_real(input [10:0] e, input [FRAC_WIDTH-1:0] f);
	reg		[63:0]	b;
	integer			i;
	begin
		b                   = 64'd0;
		b[52 +: 11]         = e + 11'd1023;
		b[51 -: FRAC_WIDTH] = f;
		make_real           = $bitstoreal(b);
	end
	endfunction
	

	task print_real(input real r);
	reg		[63:0]	b;
	begin
		b = $realtobits(r);
		$display("%b_%b_%b", b[63], b[62:52], b[51:0]); 
	end
	endtask
	
	
	// テーブル定義
	localparam	TBL_WIDTH = FRAC_WIDTH + GRAD_WIDTH;
	localparam	TBL_SIZE  = (1 << D_WIDTH);
	
	reg		[TBL_WIDTH-1:0]		mem[0:TBL_SIZE-1];
	
	
	
	// テーブル初期化
	integer	i;
	real						step;
	real						base, base_recip;
	real						next, next_recip;
	reg		[FRAC_WIDTH:0]		base_frac;
	reg		[FRAC_WIDTH:0]		next_frac;
	reg		[FRAC_WIDTH-1:0]	grad;
	reg		[FRAC_WIDTH-1:0]	grad_max;
	
	initial begin
		step = make_real(-D_WIDTH, 0);
		
		base       = make_real(0, 0);
		base_recip = 1.0 / base;
		base_frac  = (1 << FRAC_WIDTH);	// 最初だけ桁上げなので対策
		
//		$display("base"); print_real(base);
//		$display("step"); print_real(step);
		
		grad_max = 0;
		for ( i = 0; i < TBL_SIZE; i = i+1 ) begin
			next       = base + step;
			next_recip = 1.0 / next;
			next_frac  = get_frac(next_recip);
			
			grad       = base_frac - next_frac;
			if ( grad > grad_max ) grad_max = grad;
			
			mem[i][GRAD_WIDTH +: FRAC_WIDTH] = base_frac[0 +: FRAC_WIDTH];
			mem[i][0          +: GRAD_WIDTH] = grad[0 +: GRAD_WIDTH];
			
//			$display("<%d:%d>", i, grad);
//			$display("base:%h", base_frac);		print_real(base);	print_real(base_recip);
//			$display("next:%h", next_frac);		print_real(next);	print_real(next_recip);
			
			base       = next;
			base_recip = next_recip;
			base_frac  = next_frac;
		end
//		$display("grad_max:%h", grad_max);
	end
	
	reg		[TBL_WIDTH-1:0]		tbl_out;
	always @(posedge clk) begin
		if ( cke[0] ) begin
			tbl_out <= mem[in_d];
		end
	end
	
	reg		[TBL_WIDTH-1:0]		tbl_reg;
	always @(posedge clk) begin
		if ( cke[1] ) begin
			tbl_reg <= tbl_out;
		end
	end
	
	
	generate
	if ( OUT_REGS ) begin
		assign out_frac = tbl_reg[GRAD_WIDTH +: FRAC_WIDTH];
		assign out_grad = tbl_reg[0          +: GRAD_WIDTH];
	end
	else begin
		assign out_frac = tbl_out[GRAD_WIDTH +: FRAC_WIDTH];
		assign out_grad = tbl_out[0          +: GRAD_WIDTH];
	end
	endgenerate
	
	
endmodule



`default_nettype wire


// end of file
