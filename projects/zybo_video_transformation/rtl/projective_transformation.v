

`timescale 1ns / 1ps
`default_nettype none


module projective_transformation
		#(
			parameter	EXP_WIDTH   = 8,
			parameter	FRAC_WIDTH  = 23,
			parameter	FLOAT_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH,	// sign + exp + frac
			
			parameter	S_X_WIDTH   = 10,
			parameter	S_Y_WIDTH   = 10,
			parameter	M_X_WIDTH   = 10,
			parameter	M_Y_WIDTH   = 10,
			parameter	M_X_NUM     = 640,
			parameter	M_Y_NUM     = 480,
			
			parameter	USER_WIDTH  = 0,
			parameter	USER_BITS   = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[FLOAT_WIDTH-1:0]	matrix00,
			input	wire	[FLOAT_WIDTH-1:0]	matrix01,
			input	wire	[FLOAT_WIDTH-1:0]	matrix02,
			input	wire	[FLOAT_WIDTH-1:0]	matrix10,
			input	wire	[FLOAT_WIDTH-1:0]	matrix11,
			input	wire	[FLOAT_WIDTH-1:0]	matrix12,
			input	wire	[FLOAT_WIDTH-1:0]	matrix20,
			input	wire	[FLOAT_WIDTH-1:0]	matrix21,
			input	wire	[FLOAT_WIDTH-1:0]	matrix22,
			
			input	wire	[USER_BITS-1:0]		s_user,
			input	wire	[S_X_WIDTH-1:0]		s_x,
			input	wire	[S_Y_WIDTH-1:0]		s_y,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[USER_BITS-1:0]		m_user,
			output	wire						m_range_out,
			output	wire	[M_X_WIDTH-1:0]		m_x,
			output	wire	[M_Y_WIDTH-1:0]		m_y,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	
	

endmodule


`default_nettype wire


// end of file
