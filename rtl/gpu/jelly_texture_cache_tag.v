// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_tag
		#(
			parameter	USER_WIDTH       = 1,
			
			parameter	ADDR_X_WIDTH     = 12,
			parameter	ADDR_Y_WIDTH     = 12,
			
			parameter	PARALLEL_SIZE    = 0,
			parameter	TAG_ADDR_WIDTH   = 6,
			parameter	BLK_X_SIZE       = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE       = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			
			parameter	RAM_TYPE         = "distributed",
			
			parameter	ASSOCIATIVE      = TAG_ADDR_WIDTH < 3,
			parameter	ALGORITHM        = PARALLEL_SIZE > 0 ? "SUDOKU" : "TWIST",
			
			parameter	M_SLAVE_REGS     = 0,
			parameter	M_MASTER_REGS    = 0,
			
			parameter	LOG_ENABLE       = 0,
			parameter	LOG_FILE         = "cache_log.txt",
			parameter	LOG_ID           = 0,
			
			// local
			parameter	USER_BITS        = USER_WIDTH > 0 ? USER_WIDTH : 1,
			parameter	PIX_ADDR_X_WIDTH = BLK_X_SIZE,
			parameter	PIX_ADDR_Y_WIDTH = BLK_Y_SIZE,
			parameter	BLK_ADDR_X_WIDTH = ADDR_X_WIDTH - BLK_X_SIZE,
			parameter	BLK_ADDR_Y_WIDTH = ADDR_Y_WIDTH - BLK_Y_SIZE
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[USER_BITS-1:0]			s_user,
			input	wire							s_last,
			input	wire	[ADDR_X_WIDTH-1:0]		s_addrx,
			input	wire	[ADDR_Y_WIDTH-1:0]		s_addry,
			input	wire							s_strb,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[USER_BITS-1:0]			m_user,
			output	wire							m_last,
			output	wire	[TAG_ADDR_WIDTH-1:0]	m_tag_addr,
			output	wire	[PIX_ADDR_X_WIDTH-1:0]	m_pix_addrx,
			output	wire	[PIX_ADDR_Y_WIDTH-1:0]	m_pix_addry,
			output	wire	[BLK_ADDR_X_WIDTH-1:0]	m_blk_addrx,
			output	wire	[BLK_ADDR_Y_WIDTH-1:0]	m_blk_addry,
			output	wire							m_cache_hit,
			output	wire							m_strb,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	
	generate
	if ( ASSOCIATIVE ) begin : blk_associative
		jelly_texture_cache_tag_associative
				#(
					.USER_WIDTH			(USER_WIDTH),
					
					.ADDR_X_WIDTH		(ADDR_X_WIDTH),
					.ADDR_Y_WIDTH		(ADDR_Y_WIDTH),
					
					.TAG_ADDR_WIDTH		(TAG_ADDR_WIDTH),
					.BLK_X_SIZE			(BLK_X_SIZE),
					.BLK_Y_SIZE			(BLK_Y_SIZE),
					
					.M_SLAVE_REGS		(M_SLAVE_REGS),
					.M_MASTER_REGS		(M_MASTER_REGS)
				)
			i_texture_cache_tag_associative
				(
					.reset				(reset),
					.clk				(clk),
					
					.clear_start		(clear_start),
					.clear_busy			(clear_busy),
					
					.s_user				(s_user),
					.s_last				(s_last),
					.s_addrx			(s_addrx),
					.s_addry			(s_addry),
					.s_strb				(s_strb),
					.s_valid			(s_valid),
					.s_ready			(s_ready),
					
					.m_user				(m_user),
					.m_last				(m_last),
					.m_tag_addr			(m_tag_addr),
					.m_pix_addrx		(m_pix_addrx),
					.m_pix_addry		(m_pix_addry),
					.m_blk_addrx		(m_blk_addrx),
					.m_blk_addry		(m_blk_addry),
					.m_cache_hit		(m_cache_hit),
					.m_strb				(m_strb),
					.m_valid			(m_valid),
					.m_ready			(m_ready)
				);
	end
	else begin : blk_directmap
		jelly_texture_cache_tag_directmap
				#(
					.USER_WIDTH			(USER_WIDTH),
					
					.ADDR_X_WIDTH		(ADDR_X_WIDTH),
					.ADDR_Y_WIDTH		(ADDR_Y_WIDTH),
					
					.PARALLEL_SIZE		(PARALLEL_SIZE),
					.TAG_ADDR_WIDTH		(TAG_ADDR_WIDTH),
					.BLK_X_SIZE			(BLK_X_SIZE),
					.BLK_Y_SIZE			(BLK_Y_SIZE),
					
					.RAM_TYPE			(RAM_TYPE),
					
					.ALGORITHM			(ALGORITHM),
					
					.M_SLAVE_REGS		(M_SLAVE_REGS),
					.M_MASTER_REGS		(M_MASTER_REGS),
					
					.LOG_ENABLE			(LOG_ENABLE),
					.LOG_FILE			(LOG_FILE),
					.LOG_ID				(LOG_ID)
				)
			i_texture_cache_tag_directmap
				(
					.reset				(reset),
					.clk				(clk),
					
					.clear_start		(clear_start),
					.clear_busy			(clear_busy),
					
					.s_user				(s_user),
					.s_last				(s_last),
					.s_addrx			(s_addrx),
					.s_addry			(s_addry),
					.s_strb				(s_strb),
					.s_valid			(s_valid),
					.s_ready			(s_ready),
					
					.m_user				(m_user),
					.m_last				(m_last),
					.m_tag_addr			(m_tag_addr),
					.m_pix_addrx		(m_pix_addrx),
					.m_pix_addry		(m_pix_addry),
					.m_blk_addrx		(m_blk_addrx),
					.m_blk_addry		(m_blk_addry),
					.m_cache_hit		(m_cache_hit),
					.m_strb				(m_strb),
					.m_valid			(m_valid),
					.m_ready			(m_ready)
				);
	end
	endgenerate
	
	
endmodule



`default_nettype wire


// end of file
