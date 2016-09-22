// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


//
module jelly_mul_add_dsp48
		#(
			parameter	A_WIDTH = 25,
			parameter	B_WIDTH = 18,
			parameter	C_WIDTH = 48,
			parameter	P_WIDTH = 48,
			parameter	M_WIDTH = A_WIDTH + B_WIDTH,
			
			parameter	AREG   = 2,
			parameter	BREG   = 2,
			parameter	CREG   = 1,
			parameter	MREG   = 1,
			parameter	PREG   = 1,
			parameter	DEVICE = "RTL" // "7SERIES"
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							cke_a0,
			input	wire							cke_a1,
			input	wire							cke_b0,
			input	wire							cke_b1,
			input	wire							cke_c,
			input	wire							cke_m,
			input	wire							cke_p,
			
			input	wire	signed	[A_WIDTH-1:0]	in_a,
			input	wire	signed	[B_WIDTH-1:0]	in_b,
			input	wire	signed	[C_WIDTH-1:0]	in_c,
			output	wire	signed	[P_WIDTH-1:0]	out_p
		);
	
	generate
	if ( DEVICE == "VIRTEX6" || DEVICE == "SPARTAN6" || DEVICE == "7SERIES" ) begin : blk_dsp48e1
		wire	signed	[24:0]		a;
		wire	signed	[17:0]		b;
		wire	signed	[47:0]		c;
		wire	signed	[47:0]		p;
		
		assign a     = in_a;
		assign b     = in_b;
		assign c     = in_c;
		assign out_p = p;
		
		DSP48E1
				#(
					.A_INPUT			("DIRECT"),
					.B_INPUT			("DIRECT"),
					.USE_DPORT			("FALSE"),
					.USE_MULT			("MULTIPLY"),
					.USE_SIMD			("ONE48"),
					
					.AUTORESET_PATDET	("NO_RESET"),
					.MASK				(48'h3fffffffffff),
					.PATTERN			(48'h000000000000),
					.SEL_MASK			("MASK"),
					.SEL_PATTERN		("PATTERN"),
					.USE_PATTERN_DETECT	("NO_PATDET"),
					
					.ACASCREG			(AREG),
					.ADREG				(0),
					.ALUMODEREG			(0),
					.AREG				(AREG),
					.BCASCREG			(BREG),
					.BREG				(BREG),
					.CARRYINREG			(1),
					.CARRYINSELREG		(1),
					.CREG				(CREG),
					.DREG				(0),
					.INMODEREG			(0),
					.MREG				(MREG),
					.OPMODEREG			(0),
					.PREG				(PREG)
				)
			i_dsp48e1
				(
					.ACOUT				(),
					.BCOUT				(),
					.CARRYCASCOUT		(),
					.MULTSIGNOUT		(),
					.PCOUT				(),
					
					.OVERFLOW			(),
					.PATTERNBDETECT		(),
					.PATTERNDETECT		(),
					.UNDERFLOW			(),
					
					.CARRYOUT			(),
					.P					(p),
					
					.ACIN				(),
					.BCIN				(),
					.CARRYCASCIN		(),
					.MULTSIGNIN			(),
					.PCIN				(),
					
					.ALUMODE			(4'b0000),
					.CARRYINSEL			(3'b000),
					.CLK				(clk),
					.INMODE				(5'b00100),
					.OPMODE				(7'b0110101),
					
					.A					({5'b11111, a}),
					.B					(b),
					.C					(c),
					.CARRYIN			(1'b0),
					.D					(25'd0),
					
					.CEA1				(cke_a0),
					.CEA2				(cke_a1),
					.CEAD				(1'b0),
					.CEALUMODE			(1'b0),
					.CEB1				(cke_b0),
					.CEB2				(cke_b1),
					.CEC				(cke_c),
					.CECARRYIN			(1'b0),
					.CECTRL				(1'b0),
					.CED				(1'b0),
					.CEINMODE			(1'b0),
					.CEM				(cke_m),
					.CEP				(cke_p),
					
					.RSTA				(reset),
					.RSTALLCARRYIN		(reset),
					.RSTALUMODE			(reset),
					.RSTB				(reset),
					.RSTC				(reset),
					.RSTCTRL			(reset),
					.RSTD				(reset),
					.RSTINMODE			(reset),
					.RSTM				(reset),
					.RSTP				(reset)
				);
	end
	else begin : blk_rtl
		// a0
		wire	signed	[A_WIDTH-1:0]	a0;
		if ( AREG >= 1 ) begin
			reg		signed	[A_WIDTH-1:0]	reg_a0;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_a0 <= {A_WIDTH{1'b0}};
				end
				else if ( cke_a0 ) begin
					reg_a0 <= in_a;
				end
			end
			assign a0 = reg_a0;
		end
		else begin
			assign a0 = in_a;
		end
		
		// a1
		wire	signed	[A_WIDTH-1:0]	a1;
		if ( AREG >= 2 ) begin
			reg		signed	[A_WIDTH-1:0]	reg_a1;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_a1 <= {A_WIDTH{1'b0}};
				end
				else if ( cke_a1 ) begin
					reg_a1 <= a0;
				end
			end
			assign a1 = reg_a1;
		end
		else begin
			assign a1 = a0;
		end
		
		
		// b0
		wire	signed	[B_WIDTH-1:0]	b0;
		if ( BREG >= 1 ) begin
			reg		signed	[B_WIDTH-1:0]	reg_b0;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_b0 <= {B_WIDTH{1'b0}};
				end
				else if ( cke_b0 ) begin
					reg_b0 <= in_b;
				end
			end
			assign b0 = reg_b0;
		end
		else begin
			assign b0 = in_b;
		end
		
		// b1
		wire	signed	[B_WIDTH-1:0]	b1;
		if ( BREG >= 2 ) begin
			reg		signed	[B_WIDTH-1:0]	reg_b1;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_b1 <= {B_WIDTH{1'b0}};
				end
				else if ( cke_b1 ) begin
					reg_b1 <= b0;
				end
			end
			assign b1 = reg_b1;
		end
		else begin
			assign b1 = b0;
		end
		
		
		// c
		wire	signed	[C_WIDTH-1:0]	c;
		if ( CREG >= 1 ) begin
			reg		signed	[C_WIDTH-1:0]	reg_c;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_c <= {C_WIDTH{1'b0}};
				end
				else if ( cke_c ) begin
					reg_c <= in_c;
				end
			end
			assign c = reg_c;
		end
		else begin
			assign c = in_c;
		end
		
		
		// m
		wire	signed	[M_WIDTH-1:0]	m;
		if ( CREG >= 1 ) begin
			reg		signed	[M_WIDTH-1:0]	reg_m;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_m <= {M_WIDTH{1'b0}};
				end
				else if ( cke_m ) begin
					reg_m <= a1 * b1;
				end
			end
			assign m = reg_m;
		end
		else begin
			assign m = a1 * b1;
		end
		
		
		// p
		wire	signed	[P_WIDTH-1:0]	p;
		if ( PREG >= 1 ) begin
			reg		signed	[M_WIDTH-1:0]	reg_p;
			always @(posedge clk) begin
				if ( reset ) begin
					reg_p <= {P_WIDTH{1'b0}};
				end
				else if ( cke_p ) begin
					reg_p <= c + m;
				end
			end
			assign p = reg_p;
		end
		else begin
			assign p = c + m;
		end	
		
		assign out_p = p;
	end
	endgenerate
	
	
endmodule


`default_nettype wire


// end of file
