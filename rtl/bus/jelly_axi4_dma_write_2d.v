// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4 DMA 2Dデータ書き込みコア
module jelly_axi4_dma_write_2d
        #(
            parameter AWASYNC              = 1,
            parameter WASYNC               = 1,
            parameter BASYNC               = 1,
            parameter BYTE_WIDTH           = 8,
            
            parameter AXI4_ID_WIDTH        = 6,
            parameter AXI4_ADDR_WIDTH      = 49,
            parameter AXI4_DATA_SIZE       = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE),
            parameter AXI4_STRB_WIDTH      = AXI4_DATA_WIDTH / BYTE_WIDTH,
            parameter AXI4_LEN_WIDTH       = 8,
            parameter AXI4_QOS_WIDTH       = 4,
            parameter AXI4_AWID            = {AXI4_ID_WIDTH{1'b0}},
            parameter AXI4_AWSIZE          = AXI4_DATA_SIZE,
            parameter AXI4_AWBURST         = 2'b01,
            parameter AXI4_AWLOCK          = 1'b0,
            parameter AXI4_AWCACHE         = 4'b0001,
            parameter AXI4_AWPROT          = 3'b000,
            parameter AXI4_AWQOS           = 0,
            parameter AXI4_AWREGION        = 4'b0000,
            
            parameter BYPASS_ALIGN         = 0,
            parameter AXI4_ALIGN           = 12,
            
            parameter HAS_WSTRB            = 1,
            parameter HAS_WFIRST           = 0,
            parameter HAS_WLAST            = 0,
            parameter S_WDATA_SIZE         = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter S_WDATA_WIDTH        = (BYTE_WIDTH << S_WDATA_SIZE),
            parameter S_WSTRB_WIDTH        = S_WDATA_WIDTH / BYTE_WIDTH,
            parameter S_AWADDR_WIDTH       = AXI4_ADDR_WIDTH,
            parameter S_AWLEN0_WIDTH       = 32,
            parameter S_AWLEN0_SIZE        = S_WDATA_SIZE,
            parameter S_AWLEN0_OFFSET      = 1'b1,
            parameter S_AWLEN1_WIDTH       = 32,
            parameter S_AWLEN1_SIZE        = S_WDATA_SIZE,
            parameter S_AWLEN1_OFFSET      = 1'b1,
            
            parameter B2D_ASYNC            = (BASYNC || BASYNC),
            parameter B2D_FIFO_PTR_WIDTH   = 4,
            parameter B2D_FIFO_RAM_TYPE    = "distributed",
            parameter B2D_FIFO_LOW_DEALY   = 1,
            parameter B2D_FIFO_DOUT_REGS   = 0,
            parameter B2D_FIFO_S_REGS      = 0,
            parameter B2D_FIFO_M_REGS      = 0,
            
            parameter AWFIFO_PTR_WIDTH     = 4,
            parameter AWFIFO_RAM_TYPE      = "distributed",
            parameter AWFIFO_LOW_DEALY     = 1,
            parameter AWFIFO_DOUT_REGS     = 0,
            parameter AWFIFO_S_REGS        = 1,
            parameter AWFIFO_M_REGS        = 1,
            
            parameter WFIFO_PTR_WIDTH      = 9,
            parameter WFIFO_RAM_TYPE       = "block",
            parameter WFIFO_LOW_DEALY      = 0,
            parameter WFIFO_DOUT_REGS      = 1,
            parameter WFIFO_S_REGS         = 1,
            parameter WFIFO_M_REGS         = 1,
            
            parameter BFIFO_PTR_WIDTH      = 4,
            parameter BFIFO_RAM_TYPE       = "distributed",
            parameter BFIFO_LOW_DEALY      = 0,
            parameter BFIFO_DOUT_REGS      = 1,
            parameter BFIFO_S_REGS         = 1,
            parameter BFIFO_M_REGS         = 1,
            
            parameter WCMD_FIFO_PTR_WIDTH  = 4,
            parameter WCMD_FIFO_RAM_TYPE   = "distributed",
            parameter WCMD_FIFO_LOW_DEALY  = 1,
            parameter WCMD_FIFO_DOUT_REGS  = 0,
            parameter WCMD_FIFO_S_REGS     = 0,
            parameter WCMD_FIFO_M_REGS     = 1,
            
            parameter BCMD_FIFO_PTR_WIDTH  = 4,
            parameter BCMD_FIFO_RAM_TYPE   = "distributed",
            parameter BCMD_FIFO_LOW_DEALY  = 1,
            parameter BCMD_FIFO_DOUT_REGS  = 0,
            parameter BCMD_FIFO_S_REGS     = 0,
            parameter BCMD_FIFO_M_REGS     = 1,
        )
        (
            // system
            input   wire                            endian,
            
            input   wire                            s_awresetn,
            input   wire                            s_awclk,
            input   wire    [S_AWADDR_WIDTH-1:0]    s_awaddr,
            input   wire    [S_AWLEN0_WIDTH-1:0]    s_awlen0,
            input   wire    [S_AWLEN1_WIDTH-1:0]    s_awlen1,
            input   wire    [S_AWSTEP1_WIDTH-1:0]   s_awstep1,
            input   wire    [AXI4_LEN_WIDTH-1:0]    s_awlen_max,
            input   wire                            s_awvalid,
            output  wire                            s_awready,
            
            input   wire                            s_wresetn,
            input   wire                            s_wclk,
            input   wire    [S_WDATA_WIDTH-1:0]     s_wdata,
            input   wire    [S_WSTRB_WIDTH-1:0]     s_wstrb,
            input   wire                            s_wfirst,
            input   wire                            s_wlast,
            input   wire                            s_wvalid,
            output  wire                            s_wready,
            
            input   wire                            s_bresetn,
            input   wire                            s_bclk,
            output  wire                            s_bfirst1,
            output  wire                            s_blast1,
            output  wire                            s_bvalid,
            input   wire                            s_bready,
            
            // axi4
            input   wire                            m_aresetn,
            input   wire                            m_aclk,
            output  wire    [AXI4_ID_WIDTH-1:0]     m_axi4_awid,
            output  wire    [AXI4_ADDR_WIDTH-1:0]   m_axi4_awaddr,
            output  wire    [AXI4_LEN_WIDTH-1:0]    m_axi4_awlen,
            output  wire    [2:0]                   m_axi4_awsize,
            output  wire    [1:0]                   m_axi4_awburst,
            output  wire    [0:0]                   m_axi4_awlock,
            output  wire    [3:0]                   m_axi4_awcache,
            output  wire    [2:0]                   m_axi4_awprot,
            output  wire    [AXI4_QOS_WIDTH-1:0]    m_axi4_awqos,
            output  wire    [3:0]                   m_axi4_awregion,
            output  wire                            m_axi4_awvalid,
            input   wire                            m_axi4_awready,
            output  wire    [AXI4_DATA_WIDTH-1:0]   m_axi4_wdata,
            output  wire    [AXI4_STRB_WIDTH-1:0]   m_axi4_wstrb,
            output  wire                            m_axi4_wlast,
            output  wire                            m_axi4_wvalid,
            input   wire                            m_axi4_wready,
            input   wire    [AXI4_ID_WIDTH-1:0]     m_axi4_bid,
            input   wire    [1:0]                   m_axi4_bresp,
            input   wire                            m_axi4_bvalid,
            output  wire                            m_axi4_bready
        );
    
    
    // address generate
    wire    [S_AWADDR_WIDTH-1:0]    adrgen_awaddr;
    wire    [S_AWLEN0_WIDTH-1:0]    adrgen_awlen0;
    wire    [AXI4_LEN_WIDTH-1:0]    adrgen_awlen_max;
    wire                            adrgen_awfirst;
    wire                            adrgen_awlast;
    wire                            adrgen_awvalid;
    wire                            adrgen_awready;
    jelly_address_generator_step
            #(
                .USER_WIDTH             (S_AWLEN0_WIDTH + AXI4_LEN_WIDTH),
                .ADDR_WIDTH             (S_AWADDR_WIDTH),
                .STEP_WIDTH             (S_AWSTEP1_WIDTH),
                .LEN_WIDTH              (S_AWLEN1_WIDTH),
                .LEN_OFFSET             (S_AWLEN1_OFFSET)
            )
        i_address_generator_step
            (
                .reset                  (~s_awresetn),
                .clk                    (s_awclk),
                .cke                    (1'b1),
                
                .s_user                 ({s_awlen0, s_awlen_max}),
                .s_addr                 (s_awaddr),
                .s_step                 (s_awstep1),
                .s_len                  (s_awlen1),
                .s_valid                (s_awvalid),
                .s_ready                (s_awready),
                
                .m_user                 ({adrgen_awlen0, adrgen_awlen_max}),
                .m_addr                 (adrgen_awaddr),
                .m_first                (adrgen_awfirst),
                .m_last                 (adrgen_awlast),
                .m_valid                (adrgen_awvalid),
                .m_ready                (adrgen_awready)
            );
    
    
    // コマンド用とACK用に分配
    wire    [S_AWADDR_WIDTH-1:0]    cmd_awaddr;
    wire    [S_AWLEN0_WIDTH-1:0]    cmd_awlen0;
    wire    [AXI4_LEN_WIDTH-1:0]    cmd_awlen_max;
    wire                            cmd_awvalid;
    wire                            cmd_awready;
    
    wire                            ack_awfirst;
    wire                            ack_awlast;
    wire                            ack_awvalid;
    wire                            ack_awready;
    jelly_data_split_pack
            #(
                .NUM                    (2),
                .DATA0_WIDTH            (S_AWLEN0_WIDTH + AXI4_LEN_WIDTH + S_AWADDR_WIDTH),
                .DATA1_WIDTH            (2)
            )
        i_data_split_pack
            (
                .reset                  (~s_awresetn),
                .clk                    (s_awclk),
                .cke                    (1'b1),
                
                .s_data0                ({adrgen_awlen0, adrgen_awlen_max, adrgen_awaddr}),
                .s_data1                ({adrgen_awfirst, adrgen_awlast}),
                .s_valid                (adrgen_valid),
                .s_ready                (adrgen_ready),
                
                .m0_data                ({cmd_awlen0, cmd_awlen_max, cmd_awaddr}),
                .m0_valid               (cmd_awvalid),
                .m0_ready               (cmd_awready),
                
                .m1_data                ({ack_awfirst, adrgen_awlast}),
                .m1_valid               (ack_awvalid),
                .m1_ready               (ack_awready)
            );
    
    
    // Write
    wire                            ack_bvalid;
    wire                            ack_bready;
    jelly_axi4_dma_write
            #(
                .AWASYNC                (AWASYNC),
                .WASYNC                 (WASYNC),
                .BASYNC                 (BASYNC),
                .BYTE_WIDTH             (BYTE_WIDTH),
                
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH),
                .AXI4_STRB_WIDTH        (AXI4_STRB_WIDTH),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH),
                .AXI4_AWID              (AXI4_AWID),
                .AXI4_AWSIZE            (AXI4_AWSIZE),
                .AXI4_AWBURST           (AXI4_AWBURST),
                .AXI4_AWLOCK            (AXI4_AWLOCK),
                .AXI4_AWCACHE           (AXI4_AWCACHE),
                .AXI4_AWPROT            (AXI4_AWPROT),
                .AXI4_AWQOS             (AXI4_AWQOS),
                .AXI4_AWREGION          (AXI4_AWREGION),
                
                .BYPASS_ALIGN           (BYPASS_ALIGN),
                .AXI4_ALIGN             (AXI4_ALIGN),
                
                .HAS_WSTRB              (HAS_WSTRB),
                .HAS_WFIRST             (HAS_WFIRST),
                .HAS_WLAST              (HAS_WLAST),
                .S_WDATA_SIZE           (S_WDATA_SIZE),
                .S_WDATA_WIDTH          (S_WDATA_WIDTH),
                .S_WSTRB_WIDTH          (S_WSTRB_WIDTH),
                .S_AWADDR_WIDTH         (S_AWADDR_WIDTH),
                .S_AWLEN_WIDTH          (S_AWLEN_WIDTH),
                .S_AWLEN_SIZE           (S_AWLEN_SIZE),
                .S_AWLEN_OFFSET         (S_AWLEN_OFFSET),
                
                .AWFIFO_PTR_WIDTH       (AWFIFO_PTR_WIDTH),
                .AWFIFO_RAM_TYPE        (AWFIFO_RAM_TYPE),
                .AWFIFO_LOW_DEALY       (AWFIFO_LOW_DEALY),
                .AWFIFO_DOUT_REGS       (AWFIFO_DOUT_REGS),
                .AWFIFO_S_REGS          (AWFIFO_S_REGS),
                .AWFIFO_M_REGS          (AWFIFO_M_REGS),
                
                .WFIFO_PTR_WIDTH        (WFIFO_PTR_WIDTH),
                .WFIFO_RAM_TYPE         (WFIFO_RAM_TYPE),
                .WFIFO_LOW_DEALY        (WFIFO_LOW_DEALY),
                .WFIFO_DOUT_REGS        (WFIFO_DOUT_REGS),
                .WFIFO_S_REGS           (WFIFO_S_REGS),
                .WFIFO_M_REGS           (WFIFO_M_REGS),
                
                .BFIFO_PTR_WIDTH        (BFIFO_PTR_WIDTH),
                .BFIFO_RAM_TYPE         (BFIFO_RAM_TYPE),
                .BFIFO_LOW_DEALY        (BFIFO_LOW_DEALY),
                .BFIFO_DOUT_REGS        (BFIFO_DOUT_REGS),
                .BFIFO_S_REGS           (BFIFO_S_REGS),
                .BFIFO_M_REGS           (BFIFO_M_REGS),
                
                .WCMD_FIFO_PTR_WIDTH    (WCMD_FIFO_PTR_WIDTH),
                .WCMD_FIFO_RAM_TYPE     (WCMD_FIFO_RAM_TYPE),
                .WCMD_FIFO_LOW_DEALY    (WCMD_FIFO_LOW_DEALY),
                .WCMD_FIFO_DOUT_REGS    (WCMD_FIFO_DOUT_REGS),
                .WCMD_FIFO_S_REGS       (WCMD_FIFO_S_REGS),
                .WCMD_FIFO_M_REGS       (WCMD_FIFO_M_REGS),
                                         
                .BCMD_FIFO_PTR_WIDTH    (BCMD_FIFO_PTR_WIDTH),
                .BCMD_FIFO_RAM_TYPE     (BCMD_FIFO_RAM_TYPE),
                .BCMD_FIFO_LOW_DEALY    (BCMD_FIFO_LOW_DEALY),
                .BCMD_FIFO_DOUT_REGS    (BCMD_FIFO_DOUT_REGS),
                .BCMD_FIFO_S_REGS       (BCMD_FIFO_S_REGS),
                .BCMD_FIFO_M_REGS       (BCMD_FIFO_M_REGS)
            )
        i_axi4_dma_write
            (
                .endian                 (endian),
                
                .s_awresetn             (s_awresetn),
                .s_awclk                (s_awclk),
                .s_awaddr               (cmd_awaddr),
                .s_awlen                (cmd_awlen0),
                .s_awlen_max            (cmd_awlen_max),
                .s_awvalid              (cmd_awvalid),
                .s_awready              (cmd_awready),
                
                .s_wresetn              (s_wresetn),
                .s_wclk                 (s_wclk),
                .s_wdata                (s_wdata),
                .s_wstrb                (s_wstrb),
                .s_wtfirst              (s_wtfirst),
                .s_wtlast               (s_wtlast),
                .s_wvalid               (s_wvalid),
                .s_wready               (s_wready),
                
                .s_bresetn              (s_bresetn),
                .s_bclk                 (s_bclk),
                .s_bvalid               (ack_bvalid),
                .s_bready               (ack_bready),
                
                .m_aresetn              (m_aresetn),
                .m_aclk                 (m_aclk),
                .m_axi4_awid            (m_axi4_awid),
                .m_axi4_awaddr          (m_axi4_awaddr),
                .m_axi4_awlen           (m_axi4_awlen),
                .m_axi4_awsize          (m_axi4_awsize),
                .m_axi4_awburst         (m_axi4_awburst),
                .m_axi4_awlock          (m_axi4_awlock),
                .m_axi4_awcache         (m_axi4_awcache),
                .m_axi4_awprot          (m_axi4_awprot),
                .m_axi4_awqos           (m_axi4_awqos),
                .m_axi4_awregion        (m_axi4_awregion),
                .m_axi4_awvalid         (m_axi4_awvalid),
                .m_axi4_awready         (m_axi4_awready),
                .m_axi4_wdata           (m_axi4_wdata),
                .m_axi4_wstrb           (m_axi4_wstrb),
                .m_axi4_wlast           (m_axi4_wlast),
                .m_axi4_wvalid          (m_axi4_wvalid),
                .m_axi4_wready          (m_axi4_wready),
                
                .m_axi4_bid             (axi4_bid),
                .m_axi4_bresp           (axi4_bresp),
                .m_axi4_bvalid          (axi4_bvalid),
                .m_axi4_bready          (axi4_bready)
            );
    
    
    // ack
    jelly_stream_add_syncflag
            #(
                .FIRST_WIDTH            (1),
                .LAST_WIDTH             (1),
                .USER_WIDTH             (0),
                
                .HAS_FIRST              (1),
                .HAS_LAST               (1),
                
                .ASYNC                  (B2D_ASYNC),
                .FIFO_PTR_WIDTH         (B2D_FIFO_PTR_WIDTH),
                .FIFO_DOUT_REGS         (B2D_FIFO_DOUT_REGS),
                .FIFO_RAM_TYPE          (B2D_FIFO_RAM_TYPE),
                .FIFO_LOW_DEALY         (B2D_FIFO_LOW_DEALY),
                .FIFO_S_REGS            (B2D_FIFO_S_REGS),
                .FIFO_M_REGS            (B2D_FIFO_M_REGS)
            )
        i_stream_add_syncflag
            (
                .reset                  (~s_bresetn),
                .clk                    (s_bclk),
                .cke                    (1'b1),
                
                .s_first                (1'b1),
                .s_last                 (1'b1),
                .s_user                 (1'b0),
                .s_valid                (ack_bvalid),
                .s_ready                (ack_bready),
                
                .m_first                (),
                .m_last                 (),
                .m_added_first          (s_bfirst1),
                .m_added_last           (s_blast1),
                .m_user                 (),
                .m_valid                (s_bvalid),
                .m_ready                (s_bready),
                
                .s_add_reset            (~s_awresetn),
                .s_add_clk              (s_awclk),
                .s_add_first            (ack_awfirst),
                .s_add_last             (ack_awlast),
                .s_add_valid            (ack_awvalid),
                .s_add_ready            (ack_awreasy)
            );
    
    
    
endmodule


`default_nettype wire


// end of file
