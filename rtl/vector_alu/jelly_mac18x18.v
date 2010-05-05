// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    signed 18x18 MAC
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale			1ns / 1ps
`default_nettype	none


`ifdef 	USE_XILINX_DSP48E

// signed 18x18 MAC  XILINX DSP48E
module jelly_mac18x18
		#(
			parameter							INPUT_REG  = 1,
			parameter							MUL_REG    = 1,
			parameter							ADD_REG    = 1,
			parameter							OUTPUT_REG = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						enable,
			
			
			input	wire						op_mac,
			input	wire						op_sub,
			
			input	wire	[17:0]				in_data0,
			input	wire	[17:0]				in_data1,
			input	wire	[47:0]				in_data2,
			
			output	wire	[47:0]				out_data
		);

	DSP48E
			#(
				.SIM_MODE							("SAFE"), // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
				.ACASCREG							(1), // Number of pipeline registers between A/ACIN input and ACOUT output, 0, 1, or 2
				.ALUMODEREG							(1), // Number of pipeline registers on ALUMODE input, 0 or 1
				.AREG								(1), // Number of pipeline registers on the A input, 0, 1 or 2
				.AUTORESET_PATTERN_DETECT			("FALSE"), // Auto-reset upon pattern detect, "TRUE" or "FALSE"
				.AUTORESET_PATTERN_DETECT_OPTINV	("MATCH"), // Reset if "MATCH" or "NOMATCH"
				.A_INPUT			("DIRECT"), // Selects A input used, "DIRECT" (A port) or "CASCADE" (ACIN port)
				.BCASCREG			(1), // Number of pipeline registers between B/BCIN input and BCOUT output, 0, 1, or 2
				.BREG				(1), // Number of pipeline registers on the B input, 0, 1 or 2
				.B_INPUT			("DIRECT"), // Selects B input used, "DIRECT" (B port) or "CASCADE" (BCIN port)
				.CARRYINREG			(1), // Number of pipeline registers for the CARRYIN input, 0 or 1
				.CARRYINSELREG		(1), // Number of pipeline registers for the CARRYINSEL input, 0 or 1
				.CREG				(1), // Number of pipeline registers on the C input, 0 or 1
				.MASK				(48'h3fffffffffff), // 48-bit Mask value for pattern detect
				.MREG				(1), // Number of multiplier pipeline registers, 0 or 1
				.MULTCARRYINREG		(1), // Number of pipeline registers for multiplier carry in bit, 0 or 1
				.OPMODEREG			(1), // Number of pipeline registers on OPMODE input, 0 or 1
				.PATTERN			(48fh000000000000), // 48-bit Pattern match for pattern detect
				.PREG				(1), // Number of pipeline registers on the P output, 0 or 1
				.SEL_MASK			("MASK"), // Select mask value between the "MASK" value or the value on the "C" port
				.SEL_PATTERN		("PATTERN"), // Select pattern value between the "PATTERN" value or the value on the "C" port
				.SEL_ROUNDING_MASK	("SEL_MASK"), // "SEL_MASK", "MODE1", "MODE2"
				.USE_MULT			("MULT_S"), // Select multiplier usage, "MULT" (MREG => 0), "MULT_S" (MREG => 1), "NONE" (no multiplier)
				.USE_PATTERN_DETECT	("NO_PATDET"), // Enable pattern detect, "PATDET", "NO_PATDET"
				.USE_SIMD			("ONE48") // SIMD selection, "ONE48", "TWO24", "FOUR12"
			)
		i_dsp48e
			)
				.ACOUT(ACOUT), // 30-bit A port cascade output
				.BCOUT(BCOUT), // 18-bit B port cascade output
				.CARRYCASCOUT(CARRYCASCOUT), // 1-bit cascade carry output
				.CARRYOUT(CARRYOUT), // 4-bit carry output
				.MULTSIGNOUT(MULTSIGNOUT), // 1-bit multiplier sign cascade output
				.OVERFLOW(OVERFLOW), // 1-bit overflow in add/acc output
				.P(P), // 48-bit output
				.PATTERNBDETECT(PATTERNBDETECT), // 1-bit active high pattern bar detect output
				.PATTERNDETECT(PATTERNDETECT), // 1-bit active high pattern detect output
				.PCOUT(PCOUT), // 48-bit cascade output
				.UNDERFLOW(UNDERFLOW), // 1-bit active high underflow in add/acc output
				.A(A), // 30-bit A data input
				.ACIN(ACIN), // 30-bit A cascade data input
				.ALUMODE(ALUMODE), // 4-bit ALU control input
				.B(B), // 18-bit B data input
				.BCIN(BCIN), // 18-bit B cascade input
				.C(C), // 48-bit C data input
				.CARRYCASCIN(CARRYCASCIN), // 1-bit cascade carry input
				.CARRYIN(CARRYIN), // 1-bit carry input signal
				.CARRYINSEL(CARRYINSEL), // 3-bit carry select input
				.CEA1(CEA1), // 1-bit active high clock enable input for 1st stage A registers
				.CEA2(CEA2), // 1-bit active high clock enable input for 2nd stage A registers
				.CEALUMODE(CEALUMODE), // 1-bit active high clock enable input for ALUMODE registers
				.CEB1(CEB1), // 1-bit active high clock enable input for 1st stage B registers
				.CEB2(CEB2), // 1-bit active high clock enable input for 2nd stage B registers
				.CEC(CEC), // 1-bit active high clock enable input for C registers
				.CECARRYIN(CECARRYIN), // 1-bit active high clock enable input for CARRYIN register
				.CECTRL(CECTRL), // 1-bit active high clock enable input for OPMODE and carry registers
				.CEM(CEM), // 1-bit active high clock enable input for multiplier registers
				.CEMULTCARRYIN(CEMULTCARRYIN), // 1-bit active high clock enable for multiplier carry in register
				.CEP(CEP), // 1-bit active high clock enable input for P registers
				.CLK(CLK), // Clock input
				.MULTSIGNIN(MULTSIGNIN), // 1-bit multiplier sign input
				.OPMODE(OPMODE), // 7-bit operation mode input
				.PCIN(PCIN), // 48-bit P cascade input
				.RSTA(RSTA), // 1-bit reset input for A pipeline registers
				.RSTALLCARRYIN(RSTALLCARRYIN), // 1-bit reset input for carry pipeline registers
				.RSTALUMODE(RSTALUMODE), // 1-bit reset input for ALUMODE pipeline registers
				.RSTB(RSTB), // 1-bit reset input for B pipeline registers
				.RSTC(RSTC), // 1-bit reset input for C pipeline registers
				.RSTCTRL(RSTCTRL), // 1-bit reset input for OPMODE pipeline registers
				.RSTM(RSTM), // 1-bit reset input for multiplier registers
				.RSTP(RSTP) // 1-bit reset input for P pipeline registers
				);
