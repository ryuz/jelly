
`timescale 1ns / 1ps
`default_nettype none


module tb_float_reciprocal();
	localparam RATE    = 10.0;
	
	initial begin
		$dumpfile("tb_float_reciprocal.vcd");
		$dumpvars(0, tb_float_reciprocal);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	
	
	
	parameter	EXP_WIDTH   = 8;
	parameter	EXP_OFFSET  = (1 << (EXP_WIDTH-1)) - 1;
	parameter	FRAC_WIDTH  = 23;
	parameter	FLOAT_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH;
	
	parameter	D_WIDTH     = 6;
	parameter	K_WIDTH     = FRAC_WIDTH - D_WIDTH;
	parameter	GRAD_WIDTH  = FRAC_WIDTH;
	
	
	
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
		b[62:52]            = (f[FRAC_WIDTH +: EXP_WIDTH] - EXP_OFFSET) + 1023;
		b[51 -: FRAC_WIDTH] = f[0 +: FRAC_WIDTH];
		float2real          = $bitstoreal(b);
	end
	endfunction
	
	function real isnan_float(input [FLOAT_WIDTH-1:0] f);
	begin
		isnan_float = ((f[FRAC_WIDTH +: EXP_WIDTH] == {EXP_WIDTH{1'b0}}) || (f[FRAC_WIDTH +: EXP_WIDTH] == {EXP_WIDTH{1'b1}}));
	end
	endfunction
	
	
	
	reg		[FLOAT_WIDTH-1:0]	float_src = 32'h0080_0000; // {FLOAT_WIDTH{1'b0}};
	real						real_src;
	
	reg		[FLOAT_WIDTH-1:0]	in_float;
	reg		[63:0]				in_double;
	reg							in_valid = 1'b0;
	
	wire	[FLOAT_WIDTH-1:0]	out_float;
	wire	[63:0]				out_double;
	wire						out_valid;
	
	always @(posedge clk) begin
		if ( !reset ) begin
//			float_src = {$random};
			real_src  = float2real(float_src);
			
			in_float  <= float_src;
			in_double <= $realtobits(real_src);
			in_valid  <= !isnan_float(float_src);
			
			float_src = float_src + 32'h01;
		end
	end
	
	
	jelly_float_reciprocal
			#(
				.EXP_WIDTH	(EXP_WIDTH),
				.EXP_OFFSET	(EXP_OFFSET),
				.FRAC_WIDTH	(FRAC_WIDTH),
				.FLOAT_WIDTH(FLOAT_WIDTH),
				
				.D_WIDTH	(D_WIDTH),
				.K_WIDTH	(K_WIDTH),
				.GRAD_WIDTH	(GRAD_WIDTH),
				
				.MAKE_TABLE	(1)
			)
		i_float_reciprocal
			(
				.reset		(reset),
				.clk		(clk),
				.cke		(1'b1),
				
				.s_float	(in_float),
				.s_valid	(in_valid),
				.s_ready	(),
				
				.m_float	(out_float),
				.m_valid	(out_valid),
				.m_ready	(1'b1)
			);
	
	jelly_data_delay
			#(
				.LATENCY	(6),
				.DATA_WIDTH	(64)
			)
		i_data_delay_exp
			(
				.reset		(reset),
				.clk		(clk),
				.cke		(1'b1),
				
				.in_data	(in_double),
				
				.out_data	(out_double)
			);
	
	
	real	exp;
	real	result;
	real	error;
	real	error_max = 0;
	reg		error_update = 0;
	
	always @(posedge clk) begin
		if ( !reset && out_valid && !isnan_float(out_float) ) begin
			exp    = 1.0/$bitstoreal(out_double);
			result = float2real(out_float);
			error  = (result - exp) / exp;
			if ( error < 0 ) begin error = -error; end
			
//			$display("%g %g %g", result, exp, error);
			
			error_update <= 1'b0;
			if ( error > error_max ) begin
				error_update <= 1'b1;
				error_max = error;
				$display("%g %g %g", result, exp, error);
				$display("error_max: %g %h (%t)", error_max, out_float, $time);
			end
			
		end
	end
	
	initial begin
		while (1) begin
			#100000;
			$display("error_max: %g %h", error_max, in_float);
		end
//		$finish;
	end
	
endmodule


`default_nettype wire


// end of file
