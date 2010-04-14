// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    signed 18x18 MAC
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale			1ns / 1ps
`default_nettype	none


`ifdef 	USE_XILINX_DSP48A1

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
						output_reg_data <= output_reg_data + (mul_sub ? -mul_reg_data01 : mul_reg_data01);
					end
					else begin
						output_reg_data <= mul_reg_data2   + (mul_sub ? -mul_reg_data01 : mul_reg_data01);
					end
				end
			end
		end
		assign out_data = output_reg_data;
	end                   
	else begin
		assign out_data = mul_reg_data2 + (mul_sub ? -mul_reg_data01 : mul_reg_data01);
	end                    
	endgenerate
	
endmodule

`default_nettype	wire

// end of file
