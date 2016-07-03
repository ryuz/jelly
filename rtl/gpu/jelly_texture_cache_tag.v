// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_tag
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
			
			parameter	RAM_TYPE         = "distributed"
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_width,
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_height,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	s_addr_x,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	s_addr_y,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[TAG_ADDR_WIDTH-1:0]	m_tag_addr,
			output	wire	[PIX_ADDR_X_WIDTH-1:0]	m_pix_addr_x,
			output	wire	[PIX_ADDR_Y_WIDTH-1:0]	m_pix_addr_y,
			output	wire	[BLK_ADDR_X_WIDTH-1:0]	m_blk_addr_x,
			output	wire	[BLK_ADDR_Y_WIDTH-1:0]	m_blk_addr_y,
			output	wire							m_cache_hit,
			output	wire							m_range_out,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	
	// ---------------------------------
	//  Pipeline control
	// ---------------------------------
	
	wire	[2:0]					stage_cke;
	wire	[2:0]					stage_valid;
	
	wire	[S_ADDR_X_WIDTH-1:0]	src_addr_x;
	wire	[S_ADDR_Y_WIDTH-1:0]	src_addr_y;
	wire							src_valid;
	
	wire	[TAG_ADDR_WIDTH-1:0]	sink_tag_addr;
	wire	[PIX_ADDR_X_WIDTH-1:0]	sink_pix_addr_x;
	wire	[PIX_ADDR_Y_WIDTH-1:0]	sink_pix_addr_y;
	wire	[BLK_ADDR_X_WIDTH-1:0]	sink_blk_addr_x;
	wire	[BLK_ADDR_Y_WIDTH-1:0]	sink_blk_addr_y;
	wire							sink_cache_hit;
	wire							sink_range_out;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(3),
				.S_DATA_WIDTH		(S_ADDR_X_WIDTH + S_ADDR_X_WIDTH),
				.M_DATA_WIDTH		(TAG_ADDR_WIDTH + PIX_ADDR_X_WIDTH + PIX_ADDR_Y_WIDTH + BLK_ADDR_X_WIDTH + BLK_ADDR_Y_WIDTH + 1 + 1),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(1),
				.MASTER_OUT_REGS	(1)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({s_addr_x, s_addr_y}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({m_tag_addr, m_pix_addr_x, m_pix_addr_y, m_blk_addr_x, m_blk_addr_y, m_cache_hit, m_range_out}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			(3'd0),
				
				.src_data			({src_addr_x, src_addr_y}),
				.src_valid			(src_valid),
				
				.sink_data			({sink_tag_addr, sink_pix_addr_x, sink_pix_addr_y, sink_blk_addr_x, sink_blk_addr_y, sink_cache_hit, sink_range_out}),
				
				.buffered			()
			);
	
	
	
	
	// ---------------------------------
	//  TAG RAM (stage 1-3)
	// ---------------------------------
	
	localparam	TAG_ADDR_HALF = (TAG_ADDR_WIDTH >> 1);
	
	reg								reg_clear_busy;
	reg								reg_read_busy;
	
	reg								st0_tag_we;
	reg		[TAG_ADDR_WIDTH-1:0]	st0_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]	st0_pix_addr_x;
	reg		[PIX_ADDR_Y_WIDTH-1:0]	st0_pix_addr_y;
	reg		[BLK_ADDR_X_WIDTH-1:0]	st0_blk_addr_x;
	reg		[BLK_ADDR_Y_WIDTH-1:0]	st0_blk_addr_y;
	reg								st0_range_out;
	
	reg		[TAG_ADDR_WIDTH-1:0]	st1_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]	st1_pix_addr_x;
	reg		[PIX_ADDR_Y_WIDTH-1:0]	st1_pix_addr_y;
	reg		[BLK_ADDR_X_WIDTH-1:0]	st1_blk_addr_x;
	reg		[BLK_ADDR_Y_WIDTH-1:0]	st1_blk_addr_y;
	reg								st1_range_out;
	
	wire							read_tag_enable;
	wire	[BLK_ADDR_X_WIDTH-1:0]	read_blk_addr_x;
	wire	[BLK_ADDR_Y_WIDTH-1:0]	read_blk_addr_y;
	
	reg		[TAG_ADDR_WIDTH-1:0]	st2_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]	st2_pix_addr_x;
	reg		[PIX_ADDR_Y_WIDTH-1:0]	st2_pix_addr_y;
	reg		[BLK_ADDR_X_WIDTH-1:0]	st2_blk_addr_x;
	reg		[BLK_ADDR_Y_WIDTH-1:0]	st2_blk_addr_y;
	reg								st2_range_out;
	reg								st2_cache_hit;
	
	
	// TAG-RAM
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.DATA_WIDTH			(1 + BLK_ADDR_X_WIDTH + BLK_ADDR_Y_WIDTH),
				.RAM_TYPE			(RAM_TYPE),
				.DOUT_REGS			(0),
				.MODE				("READ_FIRST"),
				
				.FILLMEM			(1),
				.FILLMEM_DATA		(0)
			)
		i_ram_singleport
			(
				.clk				(clk),
				.en					(stage_cke[0]),
				.regcke				(1'b0),
				
				.we					(st0_tag_we),
				.addr				(st0_tag_addr),
				.din				({~reg_clear_busy, st0_blk_addr_y, st0_blk_addr_x}),
				.dout				({read_tag_enable, read_blk_addr_y, read_blk_addr_x})
			);
	
	
	wire	[PIX_ADDR_X_WIDTH-1:0]	src_pix_addr_x = src_addr_x[BLK_X_SIZE-1:0];
	wire	[PIX_ADDR_Y_WIDTH-1:0]	src_pix_addr_y = src_addr_y[BLK_Y_SIZE-1:0];
	wire	[BLK_ADDR_X_WIDTH-1:0]	src_blk_addr_x = src_addr_x[S_ADDR_X_WIDTH-1:BLK_X_SIZE];
	wire	[BLK_ADDR_Y_WIDTH-1:0]	src_blk_addr_y = src_addr_y[S_ADDR_Y_WIDTH-1:BLK_Y_SIZE];
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_clear_busy <= 1'b0;
			reg_read_busy  <= 1'b0;
			
			st0_tag_we     <= 1'b0;
			st0_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st0_pix_addr_x <= {PIX_ADDR_X_WIDTH{1'bx}};
			st0_pix_addr_y <= {PIX_ADDR_Y_WIDTH{1'bx}};
			st0_blk_addr_x <= {BLK_ADDR_X_WIDTH{1'bx}};
			st0_blk_addr_y <= {BLK_ADDR_Y_WIDTH{1'bx}};
			st0_range_out  <= 1'bx;
			
			st1_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st1_pix_addr_x <= {PIX_ADDR_X_WIDTH{1'bx}};
			st1_pix_addr_y <= {PIX_ADDR_Y_WIDTH{1'bx}};
			st1_blk_addr_x <= {BLK_ADDR_X_WIDTH{1'bx}};
			st1_blk_addr_y <= {BLK_ADDR_Y_WIDTH{1'bx}};
			st1_range_out  <= 1'bx;
			
			st2_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st2_pix_addr_x <= {PIX_ADDR_X_WIDTH{1'bx}};
			st2_pix_addr_y <= {PIX_ADDR_Y_WIDTH{1'bx}};
			st2_blk_addr_x <= {BLK_ADDR_X_WIDTH{1'bx}};
			st2_blk_addr_y <= {BLK_ADDR_Y_WIDTH{1'bx}};
			st2_cache_hit  <= 1'b0;
			st2_range_out  <= 1'bx;
		end
		else begin
			// stage0
			if ( reg_clear_busy ) begin
				// clear next
				st0_tag_addr <= st1_tag_addr + 1'b1;
				
				// clear end
				if ( st0_tag_addr == {TAG_ADDR_WIDTH{1'b1}} ) begin
					reg_clear_busy <= 1'b0;
				end
			end
			else if ( clear_start ) begin
				// start cache clear
				reg_clear_busy <= 1'b1;
				st0_tag_addr   <= {TAG_ADDR_WIDTH{1'b0}};
				st0_tag_we     <= 1'b1;
			end
			else if ( stage_cke[0] ) begin
				st0_tag_we     <= (src_valid && src_addr_x < param_width && src_addr_y < param_height);
				st0_tag_addr   <= src_blk_addr_x[TAG_ADDR_WIDTH-1:0] + {src_blk_addr_y[TAG_ADDR_HALF-1:0], src_blk_addr_y[TAG_ADDR_WIDTH-1:TAG_ADDR_HALF]};
			end
			
			if ( stage_cke[0] ) begin
				st0_blk_addr_x <= src_blk_addr_x;
				st0_blk_addr_y <= src_blk_addr_y;
				st0_pix_addr_x <= src_pix_addr_x;
				st0_pix_addr_y <= src_pix_addr_y;
				st0_range_out  <= (src_addr_x >= param_width || src_addr_y >= param_height);
			end
			
			
			// stage1
			if ( stage_cke[1] ) begin
				st1_tag_addr   <= st0_tag_addr;
				st1_blk_addr_x <= st0_blk_addr_x;
				st1_blk_addr_y <= st0_blk_addr_y;
				st1_pix_addr_x <= st0_pix_addr_x;
				st1_pix_addr_y <= st0_pix_addr_y;
				st1_range_out  <= st0_range_out;
			end
			
			// stage 2
			if ( stage_cke[2] ) begin
				st2_tag_addr   <= st1_tag_addr;
				st2_blk_addr_x <= st1_blk_addr_x;
				st2_blk_addr_y <= st1_blk_addr_y;
				st2_pix_addr_x <= st1_pix_addr_x;
				st2_pix_addr_y <= st1_pix_addr_y;
				st2_range_out  <= st1_range_out;
				st2_cache_hit  <= (read_tag_enable && ({st1_blk_addr_y, st1_blk_addr_x} == {read_blk_addr_y, read_blk_addr_x}));
			end
		end
	end
	
	assign clear_busy      = reg_read_busy;
	
	assign sink_tag_addr   = st2_tag_addr;
	assign sink_pix_addr_x = st2_pix_addr_x;
	assign sink_pix_addr_y = st2_pix_addr_y;
	assign sink_blk_addr_x = st2_blk_addr_x;
	assign sink_blk_addr_y = st2_blk_addr_y;
	assign sink_cache_hit  = st2_cache_hit;
	assign sink_range_out  = st2_range_out;
	
endmodule



`default_nettype wire


// end of file
