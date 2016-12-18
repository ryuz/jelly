// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_l2
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_DATA_WIDTH = 8,
			parameter	BLK_X_SIZE           = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE           = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
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
			
			parameter	USE_BORDER           = 1,
			parameter	BORDER_DATA          = {S_DATA_WIDTH{1'b0}},
			
			parameter	ADDR_WIDTH           = 24,
			
			parameter	S_NUM                = 4,
			parameter	S_USER_WIDTH         = 1,
			parameter	S_DATA_WIDTH         = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			parameter	S_ADDR_X_WIDTH       = 12,
			parameter	S_ADDR_Y_WIDTH       = 12,
			
			parameter	M_AXI4_ID_WIDTH      = 6,
			parameter	M_AXI4_ADDR_WIDTH    = 32,
			parameter	M_AXI4_DATA_SIZE     = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	M_AXI4_DATA_WIDTH    = (8 << M_AXI4_DATA_SIZE),
			parameter	M_AXI4_LEN_WIDTH     = 8,
			parameter	M_AXI4_QOS_WIDTH     = 4,
			parameter	M_AXI4_ARID          = {M_AXI4_ID_WIDTH{1'b0}},
			parameter	M_AXI4_ARSIZE        = M_AXI4_DATA_SIZE,
			parameter	M_AXI4_ARBURST       = 2'b01,
			parameter	M_AXI4_ARLOCK        = 1'b0,
			parameter	M_AXI4_ARCACHE       = 4'b0001,
			parameter	M_AXI4_ARPROT        = 3'b000,
			parameter	M_AXI4_ARQOS         = 0,
			parameter	M_AXI4_ARREGION      = 4'b0000,
			parameter	M_AXI4_REGS          = 1,

			parameter	QUE_FIFO_PTR_WIDTH   = USE_LOOK_AHEAD ? BLK_Y_SIZE + BLK_X_SIZE : 0,
			parameter	QUE_FIFO_RAM_TYPE    = "distributed",
			
			parameter	AR_FIFO_PTR_WIDTH    = 0,
			parameter	AR_FIFO_RAM_TYPE     = "distributed",
			
			parameter	R_FIFO_PTR_WIDTH     = BLK_Y_SIZE + BLK_X_SIZE - (M_AXI4_DATA_SIZE - COMPONENT_DATA_SIZE),
			parameter	R_FIFO_RAM_TYPE      = "distributed",
			
			parameter	LOG_ENABLE           = 0,
			parameter	LOG_FILE             = "cache_log.txt",
			parameter	LOG_ID               = 0         
		)
		(
			input	wire											reset,
			input	wire											clk,
			
			input	wire											endian,
			
			input	wire	[M_AXI4_ADDR_WIDTH*COMPONENT_NUM-1:0]	param_addr,
			input	wire	[M_AXI4_LEN_WIDTH-1:0]					param_arlen,
			input	wire	[ADDR_WIDTH-1:0]						param_stride,
			
			input	wire											clear_start,
			output	wire											clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]					param_width,
			input	wire	[S_ADDR_Y_WIDTH-1:0]					param_height,
			
			output	wire	[S_NUM-1:0]								status_idle,
			output	wire	[S_NUM-1:0]								status_stall,
			output	wire	[S_NUM-1:0]								status_access,
			output	wire	[S_NUM-1:0]								status_hit,
			output	wire	[S_NUM-1:0]								status_miss,
			
			input	wire	[S_NUM*S_USER_WIDTH-1:0]				s_aruser,
			input	wire	[S_NUM*S_ADDR_X_WIDTH-1:0]				s_araddrx,
			input	wire	[S_NUM*S_ADDR_Y_WIDTH-1:0]				s_araddry,
			input	wire	[S_NUM-1:0]								s_arvalid,
			output	wire	[S_NUM-1:0]								s_arready,
			
			output	wire	[S_NUM*S_USER_WIDTH-1:0]				s_ruser,
			output	wire	[S_NUM*S_DATA_WIDTH-1:0]				s_rdata,
			output	wire	[S_NUM-1:0]								s_rvalid,
			input	wire	[S_NUM-1:0]								s_rready,
			
			
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
	
	genvar	i;
	
	
	// -----------------------------
	//  localparam
	// -----------------------------
	
	localparam	ID_WIDTH             = M_AXI4_ID_WIDTH;
	
	localparam	COMPONENT_SEL_WIDTH  = COMPONENT_NUM        <=    2 ? 1 :
	                                   COMPONENT_NUM        <=    4 ? 2 :
	                                   COMPONENT_NUM        <=    8 ? 3 :
	                                   COMPONENT_NUM        <=   16 ? 4 :
	                                   COMPONENT_NUM        <=   32 ? 5 :
	                                   COMPONENT_NUM        <=   64 ? 6 : 7;
	
	localparam	COMPONENT_DATA_SIZE  = COMPONENT_DATA_WIDTH <=    8 ? 0 :
	                                   COMPONENT_DATA_WIDTH <=   16 ? 1 :
	                                   COMPONENT_DATA_WIDTH <=   32 ? 2 :
	                                   COMPONENT_DATA_WIDTH <=   64 ? 3 :
	                                   COMPONENT_DATA_WIDTH <=  128 ? 4 :
	                                   COMPONENT_DATA_WIDTH <=  256 ? 5 :
	                                   COMPONENT_DATA_WIDTH <=  512 ? 6 :
	                                   COMPONENT_DATA_WIDTH <= 1024 ? 7 :
	                                   COMPONENT_DATA_WIDTH <= 2048 ? 8 : 9;
	
	localparam	M_DATA_WIDE_SIZE     = M_AXI4_DATA_SIZE - COMPONENT_DATA_SIZE;
	localparam	M_ADDR_X_WIDTH       = S_ADDR_X_WIDTH - M_DATA_WIDE_SIZE;
	localparam	M_ADDR_Y_WIDTH       = S_ADDR_Y_WIDTH;
	
	localparam	AR_PACKET_WIDTH      = M_ADDR_X_WIDTH + M_ADDR_Y_WIDTH;
	localparam	R_PACKET_WIDTH       = 1 + COMPONENT_SEL_WIDTH + M_AXI4_DATA_WIDTH;
	
	
	
	// -----------------------------
	//  L2 Cahce
	// -----------------------------
	
	// cache
	wire	[S_NUM-1:0]						cache_clear_busy;
	assign clear_busy = cache_clear_busy[0];
	
	wire	[S_NUM*AR_PACKET_WIDTH-1:0]		cache_arpacket;
	wire	[S_NUM*M_ADDR_X_WIDTH-1:0]		cache_araddrx;
	wire	[S_NUM*M_ADDR_Y_WIDTH-1:0]		cache_araddry;
	wire	[S_NUM-1:0]						cache_arvalid;
	wire	[S_NUM-1:0]						cache_arready;
	
	wire	[S_NUM*R_PACKET_WIDTH-1:0]		cache_rpacket;
	wire	[S_NUM-1:0]						cache_rlast;
	wire	[S_NUM*COMPONENT_SEL_WIDTH-1:0]	cache_rcomponent;
	wire	[S_NUM*COMPONENT_NUM-1:0]		cache_rstrb;
	wire	[S_NUM*M_AXI4_DATA_WIDTH-1:0]	cache_rdata;
	wire	[S_NUM-1:0]						cache_rvalid;
	wire	[S_NUM-1:0]						cache_rready;
	
	
	// debug
	/*
	integer		fp_s_ar;
	integer		fp_s_r;
	integer		fp_m_ar;
	integer		fp_m_r;
	initial begin
		fp_s_ar = $fopen("l2_0_s_ar.txt", "w");
		fp_s_r  = $fopen("l2_0_s_r.txt", "w");
		fp_m_ar = $fopen("l2_0_m_ar.txt", "w");
		fp_m_r  = $fopen("l2_0_m_r.txt", "w");
	end
	*/
	
	generate
	for ( i = 0; i < S_NUM; i = i+1 ) begin : cahce_loop
		
		// strobe
		assign	cache_rstrb[i*COMPONENT_NUM +: COMPONENT_NUM] = (1 << cache_rcomponent[i*COMPONENT_SEL_WIDTH +: COMPONENT_SEL_WIDTH]);
		
		
		// ar pack
		assign cache_arpacket[i*AR_PACKET_WIDTH +: AR_PACKET_WIDTH] =
				{
					cache_araddrx[i*M_ADDR_X_WIDTH +: M_ADDR_X_WIDTH],
					cache_araddry[i*M_ADDR_Y_WIDTH +: M_ADDR_Y_WIDTH]
				};
		
		// r unpack
		assign {
					cache_rlast     [i],
					cache_rcomponent[i*COMPONENT_SEL_WIDTH +: COMPONENT_SEL_WIDTH],
					cache_rdata     [i*M_AXI4_DATA_WIDTH   +: M_AXI4_DATA_WIDTH]
				}
					= cache_rpacket[i*R_PACKET_WIDTH +: R_PACKET_WIDTH];
		
		// cahce
		jelly_texture_cache_unit
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
					
					.USE_BORDER				(USE_BORDER),
					.BORDER_DATA			(BORDER_DATA),
					
					.USE_LOOK_AHEAD			(USE_LOOK_AHEAD),
					.USE_S_RREADY			(USE_S_RREADY),  
					.USE_M_RREADY			(USE_M_RREADY),
					
					.S_USER_WIDTH			(S_USER_WIDTH),
					.S_ADDR_X_WIDTH			(S_ADDR_X_WIDTH),
					.S_ADDR_Y_WIDTH			(S_ADDR_Y_WIDTH),
					
					.M_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
					.M_IN_ORDER				(0),
					
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
					
					.m_araddrx				(cache_araddrx[i*M_ADDR_X_WIDTH +: M_ADDR_X_WIDTH]),
					.m_araddry				(cache_araddry[i*M_ADDR_Y_WIDTH +: M_ADDR_Y_WIDTH]),
					.m_arvalid				(cache_arvalid[i]),
					.m_arready				(cache_arready[i]),
					
					.m_rlast				(cache_rlast  [i]),
					.m_rstrb				(cache_rstrb  [i*COMPONENT_NUM  +: COMPONENT_NUM]),
					.m_rdata				({COMPONENT_NUM{cache_rdata[i*M_AXI4_DATA_WIDTH +: M_AXI4_DATA_WIDTH]}}),
					.m_rvalid				(cache_rvalid [i]),
					.m_rready				(cache_rready [i])
				);
		
		// debug
		/*
		always @(posedge clk) begin
			if ( !reset ) begin
				if ( i == 0 ) begin
					if ( s_arvalid[i] && s_arready[i] ) begin
						$fdisplay(fp_s_ar, "%h %h %h",
												s_aruser [i*S_USER_WIDTH   +: S_USER_WIDTH],
												s_araddrx[i*S_ADDR_X_WIDTH +: S_ADDR_X_WIDTH],
												s_araddry[i*S_ADDR_Y_WIDTH +: S_ADDR_Y_WIDTH]);
					end
					
					if ( s_rvalid[i] && s_rready[i] ) begin
						$fdisplay(fp_s_r, "%h %h",
												s_ruser  [i*S_USER_WIDTH   +: S_USER_WIDTH],
												s_rdata  [i*S_DATA_WIDTH   +: S_DATA_WIDTH]);
					end
					
					if ( cache_arvalid[i] && cache_arready[i] ) begin
						$fdisplay(fp_m_ar, "%h %h", cache_araddrx[i*M_ADDR_X_WIDTH +: M_ADDR_X_WIDTH], cache_araddry[i*M_ADDR_Y_WIDTH +: M_ADDR_Y_WIDTH]);
					end
					
					if ( cache_rvalid [i] && cache_rready [i] ) begin
						$fdisplay(fp_m_r, "%h %h %b", cache_rdata[i*M_AXI4_DATA_WIDTH +: M_AXI4_DATA_WIDTH], cache_rstrb[i*COMPONENT_NUM +: COMPONENT_NUM], cache_rlast[i]);
					end
				end
			end
		end
		*/
		
	end
	endgenerate
	
	
	
	// -----------------------------
	//  Ring-bus
	// -----------------------------
	
	wire	[ID_WIDTH-1:0]				ringbus_arid;
	wire	[AR_PACKET_WIDTH-1:0]		ringbus_arpacket;
	wire	[M_ADDR_X_WIDTH-1:0]		ringbus_araddrx;
	wire	[M_ADDR_Y_WIDTH-1:0]		ringbus_araddry;
	wire								ringbus_arvalid;
	wire								ringbus_arready;
	
	wire	[ID_WIDTH-1:0]				ringbus_rid;
	wire	[R_PACKET_WIDTH-1:0]		ringbus_rpacket;
	wire								ringbus_rlast;
	wire	[COMPONENT_SEL_WIDTH-1:0]	ringbus_rcomponent;
	wire	[M_AXI4_DATA_WIDTH-1:0]		ringbus_rdata;
	wire								ringbus_rvalid;
	wire								ringbus_rready;
	
	// ar unpack
	assign	{ringbus_araddrx, ringbus_araddry} = ringbus_arpacket;
	
	// r pack
	assign ringbus_rpacket = {ringbus_rlast, ringbus_rcomponent, ringbus_rdata};
	
	
	jelly_ring_bus_arbiter_bidirection
			#(
				.S_NUM				(S_NUM),
				.S_ID_WIDTH			(ID_WIDTH),
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
				.s_down_data		(cache_arpacket),
				.s_down_valid		(cache_arvalid),
				.s_down_ready		(cache_arready),
				.s_up_id_from		(),
				.s_up_data			(cache_rpacket),
				.s_up_valid			(cache_rvalid),
				.s_up_ready			(cache_rready),
				
				.m_down_id_from		(ringbus_arid),
				.m_down_data		(ringbus_arpacket),
				.m_down_valid		(ringbus_arvalid),
				.m_down_ready		(ringbus_arready),
				.m_up_id_to			(ringbus_rid),
				.m_up_data			(ringbus_rpacket),
				.m_up_valid			(ringbus_rvalid),
				.m_up_ready			(ringbus_rready)
			);
	
	
	
	// -----------------------------
	//  DMA
	// -----------------------------
	
	wire	[ID_WIDTH-1:0]				dma_arid;
	wire	[ADDR_WIDTH-1:0]			dma_araddr;
	wire								dma_arvalid;
	wire								dma_arready;
	
	wire	[ID_WIDTH-1:0]				dma_rid;
	wire								dma_rlast;
	wire	[COMPONENT_SEL_WIDTH-1:0]	dma_rcomponent;
	wire	[M_AXI4_DATA_WIDTH-1:0]		dma_rdata;
	wire								dma_rvalid;
	wire								dma_rready;
	
	jelly_texture_cache_dma
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_SEL_WIDTH	(COMPONENT_SEL_WIDTH),
				
				.M_AXI4_ID_WIDTH		(M_AXI4_ID_WIDTH),
				.M_AXI4_ADDR_WIDTH		(M_AXI4_ADDR_WIDTH),
				.M_AXI4_DATA_SIZE		(M_AXI4_DATA_SIZE),
				.M_AXI4_DATA_WIDTH		(M_AXI4_DATA_WIDTH),
				.M_AXI4_LEN_WIDTH		(M_AXI4_LEN_WIDTH),
				.M_AXI4_QOS_WIDTH		(M_AXI4_QOS_WIDTH),
				.M_AXI4_ARSIZE			(M_AXI4_ARSIZE),
				.M_AXI4_ARBURST			(M_AXI4_ARBURST),
				.M_AXI4_ARLOCK			(M_AXI4_ARLOCK),
				.M_AXI4_ARCACHE			(M_AXI4_ARCACHE),
				.M_AXI4_ARPROT			(M_AXI4_ARPROT),
				.M_AXI4_ARQOS			(M_AXI4_ARQOS),
				.M_AXI4_ARREGION		(M_AXI4_ARREGION),
				.M_AXI4_REGS			(M_AXI4_REGS),
				
				.ID_WIDTH				(ID_WIDTH),
				.ADDR_WIDTH				(ADDR_WIDTH),
				
				.S_AR_REGS				(1),
				.S_R_REGS				(1)
			)
		i_texture_cache_dma
			(
				.reset					(reset),
				.clk					(clk),
				                         
				.param_addr				(param_addr),
				.param_arlen			(param_arlen),
				
				.s_arid					(dma_arid),
				.s_araddr				(dma_araddr),
				.s_arvalid				(dma_arvalid),
				.s_arready				(dma_arready),
				.s_rid					(dma_rid),
				.s_rlast				(dma_rlast),
				.s_rcomponent			(dma_rcomponent),
				.s_rdata				(dma_rdata),
				.s_rvalid				(dma_rvalid),
				.s_rready				(dma_rready),
				
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
	
	reg		[ID_WIDTH-1:0]		st0_dma_arid;
	reg		[ADDR_WIDTH-1:0]	st0_dma_araddr;
	reg		[ADDR_WIDTH-1:0]	st0_dma_araddrx;
	reg							st0_dma_arvalid;
	
	reg		[ID_WIDTH-1:0]		st1_dma_arid;
	reg		[ADDR_WIDTH-1:0]	st1_dma_araddr;
	reg							st1_dma_arvalid;
	always @(posedge clk) begin
		if ( reset ) begin
			st0_dma_arid    <= {ID_WIDTH{1'bx}};
			st0_dma_araddr  <= {ADDR_WIDTH{1'bx}};
			st0_dma_araddrx <= {ADDR_WIDTH{1'bx}};
			st0_dma_arvalid <= 1'b0;
			
			st1_dma_arid    <= {ID_WIDTH{1'bx}};
			st1_dma_araddr  <= {ADDR_WIDTH{1'bx}};
			st1_dma_arvalid <= 1'b0;
		end
		else if ( !dma_arvalid || dma_arready ) begin
			st0_dma_arid    <= ringbus_arid;
			st0_dma_araddr  <= ((ringbus_araddry >> BLK_Y_SIZE) * param_stride);// + (ringbus_araddrx << (BLK_Y_SIZE + BLK_X_SIZE));
			st0_dma_araddrx <= (ringbus_araddrx << (BLK_Y_SIZE + M_DATA_WIDE_SIZE + COMPONENT_DATA_SIZE));
			st0_dma_arvalid <= ringbus_arvalid;
			
			st1_dma_arid    <= st0_dma_arid;
			st1_dma_araddr  <= st0_dma_araddr + st0_dma_araddrx;
			st1_dma_arvalid <= st0_dma_arvalid; 
		end
	end
	
	assign dma_arid           = st1_dma_arid;
	assign dma_araddr         = st1_dma_araddr;
	assign dma_arvalid        = st1_dma_arvalid;
	assign ringbus_arready    = (!dma_arvalid || dma_arready);
	
	assign ringbus_rid        = dma_rid;
	assign ringbus_rlast      = dma_rlast;
	assign ringbus_rcomponent = dma_rcomponent;
	assign ringbus_rdata      = dma_rdata;
	assign ringbus_rvalid     = dma_rvalid;
	assign dma_rready         = ringbus_rready;
	
	
endmodule


`default_nettype wire


// end of file
