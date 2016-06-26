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
			
			parameter	BLK_ADDR_X_WIDTH = 2,
			parameter	BLK_ADDR_Y_WIDTH = 2,
			
			parameter	M_ADDR_X_WIDTH   = S_ADDR_X_WIDTH - BLK_ADDR_X_WIDTH,
			parameter	M_ADDR_Y_WIDTH   = S_ADDR_Y_WIDTH - BLK_ADDR_Y_WIDTH,
			
			parameter	M_DATA_WIDE_SIZE = 0,
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
			output	wire							ckear_busy,
			
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
			
			input	wire							m_rlast,
			input	wire	[M_DATA_WIDTH-1:0]		m_rdata,
			input	wire							m_rvalid
		);
	
	
	
	// ---------------------------------
	//  TAG RAM (stage 1-3)
	// ---------------------------------
	
	localparam	TAG_ADDR_HALF = (TAG_ADDR_WIDTH >> 1);
	
	reg								reg_clear_busy;
	reg								reg_read_busy;
	
	reg								reg_m_arvalid;	
	
	reg								st1_tag_we;
	reg		[TAG_ADDR_WIDTH-1:0]	st1_tag_addr;
	reg		[M_ADDR_X_WIDTH-1:0]	st1_blk_addr_x;
	reg		[M_ADDR_Y_WIDTH-1:0]	st1_blk_addr_y;
	reg		[M_ADDR_X_WIDTH-1:0]	st1_pix_addr_x;
	reg		[M_ADDR_Y_WIDTH-1:0]	st1_pix_addr_y;
	reg								st1_valid;
	
	wire							sig_tag_enable;
	wire	[M_ADDR_X_WIDTH-1:0]	sig_blk_addr_x;
	wire	[M_ADDR_Y_WIDTH-1:0]	sig_blk_addr_y;
	
	reg		[TAG_ADDR_WIDTH-1:0]	st2_tag_addr;
	reg		[M_ADDR_X_WIDTH-1:0]	st2_blk_addr_x;
	reg		[M_ADDR_Y_WIDTH-1:0]	st2_blk_addr_y;
	reg		[M_ADDR_X_WIDTH-1:0]	st2_pix_addr_x;
	reg		[M_ADDR_Y_WIDTH-1:0]	st2_pix_addr_y;
	reg								st2_valid;
	
	reg		[TAG_ADDR_WIDTH-1:0]	st3_tag_addr;
	reg		[M_ADDR_X_WIDTH-1:0]	st3_blk_addr_x;
	reg		[M_ADDR_Y_WIDTH-1:0]	st3_blk_addr_y;
	reg		[M_ADDR_X_WIDTH-1:0]	st3_pix_addr_x;
	reg		[M_ADDR_Y_WIDTH-1:0]	st3_pix_addr_y;
	reg								st3_valid;
	
	
	// TAG-RAM
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.DATA_WIDTH			(1 + M_ADDR_X_WIDTH + M_ADDR_Y_WIDTH),
				.RAM_TYPE			(TAG_RAM_TYPE),
				.DOUT_REGS			(0),
				.MODE				("READ_FIRST"),
				
				.FILLMEM			(1),
				.FILLMEM_DATA		(0)
			)
		i_ram_singleport_tag
			(
				.clk				(clk),
				.en					(~reg_read_busy),
				.regcke				(~reg_read_busy),
				
				.we					(st1_tag_we),
				.addr				(st1_tag_addr),
				.din				({~reg_clear_busy, st1_blk_addr_y, st1_blk_addr_x}),
				.dout				({sig_tag_enable, sig_blk_addr_y, sig_blk_addr_x})
			);
	
	
	wire	[M_ADDR_X_WIDTH-1:0]	s_blk_addr_x = s_araddrx[S_ADDR_X_WIDTH-1:BLK_ADDR_X_WIDTH];
	wire	[M_ADDR_Y_WIDTH-1:0]	s_blk_addr_y = s_araddry[S_ADDR_Y_WIDTH-1:BLK_ADDR_Y_WIDTH];
	wire	[M_ADDR_X_WIDTH-1:0]	s_pix_addr_x = s_araddrx[BLK_ADDR_X_WIDTH-1:0];
	wire	[M_ADDR_Y_WIDTH-1:0]	s_pix_addr_y = s_araddry[BLK_ADDR_Y_WIDTH-1:0];
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_clear_busy <= 1'b0;
			reg_read_busy  <= 1'b0;
			
			st1_tag_we     <= 1'b0;
			st1_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st1_blk_addr_x <= {M_ADDR_X_WIDTH{1'bx}};
			st1_blk_addr_y <= {M_ADDR_X_WIDTH{1'bx}};
			st1_pix_addr_x <= {M_ADDR_X_WIDTH{1'bx}};
			st1_pix_addr_y <= {M_ADDR_X_WIDTH{1'bx}};
			st1_valid      <= 1'b0;
			
			st2_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st2_blk_addr_x <= {M_ADDR_X_WIDTH{1'bx}};
			st2_blk_addr_y <= {M_ADDR_X_WIDTH{1'bx}};
			st2_pix_addr_x <= {M_ADDR_X_WIDTH{1'bx}};
			st2_pix_addr_y <= {M_ADDR_X_WIDTH{1'bx}};
			st2_valid      <= 1'b0;
			
			st3_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st3_blk_addr_x <= {M_ADDR_X_WIDTH{1'bx}};
			st3_blk_addr_y <= {M_ADDR_X_WIDTH{1'bx}};
			st3_pix_addr_x <= {M_ADDR_X_WIDTH{1'bx}};
			st3_pix_addr_y <= {M_ADDR_X_WIDTH{1'bx}};
			st3_valid      <= 1'b0;
		end
		else begin
			// stage1
			if ( !reg_read_busy ) begin
				// input
				st1_tag_addr   <= s_blk_addr_x[TAG_ADDR_WIDTH-1:0] + {s_blk_addr_y[TAG_ADDR_HALF-1:0], s_blk_addr_y[TAG_ADDR_WIDTH-1:TAG_ADDR_HALF]};
				st1_blk_addr_x <= s_blk_addr_x;
				st1_blk_addr_y <= s_blk_addr_y;
				st1_pix_addr_x <= s_pix_addr_x;
				st1_pix_addr_y <= s_pix_addr_y;
				st1_tag_we     <= s_arvalid && s_arready;
				st1_valid      <= s_arvalid && s_arready;
				
				// clear control
				if ( !reg_clear_busy ) begin
					// clear start
					if ( clear_start ) begin
						reg_clear_busy <= 1'b1;
						st1_tag_addr   <= {TAG_ADDR_WIDTH{1'b0}};
						st1_tag_we     <= 1'b1;
						st1_valid      <= 1'b0;
					end
				end
				else begin
					// clear next
					st1_tag_addr <= st1_tag_addr + 1'b1;
					
					// clear end
					if ( st1_tag_addr == {TAG_ADDR_WIDTH{1'b1}} ) begin
						reg_clear_busy <= 1'b0;
					end
				end
			end
			
			
			// stage2
			if ( !reg_read_busy ) begin
				st2_tag_addr   <= st1_tag_addr;
				st2_blk_addr_x <= st1_blk_addr_x;
				st2_blk_addr_y <= st1_blk_addr_y;
				st2_pix_addr_x <= st1_pix_addr_x;
				st2_pix_addr_y <= st1_pix_addr_y;
				st2_valid      <= st1_valid;
			end
			
			
			// stage2
			if ( !reg_read_busy ) begin
				st2_tag_addr   <= st1_tag_addr;
				st2_blk_addr_x <= st1_blk_addr_x;
				st2_blk_addr_y <= st1_blk_addr_y;
				st2_pix_addr_x <= st1_pix_addr_x;
				st2_pix_addr_y <= st1_pix_addr_y;
				st2_valid      <= st1_valid;
			end
			
			
			// stage 3
			if ( m_arready ) begin
				reg_m_arvalid <= 1'b0;	// read command send end
			end
			
			if ( !reg_read_busy ) begin
				st3_tag_addr   <= st2_tag_addr;
				st3_blk_addr_x <= st2_blk_addr_x;
				st3_blk_addr_y <= st2_blk_addr_y;
				st3_pix_addr_x <= st2_pix_addr_x;
				st3_pix_addr_y <= st2_pix_addr_y;
				st3_valid      <= st2_valid;
				
				// cache miss
				if ( st2_valid && (!sig_tag_enable || ({st2_blk_addr_y, st2_blk_addr_x} != {sig_blk_addr_y, sig_blk_addr_x})) ) begin
					// read start
					reg_read_busy  <= 1'b1;
					st3_valid      <= 1'b0;
					
					reg_m_arvalid  <= 1'b1;	// read command send start
				end
			end
			
			// cache fill
			if ( m_rlast && m_rvalid ) begin
				reg_read_busy <= 1'b0;	// read end
				st3_valid     <= 1'b1;
			end
		end
	end
	
	assign s_arready = !reg_read_busy;
	
	assign m_araddrx = st3_blk_addr_x;
	assign m_araddry = st3_blk_addr_y;
	assign m_arvalid = reg_m_arvalid;
	
	
	
	// ---------------------------------
	//  Cache-RAM
	// ---------------------------------
	
	localparam	CACHE_ADDR_WIDTH = TAG_ADDR_WIDTH + BLK_ADDR_Y_WIDTH + BLK_ADDR_X_WIDTH - M_DATA_WIDE_SIZE;
	
	// Cache-RAM
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(CACHE_ADDR_WIDTH),
				.DATA_WIDTH			(M_DATA_WIDTH),
				.RAM_TYPE			(MEM_RAM_TYPE),
				.DOUT_REGS			(1)
			)
		i_ram_singleport_cache
			(
				.clk				(clk),
				.en					(),
				.regcke				(),
				
				.we					(st1_tag_we),
				.addr				(st1_tag_addr),
				.din				({~reg_clear_busy, st1_blk_addr_y, st1_blk_addr_x}),
				.dout				({sig_tag_enable, sig_blk_addr_y, sig_blk_addr_x})
			);
	
	
	
	/*
	
	// ---------------------------------
	//  memory
	// ---------------------------------
	
	localparam	MEM_ADDR_WIDTH = MEM_X_WIDTH + MEM_Y_WIDTH;
	localparam	MEM_DATA_WIDTH = M_DATA_WIDTH;
	
	wire							mem_we;
	wire	[MEM_ADDR_WIDTH-1:0]	mem_addr;
	wire	[MEM_DATA_WIDTH-1:0]	mem_din;
	wire	[MEM_DATA_WIDTH-1:0]	mem_dout;
	
	jelly_ram_singleport
			#(
				.ADDR_WIDTH		(MEM_ADDR_WIDTH),
				.DATA_WIDTH		(MEM_DATA_WIDTH),
				.RAM_TYPE		(RAM_TYPE),
				.DOUT_REGS		(1)
			)
		i_ram_singleport
			(
				.clk			(clk),
				.en				(1'b1),
				.regcke			(1'b1),
				.we				(mem_we),
				.addr			(mem_addr),
				.din			(mem_din),
				.dout			(mem_dout)
			);
	
	
	localparam	MEM_SEL_WIDTH  = X_WIDE_SIZE + Y_WIDE_SIZE;
	localparam	MEM_SEL_BITS   = MEM_SEL_WIDTH > 0 ? MEM_SEL_WIDTH : 1;
	
	wire	[MEM_SEL_BITS-1:0]		mem_read_sel;
	wire	[S_DATA_WIDTH-1:0]		mem_read_data;
	
	jelly_demultiplexer
			#(
				.SEL_WIDTH		(X_WIDE_SIZE + Y_WIDE_SIZE),
				.IN_WIDTH		(  = 8,
			)
		i_demultiplexer
			(
				.endian			(endian),
				.sel			(mem_sel),
				.din			(mem_dout),
				.dout			(mem_read_data)
			);
	
	
	
	
	// ---------------------------------
	//  read pipeline
	// ---------------------------------
	
	wire	cke = (s_rvalid && !s_rready);
	
	wire	[BLK_ADR_X_WIDTH-1:0]	s_araddr_pix_x = s_araddrx[BLK_ADR_X_WIDTH-1:0];
	wire	[BLK_ADR_Y_WIDTH-1:0]	s_araddr_pix_y = s_araddry[BLK_ADR_Y_WIDTH-1:0];
	wire	[M_ADR_X_WIDTH-1:0]		s_araddr_blk_x = s_araddrx[S_ADR_X_WIDTH-1:BLK_ADR_X_WIDTH];
	wire	[M_ADR_Y_WIDTH-1:0]		s_araddr_blk_y = s_araddrx[S_ADR_Y_WIDTH-1:BLK_ADR_Y_WIDTH];
	
	s_araddr_tag 
	
	wire	[S_ADR_X_WIDTH-1:0]
	
	always @(posedge clk) begin
		if ( reset ) begin
		end
		else if ( cke ) begin
			// stage 1
			if ( s_arready ) begin
				st1_x_pix    <= s_araddr_pix_x;
				st1_y_pix    <= s_araddr_pix_y;
				
				st1_rangeout <= ((s_araddrx >= param_width) || (s_araddry >= param_height));
				st1_valid    <= s_arvalid;
			end
			
			// stage 2
			if ( s_arready ) begin
				if ( st1_valid && !st1_rangeout ) begin
					st2_x <= st1_x;
					st2_y <= st1_y;
				end
				st2_rangeout <= st1_rangeout;
				st2_valid    <= st1_valid;
			end
			
			// stage 3
			st3_sel      <= {st2_y, st2_x};
			st3_rangeout <= st2_rangeout;
			st3_valid    <= st2_valid;
			
			// stage 4
			st4_data  <= st3_rangeout ? BORDER_DATA : mem_read_data;
			st4_valid <= st3_valid;
		end
	end
	
	*/
	
	
endmodule



`default_nettype wire


// end of file
