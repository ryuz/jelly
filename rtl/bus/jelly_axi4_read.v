// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4側のバス幅は AXI4_DATA_SIZE で 2のべき乗サイズのみ指定可能
// 読み出しデータは S_RDATA_WIDTH でバイト単位で指定可能


// AXI4 データ読出しコア
module jelly_axi4_read
        #(
            parameter   ARASYNC              = 1,
            parameter   RASYNC               = 1,
            
            parameter   BYTE_WIDTH           = 8,
            parameter   BYPASS_GATE          = 1,
            parameter   BYPASS_ALIGN         = 0,
            parameter   AXI4_ALIGN           = 12,  // 2^12 = 4k が境界
            parameter   ALLOW_UNALIGNED      = 0,
            
            parameter   HAS_S_RFIRST         = 0,
            parameter   HAS_S_RLAST          = 0,
            parameter   HAS_M_RFIRST         = 0,
            parameter   HAS_M_RLAST          = 1,
            
            parameter   AXI4_ID_WIDTH        = 6,
            parameter   AXI4_ADDR_WIDTH      = 32,
            parameter   AXI4_DATA_SIZE       = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter   AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE),
            parameter   AXI4_LEN_WIDTH       = 8,
            parameter   AXI4_QOS_WIDTH       = 4,
            parameter   AXI4_ARID            = {AXI4_ID_WIDTH{1'b0}},
            parameter   AXI4_ARSIZE          = AXI4_DATA_SIZE,
            parameter   AXI4_ARBURST         = 2'b01,
            parameter   AXI4_ARLOCK          = 1'b0,
            parameter   AXI4_ARCACHE         = 4'b0001,
            parameter   AXI4_ARPROT          = 3'b000,
            parameter   AXI4_ARQOS           = 0,
            parameter   AXI4_ARREGION        = 4'b0000,
            
            parameter   S_RDATA_WIDTH        = 32,
            parameter   S_ARLEN_WIDTH        = 10,
            parameter   S_ARLEN_OFFSET       = 1'b1,
            
            parameter   ARLEN_WIDTH          = S_ARLEN_WIDTH,   // 内部キューイング用
            parameter   ARLEN_OFFSET         = S_ARLEN_OFFSET,
            
            parameter   CONVERT_S_REGS       = 0,
            
            parameter   RFIFO_PTR_WIDTH      = 9,
            parameter   RFIFO_RAM_TYPE       = "block",
            parameter   RFIFO_LOW_DEALY      = 0,
            parameter   RFIFO_DOUT_REGS      = 1,
            parameter   RFIFO_S_REGS         = 0,
            parameter   RFIFO_M_REGS         = 1,
            
            parameter   ARFIFO_PTR_WIDTH     = 4,
            parameter   ARFIFO_RAM_TYPE      = "distributed",
            parameter   ARFIFO_LOW_DEALY     = 1,
            parameter   ARFIFO_DOUT_REGS     = 0,
            parameter   ARFIFO_S_REGS        = 0,
            parameter   ARFIFO_M_REGS        = 0,
            
            parameter   SRFIFO_PTR_WIDTH     = 4,
            parameter   SRFIFO_RAM_TYPE      = "distributed",
            parameter   SRFIFO_LOW_DEALY     = 0,
            parameter   SRFIFO_DOUT_REGS     = 0,
            parameter   SRFIFO_S_REGS        = 0,
            parameter   SRFIFO_M_REGS        = 0,
            
            parameter   MRFIFO_PTR_WIDTH     = 4,
            parameter   MRFIFO_RAM_TYPE      = "distributed",
            parameter   MRFIFO_LOW_DEALY     = 1,
            parameter   MRFIFO_DOUT_REGS     = 0,
            parameter   MRFIFO_S_REGS        = 0,
            parameter   MRFIFO_M_REGS        = 0
        )
        (
            input   wire                            endian,
            
            input   wire                            s_arresetn,
            input   wire                            s_arclk,
            input   wire    [AXI4_ADDR_WIDTH-1:0]   s_araddr,
            input   wire    [S_ARLEN_WIDTH-1:0]     s_arlen,
            input   wire    [AXI4_LEN_WIDTH-1:0]    s_arlen_max,
            input   wire                            s_arvalid,
            output  wire                            s_arready,
            
            input   wire                            s_rresetn,
            input   wire                            s_rclk,
            output  wire    [S_RDATA_WIDTH-1:0]     s_rdata,
            output  wire                            s_rfirst,
            output  wire                            s_rlast,
            output  wire                            s_rvalid,
            input   wire                            s_rready,
            
            input   wire                            m_aresetn,
            input   wire                            m_aclk,
            output  wire    [AXI4_ID_WIDTH-1:0]     m_axi4_arid,
            output  wire    [AXI4_ADDR_WIDTH-1:0]   m_axi4_araddr,
            output  wire    [AXI4_LEN_WIDTH-1:0]    m_axi4_arlen,
            output  wire    [2:0]                   m_axi4_arsize,
            output  wire    [1:0]                   m_axi4_arburst,
            output  wire    [0:0]                   m_axi4_arlock,
            output  wire    [3:0]                   m_axi4_arcache,
            output  wire    [2:0]                   m_axi4_arprot,
            output  wire    [AXI4_QOS_WIDTH-1:0]    m_axi4_arqos,
            output  wire    [3:0]                   m_axi4_arregion,
            output  wire                            m_axi4_arvalid,
            input   wire                            m_axi4_arready,
            input   wire    [AXI4_ID_WIDTH-1:0]     m_axi4_rid,
            input   wire    [AXI4_DATA_WIDTH-1:0]   m_axi4_rdata,
            input   wire    [1:0]                   m_axi4_rresp,
            input   wire                            m_axi4_rlast,
            input   wire                            m_axi4_rvalid,
            output  wire                            m_axi4_rready
        );
    
    
    // ---------------------------------
    //  local parameter
    // ---------------------------------
    
    localparam CAPACITY_WIDTH = ARLEN_WIDTH;
    
    wire    [AXI4_ADDR_WIDTH-1:0]   addr_mask = ALLOW_UNALIGNED ? 0 : (1 << AXI4_DATA_SIZE) - 1;
    
    
    
    // ---------------------------------
    //  bus width convert
    // ---------------------------------
    
    wire    [AXI4_ADDR_WIDTH-1:0]   conv_araddr;
    wire    [ARLEN_WIDTH-1:0]       conv_arlen;
    wire    [AXI4_LEN_WIDTH-1:0]    conv_arlen_max;
    wire                            conv_arvalid;
    wire                            conv_arready;
    
    wire    [AXI4_DATA_WIDTH-1:0]   conv_rdata;
    wire                            conv_rlast;
    wire                            conv_rvalid;
    wire                            conv_rready;
    
    wire                            s_rfifo_rd_signal;
    
    jelly_axi4_read_width_convert
            #(
                .ARASYNC                (ARASYNC),
                .RASYNC                 (RASYNC),
                .BYTE_WIDTH             (BYTE_WIDTH),
                .BYPASS_GATE            (BYPASS_GATE),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED),
                
                .HAS_S_WFIRST           (HAS_S_RFIRST),
                .HAS_S_WLAST            (HAS_S_RLAST),
                .HAS_M_WFIRST           (0),
                .HAS_M_WLAST            (1),
                
                .ARADDR_WIDTH           (AXI4_ADDR_WIDTH),
                .ARUSER_WIDTH           (AXI4_LEN_WIDTH),
                
                .S_RDATA_WIDTH          (S_RDATA_WIDTH),
                .S_RUSER_WIDTH          (0),
                .S_ARLEN_WIDTH          (S_ARLEN_WIDTH),
                .S_ARLEN_OFFSET         (S_ARLEN_OFFSET),
                .S_ARUSER_WIDTH         (0),
                
                .M_RDATA_SIZE           (AXI4_DATA_SIZE),
                .M_RUSER_WIDTH          (0),
                .M_ARLEN_WIDTH          (ARLEN_WIDTH),
                .M_ARLEN_OFFSET         (1'b1),
                .M_ARUSER_WIDTH         (0),
                
                .RFIFO_PTR_WIDTH        (RFIFO_PTR_WIDTH),
                .RFIFO_RAM_TYPE         (RFIFO_RAM_TYPE),
                .RFIFO_LOW_DEALY        (RFIFO_LOW_DEALY),
                .RFIFO_DOUT_REGS        (RFIFO_DOUT_REGS),
                .RFIFO_S_REGS           (RFIFO_S_REGS),
                .RFIFO_M_REGS           (RFIFO_M_REGS),
                
                .ARFIFO_PTR_WIDTH       (ARFIFO_PTR_WIDTH),
                .ARFIFO_RAM_TYPE        (ARFIFO_RAM_TYPE),
                .ARFIFO_LOW_DEALY       (ARFIFO_LOW_DEALY),
                .ARFIFO_DOUT_REGS       (ARFIFO_DOUT_REGS),
                .ARFIFO_S_REGS          (ARFIFO_S_REGS),
                .ARFIFO_M_REGS          (ARFIFO_M_REGS),
                
                .SRFIFO_PTR_WIDTH       (SRFIFO_PTR_WIDTH),
                .SRFIFO_RAM_TYPE        (SRFIFO_RAM_TYPE),
                .SRFIFO_LOW_DEALY       (SRFIFO_LOW_DEALY),
                .SRFIFO_DOUT_REGS       (SRFIFO_DOUT_REGS),
                .SRFIFO_S_REGS          (SRFIFO_S_REGS),
                .SRFIFO_M_REGS          (SRFIFO_M_REGS),
                
                .MRFIFO_PTR_WIDTH       (MRFIFO_PTR_WIDTH),
                .MRFIFO_RAM_TYPE        (MRFIFO_RAM_TYPE),
                .MRFIFO_LOW_DEALY       (MRFIFO_LOW_DEALY),
                .MRFIFO_DOUT_REGS       (MRFIFO_DOUT_REGS),
                .MRFIFO_S_REGS          (MRFIFO_S_REGS),
                .MRFIFO_M_REGS          (MRFIFO_M_REGS),
                
                .CONVERT_S_REGS         (CONVERT_S_REGS),
                .POST_CONVERT           (0)
            )
        i_axi4_write_width_convert
            (
                .endian                 (endian),
                
                .s_arresetn             (s_arresetn),
                .s_arclk                (s_arclk),
                .s_araddr               (s_araddr & ~addr_mask),
                .s_arlen                (s_arlen),
                .s_aruser               (s_arlen_max),
                .s_arvalid              (s_arvalid),
                .s_arready              (s_arready),
                
                .s_rresetn              (s_rresetn),
                .s_rclk                 (s_rclk),
                .s_rfirst               (s_rfirst),
                .s_rlast                (s_rlast),
                .s_rdata                (s_rdata),
                .s_ruser                (),
                .s_rvalid               (s_rvalid),
                .s_rready               (s_rready),
                .rfifo_data_count       (),
                .rfifo_rd_signal        (s_rfifo_rd_signal),
                
                .m_arresetn             (m_aresetn),
                .m_arclk                (m_aclk),
                .m_araddr               (conv_araddr),
                .m_arlen                (conv_arlen),
                .m_aruser               (conv_arlen_max),
                .m_arvalid              (conv_arvalid),
                .m_arready              (conv_arready),
                
                .m_rresetn              (m_aresetn),
                .m_rclk                 (m_aclk),
                .m_rdata                (m_axi4_rdata),
                .m_rfirst               (1'b0),
                .m_rlast                (m_axi4_rlast),
                .m_ruser                (1'b0),
                .m_rvalid               (m_axi4_rvalid),
                .m_rready               (m_axi4_rready),
                .rfifo_free_count       (),
                .rfifo_wr_signal        ()
            );
    
    
    // FIFO 書き込み済み量を CAPACIY として管理
    wire    [CAPACITY_WIDTH-1:0]    conv_rd_size;
    wire                            conv_rd_valid;
    wire                            conv_rd_ready;
    
    jelly_capacity_async
            #(
                .ASYNC                  (RASYNC),
                .CAPACITY_WIDTH         (ARLEN_WIDTH),
                .REQUEST_WIDTH          (1),
                .ISSUE_WIDTH            (ARLEN_WIDTH),
                .REQUEST_SIZE_OFFSET    (1'b1),
                .ISSUE_SIZE_OFFSET      (1'b0)
            )
        i_capacity_async
            (
                .s_reset                (~s_rresetn),
                .s_clk                  (s_rclk),
                .s_request_size         (1'b0),
                .s_request_valid        (s_rfifo_rd_signal),
                .s_queued_request       (),
                
                .m_reset                (~m_aresetn),
                .m_clk                  (m_aclk),
                .m_issue_size           (conv_rd_size),
                .m_issue_valid          (conv_rd_valid),
                .m_issue_ready          (conv_rd_ready),
                .m_queued_request       ()
            );
    
    
    
    // ---------------------------------
    //  Read command capacity control
    // ---------------------------------
    
    wire    [AXI4_ADDR_WIDTH-1:0]   adrgen_araddr;
    wire    [AXI4_LEN_WIDTH-1:0]    adrgen_arlen;
    wire                            adrgen_arlast;
    wire                            adrgen_arvalid;
    wire                            adrgen_arready;
    
    jelly_address_generator
            #(
                .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                .ADDR_UNIT              (1 << AXI4_DATA_SIZE),
                .SIZE_WIDTH             (ARLEN_WIDTH),
                .SIZE_OFFSET            (ARLEN_OFFSET),
                .LEN_WIDTH              (AXI4_LEN_WIDTH),
                .LEN_OFFSET             (1'b1),
                .S_REGS                 (0)
            )
         i_address_generator
            (
                .reset                  (~m_aresetn),
                .clk                    (m_aclk),
                .cke                    (1'b1),
                
                .s_addr                 (conv_araddr),
                .s_size                 (conv_arlen),
                .s_max_len              (conv_arlen_max),
                .s_valid                (conv_arvalid),
                .s_ready                (conv_arready),
                
                .m_addr                 (adrgen_araddr),
                .m_len                  (adrgen_arlen),
                .m_last                 (),
                .m_valid                (adrgen_arvalid),
                .m_ready                (adrgen_arready)
            );
    
    
    // capacity (FIFOに書き込み終わった分だけ発行)
    wire    [AXI4_ADDR_WIDTH-1:0]   capsize_araddr;
    wire    [AXI4_LEN_WIDTH-1:0]    capsize_arlen;
    wire                            capsize_arvalid;
    wire                            capsize_arready;
    
    wire    [CAPACITY_WIDTH-1:0]    initial_capacity = (1 << RFIFO_PTR_WIDTH);
    
    jelly_capacity_size
            #(
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
                .CMD_USER_WIDTH         (AXI4_ADDR_WIDTH),
                .CMD_SIZE_WIDTH         (AXI4_LEN_WIDTH),
                .CMD_SIZE_OFFSET        (1'b1),
                .CHARGE_WIDTH           (CAPACITY_WIDTH),
                .CHARGE_SIZE_OFFSET     (1'b0),
                .S_REGS                 (1),
                .M_REGS                 (1)
            )
        i_capacity_size
            (
                .reset                  (~m_aresetn),
                .clk                    (m_aclk),
                .cke                    (1'b1),
                
                .initial_capacity       (initial_capacity),
                .current_capacity       (),
                
                .s_charge_size          (conv_rd_size),
                .s_charge_valid         (conv_rd_valid & conv_rd_ready),
                
                .s_cmd_user             (adrgen_araddr),
                .s_cmd_size             (adrgen_arlen),
                .s_cmd_valid            (adrgen_arvalid),
                .s_cmd_ready            (adrgen_arready),
                
                .m_cmd_user             (capsize_araddr),
                .m_cmd_size             (capsize_arlen),
                .m_cmd_valid            (capsize_arvalid),
                .m_cmd_ready            (capsize_arready)
            );
    
    assign conv_rd_ready = 1'b1;
    
    
    
    // 4kアライメント処理
    wire    [AXI4_ADDR_WIDTH-1:0]   align_araddr;
    wire    [AXI4_LEN_WIDTH-1:0]    align_arlen;
    wire                            align_arvalid;
    wire                            align_arready;
    
    jelly_address_align_split
            #(
                .BYPASS                 (BYPASS_ALIGN),
                .USER_WIDTH             (0),
                .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                .UNIT_SIZE              (AXI4_DATA_SIZE),
                .LEN_WIDTH              (AXI4_LEN_WIDTH),
                .ALIGN                  (AXI4_ALIGN),
                .S_REGS                 (0)
            )
         i_address_align_split
            (
                .reset                  (~m_aresetn),
                .clk                    (m_aclk),
                .cke                    (1'b1),
                
                .s_addr                 (capsize_araddr),
                .s_len                  (capsize_arlen),
                .s_first                (1'b0),
                .s_last                 (1'b0),
                .s_user                 (1'b0),
                .s_valid                (capsize_arvalid),
                .s_ready                (capsize_arready),
                
                .m_first                (),
                .m_last                 (),
                .m_addr                 (align_araddr),
                .m_len                  (align_arlen),
                .m_user                 (),
                .m_valid                (align_arvalid),
                .m_ready                (align_arready)
            );
    
    // ar
    assign m_axi4_arid     = AXI4_ARID;
    assign m_axi4_araddr   = align_araddr;
    assign m_axi4_arlen    = align_arlen;
    assign m_axi4_arsize   = AXI4_ARSIZE;
    assign m_axi4_arburst  = AXI4_ARBURST;
    assign m_axi4_arlock   = AXI4_ARLOCK;
    assign m_axi4_arcache  = AXI4_ARCACHE;
    assign m_axi4_arprot   = AXI4_ARPROT;
    assign m_axi4_arqos    = AXI4_ARQOS;
    assign m_axi4_arregion = AXI4_ARREGION;
    assign m_axi4_arvalid  = align_arvalid;
    assign align_arready   = m_axi4_arready;
    
    
endmodule


`default_nettype wire


// end of file
