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


module jelly_vdma_axi4s_to_axi4_core
		#(
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
			parameter	AXI4_STRB_WIDTH  = (1 << AXI4_DATA_SIZE),
			parameter	AXI4_LEN_WIDTH   = 8,
			parameter	AXI4_QOS_WIDTH   = 4,
			parameter	AXI4S_USER_WIDTH = 1,
			parameter	AXI4S_DATA_WIDTH = AXI4_DATA_WIDTH,
			parameter	STRIDE_WIDTH     = 14,
			parameter	INDEX_WIDTH      = 8,
			parameter	H_WIDTH          = 12,
			parameter	V_WIDTH          = 12
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			// control
			input	wire							ctl_enable,
			input	wire							ctl_update,
			output	wire							ctl_busy,
			output	wire	[INDEX_WIDTH-1:0]		ctl_index,
			
			// parameter
			input	wire	[AXI4_ADDR_WIDTH-1:0]	param_addr,
			input	wire	[STRIDE_WIDTH-1:0]		param_stride,
			input	wire	[H_WIDTH-1:0]			param_width,
			input	wire	[V_WIDTH-1:0]			param_height,
			input	wire	[AXI4_LEN_WIDTH-1:0]	param_awlen,
			
			// status
			output	wire	[AXI4_ADDR_WIDTH-1:0]	monitor_addr,
			output	wire	[STRIDE_WIDTH-1:0]		monitor_stride,
			output	wire	[H_WIDTH-1:0]			monitor_width,
			output	wire	[V_WIDTH-1:0]			monitor_height,
			output	wire	[AXI4_LEN_WIDTH-1:0]	monitor_awlen,
			
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
			
			// slave AXI4-Stream (output)
			input	wire	[AXI4S_USER_WIDTH-1:0]	s_axi4s_tuser,
			input	wire							s_axi4s_tlast,
			input	wire	[AXI4S_DATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready
		);
	
	// 状態管理
	reg								reg_busy;
	reg								reg_skip;
	
	// シャドーレジスタ
	reg		[INDEX_WIDTH-1:0]		reg_index;			// この変化でホストは受付確認
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_param_addr;
	reg		[STRIDE_WIDTH-1:0]		reg_param_stride;
	reg		[H_WIDTH-1:0]			reg_param_width;
	reg		[V_WIDTH-1:0]			reg_param_height;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_param_awlen;
	
	// arチャネル制御変数
	reg								reg_awbusy;
	reg								reg_awvalid;
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_addr_base;
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_awaddr;
	reg		[H_WIDTH-1:0]			reg_awhcnt;
	reg								reg_awhlast;
	reg		[V_WIDTH-1:0]			reg_awvcnt;
	reg								reg_awvlast;
	
	wire	[H_WIDTH:0]				decrement_awhcnt = (reg_awhcnt - reg_param_awlen - 1'b1);
	wire	[H_WIDTH-1:0]			init_awhcnt  = (reg_param_width - 1'b1) - reg_param_awlen;
	wire							init_awhlast = 1'b0; // (reg_param_width - 1'b1) <= reg_param_awlen;
	wire	[H_WIDTH-1:0]			next_awhcnt  = decrement_awhcnt[H_WIDTH-1:0];
	wire							next_awhlast = decrement_awhcnt[H_WIDTH] || (decrement_awhcnt == 0);	// borrow or zero
	
	wire	[V_WIDTH-1:0]			init_awvcnt  = (reg_param_height - 1'b1);
	wire							init_awvlast = (init_awvcnt == 0);
	wire	[V_WIDTH-1:0]			next_awvcnt  = (reg_awvcnt - 1'b1);
	wire							next_awvlast = (next_awvcnt == 0);
	
	
	// wチャネル制御変数
	reg								reg_wbusy;
	reg								reg_wlast;
	reg		[AXI4S_DATA_WIDTH-1:0]	reg_wdata;
	reg								reg_wvalid;
	
	reg		[AXI4_LEN_WIDTH-1:0]	reg_wlen;
	reg		[H_WIDTH-1:0]			reg_whcnt;
	reg								reg_whlast;
	reg		[V_WIDTH-1:0]			reg_wvcnt;
	reg								reg_wvlast;
	
	wire							init_wlast  = (reg_param_awlen == 0);
	wire							next_wlast  = ((reg_wlen - 1'b1) == 0) || (reg_param_awlen == 0);
	
	wire	[H_WIDTH:0]				decrement_whcnt = (reg_whcnt - reg_param_awlen - 1'b1);
	wire	[H_WIDTH-1:0]			init_whcnt  = (reg_param_width - 1'b1) - reg_param_awlen;
	wire							init_whlast = 1'b0; // (reg_param_width - 1'b1) <= reg_param_awlen;
	wire	[H_WIDTH-1:0]			next_whcnt  = decrement_whcnt[H_WIDTH-1:0];
	wire							next_whlast = decrement_whcnt[H_WIDTH] || (decrement_whcnt == 0);	// borrow or zero
	
	wire	[V_WIDTH-1:0]			init_wvcnt  = (reg_param_height - 1'b1);
	wire							init_wvlast = (init_wvcnt == 0);
	wire	[V_WIDTH-1:0]			next_wvcnt  = (reg_wvcnt - 1'b1);
	wire							next_wvlast = (next_wvcnt == 0);

	wire							next_wflast = (next_wlast && reg_wvlast && (reg_param_awlen == 0 ? next_whlast : reg_whlast));
	
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_busy         <= 1'b0;
			reg_skip         <= 1'b1;
			reg_index        <= {INDEX_WIDTH{1'b0}};
			
			reg_param_addr   <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_param_stride <= {STRIDE_WIDTH{1'bx}};
			reg_param_width  <= {H_WIDTH{1'bx}};
			reg_param_height <= {V_WIDTH{1'bx}};
			reg_param_awlen  <= {AXI4_LEN_WIDTH{1'bx}};
			
			reg_awbusy       <= 1'b0;
			reg_awvalid      <= 1'b0;
			reg_addr_base    <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_awaddr       <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_awhcnt       <= {H_WIDTH{1'bx}};
			reg_awhlast      <= 1'bx;
			reg_awvcnt       <= {V_WIDTH{1'bx}};
			reg_awvlast      <= 1'bx;
			
			reg_wbusy        <= 1'b0;
			reg_wlast        <= 1'bx;
			reg_wdata        <= {AXI4S_DATA_WIDTH{1'bx}};
			reg_wvalid       <= 1'b0;
			reg_wlen         <= {AXI4_LEN_WIDTH{1'bx}};
			reg_whcnt        <= {H_WIDTH{1'bx}};
			reg_whlast       <= 1'bx;
			reg_wvcnt        <= {V_WIDTH{1'bx}};
			reg_wvlast       <= 1'bx;
		end
		else begin
			if ( m_axi4_wready ) begin
				reg_wvalid <= 1'b0;
			end
			
			// enable
			if ( !reg_busy || (!reg_skip && !reg_awbusy && !reg_wbusy) ) begin
				if ( ctl_enable ) begin
					reg_busy     <= 1'b1;
					reg_skip     <= 1'b1;
					reg_index    <= reg_index + 1'b1;
					if ( ctl_update ) begin
						reg_param_addr   <= param_addr;
						reg_param_stride <= param_stride;
						reg_param_width  <= param_width;
						reg_param_height <= param_height;
						reg_param_awlen  <= param_awlen;
					end
				end
				else begin
					reg_busy <= 1'b0;
					reg_skip <= 1'b1;
				end
			end
			
			// wait frame start
			if ( reg_busy && reg_skip ) begin
				if ( s_axi4s_tvalid && s_axi4s_tuser ) begin 
					// frame start
					reg_skip      <= 1'b0;
					
					// aw start
					reg_awbusy    <= 1'b1;
					reg_addr_base <= reg_param_addr + reg_param_stride;
					reg_awaddr    <= reg_param_addr;
					reg_awvalid   <= 1'b1;
					
					reg_awhcnt    <= init_awhcnt;
					reg_awhlast   <= init_awhlast;
					reg_awvcnt    <= init_awvcnt;
					reg_awvlast   <= init_awvlast;
					
					// w start
					reg_wbusy     <= 1'b1;
					reg_wlen      <= reg_param_awlen;
					reg_wlast     <= (reg_param_awlen == 0);
					reg_wdata     <= s_axi4s_tdata;
					reg_wvalid    <= s_axi4s_tvalid;
					
					reg_whcnt     <= init_whcnt;
					reg_whlast    <= init_whlast;
					reg_wvcnt     <= init_wvcnt;
					reg_wvlast    <= init_wvlast;
				end
			end
			
			// awチャネル制御
			if ( reg_awbusy ) begin
				if ( m_axi4_awready ) begin
					reg_awaddr  <= reg_awaddr + ((reg_param_awlen+1'b1) << 2);
					reg_awhcnt  <= next_awhcnt;
					reg_awhlast <= next_awhlast;
					
					if ( reg_awhlast ) begin
						// line end
						reg_awhcnt    <= init_awhcnt;
						reg_awhlast   <= init_awhlast;
						reg_awvcnt    <= next_awvcnt;
						reg_awvlast   <= next_awvlast;
						reg_awaddr    <= reg_addr_base;
						reg_addr_base <= reg_addr_base + reg_param_stride;
						
						if ( reg_awvlast ) begin
							// frame end
							reg_awbusy    <= 1'b0;
							reg_awvalid   <= 1'b0;
						end
					end
				end
			end
			
			// wチャネル制御
			if ( reg_wbusy ) begin
				if ( !m_axi4_wvalid || m_axi4_wready ) begin
					reg_wvalid <= s_axi4s_tvalid;
					
					if ( s_axi4s_tvalid ) begin
						reg_wlast  <= next_wlast;
						reg_wdata  <= s_axi4s_tdata;
						
						reg_wlen      <= reg_wlen - 1'b1;
						if ( reg_wlen == 0 ) begin
							reg_wlen      <= reg_param_awlen;
						end
						
						if ( reg_wlast ) begin
							reg_whcnt  <= next_whcnt;
							reg_whlast <= next_whlast;
							if ( reg_whlast ) begin
								reg_whcnt  <= init_whcnt;
								reg_whlast <= init_whlast;
								reg_wvcnt  <= next_wvcnt;
								reg_wvlast <= next_wvlast;
							end
						end
						
						if ( next_wflast ) begin
							reg_wbusy  <= 1'b0;
						end
					end
				end
			end
		end
	end
	
	assign ctl_busy        = reg_busy;
	assign ctl_index       = reg_index;
	
	assign monitor_addr    = reg_param_addr;
	assign monitor_stride  = reg_param_stride;
	assign monitor_width   = reg_param_width;
	assign monitor_height  = reg_param_height;
	assign monitor_awlen   = reg_param_awlen;
	
	assign m_axi4_awid     = {AXI4_ID_WIDTH{1'b0}};
	assign m_axi4_awaddr   = reg_awaddr;
	assign m_axi4_awburst  = 2'b01;					// INCR
	assign m_axi4_awcache  = 4'b0001;				// Bufferable
	assign m_axi4_awlen    = reg_param_awlen;
	assign m_axi4_awlock   = 1'b0;					// Normal access
	assign m_axi4_awprot   = 3'b000;
	assign m_axi4_awqos    = {AXI4_QOS_WIDTH{1'b0}};
	assign m_axi4_awregion = 4'd0;
	assign m_axi4_awsize   = AXI4_DATA_SIZE;
	assign m_axi4_awvalid  = reg_awvalid;
	
	assign m_axi4_wstrb    = {AXI4_STRB_WIDTH{1'b1}};
	assign m_axi4_wdata    = reg_wdata;
	assign m_axi4_wlast    = reg_wlast;
	assign m_axi4_wvalid   = reg_wvalid;
	assign m_axi4_bready   = 1'b1;
	
	assign s_axi4s_tready  = (reg_skip || (reg_wbusy && (!m_axi4_wvalid || m_axi4_wready)));
	
endmodule


`default_nettype wire


// end of file
