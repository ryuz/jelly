
`timescale 1 ns / 1 ps

module design_1_wrapper
        (
            output  wire            out_resetn,
            output  wire            out_clk,
            
            output  wire    [39:0]  m_axi4l_peri_awaddr,
            output  wire    [2:0]   m_axi4l_peri_awprot,
            output  wire            m_axi4l_peri_awvalid,
            input   wire            m_axi4l_peri_awready,
            output  wire    [63:0]  m_axi4l_peri_wdata,
            output  wire    [7:0]   m_axi4l_peri_wstrb,
            output  wire            m_axi4l_peri_wvalid,
            input   wire            m_axi4l_peri_wready,
            input   wire    [1:0]   m_axi4l_peri_bresp,
            input   wire            m_axi4l_peri_bvalid,
            output  wire            m_axi4l_peri_bready,
            output  wire    [39:0]  m_axi4l_peri_araddr,
            output  wire    [2:0]   m_axi4l_peri_arprot,
            output  wire            m_axi4l_peri_arvalid,
            input   wire            m_axi4l_peri_arready,
            output  wire    [63:0]  m_axi4l_peri_rdata,
            output  wire    [1:0]   m_axi4l_peri_rresp,
            output  wire            m_axi4l_peri_rvalid,
            input   wire            m_axi4l_peri_rready,
            
            input   wire    [5:0]   s_axi4_mem_awid,
            input   wire            s_axi4_mem_awuser,
            input   wire    [48:0]  s_axi4_mem_awaddr,
            input   wire    [1:0]   s_axi4_mem_awburst,
            input   wire    [3:0]   s_axi4_mem_awcache,
            input   wire    [7:0]   s_axi4_mem_awlen,
            input   wire    [0:0]   s_axi4_mem_awlock,
            input   wire    [2:0]   s_axi4_mem_awprot,
            input   wire    [3:0]   s_axi4_mem_awqos,
            input   wire    [2:0]   s_axi4_mem_awsize,
            input   wire            s_axi4_mem_awvalid,
            output  wire            s_axi4_mem_awready,
            input   wire    [127:0] s_axi4_mem_wdata,
            input   wire    [15:0]  s_axi4_mem_wstrb,
            input   wire            s_axi4_mem_wlast,
            input   wire            s_axi4_mem_wvalid,
            output  wire            s_axi4_mem_wready,
            output  wire    [5:0]   s_axi4_mem_bid,
            output  wire    [1:0]   s_axi4_mem_bresp,
            output  wire            s_axi4_mem_bvalid,
            input   wire            s_axi4_mem_bready,
            input   wire    [5:0]   s_axi4_mem_arid,
            input   wire            s_axi4_mem_aruser,
            input   wire    [48:0]  s_axi4_mem_araddr,
            input   wire    [1:0]   s_axi4_mem_arburst,
            input   wire    [3:0]   s_axi4_mem_arcache,
            input   wire    [7:0]   s_axi4_mem_arlen,
            input   wire    [0:0]   s_axi4_mem_arlock,
            input   wire    [2:0]   s_axi4_mem_arprot,
            input   wire    [3:0]   s_axi4_mem_arqos,
            input   wire    [2:0]   s_axi4_mem_arsize,
            input   wire            s_axi4_mem_arvalid,
            output  wire            s_axi4_mem_arready,
            output  wire    [5:0]   s_axi4_mem_rid,
            output  wire    [1:0]   s_axi4_mem_rresp,
            output  wire    [127:0] s_axi4_mem_rdata,
            output  wire            s_axi4_mem_rlast,
            output  wire            s_axi4_mem_rvalid,
            input   wire            s_axi4_mem_rready
        );
    
    localparam RATE100 = 1000.0/100.00;
    
    reg			reset = 1;
    initial #100 reset = 0;
    
    reg			clk100 = 1'b1;
    always #(RATE100/2.0) clk100 <= ~clk100;
	
	assign out_resetn = ~reset;
	assign out_clk    = clk100;
	
	jelly_axi4_slave_model
			#(
				.AXI_ID_WIDTH			(6),
				.AXI_ADDR_WIDTH			(49),
				.AXI_DATA_SIZE			(4),
				.MEM_WIDTH				(17),
				
				.WRITE_LOG_FILE			("axi4_write.txt"),
				.READ_LOG_FILE			(""),
				
				.AW_DELAY				(20),
				.AR_DELAY				(20),
				
				.AW_FIFO_PTR_WIDTH		(4),
				.W_FIFO_PTR_WIDTH		(4),
				.B_FIFO_PTR_WIDTH		(4),
				.AR_FIFO_PTR_WIDTH		(4),
				.R_FIFO_PTR_WIDTH		(4),
				
				.AW_BUSY_RATE			(0),
				.W_BUSY_RATE			(0),
				.B_BUSY_RATE			(0),
				.AR_BUSY_RATE			(0),
				.R_BUSY_RATE			(0)
			)
		i_axi4_slave_model
			(
				.aresetn				(~reset),
				.aclk					(clk100),
				
				.s_axi4_awid			(s_axi4_mem_awid),
				.s_axi4_awaddr			(s_axi4_mem_awaddr),
				.s_axi4_awlen			(s_axi4_mem_awlen),
				.s_axi4_awsize			(s_axi4_mem_awsize),
				.s_axi4_awburst			(s_axi4_mem_awburst),
				.s_axi4_awlock			(s_axi4_mem_awlock),
				.s_axi4_awcache			(s_axi4_mem_awcache),
				.s_axi4_awprot			(s_axi4_mem_awprot),
				.s_axi4_awqos			(s_axi4_mem_awqos),
				.s_axi4_awvalid			(s_axi4_mem_awvalid),
				.s_axi4_awready			(s_axi4_mem_awready),
				.s_axi4_wdata			(s_axi4_mem_wdata),
				.s_axi4_wstrb			(s_axi4_mem_wstrb),
				.s_axi4_wlast			(s_axi4_mem_wlast),
				.s_axi4_wvalid			(s_axi4_mem_wvalid),
				.s_axi4_wready			(s_axi4_mem_wready),
				.s_axi4_bid				(s_axi4_mem_bid),
				.s_axi4_bresp			(s_axi4_mem_bresp),
				.s_axi4_bvalid			(s_axi4_mem_bvalid),
				.s_axi4_bready			(s_axi4_mem_bready),
				.s_axi4_arid			(s_axi4_mem_arid),
				.s_axi4_araddr			(s_axi4_mem_araddr),
				.s_axi4_arlen			(s_axi4_mem_arlen),
				.s_axi4_arsize			(s_axi4_mem_arsize),
				.s_axi4_arburst			(s_axi4_mem_arburst),
				.s_axi4_arlock			(s_axi4_mem_arlock),
				.s_axi4_arcache			(s_axi4_mem_arcache),
				.s_axi4_arprot			(s_axi4_mem_arprot),
				.s_axi4_arqos			(s_axi4_mem_arqos),
				.s_axi4_arvalid			(s_axi4_mem_arvalid),
				.s_axi4_arready			(s_axi4_mem_arready),
				.s_axi4_rid				(s_axi4_mem_rid),
				.s_axi4_rdata			(s_axi4_mem_rdata),
				.s_axi4_rresp			(s_axi4_mem_rresp),
				.s_axi4_rlast			(s_axi4_mem_rlast),
				.s_axi4_rvalid			(s_axi4_mem_rvalid),
				.s_axi4_rready			(s_axi4_mem_rready)
			);
	
	
endmodule

