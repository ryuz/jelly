// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_l1
		#(
			parameter	CACHE_NUM            = 4,
			
			parameter	COMPONENT_NUM        = 1,
			parameter	COMPONENT_DATA_WIDTH = 24,
			parameter	BLK_X_SIZE           = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE           = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	TAG_ADDR_WIDTH       = 6,
			parameter	TAG_RAM_TYPE         = "distributed",
			parameter	MEM_RAM_TYPE         = "block",
			
			parameter	USE_BORDER           = 1,
			parameter	BORDER_DATA          = {S_DATA_WIDTH{1'b0}},
			
			parameter	USE_LOOK_AHEAD       = 0,
			parameter	USE_S_RREADY         = 1,	// 0: s_rready is always 1'b1.   1: handshake mode.
			parameter	USE_M_RREADY         = 0,	// 0: m_rready is always 1'b1.   1: handshake mode.
			
			parameter	S_USER_WIDTH         = 1,
			parameter	S_ADDR_X_WIDTH       = 12,
			parameter	S_ADDR_Y_WIDTH       = 12,
			parameter	S_DATA_WIDTH         = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			
			parameter	M_DATA_WIDE_SIZE     = 1,
			parameter	M_DATA_WIDTH         = (S_DATA_WIDTH << M_DATA_WIDE_SIZE),
			parameter	M_ADDR_X_WIDTH       = S_ADDR_X_WIDTH - M_DATA_WIDE_SIZE,
			parameter	M_ADDR_Y_WIDTH       = S_ADDR_Y_WIDTH,
			
			parameter	QUE_FIFO_PTR_WIDTH   = USE_LOOK_AHEAD ? BLK_Y_SIZE + BLK_X_SIZE : 0,
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
			input	wire									reset,
			input	wire									clk,
			
			input	wire									endian,
			
			input	wire									clear_start,
			output	wire									clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]			param_width,
			input	wire	[S_ADDR_X_WIDTH-1:0]			param_height,
			
			output	wire	[CACHE_NUM-1:0]					status_idle,
			output	wire	[CACHE_NUM-1:0]					status_stall,
			output	wire	[CACHE_NUM-1:0]					status_access,
			output	wire	[CACHE_NUM-1:0]					status_hit,
			output	wire	[CACHE_NUM-1:0]					status_miss,
			
			// slave port
			input	wire	[CACHE_NUM*S_USER_WIDTH-1:0]	s_aruser,
			input	wire	[CACHE_NUM*S_ADDR_X_WIDTH-1:0]	s_araddrx,
			input	wire	[CACHE_NUM*S_ADDR_Y_WIDTH-1:0]	s_araddry,
			input	wire	[CACHE_NUM-1:0]					s_arvalid,
			output	wire	[CACHE_NUM-1:0]					s_arready,
			
			output	wire	[CACHE_NUM*S_USER_WIDTH-1:0]	s_ruser,
			output	wire	[CACHE_NUM*S_DATA_WIDTH-1:0]	s_rdata,
			output	wire	[CACHE_NUM-1:0]					s_rvalid,
			input	wire	[CACHE_NUM-1:0]					s_rready,
			
			
			output	wire	[CACHE_NUM-1:0]					m_arlast,
			output	wire	[CACHE_NUM*M_ADDR_X_WIDTH-1:0]	m_araddrx,
			output	wire	[CACHE_NUM*M_ADDR_Y_WIDTH-1:0]	m_araddry,
			output	wire	[CACHE_NUM-1:0]					m_arvalid,
			input	wire	[CACHE_NUM-1:0]					m_arready,
			
			input	wire	[CACHE_NUM-1:0]					m_rlast,
			input	wire	[CACHE_NUM*M_DATA_WIDTH-1:0]	m_rdata,
			input	wire	[CACHE_NUM-1:0]					m_rvalid,
			output	wire	[CACHE_NUM-1:0]					m_rready
		);
	
	genvar	i, j;
	
	
	// -----------------------------
	//  localparam
	// -----------------------------
	
	/*
	localparam	COMPONENT_DATA_SIZE  = COMPONENT_DATA_WIDTH <=    8 ? 0 :
	                                   COMPONENT_DATA_WIDTH <=   16 ? 1 :
	                                   COMPONENT_DATA_WIDTH <=   32 ? 2 :
	                                   COMPONENT_DATA_WIDTH <=   64 ? 3 :
	                                   COMPONENT_DATA_WIDTH <=  128 ? 4 :
	                                   COMPONENT_DATA_WIDTH <=  256 ? 5 :
	                                   COMPONENT_DATA_WIDTH <=  512 ? 6 :
	                                   COMPONENT_DATA_WIDTH <= 1024 ? 7 :
	                                   COMPONENT_DATA_WIDTH <= 2048 ? 8 : 9;
	
	localparam	M_ID_WIDTH           = CACHE_NUM <    4 ? 1 :
	                                   CACHE_NUM <    8 ? 2 :
	                                   CACHE_NUM <   16 ? 3 :
	                                   CACHE_NUM <   32 ? 4 :
	                                   CACHE_NUM <   64 ? 5 :
	                                   CACHE_NUM <  128 ? 6 :
	                                   CACHE_NUM <  256 ? 7 :
	                                   CACHE_NUM <  512 ? 8 : 9;
	*/
	
	
