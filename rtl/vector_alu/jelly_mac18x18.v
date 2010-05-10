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
			parameter							OUTPUT_REG = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			input	wire						op_addsub,
			input	wire						op_feedback,
			
			input	wire	[17:0]				in_data0,
			input	wire	[17:0]				in_data1,
			input	wire	[47:0]				in_data2,
			
			output	wire	[47:0]				out_data
		);
	
	wire				dsp_addsub;
	wire				dsp_feedback;
	wire	[47:0]		dsp_data2;
	
	generate
	if ( MUL_REG ) begin
		reg					reg_addsub;
		reg					reg_feedback;
		reg		[47:0]		reg_data2;
		always @( posedge clk ) begin
			reg_addsub   <= op_addsub;
			reg_feedback <= op_feedback;
			reg_data2    <= in_data2;
		end
		assign dsp_addsub   = reg_addsub;
		assign dsp_feedback = reg_feedback;
		assign dsp_data2    = reg_data2;
	end
	else begin
		assign dsp_addsub   = op_addsub;
		assign dsp_feedback = op_feedback;
		assign dsp_data2    = in_data2;
	end
	endgenerate
	
	wire	[7:0]	opmode;
	wire	[3:0]	alumode;
	
	assign opmode  = dsp_feedback ? 7'b011_01_01 : 7'b010_01_01;
	assign alumode = dsp_addsub   ? 4'b0011      : 4'b0001;
	
	DSP48E
			#(
				.SIM_MODE							("SAFE"),
				.ACASCREG							(1),
				.ALUMODEREG							(1),
				.AREG								(INPUT_REG),
				.AUTORESET_PATTERN_DETECT			("FALSE"),
				.AUTORESET_PATTERN_DETECT_OPTINV	("MATCH"),
				.A_INPUT							("DIRECT"),
				.BCASCREG							(1),
				.BREG								(INPUT_REG),
				.B_INPUT							("DIRECT"),
				.CARRYINREG							(1),
				.CARRYINSELREG						(INPUT_REG),
				.CREG								(1),
				.MASK								(48'h3fffffffffff),
				.MREG								(MUL_REG),
				.MULTCARRYINREG						(1),
				.OPMODEREG							(INPUT_REG),
				.PATTERN							(48'h000000000000),
				.PREG								(OUTPUT_REG),
				.SEL_MASK							("MASK"),
				.SEL_PATTERN						("PATTERN"),
				.SEL_ROUNDING_MASK					("SEL_MASK"),
				.USE_MULT							("MULT_S"),
				.USE_PATTERN_DETECT					("NO_PATDET"),
				.USE_SIMD							("ONE48")
			)
		i_dsp48e
			(
				.ACOUT								(),
				.BCOUT								(),
				.CARRYCASCOUT						(),
				.CARRYOUT							(),
				.MULTSIGNOUT						(),
				.OVERFLOW							(),
				.P									(out_data),
				.PATTERNBDETECT						(),
				.PATTERNDETECT						(),
				.PCOUT								(),
				.UNDERFLOW							(),
				.A									({{12{in_data0[17]}}, in_data0[17:0]}),
				.ACIN								({30{1'b0}}),
				.ALUMODE							(alumode),
				.B									(in_data1),
				.BCIN								({18{1'b0}}),
				.C									(dsp_data2),
				.CARRYCASCIN						(1'b0),
				.CARRYIN							(1'b0),
				.CARRYINSEL							({3{1'b0}}),
				.CEA1								(cke),
				.CEA2								(cke),
				.CEALUMODE							(cke),
				.CEB1								(cke),
				.CEB2								(cke),
				.CEC								(cke),
				.CECARRYIN							(cke),
				.CECTRL								(cke),
				.CEM								(cke),
				.CEMULTCARRYIN						(cke),
				.CEP								(cke),
				.CLK								(clk),
				.MULTSIGNIN							(1'b0),
				.OPMODE								(opmode),
				.PCIN								({48{1'b0}}),
				.RSTA								(reset),
				.RSTALLCARRYIN						(reset),
				.RSTALUMODE							(reset),
				.RSTB								(reset),
				.RSTC								(reset),
				.RSTCTRL							(reset),
				.RSTM								(reset),
				.RSTP								(reset)
			);
endmodule

`else
`ifdef USE_XILINX_DSP48A1

// signed 18x18 MAC  XILINX DSP48A1
module jelly_mac18x18
		#(
			parameter							INPUT_REG  = 1,
			parameter							MUL_REG    = 1,
			parameter							OUTPUT_REG = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire						cke,
			
			
			input	wire						op_feedback,
			input	wire						op_addsub,
			
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
			input	wire						cke,
			
			input	wire						op_addsub,
			input	wire						op_feedback,
			
			input	wire	[17:0]				in_data0,
			input	wire	[17:0]				in_data1,
			input	wire	[47:0]				in_data2,
			
			output	wire	[47:0]				out_data
		);

	// input stage
	wire					input_feedback;
	wire					input_addsub;	
	wire	signed	[17:0]	input_data0;
	wire	signed	[17:0]	input_data1;
	wire	signed	[47:0]	input_data2;
	
	generate
	if ( INPUT_REG ) begin
		reg							input_reg_feedback;
		reg							input_reg_addsub;	
		reg		signed		[17:0]	input_reg_data0;
		reg		signed		[17:0]	input_reg_data1;
		reg		signed		[47:0]	input_reg_data2;
		always @( posedge clk ) begin
			if ( reset ) begin
				input_reg_feedback <= 0;
				input_reg_addsub   <= 0;
				input_reg_data0    <= 0;
				input_reg_data1    <= 0;
				input_reg_data2    <= 0;
			end
			else begin
				if ( cke ) begin
					input_reg_feedback <= op_feedback;
					input_reg_addsub   <= op_addsub;
					input_reg_data0    <= in_data0;
					input_reg_data1    <= in_data1;
					input_reg_data2    <= in_data2;
				end                  
			end
		end
		assign input_feedback = input_reg_feedback;
		assign input_addsub   = input_reg_addsub;
		assign input_data0    = input_reg_data0;
		assign input_data1    = input_reg_data1;
		assign input_data2    = input_reg_data2;		           
	end
	else begin
		assign input_feedback = op_feedback;
		assign input_addsub   = op_addsub;
		assign input_data0    = in_data0;
		assign input_data1    = in_data1;
		assign input_data2    = in_data2;		           
	end                    
	endgenerate
	
	
	// multiply stage
	wire					mul_feedback;
	wire					mul_addsub;
	wire	signed	[35:0]	mul_data01;
	wire	signed	[47:0]	mul_data2;
	generate
	if ( MUL_REG ) begin
		reg							mul_reg_feedback;
		reg							mul_reg_addsub;	
		reg		signed		[35:0]	mul_reg_data01;
		reg		signed		[47:0]	mul_reg_data2;
		always @( posedge clk ) begin
			if ( reset ) begin
				mul_reg_feedback <= 0;
				mul_reg_addsub   <= 0;
				mul_reg_data01   <= 0;
				mul_reg_data2    <= 0;
			end 
			else begin
				if ( cke ) begin
					mul_reg_feedback <= input_feedback;
					mul_reg_addsub   <= input_addsub;
					mul_reg_data01   <= input_data0 * input_data1;
					mul_reg_data2    <= input_data2;
				end
			end
		end
		assign mul_feedback = mul_reg_feedback;
		assign mul_addsub   = mul_reg_addsub;
		assign mul_data01   = mul_reg_data01;
		assign mul_data2    = mul_reg_data2;
	end                   
	else begin
		assign mul_feedback = input_feedback;
		assign mul_addsub   = input_addsub;
		assign mul_data01   = input_data0 * input_data1;
		assign mul_data2    = input_data2;
	end                    
	endgenerate
	
	
	// output stage
	generate
	if ( OUTPUT_REG ) begin
		reg		signed		[47:0]	output_reg_data;
		always @( posedge clk ) begin
			if ( reset ) begin
				output_reg_data <= 0;
			end
			else begin
				if ( cke ) begin
					if ( mul_feedback ) begin
						output_reg_data <= mul_addsub ? (output_reg_data - mul_data01) : (output_reg_data + mul_data01);
					end
					else begin
						output_reg_data <= mul_addsub ? (mul_data2 - mul_data01) : (mul_data2 + mul_data01);
					end
				end
			end
		end
		assign out_data = output_reg_data;
	end
	else begin
		assign out_data = mul_data2 + mul_addsub ? (mul_data2 - mul_data01) : (mul_data2 + mul_data01);
	end
	endgenerate
	
endmodule

`endif
`endif

`default_nettype	wire

// end of file
