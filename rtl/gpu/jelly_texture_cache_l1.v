// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
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
			
			parameter	M_DATA_WIDE_SIZE     = 0,
			parameter	M_X_SIZE             = 1,
			parameter	M_Y_SIZE             = 1,
			parameter	M_NUM                = (1 << (M_X_SIZE + M_Y_SIZE)),
			parameter	M_DATA_WIDTH         = (S_DATA_WIDTH << M_DATA_WIDE_SIZE),
			parameter	M_ADDR_X_WIDTH       = S_ADDR_X_WIDTH - M_DATA_WIDE_SIZE,
			parameter	M_ADDR_Y_WIDTH       = S_ADDR_Y_WIDTH,
			parameter	M_TAG_ADDR_WIDTH     = 9
		)
		(
			input	wire									reset,
			input	wire									clk,
			
			input	wire									endian,
			
			input	wire									clear_start,
			output	wire									clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]			param_width,
			input	wire	[S_ADDR_X_WIDTH-1:0]			param_height,
			
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
			output	wire	[M_NUM*M_TAG_ADDR_WIDTH-1:0]	m_artagaddr,
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
	
	localparam	M_ID_WIDTH           = (M_X_SIZE + M_Y_SIZE);
	
	localparam	M_DATA_WIDE_NUM      = (1 << M_DATA_WIDE_SIZE);
	
	
	// -----------------------------
	//  L1 Cahce
	// -----------------------------
	
	localparam M_BASE_TAG_ADDR_WIDTH = M_TAG_ADDR_WIDTH + M_X_SIZE + M_Y_SIZE;
	
	localparam AR_DATA_WIDTH = M_TAG_ADDR_WIDTH + M_ADDR_X_WIDTH + M_ADDR_Y_WIDTH;
	localparam R_DATA_WIDTH  = 1 + M_DATA_WIDTH;
	
	wire	[S_NUM-1:0]						cache_clear_busy;
	
	wire	[(S_NUM+1)*M_ID_WIDTH-1:0]		ringbus_l1_ar_id_to;
	wire	[(S_NUM+1)*S_ID_WIDTH-1:0]		ringbus_l1_ar_id_from;
	wire	[(S_NUM+1)*AR_DATA_WIDTH-1:0]	ringbus_l1_ar_data;
	wire	[(S_NUM+1)-1:0]					ringbus_l1_ar_valid;
	
	wire	[(S_NUM+1)*S_ID_WIDTH-1:0]		ringbus_l1_r_id_to;
	wire	[(S_NUM+1)*M_ID_WIDTH-1:0]		ringbus_l1_r_id_from;
	wire	[(S_NUM+1)*R_DATA_WIDTH-1:0]	ringbus_l1_r_data;
	wire	[(S_NUM+1)-1:0]					ringbus_l1_r_valid;
	
	genvar	i, j, k;
	
	generate
	for ( i = 0; i < S_NUM; i = i+1 ) begin : l1_loop
		// L1 cache
		wire	[M_ADDR_X_WIDTH-1:0]	l1_araddrx;
		wire	[M_ADDR_Y_WIDTH-1:0]	l1_araddry;
		wire							l1_arvalid;
		wire							l1_arready;
		
		wire							l1_rlast;
		wire	[M_DATA_WIDTH-1:0]		l1_rdata;
		wire							l1_rvalid;
		wire							l1_rready;
		
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
					
					
					.USE_M_RREADY			(USE_M_RREADY),
					
					.BORDER_DATA			(BORDER_DATA),
					
					.TAG_RAM_TYPE			(TAG_RAM_TYPE),
					.MEM_RAM_TYPE			(MEM_RAM_TYPE)
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
					
					.s_aruser				(s_aruser [i*S_USER_WIDTH   +: S_USER_WIDTH]),
					.s_araddrx				(s_araddrx[i*S_ADDR_X_WIDTH +: S_ADDR_X_WIDTH]),
					.s_araddry				(s_araddry[i*S_ADDR_Y_WIDTH +: S_ADDR_Y_WIDTH]),
					.s_arvalid				(s_arvalid[i]),
					.s_arready				(s_arready[i]),
					
					.s_ruser				(s_ruser  [i*S_USER_WIDTH   +: S_USER_WIDTH]),
					.s_rdata				(s_rdata  [i*S_DATA_WIDTH +: S_DATA_WIDTH]),
					.s_rvalid				(s_rvalid [i]),
					.s_rready				(s_rready [i]),
					
					.m_araddrx				(l1_araddrx),
					.m_araddry				(l1_araddry),
					.m_arvalid				(l1_arvalid),
					.m_arready				(l1_arready),
					
					.m_rlast				(l1_rlast),
					.m_rstrb				({COMPONENT_NUM{1'b1}}),
					.m_rdata				(l1_rdata),
					.m_rvalid				(l1_rvalid),
					.m_rready				(l1_rready)
				);
		
		
//		wire	[M_ID_WIDTH-1:0]	l2_id = ((l1_araddrx & ((1 << M_X_SIZE)-1)) | ((l1_araddry & ((1 << M_Y_SIZE)-1)) << M_X_SIZE));
		
		wire	[M_ID_WIDTH-1:0]	l2_id = (l1_araddrx + (l1_araddry << ((1 << M_Y_SIZE)/2)));
		
		
	//	wire	[M_BASE_TAG_ADDR_WIDTH-1:0]	l2_base_tag_addr = (l1_araddrx + (l1_araddry >> (M_BASE_TAG_ADDR_WIDTH/2)));
	//	wire	[M_ID_WIDTH-1:0]			l2_id            = l2_base_tag_addr;
	//	wire	[M_TAG_ADDR_WIDTH-1:0]		l2_tag_addr      = (l2_base_tag_addr >> M_ID_WIDTH);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(AR_DATA_WIDTH),
					.ID_TO_WIDTH			(M_ID_WIDTH),
					.ID_FROM_WIDTH			(S_ID_WIDTH),
					.UNIT_ID_TO				(0),
					.UNIT_ID_FROM			(i)
				)
			i_ring_bus_unit_l1_ar
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id_to				(l2_id),
					.s_data					({l2_tag_addr, l1_araddry, l1_araddrx}),
					.s_valid				(l1_arvalid),
					.s_ready				(l1_arready),
					
					.m_id_from				(),
					.m_data					(),
					.m_valid				(),
					.m_ready				(1'b0),
					
					.src_id_to				(ringbus_l1_ar_id_to  [(i+1)*M_ID_WIDTH    +: M_ID_WIDTH]),
					.src_id_from			(ringbus_l1_ar_id_from[(i+1)*S_ID_WIDTH    +: S_ID_WIDTH]),
					.src_data				(ringbus_l1_ar_data   [(i+1)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.src_valid				(ringbus_l1_ar_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l1_ar_id_to  [(i+0)*M_ID_WIDTH    +: M_ID_WIDTH]),
					.sink_id_from			(ringbus_l1_ar_id_from[(i+0)*S_ID_WIDTH    +: S_ID_WIDTH]),
					.sink_data				(ringbus_l1_ar_data   [(i+0)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.sink_valid				(ringbus_l1_ar_valid  [(i+0)])
				);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(R_DATA_WIDTH),
					.ID_TO_WIDTH			(S_ID_WIDTH),
					.ID_FROM_WIDTH			(M_ID_WIDTH),
					.UNIT_ID_TO				(i),
					.UNIT_ID_FROM			(0)
				)
			i_ring_bus_unit_l1_r
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id_to				(0),
					.s_data					(0),
					.s_valid				(1'b0),
					.s_ready				(),
					
					.m_id_from				(),
					.m_data					({l1_rlast, l1_rdata}),
					.m_valid				(l1_rvalid),
					.m_ready				(l1_rready),
					
					.src_id_to				(ringbus_l1_r_id_to  [(i+1)*S_ID_WIDTH   +: S_ID_WIDTH]),
					.src_id_from			(ringbus_l1_r_id_from[(i+1)*M_ID_WIDTH   +: M_ID_WIDTH]),
					.src_data				(ringbus_l1_r_data   [(i+1)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.src_valid				(ringbus_l1_r_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l1_r_id_to  [(i+0)*S_ID_WIDTH   +: S_ID_WIDTH]),
					.sink_id_from			(ringbus_l1_r_id_from[(i+0)*M_ID_WIDTH   +: M_ID_WIDTH]),
					.sink_data				(ringbus_l1_r_data   [(i+0)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.sink_valid				(ringbus_l1_r_valid  [(i+0)])
				);
	end
	endgenerate
	
	
	
	// -----------------------------
	//  L1 Ring-Bus
	// -----------------------------
	
	wire	[(M_NUM+1)*M_ID_WIDTH-1:0]		ringbus_l2_ar_id_to;
	wire	[(M_NUM+1)*S_ID_WIDTH-1:0]		ringbus_l2_ar_id_from;
	wire	[(M_NUM+1)*AR_DATA_WIDTH-1:0]	ringbus_l2_ar_data;
	wire	[(M_NUM+1)-1:0]					ringbus_l2_ar_valid;
	
	wire	[(M_NUM+1)*S_ID_WIDTH-1:0]		ringbus_l2_r_id_to;
	wire	[(M_NUM+1)*M_ID_WIDTH-1:0]		ringbus_l2_r_id_from;
	wire	[(M_NUM+1)*R_DATA_WIDTH-1:0]	ringbus_l2_r_data;
	wire	[(M_NUM+1)-1:0]					ringbus_l2_r_valid;
	
	generate
	for ( i = 0; i < M_NUM; i = i+1 ) begin : l2_loop
		wire	[S_ID_WIDTH-1:0]		blk_id;
		wire	[M_TAG_ADDR_WIDTH-1:0]	blk_tagaddr;
		wire	[M_ADDR_X_WIDTH-1:0]	blk_addrx;
		wire	[M_ADDR_Y_WIDTH-1:0]	blk_addry;
		wire							blk_valid;
		wire							blk_ready;
		
		// blk addr
		jelly_texture_blk_addr
				#(
					.USER_WIDTH				(M_TAG_ADDR_WIDTH+S_ID_WIDTH),
					
					.ADDR_X_WIDTH			(M_ADDR_X_WIDTH),
					.ADDR_Y_WIDTH			(M_ADDR_Y_WIDTH),
					
					.BLK_X_WIDTH			(BLK_X_SIZE - M_DATA_WIDE_SIZE),
					.BLK_Y_WIDTH			(BLK_Y_SIZE)
				)
			i_texture_blk_addr
				(
					.reset					(reset),
					.clk					(clk),
					
					.s_user					({blk_tagaddr, blk_id}),
					.s_addrx				(blk_addrx),
					.s_addry				(blk_addry),
					.s_valid				(blk_valid),
					.s_ready				(blk_ready),
					
					.m_user					({
											 m_artagaddr[i*M_TAG_ADDR_WIDTH +: M_TAG_ADDR_WIDTH],
											 m_arid     [i*S_ID_WIDTH       +: S_ID_WIDTH]
											 }),
					.m_last					(m_arlast   [i]),
					.m_addrx				(m_araddrx  [i*M_ADDR_X_WIDTH   +: M_ADDR_X_WIDTH]),
					.m_addry				(m_araddry  [i*M_ADDR_Y_WIDTH   +: M_ADDR_Y_WIDTH]),
					.m_valid				(m_arvalid  [i]),
					.m_ready				(m_arready  [i])
				);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(AR_DATA_WIDTH),
					.ID_TO_WIDTH			(M_ID_WIDTH),
					.ID_FROM_WIDTH			(S_ID_WIDTH),
					.UNIT_ID_TO				(i),
					.UNIT_ID_FROM			(0)
				)
			i_ring_bus_unit_l2_ar
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id_to				(0),
					.s_data					(0),
					.s_valid				(1'b0),
					.s_ready				(),
					
					.m_id_from				(blk_id),
					.m_data					({blk_tagaddr, blk_addry, blk_addrx}),
					.m_valid				(blk_valid),
					.m_ready				(blk_ready),
					
					.src_id_to				(ringbus_l2_ar_id_to  [(i+1)*M_ID_WIDTH    +: M_ID_WIDTH]),
					.src_id_from			(ringbus_l2_ar_id_from[(i+1)*S_ID_WIDTH    +: S_ID_WIDTH]),
					.src_data				(ringbus_l2_ar_data   [(i+1)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.src_valid				(ringbus_l2_ar_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l2_ar_id_to  [(i+0)*M_ID_WIDTH    +: M_ID_WIDTH]),
					.sink_id_from			(ringbus_l2_ar_id_from[(i+0)*S_ID_WIDTH    +: S_ID_WIDTH]),
					.sink_data				(ringbus_l2_ar_data   [(i+0)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.sink_valid				(ringbus_l2_ar_valid  [(i+0)])
				);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(R_DATA_WIDTH),
					.ID_TO_WIDTH			(S_ID_WIDTH),
					.ID_FROM_WIDTH			(M_ID_WIDTH),
					.UNIT_ID_TO				(0),
					.UNIT_ID_FROM			(0)
				)
			i_ring_bus_unit_l2_r
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id_to				(m_rid[i*S_ID_WIDTH +: S_ID_WIDTH]),
					.s_data					({m_rlast[i], m_rdata[i*M_DATA_WIDTH +: M_DATA_WIDTH]}),
					.s_valid				(m_rvalid[i]),
					.s_ready				(m_rready[i]),
					
					.m_id_from				(),
					.m_data					(),
					.m_valid				(),
					.m_ready				(1'b0),
					
					.src_id_to				(ringbus_l2_r_id_to  [(i+1)*S_ID_WIDTH   +: S_ID_WIDTH]),
					.src_id_from			(ringbus_l2_r_id_from[(i+1)*M_ID_WIDTH   +: M_ID_WIDTH]),
					.src_data				(ringbus_l2_r_data   [(i+1)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.src_valid				(ringbus_l2_r_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l2_r_id_to  [(i+0)*S_ID_WIDTH   +: S_ID_WIDTH]),
					.sink_id_from			(ringbus_l2_r_id_from[(i+0)*M_ID_WIDTH   +: M_ID_WIDTH]),
					.sink_data				(ringbus_l2_r_data   [(i+0)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.sink_valid				(ringbus_l2_r_valid  [(i+0)])
				);
	end
	endgenerate
	
	
	assign ringbus_l1_ar_id_to  [S_NUM*M_ID_WIDTH    +: M_ID_WIDTH]    = ringbus_l2_ar_id_to  [0 +: M_ID_WIDTH];
	assign ringbus_l1_ar_id_from[S_NUM*S_ID_WIDTH    +: S_ID_WIDTH]    = ringbus_l2_ar_id_from[0 +: S_ID_WIDTH];
	assign ringbus_l1_ar_data   [S_NUM*AR_DATA_WIDTH +: AR_DATA_WIDTH] = ringbus_l2_ar_data   [0 +: AR_DATA_WIDTH];
	assign ringbus_l1_ar_valid  [S_NUM]                                = ringbus_l2_ar_valid  [0];
	
	assign ringbus_l2_ar_id_to  [M_NUM*M_ID_WIDTH    +: M_ID_WIDTH]    = ringbus_l1_ar_id_to  [0 +: M_ID_WIDTH];
	assign ringbus_l2_ar_id_from[M_NUM*S_ID_WIDTH    +: S_ID_WIDTH]    = ringbus_l1_ar_id_from[0 +: S_ID_WIDTH];
	assign ringbus_l2_ar_data   [M_NUM*AR_DATA_WIDTH +: AR_DATA_WIDTH] = ringbus_l1_ar_data   [0 +: AR_DATA_WIDTH];
	assign ringbus_l2_ar_valid  [M_NUM]                                = ringbus_l1_ar_valid  [0];
	
	
	assign ringbus_l1_r_id_to   [S_NUM*S_ID_WIDTH   +: S_ID_WIDTH]     = ringbus_l2_r_id_to   [0 +: S_ID_WIDTH];
	assign ringbus_l1_r_id_from [S_NUM*M_ID_WIDTH   +: M_ID_WIDTH]     = ringbus_l2_r_id_from [0 +: M_ID_WIDTH];
	assign ringbus_l1_r_data    [S_NUM*R_DATA_WIDTH +: R_DATA_WIDTH]   = ringbus_l2_r_data    [0 +: R_DATA_WIDTH];
	assign ringbus_l1_r_valid   [S_NUM]                                = ringbus_l2_r_valid   [0];
	
	assign ringbus_l2_r_id_to   [M_NUM*S_ID_WIDTH   +: S_ID_WIDTH]     = ringbus_l1_r_id_to   [0 +: S_ID_WIDTH];
	assign ringbus_l2_r_id_from [M_NUM*M_ID_WIDTH   +: M_ID_WIDTH]     = ringbus_l1_r_id_from [0 +: M_ID_WIDTH];
	assign ringbus_l2_r_data    [M_NUM*R_DATA_WIDTH +: R_DATA_WIDTH]   = ringbus_l1_r_data    [0 +: R_DATA_WIDTH];
	assign ringbus_l2_r_valid   [M_NUM]                                = ringbus_l1_r_valid   [0];
		
endmodule


`default_nettype wire


// end of file