//	localparam	M_DATA_WIDE_NUM      = (1 << M_DATA_WIDE_SIZE);
	
	
//	localparam AR_PACKET_WIDTH = M_ADDR_X_WIDTH + M_ADDR_Y_WIDTH;
	
	localparam	CACHE_ID_WIDTH       = CACHE_NUM <=    2 ? 1 :
			                           CACHE_NUM <=    4 ? 2 :
			                           CACHE_NUM <=    8 ? 3 :
			                           CACHE_NUM <=   16 ? 4 :
			                           CACHE_NUM <=   32 ? 5 :
			                           CACHE_NUM <=   64 ? 6 :
			                           CACHE_NUM <=  128 ? 7 :
			                           CACHE_NUM <=  256 ? 8 : 9;

	
	// -----------------------------
	//  Cahce
	// -----------------------------
	
	wire	[CACHE_NUM-1:0]				cache_clear_busy;
	assign clear_busy = cache_clear_busy[0];
	
	generate
	for ( i = 0; i < CACHE_NUM; i = i+1 ) begin : loop_cache
		jelly_texture_cache_unit
				#(
					.COMPONENT_NUM			(COMPONENT_NUM),
					.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
					
					.PARALLEL_SIZE			(0),
					.BLK_X_SIZE				(BLK_X_SIZE),
					.BLK_Y_SIZE				(BLK_Y_SIZE),
					.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
					.TAG_RAM_TYPE			(TAG_RAM_TYPE),
					.MEM_RAM_TYPE			(MEM_RAM_TYPE),
					
					.USE_LOOK_AHEAD			(USE_LOOK_AHEAD),
					.USE_S_RREADY           (USE_S_RREADY),
					.USE_M_RREADY			(USE_M_RREADY),
					
					.S_USER_WIDTH			(S_USER_WIDTH),
					.S_ADDR_X_WIDTH			(S_ADDR_X_WIDTH),
					.S_ADDR_Y_WIDTH			(S_ADDR_Y_WIDTH),
					
					.M_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
					.M_IN_ORDER				(1),
					
					.BORDER_DATA			(BORDER_DATA),
					
					.QUE_FIFO_PTR_WIDTH		(QUE_FIFO_PTR_WIDTH),
					.QUE_FIFO_RAM_TYPE		(QUE_FIFO_RAM_TYPE),
					
					.AR_FIFO_PTR_WIDTH		(AR_FIFO_PTR_WIDTH),
					.AR_FIFO_RAM_TYPE		(AR_FIFO_RAM_TYPE),
					
					.R_FIFO_PTR_WIDTH		(R_FIFO_PTR_WIDTH),
					.R_FIFO_RAM_TYPE		(R_FIFO_RAM_TYPE),
					
					.LOG_ENABLE				(LOG_ENABLE),
					.LOG_FILE				(LOG_FILE),
					.LOG_ID					(LOG_ID + i)
				)
			i_texture_cache_unit
				(
					.reset					(reset),
					.clk					(clk),
					
					.endian					(endian),
					
					.clear_start			(clear_start),
					.clear_busy				(cache_clear_busy[i]),
					
					.param_width			(param_width),
					.param_height			(param_height),
					
					.status_idle			(status_idle[i]),
					.status_stall			(status_stall[i]),
					.status_access			(status_access[i]),
					.status_hit				(status_hit[i]),
					.status_miss			(status_miss[i]),
					
					.s_aruser				(s_aruser [i*S_USER_WIDTH   +: S_USER_WIDTH]),
					.s_araddrx				(s_araddrx[i*S_ADDR_X_WIDTH +: S_ADDR_X_WIDTH]),
					.s_araddry				(s_araddry[i*S_ADDR_Y_WIDTH +: S_ADDR_Y_WIDTH]),
					.s_arvalid				(s_arvalid[i]),
					.s_arready				(s_arready[i]),
					
					.s_ruser				(s_ruser  [i*S_USER_WIDTH   +: S_USER_WIDTH]),
					.s_rdata				(s_rdata  [i*S_DATA_WIDTH   +: S_DATA_WIDTH]),
					.s_rvalid				(s_rvalid [i]),
					.s_rready				(s_rready [i]),
					
					.m_araddrx				(m_araddrx[i*M_ADDR_X_WIDTH +: M_ADDR_X_WIDTH]),
					.m_araddry				(m_araddry[i*M_ADDR_Y_WIDTH +: M_ADDR_Y_WIDTH]),
					.m_arvalid				(m_arvalid[i]),
					.m_arready				(m_arready[i]),
					
					.m_rlast				(m_rlast  [i]),
					.m_rstrb				({COMPONENT_NUM{1'b1}}),
					.m_rdata				(m_rdata  [i*M_DATA_WIDTH   +: M_DATA_WIDTH]),
					.m_rvalid				(m_rvalid [i]),
					.m_rready				(m_rready [i])
				);
		
	end
	endgenerate
	
	
	
	
endmodule


`default_nettype wire


// end of file
