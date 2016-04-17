
`timescale 1ns / 1ps
`default_nettype none


module tb_float_reciprocal();
	localparam RATE    = 10.0;
	
	initial begin
		$dumpfile("tb_float_reciprocal.vcd");
		$dumpvars(0, tb_float_reciprocal);
		
		#100000;
			$finish;
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
	
	
	parameter	EXP_WIDTH   = 8;
	parameter	EXP_OFFSET  = (1 << (EXP_WIDTH-1)) - 1;
	parameter	FRAC_WIDTH  = 23;
	parameter	FLOAT_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH;
	
	
	function [FLOAT_WIDTH-1:0] real2float(input real r);
	reg		[63:0]	b;
	begin
		b                                    = $realtobits(r);
		real2float[FLOAT_WIDTH-1]            = b[63];
		real2float[FRAC_WIDTH +: EXP_WIDTH]  = (b[62:52] - 1023) + EXP_OFFSET;
		real2float[0          +: FRAC_WIDTH] = b[51 -: FRAC_WIDTH];
	end
	endfunction
	
	
	function real float2real(input [FLOAT_WIDTH-1:0] f);
	reg		[63:0]	b;
	begin
		b                   = 64'd0;
		b[63]               = f[FLOAT_WIDTH-1];
		b[62:52]            = (f[FRAC_WIDTH +: EXP_WIDTH] - EXP_OFFSET) + EXP_OFFSET;
		b[51 -: FRAC_WIDTH] = f[0 +: FRAC_WIDTH];
		float2real          = $bitstoreal(b);
	end
	endfunction
	
	
	real	r_in  = 0.5;
	real	r_out;
	real	r_exp;
	
	wire	[FLOAT_WIDTH-1:0]	out_float;
	
	always @(posedge clk) begin
		r_in  <= r_in + 0.0001;
		r_exp <= 1.0 / r_in;
		r_out <= float2real(out_float);
	end
	
	
	jelly_float_reciprocal
		i_float_reciprocal
			(
				.reset		(reset),
				.clk		(clk),
				.cke		(1'b1),
				
				.s_float	(real2float(r_in)),
				.s_valid	(1'b1),
				.s_ready	(),
				
				.m_float	(out_float),
				.m_valid	(),
				.m_ready	(1'b1)
			);
	
	
endmodule


`default_nettype wire


// end of file
