// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale			1ns / 1ps
`default_nettype	none



// Arithmetic Logic Unit
module jelly_mac16x16
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

