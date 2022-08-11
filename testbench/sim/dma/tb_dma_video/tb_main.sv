
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   int     WB_ADR_WIDTH          = 32,
            parameter   int     WB_DAT_WIDTH          = 32,
            parameter   int     WB_SEL_WIDTH          = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        src_aresetn,
            input   wire                        src_aclk,
            input   wire                        dst_aresetn,
            input   wire                        dst_aclk,
            input   wire                        mem_aresetn,
            input   wire                        mem_aclk,

            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );

    
    
    localparam  RAND_BUSY = 1;
    
    
    // -----------------------------------------
    //  parameter
    // -----------------------------------------
    
    parameter X_NUM                 = 128;
    parameter Y_NUM                 = 128;
    
    
    parameter BYTE_WIDTH            = 8;
    
    parameter WB_ASYNC              = 1;
//    parameter WB_ADR_WIDTH          = 32;
//    parameter WB_DAT_WIDTH          = 32;
//    parameter WB_SEL_WIDTH          = (WB_DAT_WIDTH / 8);
    
    // AXI4-Stream Video
    parameter AXI4S_SRC_DATA_WIDTH  = 24;
    parameter AXI4S_SRC_USER_WIDTH  = 1;
    
    parameter AXI4S_DST_DATA_WIDTH  = 24;
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
    
    
    
    
    // ----------------------------------
    //  buffer manager
    // ----------------------------------
    
    localparam BUFFER_NUM   = 4;
    localparam READER_NUM   = 1;
    
    wire                                host_buffer_request;
    wire                                host_buffer_release;
    wire    [AXI4_ADDR_WIDTH-1:0]       host_buffer_addr;
    wire    [3:0]                       host_buffer_index;
    
    wire                                dmaw_buffer_request;
    wire                                dmaw_buffer_release;
    wire    [AXI4_ADDR_WIDTH-1:0]       dmaw_buffer_addr;
    wire    [3:0]                       dmaw_buffer_index;
    
    wire                                dmar_buffer_request;
    wire                                dmar_buffer_release;
    wire    [AXI4_ADDR_WIDTH-1:0]       dmar_buffer_addr;
    wire    [3:0]                       dmar_buffer_index;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_bufm_dat_o;
    wire                                wb_bufm_stb_i;
    wire                                wb_bufm_ack_o;
    
    jelly2_buffer_manager
            #(
                .BUFFER_NUM             (BUFFER_NUM),
                .READER_NUM             (2),
                .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                .REFCNT_WIDTH           (4),
                .INDEX_WIDTH            (4),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_ADDR              ({
                                            32'h0003_0000,
                                            32'h0002_0000,
                                            32'h0001_0000,
                                            32'h0000_0000
                                        })
            )
        i_buffer_manager
            (
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_bufm_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_bufm_stb_i),
                .s_wb_ack_o             (wb_bufm_ack_o),
                
                .writer_request         (dmaw_buffer_request),
                .writer_release         (dmaw_buffer_release),
                .writer_addr            (dmaw_buffer_addr),
                .writer_index           (dmaw_buffer_index),
                
                .reader_request         ({host_buffer_request, dmar_buffer_request}),
                .reader_release         ({host_buffer_release, dmar_buffer_release}),
                .reader_addr            ({host_buffer_addr,    dmar_buffer_addr}),
                .reader_index           ({host_buffer_index,   dmar_buffer_index}),
                
                .newest_addr            (),
                .newest_index           (),
                
                .status_refcnt          ()
            );
    
    
    // ----------------------------------
    //  buffer allocator
    // ----------------------------------
    
    // バッファ割り当て
    wire    [WB_DAT_WIDTH-1:0]          wb_bufa_dat_o;
    wire                                wb_bufa_stb_i;
    wire                                wb_bufa_ack_o;
    
    jelly2_buffer_allocator
            #(
                .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                .INDEX_WIDTH            (4),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH)
            )
        i_buffer_allocator
            (
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_bufa_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_bufa_stb_i),
                .s_wb_ack_o             (wb_bufa_ack_o),
                
                .buffer_request         (host_buffer_request),
                .buffer_release         (host_buffer_release),
                .buffer_addr            (host_buffer_addr),
                .buffer_index           (host_buffer_index)
            );
    
    
    
    
    // -----------------------------------------
    //  video source
    // -----------------------------------------
    
    jelly2_axi4s_master_model
            #(
                .COMPONENTS             (3),
                .DATA_WIDTH             (8),
                .X_NUM                  (X_NUM),
                .Y_NUM                  (Y_NUM),
                .X_BLANK                (0),
                .Y_BLANK                (0),
                .X_WIDTH                (32),
                .Y_WIDTH                (32),
                .F_WIDTH                (32),
                .FILE_NAME              ("../../../../../data/images/standard_images/Mandrill_128x128_rotation/img_"),
                .FILE_EXT               (".ppm"),
                .FILE_X_NUM             (X_NUM),
                .FILE_Y_NUM             (Y_NUM),
                .SEQUENTIAL_FILE        (1),
                .BUSY_RATE              (RAND_BUSY ? 10 : 0),
                .RANDOM_SEED            (13584),
                .ENDIAN                 (0)
            )
        i_axi4s_master_model
            (
                .aresetn                (src_aresetn),
                .aclk                   (src_aclk),
                .aclken                 (1'b1),

                .enable                 (1'b1),
                .busy                   (),

                .m_axi4s_tuser          (axi4s_src_tuser),
                .m_axi4s_tlast          (axi4s_src_tlast),
                .m_axi4s_tdata          (axi4s_src_tdata),
                .m_axi4s_tx             (),
                .m_axi4s_ty             (),
                .m_axi4s_tf             (),
                .m_axi4s_tvalid         (axi4s_src_tvalid),
                .m_axi4s_tready         (axi4s_src_tready)
            );

    
    // -----------------------------------------
    //  Write
    // -----------------------------------------
    
    wire    [WB_DAT_WIDTH-1:0]          wb_dmaw_dat_o;
    wire                                wb_dmaw_stb_i;
    wire                                wb_dmaw_ack_o;
    
    jelly2_dma_video_write
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
                
                .INIT_CTL_CONTROL       (4'b0000),
                .INIT_IRQ_ENABLE        (1'b0),
                .INIT_PARAM_ADDR        (0),
                .INIT_PARAM_AWLEN_MAX   (255),
                .INIT_PARAM_H_SIZE      (12'(X_NUM-1)),
                .INIT_PARAM_V_SIZE      (12'(Y_NUM-1)),
                .INIT_PARAM_LINE_STEP   (X_NUM*4),
                .INIT_PARAM_F_SIZE      (8'(0)),
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
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_dmaw_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_dmaw_stb_i),
                .s_wb_ack_o             (wb_dmaw_ack_o),
                .out_irq                (),
                
                .buffer_request         (dmaw_buffer_request),
                .buffer_release         (dmaw_buffer_release),
                .buffer_addr            (dmaw_buffer_addr),
                
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
    
    wire    [WB_DAT_WIDTH-1:0]          wb_dmar_dat_o;
    wire                                wb_dmar_stb_i;
    wire                                wb_dmar_ack_o;
    
    jelly2_dma_video_read
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
                
                .INIT_CTL_CONTROL       (4'b0000),
                .INIT_IRQ_ENABLE        (1'b0),
                .INIT_PARAM_ADDR        (0),
                .INIT_PARAM_ARLEN_MAX   (AXI4_LEN_WIDTH'(3)),
                .INIT_PARAM_H_SIZE      (12'(X_NUM-1)),
                .INIT_PARAM_V_SIZE      (12'(Y_NUM-1)),
                .INIT_PARAM_LINE_STEP   (X_NUM*4),
                .INIT_PARAM_F_SIZE      (8'(0)),
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
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_dmar_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_dmar_stb_i),
                .s_wb_ack_o             (wb_dmar_ack_o),
                .out_irq                (),
                
                .buffer_request         (dmar_buffer_request),
                .buffer_release         (dmar_buffer_release),
                .buffer_addr            (dmar_buffer_addr),
                
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
    
    
    
    // -----------------------------------------
    //  save image
    // -----------------------------------------
    
    int     dst_frame_num;

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FORMAT             ("P3"),
                .FILE_NAME          ("dst_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0),
                .BUSY_RATE          (RAND_BUSY ? 20 : 0),
                .RANDOM_SEED        (82147)
            )
        i_axi4s_slave_model
            (
                .aresetn                (dst_aresetn),
                .aclk                   (dst_aclk),
                .aclken                 (1'b1),

                .param_width            (X_NUM),
                .param_height           (Y_NUM),
                .frame_num              (dst_frame_num),
            
                .s_axi4s_tuser          (axi4s_dst_tuser),
                .s_axi4s_tlast          (axi4s_dst_tlast),
                .s_axi4s_tdata          (axi4s_dst_tdata[23:0]),
                .s_axi4s_tvalid         (axi4s_dst_tvalid),
                .s_axi4s_tready         (axi4s_dst_tready)
        );
    
    always_ff @(dst_aclk) begin
        if ( dst_aresetn && dst_frame_num > 9 ) begin
            $finish();
        end
    end
    

    // -----------------------------------------
    //  memory model
    // -----------------------------------------
    
    jelly2_axi4_slave_model
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
                .W_BUSY_RATE            (RAND_BUSY ? 20 : 0),
                .B_BUSY_RATE            (RAND_BUSY ? 20 : 0),
                .AR_BUSY_RATE           (RAND_BUSY ? 80 : 0),
                .R_BUSY_RATE            (RAND_BUSY ? 20 : 0)
            )
        i_axi4_slave_model
            (
                .aresetn                (mem_aresetn),
                .aclk                   (mem_aclk),
                .aclken                 (1'b1),
                
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
    
    assign wb_bufm_stb_i = s_wb_stb_i & (s_wb_adr_i[9:8] == 2'b00);
    assign wb_bufa_stb_i = s_wb_stb_i & (s_wb_adr_i[9:8] == 2'b01);
    assign wb_dmaw_stb_i = s_wb_stb_i & (s_wb_adr_i[9:8] == 2'b10);
    assign wb_dmar_stb_i = s_wb_stb_i & (s_wb_adr_i[9:8] == 2'b11);
    
    assign s_wb_dat_o    = wb_bufm_stb_i ? wb_bufm_dat_o :
                           wb_bufa_stb_i ? wb_bufa_dat_o :
                           wb_dmaw_stb_i ? wb_dmaw_dat_o :
                           wb_dmar_stb_i ? wb_dmar_dat_o :
                           {WB_DAT_WIDTH{1'b0}};
    
    assign s_wb_ack_o    = wb_bufm_stb_i ? wb_bufm_ack_o :
                           wb_bufa_stb_i ? wb_bufa_ack_o :
                          
                           wb_dmaw_stb_i ? wb_dmaw_ack_o :
                           wb_dmar_stb_i ? wb_dmar_ack_o :
                           s_wb_stb_i;
    
    
endmodule


`default_nettype wire


// end of file
