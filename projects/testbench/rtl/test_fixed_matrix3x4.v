// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// f <= a*x + b*x + c
// 
// a, b, c : floating point number
// x, y    : fixed point number
// f       : denormalized number
module test_fixed_matrix3x4
		#(
			parameter	COEFF_INT_WIDTH    = 17,
			parameter	COEFF_FRAC_WIDTH   = 8,
			parameter	COEFF_WIDTH        = COEFF_INT_WIDTH + COEFF_FRAC_WIDTH,
			
			parameter	S_FIXED_INT_WIDTH  = 17,
			parameter	S_FIXED_FRAC_WIDTH = 0,
			parameter	S_FIXED_WIDTH      = S_FIXED_INT_WIDTH + S_FIXED_FRAC_WIDTH,
			
			parameter	M_FIXED_INT_WIDTH  = 17,
			parameter	M_FIXED_FRAC_WIDTH = 8,
			parameter	M_FIXED_WIDTH      = M_FIXED_INT_WIDTH + M_FIXED_FRAC_WIDTH,
			
			parameter	USER_WIDTH         = 0,
			parameter	USER_BITS          = USER_WIDTH > 0 ? USER_WIDTH : 1,
			
			parameter	STATIC_COEFF       = 1,	// no dynamic change coeff
			
			parameter	MASTER_IN_REGS     = 0,
			parameter	MASTER_OUT_REGS    = 0,
			
			parameter	DEVICE             = "RTL" // "RTL" or "7SERIES"
		)
		(
			input	wire										reset,
			input	wire										clk,
			input	wire										cke,
			
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff00,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff01,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff02,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff03,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff10,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff11,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff12,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff13,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff20,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff21,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff22,
			input	wire	signed	[COEFF_WIDTH-1:0]			coeff23,
			
			input	wire			[USER_BITS-1:0]				s_user,
			input	wire	signed	[S_FIXED_WIDTH-1:0]			s_fixed_x,
			input	wire	signed	[S_FIXED_WIDTH-1:0]			s_fixed_y,
			input	wire	signed	[S_FIXED_WIDTH-1:0]			s_fixed_z,
			input	wire										s_valid,
//			output	wire										s_ready,
			
			output	wire			[USER_BITS-1:0]				m_user,
			output	wire	signed	[M_FIXED_WIDTH-1:0]			m_fixed_x,
			output	wire	signed	[M_FIXED_WIDTH-1:0]			m_fixed_y,
			output	wire	signed	[M_FIXED_WIDTH-1:0]			m_fixed_z,
			output	wire										m_valid
//			input	wire										m_ready
		);
	
	
	jelly_fixed_matrix3x4
			#(
				.COEFF_INT_WIDTH		(COEFF_INT_WIDTH),
				.COEFF_FRAC_WIDTH		(COEFF_FRAC_WIDTH),
				
				.S_FIXED_INT_WIDTH		(S_FIXED_INT_WIDTH),
				.S_FIXED_FRAC_WIDTH		(S_FIXED_FRAC_WIDTH),
				
				.M_FIXED_INT_WIDTH		(M_FIXED_INT_WIDTH),
				.M_FIXED_FRAC_WIDTH		(M_FIXED_FRAC_WIDTH),
				                         
				.USER_WIDTH				(USER_WIDTH),
				
				.STATIC_COEFF			(STATIC_COEFF),
				
				.MASTER_IN_REGS			(MASTER_IN_REGS),
				.MASTER_OUT_REGS		(MASTER_OUT_REGS),
				
				.DEVICE					(DEVICE)
			)
		i_fixed_matrix3x4
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.coeff00				(coeff00),
				.coeff01				(coeff01),
				.coeff02				(coeff02),
				.coeff03				(coeff03),
				.coeff10				(coeff10),
				.coeff11				(coeff11),
				.coeff12				(coeff12),
				.coeff13				(coeff13),
				.coeff20				(coeff20),
				.coeff21				(coeff21),
				.coeff22				(coeff22),
				.coeff23				(coeff23),
				
				.s_user					(s_user),
				.s_fixed_x				(s_fixed_x),
				.s_fixed_y				(s_fixed_y),
				.s_fixed_z				(s_fixed_z),
				.s_valid				(s_valid),
				.s_ready				(),
				
				.m_user					(m_user),
				.m_fixed_x				(m_fixed_x),
				.m_fixed_y				(m_fixed_y),
				.m_fixed_z				(m_fixed_z),
				.m_valid				(m_valid),
				.m_ready				(1)
			);
	
	
endmodule



`default_nettype wire



// end of file
