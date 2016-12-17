// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_unit
		#(
			parameter	COMPONENT_NUM        = 1,
			parameter	COMPONENT_DATA_WIDTH = 24,
			
			parameter	BLK_X_SIZE           = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE           = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	TAG_ADDR_WIDTH       = 6,
			parameter	TAG_X_RSHIFT         = 0,
			parameter	TAG_X_LSHIFT         = 0,
			parameter	TAG_Y_RSHIFT         = TAG_X_RSHIFT,
			parameter	TAG_Y_LSHIFT         = TAG_ADDR_WIDTH / 2,
			parameter	TAG_RAM_TYPE         = "distributed",
			parameter	MEM_RAM_TYPE         = "block",
			
			parameter	USE_LOOK_AHEAD       = 0,
			parameter	USE_S_RREADY         = 1,	// 0: s_rready is always 1'b1.   1: handshake mode.
			parameter	USE_M_RREADY         = 0,	// 0: m_rready is always 1'b1.   1: handshake mode.
			
			parameter	S_USER_WIDTH         = 1,
			parameter	S_DATA_WIDTH         = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			parameter	S_ADDR_X_WIDTH       = 12,
			parameter	S_ADDR_Y_WIDTH       = 12,
			
			parameter	M_DATA_WIDE_SIZE     = 1,
			parameter	M_DATA_WIDTH         = (S_DATA_WIDTH << M_DATA_WIDE_SIZE),
			parameter	M_STRB_WIDTH         = COMPONENT_NUM,
			parameter	M_ADDR_X_WIDTH       = S_ADDR_X_WIDTH - M_DATA_WIDE_SIZE,
			parameter	M_ADDR_Y_WIDTH       = S_ADDR_Y_WIDTH,
			
			parameter	USE_BORDER           = 1,
			parameter	BORDER_DATA          = {S_DATA_WIDTH{1'b0}},
			
			parameter	QUE_FIFO_PTR_WIDTH   = 0,
			parameter	QUE_FIFO_RAM_TYPE    = "distributed",
			
			parameter	AR_FIFO_PTR_WIDTH    = 0,
			parameter	AR_FIFO_RAM_TYPE     = "distributed",
			
			parameter	R_FIFO_PTR_WIDTH     = BLK_Y_SIZE + BLK_X_SIZE - M_DATA_WIDE_SIZE,
			parameter	R_FIFO_RAM_TYPE      = "distributed",
			
			parameter	LOG_ENABLE           = 0,
			parameter	LOG_FILE             = "cache_log.txt",
			parameter	LOG_ID               = 0         
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							endian,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_width,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	param_height,
			
			output	wire							status_idle,
			output	wire							status_stall,
			output	wire							status_access,
			output	wire							status_hit,
			output	wire							status_miss,
			
			input	wire	[S_USER_WIDTH-1:0]		s_aruser,
			input	wire	[S_ADDR_X_WIDTH-1:0]	s_araddrx,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	s_araddry,
			input	wire							s_arvalid,
			output	wire							s_arready,
			output	wire	[S_USER_WIDTH-1:0]		s_ruser,
			output	wire	[S_DATA_WIDTH-1:0]		s_rdata,
			output	wire							s_rvalid,
			input	wire							s_rready,
			
			
			output	wire	[M_ADDR_X_WIDTH-1:0]	m_araddrx,
			output	wire	[M_ADDR_Y_WIDTH-1:0]	m_araddry,
			output	wire							m_arvalid,
			input	wire							m_arready,
			input	wire							m_rlast,
			input	wire	[M_STRB_WIDTH-1:0]		m_rstrb,
			input	wire	[M_DATA_WIDTH-1:0]		m_rdata,
			input	wire							m_rvalid,
			output	wire							m_rready
		);
	
	
	generate
	if ( USE_LOOK_AHEAD ) begin : blk_lookahead
		jelly_texture_cache_lookahead
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
				
				.BLK_X_SIZE				(BLK_X_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.TAG_X_RSHIFT			(TAG_X_RSHIFT),
				.TAG_X_LSHIFT			(TAG_X_LSHIFT),
				.TAG_Y_RSHIFT			(TAG_Y_RSHIFT),
				.TAG_Y_LSHIFT			(TAG_Y_LSHIFT),
				.TAG_RAM_TYPE			(TAG_RAM_TYPE),
				.MEM_RAM_TYPE			(MEM_RAM_TYPE),
				
				.USE_S_RREADY			(USE_S_RREADY),
				.USE_M_RREADY			(USE_M_RREADY),
				
				.S_USER_WIDTH			(S_USER_WIDTH),
				.S_DATA_WIDTH			(S_DATA_WIDTH),
				.S_ADDR_X_WIDTH			(S_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH			(S_ADDR_Y_WIDTH),
				
				.M_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
				.M_DATA_WIDTH			(M_DATA_WIDTH),
				.M_STRB_WIDTH			(M_STRB_WIDTH),
				.M_ADDR_X_WIDTH			(M_ADDR_X_WIDTH),
				.M_ADDR_Y_WIDTH			(M_ADDR_Y_WIDTH),
				
				.USE_BORDER				(USE_BORDER),
				.BORDER_DATA			(BORDER_DATA),
				
				.QUE_FIFO_PTR_WIDTH		(QUE_FIFO_PTR_WIDTH),
				.QUE_FIFO_RAM_TYPE		(QUE_FIFO_RAM_TYPE),
				
				.AR_FIFO_PTR_WIDTH		(AR_FIFO_PTR_WIDTH),
				.AR_FIFO_RAM_TYPE		(AR_FIFO_RAM_TYPE),
				
				.R_FIFO_PTR_WIDTH		(R_FIFO_PTR_WIDTH),
				.R_FIFO_RAM_TYPE		(R_FIFO_RAM_TYPE),
				
				.LOG_ENABLE				(LOG_ENABLE),
				.LOG_FILE				(LOG_FILE),
				.LOG_ID					(LOG_ID)
			)
		i_texture_cache_lookahead
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.clear_start			(clear_start),
				.clear_busy				(clear_busy),
				
				.param_width			(param_width),
				.param_height			(param_height),
				
				.status_idle			(status_idle),
				.status_stall			(status_stall),
				.status_access			(status_access),
				.status_hit				(status_hit),
				.status_miss			(status_miss),
				
				.s_aruser				(s_aruser),
				.s_araddrx				(s_araddrx),
				.s_araddry				(s_araddry),
				.s_arvalid				(s_arvalid),
				.s_arready				(s_arready),
				.s_ruser				(s_ruser),
				.s_rdata				(s_rdata),
				.s_rvalid				(s_rvalid),
				.s_rready				(s_rready),
				
				.m_araddrx				(m_araddrx),
				.m_araddry				(m_araddry),
				.m_arvalid				(m_arvalid),
				.m_arready				(m_arready),
				.m_rlast				(m_rlast),
				.m_rstrb				(m_rstrb),
				.m_rdata				(m_rdata),
				.m_rvalid				(m_rvalid),
				.m_rready				(m_rready)
			);
	
	
	
	end
	else begin : blk_basic
		jelly_texture_cache_basic
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
				
				.BLK_X_SIZE				(BLK_X_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.TAG_X_RSHIFT			(TAG_X_RSHIFT),
				.TAG_X_LSHIFT			(TAG_X_LSHIFT),
				.TAG_Y_RSHIFT			(TAG_Y_RSHIFT),
				.TAG_Y_LSHIFT			(TAG_Y_LSHIFT),
				.TAG_RAM_TYPE			(TAG_RAM_TYPE),
				.MEM_RAM_TYPE			(MEM_RAM_TYPE),
				
				.USE_S_RREADY			(USE_S_RREADY),
				.USE_M_RREADY			(USE_M_RREADY),
				
				.S_USER_WIDTH			(S_USER_WIDTH),
				.S_DATA_WIDTH			(S_DATA_WIDTH),
				.S_ADDR_X_WIDTH			(S_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH			(S_ADDR_Y_WIDTH),
				
				.M_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
				.M_DATA_WIDTH			(M_DATA_WIDTH),
				.M_STRB_WIDTH			(M_STRB_WIDTH),
				.M_ADDR_X_WIDTH			(M_ADDR_X_WIDTH),
				.M_ADDR_Y_WIDTH			(M_ADDR_Y_WIDTH),
				
				.USE_BORDER				(USE_BORDER),
				.BORDER_DATA			(BORDER_DATA),
				
				.QUE_FIFO_PTR_WIDTH		(QUE_FIFO_PTR_WIDTH),
				.QUE_FIFO_RAM_TYPE		(QUE_FIFO_RAM_TYPE),
				
				.LOG_ENABLE				(LOG_ENABLE),
				.LOG_FILE				(LOG_FILE),
				.LOG_ID					(LOG_ID)
			)
		i_texture_cache_basic
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.clear_start			(clear_start),
				.clear_busy				(clear_busy),
				
				.param_width			(param_width),
				.param_height			(param_height),
				
				.status_idle			(status_idle),
				.status_stall			(status_stall),
				.status_access			(status_access),
				.status_hit				(status_hit),
				.status_miss			(status_miss),
				
				.s_aruser				(s_aruser),
				.s_araddrx				(s_araddrx),
				.s_araddry				(s_araddry),
				.s_arvalid				(s_arvalid),
				.s_arready				(s_arready),
				.s_ruser				(s_ruser),
				.s_rdata				(s_rdata),
				.s_rvalid				(s_rvalid),
				.s_rready				(s_rready),
				
				.m_araddrx				(m_araddrx),
				.m_araddry				(m_araddry),
				.m_arvalid				(m_arvalid),
				.m_arready				(m_arready),
				.m_rlast				(m_rlast),
				.m_rstrb				(m_rstrb),
				.m_rdata				(m_rdata),
				.m_rvalid				(m_rvalid),
				.m_rready				(m_rready)
			);
	end
	endgenerate
	
endmodule



`default_nettype wire


// end of file
