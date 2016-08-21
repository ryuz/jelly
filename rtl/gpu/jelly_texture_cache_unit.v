// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
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
			
			parameter	AUTO_TAG_ADDR        = 1,
			parameter	USE_BORDER           = 1,
			parameter	BORDER_DATA          = {S_DATA_WIDTH{1'b0}}
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							endian,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_width,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	param_height,
			
			input	wire	[TAG_ADDR_WIDTH-1:0]	s_artagaddr,
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
	
	
	// ---------------------------------
	//  localparam
	// ---------------------------------
	
	localparam	PIX_ADDR_X_WIDTH     = BLK_X_SIZE;
	localparam	PIX_ADDR_Y_WIDTH     = BLK_Y_SIZE;
	localparam	BLK_ADDR_X_WIDTH     = S_ADDR_X_WIDTH - BLK_X_SIZE;
	localparam	BLK_ADDR_Y_WIDTH     = S_ADDR_Y_WIDTH - BLK_Y_SIZE;
	
	
	
	// ---------------------------------
	//  TAG-RAM access
	// ---------------------------------
	
	wire		[S_USER_WIDTH-1:0]		tagram_user;
	wire		[TAG_ADDR_WIDTH-1:0]	tagram_tag_addr;
	wire		[PIX_ADDR_X_WIDTH-1:0]	tagram_pix_addrx;
	wire		[PIX_ADDR_Y_WIDTH-1:0]	tagram_pix_addry;
	wire		[BLK_ADDR_X_WIDTH-1:0]	tagram_blk_addrx;
	wire		[BLK_ADDR_Y_WIDTH-1:0]	tagram_blk_addry;
	wire								tagram_range_out;
	wire								tagram_cache_hit;
	wire								tagram_valid;
	wire								tagram_ready;
	
	jelly_texture_cache_tag
			#(
				.USER_WIDTH				(S_USER_WIDTH),
				
				.S_ADDR_X_WIDTH			(S_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH			(S_ADDR_Y_WIDTH),
				.S_DATA_WIDTH			(S_DATA_WIDTH),
				
				.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.TAG_X_RSHIFT			(TAG_X_RSHIFT),
				.TAG_X_LSHIFT			(TAG_X_LSHIFT),
				.TAG_Y_RSHIFT			(TAG_Y_RSHIFT),
				.TAG_Y_LSHIFT			(TAG_Y_LSHIFT),
				.BLK_X_SIZE				(BLK_X_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.RAM_TYPE				(TAG_RAM_TYPE),
				.USE_BORDER				(USE_BORDER)
			)
		i_texture_cache_tag
			(
				.reset					(reset),
				.clk					(clk),
				
				.clear_start			(clear_start),
				.clear_busy				(clear_busy),
				
				.param_width			(param_width),
				.param_height			(param_height),
				
				.s_user					(s_aruser),
				.s_tagaddr				(s_artagaddr),
				.s_addrx				(s_araddrx),
				.s_addry				(s_araddry),
				.s_valid				(s_arvalid),
				.s_ready				(s_arready),
				
				.m_user					(tagram_user),
				.m_tag_addr				(tagram_tag_addr),
				.m_pix_addrx			(tagram_pix_addrx),
				.m_pix_addry			(tagram_pix_addry),
				.m_blk_addrx			(tagram_blk_addrx),
				.m_blk_addry			(tagram_blk_addry),
				.m_cache_hit			(tagram_cache_hit),
				.m_range_out			(tagram_range_out),
				.m_valid				(tagram_valid),
				.m_ready				(tagram_ready)
			);
	
	
	// ---------------------------------
	//  cahce miss read control
	// ---------------------------------
	
	localparam	PIX_ADDR_WIDTH = PIX_ADDR_Y_WIDTH + PIX_ADDR_X_WIDTH;
	
	wire								mem_busy;
	wire								mem_ready;
	
	reg									reg_tagram_ready;
	
	reg		[S_USER_WIDTH-1:0]			reg_user;
	reg		[TAG_ADDR_WIDTH-1:0]		reg_tag_addr;
	reg		[PIX_ADDR_WIDTH-1:0]		reg_pix_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]		reg_pix_addrx;
	reg		[PIX_ADDR_Y_WIDTH-1:0]		reg_pix_addry;
	reg		[BLK_ADDR_X_WIDTH-1:0]		reg_blk_addrx;
	reg		[BLK_ADDR_Y_WIDTH-1:0]		reg_blk_addry;
	reg									reg_range_out;
	reg									reg_valid;
	
	reg		[COMPONENT_NUM-1:0]			reg_we;
	reg									reg_wlast;
	reg		[M_DATA_WIDTH-1:0]			reg_wdata;
	
	reg									reg_m_wait;
	reg									reg_m_arvalid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_tagram_ready <= 1'b1;
			
			reg_user         <= {S_USER_WIDTH{1'bx}};
			reg_tag_addr     <= {TAG_ADDR_WIDTH{1'bx}};
			reg_pix_addr     <= {PIX_ADDR_WIDTH{1'bx}};
			reg_pix_addrx    <= {PIX_ADDR_X_WIDTH{1'bx}};
			reg_pix_addry    <= {PIX_ADDR_Y_WIDTH{1'bx}};
			reg_blk_addrx    <= {BLK_ADDR_X_WIDTH{1'bx}};
			reg_blk_addry    <= {BLK_ADDR_Y_WIDTH{1'bx}};
			reg_range_out    <= 1'bx;
			reg_valid        <= 1'b0;
			
			reg_we           <= {COMPONENT_NUM{1'b0}};
			reg_wlast        <= 1'bx;
			reg_wdata        <= {M_DATA_WIDTH{1'bx}};
			
			reg_m_wait       <= 1'b0;
			reg_m_arvalid    <= 1'b0;
		end
		else begin
			// araddr request complete
			if ( m_arready ) begin
				reg_m_arvalid <= 1'b0;
			end
			
			// memory stage request receive
			if ( mem_ready ) begin
				reg_valid <= 1'b0;
				reg_we    <= {COMPONENT_NUM{1'b0}};
			end
			
			// rdata receive
			if ( m_rvalid && m_rready ) begin
				reg_we    <= m_rstrb;
				reg_wlast <= m_rlast;
				reg_wdata <= m_rdata;
			end
			
			// m_arvalid
			if ( reg_m_wait && !mem_busy ) begin
				reg_m_wait    <= 1'b0;
				reg_m_arvalid <= 1'b1;
			end
			
			// write
			if ( (reg_we != 0) && mem_ready ) begin
				reg_pix_addr <= reg_pix_addr + (1 << M_DATA_WIDE_SIZE);
				
				if ( reg_wlast ) begin
					// write end
					reg_pix_addr     <= {reg_pix_addry, reg_pix_addrx};
					reg_valid        <= 1'b1;
					reg_tagram_ready <= 1'b1;
				end
			end
			
			if ( tagram_valid && tagram_ready ) begin
				if ( !tagram_cache_hit && !tagram_range_out ) begin
					// cache miss
					reg_tagram_ready <= 1'b0;
					reg_m_arvalid    <= (USE_M_RREADY || !mem_busy);
					reg_m_wait       <= (!USE_M_RREADY && mem_busy);
					reg_pix_addr     <= {PIX_ADDR_WIDTH{1'b0}};
					reg_valid        <= 1'b0;
				end
				else begin
					// cache hit
					reg_m_arvalid    <= 1'b0;
					reg_pix_addr     <= {tagram_pix_addry, tagram_pix_addrx};
					reg_valid        <= tagram_valid;
				end
				
				reg_tag_addr   <= tagram_tag_addr;
			end
			
			if ( tagram_ready ) begin
				reg_user      <= tagram_user;
				reg_pix_addrx <= tagram_pix_addrx;
				reg_pix_addry <= tagram_pix_addry;
				reg_blk_addrx <= tagram_blk_addrx;
				reg_blk_addry <= tagram_blk_addry;
				reg_range_out <= tagram_range_out;
			end
		end
	end
	
	assign tagram_ready = (reg_tagram_ready && (!reg_valid || mem_ready));
	
	assign m_araddrx    = (reg_blk_addrx << (BLK_X_SIZE - M_DATA_WIDE_SIZE));
	assign m_araddry    = (reg_blk_addry << BLK_Y_SIZE);
	assign m_arvalid    = reg_m_arvalid;
	
	assign m_rready     = (!USE_M_RREADY || mem_ready);
	
	
	// ---------------------------------
	//  cahce memory
	// ---------------------------------
	
	jelly_texture_cache_mem
			#(
				.USER_WIDTH				(S_USER_WIDTH),
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH),
				.TAG_ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.PIX_ADDR_WIDTH			(PIX_ADDR_WIDTH),
				.M_DATA_WIDTH			(S_DATA_WIDTH),
				.S_DATA_WIDE_SIZE		(M_DATA_WIDE_SIZE),
				.RAM_TYPE				(MEM_RAM_TYPE),
				.BORDER_DATA			(BORDER_DATA)
			)
		i_texture_cache_mem
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.busy					(mem_busy),
				
				.s_user					(reg_user),
				.s_we					(reg_we),
				.s_wdata				(reg_wdata),
				.s_tag_addr				(reg_tag_addr),
				.s_pix_addr				(reg_pix_addr),
				.s_range_out			(reg_range_out),
				.s_valid				(reg_valid),
				.s_ready				(mem_ready),
				
				.m_user					(s_ruser),
				.m_data					(s_rdata),
				.m_valid				(s_rvalid),
				.m_ready				(s_rready)
			);
	
endmodule



`default_nettype wire


// end of file
