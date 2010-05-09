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
module jelly_vector_alu
		#(
			parameter	STAGE0_REG = 1
		)
		(
			// system
			input	wire				reset,
			input	wire				clk,
			input	wire				cke,
			input	wire				endian,
			
			// control
			input	wire	[15:0]		cmd_length,
			input	wire				cmd_valid,
			output	wire				cmd_ready,
			output	wire	[5:0]		cmd_exec_num,
			
			input	wire	[31:0]		src0_addr_base,
			input	wire	[31:0]		src0_addr_step,
			input	wire	[31:0]		src0_imm_base,
			input	wire	[31:0]		src0_imm_step,
			input	wire	[4:0]		src0_shift,
			input	wire				src0_reverse,
			input	wire				src0_reg0_en,
			input	wire				src0_reg1_en,
			
			input	wire	[31:0]		src1_addr_base,
			input	wire	[31:0]		src1_addr_step,
			input	wire	[31:0]		src1_imm_base,
			input	wire	[31:0]		src1_imm_step,
			input	wire	[4:0]		src1_shift,
			input	wire				src1_reverse,
			input	wire				src1_reg0_en,
			input	wire				src1_reg1_en,
			
			input	wire	[31:0]		dst_addr_base,
			input	wire	[31:0]		dst_addr_step,
			input	wire	[31:0]		dst_imm_base,
			input	wire	[31:0]		dst_imm_step,
			input	wire	[4:0]		dst_shift,
			input	wire				dst_reverse,
			input	wire				dst_reg0_en,
			
			input	wire	[7:0]		alu_op,
			input	wire	[1:0]		alu_size,
			input	wire				alu_src0_sign,
			input	wire				alu_src1_sign,
			
			output	wire				gpvr_src00_valid,
			output	wire				gpvr_src00_we,
			output	wire	[15:0]		gpvr_src00_addr,
			output	wire	[31:0]		gpvr_src00_din,
			output	wire	[31:0]		gpvr_src00_dout,
			
			output	wire				gpvr_src01_valid,
			output	wire				gpvr_src01_we,
			output	wire	[15:0]		gpvr_src01_addr,
			output	wire	[31:0]		gpvr_src01_din,
			output	wire	[31:0]		gpvr_src01_dout,
			
			output	wire				gpvr_src10_valid,
			output	wire				gpvr_src10_we,
			output	wire	[15:0]		gpvr_src10_addr,
			output	wire	[31:0]		gpvr_src10_din,
			output	wire	[31:0]		gpvr_src10_dout,
			
			output	wire				gpvr_src11_valid,
			output	wire				gpvr_src11_we,
			output	wire	[15:0]		gpvr_src11_addr,
			output	wire	[31:0]		gpvr_src11_din,
			output	wire	[31:0]		gpvr_src11_dout,
			
			output	wire				gpvr_dst0_valid,
			output	wire				gpvr_dst0_we,
			output	wire	[15:0]		gpvr_dst0_addr,
			output	wire	[31:0]		gpvr_dst0_din,
			output	wire	[31:0]		gpvr_dst0_dout,
			
			output	wire				gpvr_dst1_valid,
			output	wire				gpvr_dst1_we,
			output	wire	[15:0]		gpvr_dst1_addr,
			output	wire	[31:0]		gpvr_dst1_din,
			output	wire	[31:0]		gpvr_dst1_dout
		);
	
	
	// ---------------------------------------------------------
	//  Control stage
	// ---------------------------------------------------------
	
	reg					ctrl_busy;
	reg		[15:0]		ctrl_counter;
	
	reg					ctrl_out_valid;
	reg					ctrl_out_first;
	reg					ctrl_out_last;
	
	reg		[31:0]		ctrl_out_src0_addr_base;
	reg		[31:0]		ctrl_out_src0_addr_step;
	reg		[31:0]		ctrl_out_src0_imm_base;
	reg		[31:0]		ctrl_out_src0_imm_step;
	reg		[4:0]		ctrl_out_src0_shift;
	reg					ctrl_out_src0_reverse;
	reg					ctrl_out_src0_reg0_en;
	reg					ctrl_out_src0_reg1_en;
	
	reg		[31:0]		ctrl_out_src1_addr_base;
	reg		[31:0]		ctrl_out_src1_addr_step;
	reg		[31:0]		ctrl_out_src1_imm_base;
	reg		[31:0]		ctrl_out_src1_imm_step;
	reg		[4:0]		ctrl_out_src1_shift;
	reg					ctrl_out_src1_reverse;
	reg					ctrl_out_src1_reg0_en;
	reg					ctrl_out_src1_reg1_en;
	
	reg		[31:0]		ctrl_out_dst_addr_base;
	reg		[31:0]		ctrl_out_dst_addr_step;
	reg		[31:0]		ctrl_out_dst_imm_base;
	reg		[31:0]		ctrl_out_dst_imm_step;
	reg		[4:0]		ctrl_out_dst_shift;
	reg					ctrl_out_dst_reverse;
	reg					ctrl_out_dst_reg0_en;
	
	reg		[7:0]		ctrl_out_alu_op;
	reg		[1:0]		ctrl_out_alu_size;
	reg					ctrl_out_alu_src0_sign;
	reg					ctrl_out_alu_src1_sign;
	
	always @(posedge clk) begin
		if ( reset ) begin
			ctrl_counter   <= 0;
			ctrl_out_valid <= 1'b0;
		end
		else begin
			if ( cke ) begin
				if ( cmd_ready & cmd_ready ) begin
					// start
					ctrl_counter   <= cmd_length;
					ctrl_out_valid <= 1'b1;
					ctrl_out_first <= 1'b1;
					ctrl_out_last  <= (cmd_length == 0);
					
					ctrl_out_src0_addr_base <= src0_addr_base;
					ctrl_out_src0_addr_step <= src0_addr_step;
					ctrl_out_src0_imm_base  <= src0_imm_base;
					ctrl_out_src0_imm_step  <= src0_imm_step;
					ctrl_out_src0_shift     <= src0_shift;
					ctrl_out_src0_reverse   <= src0_reverse;
					ctrl_out_src0_reg0_en   <= src0_reg0_en;
					ctrl_out_src0_reg1_en   <= src0_reg1_en;
                                                 
					ctrl_out_src1_addr_base <= src1_addr_base;
					ctrl_out_src1_addr_step <= src1_addr_step;
					ctrl_out_src1_imm_base  <= src1_imm_base;
					ctrl_out_src1_imm_step  <= src1_imm_step;
					ctrl_out_src1_shift     <= src1_shift;
					ctrl_out_src1_reverse   <= src1_reverse;
					ctrl_out_src1_reg0_en   <= src1_reg0_en;
					ctrl_out_src1_reg1_en   <= src1_reg1_en;
                                                 
					ctrl_out_dst_addr_base  <= dst_addr_base;
					ctrl_out_dst_addr_step  <= dst_addr_step;
					ctrl_out_dst_imm_base   <= dst_imm_base;
					ctrl_out_dst_imm_step   <= dst_imm_step;
					ctrl_out_dst_shift      <= dst_shift;
					ctrl_out_dst_reverse    <= dst_reverse;
					ctrl_out_dst_reg0_en    <= dst_reg0_en;
                                                 
					ctrl_out_alu_op         <= alu_op;
					ctrl_out_alu_size       <= alu_size;
					ctrl_out_alu_src0_sign  <= alu_src0_sign;
					ctrl_out_alu_src1_sign  <= alu_src1_sign;
				end                           
				else begin
					if ( ctrl_out_valid ) begin
						ctrl_out_valid <= !ctrl_out_last;
					end
					
					ctrl_counter   <= ctrl_counter - 1;
					ctrl_out_first <= 1'b0;
					ctrl_out_last  <= (ctrl_counter == 0);
				end
			end
		end
	end
	
	assign cmd_ready = (!ctrl_out_valid || ctrl_out_last);
	
	
	
	// ---------------------------------------------------------
	//  Read Vector Register stage (23 pipeline)
	// ---------------------------------------------------------
	
	wire				rreg_out_valid;
	wire	[7:0]		rreg_out_alu_op;
	wire	[1:0]		rreg_out_alu_size;
	wire				rreg_out_alu_src0_sign;
	wire				rreg_out_alu_src1_sign;
	wire	[31:0]		rreg_out_src0_data;
	wire	[31:0]		rreg_out_src1_data;
	wire	[31:0]		rreg_out_dst_addr;
	
	// through
	jelly_pipeline_ff
			#(
				.WIDTH		(1+8+2+1+1),
				.REG		(23),
				.INIT		({1'b0, {(8+2+1+1){1'bx}}})
			)
		i_pipeline_ff_rreg
			(
				.clk		(clk),
				.cke		(cke),
				.reset		(reset),
				
				.in_data	({ctrl_out_valid, ctrl_out_alu_op, ctrl_out_alu_size, ctrl_out_alu_src0_sign, ctrl_out_alu_src1_sign}),
				.out_data	({rreg_out_valid, rreg_out_alu_op, rreg_out_alu_size, rreg_out_alu_src0_sign, rreg_out_alu_src1_sign})		
			);
	
	// sorce0 reg read
	jelly_vector_addr
		i_vector_addr_src0
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
								
				.in_valid		(ctrl_out_valid),
				.in_start		(ctrl_out_first),
				.in_addr_base	(ctrl_out_src0_addr_base),
				.in_addr_step	(ctrl_out_src0_addr_step),
				.in_imm_base	(ctrl_out_src0_imm_base),
				.in_imm_step	(ctrl_out_src0_imm_step),
				.in_shift		(ctrl_out_src0_shift),
				.in_reverse		(ctrl_out_src0_reverse),
				.in_reg0_en		(ctrl_out_src0_reg0_en),
				.in_reg1_en		(ctrl_out_src0_reg1_en),
								               
				.out_data		(rreg_out_src0_data),
								
				.port0_valid	(gpvr_src00_valid),
				.port0_we		(gpvr_src00_we),
				.port0_addr		(gpvr_src00_addr),
				.port0_din		(gpvr_src00_din),
				.port0_dout		(gpvr_src00_dout),
								
				.port1_valid	(gpvr_src01_valid),
				.port1_we		(gpvr_src01_we),
				.port1_addr		(gpvr_src01_addr),
				.port1_din		(gpvr_src01_din),
				.port1_dout		(gpvr_src01_dout)
			);

	// sorce1 reg read
	jelly_vector_addr
		i_vector_addr_src1
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
								
				.in_valid		(ctrl_out_valid),
				.in_start		(ctrl_out_first),
				.in_addr_base	(ctrl_out_src1_addr_base),
				.in_addr_step	(ctrl_out_src1_addr_step),
				.in_imm_base	(ctrl_out_src1_imm_base),
				.in_imm_step	(ctrl_out_src1_imm_step),
				.in_shift		(ctrl_out_src1_shift),
				.in_reverse		(ctrl_out_src1_reverse),
				.in_reg0_en		(ctrl_out_src1_reg0_en),
				.in_reg1_en		(ctrl_out_src1_reg1_en),
				
				.out_data		(rreg_out_src1_data),
				
				.port0_valid	(gpvr_src10_valid),
				.port0_we		(gpvr_src10_we),
				.port0_addr		(gpvr_src10_addr),
				.port0_din		(gpvr_src10_din),
				.port0_dout		(gpvr_src10_dout),
				
				.port1_valid	(gpvr_src11_valid),
				.port1_we		(gpvr_src11_we),
				.port1_addr		(gpvr_src11_addr),
				.port1_din		(gpvr_src11_din),
				.port1_dout		(gpvr_src11_dout)
			);
	
	jelly_vector_addr
		i_vector_addr_dst
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
								
				.in_valid		(ctrl_out_valid),
				.in_start		(ctrl_out_first),
				.in_addr_base	(ctrl_out_dst_addr_base),
				.in_addr_step	(ctrl_out_dst_addr_step),
				.in_imm_base	(ctrl_out_dst_imm_base),
				.in_imm_step	(ctrl_out_dst_imm_step),
				.in_shift		(ctrl_out_dst_shift),
				.in_reverse		(ctrl_out_dst_reverse),
				.in_reg0_en		(ctrl_out_dst_reg0_en),
				.in_reg1_en		(1'b0),
				
				.out_data		(rreg_out_dst_addr),
				
				.port0_valid	(gpvr_dst0_valid),
				.port0_we		(gpvr_dst0_we),
				.port0_addr		(gpvr_dst0_addr),
				.port0_din		(gpvr_dst0_din),
				.port0_dout		(gpvr_dst0_dout),
				
				.port1_valid	(),
				.port1_we		(),
				.port1_addr		(),
				.port1_din		(),
				.port1_dout		(32'd0)
			);
	
	// ---------------------------------------------------------
	//  SIMD ALU stage (23 pipeline)
	// ---------------------------------------------------------
	
	jelly_vector_simd
		i_vector_simd
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.in_valid		(rreg_out_valid),
				.in_op			(rreg_out_alu_op),
				.in_size		(rreg_out_alu_size),
				.in_src0_sign	(rreg_out_alu_src0_sign),
				.in_src1_sign	(rreg_out_alu_src1_sign),
				.in_dst_sign	(1),
				.in_src0_data	(rreg_out_src0_data),
				.in_src1_data	(rreg_out_src1_data),
				
				.out_dst_data	()
		);
	
	
	
endmodule


`default_nettype wire


// end of file
