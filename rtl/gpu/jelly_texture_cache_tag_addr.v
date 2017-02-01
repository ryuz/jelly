// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_tag_addr
		#(
			parameter	PARALLEL_SIZE  = 0,		// 0:1, 1:2, 2:4, 2:4, 3:8 ....
			
			parameter	ADDR_X_WIDTH   = 12,
			parameter	ADDR_Y_WIDTH   = 12,
			parameter	TAG_ADDR_WIDTH = 6,
			
			parameter	ALGORITHM      = PARALLEL_SIZE > 0 ? "SUDOKU" : "TWIST",	// "SUDOKU", "TWIST"
			
			// local
			parameter	ID_WIDTH       = PARALLEL_SIZE > 0 ? PARALLEL_SIZE : 1
		)
		(
			input	wire	[ADDR_X_WIDTH-1:0]		addrx,
			input	wire	[ADDR_Y_WIDTH-1:0]		addry,
			
			output	wire	[ID_WIDTH-1:0]			unit_id,
			output	wire	[TAG_ADDR_WIDTH-1:0]	tag_addr
		);
	
	localparam	SHUFFLE_WIDTH   = PARALLEL_SIZE + TAG_ADDR_WIDTH;
	localparam	HALF_ADDR_WIDTH = TAG_ADDR_WIDTH / 2;
	localparam	TWIST_OFFSET    = (1 << (PARALLEL_SIZE + TAG_ADDR_WIDTH - 1));
	
	generate
	if ( ALGORITHM == "SUDOKU" ) begin : blk_sudoku
		wire	[SHUFFLE_WIDTH-1:0]		shuffle_x    = addrx;
		wire	[SHUFFLE_WIDTH-1:0]		shuffle_y    = addry;
		
		wire	[SHUFFLE_WIDTH-1:0]		shuffle_addr = (({shuffle_y, shuffle_y} >> HALF_ADDR_WIDTH) + shuffle_x);
		
		assign unit_id  = PARALLEL_SIZE > 0 ? shuffle_addr : 0;
		assign tag_addr = (shuffle_addr >> PARALLEL_SIZE);
	end
	else begin : blk_twist
		wire	[SHUFFLE_WIDTH-1:0]		shuffle_addr = addrx + (TWIST_OFFSET * addry) - addry;
		
		assign unit_id  = PARALLEL_SIZE > 0 ? shuffle_addr : 0;
		assign tag_addr = (shuffle_addr >> PARALLEL_SIZE);
	end
	endgenerate
	
endmodule



`default_nettype wire


// end of file
