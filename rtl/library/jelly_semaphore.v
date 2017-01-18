// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// AXIなどのコマンド発行制限用を想定


// semaphore
module jelly_semaphore
		#(
			parameter	ASYNC         = 1,
			parameter	COUNTER_WIDTH = 9,
			parameter	INIT_COUNTER  = 256
		)
		(
			// カウンタ値返却側
			input	wire						rel_reset,
			input	wire						rel_clk,
			input	wire	[COUNTER_WIDTH-1:0]	rel_add,
			input	wire						rel_valid,
			
			// カウンタ値取得側
			input	wire						req_reset,
			input	wire						req_clk,
			input	wire	[COUNTER_WIDTH-1:0]	req_sub,	// limit時に要求しないこと
			input	wire						req_valid,
			
			output	wire						out_limit
		);
	
	// 返却値のクロック乗せかえ
	
	
	
	
endmodule


`default_nettype wire


// end of file
