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
module jelly_vector_addr
		#(
			parameter	PORT_NUM    = 2,
			parameter	REG_NUM     = 8,
			parameter	INDEX_WIDTH = 3,
			parameter	WE_WIDTH    = 1,
			parameter	ADDR_WIDTH  = 9,
			parameter	DATA_WIDTH  = 32,
			
			parameter	STAGE0_REG = 1,
			parameter	STAGE1_REG = 1,
			parameter	STAGE2_REG = 1,
			parameter	STAGE3_REG = 1,
			parameter	STAGE4_REG = 1,
			parameter	STAGE5_REG = 1,
			parameter	STAGE6_REG = 1,
			parameter	STAGE7_REG = 1,
			parameter	STAGE8_REG = 1
		)
		(
			// system
			input	wire				clk,
			input	wire				cke,
			input	wire				reset,
			
			// input
			input	wire				in_valid,
			input	wire				in_start,
			input	wire	[31:0]		in_addr_base,
			input	wire	[31:0]		in_addr_step,
			input	wire	[31:0]		in_imm_base,
			input	wire	[31:0]		in_imm_step,
			input	wire	[4:0]		in_shift,
			input	wire				in_reverse,
			input	wire				in_reg0_en,
			input	wire				in_reg1_en,
			
			// output
			output	wire	[31:0]		out_data,
			
			// reg port0
			output	wire				port0_valid,
			output	wire				port0_we,
			output	wire	[15:0]		port0_addr,
			output	wire	[31:0]		port0_din,
			input	wire	[31:0]		port0_dout,

			// reg port1
			output	wire				port1_valid,
			output	wire				port1_we,
			output	wire	[15:0]		port1_addr,
			output	wire	[31:0]		port1_din,
			input	wire	[31:0]		port1_dout
		);
	
	// stage 0
	reg					stage0_out_valid;
	reg		[31:0]		stage0_out_addr;
	reg		[31:0]		stage0_out_imm;
	reg		[4:0]		stage0_out_shift;
	reg					stage0_out_reverse;
	reg					stage0_out_reg0_en;
	reg					stage0_out_reg1_en;
	always @(posedge clk) begin
		if ( reset ) begin
			stage0_out_valid   <= 1'b0;
			stage0_out_addr    <= {32{1'bx}};
			stage0_out_imm     <= {32{1'bx}};
			stage0_out_shift   <= {5{1'bx}};
			stage0_out_reverse <= 1'bx;
			stage0_out_reg0_en <= 1'bx;
			stage0_out_reg1_en <= 1'bx;
		end
		else begin
			if ( cke ) begin
				stage0_out_valid   <= in_valid;
				stage0_out_addr    <= in_start ? in_addr_base : stage0_out_addr + in_addr_step;
				stage0_out_imm     <= in_start ? in_imm_base  : stage0_out_imm  + in_imm_step;
				stage0_out_shift   <= in_shift;
				stage0_out_reverse <= in_reverse;
				stage0_out_reg0_en <= in_reg0_en;
				stage0_out_reg1_en <= in_reg1_en;
			end
		end
	end
	
	
	// register stage (1-9)
	wire			stage9_out_valid;
	wire	[31:0]	stage9_out_addr;
	wire	[31:0]	stage9_out_imm;
	wire	[4:0]	stage9_out_shift;
	wire			stage9_out_reverse;
	wire			stage9_out_reg0_en;
	wire			stage9_out_reg1_en;
	wire	[31:0]	stage9_out_dout;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(1+32+32+5+1+1+1),
				.REG		(9),
				.INIT		({1'b0, {(32+32+5+1+1+1){1'bx}}})
			)
		i_pipeline_ff_stage9
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	({stage0_out_valid, stage0_out_addr, stage0_out_imm, stage0_out_shift, stage0_out_reverse, stage0_out_reg0_en, stage0_out_reg1_en}),
				.out_data	({stage9_out_valid, stage9_out_addr, stage9_out_imm, stage9_out_shift, stage9_out_reverse, stage9_out_reg0_en, stage9_out_reg1_en})		
			);
	
	
	// register
	assign port0_valid = stage0_out_valid & stage0_out_reg0_en;
	assign port0_we    = 1'b0;
	assign port0_din   = 32'd0;
	assign port0_addr  = stage0_out_addr[31:16];
	
	assign stage9_out_dout  = port0_dout;
	
	
	// stage 10
	wire			stage10_in_valid;
	wire	[31:0]	stage10_in_addr;
	wire	[31:0]	stage10_in_imm;
	wire	[4:0]	stage10_in_shift;
	wire			stage10_in_reverse;
	wire			stage10_in_reg1_en;
	
	wire			stage10_out_valid;
	wire	[31:0]	stage10_out_addr;
	wire	[31:0]	stage10_out_imm;
	wire	[4:0]	stage10_out_shift;
	wire			stage10_out_reverse;
	wire			stage10_out_reg1_en;
	
	assign stage10_in_valid   = stage9_out_valid;
	assign stage10_in_addr    = stage9_out_reg0_en ? stage9_out_dout : stage9_out_addr;
	assign stage10_in_imm     = stage9_out_imm;
	assign stage10_in_shift   = stage9_out_shift;
	assign stage10_in_reverse = stage9_out_reverse;
	assign stage10_in_reg1_en = stage9_out_reg1_en;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(1+32+32+5+1+1),
				.REG		(1),
				.INIT		({1'b0, {(32+32+5+1+1){1'bx}}})
			)
		i_pipeline_ff_stage10
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	({stage10_in_valid,  stage10_in_addr,  stage10_in_imm,  stage10_in_shift,  stage10_in_reverse,  stage10_in_reg1_en}),
				.out_data	({stage10_out_valid, stage10_out_addr, stage10_out_imm, stage10_out_shift, stage10_out_reverse, stage10_out_reg1_en})		
			);
	
	// stage 11
	wire			stage11_in_valid;
	wire	[31:0]	stage11_in_addr;
	wire	[31:0]	stage11_in_imm;
	wire			stage11_in_reverse;
	wire			stage11_in_reg1_en;
	
	wire			stage11_out_valid;
	wire	[31:0]	stage11_out_addr;
	wire	[31:0]	stage11_out_imm;
	wire			stage11_out_reverse;
	wire			stage11_out_reg1_en;
	
	assign stage11_in_valid   = stage10_out_valid;
	assign stage11_in_addr    = (stage10_out_addr << stage10_out_shift);
	assign stage11_in_imm     = stage10_out_imm;
	assign stage11_in_reverse = stage10_out_reverse;
	assign stage11_in_reg1_en = stage10_out_reg1_en;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(1+32+32+1+1),
				.REG		(1),
				.INIT		({1'b0, {(32+32+1+1){1'bx}}})
			)
		i_pipeline_ff_stage11
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	({stage11_in_valid,  stage11_in_addr,  stage11_in_imm,  stage11_in_reverse,  stage11_in_reg1_en}),
				.out_data	({stage11_out_valid, stage11_out_addr, stage11_out_imm, stage11_out_reverse, stage11_out_reg1_en})		
			);
	
	// stage 12
	wire			stage12_in_valid;
	wire	[31:0]	stage12_in_addr;
	wire			stage12_in_reverse;
	wire			stage12_in_reg1_en;
	
	wire			stage12_out_valid;
	wire	[31:0]	stage12_out_addr;
	wire			stage12_out_reverse;
	wire			stage12_out_reg1_en;
	
	assign stage12_in_valid   = stage11_out_valid;
	assign stage12_in_addr    = stage11_out_addr + stage11_out_imm;
	assign stage12_in_reverse = stage11_out_reverse;
	assign stage12_in_reg1_en = stage11_out_reg1_en;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(1+32+1+1),
				.REG		(1),
				.INIT		({1'b0, {(32+1+1){1'bx}}})
			)
		i_pipeline_ff_stage12
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	({stage12_in_valid,  stage12_in_addr,  stage12_in_reverse,  stage12_in_reg1_en}),
				.out_data	({stage12_out_valid, stage12_out_addr, stage12_out_reverse, stage12_out_reg1_en})		
			);
	
	// stage 13-21
	wire	[31:0]	stage21_out_data;
	wire			stage21_out_reg1_en;
	wire	[31:0]	stage21_out_dout;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(32+1),
				.REG		(9),
				.INIT		({(32+1){1'bx}})
			)
		i_pipeline_ff_stage21
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	({stage12_out_addr, stage12_out_reg1_en}),
				.out_data	({stage21_out_data, stage21_out_reg1_en})
			);
	
	// register
	assign port1_valid  = stage12_out_valid & stage12_out_reg1_en;
	assign port1_we     = 1'b0;
	assign port1_din    = 32'd0;
	
		jelly_reverse
			#(
				.WIDTH		(16)
			)
		i_reverse
		(
			.reverse		(stage12_out_reverse),
			
			.din			(stage12_out_addr[31:15]),
			.dout			(port1_addr)
		);



	
	
	assign stage21_out_dout = port1_dout;
	
	
	// stage 22
	wire	[31:0]	stage22_in_data;
	wire	[31:0]	stage22_out_data;
	
	assign stage22_in_data = stage21_out_reg1_en ? stage21_out_dout : stage21_out_data;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(32),
				.REG		(1),
				.INIT		({32{1'bx}})
			)
		i_pipeline_ff_stage22
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	(stage22_in_data),
				.out_data	(stage22_out_data)		
			);
	
	assign out_data = stage22_out_data;
	
endmodule


`default_nettype wire


// end of file
