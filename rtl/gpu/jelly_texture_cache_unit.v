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
			parameter	S_ADDR_X_WIDTH   = 12,
			parameter	S_ADDR_Y_WIDTH   = 12,
			parameter	S_DATA_WIDTH     = 24,
			
			parameter	TAG_ADDR_WIDTH   = 6,
			
			parameter	BLK_X_SIZE       = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE       = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			
			parameter	PIX_ADDR_X_WIDTH = BLK_X_SIZE,
			parameter	PIX_ADDR_Y_WIDTH = BLK_Y_SIZE,
			parameter	BLK_ADDR_X_WIDTH = S_ADDR_X_WIDTH - BLK_X_SIZE,
			parameter	BLK_ADDR_Y_WIDTH = S_ADDR_Y_WIDTH - BLK_Y_SIZE,
			
			parameter	M_DATA_WIDE_SIZE = 1,
			
			parameter	M_ADDR_X_WIDTH   = BLK_ADDR_X_WIDTH,
			parameter	M_ADDR_Y_WIDTH   = BLK_ADDR_Y_WIDTH,
			parameter	M_DATA_WIDTH     = (S_DATA_WIDTH << M_DATA_WIDE_SIZE),
			
			parameter	BORDER_DATA      = {S_DATA_WIDTH{1'b0}},
			
			parameter	TAG_RAM_TYPE     = "distributed",
			parameter	MEM_RAM_TYPE     = "block"
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							endian,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_width,
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_height,
			
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	s_araddrx,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	s_araddry,
			input	wire							s_arvalid,
			output	wire							s_arready,
			
			output	wire	[S_DATA_WIDTH-1:0]		s_rdata,
			output	wire							s_rvalid,
			input	wire							s_rready,
			
			
			output	wire	[M_ADDR_X_WIDTH-1:0]	m_araddrx,
			output	wire	[M_ADDR_Y_WIDTH-1:0]	m_araddry,
			output	wire							m_arvalid,
			input	wire							m_arready,
			
			input	wire	[M_DATA_WIDTH-1:0]		m_rdata,
			input	wire							m_rlast,
			input	wire							m_rvalid,
			output	wire							m_rready
		);
	
	
	// ---------------------------------
	//  TAG-RAM access
	// ---------------------------------
	
	wire		[TAG_ADDR_WIDTH-1:0]	tagram_tag_addr;
	wire		[PIX_ADDR_X_WIDTH-1:0]	tagram_pix_addr_x;
	wire		[PIX_ADDR_Y_WIDTH-1:0]	tagram_pix_addr_y;
	wire		[BLK_ADDR_X_WIDTH-1:0]	tagram_blk_addr_x;
	wire		[BLK_ADDR_Y_WIDTH-1:0]	tagram_blk_addr_y;
	wire								tagram_range_out;
	wire								tagram_cache_hit;
	wire								tagram_valid;
	wire								tagram_ready;

	jelly_texture_cache_tag
			#(
				.S_ADDR_X_WIDTH		(S_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH		(S_ADDR_Y_WIDTH),
				.S_DATA_WIDTH		(S_DATA_WIDTH),
				                     
				.TAG_ADDR_WIDTH		(TAG_ADDR_WIDTH),
				                     
				.BLK_X_SIZE			(BLK_X_SIZE),
				.BLK_Y_SIZE			(BLK_Y_SIZE),
				
				.RAM_TYPE			(TAG_RAM_TYPE)
			)
		i_texture_cache_tag
			(
				.reset				(reset),
				.clk				(clk),
				
				.clear_start		(clear_start),
				.clear_busy			(clear_busy),
				
				.param_width		(param_width),
				.param_height		(param_height),
				
				.s_addr_x			(s_araddrx),
				.s_addr_y			(s_araddry),
				.s_valid			(s_arvalid),
				.s_ready			(s_arready),
				
				.m_tag_addr			(tagram_tag_addr),
				.m_pix_addr_x		(tagram_pix_addr_x),
				.m_pix_addr_y		(tagram_pix_addr_y),
				.m_blk_addr_x		(tagram_blk_addr_x),
				.m_blk_addr_y		(tagram_blk_addr_y),
				.m_cache_hit		(tagram_cache_hit),
				.m_range_out		(tagram_range_out),
				.m_valid			(tagram_valid),
				.m_ready			(tagram_ready)
			);
	
	
	// ---------------------------------
	//  cahce miss read control
	// ---------------------------------
	
	localparam	PIX_ADDR_WIDTH = PIX_ADDR_Y_WIDTH + PIX_ADDR_X_WIDTH;
	localparam	MEM_ADDR_WIDTH = PIX_ADDR_WIDTH - M_DATA_WIDE_SIZE;
	
	wire								mem_ready;
	
	reg									reg_tagram_ready;
	
	reg		[TAG_ADDR_WIDTH-1:0]		reg_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]		reg_pix_addr_x;
	reg		[PIX_ADDR_Y_WIDTH-1:0]		reg_pix_addr_y;
	reg		[BLK_ADDR_X_WIDTH-1:0]		reg_blk_addr_x;
	reg		[BLK_ADDR_Y_WIDTH-1:0]		reg_blk_addr_y;
	reg									reg_range_out;
	reg									reg_valid;
	
	reg									reg_we;
	reg		[MEM_ADDR_WIDTH-1:0]		reg_write_addr;
	reg		[M_DATA_WIDTH-1:0]			reg_write_data;
	
	reg									reg_m_arvalid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_tagram_ready <= 1'b1;
			
			reg_tag_addr     <= {TAG_ADDR_WIDTH{1'bx}};
			reg_pix_addr_x   <= {PIX_ADDR_X_WIDTH{1'bx}};
			reg_pix_addr_y   <= {PIX_ADDR_Y_WIDTH{1'bx}};
			reg_blk_addr_x   <= {BLK_ADDR_X_WIDTH{1'bx}};
			reg_blk_addr_y   <= {BLK_ADDR_Y_WIDTH{1'bx}};
			reg_range_out    <= 1'bx;
			reg_valid        <= 1'b0;
			
			reg_we           <= 1'b0;
			reg_write_addr   <= {MEM_ADDR_WIDTH{1'b0}};
			reg_write_data   <= {M_DATA_WIDTH{1'bx}};
		end
		else begin
			if ( m_arready ) begin
				reg_m_arvalid <= 1'b0;
			end

			if ( !reg_tagram_ready ) begin
				reg_write_data <= m_rdata;
				reg_valid      <= m_rvalid;
			end
			
			if ( reg_we && reg_valid && mem_ready ) begin
				reg_write_addr <= reg_write_addr + 1'b1;
				if ( reg_write_addr == {MEM_ADDR_WIDTH{1'b1}} ) begin
					reg_tagram_ready <= 1'b1;
					reg_valid        <= 1'b1;
					reg_we           <= 1'b0;
				end
				
//				if ( reg_write_addr == {MEM_ADDR_WIDTH{1'b1}} ) begin
//					reg_we           <= 1'b0;
//				end
			end
			
			if ( tagram_ready ) begin
				if ( tagram_valid && !tagram_cache_hit && !tagram_range_out ) begin
					// cache miss
					reg_tagram_ready <= 1'b0;
					reg_we           <= 1'b1;
					reg_valid        <= 1'b0;
					reg_m_arvalid    <= 1'b1;
				end
				else begin
					reg_tagram_ready <= 1'b1;
					reg_we           <= 1'b0;
					reg_valid        <= tagram_valid;
					reg_m_arvalid    <= 1'b0;
				end
				
				reg_tag_addr   <= tagram_tag_addr;
				reg_pix_addr_x <= tagram_pix_addr_x;
				reg_pix_addr_y <= tagram_pix_addr_y;
				reg_blk_addr_x <= tagram_blk_addr_x;
				reg_blk_addr_y <= tagram_blk_addr_y;
				reg_range_out  <= tagram_range_out;
			end
		end
	end
	
	assign tagram_ready = reg_tagram_ready && (!reg_valid || mem_ready);
	
	assign m_araddrx = reg_blk_addr_x;
	assign m_araddry = reg_blk_addr_y;
	assign m_arvalid = reg_m_arvalid;
	
	assign m_rready  = mem_ready;
	
	
	// ---------------------------------
	//  cahce memory
	// ---------------------------------
	
	jelly_texture_cache_mem
			#(
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
				
				.s_we					(reg_we),
				.s_waddr				(reg_write_addr),
				.s_wdata				(reg_write_data),
				.s_tag_addr				(reg_tag_addr),
				.s_pix_addr				({reg_pix_addr_y, reg_pix_addr_x}),
				.s_range_out			(reg_range_out),
				.s_valid				(reg_valid),
				.s_ready				(mem_ready),
				
				.m_data					(s_rdata),
				.m_valid				(s_rvalid),
				.m_ready				(s_rready)
			);
	
endmodule



`default_nettype wire


// end of file
