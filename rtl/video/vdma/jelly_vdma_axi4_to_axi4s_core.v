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
			parameter	V_WIDTH          = 12,
			parameter	SIZE_WIDTH       = 24
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
			input	wire	[SIZE_WIDTH-1:0]		param_size,
			input	wire	[AXI4_LEN_WIDTH-1:0]	param_arlen,
			
			// status
			output	wire	[AXI4_ADDR_WIDTH-1:0]	monitor_addr,
			output	wire	[STRIDE_WIDTH-1:0]		monitor_stride,
			output	wire	[H_WIDTH-1:0]			monitor_width,
			output	wire	[V_WIDTH-1:0]			monitor_height,
			output	wire	[SIZE_WIDTH-1:0]		monitor_size,
			output	wire	[AXI4_LEN_WIDTH-1:0]	monitor_arlen,
			
			// master AXI4 (read)
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_arid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_araddr,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_arlen,
			output	wire	[2:0]					m_axi4_arsize,
			output	wire	[1:0]					m_axi4_arburst,
			output	wire	[0:0]					m_axi4_arlock,
			output	wire	[3:0]					m_axi4_arcache,
			output	wire	[2:0]					m_axi4_arprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_arqos,
			output	wire	[3:0]					m_axi4_arregion,
			output	wire							m_axi4_arvalid,
			input	wire							m_axi4_arready,
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_rid,
			input	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_rdata,
			input	wire	[1:0]					m_axi4_rresp,
			input	wire							m_axi4_rlast,
			input	wire							m_axi4_rvalid,
			output	wire							m_axi4_rready,
			
			// master AXI4-Stream (output)
			output	wire	[AXI4S_DATA_WIDTH-1:0]	m_axi4s_tdata,
			output	wire							m_axi4s_tlast,
			output	wire	[AXI4S_USER_WIDTH-1:0]	m_axi4s_tuser,
			output	wire							m_axi4s_tvalid,
			input	wire							m_axi4s_tready
		);
	
	// 状態管理
	reg								reg_busy;
	reg		[INDEX_WIDTH-1:0]		reg_index;			// この変化でホストは受付確認
	
	wire							sig_arbusy;
	reg								reg_arenable;
	reg		[SIZE_WIDTH-1:0]		reg_arhcount;
	reg		[V_WIDTH-1:0]			reg_arvcount;
	reg								reg_arbusy;
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_araddr;
	
	reg								reg_rbusy;
	reg		[SIZE_WIDTH-1:0]		reg_rcount;
	reg								reg_tuser;			// frame start
	
	wire							sig_rcount_up   = (m_axi4_arvalid && m_axi4_arready);
	wire							sig_rcount_down = (m_axi4_rlast && m_axi4_rvalid && m_axi4_rready);
	wire							next_rcount     = reg_rcount + sig_rcount_up - sig_rcount_down;
	
	// シャドーレジスタ
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_param_addr;
	reg		[STRIDE_WIDTH-1:0]		reg_param_stride;
	reg		[H_WIDTH-1:0]			reg_param_width;
	reg		[V_WIDTH-1:0]			reg_param_height;
	reg		[SIZE_WIDTH-1:0]		reg_param_size;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_param_arlen;
		
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_busy         <= 1'b0;
			reg_index        <= {INDEX_WIDTH{1'b0}};
			
			reg_arenable     <= 1'b0;
			reg_arhcount     <= {SIZE_WIDTH{1'bx}};
			reg_arvcount     <= {V_WIDTH{1'bx}};
			reg_arbusy       <= 1'b0;
			reg_araddr       <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_rbusy        <= 1'b0;
			reg_rcount       <= {SIZE_WIDTH{1'b0}};
			reg_tuser        <= 1'bx;
			
			reg_param_addr   <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_param_stride <= {STRIDE_WIDTH{1'bx}};
			reg_param_width  <= {H_WIDTH{1'bx}};
			reg_param_height <= {V_WIDTH{1'bx}};
			reg_param_size   <= {SIZE_WIDTH{1'bx}};
			reg_param_arlen  <= {AXI4_LEN_WIDTH{1'bx}};
		end
		else begin
			reg_arenable <= 1'b0;
			
			if ( !reg_arenable && !reg_arbusy && !sig_arbusy && !reg_rbusy ) begin
				reg_busy <= 1'b0;
			end
			
			if ( m_axi4s_tvalid && m_axi4s_tready ) begin
				reg_tuser  <= 1'b0;
			end
			
			if ( !reg_busy ) begin
				if ( ctl_enable ) begin
					reg_busy         <= 1'b1;
					reg_index        <= reg_index + 1'b1;
					
					reg_arbusy       <= 1'b1;
					reg_arenable     <= 1'b1;
					reg_tuser        <= 1'b1;
					reg_rbusy        <= 1'b0;
					reg_rcount       <= 0;
					
					if ( ctl_update ) begin
						reg_param_addr   <= param_addr;
						reg_param_stride <= param_stride;
						reg_param_width  <= param_width;
						reg_param_height <= param_height;
						reg_param_size   <= param_size;
						reg_param_arlen  <= param_arlen;
						
						reg_arhcount <= param_width;
						reg_arvcount <= param_height;
						if ( (param_size != 0) && (param_width << AXI4_DATA_SIZE) == param_stride ) begin
							reg_arhcount <= param_size;
							reg_arvcount <= 1;
						end
						reg_araddr <= param_addr;
					end
					else begin
						reg_arhcount <= reg_param_width;
						reg_arvcount <= reg_param_height;
						if ( (reg_param_size != 0) && (reg_param_width << AXI4_DATA_SIZE) == reg_param_stride ) begin
							reg_arhcount <= reg_param_size;
							reg_arvcount <= 1;
						end
						reg_araddr <= reg_param_addr;
					end
				end
			end
			else begin
				if ( reg_arbusy && !reg_arenable && !sig_arbusy ) begin
					if ( (reg_arvcount - 1'b1) == 0 ) begin
						// end
						reg_arbusy   <= 1'b0;
						reg_araddr   <= {AXI4_ADDR_WIDTH{1'bx}};
						reg_arvcount <= {V_WIDTH{1'bx}};
					end
					else begin
						// next line
						reg_arenable <= 1'b1;
						reg_araddr   <= reg_araddr + reg_param_stride;
						reg_arvcount <= reg_arvcount - 1'b1;
					end
				end
			end
			
			reg_rbusy  <= (next_rcount != 0);
			reg_rcount <= next_rcount;
		end
	end
	
	assign ctl_busy      = reg_busy;
	assign ctl_index     = reg_index;
	
	assign monitor_addr   = reg_param_addr;
	assign monitor_stride = reg_param_stride;
	assign monitor_width  = reg_param_width;
	assign monitor_height = reg_param_height;
	assign monitor_size   = reg_param_size;
	assign monitor_arlen  = reg_param_arlen;
	
	assign m_axi4s_tuser = reg_tuser;
	
	
	// DMA
	wire	[SIZE_WIDTH-1:0]		dma_unit = reg_param_width;
	
	jelly_axi4_dma_reader
			#(
				.AXI4_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH	(AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE		(AXI4_DATA_SIZE),
				.AXI4_DATA_WIDTH	(AXI4_DATA_WIDTH),
				.AXI4_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.AXI4_QOS_WIDTH		(AXI4_QOS_WIDTH),
				.AXI4S_DATA_WIDTH	(AXI4S_DATA_WIDTH),
				.COUNT_WIDTH		(SIZE_WIDTH)
			)
		i_axi4_dma_reader
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.enable				(reg_arenable),
				.busy				(sig_arbusy),
				
				.param_addr			(reg_araddr),
				.param_count		(reg_arhcount),
				.param_maxlen		(reg_param_arlen),
				.param_last_end		(1'b1),
				.param_last_through	(1'b0),
				.param_last_unit	(1'b1),
				.param_unit			(dma_unit),
				
				.m_axi4_arid		(m_axi4_arid),
				.m_axi4_araddr		(m_axi4_araddr),
				.m_axi4_arlen		(m_axi4_arlen),
				.m_axi4_arsize		(m_axi4_arsize),
				.m_axi4_arburst		(m_axi4_arburst),
				.m_axi4_arlock		(m_axi4_arlock),
				.m_axi4_arcache		(m_axi4_arcache),
				.m_axi4_arprot		(m_axi4_arprot),
				.m_axi4_arqos		(m_axi4_arqos),
				.m_axi4_arregion	(m_axi4_arregion),
				.m_axi4_arvalid		(m_axi4_arvalid),
				.m_axi4_arready		(m_axi4_arready),
				.m_axi4_rid			(m_axi4_rid),
				.m_axi4_rdata		(m_axi4_rdata),
				.m_axi4_rresp		(m_axi4_rresp),
				.m_axi4_rlast		(m_axi4_rlast),
				.m_axi4_rvalid		(m_axi4_rvalid),
				.m_axi4_rready		(m_axi4_rready),
				
				.m_axi4s_tdata		(m_axi4s_tdata),
				.m_axi4s_tlast		(m_axi4s_tlast),
				.m_axi4s_tvalid		(m_axi4s_tvalid),
				.m_axi4s_tready		(m_axi4s_tready)
			);
	
	
endmodule


`default_nettype wire


// end of file