endmodule

`else
`ifdef USE_XILINX_DSP48A1

// signed 18x18 MAC  XILINX DSP48A1
module jelly_mac18x18
		#(
			parameter							INPUT_REG  = 1,
			parameter							MUL_REG    = 1,
			parameter							ADD_REG    = 1,
			parameter							OUTPUT_REG = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						enable,
			
			
			input	wire						op_mac,
			input	wire						op_sub,
			
			input	wire	[17:0]				in_data0,
			input	wire	[17:0]				in_data1,
			input	wire	[47:0]				in_data2,
			
			output	wire	[47:0]				out_data
		);
	
	wire	[7:0]		opmode;
	assign opmode[7]   = op_sub;
	assign opmode[6]   = 1'b0;
	assign opmode[5]   = 1'b0;
	assign opmode[4]   = 1'b0;
	assign opmode[3:2] = op_mac ? 2'b10 : 2'b11;
	assign opmode[1:0] = 2'b01;
	
	
	wire	[7:0]		dsp_opmode;
	wire	[47:0]		dsp_c;
	
	generate
	if ( MUL_REG ) begin
		reg		[7:0]		reg_opmode;
		reg		[47:0]		reg_c;
		always @( posedge clk ) begin
			reg_opmode <= opmode;
			reg_c      <= in_data2;
		end
		assign dsp_opmode = reg_opmode;
		assign dsp_c      = reg_c;
	end
	else begin
		assign dsp_opmode = opmode;
		assign dsp_c      = in_data2;
	end
	endgenerate
	
	DSP48A1
			#(
				.A0REG			(0),
				.A1REG			(INPUT_REG),
				.B0REG			(0),
				.B1REG			(INPUT_REG),
				.CARRYINREG		(1),
				.CARRYINSEL		("OPMODE5"),
				.CARRYOUTREG	(1),
				.CREG			(INPUT_REG),
				.DREG			(INPUT_REG),
				.MREG			(MUL_REG),
				.OPMODEREG		(INPUT_REG),
				.PREG			(OUTPUT_REG),
				.RSTTYPE		("SYNC")
			)
		i_dsp48a1
			(
				.BCOUT			(),
				.PCOUT			(),
				
				.CARRYOUT		(),
				.CARRYOUTF		(),
				.M				(),
				.P				(out_data),
				
				.PCIN			(48'd0),
				
				.CLK			(clk),
				.OPMODE			(dsp_opmode),
				
				.A				(in_data0),
				.B				(in_data1),
				.C				(dsp_c),
				.CARRYIN		(1'b0),
				.D				(18'd0),
				
				.CEA			(enable),
				.CEB			(enable),
				.CEC			(enable),
				.CECARRYIN		(enable),
				.CED			(enable),
				.CEM			(enable),
				.CEOPMODE		(enable),
				.CEP			(enable),
				.RSTA			(reset),
				.RSTB			(reset),
				.RSTC			(reset),
				.RSTCARRYIN		(reset),
				.RSTD			(reset),
				.RSTM			(reset),
				.RSTOPMODE		(reset),
				.RSTP			(reset) 
			);

endmodule

`else

// signed 18x18 MAC
module jelly_mac18x18
		#(
			parameter							INPUT_REG  = 1,
			parameter							MUL_REG    = 1,
			parameter							OUTPUT_REG = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						enable,
			
			
			input	wire						op_mac,
			input	wire						op_sub,
			
			input	wire	[17:0]				in_data0,
			input	wire	[17:0]				in_data1,
			input	wire	[47:0]				in_data2,
			
			output	wire	[47:0]				out_data
		);

	// input stage
	wire					input_mac;
	wire					input_sub;	
	wire	signed	[17:0]	input_data0;
	wire	signed	[17:0]	input_data1;
	wire	signed	[47:0]	input_data2;
	
	generate
	if ( INPUT_REG ) begin
		reg							input_reg_mac;
		reg							input_reg_sub;	
		reg		signed		[17:0]	input_reg_data0;
		reg		signed		[17:0]	input_reg_data1;
		reg		signed		[47:0]	input_reg_data2;
		always @( posedge clk ) begin
			if ( enable ) begin
				if ( reset ) begin
					input_reg_mac   <= 0;
					input_reg_sub   <= 0;
					input_reg_data0 <= 0;
					input_reg_data1 <= 0;
					input_reg_data2 <= 0;
				end
				else begin
					input_reg_mac   <= op_mac;
					input_reg_sub   <= op_sub;
					input_reg_data0 <= in_data0;
					input_reg_data1 <= in_data1;
					input_reg_data2 <= in_data2;
				end                  
			end
		end
		assign input_mac   = input_reg_mac;
		assign input_sub   = input_reg_sub;
		assign input_data0 = input_reg_data0;
		assign input_data1 = input_reg_data1;
		assign input_data2 = input_reg_data2;		           
	end
	else begin
		assign input_mac   = op_mac;
		assign input_sub   = op_sub;
		assign input_data0 = in_data0;
		assign input_data1 = in_data1;
		assign input_data2 = in_data2;		           
	end                    
	endgenerate
	
	
	// multiply stage
	wire					mul_mac;
	wire					mul_sub;
	wire	signed	[35:0]	mul_data01;
	wire	signed	[47:0]	mul_data2;
	generate
	if ( MUL_REG ) begin
		reg							mul_reg_mac;
		reg							mul_reg_sub;	
		reg		signed		[35:0]	mul_reg_data01;
		reg		signed		[47:0]	mul_reg_data2;
		always @( posedge clk ) begin
			if ( enable ) begin
				if ( reset ) begin
					mul_reg_mac    <= 0;
					mul_reg_sub    <= 0;
					mul_reg_data01 <= 0;
					mul_reg_data2  <= 0;
				end 
				else begin
					mul_reg_mac    <= input_mac;
					mul_reg_sub    <= input_sub;
					mul_reg_data01 <= input_data0 * input_data1;
					mul_reg_data2  <= input_data2;
				end
			end
		end
		assign mul_mac    = mul_reg_mac;
		assign mul_sub    = mul_reg_sub;
		assign mul_data01 = mul_reg_data01;
		assign mul_data2  = mul_reg_data2;
	end                   
	else begin
		assign mul_mac    = input_mac;
		assign mul_sub    = input_sub;
		assign mul_data01 = input_data0 * input_data1;
		assign mul_data2  = input_data2;
	end                    
	endgenerate
	
	
	// output stage
	generate
	if ( OUTPUT_REG ) begin
		reg		signed		[47:0]	output_reg_data;
		always @( posedge clk ) begin
			if ( enable ) begin
				if ( reset ) begin
					output_reg_data <= 0;
				end 
				else begin
					if ( mul_mac ) begin
						output_reg_data <= mul_sub ? (output_reg_data - mul_data01) : (output_reg_data + mul_data01);
					end
					else begin
						output_reg_data <= mul_sub ? (mul_data2 - mul_data01) : (mul_data2 + mul_data01);
					end
				end
			end
		end
		assign out_data = output_reg_data;
	end
	else begin
		assign out_data = mul_data2 + mul_sub ? (mul_data2 - mul_data01) : (mul_data2 + mul_data01);
	end
	endgenerate
	
endmodule

`endif
`endif

`default_nettype	wire

// end of file
