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
			
			parameter	S_NUM                = 4,
			parameter	S_ID_WIDTH           = S_NUM <=    2 ? 1 :
			                                   S_NUM <=    4 ? 2 :
			                                   S_NUM <=    8 ? 3 :
			                                   S_NUM <=   16 ? 4 :
			                                   S_NUM <=   32 ? 5 :
			                                   S_NUM <=   64 ? 6 :
			                                   S_NUM <=  128 ? 7 :
			                                   S_NUM <=  256 ? 8 : 9,
			parameter	S_USER_WIDTH         = 1,
			parameter	S_ADDR_X_WIDTH       = 12,
			parameter	S_ADDR_Y_WIDTH       = 12,
			parameter	S_DATA_WIDTH         = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			
			parameter	M_DATA_WIDE_SIZE     = 1,
			parameter	M_NUM                = 4,
			parameter	M_ID_X_RSHIFT        = 3,
			parameter	M_ID_X_LSHIFT        = 0,
			parameter	M_ID_Y_RSHIFT        = 3,
			parameter	M_ID_Y_LSHIFT        = 1,
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
			
			output	wire	[S_NUM-1:0]						status_idle,
			output	wire	[S_NUM-1:0]						status_stall,
			output	wire	[S_NUM-1:0]						status_access,
			output	wire	[S_NUM-1:0]						status_hit,
			output	wire	[S_NUM-1:0]						status_miss,
			
			// slave port
			input	wire	[S_NUM*S_USER_WIDTH-1:0]		s_aruser,
			input	wire	[S_NUM*S_ADDR_X_WIDTH-1:0]		s_araddrx,
			input	wire	[S_NUM*S_ADDR_Y_WIDTH-1:0]		s_araddry,
			input	wire	[S_NUM-1:0]						s_arvalid,
			output	wire	[S_NUM-1:0]						s_arready,
			
			output	wire	[S_NUM*S_USER_WIDTH-1:0]		s_ruser,
			output	wire	[S_NUM*S_DATA_WIDTH-1:0]		s_rdata,
			output	wire	[S_NUM-1:0]						s_rvalid,
			input	wire	[S_NUM-1:0]						s_rready,
			
			
			// master port to L2
			output	wire	[M_NUM*S_ID_WIDTH-1:0]			m_arid,
			output	wire	[M_NUM-1:0]						m_arlast,
			output	wire	[M_NUM*M_ADDR_X_WIDTH-1:0]		m_araddrx,
			output	wire	[M_NUM*M_ADDR_Y_WIDTH-1:0]		m_araddry,
			output	wire	[M_NUM-1:0]						m_arvalid,
			input	wire	[M_NUM-1:0]						m_arready,
			
			input	wire	[M_NUM*S_ID_WIDTH-1:0]			m_rid,
			input	wire	[M_NUM-1:0]						m_rlast,
			input	wire	[M_NUM*M_DATA_WIDTH-1:0]		m_rdata,
			input	wire	[M_NUM-1:0]						m_rvalid,
			output	wire	[M_NUM-1:0]						m_rready
		);
	
	genvar	i, j;
	
	
	// -----------------------------
	//  localparam
	// -----------------------------
	
	localparam	COMPONENT_DATA_SIZE  = COMPONENT_DATA_WIDTH <=    8 ? 0 :
	                                   COMPONENT_DATA_WIDTH <=   16 ? 1 :
	                                   COMPONENT_DATA_WIDTH <=   32 ? 2 :
	                                   COMPONENT_DATA_WIDTH <=   64 ? 3 :
	                                   COMPONENT_DATA_WIDTH <=  128 ? 4 :
	                                   COMPONENT_DATA_WIDTH <=  256 ? 5 :
	                                   COMPONENT_DATA_WIDTH <=  512 ? 6 :
	                                   COMPONENT_DATA_WIDTH <= 1024 ? 7 :
	                                   COMPONENT_DATA_WIDTH <= 2048 ? 8 : 9;
	
	localparam	M_ID_WIDTH           = M_NUM <    4 ? 1 :
	                                   M_NUM <    8 ? 2 :
	                                   M_NUM <   16 ? 3 :
	                                   M_NUM <   32 ? 4 :
	                                   M_NUM <   64 ? 5 :
	                                   M_NUM <  128 ? 6 :
	                                   M_NUM <  256 ? 7 :
	                                   M_NUM <  512 ? 8 : 9;
	
	localparam	M_DATA_WIDE_NUM      = (1 << M_DATA_WIDE_SIZE);
	
	
	localparam AR_PACKET_WIDTH = M_ADDR_X_WIDTH + M_ADDR_Y_WIDTH;
	localparam R_PACKET_WIDTH  = 1 + M_DATA_WIDTH;
	
	
	
	// -----------------------------
	//  Cahce
	// -----------------------------
	
	wire	[S_NUM-1:0]							cache_clear_busy;
	assign clear_busy = cache_clear_busy[0];
	
	
	wire	[S_NUM*M_NUM*AR_PACKET_WIDTH-1:0]	cache_arpacket;
	wire	[S_NUM*M_NUM-1:0]					cache_arvalid;
	wire	[S_NUM*M_NUM-1:0]					cache_arready;
	
	wire	[S_NUM*M_NUM*R_PACKET_WIDTH-1:0]	cache_rpacket;
	wire	[S_NUM*M_NUM-1:0]					cache_rvalid;
	wire	[S_NUM*M_NUM-1:0]					cache_rready;
	
	generate
	for ( i = 0; i < S_NUM; i = i+1 ) begin : loop_cache
		// L1 cache
		wire	[M_ADDR_X_WIDTH-1:0]	m_araddrx;
		wire	[M_ADDR_Y_WIDTH-1:0]	m_araddry;
		wire							m_arvalid;
		wire							m_arready;
		
		wire							m_rlast;
		wire	[M_DATA_WIDTH-1:0]		m_rdata;
		wire							m_rvalid;
		wire							m_rready;
			
		jelly_texture_cache_unit
				#(
					.S_USER_WIDTH			(S_USER_WIDTH),
					
					.COMPONENT_NUM			(COMPONENT_NUM),
					.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
					
					.M_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
					
					.S_ADDR_X_WIDTH			(S_ADDR_X_WIDTH),
					.S_ADDR_Y_WIDTH			(S_ADDR_Y_WIDTH),
					
					.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
					
					.BLK_X_SIZE				(BLK_X_SIZE),
					.BLK_Y_SIZE				(BLK_Y_SIZE),
					
					.USE_LOOK_AHEAD			(USE_LOOK_AHEAD),
					.USE_S_RREADY           (USE_S_RREADY),
					.USE_M_RREADY			(USE_M_RREADY),
					
					.BORDER_DATA			(BORDER_DATA),
					
					.TAG_RAM_TYPE			(TAG_RAM_TYPE),
					.MEM_RAM_TYPE			(MEM_RAM_TYPE),
					
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
					.s_rdata				(s_rdata  [i*S_DATA_WIDTH +: S_DATA_WIDTH]),
					.s_rvalid				(s_rvalid [i]),
					.s_rready				(s_rready [i]),
					
					.m_araddrx				(m_araddrx),
					.m_araddry				(m_araddry),
					.m_arvalid				(m_arvalid),
					.m_arready				(m_arready),
					
					.m_rlast				(m_rlast),
					.m_rstrb				({COMPONENT_NUM{1'b1}}),
					.m_rdata				(m_rdata),
					.m_rvalid				(m_rvalid),
					.m_rready				(m_rready)
				);
		
		
		// ƒAƒhƒŒƒX•Ê‚ÉL2‚ÉŠ„‚èU‚é
		wire	[M_ID_WIDTH-1:0]	m_arid = ((m_araddrx >> (M_ID_X_RSHIFT)) << M_ID_X_LSHIFT) + ((m_araddry >> (M_ID_Y_RSHIFT)) << M_ID_Y_LSHIFT);
		
		jelly_data_switch
				#(
					.NUM					(M_NUM),
					.ID_WIDTH				(M_ID_WIDTH),
					.DATA_WIDTH				(AR_PACKET_WIDTH),
					.S_REGS					(0),
					.M_REGS					(1)
				)
			i_data_switch
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id					(m_arid),
					.s_data					({m_araddrx, m_araddry}),
					.s_valid				(m_arvalid),
					.s_ready				(m_arready),
					
					.m_data					(cache_arpacket[i*M_NUM*AR_PACKET_WIDTH +: M_NUM*AR_PACKET_WIDTH]),
					.m_valid				(cache_arvalid [i*M_NUM                 +: M_NUM]),
					.m_ready				(cache_arready [i*M_NUM                 +: M_NUM])
				);
		
		
		// read data
		jelly_data_joint
				#(
					.NUM					(M_NUM),
					.DATA_WIDTH				(R_PACKET_WIDTH),
					.NO_CONFLICT			(1),
					.S_REGS					(0),
					.M_REGS					(1)
				)
			i_data_joint
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_data					(cache_rpacket[i*M_NUM*R_PACKET_WIDTH +: M_NUM*R_PACKET_WIDTH]),
					.s_valid				(cache_rvalid [i*M_NUM                +: M_NUM]),
					.s_ready				(cache_rready [i*M_NUM                +: M_NUM]),
					
					.m_data					({m_rlast, m_rdata}),
					.m_valid				(m_rvalid),
					.m_ready				(m_rready)
				);
	end
	endgenerate
	
	
	// -----------------------------
	//  Master port ring-bus
	// -----------------------------
	
	generate
	for ( i = 0; i < M_NUM; i = i+1 ) begin : loop_master
		
		wire	[S_NUM*AR_PACKET_WIDTH-1:0]		s_arpacket;
		wire	[S_NUM-1:0]						s_arvalid;
		wire	[S_NUM-1:0]						s_arready;
		
		wire	[S_NUM*R_PACKET_WIDTH-1:0]		s_rpacket;
		wire	[S_NUM-1:0]						s_rvalid;
		wire	[S_NUM-1:0]						s_rready;
		
		for ( j = 0; j < S_NUM; j = j+1 ) begin : loop_m_ar
			assign s_arpacket[j*AR_PACKET_WIDTH +: AR_PACKET_WIDTH] = cache_arpacket[(j*M_NUM+i)*AR_PACKET_WIDTH +: AR_PACKET_WIDTH];
			assign s_arvalid [j]                                    = cache_arvalid[j*M_NUM+i];
			assign cache_arready[j*M_NUM+i]                         = s_arready[j];
			
			assign cache_rpacket[(j*M_NUM+i)*R_PACKET_WIDTH +: R_PACKET_WIDTH] = s_rpacket[j*R_PACKET_WIDTH +: R_PACKET_WIDTH];
			assign cache_rvalid[j*M_NUM+i]                                     = s_rvalid[j];
			assign s_rready[j]                                                 = cache_rready[j*M_NUM+i];
		end
		
		wire	[S_ID_WIDTH-1:0]		blk_id;
		wire	[M_ADDR_X_WIDTH-1:0]	blk_addrx;
		wire	[M_ADDR_Y_WIDTH-1:0]	blk_addry;
		wire							blk_valid;
		wire							blk_ready;
		
		jelly_ring_bus_arbiter_bidirection
				#(
					.S_NUM				(S_NUM),
					.S_ID_WIDTH			(S_ID_WIDTH),
					.M_NUM				(1),
					.M_ID_WIDTH			(1),
					.DOWN_DATA_WIDTH	(AR_PACKET_WIDTH),
					.UP_DATA_WIDTH		(R_PACKET_WIDTH)
				)
			i_ring_bus_arbiter_bidirection
				(
					.reset				(reset),
					.clk				(clk),
					.cke				(1'b1),
					
					
					.s_down_id_to		(1'b0),
					.s_down_data		(s_arpacket),
					.s_down_valid		(s_arvalid),
					.s_down_ready		(s_arready),
					
					.s_up_id_from		(),
					.s_up_data			(s_rpacket),
					.s_up_valid			(s_rvalid),
					.s_up_ready			(s_rready),
					
					
					.m_down_id_from		(blk_id),
					.m_down_data		({blk_addrx, blk_addry}),
					.m_down_valid		(blk_valid),
					.m_down_ready		(blk_ready),
					
					.m_up_id_to			(m_rid   [i*S_ID_WIDTH +: S_ID_WIDTH]),
					.m_up_data			({m_rlast[i], m_rdata[i*M_DATA_WIDTH +: M_DATA_WIDTH]}),
					.m_up_valid			(m_rvalid[i]),
					.m_up_ready			(m_rready[i])
				);
		
		
		// blk addr
		jelly_texture_blk_addr
				#(
					.USER_WIDTH				(S_ID_WIDTH),
					
					.ADDR_X_WIDTH			(M_ADDR_X_WIDTH),
					.ADDR_Y_WIDTH			(M_ADDR_Y_WIDTH),
					
					.BLK_X_WIDTH			(BLK_X_SIZE - M_DATA_WIDE_SIZE),
					.BLK_Y_WIDTH			(BLK_Y_SIZE)
				)
			i_texture_blk_addr
				(
					.reset					(reset),
					.clk					(clk),
					
					.s_user					(blk_id),
					.s_addrx				(blk_addrx),
					.s_addry				(blk_addry),
					.s_valid				(blk_valid),
					.s_ready				(blk_ready),
					
					.m_user					(m_arid   [i*S_ID_WIDTH     +: S_ID_WIDTH]),
					.m_last					(m_arlast [i]),
					.m_addrx				(m_araddrx[i*M_ADDR_X_WIDTH +: M_ADDR_X_WIDTH]),
					.m_addry				(m_araddry[i*M_ADDR_Y_WIDTH +: M_ADDR_Y_WIDTH]),
					.m_valid				(m_arvalid[i]),
					.m_ready				(m_arready[i])
				);
		
		
	end
	endgenerate
	
	
endmodule


`default_nettype wire


// end of file
