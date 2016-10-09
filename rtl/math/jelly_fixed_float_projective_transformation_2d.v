// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly_fixed_float_projective_transformation_2d
		#(
			parameter	FLOAT_EXP_WIDTH        = 8,
			parameter	FLOAT_EXP_OFFSET       = (1 << (FLOAT_EXP_WIDTH-1)) - 1,
			parameter	FLOAT_FRAC_WIDTH       = 23,
			parameter	FLOAT_WIDTH            = 1 + FLOAT_EXP_WIDTH + FLOAT_FRAC_WIDTH,	// sign + exp + frac
			
			parameter	S_FIXED_INT_WIDTH      = 16,
			parameter	S_FIXED_FRAC_WIDTH     = 0,
			parameter	S_FIXED_WIDTH          = S_FIXED_INT_WIDTH + S_FIXED_FRAC_WIDTH,
			
			parameter	M_FIXED_INT_WIDTH      = 25,
			parameter	M_FIXED_FRAC_WIDTH     = 8,
			parameter	M_FIXED_WIDTH          = M_FIXED_INT_WIDTH + M_FIXED_FRAC_WIDTH,
			
			parameter	USER_WIDTH             = 0,
			parameter	USER_BITS              = USER_WIDTH > 0 ? USER_WIDTH : 1,
			
			parameter	MUL_DENORM_EXP_WIDTH   = FLOAT_EXP_WIDTH,
			parameter	MUL_DENORM_EXP_OFFSET  = FLOAT_EXP_OFFSET,
			parameter	MUL_DENORM_INT_WIDTH   = 16,
			parameter	MUL_DENORM_FRAC_WIDTH  = 16,
			
			parameter	RECIP_FLOAT_EXP_WIDTH  = FLOAT_EXP_WIDTH,
			parameter	RECIP_FLOAT_EXP_OFFSET = FLOAT_EXP_OFFSET,
			parameter	RECIP_FLOAT_FRAC_WIDTH = 16,
			parameter	RECIP_D_WIDTH          = 6,
			parameter	RECIP_K_WIDTH          = RECIP_FLOAT_FRAC_WIDTH - RECIP_D_WIDTH,
			parameter	RECIP_GRAD_WIDTH       = RECIP_FLOAT_FRAC_WIDTH,
			parameter	RECIP_RAM_TYPE         = "distributed",
			
			parameter	MASTER_IN_REGS         = 1,
			parameter	MASTER_OUT_REGS        = 1,
			
			parameter	DEVICE                 = "RTL"
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire			[FLOAT_WIDTH-1:0]	matrix00,
			input	wire			[FLOAT_WIDTH-1:0]	matrix01,
			input	wire			[FLOAT_WIDTH-1:0]	matrix02,
			input	wire			[FLOAT_WIDTH-1:0]	matrix10,
			input	wire			[FLOAT_WIDTH-1:0]	matrix11,
			input	wire			[FLOAT_WIDTH-1:0]	matrix12,
			input	wire			[FLOAT_WIDTH-1:0]	matrix20,
			input	wire			[FLOAT_WIDTH-1:0]	matrix21,
			input	wire			[FLOAT_WIDTH-1:0]	matrix22,
			
			input	wire			[USER_BITS-1:0]		s_user,
			input	wire	signed	[S_FIXED_WIDTH-1:0]	s_x,
			input	wire	signed	[S_FIXED_WIDTH-1:0]	s_y,
			input	wire								s_valid,
			output	wire								s_ready,
			
			output	wire			[USER_BITS-1:0]		m_user,
			output	wire			[M_FIXED_WIDTH-1:0]	m_x,
			output	wire			[M_FIXED_WIDTH-1:0]	m_y,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
	
	
	
	// -----------------------------------------
	//  multiply
	// -----------------------------------------
	
	localparam	MUL_DENORM_FIXED_WIDTH = MUL_DENORM_INT_WIDTH + MUL_DENORM_FRAC_WIDTH;
	
	
	wire			[MUL_DENORM_EXP_WIDTH-1:0]		mul_denorm_x_exp;
	wire	signed	[MUL_DENORM_FIXED_WIDTH-1:0]	mul_denorm_x_fixed;
	
	wire			[MUL_DENORM_EXP_WIDTH-1:0]		mul_denorm_y_exp;
	wire	signed	[MUL_DENORM_FIXED_WIDTH-1:0]	mul_denorm_y_fixed;
	
	wire			[MUL_DENORM_EXP_WIDTH-1:0]		mul_denorm_w_exp;
	wire	signed	[MUL_DENORM_FIXED_WIDTH-1:0]	mul_denorm_w_fixed;
	
	wire			[USER_BITS-1:0]					mul_user;
	wire											mul_valid;
	wire											mul_ready;
	
	jelly_fixed_float_mul_add2
			#(
				.S_FIXED_INT_WIDTH		(S_FIXED_INT_WIDTH),
				.S_FIXED_FRAC_WIDTH		(S_FIXED_FRAC_WIDTH),
				
				.S_FLOAT_EXP_WIDTH		(FLOAT_EXP_WIDTH),
				.S_FLOAT_EXP_OFFSET		(FLOAT_EXP_OFFSET),
				.S_FLOAT_FRAC_WIDTH		(FLOAT_FRAC_WIDTH),
				
				.M_DENORM_EXP_WIDTH		(MUL_DENORM_EXP_WIDTH),
				.M_DENORM_EXP_OFFSET	(MUL_DENORM_EXP_OFFSET),
				.M_DENORM_INT_WIDTH		(MUL_DENORM_INT_WIDTH),
				.M_DENORM_FRAC_WIDTH	(MUL_DENORM_FRAC_WIDTH),
				
				.USER_WIDTH				(USER_WIDTH),
				
				.MASTER_IN_REGS			(0),
				.MASTER_OUT_REGS		(0),
				
				.DEVICE					(DEVICE)
			)
		i_fixed_float_mul_add2_x
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_user					(s_user),
				.s_fixed_x				(s_x),
				.s_fixed_y				(s_y),
				.s_float_a				(matrix00),
				.s_float_b				(matrix01),
				.s_float_c				(matrix02),
				.s_valid				(s_valid),
				.s_ready				(s_ready),
				
				.m_user					(mul_user),
				.m_denorm_exp			(mul_denorm_x_exp),
				.m_denorm_fixed			(mul_denorm_x_fixed),
				.m_valid				(mul_valid),
				.m_ready				(mul_ready)
			);
	
	
	jelly_fixed_float_mul_add2
			#(
				.S_FIXED_INT_WIDTH		(S_FIXED_INT_WIDTH),
				.S_FIXED_FRAC_WIDTH		(S_FIXED_FRAC_WIDTH),
				
				.S_FLOAT_EXP_WIDTH		(FLOAT_EXP_WIDTH),
				.S_FLOAT_EXP_OFFSET		(FLOAT_EXP_OFFSET),
				.S_FLOAT_FRAC_WIDTH		(FLOAT_FRAC_WIDTH),
				
				.M_DENORM_EXP_WIDTH		(MUL_DENORM_EXP_WIDTH),
				.M_DENORM_EXP_OFFSET	(MUL_DENORM_EXP_OFFSET),
				.M_DENORM_INT_WIDTH		(MUL_DENORM_INT_WIDTH),
				.M_DENORM_FRAC_WIDTH	(MUL_DENORM_FRAC_WIDTH),
				
				.USER_WIDTH				(0),
				
				.MASTER_IN_REGS			(0),
				.MASTER_OUT_REGS		(0),
				
				.DEVICE					(DEVICE)
			)
		i_fixed_float_mul_add2_y
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_user					(),
				.s_fixed_x				(s_x),
				.s_fixed_y				(s_y),
				.s_float_a				(matrix10),
				.s_float_b				(matrix11),
				.s_float_c				(matrix12),
				.s_valid				(s_valid),
				.s_ready				(),
				
				.m_user					(),
				.m_denorm_exp			(mul_denorm_y_exp),
				.m_denorm_fixed			(mul_denorm_y_fixed),
				.m_valid				(),
				.m_ready				(mul_ready)
			);
	
	
	jelly_fixed_float_mul_add2
			#(
				.S_FIXED_INT_WIDTH		(S_FIXED_INT_WIDTH),
				.S_FIXED_FRAC_WIDTH		(S_FIXED_FRAC_WIDTH),
				
				.S_FLOAT_EXP_WIDTH		(FLOAT_EXP_WIDTH),
				.S_FLOAT_EXP_OFFSET		(FLOAT_EXP_OFFSET),
				.S_FLOAT_FRAC_WIDTH		(FLOAT_FRAC_WIDTH),
				
				.M_DENORM_EXP_WIDTH		(MUL_DENORM_EXP_WIDTH),
				.M_DENORM_EXP_OFFSET	(MUL_DENORM_EXP_OFFSET),
				.M_DENORM_INT_WIDTH		(MUL_DENORM_INT_WIDTH),
				.M_DENORM_FRAC_WIDTH	(MUL_DENORM_FRAC_WIDTH),
				
				.USER_WIDTH				(0),
				
				.MASTER_IN_REGS			(0),
				.MASTER_OUT_REGS		(0),
				
				.DEVICE					(DEVICE)
			)
		i_fixed_float_mul_add2_w
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_user					(),
				.s_fixed_x				(s_x),
				.s_fixed_y				(s_y),
				.s_float_a				(matrix20),
				.s_float_b				(matrix21),
				.s_float_c				(matrix22),
				.s_valid				(s_valid),
				.s_ready				(),
				
				.m_user					(),
				.m_denorm_exp			(mul_denorm_w_exp),
				.m_denorm_fixed			(mul_denorm_w_fixed),
				.m_valid				(),
				.m_ready				(mul_ready)
			);
	
	
	
	// -----------------------------------------
	//  recip
	// -----------------------------------------
	
	localparam	RECIP_FLOAT_WIDTH = 1 + RECIP_FLOAT_EXP_WIDTH + RECIP_FLOAT_FRAC_WIDTH;
	
	wire			[MUL_DENORM_EXP_WIDTH-1:0]		recip_denorm_x_exp;
	wire	signed	[MUL_DENORM_FIXED_WIDTH-1:0]	recip_denorm_x_fixed;
	
	wire			[MUL_DENORM_EXP_WIDTH-1:0]		recip_denorm_y_exp;
	wire	signed	[MUL_DENORM_FIXED_WIDTH-1:0]	recip_denorm_y_fixed;
	
	wire			[RECIP_FLOAT_WIDTH-1:0]			recip_float_w;
	
	wire			[USER_BITS-1:0]					recip_user;
	wire											recip_valid;
	wire											recip_ready;
	
	jelly_denorm_reciprocal_float
			#(
				.DENORM_SIGNED			(1),
				.DENORM_INT_WIDTH		(MUL_DENORM_INT_WIDTH),
				.DENORM_FRAC_WIDTH		(MUL_DENORM_FRAC_WIDTH),
				.DENORM_EXP_WIDTH		(MUL_DENORM_EXP_WIDTH),
				.DENORM_EXP_OFFSET		(MUL_DENORM_EXP_OFFSET),
				
				.FLOAT_EXP_WIDTH		(RECIP_FLOAT_EXP_WIDTH),
				.FLOAT_EXP_OFFSET		(RECIP_FLOAT_EXP_OFFSET),
				.FLOAT_FRAC_WIDTH		(RECIP_FLOAT_FRAC_WIDTH),
				
				.USER_WIDTH				(USER_BITS + 2*(MUL_DENORM_EXP_WIDTH+MUL_DENORM_FIXED_WIDTH)),
				
				.D_WIDTH				(RECIP_D_WIDTH),
				.K_WIDTH				(RECIP_K_WIDTH),
				.GRAD_WIDTH				(RECIP_GRAD_WIDTH),
				
				.RAM_TYPE				(RECIP_RAM_TYPE),
				
				.MASTER_IN_REGS			(0),
				.MASTER_OUT_REGS		(0)
			)
		i_denorm_reciprocal_float
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				                         
				.s_user					({mul_user, mul_denorm_y_exp, mul_denorm_y_fixed, mul_denorm_x_exp, mul_denorm_x_fixed}),
				.s_denorm_fixed			(mul_denorm_w_fixed),
				.s_denorm_exp			(mul_denorm_w_exp),
				.s_valid				(mul_valid),
				.s_ready				(mul_ready),
				                         
				.m_user					({recip_user, recip_denorm_y_exp, recip_denorm_y_fixed, recip_denorm_x_exp, recip_denorm_x_fixed}),
				.m_float				(recip_float_w),
				.m_valid				(recip_valid),
				.m_ready				(recip_ready)
			);
	
	
	
	
	
	
	
	
	
	/*
	
	
	wire	[USER_BITS-1:0]		mul_user;
	wire	[FLOAT_WIDTH-1:0]	mul_float00;
	wire	[FLOAT_WIDTH-1:0]	mul_float01;
	wire	[FLOAT_WIDTH-1:0]	mul_float10;
	wire	[FLOAT_WIDTH-1:0]	mul_float11;
	wire	[FLOAT_WIDTH-1:0]	mul_float20;
	wire	[FLOAT_WIDTH-1:0]	mul_float21;
	wire						mul_valid;
	wire						mul_ready;
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(USER_BITS)
			)
		i_float_multiply_00
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(s_user),
				.s_float0		(s_x),
				.s_float1		(matrix00),
				.s_valid		(s_valid),
				.s_ready		(s_ready),
				
				.m_user			(mul_user),
				.m_float		(mul_float00),
				.m_valid		(mul_valid),
				.m_ready		(mul_ready)
			);
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_multiply_01
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(s_y),
				.s_float1		(matrix01),
				.s_valid		(s_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(mul_float01),
				.m_valid		(),
				.m_ready		(mul_ready)
			);
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_multiply_10
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(s_x),
				.s_float1		(matrix10),
				.s_valid		(s_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(mul_float10),
				.m_valid		(),
				.m_ready		(mul_ready)
			);
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_multiply_11
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(s_y),
				.s_float1		(matrix11),
				.s_valid		(s_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(mul_float11),
				.m_valid		(),
				.m_ready		(mul_ready)
			);
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_multiply_20
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(s_x),
				.s_float1		(matrix20),
				.s_valid		(s_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(mul_float20),
				.m_valid		(),
				.m_ready		(mul_ready)
			);
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_multiply_21
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(s_y),
				.s_float1		(matrix21),
				.s_valid		(s_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(mul_float21),
				.m_valid		(),
				.m_ready		(mul_ready)
			);
	
	
	// -----------------------------------------
	//  add0
	// -----------------------------------------
	
	wire	[USER_BITS-1:0]		add0_user;
	wire	[FLOAT_WIDTH-1:0]	add0_float0;
	wire	[FLOAT_WIDTH-1:0]	add0_float1;
	wire	[FLOAT_WIDTH-1:0]	add0_float2;
	wire						add0_valid;
	wire						add0_ready;
	
	jelly_float_add
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(USER_BITS)
			)
		i_float_add0_0
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(mul_user),
				.s_float0		(mul_float00),
				.s_float1		(mul_float01),
				.s_valid		(mul_valid),
				.s_ready		(mul_ready),
				
				.m_user			(add0_user),
				.m_float		(add0_float0),
				.m_valid		(add0_valid),
				.m_ready		(add0_ready)
			);
	
	jelly_float_add
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_add0_1
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(mul_float10),
				.s_float1		(mul_float11),
				.s_valid		(mul_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(add0_float1),
				.m_valid		(),
				.m_ready		(add0_ready)
			);
	
	jelly_float_add
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_add0_2
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(mul_float20),
				.s_float1		(mul_float21),
				.s_valid		(mul_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(add0_float2),
				.m_valid		(),
				.m_ready		(add0_ready)
			);
	
	
	// -----------------------------------------
	//  add1
	// -----------------------------------------
	
	wire	[USER_BITS-1:0]		add1_user;
	wire	[FLOAT_WIDTH-1:0]	add1_float0;
	wire	[FLOAT_WIDTH-1:0]	add1_float1;
	wire	[FLOAT_WIDTH-1:0]	add1_float2;
	wire						add1_valid;
	wire						add1_ready;
	
	jelly_float_add
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(USER_BITS)
			)
		i_float_add1_0
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(add0_user),
				.s_float0		(add0_float0),
				.s_float1		(matrix02),
				.s_valid		(add0_valid),
				.s_ready		(add0_ready),
				
				.m_user			(add1_user),
				.m_float		(add1_float0),
				.m_valid		(add1_valid),
				.m_ready		(add1_ready)
			);
	
	jelly_float_add
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_add1_1
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(add0_float1),
				.s_float1		(matrix12),
				.s_valid		(add0_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(add1_float1),
				.m_valid		(),
				.m_ready		(add1_ready)
			);
	
	jelly_float_add
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_add1_2
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(add0_float2),
				.s_float1		(matrix22),
				.s_valid		(add0_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(add1_float2),
				.m_valid		(),
				.m_ready		(add1_ready)
			);
	
	
	// -----------------------------------------
	//  div
	// -----------------------------------------
	
	wire	[USER_BITS-1:0]		recip_user;
	wire	[FLOAT_WIDTH-1:0]	recip_float0;
	wire	[FLOAT_WIDTH-1:0]	recip_float1;
	wire	[FLOAT_WIDTH-1:0]	recip_float2;
	wire						recip_valid;
	wire						recip_ready;
	
	jelly_float_reciprocal
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(USER_BITS+FLOAT_WIDTH+FLOAT_WIDTH),
				.D_WIDTH		(9)
			)
		i_float_reciprocal
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			({add1_user, add1_float1, add1_float0}),
				.s_float		(add1_float2),
				.s_valid		(add1_valid),
				.s_ready		(add1_ready),
				
				.m_user			({recip_user, recip_float1, recip_float0}),
				.m_float		(recip_float2),
				.m_valid		(recip_valid),
				.m_ready		(recip_ready)
			);
	
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(USER_BITS)
			)
		i_float_multiply_div0
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(recip_user),
				.s_float0		(recip_float0),
				.s_float1		(recip_float2),
				.s_valid		(recip_valid),
				.s_ready		(recip_ready),
				
				.m_user			(m_user),
				.m_float		(m_x),
				.m_valid		(m_valid),
				.m_ready		(m_ready)
			);
	
	jelly_float_multiply
			#(
				.EXP_WIDTH		(EXP_WIDTH),
				.FRAC_WIDTH		(FRAC_WIDTH),
				.USER_WIDTH		(0)
			)
		i_float_multiply_div1
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.s_user			(),
				.s_float0		(recip_float1),
				.s_float1		(recip_float2),
				.s_valid		(recip_valid),
				.s_ready		(),
				
				.m_user			(),
				.m_float		(m_y),
				.m_valid		(),
				.m_ready		(m_ready)
			);
	*/
	
endmodule


`default_nettype wire


// end of file
