
`timescale 1ns / 1ps
`default_nettype none


module tb_dma_video();
    localparam WB_RATE  = 1000.0 / 66.6;
    localparam SRC_RATE = 1000.0 / 166.0;
    localparam DST_RATE = 1000.0 / 133.0;
    localparam MEM_RATE = 1000.0 / 200.0;
    
    
    initial begin
        $dumpfile("tb_dma_video.vcd");
        $dumpvars(0, tb_dma_video);
        
        #1000000;
            $finish;
    end
    
    
    reg     wb_rst_i = 1'b1;
    initial #(WB_RATE*100)      wb_rst_i = 1'b0;
    
    reg     wb_clk_i = 1'b1;
    always #(WB_RATE/2.0)       wb_clk_i = ~wb_clk_i;
    
    
    reg     src_aresetn = 1'b0;
    initial #(SRC_RATE*100)     src_aresetn = 1'b1;
    
    reg     src_aclk = 1'b1;
    always #(SRC_RATE/2.0)      src_aclk = ~src_aclk;
    
    
    reg     dst_aresetn = 1'b0;
    initial #(DST_RATE*100)     dst_aresetn = 1'b1;
    
    reg     dst_aclk = 1'b1;
    always #(DST_RATE/2.0)      dst_aclk = ~dst_aclk;
    
    
    reg     mem_aresetn = 1'b0;
    initial #(MEM_RATE*100)     mem_aresetn = 1'b1;
    
    reg     mem_aclk = 1'b1;
    always #(MEM_RATE/2.0)      mem_aclk = ~mem_aclk;
    
    
    
    localparam  RAND_BUSY = 1;
    
    
    
    // -----------------------------------------
    //  parameter
    // -----------------------------------------
    
    parameter X_NUM                 = 128;
    parameter Y_NUM                 = 128;
    
    
    parameter BYTE_WIDTH            = 8;
    
    parameter WB_ASYNC              = 1;
    parameter WB_ADR_WIDTH          = 32;
    parameter WB_DAT_WIDTH          = 32;
    parameter WB_SEL_WIDTH          = (WB_DAT_WIDTH / 8);
    
    // AXI4-Stream Video
    parameter AXI4S_SRC_DATA_WIDTH  = 32;
    parameter AXI4S_SRC_USER_WIDTH  = 1;
    
    parameter AXI4S_DST_DATA_WIDTH  = 32;
    parameter AXI4S_DST_USER_WIDTH  = 1;
    
    // AXI4 Memory
    parameter AXI4_ID_WIDTH         = 6;
    parameter AXI4_ADDR_WIDTH       = 32;
    parameter AXI4_DATA_SIZE        = 2;    // 0:8bit; 1:16bit; 2:32bit ...
    parameter AXI4_DATA_WIDTH       = (BYTE_WIDTH << AXI4_DATA_SIZE);
    parameter AXI4_STRB_WIDTH       = AXI4_DATA_WIDTH / BYTE_WIDTH;
    parameter AXI4_LEN_WIDTH        = 8;
    parameter AXI4_QOS_WIDTH        = 4;
    parameter AXI4_AWID             = {AXI4_ID_WIDTH{1'b0}};
    parameter AXI4_AWSIZE           = AXI4_DATA_SIZE;
    parameter AXI4_AWBURST          = 2'b01;
    parameter AXI4_AWLOCK           = 1'b0;
    parameter AXI4_AWCACHE          = 4'b0001;
    parameter AXI4_AWPROT           = 3'b000;
    parameter AXI4_AWQOS            = 0;
    parameter AXI4_AWREGION         = 4'b0000;
    parameter AXI4_ALIGN            = 12;  // 2^12 = 4k が境界
    
    
    // endian
    wire                                endian = 1'b0;
    
    // WISHBONE
    reg    [WB_ADR_WIDTH-1:0]           wb_adr_o;
    reg    [WB_DAT_WIDTH-1:0]           wb_dat_o;
    wire   [WB_DAT_WIDTH-1:0]           wb_dat_i;
    reg                                 wb_we_o;
    reg    [WB_SEL_WIDTH-1:0]           wb_sel_o;
    reg                                 wb_stb_o;
    wire                                wb_ack_i;
    
    // source stream
    wire    [AXI4S_SRC_USER_WIDTH-1:0]  axi4s_src_tuser;
    wire                                axi4s_src_tlast;
    wire    [AXI4S_SRC_DATA_WIDTH-1:0]  axi4s_src_tdata;
    wire                                axi4s_src_tvalid;
    wire                                axi4s_src_tready;
    
    // destination stream
    wire    [AXI4S_DST_USER_WIDTH-1:0]  axi4s_dst_tuser;
    wire                                axi4s_dst_tlast;
    wire    [AXI4S_DST_DATA_WIDTH-1:0]  axi4s_dst_tdata;
    wire                                axi4s_dst_tvalid;
    wire                                axi4s_dst_tready;
    
    // AXI4
    wire    [AXI4_ID_WIDTH-1:0]         axi4_mem_awid;
    wire    [AXI4_ADDR_WIDTH-1:0]       axi4_mem_awaddr;
    wire    [AXI4_LEN_WIDTH-1:0]        axi4_mem_awlen;
    wire    [2:0]                       axi4_mem_awsize;
    wire    [1:0]                       axi4_mem_awburst;
    wire    [0:0]                       axi4_mem_awlock;
    wire    [3:0]                       axi4_mem_awcache;
    wire    [2:0]                       axi4_mem_awprot;
    wire    [AXI4_QOS_WIDTH-1:0]        axi4_mem_awqos;
    wire    [3:0]                       axi4_mem_awregion;
    wire                                axi4_mem_awvalid;
    wire                                axi4_mem_awready;
    wire    [AXI4_DATA_WIDTH-1:0]       axi4_mem_wdata;
    wire    [AXI4_STRB_WIDTH-1:0]       axi4_mem_wstrb;
    wire                                axi4_mem_wlast;
    wire                                axi4_mem_wvalid;
    wire                                axi4_mem_wready;
    wire    [AXI4_ID_WIDTH-1:0]         axi4_mem_bid;
    wire    [1:0]                       axi4_mem_bresp;
    wire                                axi4_mem_bvalid;
    wire                                axi4_mem_bready;
    wire    [AXI4_ID_WIDTH-1:0]         axi4_mem_arid;
    wire    [AXI4_ADDR_WIDTH-1:0]       axi4_mem_araddr;
    wire    [AXI4_LEN_WIDTH-1:0]        axi4_mem_arlen;
    wire    [2:0]                       axi4_mem_arsize;
    wire    [1:0]                       axi4_mem_arburst;
    wire    [0:0]                       axi4_mem_arlock;
    wire    [3:0]                       axi4_mem_arcache;
    wire    [2:0]                       axi4_mem_arprot;
    wire    [AXI4_QOS_WIDTH-1:0]        axi4_mem_arqos;
    wire    [3:0]                       axi4_mem_arregion;
    wire                                axi4_mem_arvalid;
    wire                                axi4_mem_arready;
    wire    [AXI4_ID_WIDTH-1:0]         axi4_mem_rid;
    wire    [AXI4_DATA_WIDTH-1:0]       axi4_mem_rdata;
    wire    [1:0]                       axi4_mem_rresp;
    wire                                axi4_mem_rlast;
    wire                                axi4_mem_rvalid;
    wire                                axi4_mem_rready;
    
    
    
    // -----------------------------------------
    //  Source
    // -----------------------------------------
    
    jelly_axi4s_master_model
            #(
                .AXI4S_DATA_WIDTH       (AXI4S_SRC_DATA_WIDTH),
                .X_NUM                  (X_NUM),
                .Y_NUM                  (Y_NUM),
                .PPM_FILE               ("Mandrill_128x128.ppm"),
                .BUSY_RATE              (RAND_BUSY ? 10 : 0),
                .RANDOM_SEED            (13584)
            )
        i_axi4s_master_model
            (
                .aresetn                (src_aresetn),
                .aclk                   (src_aclk),
                
                .m_axi4s_tuser          (axi4s_src_tuser),
                .m_axi4s_tlast          (axi4s_src_tlast),
                .m_axi4s_tdata          (axi4s_src_tdata),
                .m_axi4s_tvalid         (axi4s_src_tvalid),
                .m_axi4s_tready         (axi4s_src_tready)
            );
    
    
    // -----------------------------------------
    //  Write
    // -----------------------------------------
    
    wire    [WB_DAT_WIDTH-1:0]          wb_wr_dat_i;
    wire                                wb_wr_stb_o;
    wire                                wb_wr_ack_i;
    
    wire                                write_buffer_request;
    wire                                write_buffer_release;
    wire    [AXI4_ADDR_WIDTH-1:0]       write_buffer_addr;
    
    jelly_dma_video_write
            #(
                .BYTE_WIDTH             (BYTE_WIDTH),
                
                .WB_ASYNC               (1),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .AXI4S_ASYNC            (1),
                .AXI4S_DATA_WIDTH       (AXI4S_SRC_DATA_WIDTH),
                .AXI4S_USER_WIDTH       (AXI4S_SRC_USER_WIDTH),
                
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH),
                .AXI4_STRB_WIDTH        (AXI4_STRB_WIDTH),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH),
                .AXI4_AWID              ({AXI4_ID_WIDTH{1'b0}}),
                .AXI4_AWSIZE            (AXI4_DATA_SIZE),
                .AXI4_AWBURST           (2'b01),
                .AXI4_AWLOCK            (1'b0),
                .AXI4_AWCACHE           (4'b0001),
                .AXI4_AWPROT            (3'b000),
                .AXI4_AWQOS             (0),
                .AXI4_AWREGION          (4'b0000),
                .AXI4_ALIGN             (12),  // 2^12 = 4k が境界
                
                .INDEX_WIDTH            (1),
                .SIZE_OFFSET            (1'b1),
                .H_SIZE_WIDTH           (12),
                .V_SIZE_WIDTH           (12),
                .F_SIZE_WIDTH           (8),
                .LINE_STEP_WIDTH        (AXI4_ADDR_WIDTH),
                .FRAME_STEP_WIDTH       (AXI4_ADDR_WIDTH),
                
                .INIT_CTL_CONTROL       (4'b0001),
                .INIT_IRQ_ENABLE        (1'b0),
                .INIT_PARAM_ADDR        (0),
                .INIT_PARAM_AWLEN_MAX   (7),
                .INIT_PARAM_H_SIZE      (X_NUM-1),
                .INIT_PARAM_V_SIZE      (Y_NUM-1),
                .INIT_PARAM_LINE_STEP   (X_NUM*4),
                .INIT_PARAM_F_SIZE      (0),
                .INIT_PARAM_FRAME_STEP  (X_NUM*Y_NUM*4),
                .INIT_SKIP_EN           (1'b1),
                .INIT_DETECT_FIRST      (3'b010),
                .INIT_DETECT_LAST       (3'b001),
                .INIT_PADDING_EN        (1'b1),
                .INIT_PADDING_DATA      ({AXI4S_SRC_DATA_WIDTH{1'b0}}),
                
                .CORE_ID                (32'h527a_ffff),
                .CORE_VERSION           (32'h0000_0000),
                .BYPASS_GATE            (0),
                .BYPASS_ALIGN           (0),
                .DETECTOR_ENABLE        (1),
                .ALLOW_UNALIGNED        (1),
                .CAPACITY_WIDTH         (32),
                .WFIFO_PTR_WIDTH        (9),
                .WFIFO_RAM_TYPE         ("block"),
                .WFIFO_LOW_DEALY        (0),
                .WFIFO_DOUT_REGS        (1),
                .WFIFO_S_REGS           (0),
                .WFIFO_M_REGS           (1),
                .AWFIFO_PTR_WIDTH       (4),
                .AWFIFO_RAM_TYPE        ("distributed"),
                .AWFIFO_LOW_DEALY       (1),
                .AWFIFO_DOUT_REGS       (0),
                .AWFIFO_S_REGS          (0),
                .AWFIFO_M_REGS          (0),
                .BFIFO_PTR_WIDTH        (4),
                .BFIFO_RAM_TYPE         ("distributed"),
                .BFIFO_LOW_DEALY        (0),
                .BFIFO_DOUT_REGS        (0),
                .BFIFO_S_REGS           (0),
                .BFIFO_M_REGS           (0),
                .SWFIFOPTR_WIDTH        (4),
                .SWFIFORAM_TYPE         ("distributed"),
                .SWFIFOLOW_DEALY        (1),
                .SWFIFODOUT_REGS        (0),
                .SWFIFOS_REGS           (0),
                .SWFIFOM_REGS           (0),
                .MBFIFO_PTR_WIDTH       (4),
                .MBFIFO_RAM_TYPE        ("distributed"),
                .MBFIFO_LOW_DEALY       (1),
                .MBFIFO_DOUT_REGS       (0),
                .MBFIFO_S_REGS          (0),
                .MBFIFO_M_REGS          (0),
                .WDATFIFO_PTR_WIDTH     (4),
                .WDATFIFO_DOUT_REGS     (0),
                .WDATFIFO_RAM_TYPE      ("distributed"),
                .WDATFIFO_LOW_DEALY     (1),
                .WDATFIFO_S_REGS        (0),
                .WDATFIFO_M_REGS        (0),
                .WDAT_S_REGS            (0),
                .WDAT_M_REGS            (1),
                .BACKFIFO_PTR_WIDTH     (4),
                .BACKFIFO_DOUT_REGS     (0),
                .BACKFIFO_RAM_TYPE      ("distributed"),
                .BACKFIFO_LOW_DEALY     (1),
                .BACKFIFO_S_REGS        (0),
                .BACKFIFO_M_REGS        (0),
                .BACK_S_REGS            (0),
                .BACK_M_REGS            (1),
                .CONVERT_S_REGS         (0)
            )
        i_dma_video_write
            (
                .endian                 (endian),
                
                .s_wb_rst_i             (wb_rst_i),
                .s_wb_clk_i             (wb_clk_i),
                .s_wb_adr_i             (wb_adr_o[7:0]),
                .s_wb_dat_i             (wb_dat_o),
                .s_wb_dat_o             (wb_wr_dat_i),
                .s_wb_we_i              (wb_we_o),
                .s_wb_sel_i             (wb_sel_o),
                .s_wb_stb_i             (wb_wr_stb_o),
                .s_wb_ack_o             (wb_wr_ack_i),
                .out_irq                (),
                
                .buffer_request         (write_buffer_request),
                .buffer_release         (write_buffer_release),
                .buffer_addr            (write_buffer_addr),
                
                .s_axi4s_aresetn        (src_aresetn),
                .s_axi4s_aclk           (src_aclk),
                .s_axi4s_tuser          (axi4s_src_tuser),
                .s_axi4s_tlast          (axi4s_src_tlast),
                .s_axi4s_tdata          (axi4s_src_tdata),
                .s_axi4s_tvalid         (axi4s_src_tvalid),
                .s_axi4s_tready         (axi4s_src_tready),
                
                .m_aresetn              (mem_aresetn),
                .m_aclk                 (mem_aclk),
                .m_axi4_awid            (axi4_mem_awid),
                .m_axi4_awaddr          (axi4_mem_awaddr),
                .m_axi4_awlen           (axi4_mem_awlen),
                .m_axi4_awsize          (axi4_mem_awsize),
                .m_axi4_awburst         (axi4_mem_awburst),
                .m_axi4_awlock          (axi4_mem_awlock),
                .m_axi4_awcache         (axi4_mem_awcache),
                .m_axi4_awprot          (axi4_mem_awprot),
                .m_axi4_awqos           (axi4_mem_awqos),
                .m_axi4_awregion        (axi4_mem_awregion),
                .m_axi4_awvalid         (axi4_mem_awvalid),
                .m_axi4_awready         (axi4_mem_awready),
                .m_axi4_wdata           (axi4_mem_wdata),
                .m_axi4_wstrb           (axi4_mem_wstrb),
                .m_axi4_wlast           (axi4_mem_wlast),
                .m_axi4_wvalid          (axi4_mem_wvalid),
                .m_axi4_wready          (axi4_mem_wready),
                .m_axi4_bid             (axi4_mem_bid),
                .m_axi4_bresp           (axi4_mem_bresp),
                .m_axi4_bvalid          (axi4_mem_bvalid),
                .m_axi4_bready          (axi4_mem_bready)
            );
    
    
    
    // -----------------------------------------
    //  Read
    // -----------------------------------------
    
    wire    [WB_DAT_WIDTH-1:0]          wb_rd_dat_i;
    wire                                wb_rd_stb_o;
    wire                                wb_rd_ack_i;
    
    wire                                read_buffer_request;
    wire                                read_buffer_release;
    wire    [AXI4_ADDR_WIDTH-1:0]       read_buffer_addr;
    
    jelly_dma_video_read
            #(
                .BYTE_WIDTH             (BYTE_WIDTH),
                
                .WB_ASYNC               (1),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .AXI4S_ASYNC            (1),
                .AXI4S_DATA_WIDTH       (AXI4S_DST_DATA_WIDTH),
                .AXI4S_USER_WIDTH       (AXI4S_DST_USER_WIDTH),
                
                .AXI4_ID_WIDTH          (6),
                .AXI4_ADDR_WIDTH        (32),
                .AXI4_DATA_SIZE         (2),    // 0:8bit), 1:16bit), 2:32bit ...
                .AXI4_DATA_WIDTH        ((BYTE_WIDTH << AXI4_DATA_SIZE)),
                .AXI4_LEN_WIDTH         (8),
                .AXI4_QOS_WIDTH         (4),
                .AXI4_ARID              ({AXI4_ID_WIDTH{1'b0}}),
                .AXI4_ARSIZE            (AXI4_DATA_SIZE),
                .AXI4_ARBURST           (2'b01),
                .AXI4_ARLOCK            (1'b0),
                .AXI4_ARCACHE           (4'b0001),
                .AXI4_ARPROT            (3'b000),
                .AXI4_ARQOS             (0),
                .AXI4_ARREGION          (4'b0000),
                .AXI4_ALIGN             (12),  // 2^12 = 4k が境界
                
                .INDEX_WIDTH            (1),
                .SIZE_OFFSET            (1'b1),
                .H_SIZE_WIDTH           (12),
                .V_SIZE_WIDTH           (12),
                .F_SIZE_WIDTH           (8),
                .LINE_STEP_WIDTH        (AXI4_ADDR_WIDTH),
                .FRAME_STEP_WIDTH       (AXI4_ADDR_WIDTH),
                
                .INIT_CTL_CONTROL       (4'b0001),
                .INIT_IRQ_ENABLE        (1'b0),
                .INIT_PARAM_ADDR        (0),
                .INIT_PARAM_AWLEN_MAX   (3),
                .INIT_PARAM_H_SIZE      (X_NUM-1),
                .INIT_PARAM_V_SIZE      (Y_NUM-1),
                .INIT_PARAM_LINE_STEP   (X_NUM*4),
                .INIT_PARAM_F_SIZE      (0),
                .INIT_PARAM_FRAME_STEP  (X_NUM*Y_NUM*4),
                
                .CORE_ID                (32'h527a_ffff),
                .CORE_VERSION           (32'h0000_0000),
                .BYPASS_GATE            (0),
                .BYPASS_ALIGN           (0),
                .ALLOW_UNALIGNED        (1),
                .CAPACITY_WIDTH         (32),
                .RFIFO_PTR_WIDTH        (9),
                .RFIFO_RAM_TYPE         ("block"),
                .RFIFO_LOW_DEALY        (0),
                .RFIFO_DOUT_REGS        (1),
                .RFIFO_S_REGS           (0),
                .RFIFO_M_REGS           (1),
                .ARFIFO_PTR_WIDTH       (4),
                .ARFIFO_RAM_TYPE        ("distributed"),
                .ARFIFO_LOW_DEALY       (1),
                .ARFIFO_DOUT_REGS       (0),
                .ARFIFO_S_REGS          (0),
                .ARFIFO_M_REGS          (0),
                .SRFIFO_PTR_WIDTH       (4),
                .SRFIFO_RAM_TYPE        ("distributed"),
                .SRFIFO_LOW_DEALY       (0),
                .SRFIFO_DOUT_REGS       (0),
                .SRFIFO_S_REGS          (0),
                .SRFIFO_M_REGS          (0),
                .MRFIFO_PTR_WIDTH       (4),
                .MRFIFO_RAM_TYPE        ("distributed"),
                .MRFIFO_LOW_DEALY       (1),
                .MRFIFO_DOUT_REGS       (0),
                .MRFIFO_S_REGS          (0),
                .MRFIFO_M_REGS          (0),
                .RACKFIFO_PTR_WIDTH     (4),
                .RACKFIFO_DOUT_REGS     (0),
                .RACKFIFO_RAM_TYPE      ("distributed"),
                .RACKFIFO_LOW_DEALY     (1),
                .RACKFIFO_S_REGS        (0),
                .RACKFIFO_M_REGS        (0),
                .RACK_S_REGS            (0),
                .RACK_M_REGS            (1),
                .CACKFIFO_PTR_WIDTH     (4),
                .CACKFIFO_DOUT_REGS     (0),
                .CACKFIFO_RAM_TYPE      ("distributed"),
                .CACKFIFO_LOW_DEALY     (1),
                .CACKFIFO_S_REGS        (0),
                .CACKFIFO_M_REGS        (0),
                .CACK_S_REGS            (0),
                .CACK_M_REGS            (1),
                .CONVERT_S_REGS         (0)
            )
        i_dma_video_read
            (
                .endian                 (endian),
                
                .s_wb_rst_i             (wb_rst_i),
                .s_wb_clk_i             (wb_clk_i),
                .s_wb_adr_i             (wb_adr_o[7:0]),
                .s_wb_dat_i             (wb_dat_o),
                .s_wb_dat_o             (wb_rd_dat_i),
                .s_wb_we_i              (wb_we_o),
                .s_wb_sel_i             (wb_sel_o),
                .s_wb_stb_i             (wb_rd_stb_o),
                .s_wb_ack_o             (wb_rd_ack_i),
                .out_irq                (),
                
                .buffer_request         (read_buffer_request),
                .buffer_release         (read_buffer_release),
                .buffer_addr            (read_buffer_addr),
                
                .m_axi4s_aresetn        (dst_aresetn),
                .m_axi4s_aclk           (dst_aclk),
                .m_axi4s_tuser          (axi4s_dst_tuser),
                .m_axi4s_tlast          (axi4s_dst_tlast),
                .m_axi4s_tdata          (axi4s_dst_tdata),
                .m_axi4s_tvalid         (axi4s_dst_tvalid),
                .m_axi4s_tready         (axi4s_dst_tready),
                
                .m_aresetn              (mem_aresetn),
                .m_aclk                 (mem_aclk),
                .m_axi4_arid            (axi4_mem_arid),
                .m_axi4_araddr          (axi4_mem_araddr),
                .m_axi4_arlen           (axi4_mem_arlen),
                .m_axi4_arsize          (axi4_mem_arsize),
                .m_axi4_arburst         (axi4_mem_arburst),
                .m_axi4_arlock          (axi4_mem_arlock),
                .m_axi4_arcache         (axi4_mem_arcache),
                .m_axi4_arprot          (axi4_mem_arprot),
                .m_axi4_arqos           (axi4_mem_arqos),
                .m_axi4_arregion        (axi4_mem_arregion),
                .m_axi4_arvalid         (axi4_mem_arvalid),
                .m_axi4_arready         (axi4_mem_arready),
                .m_axi4_rid             (axi4_mem_rid),
                .m_axi4_rdata           (axi4_mem_rdata),
                .m_axi4_rresp           (axi4_mem_rresp),
                .m_axi4_rlast           (axi4_mem_rlast),
                .m_axi4_rvalid          (axi4_mem_rvalid),
                .m_axi4_rready          (axi4_mem_rready)
            );
    
    
    // ----------------------------------
    //  buffer allocator
    // ----------------------------------
    
    parameter   BUFFER_NUM   = 3;
    parameter   READER_NUM   = 1;
    parameter   ADDR_WIDTH   = AXI4_ADDR_WIDTH;
    parameter   REFCNT_WIDTH = 2;
    
    reg     [ADDR_WIDTH-1:0]        param_buf_addr0 = 32'h1000_0000;
    reg     [ADDR_WIDTH-1:0]        param_buf_addr1 = 32'h2000_0000;
    reg     [ADDR_WIDTH-1:0]        param_buf_addr2 = 32'h3000_0000;
    
    wire    [ADDR_WIDTH-1:0]        newest_addr;
    wire    [1:0]                   newest_index;
    wire    [REFCNT_WIDTH-1:0]      status_refcnt0;
    wire    [REFCNT_WIDTH-1:0]      status_refcnt1;
    wire    [REFCNT_WIDTH-1:0]      status_refcnt2;
    
    
    jelly_buffer_allocator
            #(
                .BUFFER_NUM             (BUFFER_NUM),
                .READER_NUM             (READER_NUM),
                .ADDR_WIDTH             (ADDR_WIDTH),
                .REFCNT_WIDTH           (REFCNT_WIDTH),
                .INDEX_WIDTH            (2)
            )
        i_buffer_allocator
            (
                .reset                  (wb_rst_i),
                .clk                    (wb_clk_i),
                .cke                    (1'b1),
                
                .param_buf_addr         ({param_buf_addr2, param_buf_addr1, param_buf_addr0}),
                
                .writer_request         (write_buffer_request),
                .writer_release         (write_buffer_release),
                .writer_addr            (write_buffer_addr),
                .writer_index           (),
                
                .reader_request         (read_buffer_request),
                .reader_release         (read_buffer_release),
                .reader_addr            (read_buffer_addr),
                .reader_index           (),
                
                .newest_addr            (newest_addr),
                .newest_index           (newest_index),
                .status_refcnt          ({status_refcnt2, status_refcnt1, status_refcnt0})
            );
    
    /*
    // dummy writer
    initial begin
    #10000;
        while ( 1 ) begin
            while ( {$random()} % 10 != 0 )
                @(posedge wb_clk_i);
            read_request <= 1'b1;
            @(posedge wb_clk_i);
            read_request <= 1'b0;
            @(posedge wb_clk_i);
            
            @(posedge wb_clk_i);
            while ( {$random()} % 100 != 0 )
                @(posedge wb_clk_i);
            
            read_release <= 1'b1;
            @(posedge wb_clk_i);
            read_release <= 1'b0;
            @(posedge wb_clk_i);
        end
    end
    */
    
    
    
    // -----------------------------------------
    //  save image
    // -----------------------------------------
    
    jelly_axi4s_slave_model
            #(
                .COMPONENT_NUM          (3),
                .DATA_WIDTH             (8),
                .INIT_FRAME_NUM         (0),
                .FILE_NAME              ("dst_%04d.ppm"),
                .BUSY_RATE              (RAND_BUSY ? 50 : 0),
                .RANDOM_SEED            (82147)
            )
        i_axi4s_slave_model
            (
                .aresetn                (dst_aresetn),
                .aclk                   (dst_aclk),
                .aclken                 (1'b1),
                
                .param_width            (X_NUM),
                .param_height           (Y_NUM),
                
                .s_axi4s_tuser          (axi4s_dst_tuser),
                .s_axi4s_tlast          (axi4s_dst_tlast),
                .s_axi4s_tdata          (axi4s_dst_tdata[23:0]),
                .s_axi4s_tvalid         (axi4s_dst_tvalid),
                .s_axi4s_tready         (axi4s_dst_tready)
            );
    
    
    // -----------------------------------------
    //  memory model
    // -----------------------------------------
    
    jelly_axi4_slave_model
            #(
                .AXI_ID_WIDTH           (AXI4_ID_WIDTH),
                .AXI_ADDR_WIDTH         (AXI4_ADDR_WIDTH),
                .AXI_QOS_WIDTH          (AXI4_QOS_WIDTH),
                .AXI_LEN_WIDTH          (AXI4_LEN_WIDTH),
                .AXI_DATA_SIZE          (AXI4_DATA_SIZE),
                .AXI_DATA_WIDTH         (AXI4_DATA_WIDTH),
                .AXI_STRB_WIDTH         (AXI4_DATA_WIDTH/8),
                .MEM_WIDTH              (24),
                
                .READ_DATA_ADDR         (0),
                
                .WRITE_LOG_FILE         ("axi4_write.txt"),
                .READ_LOG_FILE          ("axi4_read.txt"),
                
                .AW_DELAY               (RAND_BUSY ? 64 : 0),
                .AR_DELAY               (RAND_BUSY ? 64 : 0),
                
                .AW_FIFO_PTR_WIDTH      (RAND_BUSY ? 4 : 0),
                .W_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .B_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .AR_FIFO_PTR_WIDTH      (0),
                .R_FIFO_PTR_WIDTH       (0),
                
                .AW_BUSY_RATE           (RAND_BUSY ? 80 : 0),
                .W_BUSY_RATE            (RAND_BUSY ? 80 : 0),
                .B_BUSY_RATE            (RAND_BUSY ? 80 : 0),
                .AR_BUSY_RATE           (0),
                .R_BUSY_RATE            (0)
            )
        i_axi4_slave_model
            (
                .aresetn                (mem_aresetn),
                .aclk                   (mem_aclk),
                
                .s_axi4_awid            (axi4_mem_awid),
                .s_axi4_awaddr          (axi4_mem_awaddr),
                .s_axi4_awlen           (axi4_mem_awlen),
                .s_axi4_awsize          (axi4_mem_awsize),
                .s_axi4_awburst         (axi4_mem_awburst),
                .s_axi4_awlock          (axi4_mem_awlock),
                .s_axi4_awcache         (axi4_mem_awcache),
                .s_axi4_awprot          (axi4_mem_awprot),
                .s_axi4_awqos           (axi4_mem_awqos),
                .s_axi4_awvalid         (axi4_mem_awvalid),
                .s_axi4_awready         (axi4_mem_awready),
                .s_axi4_wdata           (axi4_mem_wdata),
                .s_axi4_wstrb           (axi4_mem_wstrb),
                .s_axi4_wlast           (axi4_mem_wlast),
                .s_axi4_wvalid          (axi4_mem_wvalid),
                .s_axi4_wready          (axi4_mem_wready),
                .s_axi4_bid             (axi4_mem_bid),
                .s_axi4_bresp           (axi4_mem_bresp),
                .s_axi4_bvalid          (axi4_mem_bvalid),
                .s_axi4_bready          (axi4_mem_bready),
                
                .s_axi4_arid            (axi4_mem_arid),
                .s_axi4_araddr          (axi4_mem_araddr),
                .s_axi4_arlen           (axi4_mem_arlen),
                .s_axi4_arsize          (axi4_mem_arsize),
                .s_axi4_arburst         (axi4_mem_arburst),
                .s_axi4_arlock          (axi4_mem_arlock),
                .s_axi4_arcache         (axi4_mem_arcache),
                .s_axi4_arprot          (axi4_mem_arprot),
                .s_axi4_arqos           (axi4_mem_arqos),
                .s_axi4_arvalid         (axi4_mem_arvalid),
                .s_axi4_arready         (axi4_mem_arready),
                .s_axi4_rid             (axi4_mem_rid),
                .s_axi4_rdata           (axi4_mem_rdata),
                .s_axi4_rresp           (axi4_mem_rresp),
                .s_axi4_rlast           (axi4_mem_rlast),
                .s_axi4_rvalid          (axi4_mem_rvalid),
                .s_axi4_rready          (axi4_mem_rready)
            );
    
    
    // -----------------------------------------
    //  WISHBONE address decoder
    // -----------------------------------------
    
    assign wb_wr_stb_o = wb_stb_o & (wb_adr_o[9:8] == 2'b00);
    assign wb_rd_stb_o = wb_stb_o & (wb_adr_o[9:8] == 2'b01);
    
    assign wb_dat_i    = wb_wr_stb_o ? wb_wr_dat_i :
                         wb_rd_stb_o ? wb_rd_dat_i :
                         {WB_DAT_WIDTH{1'b0}};
    
    assign wb_ack_i    = wb_wr_stb_o ? wb_wr_ack_i :
                         wb_rd_stb_o ? wb_rd_ack_i :
                         wb_stb_o;
    
    
    
    // -----------------------------------------
    //  WISHBONE master
    // -----------------------------------------
    
    reg     [WB_DAT_WIDTH-1:0]      reg_wb_dat;
    reg                             reg_wb_ack;
    always @(posedge wb_clk_i) begin
        if ( ~wb_we_o & wb_stb_o & wb_ack_i ) begin
            reg_wb_dat <= wb_dat_i;
        end
        reg_wb_ack <= wb_ack_i;
    end
    
    
    task wb_write(
                input [WB_ADR_WIDTH-1:0]    adr,
                input [WB_DAT_WIDTH-1:0]    dat,
                input [WB_SEL_WIDTH-1:0]    sel
            );
    begin
        $display("WISHBONE_WRITE(adr:%h dat:%h sel:%b)", adr, dat, sel);
        @(negedge wb_clk_i);
            wb_adr_o = adr;
            wb_dat_o = dat;
            wb_sel_o = sel;
            wb_we_o  = 1'b1;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
    end
    endtask
    
    task wb_read(
                input [WB_ADR_WIDTH-1:0]    adr
            );
    begin
        @(negedge wb_clk_i);
            wb_adr_o = adr;
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'b1}};
            wb_we_o  = 1'b0;
            wb_stb_o = 1'b1;
        @(negedge wb_clk_i);
            while ( reg_wb_ack == 1'b0 ) begin
                @(negedge wb_clk_i);
            end
            wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            wb_we_o  = 1'bx;
            wb_stb_o = 1'b0;
            $display("WISHBONE_READ(adr:%h dat:%h)", adr, reg_wb_dat);
    end
    endtask
    
    
    initial begin
        #(WB_RATE*200);
        
        
        $display("start");
        
        /*
        wb_read(ADR_CORE_ID);
        wb_read(ADR_CORE_VERSION);
        wb_read(ADR_CORE_CONFIG);
        
        wb_write(ADR_PARAM_AWADDR,    32'h0001_0000, 8'hff);
        wb_write(ADR_PARAM_AWLEN_MAX, 32'h0000_000f, 8'hff);
        wb_write(ADR_PARAM_AWLEN0,               31, 8'hff);
        wb_write(ADR_PARAM_AWLEN1,                2, 8'hff);
        wb_write(ADR_PARAM_AWSTEP1,   32'h0001_0100, 8'hff);
        wb_write(ADR_PARAM_AWLEN2,                1, 8'hff);
        wb_write(ADR_PARAM_AWSTEP2,   32'h0001_1000, 8'hff);
        
        wb_write(ADR_CTL_CONTROL,     32'h0000_000b, 8'hff);
        
        #40000;
        
        wb_write(ADR_CTL_CONTROL,     32'h0000_0000, 8'hff);
        */
        
        #1000000;
            $finish();
    end
    
    
endmodule


`default_nettype wire


// end of file
