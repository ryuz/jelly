// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    MIPS like CPU core
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                  http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none


// Arithmetic Logic Unit
module jelly_adder48
		#(
			parameter	STAGE0_REG = 1,
			parameter	STAGE1_REG = 1,
			parameter	STAGE2_REG = 1,
			parameter	STAGE3_REG = 1,
			parameter	STAGE4_REG = 1,
			parameter	STAGE5_REG = 1
		)
		(
			input	wire			reset,
			input	wire			enable,
			input	wire			clk,
			
			input	wire			in_feedback,
			input	wire			in_negative,
			input	wire	[47:0]	in_data0,
			input	wire	[47:0]	in_data1,
			
			output	wire	[47:0]	out_data,
			output	wire			out_carry
		);
	
	
	// stage 0
	wire			stage0_in_feedback;
	wire			stage0_in_negative;
	wire	[47:0]	stage0_in_data0;
	wire	[47:0]	stage0_in_data1;
	
	wire			stage0_out_feedback;
	wire			stage0_out_negative;
	wire	[47:0]	stage0_out_data0;
	wire	[47:0]	stage0_out_data1;
	
	assign stage0_in_feedback = in_feedback;
	assign stage0_in_negative = in_negative;
	assign stage0_in_data0    = in_data0;
	assign stage0_in_data1    = in_data1;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(1+1+48+48),
				.REG		(STAGE0_REG)
			)
		i_pipeline_ff_stage0
			(
				.reset		(reset),
				.enable		(enable),
				.clk		(clk),
                
				.in_data	({stage0_in_feedback,  stage0_in_negative,  stage0_in_data0,  stage0_in_data1}),
				.out_data	({stage0_out_feedback, stage0_out_negative, stage0_out_data0, stage0_out_data1})		
			);
	
	// stage 1
	wire			stage1_in_feedback;
	wire			stage1_in_carry;
	wire	[47:0]	stage1_in_data0;
	wire	[47:0]	stage1_in_data1;
	
	wire			stage1_out_feedback;
	wire			stage1_out_carry;
	wire	[47:0]	stage1_out_data0;
	wire	[47:0]	stage1_out_data1;

	assign stage1_in_feedback = stage0_out_feedback;
	assign stage1_in_carry    = stage0_out_negative;
	assign stage1_in_data0    = stage0_out_negative ? ~stage0_out_data0 : stage0_out_data0;
	assign stage1_in_data1    = stage0_out_data1;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(1+48+48+1),
				.REG		(STAGE1_REG)
			)
		i_pipeline_ff_stage1
			(
				.reset		(reset),
				.enable		(enable),
				.clk		(clk),
                
				.in_data	({stage1_in_feedback,  stage1_in_data1,  stage1_in_data0,  stage1_in_carry}),
				.out_data	({stage1_out_feedback, stage1_out_data1, stage1_out_data0, stage1_out_carry})
			);
		
	// stage 2
	reg		[47:0]	stage2_in_data;
	reg		[47:0]	stage2_in_carry;
	
	wire	[47:0]	stage2_out_data;
	wire	[47:0]	stage2_out_carry;
	
	wire	[47:0]	stage2_tmp_src0;
	wire	[47:0]	stage2_tmp_src1;
	assign stage2_tmp_src0 = stage1_out_feedback ? stage2_out_data : stage1_out_data1;
	assign stage2_tmp_src1 = stage1_out_data0;
	
	integer			i;
	always @* begin
		{stage2_in_carry[0], stage2_in_data[0]} = {1'b0, stage2_tmp_src0[0]} + {1'b0, stage2_tmp_src0[0]} + stage1_out_carry;
		for ( i = 1; i < 48; i = i + 1 ) begin
			{stage2_in_carry[i], stage2_in_data[i]} = {1'b0, stage2_tmp_src0[i]} + {1'b0, stage2_tmp_src0[i]} + stage2_out_carry[i-1];
		end		
	end
	
	jelly_pipeline_ff
			#(
				.WIDTH		(47+47),
				.REG		(STAGE2_REG)
			)
		i_pipeline_ff_stage2
			(
				.reset		(reset),
				.enable		(enable),
				.clk		(clk),
                
				.in_data	({stage2_in_carry,  stage2_in_data}),
				.out_data	({stage2_out_carry, stage2_out_data})
			);
	
	// stage 3
	wire	[16:0]	stage3_in_data0;
	wire	[16:0]	stage3_in_data1;
	wire	[16:0]	stage3_in_data2;
	
	wire	[16:0]	stage3_out_data0;
	wire	[16:0]	stage3_out_data1;
	wire	[16:0]	stage3_out_data2;
	
	assign stage3_in_data0 = {1'b0, stage2_out_data[15:0]}  + {1'b0, stage2_out_carry[14:0], 1'b0};
	assign stage3_in_data1 = {1'b0, stage2_out_data[31:16]} + {1'b0, stage2_out_carry[30:15]};
	assign stage3_in_data2 = {1'b0, stage2_out_data[47:32]} + {stage2_out_carry[47:31]};
	
	jelly_pipeline_ff
			#(
				.WIDTH		(17+17+17),
				.REG		(STAGE3_REG)
			)
		i_pipeline_ff_stage3
			(
				.reset		(reset),
				.enable		(enable),
				.clk		(clk),
                             
				.in_data	({stage3_in_data2,  stage3_in_data1,  stage3_in_data0}),
				.out_data	({stage3_out_data2, stage3_out_data1, stage3_out_data0})
			);                                                   
	
	// stage 4
	wire	[32:0]	stage4_in_data0;
	wire	[16:0]	stage4_in_data1;
	
	wire	[32:0]	stage4_out_data0;
	wire	[16:0]	stage4_out_data1;
	
	assign stage4_in_data0[15:0]  = stage3_out_data0[15:0];
	assign stage4_in_data0[32:16] = {1'b0, stage3_out_data1[15:0]} + stage3_out_data0[16];
	assign stage4_in_data1        = stage3_out_data2 + stage3_out_data1[16];
	
	jelly_pipeline_ff
			#(
				.WIDTH		(17+33),
				.REG		(STAGE4_REG)
			)
		i_pipeline_ff_stage4
			(
				.reset		(reset),
				.enable		(enable),
				.clk		(clk),
                             
				.in_data	({stage4_in_data1,  stage4_in_data0}),
				.out_data	({stage4_out_data1, stage4_out_data0})
			);
	
	
	// stage 5
	wire	[48:0]	stage5_in_data;
	
	wire	[48:0]	stage5_out_data;
	
	assign stage5_in_data[31:0]  = stage4_out_data0[31:0];
	assign stage5_in_data[47:32] = stage4_out_data1 + stage4_out_data0[32];
	
	jelly_pipeline_ff
			#(
				.WIDTH		(49),
				.REG		(STAGE5_REG)
			)
		i_pipeline_ff_stage5
			(
				.reset		(reset),
				.enable		(enable),
				.clk		(clk),
                             
				.in_data	({stage5_in_data}),
				.out_data	({stage5_out_data})
			);
	
	assign out_data  = stage5_out_data[47:0];
	assign out_carry = stage5_out_data[48];
	
endmodule


`default_nettype wire


// end of file
