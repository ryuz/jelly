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
module jelly_simd_mul
		#(
			parameter 							EXT_WIDTH  = 1
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire						in_valid,
			input	wire						in_signed,
			input	wire	[1:0]				in_size,
			input	wire						in_mac,
			input	wire	[31:0]				in_data0,
			input	wire	[31:0]				in_data1,
			
			output	wire	[31:0]				out_valid,
			output	wire	[63:0]				out_data
		);
	
	// input
	reg						reg_in_valid;
	reg						reg_in_signed;
	reg		[1:0]			reg_in_size;
	reg						reg_in_mac;
	reg		[31:0]			reg_in_data0;
	reg		[31:0]			reg_in_data1;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_in_valid  <= 1'b0;
			reg_in_signed <= 1'bx;
			reg_in_size   <= {2{1'bx}};
			reg_in_mac    <= 1'bx;
			reg_in_data0  <= {32{1'bx}};
			reg_in_data1  <= {32{1'bx}};
		end
		else begin
			reg_in_valid  <= in_valid;
			reg_in_signed <= in_signed;
			reg_in_size   <= in_size;
			reg_in_mac    <= in_mac; 
			reg_in_data0  <= in_data0;
			reg_in_data1  <= in_data1;
		end                
	end
	
	// simd split
	reg						reg_split_valid;
	reg						reg_split_signed;
	reg				[1:0]	reg_split_size;
	reg						reg_split_mac;
	reg		signed [32:0]	reg_split_data0_b0;
	reg		signed [32:0]	reg_split_data0_b1;
	reg		signed [32:0]	reg_split_data0_b2;
	reg		signed [32:0]	reg_split_data0_b3;
	reg		signed [32:0]	reg_split_data0_h0;
	reg		signed [32:0]	reg_split_data0_h1;
	reg		signed [32:0]	reg_split_data0_w;
	reg		signed [32:0]	reg_split_data1_b0;
	reg		signed [32:0]	reg_split_data1_b1;
	reg		signed [32:0]	reg_split_data1_b2;
	reg		signed [32:0]	reg_split_data1_b3;
	reg		signed [32:0]	reg_split_data1_h0;
	reg		signed [32:0]	reg_split_data1_h1;
	reg		signed [32:0]	reg_split_data1_w;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_split_valid    <= 1'b0;
			reg_split_signed   <= 1'bx;
			reg_split_size     <= {2{1'bx}};
			reg_split_mac      <= 1'bx;
			reg_split_data0_b0 <= {33{1'bx}};
			reg_split_data0_b1 <= {33{1'bx}};
			reg_split_data0_b2 <= {33{1'bx}};
			reg_split_data0_b3 <= {33{1'bx}};
			reg_split_data0_h0 <= {33{1'bx}};
			reg_split_data0_h1 <= {33{1'bx}};
			reg_split_data0_w  <= {33{1'bx}};
			reg_split_data1_b0 <= {33{1'bx}};
			reg_split_data1_b1 <= {33{1'bx}};
			reg_split_data1_b2 <= {33{1'bx}};
			reg_split_data1_b3 <= {33{1'bx}};
			reg_split_data1_h0 <= {33{1'bx}};
			reg_split_data1_h1 <= {33{1'bx}};
			reg_split_data1_w  <= {33{1'bx}};
		end
		else begin
			reg_split_valid    <= reg_in_valid;
			reg_split_signed   <= reg_in_signed;
			reg_split_size     <= reg_in_size;
			reg_split_mac      <= reg_in_mac;
			reg_split_data0_b0 <= {(reg_in_signed ? {25{reg_in_data0[7]}}  : {25{1'b0}}), reg_in_data0[7:0]};
			reg_split_data0_b1 <= {(reg_in_signed ? {25{reg_in_data0[15]}} : {25{1'b0}}), reg_in_data0[15:8]};
			reg_split_data0_b2 <= {(reg_in_signed ? {25{reg_in_data0[23]}} : {25{1'b0}}), reg_in_data0[23:16]};
			reg_split_data0_b3 <= {(reg_in_signed ? {25{reg_in_data0[31]}} : {25{1'b0}}), reg_in_data0[31:24]};
			reg_split_data0_h0 <= {(reg_in_signed ? {17{reg_in_data0[15]}} : {17{1'b0}}), reg_in_data0[15:0]};
			reg_split_data0_h1 <= {(reg_in_signed ? {17{reg_in_data0[31]}} : {17{1'b0}}), reg_in_data0[31:16]};
			reg_split_data0_w  <= {(reg_in_signed ? {1{reg_in_data0[31]}}  : {1{1'b0}}),  reg_in_data0[31:0]};
			reg_split_data1_b0 <= {(reg_in_signed ? {25{reg_in_data1[7]}}  : {25{1'b0}}), reg_in_data1[7:0]};
			reg_split_data1_b1 <= {(reg_in_signed ? {25{reg_in_data1[15]}} : {25{1'b0}}), reg_in_data1[15:8]};
			reg_split_data1_b2 <= {(reg_in_signed ? {25{reg_in_data1[23]}} : {25{1'b0}}), reg_in_data1[23:16]};
			reg_split_data1_b3 <= {(reg_in_signed ? {25{reg_in_data1[31]}} : {25{1'b0}}), reg_in_data1[31:24]};
			reg_split_data1_h0 <= {(reg_in_signed ? {17{reg_in_data1[15]}} : {17{1'b0}}), reg_in_data1[15:0]};
			reg_split_data1_h1 <= {(reg_in_signed ? {17{reg_in_data1[31]}} : {17{1'b0}}), reg_in_data1[31:16]};
			reg_split_data1_w  <= {(reg_in_signed ? {1{reg_in_data1[31]}}  : {1{1'b0}}),  reg_in_data1[31:0]};
		end                
	end
		
	// multiply source
	reg						reg_mul_src_valid;
	reg						reg_mul_src_mac;
	reg		signed	[17:0]	reg_mul0_src0;
	reg		signed	[17:0]	reg_mul0_src1;
	reg		signed	[17:0]	reg_mul1_src0;
	reg		signed	[17:0]	reg_mul1_src1;
	reg		signed	[17:0]	reg_mul2_src0;
	reg		signed	[17:0]	reg_mul2_src1;
	reg		signed	[17:0]	reg_mul3_src0;
	reg		signed	[17:0]	reg_mul3_src1;
	always @( posedge clk ) begin
		if ( reset ) begin
			reg_mul_src_valid <= 1'b0;
			reg_mul_src_mac   <= 1'bx;
			reg_mul0_src0     <= {18{1'bx}};
			reg_mul0_src1     <= {18{1'bx}};
			reg_mul1_src0     <= {18{1'bx}};
			reg_mul1_src1     <= {18{1'bx}};
			reg_mul2_src0     <= {18{1'bx}};
			reg_mul2_src1     <= {18{1'bx}};
			reg_mul3_src0     <= {18{1'bx}};
			reg_mul3_src1     <= {18{1'bx}};
		end
		else begin
			reg_mul_src_valid <= reg_split_valid;
			reg_mul_src_mac   <= reg_split_mac;
			
			case ( reg_in_size )
			2'b00:	// 8bit
				begin
					reg_mul0_src0 <= reg_split_data0_b0;
					reg_mul0_src1 <= reg_split_data1_b0;
					reg_mul1_src0 <= reg_split_data0_b1;
					reg_mul1_src1 <= reg_split_data1_b1;
					reg_mul2_src0 <= reg_split_data0_b2;
					reg_mul2_src1 <= reg_split_data1_b2;
					reg_mul3_src0 <= reg_split_data0_b3;
					reg_mul3_src1 <= reg_split_data1_b3;
				end
			
			2'b01:	// 16bit
				begin
					reg_mul0_src0 <= reg_split_data0_h0;
					reg_mul0_src1 <= reg_split_data1_h0;
					reg_mul1_src0 <= {18{1'bx}};
					reg_mul1_src1 <= {18{1'bx}};
					reg_mul2_src0 <= {18{1'bx}};
					reg_mul2_src1 <= {18{1'bx}};
					reg_mul0_src0 <= reg_split_data0_h1;
					reg_mul0_src1 <= reg_split_data1_h1;
				end

			2'b10:	// reserve
				begin
					reg_mul0_src0 <= {18{1'bx}};
					reg_mul0_src1 <= {18{1'bx}};
					reg_mul1_src0 <= {18{1'bx}};
					reg_mul1_src1 <= {18{1'bx}};
					reg_mul2_src0 <= {18{1'bx}};
					reg_mul2_src1 <= {18{1'bx}};
					reg_mul3_src0 <= {18{1'bx}};
					reg_mul3_src1 <= {18{1'bx}};
				end
			
			2'b11:	// 32bit
				begin
					reg_mul0_src0 <= {{2{1'b0}}, reg_split_data0_w[15:0]};
					reg_mul0_src1 <= {{2{1'b0}}, reg_split_data1_w[15:0]};
					reg_mul1_src0 <= {{2{reg_isplit_data0[31]}}, reg_in_data0_w[31:16]};
					reg_mul1_src1 <= {{2{1'b0}}, reg_split_data1_w[15:0]};
					reg_mul2_src0 <= {{2{1'b0}}, reg_split_data0_w[15:0]};
					reg_mul2_src1 <= {{2{reg_isplit_data0[31]}}, reg_in_data1_w[31:16]};
					reg_mul3_src0 <= {{2{reg_isplit_data0[31]}}, reg_in_data0_w[31:16]};
					reg_mul3_src1 <= {{2{reg_isplit_data0[31]}}, reg_in_data1_w[31:16]};
				end
			endcase
		end		
	end
	
	// multiply destination
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
	
	
	
endmodule

