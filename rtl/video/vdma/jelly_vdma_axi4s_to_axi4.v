// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns/1ps
`default_nettype none



module jelly_vdma_axi4s_to_axi4
		#(
			parameter	CORE_ID          = 32'habcd_0000,
			parameter	CORE_VERSION     = 32'h0000_0000,
			
			parameter	ASYNC            = 0,
			parameter	FIFO_PTR_WIDTH   = 0,
			
			parameter	PIXEL_SIZE       = 2,	// 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
			
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
			parameter	AXI4_STRB_WIDTH  = (1 << AXI4_DATA_SIZE),
			parameter	AXI4_LEN_WIDTH   = 8,
			parameter	AXI4_QOS_WIDTH   = 4,
			parameter	AXI4_AWID        = {AXI4_ID_WIDTH{1'b0}},
			parameter	AXI4_AWSIZE      = AXI4_DATA_SIZE,
			parameter	AXI4_AWBURST     = 2'b01,
			parameter	AXI4_AWLOCK      = 1'b0,
			parameter	AXI4_AWCACHE     = 4'b0001,
			parameter	AXI4_AWPROT      = 3'b000,
			parameter	AXI4_AWQOS       = 0,
			parameter	AXI4_AWREGION    = 4'b0000,
			
			parameter	AXI4S_DATA_SIZE  = 2,	// 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
			parameter	AXI4S_DATA_WIDTH = (8 << AXI4S_DATA_SIZE),
			parameter	AXI4S_USER_WIDTH = 1,
			
			parameter	AXI4_AW_REGS     = 1,
			parameter	AXI4_W_REGS      = 1,
			parameter	AXI4S_REGS       = 1,
			
			parameter	INDEX_WIDTH      = 8,
			parameter	STRIDE_WIDTH     = 14,
			parameter	H_WIDTH          = 12,
			parameter	V_WIDTH          = 12,
			parameter	SIZE_WIDTH       = H_WIDTH + V_WIDTH,
			
			parameter	WB_ADR_WIDTH     = 8,
			parameter	WB_DAT_WIDTH     = 32,
			parameter	WB_SEL_WIDTH     = (WB_DAT_WIDTH / 8),
			
			parameter	INIT_CTL_CONTROL  = 3'b000,
			parameter	INIT_PARAM_ADDR   = 32'h0000_0000,
			parameter	INIT_PARAM_STRIDE = 4096,
			parameter	INIT_PARAM_WIDTH  = 640,
			parameter	INIT_PARAM_HEIGHT = 480,
			parameter	INIT_PARAM_SIZE   = INIT_PARAM_WIDTH * INIT_PARAM_HEIGHT,
			parameter	INIT_PARAM_AWLEN  = 7
		)
		(
			// master AXI4 (write)
			input	wire							m_axi4_aresetn,
			input	wire							m_axi4_aclk,
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_awid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_awaddr,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_awlen,
			output	wire	[2:0]					m_axi4_awsize,
			output	wire	[1:0]					m_axi4_awburst,
			output	wire	[0:0]					m_axi4_awlock,
			output	wire	[3:0]					m_axi4_awcache,
			output	wire	[2:0]					m_axi4_awprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_awqos,
			output	wire	[3:0]					m_axi4_awregion,
			output	wire							m_axi4_awvalid,
			input	wire							m_axi4_awready,
			output	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_wdata,
			output	wire	[AXI4_STRB_WIDTH-1:0]	m_axi4_wstrb,
			output	wire							m_axi4_wlast,
			output	wire							m_axi4_wvalid,
			input	wire							m_axi4_wready,
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_bid,
			input	wire	[1:0]					m_axi4_bresp,
			input	wire							m_axi4_bvalid,
			output	wire							m_axi4_bready,
			
			// slave AXI4-Stream (input)
			input	wire							s_axi4s_aresetn,
			input	wire							s_axi4s_aclk,
			input	wire	[AXI4S_DATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire							s_axi4s_tlast,
			input	wire	[AXI4S_USER_WIDTH-1:0]	s_axi4s_tuser,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready,
			
			// WISHBONE (register access)
			input	wire							s_wb_rst_i,
			input	wire							s_wb_clk_i,
			input	wire	[WB_ADR_WIDTH-1:0]		s_wb_adr_i,
			input	wire	[WB_DAT_WIDTH-1:0]		s_wb_dat_i,
			output	wire	[WB_DAT_WIDTH-1:0]		s_wb_dat_o,
			input	wire							s_wb_we_i,
			input	wire	[WB_SEL_WIDTH-1:0]		s_wb_sel_i,
			input	wire							s_wb_stb_i,
			output	wire							s_wb_ack_o,
			output	wire							out_irq
		);
	
	// address mask
	localparam	[AXI4_ADDR_WIDTH-1:0]	ADDR_MASK = ~((1 << AXI4_DATA_SIZE) - 1);
	
	
	// ---------------------------------
	//  Register
	// ---------------------------------
	
	// register address offset
	localparam	REGOFFSET_ID             = 32'h0000_0000 >> 2;
	localparam	REGOFFSET_VERSION        = 32'h0000_0004 >> 2;
	
	localparam	REGOFFSET_CTL_CONTROL    = 32'h0000_0010 >> 2;
	localparam	REGOFFSET_CTL_STATUS     = 32'h0000_0014 >> 2;
	localparam	REGOFFSET_CTL_INDEX      = 32'h0000_001c >> 2;
	
	localparam	REGOFFSET_PARAM_ADDR     = 32'h0000_0020 >> 2;
	localparam	REGOFFSET_PARAM_STRIDE   = 32'h0000_0024 >> 2;
	localparam	REGOFFSET_PARAM_WIDTH    = 32'h0000_0028 >> 2;
	localparam	REGOFFSET_PARAM_HEIGHT   = 32'h0000_002c >> 2;
	localparam	REGOFFSET_PARAM_SIZE     = 32'h0000_0030 >> 2;
	localparam	REGOFFSET_PARAM_AWLEN    = 32'h0000_003c >> 2;
	
	localparam	REGOFFSET_MONITOR_ADDR   = 32'h0000_0040 >> 2;
	localparam	REGOFFSET_MONITOR_STRIDE = 32'h0000_0044 >> 2;
	localparam	REGOFFSET_MONITOR_WIDTH  = 32'h0000_0048 >> 2;
	localparam	REGOFFSET_MONITOR_HEIGHT = 32'h0000_004c >> 2;
	localparam	REGOFFSET_MONITOR_SIZE   = 32'h0000_0050 >> 2;
	localparam	REGOFFSET_MONITOR_AWLEN  = 32'h0000_005c >> 2;
	
	// registers
	reg		[2:0]					reg_ctl_control;
	wire	[0:0]					sig_ctl_status;
	wire	[INDEX_WIDTH-1:0]		sig_ctl_index;
	
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_param_addr;
	reg		[STRIDE_WIDTH-1:0]		reg_param_stride;
	reg		[H_WIDTH-1:0]			reg_param_width;
	reg		[V_WIDTH-1:0]			reg_param_height;
	reg		[SIZE_WIDTH-1:0]		reg_param_size;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_param_awlen;
	
	wire	[AXI4_ADDR_WIDTH-1:0]	sig_monitor_addr;
	wire	[STRIDE_WIDTH-1:0]		sig_monitor_stride;
	wire	[H_WIDTH-1:0]			sig_monitor_width;
	wire	[V_WIDTH-1:0]			sig_monitor_height;
	wire	[SIZE_WIDTH-1:0]		sig_monitor_size;
	wire	[AXI4_LEN_WIDTH-1:0]	sig_monitor_awlen;
	
	reg		[2:0]					reg_prev_index;
	
	reg								reg_irq;
	
	always @(posedge s_wb_clk_i ) begin
		if ( s_wb_rst_i ) begin
			reg_ctl_control  <= INIT_CTL_CONTROL;
			reg_param_addr   <= INIT_PARAM_ADDR   & ADDR_MASK;
			reg_param_stride <= INIT_PARAM_STRIDE & ADDR_MASK;
			reg_param_width  <= INIT_PARAM_WIDTH;
			reg_param_height <= INIT_PARAM_HEIGHT;
			reg_param_size   <= INIT_PARAM_SIZE;
			reg_param_awlen  <= INIT_PARAM_AWLEN;
			reg_prev_index   <= 3'b000;
			reg_irq          <= 1'b0;
		end
		else if ( s_wb_stb_i && s_wb_we_i ) begin
			// register write
			case ( s_wb_adr_i )
			REGOFFSET_CTL_CONTROL:	reg_ctl_control  <= s_wb_dat_i[2:0];
			REGOFFSET_PARAM_ADDR:	reg_param_addr   <= s_wb_dat_i[AXI4_ADDR_WIDTH-1:0] & ADDR_MASK;
			REGOFFSET_PARAM_STRIDE:	reg_param_stride <= s_wb_dat_i[STRIDE_WIDTH-1:0]    & ADDR_MASK;
			REGOFFSET_PARAM_WIDTH:	reg_param_width  <= s_wb_dat_i[H_WIDTH-1:0];
			REGOFFSET_PARAM_HEIGHT:	reg_param_height <= s_wb_dat_i[V_WIDTH-1:0];
			REGOFFSET_PARAM_SIZE:	reg_param_size   <= s_wb_dat_i[SIZE_WIDTH-1:0];
			REGOFFSET_PARAM_AWLEN:	reg_param_awlen  <= s_wb_dat_i[AXI4_LEN_WIDTH-1:0];
			endcase
			
			// update
			reg_irq           <= 1'b0;
			reg_prev_index[0] <= sig_ctl_index[0];
			reg_prev_index[1] <= reg_prev_index[0];
			reg_prev_index[2] <= reg_prev_index[1];
			if ( reg_prev_index[2] != reg_prev_index[1] ) begin
				// IRQ puls
				reg_irq <= 1'b1;
				
				// update flag auto clear
				reg_ctl_control[1] <= 1'b0;
				
				// auto stop
				if ( reg_ctl_control[2] ) begin
					reg_ctl_control[0] <= 1'b0;
					reg_ctl_control[2] <= 1'b0;
				end
			end
		end
	end
	
	// register read
	assign s_wb_dat_o = (s_wb_adr_i == REGOFFSET_ID)             ? CORE_ID            :
	                    (s_wb_adr_i == REGOFFSET_VERSION)        ? CORE_VERSION       :
	                    (s_wb_adr_i == REGOFFSET_CTL_CONTROL)    ? reg_ctl_control    :
	                    (s_wb_adr_i == REGOFFSET_CTL_STATUS)     ? sig_ctl_status     :
	                    (s_wb_adr_i == REGOFFSET_CTL_INDEX)      ? sig_ctl_index      :
	                    (s_wb_adr_i == REGOFFSET_PARAM_ADDR)     ? reg_param_addr     :
	                    (s_wb_adr_i == REGOFFSET_PARAM_STRIDE)   ? reg_param_stride   :
	                    (s_wb_adr_i == REGOFFSET_PARAM_WIDTH)    ? reg_param_width    :
	                    (s_wb_adr_i == REGOFFSET_PARAM_HEIGHT)   ? reg_param_height   :
	                    (s_wb_adr_i == REGOFFSET_PARAM_SIZE)     ? reg_param_size     :
	                    (s_wb_adr_i == REGOFFSET_PARAM_AWLEN)    ? reg_param_awlen    :
	                    (s_wb_adr_i == REGOFFSET_MONITOR_ADDR)   ? sig_monitor_addr   :
	                    (s_wb_adr_i == REGOFFSET_MONITOR_STRIDE) ? sig_monitor_stride :
	                    (s_wb_adr_i == REGOFFSET_MONITOR_WIDTH)  ? sig_monitor_width  :
	                    (s_wb_adr_i == REGOFFSET_MONITOR_HEIGHT) ? sig_monitor_height :
	                    (s_wb_adr_i == REGOFFSET_MONITOR_SIZE)   ? sig_monitor_size   :
	                    (s_wb_adr_i == REGOFFSET_MONITOR_AWLEN)  ? sig_monitor_awlen  :
	                    32'h0000_0000;
	
	assign s_wb_ack_o = s_wb_stb_i;
	
	assign out_irq    = reg_irq;
	
	
	// ---------------------------------
	//  Core
	// ---------------------------------
	
	jelly_vdma_axi4s_to_axi4_core
			#(
				.ASYNC				(ASYNC),
				.FIFO_PTR_WIDTH		(FIFO_PTR_WIDTH),
				.PIXEL_SIZE			(PIXEL_SIZE),
				.AXI4_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH	(AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE 	(AXI4_DATA_SIZE),
				.AXI4_DATA_WIDTH	(AXI4_DATA_WIDTH),
				.AXI4_STRB_WIDTH	(AXI4_STRB_WIDTH),
				.AXI4_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.AXI4_QOS_WIDTH		(AXI4_QOS_WIDTH),
				.AXI4_AWID			(AXI4_AWID),
				.AXI4_AWSIZE		(AXI4_AWSIZE),
				.AXI4_AWBURST		(AXI4_AWBURST),
				.AXI4_AWLOCK		(AXI4_AWLOCK),
				.AXI4_AWCACHE		(AXI4_AWCACHE),
				.AXI4_AWPROT		(AXI4_AWPROT),
				.AXI4_AWQOS			(AXI4_AWQOS),
				.AXI4_AWREGION		(AXI4_AWREGION),
				.AXI4S_DATA_SIZE	(AXI4S_DATA_SIZE),
				.AXI4S_DATA_WIDTH   (AXI4S_DATA_WIDTH),
				.AXI4S_USER_WIDTH   (AXI4S_USER_WIDTH),
				.AXI4_AW_REGS		(AXI4_AW_REGS),
				.AXI4_W_REGS		(AXI4_W_REGS),
				.AXI4S_REGS			(AXI4S_REGS),
				.STRIDE_WIDTH		(STRIDE_WIDTH),
				.INDEX_WIDTH		(INDEX_WIDTH),
				.H_WIDTH			(H_WIDTH),
				.V_WIDTH			(V_WIDTH),
				.SIZE_WIDTH			(SIZE_WIDTH)
			)
		i_vdma_axi4s_to_axi4_core
			(
				.ctl_enable			(reg_ctl_control[0]),
				.ctl_update			(reg_ctl_control[1]),
				.ctl_busy			(sig_ctl_status[0]),
				.ctl_index			(sig_ctl_index),
				
				.param_addr			(reg_param_addr),
				.param_stride		(reg_param_stride),
				.param_width		(reg_param_width),
				.param_height		(reg_param_height),
				.param_size			(reg_param_size),
				.param_awlen		(reg_param_awlen),
				
				.monitor_addr		(sig_monitor_addr),
				.monitor_stride		(sig_monitor_stride),
				.monitor_width		(sig_monitor_width),
				.monitor_height		(sig_monitor_height),
				.monitor_size		(sig_monitor_size),
				.monitor_awlen		(sig_monitor_awlen),
				
				.m_axi4_aresetn		(m_axi4_aresetn),
				.m_axi4_aclk		(m_axi4_aclk),
				.m_axi4_awid		(m_axi4_awid),
				.m_axi4_awaddr		(m_axi4_awaddr),
				.m_axi4_awburst		(m_axi4_awburst),
				.m_axi4_awcache		(m_axi4_awcache),
				.m_axi4_awlen		(m_axi4_awlen),
				.m_axi4_awlock		(m_axi4_awlock),
				.m_axi4_awprot		(m_axi4_awprot),
				.m_axi4_awqos		(m_axi4_awqos),
				.m_axi4_awregion	(m_axi4_awregion),
				.m_axi4_awsize		(m_axi4_awsize),
				.m_axi4_awvalid		(m_axi4_awvalid),
				.m_axi4_awready		(m_axi4_awready),
				.m_axi4_wstrb		(m_axi4_wstrb),
				.m_axi4_wdata		(m_axi4_wdata),
				.m_axi4_wlast		(m_axi4_wlast),
				.m_axi4_wvalid		(m_axi4_wvalid),
				.m_axi4_wready		(m_axi4_wready),
				.m_axi4_bid			(m_axi4_bid),
				.m_axi4_bresp		(m_axi4_bresp),
				.m_axi4_bvalid		(m_axi4_bvalid),
				.m_axi4_bready		(m_axi4_bready),
				
				.s_axi4s_aresetn	(s_axi4s_aresetn),
				.s_axi4s_aclk		(s_axi4s_aclk),
				.s_axi4s_tuser		(s_axi4s_tuser),
				.s_axi4s_tlast		(s_axi4s_tlast),
				.s_axi4s_tdata		(s_axi4s_tdata),
				.s_axi4s_tvalid		(s_axi4s_tvalid),
				.s_axi4s_tready		(s_axi4s_tready)
			);
	
endmodule


`default_nettype wire


// end of file
