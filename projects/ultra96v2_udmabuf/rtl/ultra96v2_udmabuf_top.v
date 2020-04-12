`timescale 1ns / 1ps
`default_nettype none

module ultra96v2_udmabuf_top
            (
                output  wire    [1:0]   led
            );
    
    
    wire            resetn;
    wire            clk;
    
    wire    [39:0]  axi4l_peri_awaddr;
    wire    [2:0]   axi4l_peri_awprot;
    wire            axi4l_peri_awvalid;
    wire            axi4l_peri_awready;
    wire    [63:0]  axi4l_peri_wdata;
    wire    [7:0]   axi4l_peri_wstrb;
    wire            axi4l_peri_wvalid;
    wire            axi4l_peri_wready;
    wire    [1:0]   axi4l_peri_bresp;
    wire            axi4l_peri_bvalid;
    wire            axi4l_peri_bready;
    wire    [39:0]  axi4l_peri_araddr;
    wire    [2:0]   axi4l_peri_arprot;
    wire            axi4l_peri_arvalid;
    wire            axi4l_peri_arready;
    wire    [63:0]  axi4l_peri_rdata;
    wire    [1:0]   axi4l_peri_rresp;
    wire            axi4l_peri_rvalid;
    wire            axi4l_peri_rready;
    
    wire    [5:0]   axi4_mem_awid;
    wire            axi4_mem_awuser;
    wire    [48:0]  axi4_mem_awaddr;
    wire    [1:0]   axi4_mem_awburst;
    wire    [3:0]   axi4_mem_awcache;
    wire    [7:0]   axi4_mem_awlen;
    wire    [0:0]   axi4_mem_awlock;
    wire    [2:0]   axi4_mem_awprot;
    wire    [3:0]   axi4_mem_awqos;
    wire    [2:0]   axi4_mem_awsize;
    wire            axi4_mem_awvalid = 0;
    wire            axi4_mem_awready;
    wire    [127:0] axi4_mem_wdata;
    wire    [15:0]  axi4_mem_wstrb;
    wire            axi4_mem_wlast;
    wire            axi4_mem_wvalid;
    wire            axi4_mem_wready;
    wire    [5:0]   axi4_mem_bid;
    wire    [1:0]   axi4_mem_bresp;
    wire            axi4_mem_bvalid;
    wire            axi4_mem_bready = 0;
    wire    [5:0]   axi4_mem_arid;
    wire            axi4_mem_aruser;
    wire    [48:0]  axi4_mem_araddr;
    wire    [1:0]   axi4_mem_arburst;
    wire    [3:0]   axi4_mem_arcache;
    wire    [7:0]   axi4_mem_arlen;
    wire    [0:0]   axi4_mem_arlock;
    wire    [2:0]   axi4_mem_arprot;
    wire    [3:0]   axi4_mem_arqos;
    wire    [2:0]   axi4_mem_arsize;
    wire            axi4_mem_arvalid = 0;
    wire            axi4_mem_arready;
    wire    [5:0]   axi4_mem_rid;
    wire    [1:0]   axi4_mem_rresp;
    wire    [127:0] axi4_mem_rdata;
    wire            axi4_mem_rlast;
    wire            axi4_mem_rvalid;
    wire            axi4_mem_rready = 0;
    
    
    design_1_wrapper
        i_design_1
            (
                .out_resetn             (resetn),
                .out_clk                (clk),
                
                .m_axi4l_peri_awaddr    (axi4l_peri_awaddr),
                .m_axi4l_peri_awprot    (axi4l_peri_awprot),
                .m_axi4l_peri_awvalid   (axi4l_peri_awvalid),
                .m_axi4l_peri_awready   (axi4l_peri_awready),
                .m_axi4l_peri_wdata     (axi4l_peri_wdata),
                .m_axi4l_peri_wstrb     (axi4l_peri_wstrb),
                .m_axi4l_peri_wvalid    (axi4l_peri_wvalid),
                .m_axi4l_peri_wready    (axi4l_peri_wready),
                .m_axi4l_peri_bresp     (axi4l_peri_bresp),
                .m_axi4l_peri_bvalid    (axi4l_peri_bvalid),
                .m_axi4l_peri_bready    (axi4l_peri_bready),
                .m_axi4l_peri_araddr    (axi4l_peri_araddr),
                .m_axi4l_peri_arprot    (axi4l_peri_arprot),
                .m_axi4l_peri_arvalid   (axi4l_peri_arvalid),
                .m_axi4l_peri_arready   (axi4l_peri_arready),
                .m_axi4l_peri_rdata     (axi4l_peri_rdata),
                .m_axi4l_peri_rresp     (axi4l_peri_rresp),
                .m_axi4l_peri_rvalid    (axi4l_peri_rvalid),
                .m_axi4l_peri_rready    (axi4l_peri_rready),
                
                .s_axi4_mem_awid        (axi4_mem_awid),
                .s_axi4_mem_awuser      (axi4_mem_awuser),
                .s_axi4_mem_awaddr      (axi4_mem_awaddr),
                .s_axi4_mem_awburst     (axi4_mem_awburst),
                .s_axi4_mem_awcache     (axi4_mem_awcache),
                .s_axi4_mem_awlen       (axi4_mem_awlen),
                .s_axi4_mem_awlock      (axi4_mem_awlock),
                .s_axi4_mem_awprot      (axi4_mem_awprot),
                .s_axi4_mem_awqos       (axi4_mem_awqos),
                .s_axi4_mem_awsize      (axi4_mem_awsize),
                .s_axi4_mem_awvalid     (axi4_mem_awvalid),
                .s_axi4_mem_awready     (axi4_mem_awready),
                .s_axi4_mem_wdata       (axi4_mem_wdata),
                .s_axi4_mem_wstrb       (axi4_mem_wstrb),
                .s_axi4_mem_wlast       (axi4_mem_wlast),
                .s_axi4_mem_wvalid      (axi4_mem_wvalid),
                .s_axi4_mem_wready      (axi4_mem_wready),
                .s_axi4_mem_bid         (axi4_mem_bid),
                .s_axi4_mem_bready      (axi4_mem_bready),
                .s_axi4_mem_bresp       (axi4_mem_bresp),
                .s_axi4_mem_bvalid      (axi4_mem_bvalid),
                .s_axi4_mem_arid        (axi4_mem_arid),
                .s_axi4_mem_aruser      (axi4_mem_aruser),
                .s_axi4_mem_araddr      (axi4_mem_araddr),
                .s_axi4_mem_arburst     (axi4_mem_arburst),
                .s_axi4_mem_arcache     (axi4_mem_arcache),
                .s_axi4_mem_arlen       (axi4_mem_arlen),
                .s_axi4_mem_arlock      (axi4_mem_arlock),
                .s_axi4_mem_arprot      (axi4_mem_arprot),
                .s_axi4_mem_arqos       (axi4_mem_arqos),
                .s_axi4_mem_arsize      (axi4_mem_arsize),
                .s_axi4_mem_arvalid     (axi4_mem_arvalid),
                .s_axi4_mem_arready     (axi4_mem_arready),
                .s_axi4_mem_rid         (axi4_mem_rid),
                .s_axi4_mem_rresp       (axi4_mem_rresp),
                .s_axi4_mem_rdata       (axi4_mem_rdata),
                .s_axi4_mem_rlast       (axi4_mem_rlast),
                .s_axi4_mem_rvalid      (axi4_mem_rvalid),
                .s_axi4_mem_rready      (axi4_mem_rready)
            );
    
    
    localparam  WB_DAT_SIZE  = 3;
    localparam  WB_ADR_WIDTH = 40 - WB_DAT_SIZE;
    localparam  WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
    wire                            wb_peri_rst_i;
    wire                            wb_peri_clk_i;
    wire    [WB_ADR_WIDTH-1:0]      wb_peri_adr_i;
    wire    [WB_DAT_WIDTH-1:0]      wb_peri_dat_i;
    wire    [WB_DAT_WIDTH-1:0]      wb_peri_dat_o;
    wire                            wb_peri_we_i;
    wire    [WB_SEL_WIDTH-1:0]      wb_peri_sel_i;
    wire                            wb_peri_stb_i;
    wire                            wb_peri_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH       (32),
                .AXI4L_DATA_SIZE        (3)     // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn        (resetn),
                .s_axi4l_aclk           (clk),
                .s_axi4l_awaddr         (axi4l_peri_awaddr),
                .s_axi4l_awprot         (axi4l_peri_awprot),
                .s_axi4l_awvalid        (axi4l_peri_awvalid),
                .s_axi4l_awready        (axi4l_peri_awready),
                .s_axi4l_wstrb          (axi4l_peri_wstrb),
                .s_axi4l_wdata          (axi4l_peri_wdata),
                .s_axi4l_wvalid         (axi4l_peri_wvalid),
                .s_axi4l_wready         (axi4l_peri_wready),
                .s_axi4l_bresp          (axi4l_peri_bresp),
                .s_axi4l_bvalid         (axi4l_peri_bvalid),
                .s_axi4l_bready         (axi4l_peri_bready),
                .s_axi4l_araddr         (axi4l_peri_araddr),
                .s_axi4l_arprot         (axi4l_peri_arprot),
                .s_axi4l_arvalid        (axi4l_peri_arvalid),
                .s_axi4l_arready        (axi4l_peri_arready),
                .s_axi4l_rdata          (axi4l_peri_rdata),
                .s_axi4l_rresp          (axi4l_peri_rresp),
                .s_axi4l_rvalid         (axi4l_peri_rvalid),
                .s_axi4l_rready         (axi4l_peri_rready),
                
                .m_wb_rst_o             (wb_peri_rst_i),
                .m_wb_clk_o             (wb_peri_clk_i),
                .m_wb_adr_o             (wb_peri_adr_i),
                .m_wb_dat_o             (wb_peri_dat_i),
                .m_wb_dat_i             (wb_peri_dat_o),
                .m_wb_we_o              (wb_peri_we_i),
                .m_wb_sel_o             (wb_peri_sel_i),
                .m_wb_stb_o             (wb_peri_stb_i),
                .m_wb_ack_i             (wb_peri_ack_o)
            );
    
    
    assign wb_peri_dat_o = wb_peri_adr_i;
    assign wb_peri_ack_o = wb_peri_stb_i;
    
    
    
    
    
    reg     [26:0]  reg_count;
    always @(posedge clk) begin
        reg_count <= reg_count + 1;
    end
    
    assign led[0] = reg_count[24];
    assign led[1] = reg_count[26];
    
    
endmodule



`default_nettype wire

