// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_core
		#(
			parameter	COMPONENT_NUM         = 3,
			parameter	COMPONENT_DATA_WIDTH  = 8,
			
			parameter	USER_WIDTH            = 1,
			parameter	USE_S_RREADY          = 1,	// 0: s_rready is always 1'b1.   1: handshake mode.
			parameter	USE_BORDER            = 1,
			parameter	BORDER_DATA           = {S_DATA_WIDTH{1'b0}},
			
			parameter	ADDR_WIDTH            = 24,
			parameter	ADDR_X_WIDTH          = 12,
			parameter	ADDR_Y_WIDTH          = 12,
			parameter	S_DATA_WIDTH          = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			
			parameter	L1_CACHE_NUM          = 4,
			parameter	L1_USE_LOOK_AHEAD     = 0,
			parameter	L1_TAG_ADDR_WIDTH     = 6,
			parameter	L1_BLK_X_SIZE         = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L1_BLK_Y_SIZE         = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L1_TAG_RAM_TYPE       = "distributed",
			parameter	L1_MEM_RAM_TYPE       = "block",
			parameter	L1_DATA_WIDE_SIZE     = 1,
			parameter	L1_QUE_FIFO_PTR_WIDTH = L1_USE_LOOK_AHEAD ? L1_BLK_Y_SIZE + L1_BLK_X_SIZE : 0,
			parameter	L1_QUE_FIFO_RAM_TYPE  = "distributed",
			parameter	L1_AR_FIFO_PTR_WIDTH  = 0,
			parameter	L1_AR_FIFO_RAM_TYPE   = "distributed",
			parameter	L1_R_FIFO_PTR_WIDTH   = L1_BLK_Y_SIZE + L1_BLK_X_SIZE - L1_DATA_WIDE_SIZE,
			parameter	L1_R_FIFO_RAM_TYPE    = "distributed",
			parameter	L1_LOG_ENABLE         = 0,
			parameter	L1_LOG_FILE           = "l1_log.txt",
			parameter	L1_LOG_ID             = 0,
			
			parameter	L2_PARALLEL_SIZE      = 2,
			parameter	L2_USE_LOOK_AHEAD     = 0,
			parameter	L2_TAG_ADDR_WIDTH     = 6,
			parameter	L2_BLK_X_SIZE         = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L2_BLK_Y_SIZE         = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L2_TAG_RAM_TYPE       = "distributed",
			parameter	L2_MEM_RAM_TYPE       = "block",
			parameter	L2_QUE_FIFO_PTR_WIDTH = L2_USE_LOOK_AHEAD ? L2_BLK_Y_SIZE + L2_BLK_X_SIZE : 0,
			parameter	L2_QUE_FIFO_RAM_TYPE  = "distributed",
			parameter	L2_AR_FIFO_PTR_WIDTH  = 0,
			parameter	L2_AR_FIFO_RAM_TYPE   = "distributed",
			parameter	L2_R_FIFO_PTR_WIDTH   = L2_BLK_Y_SIZE + L2_BLK_X_SIZE - M_AXI4_DATA_SIZE,
			parameter	L2_R_FIFO_RAM_TYPE    = "distributed",
			parameter	L2_LOG_ENABLE         = 0,
			parameter	L2_LOG_FILE           = "l2_log.txt",
			parameter	L2_LOG_ID             = 0,
			
			parameter	M_AXI4_ID_WIDTH       = 6,
			parameter	M_AXI4_ADDR_WIDTH     = 32,
			parameter	M_AXI4_DATA_SIZE      = 3,	// 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
			parameter	M_AXI4_DATA_WIDTH     = (8 << M_AXI4_DATA_SIZE),
			parameter	M_AXI4_LEN_WIDTH      = 8,
			parameter	M_AXI4_QOS_WIDTH      = 4,
			parameter	M_AXI4_ARID           = {M_AXI4_ID_WIDTH{1'b0}},
			parameter	M_AXI4_ARSIZE         = M_AXI4_DATA_SIZE,
			parameter	M_AXI4_ARBURST        = 2'b01,
			parameter	M_AXI4_ARLOCK         = 1'b0,
			parameter	M_AXI4_ARCACHE        = 4'b0001,
			parameter	M_AXI4_ARPROT         = 3'b000,
			parameter	M_AXI4_ARQOS          = 0,
			parameter	M_AXI4_ARREGION       = 4'b0000,
			parameter	M_AXI4_REGS           = 1
		)
		(
			input	wire											reset,
			input	wire											clk,
			
			input	wire											endian,
			
			input	wire											clear_start,
			output	wire											clear_busy,
			
			input	wire	[M_AXI4_ADDR_WIDTH*COMPONENT_NUM-1:0]	param_addr,
			input	wire	[ADDR_X_WIDTH-1:0]						param_width,
			input	wire	[ADDR_Y_WIDTH-1:0]						param_height,
			input	wire	[ADDR_WIDTH-1:0]						param_stride,
			
			output	wire	[L1_CACHE_NUM-1:0]						status_l1_idle,
			output	wire	[L1_CACHE_NUM-1:0]						status_l1_stall,
			output	wire	[L1_CACHE_NUM-1:0]						status_l1_access,
			output	wire	[L1_CACHE_NUM-1:0]						status_l1_hit,
			output	wire	[L1_CACHE_NUM-1:0]						status_l1_miss,
			
			output	wire	[L2_CACHE_NUM-1:0]						status_l2_idle,
			output	wire	[L2_CACHE_NUM-1:0]						status_l2_stall,
			output	wire	[L2_CACHE_NUM-1:0]						status_l2_access,
			output	wire	[L2_CACHE_NUM-1:0]						status_l2_hit,
			output	wire	[L2_CACHE_NUM-1:0]						status_l2_miss,
			
			
			input	wire	[L1_CACHE_NUM*USER_WIDTH-1:0]			s_aruser,
			input	wire	[L1_CACHE_NUM*ADDR_X_WIDTH-1:0]			s_araddrx,
			input	wire	[L1_CACHE_NUM*ADDR_Y_WIDTH-1:0]			s_araddry,
			input	wire	[L1_CACHE_NUM-1:0]						s_arvalid,
			output	wire	[L1_CACHE_NUM-1:0]						s_arready,
			
			output	wire	[L1_CACHE_NUM*USER_WIDTH-1:0]			s_ruser,
			output	wire	[L1_CACHE_NUM*S_DATA_WIDTH-1:0]			s_rdata,
			output	wire	[L1_CACHE_NUM-1:0]						s_rvalid,
			input	wire	[L1_CACHE_NUM-1:0]						s_rready,
			
			
			// AXI4 read (master)
			output	wire	[M_AXI4_ID_WIDTH-1:0]					m_axi4_arid,
			output	wire	[M_AXI4_ADDR_WIDTH-1:0]					m_axi4_araddr,
			output	wire	[M_AXI4_LEN_WIDTH-1:0]					m_axi4_arlen,
			output	wire	[2:0]									m_axi4_arsize,
			output	wire	[1:0]									m_axi4_arburst,
			output	wire	[0:0]									m_axi4_arlock,
			output	wire	[3:0]									m_axi4_arcache,
			output	wire	[2:0]									m_axi4_arprot,
			output	wire	[M_AXI4_QOS_WIDTH-1:0]					m_axi4_arqos,
			output	wire	[3:0]									m_axi4_arregion,
			output	wire											m_axi4_arvalid,
			input	wire											m_axi4_arready,
			input	wire	[M_AXI4_ID_WIDTH-1:0]					m_axi4_rid,
			input	wire	[M_AXI4_DATA_WIDTH-1:0]					m_axi4_rdata,
			input	wire	[1:0]									m_axi4_rresp,
			input	wire											m_axi4_rlast,
			input	wire											m_axi4_rvalid,
			output	wire											m_axi4_rready
		);
	
	
	// -----------------------------
	//  localparam
	// -----------------------------
	
	localparam	L2_CACHE_NUM            = (1 << L2_PARALLEL_SIZE);

	localparam	COMPONENT_DATA_SIZE     = COMPONENT_DATA_WIDTH <=    8 ? 0 :
	                                      COMPONENT_DATA_WIDTH <=   16 ? 1 :
	                                      COMPONENT_DATA_WIDTH <=   32 ? 2 :
	                                      COMPONENT_DATA_WIDTH <=   64 ? 3 :
	                                      COMPONENT_DATA_WIDTH <=  128 ? 4 :
	                                      COMPONENT_DATA_WIDTH <=  256 ? 5 :
	                                      COMPONENT_DATA_WIDTH <=  512 ? 6 :
	                                      COMPONENT_DATA_WIDTH <= 1024 ? 7 :
	                                      COMPONENT_DATA_WIDTH <= 2048 ? 8 : 9;
	
	
	// L1キャッシュは１画素１コンポーネントに統合
	localparam	L1_COMPONENT_NUM        = 1;
	localparam	L1_COMPONENT_DATA_WIDTH = COMPONENT_NUM * COMPONENT_DATA_WIDTH;
	localparam	L1_ADDR_X_WIDTH         = ADDR_X_WIDTH;
	localparam	L1_ADDR_Y_WIDTH         = ADDR_Y_WIDTH;
	
	localparam	L1_ID_WIDTH             = L1_CACHE_NUM <=    2 ? 1 :
	                                      L1_CACHE_NUM <=    4 ? 2 :
	                                      L1_CACHE_NUM <=    8 ? 3 :
	                                      L1_CACHE_NUM <=   16 ? 4 :
	                                      L1_CACHE_NUM <=   32 ? 5 :
	                                      L1_CACHE_NUM <=   64 ? 6 :
	                                      L1_CACHE_NUM <=  128 ? 7 :
	                                      L1_CACHE_NUM <=  256 ? 8 : 9;
	
	localparam	L2_ID_WIDTH             = L2_CACHE_NUM <=    2 ? 1 :
	                                      L2_CACHE_NUM <=    4 ? 2 :
	                                      L2_CACHE_NUM <=    8 ? 3 :
	                                      L2_CACHE_NUM <=   16 ? 4 :
	                                      L2_CACHE_NUM <=   32 ? 5 :
	                                      L2_CACHE_NUM <=   64 ? 6 :
	                                      L2_CACHE_NUM <=  128 ? 7 :
	                                      L2_CACHE_NUM <=  256 ? 8 : 9;
	
	
	// L2キャッシュはコンポーネント分解＆ピクセル並列化
	localparam	L2_COMPONENT_NUM        = COMPONENT_NUM;
	localparam	L2_COMPONENT_DATA_WIDTH = (COMPONENT_DATA_WIDTH << L1_DATA_WIDE_SIZE);
	localparam	L2_ADDR_X_WIDTH         = ADDR_X_WIDTH - L1_DATA_WIDE_SIZE;
	localparam	L2_ADDR_Y_WIDTH         = ADDR_Y_WIDTH;
	localparam	L2_DATA_WIDTH           = L2_COMPONENT_NUM * L2_COMPONENT_DATA_WIDTH;
	
	
	
	// -----------------------------
	//  L1 Cache
	// -----------------------------
	
	wire	[L1_CACHE_NUM-1:0]						m_arlast;
	wire	[L1_CACHE_NUM*L2_ADDR_X_WIDTH-1:0]		m_araddrx;
	wire	[L1_CACHE_NUM*L2_ADDR_Y_WIDTH-1:0]		m_araddry;
	wire	[L1_CACHE_NUM-1:0]						m_arvalid;
	wire	[L1_CACHE_NUM-1:0]						m_arready;
	
	wire	[L1_CACHE_NUM-1:0]						m_rlast;
	wire	[L1_CACHE_NUM*L2_DATA_WIDTH-1:0]		m_rdata;
	wire	[L1_CACHE_NUM-1:0]						m_rvalid;
	wire	[L1_CACHE_NUM-1:0]						m_rready;
	
	wire											l1_clear_busy;
	
	jelly_texture_cache_l1
			#(
				.CACHE_NUM				(L1_CACHE_NUM),
				
				.COMPONENT_NUM			(L1_COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(L1_COMPONENT_DATA_WIDTH),
				.TAG_ADDR_WIDTH			(L1_TAG_ADDR_WIDTH),
				.BLK_X_SIZE				(L1_BLK_X_SIZE),
				.BLK_Y_SIZE				(L1_BLK_Y_SIZE),
				.TAG_RAM_TYPE			(L1_TAG_RAM_TYPE),
				.MEM_RAM_TYPE			(L1_MEM_RAM_TYPE),
				
				.USE_LOOK_AHEAD			(L1_USE_LOOK_AHEAD),
				.USE_S_RREADY			(USE_S_RREADY),
				.USE_M_RREADY			(0),
				.USE_BORDER				(USE_BORDER),
				.BORDER_DATA			(BORDER_DATA),
				
				.S_USER_WIDTH			(USER_WIDTH),
				.S_ADDR_X_WIDTH			(L1_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH			(L1_ADDR_Y_WIDTH),
				
				.M_DATA_WIDE_SIZE		(L1_DATA_WIDE_SIZE),
				
				.QUE_FIFO_PTR_WIDTH		(L1_QUE_FIFO_PTR_WIDTH),
				.QUE_FIFO_RAM_TYPE		(L1_QUE_FIFO_RAM_TYPE),
				.AR_FIFO_PTR_WIDTH		(L1_AR_FIFO_PTR_WIDTH),
				.AR_FIFO_RAM_TYPE		(L1_AR_FIFO_RAM_TYPE),
				.R_FIFO_PTR_WIDTH		(L1_R_FIFO_PTR_WIDTH),
				.R_FIFO_RAM_TYPE		(L1_R_FIFO_RAM_TYPE),
				
				.LOG_ENABLE				(L1_LOG_ENABLE),
				.LOG_FILE				(L1_LOG_FILE),
				.LOG_ID					(L1_LOG_ID)
			)
		i_texture_cache_l1
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.clear_start			(clear_start),
				.clear_busy				(l1_clear_busy),
				
				.param_width			(param_width),
				.param_height			(param_height),
				
				.status_idle			(status_l1_idle),
				.status_stall			(status_l1_stall),
				.status_access			(status_l1_access),
				.status_hit				(status_l1_hit),
				.status_miss			(status_l1_miss),
				
				
				.s_aruser				(s_aruser),
				.s_araddrx				(s_araddrx),
				.s_araddry				(s_araddry),
				.s_arvalid				(s_arvalid),
				.s_arready				(s_arready),
				
				.s_ruser				(s_ruser),
				.s_rdata				(s_rdata),
				.s_rvalid				(s_rvalid),
				.s_rready				(s_rready),
				
				
				.m_arlast				(m_arlast),
				.m_araddrx				(m_araddrx),
				.m_araddry				(m_araddry),
				.m_arvalid				(m_arvalid),
				.m_arready				(m_arready),
				
				.m_rlast				(m_rlast),
				.m_rdata				(m_rdata),
				.m_rvalid				(m_rvalid),
				.m_rready				(m_rready)
			);
	
	
	// -----------------------------
	//  L2 Cache
	// -----------------------------
	
	localparam	L2_USER_WIDTH    = L1_ID_WIDTH;
	localparam	L1_DATA_WIDE_NUM = (1 << L1_DATA_WIDE_SIZE);
	
	wire	[L1_CACHE_NUM-1:0]					l2_rlast;
	wire	[L1_CACHE_NUM*L2_DATA_WIDTH-1:0]	l2_rdata;
	
	genvar	i, j, k;
	generate
	for ( i = 0; i < L1_CACHE_NUM; i = i+1 ) begin : l2_user_loop
		assign m_rlast[i]                                = l2_rlast[i];
		
		wire	[L2_DATA_WIDTH-1:0]		m_rdata_c;
		wire	[L2_DATA_WIDTH-1:0]		l2_rdata_c;
		assign m_rdata[i*L2_DATA_WIDTH +: L2_DATA_WIDTH] = m_rdata_c;
		assign l2_rdata_c                                = l2_rdata[i*L2_DATA_WIDTH +: L2_DATA_WIDTH];
		
		for ( j = 0; j < L1_DATA_WIDE_NUM; j = j+1 ) begin : j_loop
			for ( k = 0; k < L2_COMPONENT_NUM; k = k+1 ) begin : k_loop
				assign m_rdata_c[(j*COMPONENT_NUM+k)*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH]
								= l2_rdata_c[(k*L1_DATA_WIDE_NUM+j)*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH];
			end
		end
	end
	endgenerate
	
	
	
	wire	[M_AXI4_LEN_WIDTH-1:0]	param_arlen = (1 << (L2_BLK_Y_SIZE + L2_BLK_X_SIZE + COMPONENT_DATA_SIZE - M_AXI4_DATA_SIZE)) - 1;

	wire							l2_clear_busy;
			
	jelly_texture_cache_l2
			#(
				
				.COMPONENT_NUM			(L2_COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(L2_COMPONENT_DATA_WIDTH),
				
				.S_NUM					(L1_CACHE_NUM),
				.S_ADDR_X_WIDTH			(L2_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH			(L2_ADDR_Y_WIDTH),
				.S_BLK_X_NUM			(1 << (L1_BLK_X_SIZE - L1_DATA_WIDE_SIZE)),
				.S_BLK_Y_NUM			(1 << L1_BLK_Y_SIZE),
				
				.PARALLEL_SIZE			(L2_PARALLEL_SIZE),
				.TAG_ADDR_WIDTH			(L2_TAG_ADDR_WIDTH),				
				.BLK_X_SIZE				(L2_BLK_X_SIZE - L1_DATA_WIDE_SIZE),
				.BLK_Y_SIZE				(L2_BLK_Y_SIZE),
				
				.USE_LOOK_AHEAD			(L2_USE_LOOK_AHEAD),
				.USE_S_RREADY			(1),
				.USE_M_RREADY			(0),
				
				.USE_BORDER				(0),
				.BORDER_DATA			(BORDER_DATA),
				
				.TAG_RAM_TYPE			(L2_TAG_RAM_TYPE),
				.MEM_RAM_TYPE			(L2_MEM_RAM_TYPE),
				
				.M_AXI4_ID_WIDTH		(M_AXI4_ID_WIDTH),
				.M_AXI4_ADDR_WIDTH		(M_AXI4_ADDR_WIDTH),
				.M_AXI4_DATA_SIZE		(M_AXI4_DATA_SIZE),
				.M_AXI4_DATA_WIDTH		(M_AXI4_DATA_WIDTH),
				.M_AXI4_LEN_WIDTH		(M_AXI4_LEN_WIDTH),
				.M_AXI4_QOS_WIDTH		(M_AXI4_QOS_WIDTH),
				.M_AXI4_ARID			(M_AXI4_ARID),
				.M_AXI4_ARSIZE			(M_AXI4_ARSIZE),
				.M_AXI4_ARBURST			(M_AXI4_ARBURST),
				.M_AXI4_ARLOCK			(M_AXI4_ARLOCK),
				.M_AXI4_ARCACHE			(M_AXI4_ARCACHE),
				.M_AXI4_ARPROT			(M_AXI4_ARPROT),
				.M_AXI4_ARQOS			(M_AXI4_ARQOS),
				.M_AXI4_ARREGION		(M_AXI4_ARREGION),
				.M_AXI4_REGS			(M_AXI4_REGS),
				
				.QUE_FIFO_PTR_WIDTH		(L2_QUE_FIFO_PTR_WIDTH),
				.QUE_FIFO_RAM_TYPE		(L2_QUE_FIFO_RAM_TYPE),
				.AR_FIFO_PTR_WIDTH		(L2_AR_FIFO_PTR_WIDTH),
				.AR_FIFO_RAM_TYPE		(L2_AR_FIFO_RAM_TYPE),
				.R_FIFO_PTR_WIDTH		(L2_R_FIFO_PTR_WIDTH),
				.R_FIFO_RAM_TYPE		(L2_R_FIFO_RAM_TYPE),
				
				.LOG_ENABLE				(L2_LOG_ENABLE),
				.LOG_FILE				(L2_LOG_FILE),
				.LOG_ID					(L2_LOG_ID)
			)
		i_texture_cache_l2
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.clear_start			(clear_start),
				.clear_busy				(l2_clear_busy),
				
				.param_addr				(param_addr),
				.param_width			(param_width[ADDR_X_WIDTH-1:L1_DATA_WIDE_SIZE]),
				.param_height			(param_height),
				.param_stride			(param_stride),
				.param_arlen			(param_arlen),
				
				.status_idle			(status_l2_idle),
				.status_stall			(status_l2_stall),
				.status_access			(status_l2_access),
				.status_hit				(status_l2_hit),
				.status_miss			(status_l2_miss),
				
				
				.s_araddrx				(m_araddrx),
				.s_araddry				(m_araddry),
				.s_arvalid				(m_arvalid),
				.s_arready				(m_arready),
				.s_rlast				(l2_rlast),
				.s_rdata				(l2_rdata),
				.s_rvalid				(m_rvalid),
				.s_rready				(m_rready),
				
				
				.m_axi4_arid			(m_axi4_arid),
				.m_axi4_araddr			(m_axi4_araddr),
				.m_axi4_arlen			(m_axi4_arlen),
				.m_axi4_arsize			(m_axi4_arsize),
				.m_axi4_arburst			(m_axi4_arburst),
				.m_axi4_arlock			(m_axi4_arlock),
				.m_axi4_arcache			(m_axi4_arcache),
				.m_axi4_arprot			(m_axi4_arprot),
				.m_axi4_arqos			(m_axi4_arqos),
				.m_axi4_arregion		(m_axi4_arregion),
				.m_axi4_arvalid			(m_axi4_arvalid),
				.m_axi4_arready			(m_axi4_arready),
				.m_axi4_rid				(m_axi4_rid),
				.m_axi4_rdata			(m_axi4_rdata),
				.m_axi4_rresp			(m_axi4_rresp),
				.m_axi4_rlast			(m_axi4_rlast),
				.m_axi4_rvalid			(m_axi4_rvalid),
				.m_axi4_rready			(m_axi4_rready)
			);
	
	
	assign clear_busy = (l1_clear_busy | l2_clear_busy);
	
endmodule


`default_nettype wire


// end of file
