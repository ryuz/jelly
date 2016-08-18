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
			parameter	USER_WIDTH           = 1,
			parameter	COMPONENT_NUM        = 1,
			parameter	COMPONENT_DATA_WIDTH = 24,
			parameter	TAG_ADDR_WIDTH       = 6,
			parameter	PIX_ADDR_WIDTH       = 4,
			parameter	M_DATA_WIDTH         = COMPONENT_NUM * COMPONENT_DATA_WIDTH,
			parameter	S_DATA_WIDE_SIZE     = 1,
			parameter	S_ADDR_WIDTH         = PIX_ADDR_WIDTH - S_DATA_WIDE_SIZE,
			parameter	S_DATA_WIDTH         = (M_DATA_WIDTH << S_DATA_WIDE_SIZE),
			parameter	BORDER_DATA          = {M_DATA_WIDTH{1'b0}},
			parameter	RAM_TYPE             = "block",
			parameter	MASTER_REGS          = 1
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							endian,
			
			output	wire							busy,
			
			input	wire	[USER_WIDTH-1:0]		s_user,
			input	wire	[COMPONENT_NUM-1:0]		s_we,
			input	wire	[S_DATA_WIDTH-1:0]		s_wdata,
			input	wire	[TAG_ADDR_WIDTH-1:0]	s_tag_addr,
			input	wire	[PIX_ADDR_WIDTH-1:0]	s_pix_addr,
			input	wire							s_range_out,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[USER_WIDTH-1:0]		m_user,
			output	wire	[M_DATA_WIDTH-1:0]		m_data,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	localparam	SEL_WIDTH         = S_DATA_WIDE_SIZE > 0 ? S_DATA_WIDE_SIZE : 1;
	localparam	S_COMPONENT_WIDTH = (COMPONENT_DATA_WIDTH << S_DATA_WIDE_SIZE);
	
	genvar							i;
	
	
	//  cahce memory read
	wire							cke;
	
	wire	[USER_WIDTH-1:0]		st0_user      = s_user;
	wire	[COMPONENT_NUM-1:0]		st0_we        = s_we;
	wire	[S_DATA_WIDTH-1:0]		st0_wdata     = s_wdata;
	wire	[TAG_ADDR_WIDTH-1:0]	st0_tag_addr  = s_tag_addr;
	wire	[S_ADDR_WIDTH-1:0]		st0_addr      = ({s_tag_addr, s_pix_addr} >> S_DATA_WIDE_SIZE);
	wire	[SEL_WIDTH-1:0]			st0_sel       = {s_tag_addr, s_pix_addr};
	wire							st0_range_out = s_range_out;
	wire							st0_valid     = s_valid;
	
	reg		[USER_WIDTH-1:0]		st1_user;
	reg		[SEL_WIDTH-1:0]			st1_sel;
	reg								st1_range_out;
	reg								st1_valid;
	
	reg		[USER_WIDTH-1:0]		st2_user;
	reg		[SEL_WIDTH-1:0]			st2_sel;
	reg								st2_range_out;
	reg								st2_valid;
	
	wire	[S_DATA_WIDTH-1:0]		mem_rdata;
	wire	[M_DATA_WIDTH-1:0]		read_data;
	
	reg		[USER_WIDTH-1:0]		st3_user;
	reg		[M_DATA_WIDTH-1:0]		st3_data;
	reg								st3_valid;
	
	
	generate
	for ( i = 0; i < COMPONENT_NUM; i = i+1 ) begin : mem_loop
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
					
					.we					(st0_we[i]),
					.addr				({st0_tag_addr, st0_addr}),
					.din				(st0_wdata[S_COMPONENT_WIDTH*i +: S_COMPONENT_WIDTH]),
					.dout				(mem_rdata[S_COMPONENT_WIDTH*i +: S_COMPONENT_WIDTH])
				);
		
		jelly_multiplexer
				#(
					.SEL_WIDTH			(S_DATA_WIDE_SIZE),
					.OUT_WIDTH			(COMPONENT_DATA_WIDTH)
				)
			i_multiplexer
				(
					.endian				(endian),
					.sel				(st2_sel),
					.din				(mem_rdata[S_COMPONENT_WIDTH*i +: S_COMPONENT_WIDTH]),
					.dout				(read_data[COMPONENT_DATA_WIDTH*i   +: COMPONENT_DATA_WIDTH])
				);
	end
	endgenerate
	
	
	// pipeline
	always @(posedge clk) begin
		if ( reset ) begin
			st1_user       <= {USER_WIDTH{1'bx}};
			st1_sel        <= {SEL_WIDTH{1'bx}};
			st1_range_out  <= 1'bx;
			st1_valid      <= 1'b0;
			
			st2_user       <= {USER_WIDTH{1'bx}};
			st2_sel        <= {SEL_WIDTH{1'bx}};
			st2_range_out  <= 1'bx;
			st2_valid      <= 1'b0;
			
			st3_user       <= {USER_WIDTH{1'bx}};
			st3_data       <= {M_DATA_WIDTH{1'bx}};
			st3_valid      <= 1'b0;
		end
		else if ( cke ) begin
			// stage1
			st1_user      <= st0_user;
			st1_sel       <= st0_sel;
			st1_range_out <= st0_range_out;
			st1_valid     <= st0_valid;
			
			// stage2
			st2_user      <= st1_user;
			st2_sel       <= st1_sel;
			st2_range_out <= st1_range_out;
			st2_valid     <= st1_valid;
			
			// stage3
			st3_user      <= st2_user;
			st3_data      <= st2_range_out ? BORDER_DATA : read_data;
			st3_valid     <= st2_valid;
		end
	end
	
	
	// output
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(USER_WIDTH + M_DATA_WIDTH),
				.SLAVE_REGS			(1),
				.MASTER_REGS		(MASTER_REGS)
			)
		i_pipeline_insert_ff
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({st3_user, st3_data}),
				.s_valid			(st3_valid),
				.s_ready			(cke),
				
				.m_data				({m_user, m_data}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	assign s_ready = cke;
	
	assign busy    = (!cke || st0_valid || st1_valid || st2_valid || st3_valid);
	
endmodule



`default_nettype wire


// end of file
