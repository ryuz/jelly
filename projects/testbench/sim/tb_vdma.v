
`timescale 1ns / 1ps
`default_nettype none


module tb_vdma();
	localparam RATE    = 10.0;
	
	initial begin
		$dumpfile("tb_vdma.vcd");
		$dumpvars(0, tb_vdma);
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	always #(RATE*100)	reset = 1'b0;
	
	parameter	PIXEL_SIZE  = 2;	// 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
	parameter	PIXEL_WIDTH = (8 << PIXEL_SIZE);
	parameter	DATA_WIDTH  = 32;
	parameter	X_NUM       = 640;	//640;
	parameter	Y_NUM       = 8;	//48;	//480;
	parameter	X_WIDTH     = 10;
	parameter	Y_WIDTH     = 9;
	
	wire						axi4s_aresetn = ~reset;
	wire						axi4s_aclk    = clk;
	wire	[DATA_WIDTH-1:0]	axi4s_tdata;
	wire						axi4s_tlast;
	wire	[0:0]				axi4s_tuser;
	wire						axi4s_tvalid;
	wire						axi4s_tready;
	
	reg		ptn_busy = 1'b0;
	always @(posedge clk) begin
		ptn_busy <= 1'b0; // {$random};
	end
	
	reg		ptn_enable = 1;
	initial begin
		#100000 ptn_enable = 0;
	end
	
	jelly_pattern_generator_axi4s
			#(
				.AXI4S_DATA_WIDTH	(DATA_WIDTH),
				.X_NUM				(X_NUM),
				.Y_NUM				(Y_NUM),
				.X_WIDTH			(X_WIDTH),
				.Y_WIDTH			(Y_WIDTH)
			)
		i_pattern_generator_axi4s
			(
				.aresetn			(axi4s_aresetn),
				.aclk				(axi4s_aclk),
				
				.enable				(ptn_enable),
				.busy				(),
				
				.m_axi4s_tdata		(axi4s_tdata),
				.m_axi4s_tlast		(axi4s_tlast),
				.m_axi4s_tuser		(axi4s_tuser),
				.m_axi4s_tvalid		(axi4s_tvalid),
				.m_axi4s_tready		(axi4s_tready & !ptn_busy)
			);
	
	
	parameter	AXI4_ID_WIDTH    = 6;
	parameter	AXI4_ADDR_WIDTH  = 32;
	parameter	AXI4_DATA_SIZE   = 6;	// 0:8bit, 1:16bit, 2:32bit ...
	parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE);
	parameter	AXI4_STRB_WIDTH  = (1 << AXI4_DATA_SIZE);
	parameter	AXI4_LEN_WIDTH   = 8;
	parameter	AXI4_QOS_WIDTH   = 4;
	
	wire							axi4_aresetn = ~reset;
	wire							axi4_aclk    = clk;
	wire	[AXI4_ID_WIDTH-1:0]		axi4_awid;
	wire	[AXI4_ADDR_WIDTH-1:0]	axi4_awaddr;
	wire	[AXI4_LEN_WIDTH-1:0]	axi4_awlen;
	wire	[2:0]					axi4_awsize;
	wire	[1:0]					axi4_awburst;
	wire	[0:0]					axi4_awlock;
	wire	[3:0]					axi4_awcache;
	wire	[2:0]					axi4_awprot;
	wire	[AXI4_QOS_WIDTH-1:0]	axi4_awqos;
	wire	[3:0]					axi4_awregion;
	wire							axi4_awvalid;
	wire							axi4_awready;
	wire	[AXI4_DATA_WIDTH-1:0]	axi4_wdata;
	wire	[AXI4_STRB_WIDTH-1:0]	axi4_wstrb;
	wire							axi4_wlast;
	wire							axi4_wvalid;
	wire							axi4_wready;
	wire	[AXI4_ID_WIDTH-1:0]		axi4_bid;
	wire	[1:0]					axi4_bresp;
	wire							axi4_bvalid;
	wire							axi4_bready;
	
	jelly_vdma_axi4s_to_axi4
			#(
				.ASYNC				(0),
				.FIFO_PTR_WIDTH		(8),
				
				.PIXEL_SIZE			(PIXEL_SIZE),
				
				.AXI4_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH	(AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE		(AXI4_DATA_SIZE),
				.AXI4_DATA_WIDTH	(AXI4_DATA_WIDTH),
				.AXI4_STRB_WIDTH	(AXI4_STRB_WIDTH),
				.AXI4_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.AXI4_QOS_WIDTH		(AXI4_QOS_WIDTH),
				
				.AXI4S_DATA_SIZE	(PIXEL_SIZE),	// 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
				
				.AXI4_AW_REGS		(1),
				.AXI4_W_REGS		(1),
				.AXI4S_REGS			(1),
				
				.INDEX_WIDTH		(8),
				.STRIDE_WIDTH		(14),
				.H_WIDTH			(12),
				.V_WIDTH			(12),
				
				.WB_ADR_WIDTH		(8),
				.WB_DAT_WIDTH		(32),
				
				.INIT_CTL_CONTROL	(3'b011),
				.INIT_PARAM_ADDR	(32'h0000_0000),
				.INIT_PARAM_STRIDE	(X_NUM*4),
				.INIT_PARAM_WIDTH	(X_NUM),
				.INIT_PARAM_HEIGHT	(Y_NUM),
				.INIT_PARAM_AWLEN	(8'h1f)
			)
		i_vdma_axi4s_to_axi4
			(
				.m_axi4_aresetn		(axi4_aresetn),
				.m_axi4_aclk		(axi4_aclk),
				.m_axi4_awid		(axi4_awid),
				.m_axi4_awaddr		(axi4_awaddr),
				.m_axi4_awlen		(axi4_awlen),
				.m_axi4_awsize		(axi4_awsize),
				.m_axi4_awburst		(axi4_awburst),
				.m_axi4_awlock		(axi4_awlock),
				.m_axi4_awcache		(axi4_awcache),
				.m_axi4_awprot		(axi4_awprot),
				.m_axi4_awqos		(axi4_awqos),
				.m_axi4_awregion	(axi4_awregion),
				.m_axi4_awvalid		(axi4_awvalid),
				.m_axi4_awready		(axi4_awready),
				.m_axi4_wdata		(axi4_wdata),
				.m_axi4_wstrb		(axi4_wstrb),
				.m_axi4_wlast		(axi4_wlast),
				.m_axi4_wvalid		(axi4_wvalid),
				.m_axi4_wready		(axi4_wready),
				.m_axi4_bid			(axi4_bid),
				.m_axi4_bresp		(axi4_bresp),
				.m_axi4_bvalid		(axi4_bvalid),
				.m_axi4_bready		(axi4_bready),
				
				.s_axi4s_aresetn	(axi4s_aresetn),
				.s_axi4s_aclk		(axi4s_aclk),
				.s_axi4s_tdata		(axi4s_tdata),
				.s_axi4s_tlast		(axi4s_tlast),
				.s_axi4s_tuser		(axi4s_tuser),
				.s_axi4s_tvalid		(axi4s_tvalid & !ptn_busy),
				.s_axi4s_tready		(axi4s_tready),
				
				.s_wb_rst_i			(reset),
				.s_wb_clk_i			(clk),
				.s_wb_adr_i			(0),
				.s_wb_dat_i			(0),
				.s_wb_dat_o			(),
				.s_wb_we_i			(0),
				.s_wb_sel_i			(0),
				.s_wb_stb_i			(0),
				.s_wb_ack_o			(),
				
				.out_irq			()
			);
	
	
	jelly_axi4_slave_model
			#(
				.AXI_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI_ADDR_WIDTH		(AXI4_ADDR_WIDTH),
				.AXI_QOS_WIDTH		(AXI4_QOS_WIDTH),
				.AXI_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.AXI_DATA_SIZE		(AXI4_DATA_SIZE),
				
				.MEM_WIDTH			(16),
				
				.WRITE_LOG_FILE		("axi4_write.txt"),
				.READ_LOG_FILE		("axi4_read.txt"),
				
				.AW_FIFO_PTR_WIDTH	(8),
				.W_FIFO_PTR_WIDTH	(0),
				.B_FIFO_PTR_WIDTH	(0),
				.AR_FIFO_PTR_WIDTH	(0),
				.R_FIFO_PTR_WIDTH	(0),
				
				.AW_BUSY_RATE		(50),
				.W_BUSY_RATE		(50),
				.B_BUSY_RATE		(50),
				.AR_BUSY_RATE		(50),
				.R_BUSY_RATE		(50),
				
				.AW_BUSY_RAND		(0),
				.W_BUSY_RAND		(1),
				.B_BUSY_RAND		(2),
				.AR_BUSY_RAND		(3),
				.R_BUSY_RAND		(4)
			)
		i_axi4_slave_model
			(
				.aresetn			(axi4_aresetn),
				.aclk				(axi4_aclk),
				
				.s_axi4_awid		(axi4_awid),
				.s_axi4_awaddr		(axi4_awaddr),
				.s_axi4_awlen		(axi4_awlen),
				.s_axi4_awsize		(axi4_awsize),
				.s_axi4_awburst		(axi4_awburst),
				.s_axi4_awlock		(axi4_awlock),
				.s_axi4_awcache		(axi4_awcache),
				.s_axi4_awprot		(axi4_awprot),
				.s_axi4_awqos		(axi4_awqos),
				.s_axi4_awvalid		(axi4_awvalid),
				.s_axi4_awready		(axi4_awready),
				.s_axi4_wdata		(axi4_wdata),
				.s_axi4_wstrb		(axi4_wstrb),
				.s_axi4_wlast		(axi4_wlast),
				.s_axi4_wvalid		(axi4_wvalid),
				.s_axi4_wready		(axi4_wready),
				.s_axi4_bid			(axi4_bid),
				.s_axi4_bresp		(axi4_bresp),
				.s_axi4_bvalid		(axi4_bvalid),
				.s_axi4_bready		(axi4_bready),
				
				.s_axi4_arid		(),
				.s_axi4_araddr		(),
				.s_axi4_arlen		(),
				.s_axi4_arsize		(),
				.s_axi4_arburst		(),
				.s_axi4_arlock		(),
				.s_axi4_arcache		(),
				.s_axi4_arprot		(),
				.s_axi4_arqos		(),
				.s_axi4_arvalid		(0),
				.s_axi4_arready		(),
				.s_axi4_rid			(),
				.s_axi4_rdata		(),
				.s_axi4_rresp		(),
				.s_axi4_rlast		(),
				.s_axi4_rvalid		(),
				.s_axi4_rready		(0)
			);
	
endmodule


`default_nettype wire


// end of file
