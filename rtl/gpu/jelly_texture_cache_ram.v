// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_ram
		#(
			parameter	TAG_ADDR_WIDTH   = 6,
			parameter	PIX_ADDR_WIDTH   = 4,
			parameter	M_DATA_WIDTH     = 24,
			parameter	S_DATA_WIDE_SIZE = 1,
			parameter	S_ADDR_WIDTH     = TAG_ADDR_WIDTH + PIX_ADDR_WIDTH - S_DATA_WIDE_SIZE,
			parameter	S_DATA_WIDTH     = (M_DATA_WIDTH << S_DATA_WIDE_SIZE),
			parameter	BORDER_DATA      = {DATA_WIDTH{1'b0}},
			parameter	RAM_TYPE         = "block"
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							endian,
			
			input	wire							s_we,
			input	wire	[S_ADDR_WIDTH-1:0]		s_waddr,
			input	wire	[S_DATA_WIDTH-1:0]		s_wdata,
			input	wire	[TAG_ADDR_WIDTH-1:0]	s_tag_addr,
			input	wire	[PIX_ADDR_WIDTH-1:0]	s_pix_addr,
			input	wire							s_range_out,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[M_DATA_WIDTH-1:0]		m_data,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	localparam	SEL_WIDTH      = S_DATA_WIDE_SIZE > 0 ? S_DATA_WIDE_SIZE : 1;
	
	
	// ---------------------------------
	//  Pipeline control
	// ---------------------------------
	
	wire	[3:0]					stage_cke;
	wire	[3:0]					stage_valid;
	
	wire							src_we;
	wire	[S_ADDR_WIDTH-1:0]		src_waddr;
	wire	[S_DATA_WIDTH-1:0]		src_wdata;
	wire	[TAG_ADDR_WIDTH-1:0]	src_tag_addr,
	wire	[PIX_ADDR_WIDTH-1:0]	src_pix_addr;
	wire							src_range_out;
	
	wire	[M_DATA_WIDTH-1:0]		sink_data;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(4),
				.S_DATA_WIDTH		(1 + S_ADDR_WIDTH + S_DATA_WIDTH + TAG_ADDR_WIDTH + PIX_ADDR_WIDTH + 1),
				.M_DATA_WIDTH		(M_DATA_WIDTH),
				.AUTO_VALID			(1),
				.MASTER_IN_REGS		(1),
				.MASTER_OUT_REGS	(1)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({
										s_we,
										s_waddr,
										s_wdata,
										s_tag_addr,
										s_pix_addr,
										s_range_out,
										s_valid,
										s_ready
									}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				(m_data),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			(3'd0),
				
				.src_data			({
										src_we,
										src_waddr,
										src_wdata,
										src_tag_addr,
										src_pix_addr,
										src_range_out,
										src_valid,
										src_ready
									}),
				
				.sink_data			(sink_data),
				
				.buffered			()
			);
	
	
	
	// ---------------------------------
	//  Cahce read
	// ---------------------------------
	
	reg								st0_we;
	reg		[MEM_ADDR_WIDTH-1:0]	st0_addr;
	reg		[S_DATA_WIDTH-1:0]		st0_wdata;
	reg		[SEL_WIDTH-1:0]			st0_sel;
	reg								st0_range_out;
	
	reg		[SEL_WIDTH-1:0]			st1_sel;
	reg								st1_range_out;
	
	reg		[SEL_WIDTH-1:0]			st2_sel;
	reg								st2_range_out;
	
	reg		[M_DATA_WIDTH-1:0]		st3_data;
	
	// CACHE-RAM
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(S_ADDR_WIDTH),
				.DATA_WIDTH			(S_DATA_WIDTH),
				.RAM_TYPE			(RAM_TYPE),
				.DOUT_REGS			(1)
			)
		i_ram_singleport
			(
				.clk				(clk),
				.en					(stage_cke[0]),
				.regcke				(stage_cke[1]),
				
				.we					(st0_we),
				.addr				(st0_addr),
				.din				(st0_wdata),
				.dout				(mem_rdata)
			);
	
		jelly_ram_singleport
			#(
				.ADDR_WIDTH			(MEM_ADDR_WIDTH),
				.DATA_WIDTH			(S_DATA_WIDTH),
				.RAM_TYPE			(RAM_TYPE),
				.DOUT_REGS			(1)
			)
		i_ram_singleport
			(
				.clk				(clk),
				.en					(stage_cke[0]),
				.regcke				(stage_cke[1]),
				
				.we					(st0_we),
				.addr				(st0_addr),
				.din				(st0_wdata),
				.dout				(mem_rdata)
			);
	
	wire	[M_DATA_WIDTH-1:0]		read_data;
	jelly_multiplexer
			#(
				.SEL_WIDTH			(S_DATA_WIDE_SIZE),
				.OUT_WIDTH			(M_DATA_WIDTH)
			)
		i_multiplexer
			(
				.endian				(endian),
				.sel				(st2_sel),
				.din				(mem_rdata),
				.dout				(read_data)
			);
	
	
	// pipeline
	always @(posedge clk) begin
		if ( reset ) begin
			st0_we         <= 1'b0;
			st0_addr       <= {MEM_ADDR_WIDTH{1'bx}};
			st0_wdata      <= {S_DATA_WIDTH{1'bx}};
			st0_sel        <= {SEL_WIDTH{1'bx}};
			st0_range_out  <= 1'bx;
			
			st1_sel        <= {SEL_WIDTH{1'bx}};
			st1_range_out  <= 1'bx;
			
			st2_sel        <= {SEL_WIDTH{1'bx}};
			st2_range_out  <= 1'bx;
			
			st3_data       <= {M_DATA_WIDTH{1'bx}};
		end
		else begin
			// stage0
			if ( stage_cke[0] ) begin
				st0_we        <= src_we;
				st0_addr      <= src_we ? src_waddr : ({s_tag_addr, s_pix_addr} >> S_DATA_WIDE_SIZE);
				st0_wdata     <= src_wdata;
				st0_sel       <= {s_tag_addr, s_pix_addr};
				st0_range_out <= src_range_out;
			end
			
			// stage1
			if ( stage_cke[1] ) begin
				st1_sel       <= st0_sel;
				st1_range_out <= st0_range_out;
			end
			
			// stage2
			if ( stage_cke[2] ) begin
				st2_sel       <= st1_sel;
				st2_range_out <= st1_range_out;
			end
			
			// stage3
			if ( stage_cke[3] ) begin
				st3_data      <= st2_range_out ? BORDER_DATA : read_data;
			end
		end
	end
	
	assign sink_data = st3_data;
	
endmodule



`default_nettype wire


// end of file
