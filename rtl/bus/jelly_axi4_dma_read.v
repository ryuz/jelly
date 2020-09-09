// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// AXI4 DMA データ読出しコア
module jelly_axi4_dma_read
        #(
            parameter   ARASYNC              = 1,
            parameter   RASYNC               = 1,
            parameter   BYTE_WIDTH           = 8,
            
            parameter   AXI4_ID_WIDTH        = 6,
            parameter   AXI4_ADDR_WIDTH      = 49,
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
            
            parameter   BYPASS_ALIGN         = 0,
            parameter   AXI4_ALIGN           = 12,
            
            parameter   S_RDATA_SIZE         = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter   S_RDATA_WIDTH        = (BYTE_WIDTH << S_RDATA_SIZE),
            parameter   S_ARADDR_WIDTH       = AXI4_ADDR_WIDTH,
            parameter   S_ARLEN_WIDTH        = 32,
            parameter   S_ARLEN_SIZE         = S_RDATA_SIZE,
            parameter   S_ARLEN_OFFSET       = 1'b1,
            parameter   HAS_RLAST            = 1,
            
            parameter   ARFIFO_PTR_WIDTH     = 4,
            parameter   ARFIFO_RAM_TYPE      = "distributed",
            parameter   ARFIFO_LOW_DEALY     = 1,
            parameter   ARFIFO_DOUT_REGS     = 0,
            parameter   ARFIFO_S_REGS        = 1,
            parameter   ARFIFO_M_REGS        = 1,
            
            parameter   RFIFO_PTR_WIDTH      = 9,
            parameter   RFIFO_RAM_TYPE       = "block",
            parameter   RFIFO_LOW_DEALY      = 0,
            parameter   RFIFO_DOUT_REGS      = 1,
            parameter   RFIFO_S_REGS         = 1,
            parameter   RFIFO_M_REGS         = 1,
            
            parameter   RCMD_FIFO_PTR_WIDTH  = 4,
            parameter   RCMD_FIFO_RAM_TYPE   = "distributed",
            parameter   RCMD_FIFO_LOW_DEALY  = 1,
            parameter   RCMD_FIFO_DOUT_REGS  = 0,
            parameter   RCMD_FIFO_S_REGS     = 0,
            parameter   RCMD_FIFO_M_REGS     = 1
        )
        (
            input   wire                                endian,
            
            input   wire                                s_arresetn,
            input   wire                                s_arclk,
            input   wire    [S_ARADDR_WIDTH-1:0]        s_araddr,
            input   wire    [S_ARLEN_WIDTH-1:0]         s_arlen,
            input   wire    [AXI4_LEN_WIDTH-1:0]        s_arlen_max,
            input   wire                                s_arvalid,
            output  wire                                s_arready,
            
            input   wire                                s_rresetn,
            input   wire                                s_rclk,
            output  wire                                s_rlast,
            output  wire    [S_RDATA_WIDTH-1:0]         s_rdata,
            output  wire                                s_rvalid,
            input   wire                                s_rready,
            
            input   wire                                m_aresetn,
            input   wire                                m_aclk,
            output  wire    [AXI4_ID_WIDTH-1:0]         m_axi4_arid,
            output  wire    [AXI4_ADDR_WIDTH-1:0]       m_axi4_araddr,
            output  wire    [AXI4_LEN_WIDTH-1:0]        m_axi4_arlen,
            output  wire    [2:0]                       m_axi4_arsize,
            output  wire    [1:0]                       m_axi4_arburst,
            output  wire    [0:0]                       m_axi4_arlock,
            output  wire    [3:0]                       m_axi4_arcache,
            output  wire    [2:0]                       m_axi4_arprot,
            output  wire    [AXI4_QOS_WIDTH-1:0]        m_axi4_arqos,
            output  wire    [3:0]                       m_axi4_arregion,
            output  wire                                m_axi4_arvalid,
            input   wire                                m_axi4_arready,
            input   wire    [AXI4_ID_WIDTH-1:0]         m_axi4_rid,
            input   wire    [AXI4_DATA_WIDTH-1:0]       m_axi4_rdata,
            input   wire    [1:0]                       m_axi4_rresp,
            input   wire                                m_axi4_rlast,
            input   wire                                m_axi4_rvalid,
            output  wire                                m_axi4_rready
        );
    
    
    // ---------------------------------
    //  localparam
    // ---------------------------------
    
    localparam  RDATA_FIFO_SIZE = S_RDATA_SIZE > AXI4_DATA_SIZE ? S_RDATA_SIZE - AXI4_DATA_SIZE : 0;
    
    localparam  CAPACITY_WIDTH  = S_ARLEN_WIDTH - AXI4_DATA_SIZE;
    
    localparam  ADDR_WIDTH      = S_ARADDR_WIDTH - AXI4_DATA_SIZE;
    localparam  LEN_WIDTH       = S_ARLEN_WIDTH + S_ARLEN_SIZE - AXI4_DATA_SIZE;
    
    
    // ---------------------------------
    //  ar FIFO
    // ---------------------------------
    
    // 内部アドレスに換算
    wire    [ADDR_WIDTH-1:0]    s_addr = (s_araddr >> AXI4_DATA_SIZE);
    wire    [LEN_WIDTH-1:0]     s_len;
    jelly_func_parameter_shift
            #(
                .IN_WIDTH               (S_ARLEN_WIDTH),
                .OUT_WIDTH              (LEN_WIDTH),
                .SHIFT_LEFT             (S_ARLEN_SIZE),
                .SHIFT_RIGHT            (AXI4_DATA_SIZE)
            )
        i_func_parameter_shift
            (
                .in                     (s_arlen),
                .out                    (s_len)
            );
    
    wire    [ADDR_WIDTH-1:0]        arfifo_addr;
    wire    [LEN_WIDTH-1:0]         arfifo_len;
    wire    [AXI4_LEN_WIDTH-1:0]    arfifo_arlen_max;
    wire                            arfifo_valid;
    wire                            arfifo_ready;
    
    jelly_fifo_generic_fwtf
            #(
                .ASYNC                  (ARASYNC),
                .DATA_WIDTH             (ADDR_WIDTH + LEN_WIDTH + AXI4_LEN_WIDTH),
                .PTR_WIDTH              (ARFIFO_PTR_WIDTH),
                .DOUT_REGS              (ARFIFO_DOUT_REGS),
                .RAM_TYPE               (ARFIFO_RAM_TYPE),
                .LOW_DEALY              (ARFIFO_LOW_DEALY),
                .SLAVE_REGS             (ARFIFO_S_REGS),
                .MASTER_REGS            (ARFIFO_M_REGS)
            )
        i_fifo_generic_fwtf_ar
            (
                .s_reset                (~s_arresetn),
                .s_clk                  (s_arclk),
                .s_data                 ({s_addr, s_len, s_arlen_max}),
                .s_valid                (s_arvalid),
                .s_ready                (s_arready),
                .s_free_count           (),
                
                .m_reset                (~m_aresetn),
                .m_clk                  (m_aclk),
                .m_data                 ({arfifo_addr, arfifo_len, arfifo_arlen_max}),
                .m_valid                (arfifo_valid),
                .m_ready                (arfifo_ready),
                .m_data_count           ()
            );
    
    
    
    // ---------------------------------
    //  r FIFO
    // ---------------------------------
    
    wire                            rfifo_rlast;
    wire    [AXI4_DATA_WIDTH-1:0]   rfifo_rdata;
    wire                            rfifo_rvalid;
    wire                            rfifo_rready;
    
    wire    [CAPACITY_WIDTH-1:0]    s_rfifo_rd_size = (1 << RDATA_FIFO_SIZE);
    wire                            s_rfifo_rd_signal;
    
    jelly_axi4s_fifo_width_converter
            #(
                .ASYNC                  (RASYNC),
                .FIFO_PTR_WIDTH         (RFIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE          (RFIFO_RAM_TYPE),
                .FIFO_LOW_DEALY         (RFIFO_LOW_DEALY),
                .FIFO_DOUT_REGS         (RFIFO_DOUT_REGS),
                .FIFO_S_REGS            (RFIFO_S_REGS),
                .FIFO_M_REGS            (RFIFO_M_REGS),
                
                .HAS_STRB               (0),
                .HAS_KEEP               (0),
                .HAS_FIRST              (0),
                .HAS_LAST               (HAS_RLAST),
                
                .BYTE_WIDTH             (BYTE_WIDTH),
                .S_TDATA_WIDTH          (AXI4_DATA_WIDTH),
                .M_TDATA_WIDTH          (S_RDATA_WIDTH),
                .FIRST_FORCE_LAST       (1),
                .FIRST_OVERWRITE        (0),
                .S_REGS                 (1)
            )
        i_axi4s_fifo_width_converter
            (
                .endian                 (endian),
                
                .s_aresetn              (m_aresetn),
                .s_aclk                 (m_aclk),
                .s_axi4s_tdata          (rfifo_rdata),
                .s_axi4s_tstrb          (1'b0),
                .s_axi4s_tkeep          (1'b0),
                .s_axi4s_tfirst         (1'b0),
                .s_axi4s_tlast          (rfifo_rlast),
                .s_axi4s_tuser          (1'b0),
                .s_axi4s_tvalid         (rfifo_rvalid),
                .s_axi4s_tready         (rfifo_rready),
                .s_fifo_free_count      (),
                .s_fifo_wr_signal       (),
                
                .m_aresetn              (s_rresetn),
                .m_aclk                 (s_rclk),
                .m_axi4s_tdata          (s_rdata),
                .m_axi4s_tstrb          (),
                .m_axi4s_tkeep          (),
                .m_axi4s_tfirst         (),
                .m_axi4s_tlast          (s_rlast),
                .m_axi4s_tuser          (),
                .m_axi4s_tvalid         (s_rvalid),
                .m_axi4s_tready         (s_rready),
                .m_fifo_data_count      (),
                .m_fifo_rd_signal       (s_rfifo_rd_signal)
            );
    
    /*
    jelly_fifo_width_converter
            #(
                .ASYNC                  (RASYNC),
                .UNIT_WIDTH             (UNIT_WIDTH),
                .S_DATA_SIZE            (1+AXI4_DATA_SIZE),
                .M_DATA_SIZE            (1+S_RDATA_SIZE),
                
                .FIFO_PTR_WIDTH         (RDATA_FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE          (RDATA_FIFO_RAM_TYPE),
                .FIFO_LOW_DEALY         (RDATA_FIFO_LOW_DEALY),
                .FIFO_DOUT_REGS         (RDATA_FIFO_DOUT_REGS),
                .FIFO_SLAVE_REGS        (RDATA_FIFO_S_REGS),
                .FIFO_MASTER_REGS       (RDATA_FIFO_M_REGS)
            )
        i_fifo_width_converter_rdata
            (
                .endian                 (1'b0),
                
                .s_reset                (~m_aresetn),
                .s_clk                  (m_aclk),
                .s_data                 ({rfifo_rlast, rfifo_rdata}),
                .s_valid                (rfifo_rvalid),
                .s_ready                (rfifo_rready),
                .s_free_count           (),
                .s_wr_signal            (),
                
                .m_reset                (~s_rresetn),
                .m_clk                  (s_rclk),
                .m_data                 ({s_rlast, s_rdata}),
                .m_valid                (s_rvalid),
                .m_ready                (s_rready),
                .m_data_count           (),
                .m_rd_signal            (s_rfifo_rd_signal)
            );
    */
    
    
    wire    [CAPACITY_WIDTH-1:0]    rfifo_rd_size;
    wire                            rfifo_rd_valid;
    wire                            rfifo_rd_ready;
    
    jelly_capacity_async
            #(
                .ASYNC                  (RASYNC),
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
                .REQUEST_WIDTH          (CAPACITY_WIDTH),
                .ISSUE_WIDTH            (CAPACITY_WIDTH),
                .REQUEST_SIZE_OFFSET    (1'b0),
                .ISSUE_SIZE_OFFSET      (1'b0)
            )
        i_capacity_async
            (
                .s_reset                (~s_rresetn),
                .s_clk                  (s_rclk),
                .s_request_size         (s_rfifo_rd_size),
                .s_request_valid        (s_rfifo_rd_signal),
                .s_queued_request       (),
                
                .m_reset                (~m_aresetn),
                .m_clk                  (m_aclk),
                .m_issue_size           (rfifo_rd_size),
                .m_issue_valid          (rfifo_rd_valid),
                .m_issue_ready          (rfifo_rd_ready),
                .m_queued_request       ()
            );
    
    
    // ---------------------------------
    //  Read command capacity control
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
                .SIZE_OFFSET            (S_ARLEN_OFFSET),
                .LEN_OFFSET             (1'b1),
                .S_REGS                 (1)
            )
         i_address_generator
            (
                .reset                  (~m_aresetn),
                .clk                    (m_aclk),
                .cke                    (1'b1),
                
                .s_addr                 (arfifo_addr),
                .s_size                 (arfifo_len),
                .s_max_len              (arfifo_arlen_max),
                .s_valid                (arfifo_valid),
                .s_ready                (arfifo_ready),
                
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
                
                .initial_capacity       (1 << RFIFO_PTR_WIDTH),
                .current_capacity       (),
                
                .s_charge_size          (rfifo_rd_size),
                .s_charge_valid         (rfifo_rd_valid & rfifo_rd_ready),
                
                .s_cmd_user             ({adrgen_last, adrgen_addr}),
                .s_cmd_size             (adrgen_len),
                .s_cmd_valid            (adrgen_valid),
                .s_cmd_ready            (adrgen_ready),
                
                .m_cmd_user             ({capsiz_last, capsiz_addr}),
                .m_cmd_size             (capsiz_len),
                .m_cmd_valid            (capsiz_valid),
                .m_cmd_ready            (capsiz_ready)
            );
    
    assign rfifo_rd_ready = 1'b1;
    
    
    
    // AXI4スケールに変換
    wire    [AXI4_ADDR_WIDTH-1:0]   capsiz_araddr;
    wire    [AXI4_LEN_WIDTH-1:0]    capsiz_arlen;
    wire                            capsiz_arlast;
    wire                            capsiz_arvalid;
    wire                            capsiz_arready;
    
    assign capsiz_araddr  = (capsiz_addr << AXI4_DATA_SIZE);
    assign capsiz_arlen   = capsiz_len;
    assign capsiz_arlast  = capsiz_last;
    assign capsiz_arvalid = capsiz_valid;
    assign capsiz_ready   = capsiz_arready;
    
    
    
    // 4kアライメント処理
    wire    [AXI4_ADDR_WIDTH-1:0]   align_araddr;
    wire                            align_arlast;
    wire    [AXI4_LEN_WIDTH-1:0]    align_arlen;
    wire                            align_arvalid;
    wire                            align_arready;
    
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
                
                .s_user                 (capsiz_arlast),
                .s_addr                 (capsiz_araddr),
                .s_len                  (capsiz_arlen),
                .s_valid                (capsiz_arvalid),
                .s_ready                (capsiz_arready),
                
                .m_user                 (align_arlast),
                .m_addr                 (align_araddr),
                .m_len                  (align_arlen),
                .m_valid                (align_arvalid),
                .m_ready                (align_arready)
            );
    
    
    
    // ---------------------------------
    //  address command split
    // ---------------------------------
    
    // コマンド発行用と終了管理用に2分岐させる
    wire    [AXI4_ADDR_WIDTH-1:0]           cmd0_araddr;
    wire                                    cmd0_arlast;
    wire    [AXI4_LEN_WIDTH-1:0]            cmd0_arlen;
    wire                                    cmd0_arvalid;
    wire                                    cmd0_arready;
    
    wire    [AXI4_ADDR_WIDTH-1:0]           cmd1_araddr;
    wire                                    cmd1_arlast;
    wire    [AXI4_LEN_WIDTH-1:0]            cmd1_arlen;
    wire                                    cmd1_arvalid;
    wire                                    cmd1_arready;
    
    jelly_data_spliter
            #(
                .NUM            (2),
                .DATA_WIDTH     (AXI4_ADDR_WIDTH+1+AXI4_LEN_WIDTH),
                .S_REGS         (0),
                .M_REGS         (0)
            )
        i_data_spliter
            (
                .reset          (~m_aresetn),
                .clk            (m_aclk),
                .cke            (1'b1),
                
                .s_data         ({2{align_araddr, align_arlast, align_arlen}}),
                .s_valid        (align_arvalid),
                .s_ready        (align_arready),
                
                .m_data         ({{cmd1_araddr, cmd1_arlast, cmd1_arlen}, {cmd0_araddr, cmd0_arlast, cmd0_arlen}}),
                .m_valid        ({ cmd1_arvalid,                           cmd0_arvalid}),
                .m_ready        ({ cmd1_arready,                           cmd0_arready})
            );
    
    
    // ar
    assign m_axi4_arid     = AXI4_ARID;
    assign m_axi4_araddr   = cmd0_araddr;
    assign m_axi4_arlen    = cmd0_arlen;
    assign m_axi4_arsize   = AXI4_ARSIZE;
    assign m_axi4_arburst  = AXI4_ARBURST;
    assign m_axi4_arlock   = AXI4_ARLOCK;
    assign m_axi4_arcache  = AXI4_ARCACHE;
    assign m_axi4_arprot   = AXI4_ARPROT;
    assign m_axi4_arqos    = AXI4_ARQOS;
    assign m_axi4_arregion = AXI4_ARREGION;
    assign m_axi4_arvalid  = cmd0_arvalid;
    assign cmd0_arready    = m_axi4_arready;
    
    
    // ---------------------------------
    //  data
    // ---------------------------------
    
    wire                                rcmd_arlast;
    wire                                rcmd_arvalid;
    wire                                rcmd_arready;
    
    jelly_fifo_fwtf
            #(
                .DATA_WIDTH                 (1'b1),
                .PTR_WIDTH                  (RCMD_FIFO_PTR_WIDTH),
                .DOUT_REGS                  (RCMD_FIFO_DOUT_REGS),
                .RAM_TYPE                   (RCMD_FIFO_RAM_TYPE),
                .LOW_DEALY                  (RCMD_FIFO_LOW_DEALY),
                .SLAVE_REGS                 (RCMD_FIFO_S_REGS),
                .MASTER_REGS                (RCMD_FIFO_M_REGS)
            )
        i_fifo_fwtf_rcmd
            (
                .reset                      (~m_aresetn),
                .clk                        (m_aclk),
                
                .s_data                     (cmd1_arlast),
                .s_valid                    (cmd1_arvalid),
                .s_ready                    (cmd1_arready),
                .s_free_count               (),
                
                .m_data                     (rcmd_arlast),
                .m_valid                    (rcmd_arvalid),
                .m_ready                    (rcmd_arready),
                .m_data_count               ()
            );
    
    assign rcmd_arready  = m_axi4_rvalid & m_axi4_rready && m_axi4_rlast;
    assign m_axi4_rready = rcmd_arvalid;
    
    assign rfifo_rlast   = m_axi4_rlast & rcmd_arlast;
    assign rfifo_rdata   = m_axi4_rdata;
    assign rfifo_rvalid  = m_axi4_rvalid & m_axi4_rready;
    
    
    
endmodule


`default_nettype wire


// end of file
