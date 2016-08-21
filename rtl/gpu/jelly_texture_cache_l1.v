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
			parameter	L1_CACHE_NUM         = 4,
			parameter	L2_CACHE_X_SIZE      = 1,
			parameter	L2_CACHE_Y_SIZE      = 1,
			parameter	L2_CACHE_NUM         = (1 << (L2_CACHE_X_SIZE + L2_CACHE_Y_SIZE)),
			
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_SEL_WIDTH  = COMPONENT_NUM <= 2  ?  1 :
			                                   COMPONENT_NUM <= 4  ?  2 :
			                                   COMPONENT_NUM <= 8  ?  3 :
			                                   COMPONENT_NUM <= 16 ?  4 :
			                                   COMPONENT_NUM <= 32 ?  5 :
			                                   COMPONENT_NUM <= 64 ?  6 : 7,
			parameter	COMPONENT_DATA_WIDTH = 8,
			
			parameter	USER_WIDTH           = 1,
			
			parameter	ADDR_X_WIDTH         = 12,
			parameter	ADDR_Y_WIDTH         = 12,
			parameter	S_DATA_WIDTH         = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			
			parameter	TAG_ADDR_WIDTH       = 6,
			
			parameter	L1_ID_WIDTH          = L1_CACHE_NUM <=    2 ? 1 :
			                                   L1_CACHE_NUM <=    4 ? 2 :
			                                   L1_CACHE_NUM <=    8 ? 3 :
			                                   L1_CACHE_NUM <=   16 ? 4 :
			                                   L1_CACHE_NUM <=   32 ? 5 :
			                                   L1_CACHE_NUM <=   64 ? 6 :
			                                   L1_CACHE_NUM <=  128 ? 7 :
			                                   L1_CACHE_NUM <=  256 ? 8 : 9,
			
			parameter	L1_BLK_X_SIZE        = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L1_BLK_Y_SIZE        = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			
			parameter	M_DATA_WIDE_SIZE     = 0,
			parameter	M_DATA_WIDTH         = (S_DATA_WIDTH << M_DATA_WIDE_SIZE),
			
			parameter	L2_ID_WIDTH          = (L2_CACHE_X_SIZE + L2_CACHE_Y_SIZE),
			parameter	L2_BLK_X_SIZE        = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L2_BLK_Y_SIZE        = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			
			parameter	USE_M_RREADY         = 0,	// 0: m_rready is always 1'b1.   1: handshake mode.
			
			parameter	BORDER_DATA          = {S_DATA_WIDTH{1'b0}},
			
			parameter	TAG_RAM_TYPE         = "distributed",
			parameter	MEM_RAM_TYPE         = "block"
		)
		(
			input	wire											reset,
			input	wire											clk,
			
			input	wire											endian,
			
			input	wire											clear_start,
			output	wire											clear_busy,
			
			input	wire	[ADDR_X_WIDTH-1:0]						param_width,
			input	wire	[ADDR_X_WIDTH-1:0]						param_height,
			
			
			input	wire	[L1_CACHE_NUM*USER_WIDTH-1:0]			s_aruser,
			input	wire	[L1_CACHE_NUM*ADDR_X_WIDTH-1:0]			s_araddrx,
			input	wire	[L1_CACHE_NUM*ADDR_Y_WIDTH-1:0]			s_araddry,
			input	wire	[L1_CACHE_NUM-1:0]						s_arvalid,
			output	wire	[L1_CACHE_NUM-1:0]						s_arready,
			
			output	wire	[L1_CACHE_NUM*USER_WIDTH-1:0]			s_ruser,
			output	wire	[L1_CACHE_NUM*S_DATA_WIDTH-1:0]			s_rdata,
			output	wire	[L1_CACHE_NUM-1:0]						s_rvalid,
			input	wire	[L1_CACHE_NUM-1:0]						s_rready,
			
			
			output	wire	[L2_CACHE_NUM*L1_ID_WIDTH-1:0]			m_arid,
			output	wire	[L2_CACHE_NUM-1:0]						m_arlast,
			output	wire	[L2_CACHE_NUM*ADDR_X_WIDTH-1:0]			m_araddrx,
			output	wire	[L2_CACHE_NUM*ADDR_Y_WIDTH-1:0]			m_araddry,
			output	wire	[L2_CACHE_NUM-1:0]						m_arvalid,
			input	wire	[L2_CACHE_NUM-1:0]						m_arready,
			
			input	wire	[L2_CACHE_NUM*L1_ID_WIDTH-1:0]			m_rid,
			input	wire	[L2_CACHE_NUM-1:0]						m_rlast,
			input	wire	[L2_CACHE_NUM*M_DATA_WIDTH-1:0]			m_rdata,
			input	wire	[L2_CACHE_NUM-1:0]						m_rvalid,
			output	wire	[L2_CACHE_NUM-1:0]						m_rready
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
		
	localparam	M_ADDR_X_WIDTH       = ADDR_X_WIDTH - L1_BLK_X_SIZE;
	localparam	M_ADDR_Y_WIDTH       = ADDR_Y_WIDTH - L1_BLK_Y_SIZE;
	
	localparam	M_DATA_WIDE_NUM      = (1 << M_DATA_WIDE_SIZE);
	
	
	// -----------------------------
	//  L1 Cahce
	// -----------------------------
	
	localparam AR_DATA_WIDTH = M_ADDR_X_WIDTH + M_ADDR_Y_WIDTH;
	localparam R_DATA_WIDTH  = 1 + M_DATA_WIDTH;
	
	wire	[L1_CACHE_NUM-1:0]						cache_clear_busy;
	
	wire	[(L1_CACHE_NUM+1)*L2_ID_WIDTH-1:0]		ringbus_l1_ar_id_to;
	wire	[(L1_CACHE_NUM+1)*L1_ID_WIDTH-1:0]		ringbus_l1_ar_id_from;
	wire	[(L1_CACHE_NUM+1)*AR_DATA_WIDTH-1:0]	ringbus_l1_ar_data;
	wire	[(L1_CACHE_NUM+1)-1:0]					ringbus_l1_ar_valid;
	
	wire	[(L1_CACHE_NUM+1)*L1_ID_WIDTH-1:0]		ringbus_l1_r_id_to;
	wire	[(L1_CACHE_NUM+1)*L2_ID_WIDTH-1:0]		ringbus_l1_r_id_from;
	wire	[(L1_CACHE_NUM+1)*R_DATA_WIDTH-1:0]		ringbus_l1_r_data;
	wire	[(L1_CACHE_NUM+1)-1:0]					ringbus_l1_r_valid;
	
	genvar	i, j, k;
	
	generate
	for ( i = 0; i < L1_CACHE_NUM; i = i+1 ) begin : l1_loop
		// L1 cache
		wire	[M_ADDR_X_WIDTH-1:0]		l1_araddrx;
		wire	[M_ADDR_Y_WIDTH-1:0]		l1_araddry;
		wire								l1_arvalid;
		wire								l1_arready;
		
		wire								l1_rlast;
		wire	[M_DATA_WIDTH-1:0]			l1_rdata;
		wire	[M_DATA_WIDTH-1:0]			l1_rdata_tmp;
		wire								l1_rvalid;
		wire								l1_rready;
		
		for ( j = 0; j < M_DATA_WIDE_NUM; j = j+1 ) begin : j_loop
			for ( k = 0; k < COMPONENT_NUM; k = k+1 ) begin : k_loop
				assign l1_rdata[(j*COMPONENT_NUM+k)*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH]
								= l1_rdata_tmp[(k*M_DATA_WIDE_NUM+j)*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH];
			end
		end
		
		jelly_texture_cache_unit
				#(
					.USER_WIDTH				(USER_WIDTH),
					
					.COMPONENT_NUM			(1),
					.COMPONENT_DATA_WIDTH	(S_DATA_WIDTH),
					
					.S_ADDR_X_WIDTH			(ADDR_X_WIDTH),
					.S_ADDR_Y_WIDTH			(ADDR_Y_WIDTH),
					.S_DATA_WIDTH			(S_DATA_WIDTH),
					
					.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
					
					.BLK_X_SIZE				(L1_BLK_X_SIZE),
					.BLK_Y_SIZE				(L1_BLK_Y_SIZE),
					
					.M_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
					
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
					
					.s_aruser				(s_aruser [i*USER_WIDTH   +: USER_WIDTH]),
					.s_araddrx				(s_araddrx[i*ADDR_X_WIDTH +: ADDR_X_WIDTH]),
					.s_araddry				(s_araddry[i*ADDR_Y_WIDTH +: ADDR_Y_WIDTH]),
					.s_arvalid				(s_arvalid[i]),
					.s_arready				(s_arready[i]),
					
					.s_ruser				(s_ruser  [i*USER_WIDTH   +: USER_WIDTH]),
					.s_rdata				(s_rdata  [i*S_DATA_WIDTH +: S_DATA_WIDTH]),
					.s_rvalid				(s_rvalid [i]),
					.s_rready				(s_rready [i]),
					
					.m_araddrx				(l1_araddrx),
					.m_araddry				(l1_araddry),
					.m_arvalid				(l1_arvalid),
					.m_arready				(l1_arready),
					
					.m_rlast				(l1_rlast),
					.m_rstrb				(1'b1),
					.m_rdata				(l1_rdata),
					.m_rvalid				(l1_rvalid),
					.m_rready				(l1_rready)
				);
		
		
		wire	[L2_ID_WIDTH-1:0]	l2_id = ((l1_araddrx & ((1 << L2_CACHE_X_SIZE)-1)) | ((l1_araddry & ((1 << L2_CACHE_Y_SIZE)-1)) << L2_CACHE_X_SIZE));
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(AR_DATA_WIDTH),
					.ID_TO_WIDTH			(L2_ID_WIDTH),
					.ID_FROM_WIDTH			(L1_ID_WIDTH),
					.UNIT_ID_TO				(0),
					.UNIT_ID_FROM			(i)
				)
			i_ring_bus_unit_l1_ar
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id_to				(l2_id),
					.s_data					({l1_araddry, l1_araddrx}),
					.s_valid				(l1_arvalid),
					.s_ready				(l1_arready),
					
					.m_id_from				(),
					.m_data					(),
					.m_valid				(),
					.m_ready				(1'b0),
					
					.src_id_to				(ringbus_l1_ar_id_to  [(i+1)*L2_ID_WIDTH   +: L2_ID_WIDTH]),
					.src_id_from			(ringbus_l1_ar_id_from[(i+1)*L1_ID_WIDTH   +: L1_ID_WIDTH]),
					.src_data				(ringbus_l1_ar_data   [(i+1)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.src_valid				(ringbus_l1_ar_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l1_ar_id_to  [(i+0)*L2_ID_WIDTH   +: L2_ID_WIDTH]),
					.sink_id_from			(ringbus_l1_ar_id_from[(i+0)*L1_ID_WIDTH   +: L1_ID_WIDTH]),
					.sink_data				(ringbus_l1_ar_data   [(i+0)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.sink_valid				(ringbus_l1_ar_valid  [(i+0)])
				);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(R_DATA_WIDTH),
					.ID_TO_WIDTH			(L1_ID_WIDTH),
					.ID_FROM_WIDTH			(L2_ID_WIDTH),
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
					.m_data					({l1_rlast, l1_rdata_tmp}),
					.m_valid				(l1_rvalid),
					.m_ready				(l1_rready),
					
					.src_id_to				(ringbus_l1_r_id_to  [(i+1)*L1_ID_WIDTH  +: L1_ID_WIDTH]),
					.src_id_from			(ringbus_l1_r_id_from[(i+1)*L2_ID_WIDTH  +: L2_ID_WIDTH]),
					.src_data				(ringbus_l1_r_data   [(i+1)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.src_valid				(ringbus_l1_r_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l1_r_id_to  [(i+0)*L1_ID_WIDTH  +: L1_ID_WIDTH]),
					.sink_id_from			(ringbus_l1_r_id_from[(i+0)*L2_ID_WIDTH  +: L2_ID_WIDTH]),
					.sink_data				(ringbus_l1_r_data   [(i+0)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.sink_valid				(ringbus_l1_r_valid  [(i+0)])
				);
	end
	endgenerate
	
	
	
	// -----------------------------
	//  L1 Ring-Bus
	// -----------------------------
	
	wire	[(L2_CACHE_NUM+1)*L2_ID_WIDTH-1:0]		ringbus_l2_ar_id_to;
	wire	[(L2_CACHE_NUM+1)*L1_ID_WIDTH-1:0]		ringbus_l2_ar_id_from;
	wire	[(L2_CACHE_NUM+1)*AR_DATA_WIDTH-1:0]	ringbus_l2_ar_data;
	wire	[(L2_CACHE_NUM+1)-1:0]					ringbus_l2_ar_valid;
	
	wire	[(L2_CACHE_NUM+1)*L1_ID_WIDTH-1:0]		ringbus_l2_r_id_to;
	wire	[(L2_CACHE_NUM+1)*L2_ID_WIDTH-1:0]		ringbus_l2_r_id_from;
	wire	[(L2_CACHE_NUM+1)*R_DATA_WIDTH-1:0]		ringbus_l2_r_data;
	wire	[(L2_CACHE_NUM+1)-1:0]					ringbus_l2_r_valid;
	
	generate
	for ( i = 0; i < L2_CACHE_NUM; i = i+1 ) begin : l2_loop
		wire	[L2_ID_WIDTH-1:0]		blk_id;
		wire	[M_ADDR_X_WIDTH-1:0]	blk_addr_x;
		wire	[M_ADDR_Y_WIDTH-1:0]	blk_addr_y;
		wire							blk_valid;
		wire							blk_ready;
		
		// blk addr
		jelly_texture_blk_addr
				#(
					.USER_WIDTH				(L1_ID_WIDTH),
					
					.ADDR_X_WIDTH			(ADDR_X_WIDTH),
					.ADDR_Y_WIDTH			(ADDR_Y_WIDTH),
					
					.BLK_X_WIDTH			(L1_BLK_X_SIZE),
					.BLK_Y_WIDTH			(L1_BLK_Y_SIZE)
				)
			i_texture_blk_addr
				(
					.reset					(reset),
					.clk					(clk),
					
					.s_user					(blk_id),
					.s_addr_x				(blk_addr_x << L1_BLK_X_SIZE),
					.s_addr_y				(blk_addr_y << L1_BLK_Y_SIZE),
					.s_valid				(blk_valid),
					.s_ready				(blk_ready),
					
					.m_user					(m_arid    [i*L1_ID_WIDTH  +: L1_ID_WIDTH]),
					.m_last					(m_arlast  [i]),
					.m_addr_x				(m_araddrx [i*ADDR_X_WIDTH +: ADDR_X_WIDTH]),
					.m_addr_y				(m_araddry [i*ADDR_Y_WIDTH +: ADDR_Y_WIDTH]),
					.m_valid				(m_arvalid [i]),
					.m_ready				(m_arready [i])
				);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(AR_DATA_WIDTH),
					.ID_TO_WIDTH			(L2_ID_WIDTH),
					.ID_FROM_WIDTH			(L1_ID_WIDTH),
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
					.m_data					({blk_addr_y, blk_addr_x}),
					.m_valid				(blk_valid),
					.m_ready				(blk_ready),
					
					.src_id_to				(ringbus_l2_ar_id_to  [(i+1)*L2_ID_WIDTH   +: L2_ID_WIDTH]),
					.src_id_from			(ringbus_l2_ar_id_from[(i+1)*L1_ID_WIDTH   +: L1_ID_WIDTH]),
					.src_data				(ringbus_l2_ar_data   [(i+1)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.src_valid				(ringbus_l2_ar_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l2_ar_id_to  [(i+0)*L2_ID_WIDTH   +: L2_ID_WIDTH]),
					.sink_id_from			(ringbus_l2_ar_id_from[(i+0)*L1_ID_WIDTH   +: L1_ID_WIDTH]),
					.sink_data				(ringbus_l2_ar_data   [(i+0)*AR_DATA_WIDTH +: AR_DATA_WIDTH]),
					.sink_valid				(ringbus_l2_ar_valid  [(i+0)])
				);
		
		jelly_ring_bus_unit
				#(
					.DATA_WIDTH				(R_DATA_WIDTH),
					.ID_TO_WIDTH			(L1_ID_WIDTH),
					.ID_FROM_WIDTH			(L2_ID_WIDTH),
					.UNIT_ID_TO				(0),
					.UNIT_ID_FROM			(0)
				)
			i_ring_bus_unit_l2_r
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_id_to				(m_rid[i*L1_ID_WIDTH +: L1_ID_WIDTH]),
					.s_data					({m_rlast[i], m_rdata[i*M_DATA_WIDTH +: M_DATA_WIDTH]}),
					.s_valid				(m_rvalid[i]),
					.s_ready				(m_rready[i]),
					
					.m_id_from				(),
					.m_data					(),
					.m_valid				(),
					.m_ready				(1'b0),
					
					.src_id_to				(ringbus_l2_r_id_to  [(i+1)*L1_ID_WIDTH  +: L1_ID_WIDTH]),
					.src_id_from			(ringbus_l2_r_id_from[(i+1)*L2_ID_WIDTH  +: L2_ID_WIDTH]),
					.src_data				(ringbus_l2_r_data   [(i+1)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.src_valid				(ringbus_l2_r_valid  [(i+1)]),
					
					.sink_id_to				(ringbus_l2_r_id_to  [(i+0)*L1_ID_WIDTH  +: L1_ID_WIDTH]),
					.sink_id_from			(ringbus_l2_r_id_from[(i+0)*L2_ID_WIDTH  +: L2_ID_WIDTH]),
					.sink_data				(ringbus_l2_r_data   [(i+0)*R_DATA_WIDTH +: R_DATA_WIDTH]),
					.sink_valid				(ringbus_l2_r_valid  [(i+0)])
				);
	end
	endgenerate
	
	
	assign ringbus_l1_ar_id_to  [L1_CACHE_NUM*L2_ID_WIDTH   +: L2_ID_WIDTH]   = ringbus_l2_ar_id_to  [0 +: L2_ID_WIDTH];
	assign ringbus_l1_ar_id_from[L1_CACHE_NUM*L1_ID_WIDTH   +: L1_ID_WIDTH]   = ringbus_l2_ar_id_from[0 +: L1_ID_WIDTH];
	assign ringbus_l1_ar_data   [L1_CACHE_NUM*AR_DATA_WIDTH +: AR_DATA_WIDTH] = ringbus_l2_ar_data   [0 +: AR_DATA_WIDTH];
	assign ringbus_l1_ar_valid  [L1_CACHE_NUM]                                = ringbus_l2_ar_valid  [0];
	
	assign ringbus_l2_ar_id_to  [L2_CACHE_NUM*L2_ID_WIDTH  +: L2_ID_WIDTH]    = ringbus_l1_ar_id_to  [0 +: L2_ID_WIDTH];
	assign ringbus_l2_ar_id_from[L2_CACHE_NUM*L1_ID_WIDTH  +: L1_ID_WIDTH]    = ringbus_l1_ar_id_from[0 +: L1_ID_WIDTH];
	assign ringbus_l2_ar_data   [L2_CACHE_NUM*AR_DATA_WIDTH +: AR_DATA_WIDTH] = ringbus_l1_ar_data   [0 +: AR_DATA_WIDTH];
	assign ringbus_l2_ar_valid  [L2_CACHE_NUM]                                = ringbus_l1_ar_valid  [0];
	
	
	assign ringbus_l1_r_id_to   [L1_CACHE_NUM*L1_ID_WIDTH  +: L1_ID_WIDTH]    = ringbus_l2_r_id_to   [0 +: L1_ID_WIDTH];
	assign ringbus_l1_r_id_from [L1_CACHE_NUM*L2_ID_WIDTH  +: L2_ID_WIDTH]    = ringbus_l2_r_id_from [0 +: L2_ID_WIDTH];
	assign ringbus_l1_r_data    [L1_CACHE_NUM*R_DATA_WIDTH +: R_DATA_WIDTH]   = ringbus_l2_r_data    [0 +: R_DATA_WIDTH];
	assign ringbus_l1_r_valid   [L1_CACHE_NUM]                                = ringbus_l2_r_valid   [0];
	
	assign ringbus_l2_r_id_to   [L2_CACHE_NUM*L1_ID_WIDTH  +: L1_ID_WIDTH]    = ringbus_l1_r_id_to   [0 +: L1_ID_WIDTH];
	assign ringbus_l2_r_id_from [L2_CACHE_NUM*L2_ID_WIDTH  +: L2_ID_WIDTH]    = ringbus_l1_r_id_from [0 +: L2_ID_WIDTH];
	assign ringbus_l2_r_data    [L2_CACHE_NUM*R_DATA_WIDTH +: R_DATA_WIDTH]   = ringbus_l1_r_data    [0 +: R_DATA_WIDTH];
	assign ringbus_l2_r_valid   [L2_CACHE_NUM]                                = ringbus_l1_r_valid   [0];
	
	
endmodule


`default_nettype wire


// end of file
