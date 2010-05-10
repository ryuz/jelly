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
module jelly_vector_mac
		#(
			parameter STAGE0_REG = 0,
			parameter STAGE1_REG = 1,
			parameter STAGE2_REG = 1,
			parameter STAGE3_REG = 1,
			parameter STAGE4_REG = 1,
			parameter STAGE5_REG = 1,
			parameter STAGE6_REG = 1,
			parameter STAGE7_REG = 1,
			parameter STAGE8_REG = 1
		)
		(
			input	wire			reset,
			input	wire			clk,
			input	wire			cke,
			
			input	wire	[1:0]	in_size,
			input	wire			in_addsub,
			input	wire			in_feedback,
			input	wire	[5:0]	in_shift,
			input	wire			in_clip,
			input	wire			in_src0_sign,
			input	wire			in_src1_sign,
			input	wire			in_src2_sign,
			input	wire			in_dst_sign,
			input	wire	[31:0]	in_src0_data,
			input	wire	[31:0]	in_src1_data,
			input	wire	[31:0]	in_src2_data,
			
			output	wire	[31:0]	out_dst_data
		);
	
	// -----------------------------------------
	//  Input (stage 0)
	// -----------------------------------------
	
	wire	[1:0]	stage0_out_size;
	wire			stage0_out_addsub;
	wire			stage0_out_feedback;
	wire	[5:0]	stage0_out_shift;
	wire			stage0_out_clip;
	wire			stage0_out_src0_sign;
	wire			stage0_out_src1_sign;
	wire			stage0_out_src2_sign;
	wire			stage0_out_dst_sign;
	wire	[31:0]	stage0_out_src0_data;
	wire	[31:0]	stage0_out_src1_data;
	wire	[31:0]	stage0_out_src2_data;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(2+1+1+6+1+1+1+1+1+32+32+32),
				.REG		(STAGE0_REG),
				.INIT		({1'b0, {(2+1+6+1+1+1+1+1+32+32+32){1'bx}}})
			)
		i_pipeline_ff_stage0
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	(
								{
									in_size,
									in_addsub,
									in_feedback,
									in_shift,
									in_clip,
									in_src0_sign,
									in_src1_sign,
									in_src2_sign,
									in_dst_sign,
									in_src0_data,
									in_src1_data,
									in_src2_data
								}
							),
				.out_data	(
								{
									stage0_out_size,
									stage0_out_addsub,
									stage0_out_feedback,
									stage0_out_shift,
									stage0_out_clip,
									stage0_out_src0_sign,
									stage0_out_src1_sign,
									stage0_out_src2_sign,
									stage0_out_dst_sign,
									stage0_out_src0_data,
									stage0_out_src1_data,
									stage0_out_src2_data
								}
							)

			);
	
	// -----------------------------------------
	//  Sign expand (stage 1)
	// -----------------------------------------
	
	wire			[1:0]	stage1_in_size;
	wire					stage1_in_addsub;
	wire					stage1_in_feedback;
	wire			[5:0]	stage1_in_shift;
	wire					stage1_in_clip;
	wire					stage1_in_dst_sign;
	wire	signed [32:0]	stage1_in_src0_b0;
	wire	signed [32:0]	stage1_in_src0_b1;
	wire	signed [32:0]	stage1_in_src0_b2;
	wire	signed [32:0]	stage1_in_src0_b3;
	wire	signed [32:0]	stage1_in_src0_h0;
	wire	signed [32:0]	stage1_in_src0_h1;
	wire	signed [32:0]	stage1_in_src0_w;
	wire	signed [32:0]	stage1_in_src1_b0;
	wire	signed [32:0]	stage1_in_src1_b1;
	wire	signed [32:0]	stage1_in_src1_b2;
	wire	signed [32:0]	stage1_in_src1_b3;
	wire	signed [32:0]	stage1_in_src1_h0;
	wire	signed [32:0]	stage1_in_src1_h1;
	wire	signed [32:0]	stage1_in_src1_w;
	wire	signed [32:0]	stage1_in_src2_b0;
	wire	signed [32:0]	stage1_in_src2_b1;
	wire	signed [32:0]	stage1_in_src2_b2;
	wire	signed [32:0]	stage1_in_src2_b3;
	wire	signed [32:0]	stage1_in_src2_h0;
	wire	signed [32:0]	stage1_in_src2_h1;
	wire	signed [32:0]	stage1_in_src2_w;
	
	wire			[1:0]	stage1_out_size;
	wire					stage1_out_addsub;
	wire					stage1_out_feedback;
	wire			[5:0]	stage1_out_shift;
	wire					stage1_out_clip;
	wire					stage1_out_dst_sign;
	wire	signed [32:0]	stage1_out_src0_b0;
	wire	signed [32:0]	stage1_out_src0_b1;
	wire	signed [32:0]	stage1_out_src0_b2;
	wire	signed [32:0]	stage1_out_src0_b3;
	wire	signed [32:0]	stage1_out_src0_h0;
	wire	signed [32:0]	stage1_out_src0_h1;
	wire	signed [32:0]	stage1_out_src0_w;
	wire	signed [32:0]	stage1_out_src1_b0;
	wire	signed [32:0]	stage1_out_src1_b1;
	wire	signed [32:0]	stage1_out_src1_b2;
	wire	signed [32:0]	stage1_out_src1_b3;
	wire	signed [32:0]	stage1_out_src1_h0;
	wire	signed [32:0]	stage1_out_src1_h1;
	wire	signed [32:0]	stage1_out_src1_w;
	wire	signed [32:0]	stage1_out_src2_b0;
	wire	signed [32:0]	stage1_out_src2_b1;
	wire	signed [32:0]	stage1_out_src2_b2;
	wire	signed [32:0]	stage1_out_src2_b3;
	wire	signed [32:0]	stage1_out_src2_h0;
	wire	signed [32:0]	stage1_out_src2_h1;
	wire	signed [32:0]	stage1_out_src2_w;
	
	assign stage1_in_size     = stage0_out_size;
	assign stage1_in_addsub   = stage0_out_addsub;
	assign stage1_in_feedback = stage0_out_feedback;
	assign stage1_in_shift    = stage0_out_shift;
	assign stage1_in_clip     = stage0_out_clip;
	assign stage1_in_dst_sign = stage0_out_dst_sign;
	assign stage1_in_src0_b0  = {(stage0_out_src0_sign ? {25{stage0_out_src0_data[7]}}  : {25{1'b0}}), stage0_out_src0_data[7:0]};
	assign stage1_in_src0_b1  = {(stage0_out_src0_sign ? {25{stage0_out_src0_data[15]}} : {25{1'b0}}), stage0_out_src0_data[15:8]};
	assign stage1_in_src0_b2  = {(stage0_out_src0_sign ? {25{stage0_out_src0_data[23]}} : {25{1'b0}}), stage0_out_src0_data[23:16]};
	assign stage1_in_src0_b3  = {(stage0_out_src0_sign ? {25{stage0_out_src0_data[31]}} : {25{1'b0}}), stage0_out_src0_data[31:24]};
	assign stage1_in_src0_h0  = {(stage0_out_src0_sign ? {17{stage0_out_src0_data[15]}} : {17{1'b0}}), stage0_out_src0_data[15:0]};
	assign stage1_in_src0_h1  = {(stage0_out_src0_sign ? {17{stage0_out_src0_data[31]}} : {17{1'b0}}), stage0_out_src0_data[31:16]};
	assign stage1_in_src0_w   = {(stage0_out_src0_sign ? { 1{stage0_out_src0_data[31]}} : {1{1'b0}}),  stage0_out_src0_data[31:0]};
	assign stage1_in_src1_b0  = {(stage0_out_src1_sign ? {25{stage0_out_src1_data[7]}}  : {25{1'b0}}), stage0_out_src1_data[7:0]};
	assign stage1_in_src1_b1  = {(stage0_out_src1_sign ? {25{stage0_out_src1_data[15]}} : {25{1'b0}}), stage0_out_src1_data[15:8]};
	assign stage1_in_src1_b2  = {(stage0_out_src1_sign ? {25{stage0_out_src1_data[23]}} : {25{1'b0}}), stage0_out_src1_data[23:16]};
	assign stage1_in_src1_b3  = {(stage0_out_src1_sign ? {25{stage0_out_src1_data[31]}} : {25{1'b0}}), stage0_out_src1_data[31:24]};
	assign stage1_in_src1_h0  = {(stage0_out_src1_sign ? {17{stage0_out_src1_data[15]}} : {17{1'b0}}), stage0_out_src1_data[15:0]};
	assign stage1_in_src1_h1  = {(stage0_out_src1_sign ? {17{stage0_out_src1_data[31]}} : {17{1'b0}}), stage0_out_src1_data[31:16]};
	assign stage1_in_src1_w   = {(stage0_out_src1_sign ? { 1{stage0_out_src1_data[31]}} : {1{1'b0}}),  stage0_out_src1_data[31:0]};
	assign stage1_in_src2_b0  = {(stage0_out_src2_sign ? {25{stage0_out_src2_data[7]}}  : {25{1'b0}}), stage0_out_src2_data[7:0]};
	assign stage1_in_src2_b1  = {(stage0_out_src2_sign ? {25{stage0_out_src2_data[15]}} : {25{1'b0}}), stage0_out_src2_data[15:8]};
	assign stage1_in_src2_b2  = {(stage0_out_src2_sign ? {25{stage0_out_src2_data[23]}} : {25{1'b0}}), stage0_out_src2_data[23:16]};
	assign stage1_in_src2_b3  = {(stage0_out_src2_sign ? {25{stage0_out_src2_data[31]}} : {25{1'b0}}), stage0_out_src2_data[31:24]};
	assign stage1_in_src2_h0  = {(stage0_out_src2_sign ? {17{stage0_out_src2_data[15]}} : {17{1'b0}}), stage0_out_src2_data[15:0]};
	assign stage1_in_src2_h1  = {(stage0_out_src2_sign ? {17{stage0_out_src2_data[31]}} : {17{1'b0}}), stage0_out_src2_data[31:16]};
	assign stage1_in_src2_w   = {(stage0_out_src2_sign ? { 1{stage0_out_src2_data[31]}} : { 1{1'b0}}), stage0_out_src2_data[31:0]};
	
	jelly_pipeline_ff
			#(
				.WIDTH		(2+1+1+6+1+1+(33*21)),
				.REG		(STAGE1_REG),
				.INIT		({1'b0, {(2+1+6+1+1+(33*21)){1'bx}}})
			)
		i_pipeline_ff_stage1
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	(
								{
									stage1_in_size,
									stage1_in_addsub,
									stage1_in_feedback,
									stage1_in_shift,
									stage1_in_clip,
									stage1_in_dst_sign,
									stage1_in_src0_b0,
									stage1_in_src0_b1,
									stage1_in_src0_b2,
									stage1_in_src0_b3,
									stage1_in_src0_h0,
									stage1_in_src0_h1,
									stage1_in_src0_w,
									stage1_in_src1_b0,
									stage1_in_src1_b1,
									stage1_in_src1_b2,
									stage1_in_src1_b3,
									stage1_in_src1_h0,
									stage1_in_src1_h1,
									stage1_in_src1_w,
									stage1_in_src2_b0,
									stage1_in_src2_b1,
									stage1_in_src2_b2,
									stage1_in_src2_b3,
									stage1_in_src2_h0,
									stage1_in_src2_h1,
									stage1_in_src2_w
								}
							),
				.out_data	(
								{
									stage1_out_size,
									stage1_out_addsub,
									stage1_out_feedback,
									stage1_out_shift,
									stage1_out_clip,
									stage1_out_dst_sign,
									stage1_out_src0_b0,
									stage1_out_src0_b1,
									stage1_out_src0_b2,
									stage1_out_src0_b3,
									stage1_out_src0_h0,
									stage1_out_src0_h1,
									stage1_out_src0_w,
									stage1_out_src1_b0,
									stage1_out_src1_b1,
									stage1_out_src1_b2,
									stage1_out_src1_b3,
									stage1_out_src1_h0,
									stage1_out_src1_h1,
									stage1_out_src1_w,
									stage1_out_src2_b0,
									stage1_out_src2_b1,
									stage1_out_src2_b2,
									stage1_out_src2_b3,
									stage1_out_src2_h0,
									stage1_out_src2_h1,
									stage1_out_src2_w
								}
							)
			);
	
	
	// -----------------------------------------
	//  Select multiply source (stage 2)
	// -----------------------------------------
	
	wire			[1:0]	stage2_in_size;
	wire					stage2_in_addsub;
	wire					stage2_in_feedback;
	wire			[5:0]	stage2_in_shift;
	wire					stage2_in_clip;
	wire					stage2_in_dst_sign;
	reg		signed	[17:0]	stage2_in_mul0_src0;
	reg		signed	[17:0]	stage2_in_mul0_src1;
	reg		signed	[17:0]	stage2_in_mul0_src2;
	reg		signed	[17:0]	stage2_in_mul1_src0;
	reg		signed	[17:0]	stage2_in_mul1_src1;
	reg		signed	[17:0]	stage2_in_mul1_src2;
	reg		signed	[17:0]	stage2_in_mul2_src0;
	reg		signed	[17:0]	stage2_in_mul2_src1;
	reg		signed	[17:0]	stage2_in_mul2_src2;
	reg		signed	[17:0]	stage2_in_mul3_src0;
	reg		signed	[17:0]	stage2_in_mul3_src1;
	reg		signed	[17:0]	stage2_in_mul3_src2;
	
	wire			[1:0]	stage2_out_size;
	wire					stage2_out_addsub;
	wire					stage2_out_feedback;
	wire			[5:0]	stage2_out_shift;
	wire					stage2_out_clip;
	wire					stage2_out_dst_sign;
	wire	signed	[17:0]	stage2_out_mul0_src0;
	wire	signed	[17:0]	stage2_out_mul0_src1;
	wire	signed	[17:0]	stage2_out_mul0_src2;
	wire	signed	[17:0]	stage2_out_mul1_src0;
	wire	signed	[17:0]	stage2_out_mul1_src1;
	wire	signed	[17:0]	stage2_out_mul1_src2;
	wire	signed	[17:0]	stage2_out_mul2_src0;
	wire	signed	[17:0]	stage2_out_mul2_src1;
	wire	signed	[17:0]	stage2_out_mul2_src2;
	wire	signed	[17:0]	stage2_out_mul3_src0;
	wire	signed	[17:0]	stage2_out_mul3_src1;
	wire	signed	[17:0]	stage2_out_mul3_src2;
	

	assign stage2_in_size     = stage1_out_size;
	assign stage2_in_addsub   = stage1_out_addsub;
	assign stage2_in_feedback = stage1_out_feedback;
	assign stage2_in_shift    = stage1_out_shift;
	assign stage2_in_clip     = stage1_out_clip;
	assign stage2_in_dst_sign = stage1_out_dst_sign;
	
	always @* begin
		case ( stage1_out_size )
		2'b00:	// 8bit
			begin
				stage2_in_mul0_src0 <= stage1_out_src0_b0;
				stage2_in_mul0_src1 <= stage1_out_src1_b0;
				stage2_in_mul0_src2 <= stage1_out_src2_b0;
				stage2_in_mul1_src0 <= stage1_out_src0_b1;
				stage2_in_mul1_src1 <= stage1_out_src1_b1;
				stage2_in_mul1_src2 <= stage1_out_src2_b1;
				stage2_in_mul2_src0 <= stage1_out_src0_b2;
				stage2_in_mul2_src1 <= stage1_out_src1_b2;
				stage2_in_mul2_src2 <= stage1_out_src2_b2;
				stage2_in_mul3_src0 <= stage1_out_src0_b3;
				stage2_in_mul3_src1 <= stage1_out_src1_b3;
				stage2_in_mul3_src2 <= stage1_out_src2_b3;
			end
			
		2'b01:	// 16bit
			begin
				stage2_in_mul0_src0 <= stage1_out_src0_h0;
				stage2_in_mul0_src1 <= stage1_out_src1_h0;
				stage2_in_mul0_src2 <= stage1_out_src2_h0;
				stage2_in_mul1_src0 <= {18{1'bx}};
				stage2_in_mul1_src1 <= {18{1'bx}};
				stage2_in_mul1_src2 <= {18{1'bx}};
				stage2_in_mul2_src0 <= {18{1'bx}};
				stage2_in_mul2_src1 <= {18{1'bx}};
				stage2_in_mul2_src2 <= {18{1'bx}};
				stage2_in_mul3_src0 <= stage1_out_src0_h1;
				stage2_in_mul3_src1 <= stage1_out_src1_h1;
				stage2_in_mul3_src2 <= stage1_out_src2_h1;
			end

			2'b10:	// reserve
				begin
				stage2_in_mul0_src0 <= {18{1'bx}};
				stage2_in_mul0_src1 <= {18{1'bx}};
				stage2_in_mul0_src2 <= {18{1'bx}};
				stage2_in_mul1_src0 <= {18{1'bx}};
				stage2_in_mul1_src1 <= {18{1'bx}};
				stage2_in_mul1_src2 <= {18{1'bx}};
				stage2_in_mul2_src0 <= {18{1'bx}};
				stage2_in_mul2_src1 <= {18{1'bx}};
				stage2_in_mul2_src2 <= {18{1'bx}};
				stage2_in_mul3_src0 <= {18{1'bx}};
				stage2_in_mul3_src1 <= {18{1'bx}};
				stage2_in_mul3_src2 <= {18{1'bx}};
				end
			
			2'b11:	// 32bit
			begin
				stage2_in_mul0_src0 <= {{2{1'b0}}, stage1_out_src0_w[15:0]};
				stage2_in_mul0_src1 <= {{2{1'b0}}, stage1_out_src1_w[15:0]};
				stage2_in_mul0_src2 <= {{2{1'b0}}, stage1_out_src2_w[15:0]};
				stage2_in_mul1_src0 <= {{2{stage1_out_src0_w[31]}}, stage1_out_src0_w[31:16]};
				stage2_in_mul1_src1 <= {{2{1'b0}}, stage1_out_src1_w[15:0]};
				stage2_in_mul1_src2 <= {18{1'b0}};
				stage2_in_mul2_src0 <= {{2{1'b0}}, stage1_out_src0_w[15:0]};
				stage2_in_mul2_src1 <= {{2{stage1_out_src1_w[31]}}, stage1_out_src1_w[31:16]};
				stage2_in_mul2_src2 <= {18{1'b0}};
				stage2_in_mul3_src0 <= {{2{stage1_out_src0_w[31]}}, stage1_out_src0_w[31:16]};
				stage2_in_mul3_src1 <= {{2{stage1_out_src1_w[31]}}, stage1_out_src1_w[31:16]};
				stage2_in_mul3_src2 <= {{2{stage1_out_src2_w[31]}}, stage1_out_src2_w[31:16]};
			end
		endcase
	end
	
	jelly_pipeline_ff
			#(
				.WIDTH		(2+1+1+6+1+1+(18*12)),
				.REG		(STAGE1_REG),
				.INIT		({(2+1+1+6+1+1+(18*12)){1'bx}})
			)
		i_pipeline_ff_stage2
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	(
								{
									stage2_in_size,
									stage2_in_addsub,
									stage2_in_feedback,
									stage2_in_shift,
									stage2_in_clip,
									stage2_in_dst_sign,
									stage2_in_mul0_src0,
									stage2_in_mul0_src1,
									stage2_in_mul0_src2,
									stage2_in_mul1_src0,
									stage2_in_mul1_src1,
									stage2_in_mul1_src2,
									stage2_in_mul2_src0,
									stage2_in_mul2_src1,
									stage2_in_mul2_src2,
									stage2_in_mul3_src0,
									stage2_in_mul3_src1,
									stage2_in_mul3_src2
								}
							),
				.out_data	(
								{
									stage2_out_size,
									stage2_out_addsub,
									stage2_out_feedback,
									stage2_out_shift,
									stage2_out_clip,
									stage2_out_dst_sign,
									stage2_out_mul0_src0,
									stage2_out_mul0_src1,
									stage2_out_mul0_src2,
									stage2_out_mul1_src0,
									stage2_out_mul1_src1,
									stage2_out_mul1_src2,
									stage2_out_mul2_src0,
									stage2_out_mul2_src1,
									stage2_out_mul2_src2,
									stage2_out_mul3_src0,
									stage2_out_mul3_src1,
									stage2_out_mul3_src2
								}
							)
			);
	
	
	// -----------------------------------------
	//  multiply (stage 3-5)
	// -----------------------------------------

	wire			[1:0]	stage5_out_size;
	wire			[5:0]	stage5_out_shift;
	wire					stage5_out_clip;
	wire					stage5_out_dst_sign;
	wire	[47:0]			stage5_out_data0;
	wire	[47:0]			stage5_out_data1;
	wire	[47:0]			stage5_out_data2;
	wire	[47:0]			stage5_out_data3;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(2+6+1+1),
				.REG		(STAGE3_REG+STAGE4_REG+STAGE5_REG),
				.INIT		({(2+6+1+1){1'bx}})
			)
		i_pipeline_ff_stage5
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	(
								{
									stage2_out_size,
									stage2_out_shift,
									stage2_out_clip,
									stage2_out_dst_sign
								}
							),
				.out_data	(
								{
									stage5_out_size,
									stage5_out_shift,
									stage5_out_clip,
									stage5_out_dst_sign
								}
							)
			);
	
	jelly_mac18x18
			#(
				.INPUT_REG 		(STAGE3_REG),
				.MUL_REG   		(STAGE4_REG),	
				.OUTPUT_REG		(STAGE5_REG)
			)
		i_mac18x18_0
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.op_addsub		(stage2_out_addsub),
				.op_feedback	(stage2_out_feedback),
			
				.in_data0		(stage2_out_mul0_src0),
				.in_data1		(stage2_out_mul0_src1),
				.in_data2		({{30{stage2_out_mul0_src2[17]}}, stage2_out_mul0_src2}),
				
				.out_data		(stage5_out_data0)
			);
	
	jelly_mac18x18
			#(
				.INPUT_REG 		(STAGE3_REG),
				.MUL_REG   		(STAGE4_REG),	
				.OUTPUT_REG		(STAGE5_REG)
			)
		i_mac18x18_1
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.op_addsub		(stage2_out_addsub),
				.op_feedback	(stage2_out_feedback),
				
				.in_data0		(stage2_out_mul1_src0),
				.in_data1		(stage2_out_mul1_src1),
				.in_data2		({{30{stage2_out_mul1_src2[17]}}, stage2_out_mul1_src2}),
				
				.out_data		(stage5_out_data1)
			);
	
	jelly_mac18x18
			#(
				.INPUT_REG 		(STAGE3_REG),
				.MUL_REG   		(STAGE4_REG),	
				.OUTPUT_REG		(STAGE5_REG)
			)
		i_mac18x18_2
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.op_addsub		(stage2_out_addsub),
				.op_feedback	(stage2_out_feedback),
				
				.in_data0		(stage2_out_mul2_src0),
				.in_data1		(stage2_out_mul2_src1),
				.in_data2		({{30{stage2_out_mul2_src2[17]}}, stage2_out_mul2_src2}),
				
				.out_data		(stage5_out_data2)
			);
	
	jelly_mac18x18
			#(
				.INPUT_REG 		(STAGE3_REG),
				.MUL_REG   		(STAGE4_REG),	
				.OUTPUT_REG		(STAGE5_REG)
			)
		i_mac18x18_3
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.op_addsub		(stage2_out_addsub),
				.op_feedback	(stage2_out_feedback),
				
				.in_data0		(stage2_out_mul3_src0),
				.in_data1		(stage2_out_mul3_src1),
				.in_data2		({{30{stage2_out_mul3_src2[17]}}, stage2_out_mul3_src2}),
				
				.out_data		(stage5_out_data3)
			);
	
	
	
	assign out_dst_data = stage5_out_data0 | stage5_out_data1 | stage5_out_data2 | stage5_out_data3;
	
	// multiply destination
	/*
	reg						reg_mul_dst_valid;
	reg						reg_mul_dst_mac;
	reg		signed	[35:0]	reg_mul0_dst;
	reg		signed	[35:0]	reg_mul1_dst;
	reg		signed	[35:0]	reg_mul2_dst;
	reg		signed	[35:0]	reg_mul3_dst;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_mul_dst_valid <= 1'b0;
			reg_mul_dst_mac   <= 1'bx;
			reg_mul0_dst      <= {36{1'bx}};
			reg_mul1_dst      <= {36{1'bx}};
			reg_mul2_dst      <= {36{1'bx}};
			reg_mul3_dst      <= {36{1'bx}};
		end
		else begin
			reg_mul_dst_valid <= reg_mul_src_valid;
			reg_mul_dst_mac   <= reg_mul_src_mac;
			reg_mul0_dst      <= reg_mul0_src0 * reg_mul0_src1;
			reg_mul1_dst      <= reg_mul1_src0 * reg_mul1_src1;
			reg_mul2_dst      <= reg_mul2_src0 * reg_mul2_src1;
			reg_mul3_dst      <= reg_mul3_src0 * reg_mul3_src1;
		end
	end

	
	reg						reg_mul_dst_valid;
	reg						reg_mul_dst_mac;
	reg		signed	[35:0]	reg_mul0_dst;
	reg		signed	[35:0]	reg_mul1_dst;
	reg		signed	[35:0]	reg_mul2_dst;
	reg		signed	[35:0]	reg_mul3_dst;
	
	
	// mac
	reg						reg_mac_valid;
	reg		signed	[47:0]	reg_mac0_data;
	reg		signed	[47:0]	reg_mac1_data;
	reg		signed	[47:0]	reg_mac2_data;
	reg		signed	[47:0]	reg_mac3_data;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_mac_valid <= 1'b0;
			reg_mac0_data <= {48{1'bx}};
			reg_mac1_data <= {48{1'bx}};
			reg_mac2_data <= {48{1'bx}};
			reg_mac3_data <= {48{1'bx}};
		end
		else begin
			reg_mac_valid <= reg_mul_dst_valid;
			reg_mac0_data <= reg_mul_dst_mac ? reg_mac0_data + reg_mul0_dst : reg_mul0_dst;
			reg_mac1_data <= reg_mul_dst_mac ? reg_mac1_data + reg_mul1_dst : reg_mul1_dst;
			reg_mac2_data <= reg_mul_dst_mac ? reg_mac2_data + reg_mul2_dst : reg_mul2_dst;
			reg_mac3_data <= reg_mul_dst_mac ? reg_mac3_data + reg_mul3_dst : reg_mul3_dst;
		end
	end
	
	assign out_valid = reg_mac_valid;
	assign out_data  = reg_mac0_data | reg_mac1_data | reg_mac2_data | reg_mac3_data;
	*/


//	assign out_valid = reg_mul_src_valid;
//	assign out_data  = mac_out_data0 | mac_out_data1 | mac_out_data2 | mac_out_data3;
	
	/*
	reg		signed	[63:0]	reg_mac0_data;
	reg		signed	[63:0]	reg_mac1_data;
	reg		signed	[63:0]	reg_mac2_data;
	reg		signed	[63:0]	reg_mac3_data;
	reg		signed	[63:0]	reg_mac01_data;
	reg		signed	[63:0]	reg_mac23_data;
	reg		signed	[63:0]	reg_mac4_data;
	reg		signed	[63:0]	reg_mac5_data;
	reg		signed	[63:0]	reg_mac6_data;
	reg		signed	[63:0]	reg_mac7_data;
	reg		signed	[63:0]	reg_mac8_data;
	reg		signed	[63:0]	reg_mac9_data;
	always @( posedge clk ) begin
		reg_mac0_data  <= mac_out_data0;
		reg_mac1_data  <= mac_out_data1;
		reg_mac2_data  <= mac_out_data2;
		reg_mac3_data  <= mac_out_data3;
		reg_mac01_data <= (reg_mac0_data <<  0) + (reg_mac1_data << 16);
		reg_mac23_data <= (reg_mac2_data << 16) + (reg_mac3_data << 32);
		reg_mac4_data  <= reg_mac01_data;
		reg_mac5_data  <= reg_mac23_data;
		reg_mac6_data  <= reg_mac4_data + reg_mac5_data;
		reg_mac7_data  <= reg_mac6_data;
		reg_mac8_data  <= reg_mac7_data;
		reg_mac9_data  <= reg_mac8_data;
	end
	*/
//	assign out_data  = reg_mac9_data;
	
	
endmodule

