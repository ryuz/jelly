// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_mem
		#(
			parameter	TAG_ADDR_WIDTH   = 6,
			parameter	PIX_ADDR_WIDTH   = 4,
			parameter	M_DATA_WIDTH     = 24,
			parameter	S_DATA_WIDE_SIZE = 1,
			parameter	S_ADDR_WIDTH     = PIX_ADDR_WIDTH - S_DATA_WIDE_SIZE,
			parameter	S_DATA_WIDTH     = (M_DATA_WIDTH << S_DATA_WIDE_SIZE),
			parameter	BORDER_DATA      = {M_DATA_WIDTH{1'b0}},
			parameter	RAM_TYPE         = "block",
			parameter	MASTER_REGS      = 1
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
	
	
	
	//  cahce memory read
	wire							cke;
	
	reg								st0_we;
	reg		[TAG_ADDR_WIDTH-1:0]	st0_tag_addr;
	reg		[S_ADDR_WIDTH-1:0]		st0_addr;
	reg		[S_DATA_WIDTH-1:0]		st0_wdata;
	reg		[SEL_WIDTH-1:0]			st0_sel;
	reg								st0_range_out;
	reg								st0_valid;
	
	reg		[SEL_WIDTH-1:0]			st1_sel;
	reg								st1_range_out;
	reg								st1_valid;
	
	reg		[SEL_WIDTH-1:0]			st2_sel;
	reg								st2_range_out;
	reg								st2_valid;
	
	wire	[S_DATA_WIDTH-1:0]		mem_rdata;
	wire	[M_DATA_WIDTH-1:0]		read_data;
	
	reg		[M_DATA_WIDTH-1:0]		st3_data;
	reg								st3_valid;
	
	
	// CACHE-RAM
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(TAG_ADDR_WIDTH + S_ADDR_WIDTH),
				.DATA_WIDTH			(S_DATA_WIDTH),
				.RAM_TYPE			(RAM_TYPE),
				.DOUT_REGS			(1)
			)
		i_ram_singleport
			(
				.clk				(clk),
				.en					(cke),
				.regcke				(cke),
				
				.we					(st0_we),
				.addr				({st0_tag_addr, st0_addr}),
				.din				(st0_wdata),
				.dout				(mem_rdata)
			);
	
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
			st0_tag_addr   <= {TAG_ADDR_WIDTH{1'bx}};
			st0_addr       <= {S_ADDR_WIDTH{1'bx}};
			st0_wdata      <= {S_DATA_WIDTH{1'bx}};
			st0_sel        <= {SEL_WIDTH{1'bx}};
			st0_range_out  <= 1'bx;
			st0_valid      <= 1'b0;
			
			st1_sel        <= {SEL_WIDTH{1'bx}};
			st1_range_out  <= 1'bx;
			st1_valid      <= 1'b0;
			
			st2_sel        <= {SEL_WIDTH{1'bx}};
			st2_range_out  <= 1'bx;
			st2_valid      <= 1'b0;
			
			st3_data       <= {M_DATA_WIDTH{1'bx}};
			st3_valid      <= 1'b0;
		end
		else if ( cke ) begin
			// stage0
			st0_we        <= s_we;
			st0_tag_addr  <= s_tag_addr;
			st0_addr      <= s_we ? s_waddr : ({s_tag_addr, s_pix_addr} >> S_DATA_WIDE_SIZE);
			st0_wdata     <= s_wdata;
			st0_sel       <= {s_tag_addr, s_pix_addr};
			st0_range_out <= s_range_out;
			st0_valid     <= s_valid;
			
			// stage1
			st1_sel       <= st0_sel;
			st1_range_out <= st0_range_out;
			st1_valid     <= (st0_valid && !st0_we);
			
			// stage2
			st2_sel       <= st1_sel;
			st2_range_out <= st1_range_out;
			st2_valid     <= st1_valid;
			
			// stage3
			st3_data      <= st2_range_out ? BORDER_DATA : read_data;
			st3_valid     <= st2_valid;
		end
	end
	
	
	// output
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(M_DATA_WIDTH),
				.SLAVE_REGS			(1),
				.MASTER_REGS		(MASTER_REGS)
			)
		i_pipeline_insert_ff
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				(st3_data),
				.s_valid			(st3_valid),
				.s_ready			(cke),
				
				.m_data				(m_data),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	assign s_ready = cke;
	
endmodule



`default_nettype wire


// end of file
