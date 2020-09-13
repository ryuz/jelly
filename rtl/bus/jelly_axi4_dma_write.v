// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4 DMA データ書き込みコア
module jelly_axi4_dma_write
        #(
            parameter   AWASYNC              = 1,
            parameter   WASYNC               = 1,
            parameter   BASYNC               = 1,
            parameter   BYTE_WIDTH           = 8,
            
            parameter   AXI4_ID_WIDTH        = 6,
            parameter   AXI4_ADDR_WIDTH      = 49,
            parameter   AXI4_DATA_SIZE       = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter   AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE),
            parameter   AXI4_STRB_WIDTH      = AXI4_DATA_WIDTH / BYTE_WIDTH,
            parameter   AXI4_LEN_WIDTH       = 8,
            parameter   AXI4_QOS_WIDTH       = 4,
            parameter   AXI4_AWID            = {AXI4_ID_WIDTH{1'b0}},
            parameter   AXI4_AWSIZE          = AXI4_DATA_SIZE,
            parameter   AXI4_AWBURST         = 2'b01,
            parameter   AXI4_AWLOCK          = 1'b0,
            parameter   AXI4_AWCACHE         = 4'b0001,
            parameter   AXI4_AWPROT          = 3'b000,
            parameter   AXI4_AWQOS           = 0,
            parameter   AXI4_AWREGION        = 4'b0000,
            
            parameter   BYPASS_ALIGN         = 0,
            parameter   AXI4_ALIGN           = 12,
            
            parameter   HAS_WSTRB            = 1,
            parameter   HAS_WFIRST           = 0,
            parameter   HAS_WLAST            = 0,
            parameter   S_WDATA_SIZE         = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter   S_WDATA_WIDTH        = (BYTE_WIDTH << S_WDATA_SIZE),
            parameter   S_WSTRB_WIDTH        = S_WDATA_WIDTH / BYTE_WIDTH,
            parameter   S_AWADDR_WIDTH       = AXI4_ADDR_WIDTH,
            parameter   S_AWLEN_WIDTH        = 32,
            parameter   S_AWLEN_SIZE         = S_WDATA_SIZE,
            parameter   S_AWLEN_OFFSET       = 1'b1,
            
            parameter   AWFIFO_PTR_WIDTH     = 4,
            parameter   AWFIFO_RAM_TYPE      = "distributed",
            parameter   AWFIFO_LOW_DEALY     = 1,
            parameter   AWFIFO_DOUT_REGS     = 0,
            parameter   AWFIFO_S_REGS        = 1,
            parameter   AWFIFO_M_REGS        = 1,
            
            parameter   WFIFO_PTR_WIDTH      = 9,
            parameter   WFIFO_RAM_TYPE       = "block",
            parameter   WFIFO_LOW_DEALY      = 0,
            parameter   WFIFO_DOUT_REGS      = 1,
            parameter   WFIFO_S_REGS         = 1,
            parameter   WFIFO_M_REGS         = 1,
            
            parameter   BFIFO_PTR_WIDTH      = 5,
            parameter   BFIFO_RAM_TYPE       = "distributed",
            parameter   BFIFO_LOW_DEALY      = 0,
            parameter   BFIFO_DOUT_REGS      = 1,
            parameter   BFIFO_S_REGS         = 1,
            parameter   BFIFO_M_REGS         = 1,
            
            parameter   WCMD_FIFO_PTR_WIDTH  = 4,
            parameter   WCMD_FIFO_RAM_TYPE   = "distributed",
            parameter   WCMD_FIFO_LOW_DEALY  = 1,
            parameter   WCMD_FIFO_DOUT_REGS  = 0,
            parameter   WCMD_FIFO_S_REGS     = 0,
            parameter   WCMD_FIFO_M_REGS     = 1,
            
            parameter   BCMD_FIFO_PTR_WIDTH  = 4,
            parameter   BCMD_FIFO_RAM_TYPE   = "distributed",
            parameter   BCMD_FIFO_LOW_DEALY  = 1,
            parameter   BCMD_FIFO_DOUT_REGS  = 0,
            parameter   BCMD_FIFO_S_REGS     = 0,
            parameter   BCMD_FIFO_M_REGS     = 1
        )
        (
            input   wire                                endian,
            
            input   wire                                s_awresetn,
            input   wire                                s_awclk,
            input   wire    [S_AWADDR_WIDTH-1:0]        s_awaddr,
            input   wire    [S_AWLEN_WIDTH-1:0]         s_awlen,
            input   wire    [AXI4_LEN_WIDTH-1:0]        s_awlen_max,
            input   wire                                s_awvalid,
            output  wire                                s_awready,
            
            input   wire                                s_wresetn,
            input   wire                                s_wclk,
            input   wire    [S_WDATA_WIDTH-1:0]         s_wdata,
            input   wire    [S_WSTRB_WIDTH-1:0]         s_wstrb,
            input   wire                                s_wtfirst,
            input   wire                                s_wtlast,
            input   wire                                s_wvalid,
            output  wire                                s_wready,
            
            input   wire                                s_bresetn,
            input   wire                                s_bclk,
            output  wire                                s_bvalid,
            input   wire                                s_bready,
            
            input   wire                                m_aresetn,
            input   wire                                m_aclk,
            output  wire    [AXI4_ID_WIDTH-1:0]         m_axi4_awid,
            output  wire    [AXI4_ADDR_WIDTH-1:0]       m_axi4_awaddr,
            output  wire    [AXI4_LEN_WIDTH-1:0]        m_axi4_awlen,
            output  wire    [2:0]                       m_axi4_awsize,
            output  wire    [1:0]                       m_axi4_awburst,
            output  wire    [0:0]                       m_axi4_awlock,
            output  wire    [3:0]                       m_axi4_awcache,
            output  wire    [2:0]                       m_axi4_awprot,
            output  wire    [AXI4_QOS_WIDTH-1:0]        m_axi4_awqos,
            output  wire    [3:0]                       m_axi4_awregion,
            output  wire                                m_axi4_awvalid,
            input   wire                                m_axi4_awready,
            output  wire    [AXI4_DATA_WIDTH-1:0]       m_axi4_wdata,
            output  wire    [AXI4_STRB_WIDTH-1:0]       m_axi4_wstrb,
            output  wire                                m_axi4_wlast,
            output  wire                                m_axi4_wvalid,
            input   wire                                m_axi4_wready,
            input   wire    [AXI4_ID_WIDTH-1:0]         m_axi4_bid,
            input   wire    [1:0]                       m_axi4_bresp,
            input   wire                                m_axi4_bvalid,
            output  wire                                m_axi4_bready
        );
    
    
    // ---------------------------------
    //  localparam
    // ---------------------------------
    
    
    localparam  WDATA_FIFO_SIZE = S_WDATA_SIZE > AXI4_DATA_SIZE ? S_WDATA_SIZE - AXI4_DATA_SIZE : 0;
    
    localparam  CAPACITY_WIDTH  = S_AWLEN_WIDTH  - AXI4_DATA_SIZE;
    
    localparam  ADDR_WIDTH      = S_AWADDR_WIDTH - AXI4_DATA_SIZE;
    localparam  LEN_WIDTH       = S_AWLEN_WIDTH + S_AWLEN_SIZE - AXI4_DATA_SIZE;
    
    
    
    // ---------------------------------
    //  aw FIFO
    // ---------------------------------
    
    // 内部アドレスに換算
    wire    [ADDR_WIDTH-1:0]    s_addr = (s_awaddr >> AXI4_DATA_SIZE);
    wire    [LEN_WIDTH-1:0]     s_len;
    jelly_func_shift
            #(
                .IN_WIDTH       (S_AWLEN_WIDTH),
                .OUT_WIDTH      (LEN_WIDTH),
                .SHIFT_LEFT     (S_AWLEN_SIZE),
                .SHIFT_RIGHT    (AXI4_DATA_SIZE)
            )
        i_func_shift
            (
                .in             (s_awlen),
                .out            (s_len)
            );
    
    wire    [ADDR_WIDTH-1:0]            awfifo_addr;
    wire    [LEN_WIDTH-1:0]             awfifo_len;
    wire    [AXI4_LEN_WIDTH-1:0]        awfifo_awlen_max;
    wire                                awfifo_valid;
    wire                                awfifo_ready;
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC          (AWASYNC),
                .DATA_WIDTH     (ADDR_WIDTH + LEN_WIDTH + AXI4_LEN_WIDTH),
                .PTR_WIDTH      (AWFIFO_PTR_WIDTH),
                .DOUT_REGS      (AWFIFO_DOUT_REGS),
                .RAM_TYPE       (AWFIFO_RAM_TYPE),
                .LOW_DEALY      (AWFIFO_LOW_DEALY),
                .SLAVE_REGS     (AWFIFO_S_REGS),
                .MASTER_REGS    (AWFIFO_M_REGS)
            )
        i_fifo_generic_fwtf_aw
            (
                .s_reset        (~s_awresetn),
                .s_clk          (s_awclk),
                .s_data         ({s_addr, s_len, s_awlen_max}),
                .s_valid        (s_awvalid),
                .s_ready        (s_awready),
                .s_free_count   (),
                
                .m_reset        (~m_aresetn),
                .m_clk          (m_aclk),
                .m_data         ({awfifo_addr, awfifo_len, awfifo_awlen_max}),
                .m_valid        (awfifo_valid),
                .m_ready        (awfifo_ready),
                .m_data_count   ()
            );
    
    
    
    // ---------------------------------
    //  wdata FIFO
    // ---------------------------------
    
    wire    [AXI4_STRB_WIDTH-1:0]   wfifo_wstrb;
    wire    [AXI4_DATA_WIDTH-1:0]   wfifo_wdata;
    wire                            wfifo_wvalid;
    wire                            wfifo_wready;
    
    wire    [CAPACITY_WIDTH-1:0]    s_wfifo_wr_size = (1 << WDATA_FIFO_SIZE);
    wire                            s_wfifo_wr_signal;
    
    jelly_axi4s_fifo_width_converter
            #(
                .ASYNC                  (WASYNC),
                .FIFO_PTR_WIDTH         (WFIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE          (WFIFO_RAM_TYPE),
                .FIFO_LOW_DEALY         (WFIFO_LOW_DEALY),
                .FIFO_DOUT_REGS         (WFIFO_DOUT_REGS),
                .FIFO_S_REGS            (WFIFO_S_REGS),
                .FIFO_M_REGS            (WFIFO_M_REGS),
                
                .HAS_STRB               (S_WDATA_HAS_STRB),
                .HAS_KEEP               (0),
                .HAS_FIRST              (S_WDATA_HAS_FIRST),
                .HAS_LAST               (S_WDATA_HAS_LAST),
                
                .BYTE_WIDTH             (BYTE_WIDTH),
                .S_TDATA_WIDTH          (S_WDATA_WIDTH),
                .M_TDATA_WIDTH          (AXI4_DATA_WIDTH),
                .DATA_WIDTH_GCD         (BYTE_WIDTH),
                
                .ALLOW_UNALIGN_FIRST    (HAS_WFIRST),
                .ALLOW_UNALIGN_LAST     (HAS_WLAST),
                .FIRST_FORCE_LAST       (1),
                .FIRST_OVERWRITE        (0),
                
                .CONVERT_S_REGS         (1),
                .POST_CONVERT           (!HAS_WFIRST && !WLAST && (S_TDATA_WIDTH > M_TDATA_WIDTH))
            )
        i_axi4s_fifo_width_converter
            (
                .endian                 (endian),
                
                .s_aresetn              (s_wresetn),
                .s_aclk                 (s_wclk),
                .s_axi4s_tdata          (s_wdata),
                .s_axi4s_tstrb          (s_wstrb),
                .s_axi4s_tkeep          (),
                .s_axi4s_tfirst         (s_wtfirst),
                .s_axi4s_tlast          (s_wtlast),
                .s_axi4s_tuser          (),
                .s_axi4s_tvalid         (s_wvalid),
                .s_axi4s_tready         (s_wready),
                .s_fifo_free_count      (),
                .s_fifo_wr_signal       (s_wfifo_wr_signal),
                
                .m_aresetn              (m_aresetn),
                .m_aclk                 (m_aclk),
                .m_axi4s_tdata          (wfifo_wdata),
                .m_axi4s_tstrb          (wfifo_wstrb),
                .m_axi4s_tkeep          (),
                .m_axi4s_tfirst         (),
                .m_axi4s_tlast          (),
                .m_axi4s_tuser          (),
                .m_axi4s_tvalid         (wfifo_wvalid),
                .m_axi4s_tready         (wfifo_wready),
                .m_fifo_data_count      (),
                .m_fifo_rd_signal       ()
            );
    
    
    wire    [CAPACITY_WIDTH-1:0]    wfifo_wr_size;
    wire                            wfifo_wr_valid;
    wire                            wfifo_wr_ready;
    
    jelly_capacity_async
            #(
                .ASYNC                  (WASYNC),
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
                .REQUEST_WIDTH          (CAPACITY_WIDTH),
                .ISSUE_WIDTH            (CAPACITY_WIDTH),
                .REQUEST_SIZE_OFFSET    (1'b0),
                .ISSUE_SIZE_OFFSET      (1'b0)
            )
        i_capacity_async
            (
                .s_reset                (~s_wresetn),
                .s_clk                  (s_wclk),
                .s_request_size         (s_wfifo_wr_size),
                .s_request_valid        (s_wfifo_wr_signal),
                .s_queued_request       (),
                
                .m_reset                (~m_aresetn),
                .m_clk                  (m_aclk),
                .m_issue_size           (wfifo_wr_size),
                .m_issue_valid          (wfifo_wr_valid),
                .m_issue_ready          (wfifo_wr_ready),
                .m_queued_request       ()
            );
    
    
    // ---------------------------------
    //  b FIFO
    // ---------------------------------
    
    wire                                bfifo_valid;
    wire                                bfifo_ready;
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC          (BASYNC),
                .DATA_WIDTH     (1'b1),
                .PTR_WIDTH      (BFIFO_PTR_WIDTH),
                .DOUT_REGS      (BFIFO_DOUT_REGS),
                .RAM_TYPE       (BFIFO_RAM_TYPE),
                .LOW_DEALY      (BFIFO_LOW_DEALY),
                .SLAVE_REGS     (BFIFO_S_REGS),
                .MASTER_REGS    (BFIFO_M_REGS)
            )
        i_fifo_generic_fwtf_b
            (
                .s_reset        (~m_aresetn),
                .s_clk          (m_aclk),
                .s_data         (1'b0),
                .s_valid        (bfifo_valid),
                .s_ready        (bfifo_ready),
                .s_free_count   (),
                
                .m_reset        (~s_bresetn),
                .m_clk          (s_bclk),
                .m_data         (),
                .m_valid        (s_bvalid),
                .m_ready        (s_bready),
                .m_data_count   ()
            );
    
    
    
    // ---------------------------------
    //  Write command capacity control
    // ---------------------------------
    
    wire    [ADDR_WIDTH-1:0]        adrgen_addr;
    wire    [AXI4_LEN_WIDTH-1:0]    adrgen_len;
    wire                            adrgen_last;
    wire                            adrgen_valid;
    wire                            adrgen_ready;
    
    jelly_address_generator
            #(
                .ADDR_WIDTH             (ADDR_WIDTH),
                .SIZE_WIDTH             (LEN_WIDTH),
                .LEN_WIDTH              (AXI4_LEN_WIDTH),
                .SIZE_OFFSET            (S_AWLEN_OFFSET),
                .LEN_OFFSET             (1'b1),
                .S_REGS                 (1)
            )
         i_address_generator
            (
                .reset                  (~m_aresetn),
                .clk                    (m_aclk),
                .cke                    (1'b1),
                
                .s_addr                 (awfifo_addr),
                .s_size                 (awfifo_len),
                .s_max_len              (awfifo_awlen_max),
                .s_valid                (awfifo_valid),
                .s_ready                (awfifo_ready),
                
                .m_addr                 (adrgen_addr),
                .m_len                  (adrgen_len),
                .m_last                 (adrgen_last),
                .m_valid                (adrgen_valid),
                .m_ready                (adrgen_ready)
            );
    
    
    // capacity
    wire    [ADDR_WIDTH-1:0]        capsiz_addr;
    wire    [AXI4_LEN_WIDTH-1:0]    capsiz_len;
    wire                            capsiz_last;
    wire                            capsiz_valid;
    wire                            capsiz_ready;
    
    jelly_capacity_size
            #(
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
                .CMD_USER_WIDTH         (1 + ADDR_WIDTH),
                .CMD_SIZE_WIDTH         (AXI4_LEN_WIDTH),
                .CMD_SIZE_OFFSET        (1'b1),
                .CHARGE_WIDTH           (CAPACITY_WIDTH),
                .CHARGE_SIZE_OFFSET     (1'b0)
            )
        i_capacity_size
            (
                .reset                  (~m_aresetn),
                .clk                    (m_aclk),
                .cke                    (1'b1),
                
                .initial_capacity       ({CAPACITY_WIDTH{1'b0}}),
                .current_capacity       (),
                
                .s_charge_size          (wfifo_wr_size),
                .s_charge_valid         (wfifo_wr_valid & wfifo_wr_ready),
                
                .s_cmd_user             ({adrgen_last, adrgen_addr}),
                .s_cmd_size             (adrgen_len),
                .s_cmd_valid            (adrgen_valid),
                .s_cmd_ready            (adrgen_ready),
                
                .m_cmd_user             ({capsiz_last, capsiz_addr}),
                .m_cmd_size             (capsiz_len),
                .m_cmd_valid            (capsiz_valid),
                .m_cmd_ready            (capsiz_ready)
            );
    
    assign wfifo_wr_ready = 1'b1;
    
    
    
    // AXI4スケールに変換
    wire    [AXI4_ADDR_WIDTH-1:0]   capsiz_awaddr;
    wire    [AXI4_LEN_WIDTH-1:0]    capsiz_awlen;
    wire                            capsiz_awlast;
    wire                            capsiz_awvalid;
    wire                            capsiz_awready;
    
    assign capsiz_awaddr  = (capsiz_addr << AXI4_DATA_SIZE);
    assign capsiz_awlen   = capsiz_len;
    assign capsiz_awlast  = capsiz_last;
    assign capsiz_awvalid = capsiz_valid;
    assign capsiz_ready   = capsiz_awready;
    
    
    
    // 4kアライメント処理
    wire    [AXI4_ADDR_WIDTH-1:0]   align_awaddr;
    wire                            align_awlast;
    wire    [AXI4_LEN_WIDTH-1:0]    align_awlen;
    wire                            align_awvalid;
    wire                            align_awready;
    
    jelly_axi_addr_align
            #(
                .BYPASS                 (BYPASS_ALIGN),
                .USER_WIDTH             (1),
                .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                .DATA_SIZE              (AXI4_DATA_SIZE),
                .LEN_WIDTH              (AXI4_LEN_WIDTH),
                .ALIGN                  (AXI4_ALIGN),
                .S_SLAVE_REGS           (0),
                .S_MASTER_REGS          (0),
                .M_SLAVE_REGS           (0),
                .M_MASTER_REGS          (1)
            )
        i_axi_addr_align
            (
                .aresetn                (m_aresetn),
                .aclk                   (m_aclk),
                .aclken                 (1'b1),
                
                .busy                   (),
                
                .s_user                 (capsiz_awlast),
                .s_addr                 (capsiz_awaddr),
                .s_len                  (capsiz_awlen),
                .s_valid                (capsiz_awvalid),
                .s_ready                (capsiz_awready),
                
                .m_user                 (align_awlast),
                .m_addr                 (align_awaddr),
                .m_len                  (align_awlen),
                .m_valid                (align_awvalid),
                .m_ready                (align_awready)
            );
    
    
    
    // ---------------------------------
    //  address command split
    // ---------------------------------
    
    // コマンド発行用とデータ管理用と終了管理用に3分岐させる
    wire    [AXI4_ADDR_WIDTH-1:0]           cmd0_awaddr;
    wire                                    cmd0_awlast;
    wire    [AXI4_LEN_WIDTH-1:0]            cmd0_awlen;
    wire                                    cmd0_awvalid;
    wire                                    cmd0_awready;
    
    wire    [AXI4_ADDR_WIDTH-1:0]           cmd1_awaddr;
    wire                                    cmd1_awlast;
    wire    [AXI4_LEN_WIDTH-1:0]            cmd1_awlen;
    wire                                    cmd1_awvalid;
    wire                                    cmd1_awready;
    
    wire    [AXI4_ADDR_WIDTH-1:0]           cmd2_awaddr;
    wire                                    cmd2_awlast;
    wire    [AXI4_LEN_WIDTH-1:0]            cmd2_awlen;
    wire                                    cmd2_awvalid;
    wire                                    cmd2_awready;
    
    jelly_data_spliter
            #(
                .NUM            (3),
                .DATA_WIDTH     (AXI4_ADDR_WIDTH+1+AXI4_LEN_WIDTH),
                .S_REGS         (0),
                .M_REGS         (0)
            )
        i_data_spliter
            (
                .reset          (~m_aresetn),
                .clk            (m_aclk),
                .cke            (1'b1),
                
                .s_data         ({3{align_awaddr, align_awlast, align_awlen}}),
                .s_valid        (align_awvalid),
                .s_ready        (align_awready),
                
                .m_data         ({{cmd2_awaddr, cmd2_awlast, cmd2_awlen}, {cmd1_awaddr, cmd1_awlast, cmd1_awlen}, {cmd0_awaddr, cmd0_awlast, cmd0_awlen}}),
                .m_valid        ({cmd2_awvalid,                            cmd1_awvalid,                           cmd0_awvalid}),
                .m_ready        ({cmd2_awready,                            cmd1_awready,                           cmd0_awready})
            );
    
    // aw
    assign m_axi4_awid     = AXI4_AWID;
    assign m_axi4_awaddr   = cmd0_awaddr;
    assign m_axi4_awlen    = cmd0_awlen;
    assign m_axi4_awsize   = AXI4_AWSIZE;
    assign m_axi4_awburst  = AXI4_AWBURST;
    assign m_axi4_awlock   = AXI4_AWLOCK;
    assign m_axi4_awcache  = AXI4_AWCACHE;
    assign m_axi4_awprot   = AXI4_AWPROT;
    assign m_axi4_awqos    = AXI4_AWQOS;
    assign m_axi4_awregion = AXI4_AWREGION;
    assign m_axi4_awvalid  = cmd0_awvalid;
    assign cmd0_awready    = m_axi4_awready;
    
    
    
    // ---------------------------------
    //  data
    // ---------------------------------
    
    // wlast付与
    jelly_axi_data_last
            #(
                .BYPASS                     (0),
                .USER_WIDTH                 (AXI4_STRB_WIDTH),
                .DATA_WIDTH                 (AXI4_DATA_WIDTH),
                .LEN_WIDTH                  (AXI4_LEN_WIDTH),
                .FIFO_ASYNC                 (0),
                .FIFO_PTR_WIDTH             (WCMD_FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE              (WCMD_FIFO_RAM_TYPE),
                .S_SLAVE_REGS               (0),
                .S_MASTER_REGS              (0),
                .M_SLAVE_REGS               (0),
                .M_MASTER_REGS              (1)
            )
        i_axi_data_last
            (
                .aresetn                    (m_aresetn),
                .aclk                       (m_aclk),
                .aclken                     (1'b1),
                
                .s_cmd_aresetn              (m_aresetn),
                .s_cmd_aclk                 (m_aclk),
                .s_cmd_aclken               (1'b1),
                .s_cmd_len                  (cmd1_awlen),
                .s_cmd_valid                (cmd1_awvalid),
                .s_cmd_ready                (cmd1_awready),
                
                .s_user                     (wfifo_wstrb),
                .s_last                     (1'b1),
                .s_data                     (wfifo_wdata),
                .s_valid                    (wfifo_wvalid),
                .s_ready                    (wfifo_wready),
                
                .m_user                     (m_axi4_wstrb),
                .m_last                     (m_axi4_wlast),
                .m_data                     (m_axi4_wdata),
                .m_valid                    (m_axi4_wvalid),
                .m_ready                    (m_axi4_wready)
            );
    
    
    
    // ---------------------------------
    //  write complete
    // ---------------------------------
    
    wire                                bcmd_awlast;
    wire                                bcmd_awvalid;
    wire                                bcmd_awready;
    
    jelly_fifo_fwtf
            #(
                .DATA_WIDTH                 (1'b1),
                .PTR_WIDTH                  (BCMD_FIFO_PTR_WIDTH),
                .DOUT_REGS                  (BCMD_FIFO_DOUT_REGS),
                .RAM_TYPE                   (BCMD_FIFO_RAM_TYPE),
                .LOW_DEALY                  (BCMD_FIFO_LOW_DEALY),
                .SLAVE_REGS                 (BCMD_FIFO_S_REGS),
                .MASTER_REGS                (BCMD_FIFO_M_REGS)
            )
        i_fifo_fwtf_bcmd
            (
                .reset                      (~m_aresetn),
                .clk                        (m_aclk),
                
                .s_data                     (cmd2_awlast),
                .s_valid                    (cmd2_awvalid),
                .s_ready                    (cmd2_awready),
                .s_free_count               (),
                
                .m_data                     (bcmd_awlast),
                .m_valid                    (bcmd_awvalid),
                .m_ready                    (bcmd_awready),
                .m_data_count               ()
            );
    
    assign bcmd_awready  = (bcmd_awvalid & bcmd_awlast) ? (m_axi4_bvalid & bfifo_ready) : m_axi4_bvalid;
    assign bfifo_valid   = (bcmd_awvalid & bcmd_awlast & m_axi4_bvalid && m_axi4_bready);
    assign m_axi4_bready = (bcmd_awvalid & bcmd_awlast) ? (bcmd_awvalid && bfifo_ready) : bcmd_awvalid;
    
    
    
    
    // ---------------------------------
    //  debug (for dimulation)
    // ---------------------------------
    
    integer total_aw;
    integer total_w;
    always @(posedge m_aclk) begin
        if ( ~m_aresetn ) begin
            total_aw <= 0;
            total_w  <= 0;
        end
        else begin
            if ( m_axi4_awvalid & m_axi4_awready ) begin
                total_aw <= total_aw + m_axi4_awlen + 1'b1;
            end
            
            if ( m_axi4_wvalid & m_axi4_wready ) begin
                total_w <= total_w + 'b1;
            end
        end
    end
    
    
endmodule


`default_nettype wire


// end of file
