// ---------------------------------------------------------------------------
//  AXI4 から Read して AXI4Streamにするコア
//      受付コマンド数などは AXI interconnect などで制約できるので
//    コアはシンプルな作りとする
//
//                                      Copyright (C) 2015 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly_vdma_axi4_to_axi4s_core
		#(
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
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
			input	wire	[AXI4_LEN_WIDTH-1:0]	param_arlen,
			
			// status
			output	wire	[AXI4_ADDR_WIDTH-1:0]	monitor_addr,
			output	wire	[STRIDE_WIDTH-1:0]		monitor_stride,
			output	wire	[H_WIDTH-1:0]			monitor_width,
			output	wire	[V_WIDTH-1:0]			monitor_height,
			output	wire	[AXI4_LEN_WIDTH-1:0]	monitor_arlen,
			
			// master AXI4 (read)
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_arid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_araddr,
			output	wire	[1:0]					m_axi4_arburst,
			output	wire	[3:0]					m_axi4_arcache,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_arlen,
			output	wire	[0:0]					m_axi4_arlock,
			output	wire	[2:0]					m_axi4_arprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_arqos,
			output	wire	[3:0]					m_axi4_arregion,
			output	wire	[2:0]					m_axi4_arsize,
			output	wire							m_axi4_arvalid,
			input	wire							m_axi4_arready,
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_rid,
			input	wire	[1:0]					m_axi4_rresp,
			input	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_rdata,
			input	wire							m_axi4_rlast,
			input	wire							m_axi4_rvalid,
			output	wire							m_axi4_rready,
			
			// master AXI4-Stream (output)
			output	wire	[AXI4S_USER_WIDTH-1:0]	m_axi4s_tuser,
			output	wire							m_axi4s_tlast,
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	// 状態管理
	reg								reg_busy;
	
	// シャドーレジスタ
	reg		[INDEX_WIDTH-1:0]		reg_index;			// この変化でホストは受付確認
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_param_addr;
	reg		[STRIDE_WIDTH-1:0]		reg_param_stride;
	reg		[H_WIDTH-1:0]			reg_param_width;
	reg		[V_WIDTH-1:0]			reg_param_height;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_param_arlen;
	
	// arチャネル制御変数
	reg								reg_arbusy;
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_addr_base;
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_araddr;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_arlen; 
	reg								reg_arvalid;
	reg		[H_WIDTH-1:0]			reg_arhcnt;
	reg								reg_arhlast;
	reg		[V_WIDTH-1:0]			reg_arvcnt;
	reg								reg_arvlast;

	wire	[H_WIDTH:0]				decrement_arhcnt = (reg_arhcnt - reg_param_arlen - 1'b1);
	
	wire	[AXI4_LEN_WIDTH-1:0]	init_arlen   = reg_param_arlen;		// reg_param_arlen < reg_param_width-1 ? reg_param_arlen : reg_param_width-1;
	wire	[AXI4_LEN_WIDTH-1:0]	next_arlen   = decrement_arhcnt[H_WIDTH] ? (reg_arhcnt - 1'b1) : reg_param_arlen;
	
	wire	[H_WIDTH-1:0]			init_arhcnt  = (reg_param_width - 1'b1) - reg_param_arlen;
	wire							init_arhlast = 1'b0; // (reg_param_width - 1'b1) <= reg_param_arlen;
	wire	[H_WIDTH-1:0]			next_arhcnt  = decrement_arhcnt[H_WIDTH-1:0];
	wire							next_arhlast = decrement_arhcnt[H_WIDTH] || (decrement_arhcnt == 0);	// borrow or zero
	
	wire	[V_WIDTH-1:0]			init_arvcnt  = (reg_param_height - 1'b1);
	wire							init_arvlast = (init_arvcnt == 0);
	wire	[V_WIDTH-1:0]			next_arvcnt  = (reg_arvcnt - 1'b1);
	wire							next_arvlast = (next_arvcnt == 0);

	
	// rチャネル制御変数
	reg								reg_rbusy;
	reg								reg_rfs;	// frame start
	reg								reg_rfe;	// frame end
	reg								reg_rle;	// line end
	reg		[H_WIDTH-1:0]			reg_rhcnt;
	reg								reg_rhlast;
	reg		[V_WIDTH-1:0]			reg_rvcnt;
	reg								reg_rvlast;

	wire	[H_WIDTH-1:0]			init_rhcnt  = (reg_param_width  - 1'b1);
	wire							init_rhlast = (init_rhcnt == 0);
	wire	[H_WIDTH-1:0]			next_rhcnt  = (reg_rhcnt - 1'b1);
	wire							next_rhlast = (next_rhcnt == 0);

	wire	[V_WIDTH-1:0]			init_rvcnt  = (reg_param_height - 1'b1);
	wire							init_rvlast = (init_rvcnt == 0);
	wire	[V_WIDTH-1:0]			next_rvcnt  = (reg_rvcnt - 1'b1);
	wire							next_rvlast = (next_rvcnt == 0);
		
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_busy         <= 1'b0;
			reg_index        <= {INDEX_WIDTH{1'b0}};
			
			reg_param_addr   <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_param_stride <= {STRIDE_WIDTH{1'bx}};
			reg_param_width  <= {H_WIDTH{1'bx}};
			reg_param_height <= {V_WIDTH{1'bx}};
			reg_param_arlen  <= {AXI4_LEN_WIDTH{1'bx}};
			
			reg_arbusy       <= 1'b0;
			reg_addr_base    <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_araddr       <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_arlen        <= {AXI4_LEN_WIDTH{1'bx}};
			reg_arvalid      <= 1'b0;
			reg_arhcnt       <= {H_WIDTH{1'bx}};
			reg_arhlast      <= 1'bx;
			reg_arvcnt       <= {V_WIDTH{1'bx}};
			reg_arvlast      <= 1'bx;
			
			
			reg_rbusy        <= 1'b0;
			reg_rfs          <= 1'bx;
			reg_rfe          <= 1'bx;
			reg_rle          <= 1'bx;
			reg_rhcnt        <= {H_WIDTH{1'bx}};
			reg_rhlast       <= 1'bx;
			reg_rvcnt        <= {V_WIDTH{1'bx}};
			reg_rvlast       <= 1'bx;
		end
		else begin
			// enable
			if ( !reg_busy ) begin
				if ( ctl_enable ) begin
					reg_busy         <= 1'b1;
					reg_arbusy       <= 1'b1;
					reg_index        <= reg_index + 1'b1;
					
					if ( ctl_update ) begin
						reg_param_addr   <= param_addr;
						reg_param_stride <= param_stride;
						reg_param_width  <= param_width;
						reg_param_height <= param_height;
						reg_param_arlen  <= param_arlen;
					end
				end
			end
			else begin
				if ( !reg_arbusy && !reg_rbusy ) begin
					reg_busy <= 1'b0;
				end
			end
			
			// arチャネル制御
			if ( reg_arbusy ) begin
				if ( !reg_arvalid ) begin
					// frame start
					reg_addr_base <= reg_param_addr + reg_param_stride;
					reg_araddr    <= reg_param_addr;
					reg_arlen     <= init_arlen;
					reg_arvalid   <= 1'b1;
					
					reg_arhcnt    <= init_arhcnt;
					reg_arhlast   <= init_arhlast;
					reg_arvcnt    <= init_arvcnt;
					reg_arvlast   <= init_arvlast;
					
					reg_rbusy     <= 1'b1;
					reg_rfs       <= 1'b1;
					reg_rfe       <= 1'b0;
					reg_rle       <= 1'b0;
					reg_rhcnt     <= init_rhcnt;
					reg_rhlast    <= init_rhlast;
					reg_rvcnt     <= init_rvcnt;
					reg_rvlast    <= init_rvlast;
				end
				else begin
					if ( m_axi4_arready ) begin
						reg_araddr  <= reg_araddr + ((reg_param_arlen+1'b1) << 2);
						reg_arlen   <= next_arlen;
						reg_arhcnt  <= next_arhcnt;
						reg_arhlast <= next_arhlast;
						
						if ( reg_arhlast ) begin
							// line end
							reg_arlen     <= init_arlen;
							reg_arhcnt    <= init_arhcnt;
							reg_arhlast   <= init_arhlast;
							reg_arvcnt    <= next_arvcnt;
							reg_arvlast   <= next_arvlast;
							reg_araddr    <= reg_addr_base;
							reg_addr_base <= reg_addr_base + reg_param_stride;
							
							if ( reg_arvlast ) begin
								// frame end
								reg_arbusy    <= 1'b0;
								reg_arvalid   <= 1'b0;
							end
						end
					end
				end
			end
			
			// rチャネル制御
			if ( m_axi4_rvalid && m_axi4_rready ) begin
				reg_rfs <= 1'b0;
				reg_rfe <= (next_rhcnt == 0) && (reg_rvcnt == 0);
				reg_rle <= (next_rhcnt == 0);
				
				reg_rhcnt  <= next_rhcnt;
				reg_rhlast <= next_rhlast;
				if ( reg_rhlast ) begin
					reg_rhcnt  <= init_rhcnt;
					reg_rhlast <= init_rhlast;
					reg_rvcnt  <= next_rvcnt;
					reg_rvlast <= next_rvlast;
					if ( reg_rvlast ) begin
						reg_rbusy <= 1'b0;
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
	assign monitor_arlen   = reg_param_arlen;
	
	assign m_axi4_arid     = {AXI4_ID_WIDTH{1'b0}};
	assign m_axi4_araddr   = reg_araddr;
	assign m_axi4_arburst  = 2'b01;					// INCR
	assign m_axi4_arcache  = 4'b0001;				// Bufferable
	assign m_axi4_arlen    = reg_arlen;	// reg_param_arlen;
	assign m_axi4_arlock   = 1'b0;					// Normal access
	assign m_axi4_arprot   = 3'b000;
	assign m_axi4_arqos    = {AXI4_QOS_WIDTH{1'b0}};
	assign m_axi4_arregion = 4'd0;
	assign m_axi4_arsize   = AXI4_DATA_SIZE;
	assign m_axi4_arvalid  = reg_arvalid;
	assign m_axi4_rready   = m_axi4s_tready;
	
	assign m_axi4s_tuser   = {reg_rfe, reg_rfs};	// FrameEnd はおまけ
	assign m_axi4s_tlast   = reg_rle;
	assign m_axi4s_tdata   = m_axi4_rdata;
	assign m_axi4s_tvalid  = m_axi4_rvalid;
	
endmodule


`default_nettype wire


// end of file
