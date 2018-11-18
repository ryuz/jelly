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
	
	
endmodule


`default_nettype wire


// end of file
