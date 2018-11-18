// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module img_mnist_unit
		#(
			parameter	USER_WIDTH = 0,
			
			parameter	USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			input	wire							cke,
			
			input	wire	[USER_BITS-1:0]			in_user,
			input	wire	[28*28-1:0]				in_data,
			input	wire							in_valid,
			
			output	wire	[USER_BITS-1:0]			out_user,
			output	wire	[1:0]					out_count,
			output	wire	[3:0]					out_number,
			output	wire							out_valid
		);
	
	integer		i;
	
	wire	[USER_BITS-1:0]		lutnet_user;
	wire	[3*10-1:0]			lutnet_data;
	wire						lutnet_valid;
	
	mnist_lut_net
			#(
				.USER_WIDTH		(USER_WIDTH)
			)
		i_mnist_lut_net
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(cke),
				
				.in_user		(in_user),
				.in_data		(in_data),
				.in_valid		(in_valid),
				
				.out_user		(lutnet_user),
				.out_data		(lutnet_data),
				.out_valid		(lutnet_valid)
			);
	
	
	// counting
	reg		[USER_BITS-1:0]		counting_user;
	reg		[2*10-1:0]			counting_count;
	reg							counting_valid;
	always @(posedge clk) begin
		if( reset ) begin
			counting_user   <= {USER_BITS{1'bx}};
			counting_count  <= {20{1'bx}};
			counting_valid  <= 1'b0;
		end
		else if ( cke ) begin
			counting_user   <= lutnet_user;
			for ( i = 0; i < 10; i = i+1 ) begin
				counting_count[2*i +:2] <= lutnet_data[i] + lutnet_data[10+i] + lutnet_data[20+i];
			end
			counting_valid  <= 1'b0;
		end
	end
	
/*	
	// select max
	jelly_minmax
			#(
				.NUM				(10),
				.COMMON_USER_WIDTH	(USER_WIDTH),
				.USER_WIDTH			(0),
				.DATA_WIDTH			(2),
				.DATA_SIGNED		(0),
				.CMP_MIN			(0),	// min‚©max‚©
				.CMP_EQ				(0)		// “¯’l‚Ì‚Æ‚« data0 ‚Æ data1 ‚Ç‚¿‚ç‚ğ—Dæ‚·‚é‚©
			)
		i_minmax
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_common_user		(counting_user),
				.s_user				(1'b0),
				.s_data				(counting_count),
				.s_en				({10{1'b1}}),
				.s_valid			(counting_valid),
				
				.m_common_user		(out_user),
				.m_user				(),
				.m_data				(out_count),
				.m_index			(out_number),
				.m_en				(),
				.m_valid			(out_valid)
			);
*/	
	
	
	// select max
	
	reg		[USER_BITS-1:0]			st0_user;
	reg		[9:0]					st0_hi;
	reg		[9:0]					st0_lo;
	reg								st0_valid;
	
	reg		[USER_BITS-1:0]			st1_user;
	reg		[9:0]					st1_hi;
	reg		[9:0]					st1_lo;
	reg								st1_valid;
	
	reg		[USER_BITS-1:0]			st2_user;
	reg								st2_hi_en;
	reg								st2_lo_en;
	reg		[3:0]					st2_number;
	reg								st2_valid;
	
	reg		[USER_BITS-1:0]			st3_user;
	reg		[1:0]					st3_count;
	reg		[3:0]					st3_number;
	reg								st3_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_user   <= {USER_BITS{1'bx}};
			st0_hi     <= {10{1'bx}};
			st0_lo     <= {10{1'bx}};
			st0_valid  <= 1'b0;
			
			st1_user   <= {USER_BITS{1'bx}};
			st1_hi     <= {10{1'bx}};
			st1_lo     <= {10{1'bx}};
			st1_valid  <= 1'b0;
			
			st2_user   <= {USER_BITS{1'bx}};
			st2_hi_en  <= 1'bx;
			st2_lo_en  <= 1'bx;
			st2_number <= {4{1'bx}};
			st2_valid  <= 1'b0;
			
			st3_user   <= {USER_BITS{1'bx}};
			st3_count  <= {2{1'bx}};
			st3_number <= {4{1'bx}};
			st3_valid  <= 1'b0;
		end
		else if ( cke ) begin
			// stage 0
			st0_user  <= counting_user;
			
			st0_hi[0] <= (counting_count[0*2 +: 2] >= 3);
			st0_hi[1] <= (counting_count[1*2 +: 2] >= 3);
			st0_hi[2] <= (counting_count[2*2 +: 2] >= 3);
			st0_hi[3] <= (counting_count[3*2 +: 2] >= 3);
			st0_hi[4] <= (counting_count[4*2 +: 2] >= 3);
			st0_hi[5] <= (counting_count[5*2 +: 2] >= 3);
			st0_hi[6] <= (counting_count[6*2 +: 2] >= 3);
			st0_hi[7] <= (counting_count[7*2 +: 2] >= 3);
			st0_hi[8] <= (counting_count[8*2 +: 2] >= 3);
			st0_hi[9] <= (counting_count[9*2 +: 2] >= 3);
			
			st0_lo[0] <= (counting_count[0*2 +: 2] >= 1);
			st0_lo[1] <= (counting_count[1*2 +: 2] >= 1);
			st0_lo[2] <= (counting_count[2*2 +: 2] >= 1);
			st0_lo[3] <= (counting_count[3*2 +: 2] >= 1);
			st0_lo[4] <= (counting_count[4*2 +: 2] >= 1);
			st0_lo[5] <= (counting_count[5*2 +: 2] >= 1);
			st0_lo[6] <= (counting_count[6*2 +: 2] >= 1);
			st0_lo[7] <= (counting_count[7*2 +: 2] >= 1);
			st0_lo[8] <= (counting_count[8*2 +: 2] >= 1);
			st0_lo[9] <= (counting_count[9*2 +: 2] >= 1);
			
			st0_valid <= counting_valid;
			
			
			// stage 1
			st1_user  <= st0_user;
			st1_hi[0] <= (st0_hi == 10'b0000000001);
			st1_hi[1] <= (st0_hi == 10'b0000000010);
			st1_hi[2] <= (st0_hi == 10'b0000000100);
			st1_hi[3] <= (st0_hi == 10'b0000001000);
			st1_hi[4] <= (st0_hi == 10'b0000010000);
			st1_hi[5] <= (st0_hi == 10'b0000100000);
			st1_hi[6] <= (st0_hi == 10'b0001000000);
			st1_hi[7] <= (st0_hi == 10'b0010000000);
			st1_hi[8] <= (st0_hi == 10'b0100000000);
			st1_hi[9] <= (st0_hi == 10'b1000000000);
			st1_lo    <= st0_lo;
			st1_valid <= st0_valid;
			
			
			// stage 2
			st2_user  <= st1_user;
			st2_hi_en <= (st1_hi != 0);
			st2_lo_en <= ((st1_lo & ~st1_hi) == 0) && (st1_hi != 0);
			case ( st1_hi )
			10'b0000000001: st2_number <= 4'd0;
			10'b0000000010: st2_number <= 4'd1;
			10'b0000000100: st2_number <= 4'd2;
			10'b0000001000: st2_number <= 4'd3;
			10'b0000010000: st2_number <= 4'd4;
			10'b0000100000: st2_number <= 4'd5;
			10'b0001000000: st2_number <= 4'd6;
			10'b0010000000: st2_number <= 4'd7;
			10'b0100000000: st2_number <= 4'd8;
			10'b1000000000: st2_number <= 4'd9;
			default:		st2_number <= 4'hx;
			endcase
			st2_valid <= st1_valid;
			
			// stage 3
			st3_user   <= st2_user;
			st3_number <= st2_number;
			st3_count  <= {st2_hi_en, st2_lo_en};
			st3_valid  <= st2_valid;
		end
	end
	
	assign out_user   = st3_user;
	assign out_count  = st3_count;
	assign out_number = st3_number;
	assign out_valid  = st3_valid;
	
endmodule


`default_nettype wire


// end of file
