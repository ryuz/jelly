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
			
			parameter	M_PARALLEL_SIZE      = 2,
			parameter	M_NUM                = (1 << M_PARALLEL_SIZE),
			parameter	M_DATA_WIDE_SIZE     = 1,
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
	
	
	
	// -----------------------------
	//  Cahce
	// -----------------------------
	
	wire	[S_NUM-1:0]							cache_clear_busy;
	assign clear_busy = cache_clear_busy[0];
	
	
	wire	[S_NUM*M_ID_WIDTH-1:0]		cache_arid;
	wire	[S_NUM*AR_PACKET_WIDTH-1:0]	cache_arpacket;
	wire	[S_NUM-1:0]					cache_arvalid;
	wire	[S_NUM-1:0]					cache_arready;
	
	wire	[S_NUM-1:0]					cache_rlast;
	wire	[S_NUM*M_DATA_WIDTH-1:0]	cache_rdata;
	wire	[S_NUM-1:0]					cache_rvalid;
	wire	[S_NUM-1:0]					cache_rready;
	
	generate
	for ( i = 0; i < S_NUM; i = i+1 ) begin : loop_cache
		// L1 cache
		wire	[M_ADDR_X_WIDTH-1:0]	unit_araddrx;
		wire	[M_ADDR_Y_WIDTH-1:0]	unit_araddry;
		wire							unit_arvalid;
		wire							unit_arready;
		
		wire							unit_rlast;
		wire	[M_DATA_WIDTH-1:0]		unit_rdata;
		wire							unit_rvalid;
		wire							unit_rready;
		
		jelly_texture_cache_unit
				#(
					.COMPONENT_NUM			(COMPONENT_NUM),
					.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
					
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
					.s_rdata				(s_rdata  [i*S_DATA_WIDTH +: S_DATA_WIDTH]),
					.s_rvalid				(s_rvalid [i]),
					.s_rready				(s_rready [i]),
					
					.m_araddrx				(unit_araddrx),
					.m_araddry				(unit_araddry),
					.m_arvalid				(unit_arvalid),
					.m_arready				(unit_arready),
					
					.m_rlast				(unit_rlast),
					.m_rstrb				({COMPONENT_NUM{1'b1}}),
					.m_rdata				(unit_rdata),
					.m_rvalid				(unit_rvalid),
					.m_rready				(unit_rready)
				);
		
		
		// ƒAƒhƒŒƒX•Ê‚ÉL2‚ÉŠ„‚èU‚é
		wire	[M_ID_WIDTH-1:0]	unit_arid = ((unit_araddrx >> (M_ID_X_RSHIFT)) << M_ID_X_LSHIFT) + ((unit_araddry >> (M_ID_Y_RSHIFT)) << M_ID_Y_LSHIFT);
		
		/*
		wire	[M_ID_WIDTH-1:0]	unit_arid;
		jelly_texture_cache_tag_addr
				#(
					.PARALLEL_SIZE		(M_PARALLEL_SIZE),
					
					.ADDR_X_WIDTH		(M_ADDR_X_WIDTH),
					.ADDR_Y_WIDTH		(M_ADDR_Y_WIDTH),
					.TAG_ADDR_WIDTH		(4)
				)
			i_texture_cache_tag_addr
				(
					.addrx				(tag_addr_x),
					.addry				(tag_addr_y),
					
					.unit_id			(),
					.tag_addr			()
				);
		*/
		
		
		assign cache_arid    [i*M_ID_WIDTH      +: M_ID_WIDTH]      = unit_arid;
		assign cache_arpacket[i*AR_PACKET_WIDTH +: AR_PACKET_WIDTH] = {unit_araddrx, unit_araddry};
		assign cache_arvalid [i]                                    = unit_arvalid;
		assign unit_arready                                         = cache_arready[i];
		
		assign unit_rlast      = cache_rlast [i];
		assign unit_rdata      = cache_rdata [i*M_DATA_WIDTH +: M_DATA_WIDTH];
		assign unit_rvalid     = cache_rvalid[i];
		assign cache_rready[i] = unit_rready;
	end
	endgenerate
	
	
	
	// -----------------------------
	//  Arbiter
	// -----------------------------
	
	/*
	wire	[M_NUM*S_ID_WIDTH-1:0]		arbit_arid;
	wire	[M_NUM*AR_PACKET_WIDTH-1:0]	arbit_arpacket;
	wire	[M_NUM-1:0]					arbit_arvalid;
	wire	[M_NUM-1:0]					arbit_arready;
	
	wire	[M_NUM*S_ID_WIDTH-1:0]		arbit_rid;
	wire	[M_NUM-1:0]					arbit_rlast;
	wire	[M_NUM*M_DATA_WIDTH-1:0]	arbit_rdata;
	wire	[M_NUM-1:0]					arbit_rvalid;
	wire	[M_NUM-1:0]					arbit_rready;
	
	jelly_stream_arbiter_bidirection
			#(
				.S_NUM					(S_NUM),
				.S_ID_WIDTH				(S_ID_WIDTH),
				.M_NUM					(M_NUM),
				.M_ID_WIDTH				(M_ID_WIDTH),
				.REQ_DATA_WIDTH			(AR_PACKET_WIDTH),
				.REQ_LEN_WIDTH			(0),
				.ACK_DATA_WIDTH			(M_DATA_WIDTH),
				.ACK_LEN_WIDTH			(8),
				.IN_ORDER				(USE_LOOK_AHEAD && (M_NUM > 1)),
				.ORDER_FIFO_PTR_WIDTH	(6),
				.ORDER_FIFO_RAM_TYPE	("distributed")
			)
		i_ring_bus_crossbar_bidirection
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(1'b1),
				
				.s_req_id_to			(cache_arid),
				.s_req_last				({S_NUM{1'b1}}),
				.s_req_data				(cache_arpacket),
				.s_req_valid			(cache_arvalid),
				.s_req_ready			(cache_arready),
				
				.s_ack_id_from			(),
				.s_ack_last				(cache_rlast),
				.s_ack_data				(cache_rdata),
				.s_ack_valid			(cache_rvalid),
				.s_ack_ready			(cache_rready),
				
				
				.m_req_id_from			(arbit_arid),
				.m_req_last				(),
				.m_req_data				(arbit_arpacket),
				.m_req_valid			(arbit_arvalid),
				.m_req_ready			(arbit_arready),
				
				.m_ack_id_to			(arbit_rid),
				.m_ack_last				(arbit_rlast),
				.m_ack_data				(arbit_rdata),
				.m_ack_valid			(arbit_rvalid),
				.m_ack_ready			(arbit_rready)
			);
	*/
	
	
	wire	[M_NUM*S_ID_WIDTH-1:0]		arbit_arid;
	wire	[M_NUM*AR_PACKET_WIDTH-1:0]	arbit_arpacket;
	wire	[M_NUM-1:0]					arbit_arvalid;
	wire	[M_NUM-1:0]					arbit_arready;
	
	jelly_data_arbiter_ring_bus
			#(
				.S_NUM				(S_NUM),
				.S_ID_WIDTH			(S_ID_WIDTH),
				.M_NUM				(M_NUM),
				.M_ID_WIDTH			(M_ID_WIDTH),
				.DATA_WIDTH			(AR_PACKET_WIDTH)
			)
		i_data_arbiter_ring_bus
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_id_to			(cache_arid),
				.s_data				(cache_arpacket),
				.s_valid			(cache_arvalid),
				.s_ready			(cache_arready),
				
				.m_id_from			(arbit_arid),
				.m_data				(arbit_arpacket),
				.m_valid			(arbit_arvalid),
				.m_ready			(arbit_arready)
			);
	
	
	wire	[M_NUM*S_ID_WIDTH-1:0]		arbit_rid;
	wire	[M_NUM-1:0]					arbit_rlast;
	wire	[M_NUM*M_DATA_WIDTH-1:0]	arbit_rdata;
	wire	[M_NUM-1:0]					arbit_rvalid;
	wire	[M_NUM-1:0]					arbit_rready;
	
	jelly_stream_arbiter_crossbar
			#(
				.S_NUM				(M_NUM),
				.S_ID_WIDTH			(M_ID_WIDTH),
				.M_NUM				(S_NUM),
				.M_ID_WIDTH			(S_ID_WIDTH),
				.DATA_WIDTH			(M_DATA_WIDTH)
			)
		i_stream_arbiter_crossbar_r
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_id_to			(arbit_rid),
				.s_last				(arbit_rlast),
				.s_data				(arbit_rdata),
				.s_valid			(arbit_rvalid),
				.s_ready			(arbit_rready),
				
				.m_id_from			(),
				.m_last				(cache_rlast),
				.m_data				(cache_rdata),
				.m_valid			(cache_rvalid),
				.m_ready			(cache_rready)
			);
	
	
	/*
	jelly_ring_bus_crossbar_bidirection
			#(
				.S_NUM				(S_NUM),
				.S_ID_WIDTH			(S_ID_WIDTH),
				.M_NUM				(M_NUM),
				.M_ID_WIDTH			(M_ID_WIDTH),
				.DOWN_DATA_WIDTH	(AR_PACKET_WIDTH),
				.UP_DATA_WIDTH		(R_PACKET_WIDTH)
			)
		i_ring_bus_crossbar_bidirection
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_down_id_to		(cache_arid),
				.s_down_data		(cache_arpacket),
				.s_down_valid		(cache_arvalid),
				.s_down_ready		(cache_arready),
				
				.s_up_id_from		(),
				.s_up_data			(cache_rpacket),
				.s_up_valid			(cache_rvalid),
				.s_up_ready			(cache_rready),
				
				.m_down_id_from		(arbit_arid),
				.m_down_data		(arbit_arpacket),
				.m_down_valid		(arbit_arvalid),
				.m_down_ready		(arbit_arready),
				
				.m_up_id_to			(arbit_rid),
				.m_up_data			(arbit_rpacket),
				.m_up_valid			(arbit_rvalid),
				.m_up_ready			(arbit_rready)
			);
	*/
	
	
	// -----------------------------
	//  Master port
	// -----------------------------
	
	generate
	for ( i = 0; i < M_NUM; i = i+1 ) begin : loop_master
		
		// blk addr
		wire	[S_ID_WIDTH-1:0]		blk_id;
		wire	[M_ADDR_X_WIDTH-1:0]	blk_addrx;
		wire	[M_ADDR_Y_WIDTH-1:0]	blk_addry;
		wire							blk_valid;
		wire							blk_ready;
		
		assign blk_id                 = arbit_arid    [i*S_ID_WIDTH      +: S_ID_WIDTH];
		assign {blk_addrx, blk_addry} = arbit_arpacket[i*AR_PACKET_WIDTH +: AR_PACKET_WIDTH];
		assign blk_valid              = arbit_arvalid [i];
		assign arbit_arready[i]       = blk_ready;
		
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
		
		
		// rdata
		assign arbit_rid   [i*S_ID_WIDTH   +: S_ID_WIDTH]    = m_rid[i*S_ID_WIDTH +: S_ID_WIDTH];
		assign arbit_rlast [i]                               = m_rlast[i];
		assign arbit_rdata [i*M_DATA_WIDTH +: M_DATA_WIDTH]  = m_rdata[i*M_DATA_WIDTH +: M_DATA_WIDTH];
		assign arbit_rvalid[i]                               = m_rvalid[i];
		assign m_rready    [i]                               = arbit_rready[i];
	end
	endgenerate
	
	
endmodule


`default_nettype wire


// end of file
