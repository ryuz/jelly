// ---------------------------------------------------------------------------
//  AXI4Stream を AXI4に Write するコア
//      受付コマンド数などは AXI interconnect などで制約できるので
//    コアはシンプルな作りとする
//
//                                      Copyright (C) 2015 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly_axi4_dma_writer
		#(
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
			parameter	AXI4_STRB_WIDTH  = (1 << AXI4_DATA_SIZE),
			parameter	AXI4_LEN_WIDTH   = 8,
			parameter	AXI4_QOS_WIDTH   = 4,
			parameter	AXI4S_DATA_WIDTH = AXI4_DATA_WIDTH,
			parameter	COUNT_WIDTH      = AXI4_ADDR_WIDTH - AXI4_DATA_SIZE
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			// control
			input	wire							enable,
			output	wire							busy,
			
			// parameter
			input	wire	[AXI4_ADDR_WIDTH-1:0]	param_addr,
			input	wire	[COUNT_WIDTH-1:0]		param_count,
			input	wire	[AXI4_LEN_WIDTH-1:0]	param_maxlen,
			
			// master AXI4 (write)
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_awid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_awaddr,
			output	wire	[1:0]					m_axi4_awburst,
			output	wire	[3:0]					m_axi4_awcache,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_awlen,
			output	wire	[0:0]					m_axi4_awlock,
			output	wire	[2:0]					m_axi4_awprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_awqos,
			output	wire	[3:0]					m_axi4_awregion,
			output	wire	[2:0]					m_axi4_awsize,
			output	wire							m_axi4_awvalid,
			input	wire							m_axi4_awready,
			output	wire	[AXI4_STRB_WIDTH-1:0]	m_axi4_wstrb,
			output	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_wdata,
			output	wire							m_axi4_wlast,
			output	wire							m_axi4_wvalid,
			input	wire							m_axi4_wready,
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_bid,
			input	wire	[1:0]					m_axi4_bresp,
			input	wire							m_axi4_bvalid,
			output	wire							m_axi4_bready,
			
			// slave AXI4-Stream
			input	wire	[AXI4S_DATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready
		);
	
	wire							cmd_busy;
	
	wire	[AXI4_LEN_WIDTH-1:0]	cmd_len;
	wire							cmd_valid;
	wire							cmd_ready;
	
	jelly_axi4_dma_addr
			#(
				.AXI4_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH	(AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE		(AXI4_DATA_SIZE),
				.AXI4_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.COUNT_WIDTH		(COUNT_WIDTH)
			)
		i_axi4_dma_addr
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.enable				(enable),
				.busy				(cmd_busy),
				
				.param_addr			(param_addr),
				.param_count		(param_count),
				.param_maxlen		(param_maxlen),
				
				.m_cmd_len			(cmd_len),
				.m_cmd_valid		(cmd_valid),
				.m_cmd_ready		(cmd_ready),
				
				.m_axi4_addr		(m_axi4_awaddr),
				.m_axi4_len			(m_axi4_awlen),
				.m_axi4_valid		(m_axi4_awvalid),
				.m_axi4_ready		(m_axi4_awready)
			);
	
	assign m_axi4_awburst = 2'b01;
	assign m_axi4_awcache = 4'b0001;
	assign m_axi4_awlock  = 1'b0;
	assign m_axi4_awprot  = 3'b000;
	assign m_axi4_awqos   = 0;
	assign m_axi4_awregion = 4'b0000;
	assign m_axi4_awsize   = AXI4_DATA_SIZE;
	
		
	reg								reg_wbusy,  next_wbusy;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_wcount, next_wcount;
	
	always @* begin
		next_wbusy  = reg_wbusy;
		next_wcount = reg_wcount;
				
		if ( cmd_valid && cmd_ready ) begin
			next_wbusy  = 1'b1;
			next_wcount = cmd_len;
		end
		
		if ( m_axi4_wvalid && m_axi4_wready ) begin
			next_wcount = next_wcount - 1'b1;
		end		
		
		if ( m_axi4_wvalid && m_axi4_wready && m_axi4_wlast ) begin
			next_wbusy = 1'b0;
		end
	end
	
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_wbusy  <= 1'b0;
			reg_wcount <= {AXI4_LEN_WIDTH{1'bx}};
		end
		else begin
			reg_wbusy  <= next_wbusy;
			reg_wcount <= next_wcount;
		end
	end
	
	assign cmd_ready      = !reg_wbusy;	// || (m_axi4_wvalid && m_axi4_wlast && m_axi4_wready);
	
	assign m_axi4_wstrb   = {AXI4_STRB_WIDTH{1'b1}};
	assign m_axi4_wdata   = s_axi4s_tdata;
	assign m_axi4_wlast   = (reg_wbusy && reg_wcount == 0) || (!reg_wbusy && cmd_len == 0);
	assign m_axi4_wvalid  = (reg_wbusy || cmd_valid) && s_axi4s_tvalid;

	assign m_axi4_bready  = 1'b1;
	
	assign s_axi4s_tready = (reg_wbusy || cmd_valid) && m_axi4_wready;
	
	assign busy = cmd_busy || reg_wbusy;
	
endmodule


`default_nettype wire


// end of file
