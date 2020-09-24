// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// N次元アドレッシング(軸毎にアドレスbit数を変えられるように設計)


// AXI4 データ読出しコア
module jelly_axi4_read_2d
        #(
            parameter   N                    = 1,
            
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
            parameter   S_ARSTEP_WIDTH       = AXI4_ADDR_WIDTH,
            parameter   S_ARLEN_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   S_ARLEN_OFFSET       = 1'b1,
            
            parameter   ARLEN_WIDTH          = AXI4_ADDR_WIDTH,   // 内部キューイング用
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
            parameter   MRFIFO_M_REGS        = 0,
            
            parameter   RFLAGFIFO_PTR_WIDTH  = 4,
            parameter   RFLAGFIFO_DOUT_REGS  = 0,
            parameter   RFLAGFIFO_RAM_TYPE   = "distributed",
            parameter   RFLAGFIFO_LOW_DEALY  = 1,
            parameter   RFLAGFIFO_S_REGS     = 0,
            parameter   RFLAGFIFO_M_REGS     = 0,
            parameter   SYNCFLAG_S_REGS      = 0,
            parameter   SYNCFLAG_M_REGS      = 1
        )
        (
            input   wire                            endian,
            
            input   wire                            s_arresetn,
            input   wire                            s_arclk,
            input   wire    [AXI4_ADDR_WIDTH-1:0]   s_araddr,
            input   wire    [AXI4_LEN_WIDTH-1:0]    s_arlen_max,
            input   wire    [N*S_ARSTEP_WIDTH-1:0]  s_arstep,       // step0は無視(1固定、つまり連続アクセスのみ)
            input   wire    [N*S_ARLEN_WIDTH-1:0]   s_arlen,
            input   wire                            s_arvalid,
            output  wire                            s_arready,
            
            input   wire                            s_rresetn,
            input   wire                            s_rclk,
            output  wire    [S_RDATA_WIDTH-1:0]     s_rdata,
            output  wire    [N-1:0]                 s_rfirst,
            output  wire    [N-1:0]                 s_rlast,
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
    
    
    wire    [AXI4_ADDR_WIDTH-1:0]   adrgen_araddr;
    wire    [ARLEN_WIDTH-1:0]       adrgen_arlen;
    wire    [AXI4_LEN_WIDTH-1:0]    adrgen_arlen_max;
    wire    [N-1:0]                 adrgen_arfirst;
    wire    [N-1:0]                 adrgen_arlast;
    wire                            adrgen_arvalid;
    wire                            adrgen_arready;
    
    generate
    if ( N >= 2 ) begin : blk_adrgen_nd
        // 2D以上のアドレッシング
        
        wire    [(N-1)*ARSTEP_WIDTH-1:0]    tmp_arstep;
        wire    [(N-1)*ARLEN_WIDTH-1:0]     tmp_arlen;
        
        jelly_address_generator_nd
                #(
                    .N                      (N-1),
                    .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                    .STEP_WIDTH             (S_ARSTEP_WIDTH),
                    .LEN_WIDTH              (S_ARLEN_WIDTH),
                    .LEN_OFFSET             (S_ARLEN_OFFSET),
                    .USER_WIDTH             (S_ARLEN0_WIDTH + AXI4_LEN_WIDTH)
                )
            i_address_generator_nd
                (
                    .reset                  (~s_arresetn),
                    .clk                    (s_arclk),
                    .cke                    (1'b1),
                    
                    .s_addr                 (s_araddr),
                    .s_step                 (s_arstep[N*S_ARSTEP_WIDTH-1:S_ARSTEP_WIDTH]),
                    .s_len                  (s_arlen [N*S_ARLEN_WIDTH-1:S_ARLEN_WIDTH]),
                    .s_user                 ({s_arlen[ARLEN_WIDTH-1:0], s_arlen_max}),
                    .s_valid                (s_arvalid),
                    .s_ready                (s_arready),
                    
                    .m_addr                 (adrgen_addr),
                    .m_first                (adrgen_arfirst[N-1:1]),
                    .m_last                 (adrgen_arlast[N-1:1]),
                    .m_user                 ({adrgen_arlen, adrgen_arlen_max}),
                    .m_valid                (adrgen_valid),
                    .m_ready                (adrgen_ready)
                );
            assign adrgen_arfirst[0] = 1'b1;
            assign adrgen_arlast[0]  = 1'b1;
    end
    else begin : blk_adrgen_1d
        // 1D
        assign adrgen_araddr    = s_araddr;
        assign adrgen_arlen     = s_arlen[ARLEN_WIDTH-1:0];
        assign adrgen_arlen_max = s_arlen_max;
        assign adrgen_arfirst   = 1'b1;
        assign adrgen_arlast    = 1'b1;
        assign adrgen_arvalid   = adrgen_valid;
        assign s_arready        = adrgen_arready;
    end
    endgenerate
    
    
    // read
    wire    [S_RDATA_WIDTH-1:0]     read_rdata;
    wire                            read_rfirst;
    wire                            read_rlast;
    wire                            read_rvalid;
    wire                            read_rready;
    
    jelly_axi4_read
            #(
                .ARASYNC                (ARASYNC),
                .RASYNC                 (RASYNC),
                .BYTE_WIDTH             (BYTE_WIDTH),
                .BYPASS_GATE            (BYPASS_GATE),
                .BYPASS_ALIGN           (BYPASS_ALIGN),
                .AXI4_ALIGN             (AXI4_ALIGN),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED),
                .HAS_S_RFIRST           (HAS_S_RFIRST),
                .HAS_S_RLAST            (HAS_S_RLAST),
                .HAS_M_RFIRST           (HAS_M_RFIRST),
                .HAS_M_RLAST            (HAS_M_RLAST),
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH),
                .AXI4_ARID              (AXI4_ARID),
                .AXI4_ARSIZE            (AXI4_ARSIZE),
                .AXI4_ARBURST           (AXI4_ARBURST),
                .AXI4_ARLOCK            (AXI4_ARLOCK),
                .AXI4_ARCACHE           (AXI4_ARCACHE),
                .AXI4_ARPROT            (AXI4_ARPROT),
                .AXI4_ARQOS             (AXI4_ARQOS),
                .AXI4_ARREGION          (AXI4_ARREGION),
                .S_RDATA_WIDTH          (S_RDATA_WIDTH),
                .S_ARLEN_WIDTH          (S_ARLEN_MAX),
                .S_ARLEN_OFFSET         (S_ARLEN_OFFSET),
                .ARLEN_WIDTH            (ARLEN_WIDTH),
                .ARLEN_OFFSET           (ARLEN_OFFSET),
                .CONVERT_S_REGS         (CONVERT_S_REGS),
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
            )
        i_axi4_read
            (
                .endian                 (endian),
                
                .s_arresetn             (s_arresetn),
                .s_arclk                (s_arclk),
                .s_araddr               (adrgen_araddr),
                .s_arlen                (adrgen_arlen),
                .s_arlen_max            (adrgen_arlen_max),
                .s_arvalid              (adrgen_arvalid),
                .s_arready              (adrgen_arready),
                
                .s_rresetn              (s_rresetn),
                .s_rclk                 (s_rclk),
                .s_rdata                (read_rdata),
                .s_rfirst               (read_rfirst),
                .s_rlast                (read_rlast),
                .s_rvalid               (read_rvalid),
                .s_rready               (read_rready),
                
                .m_aresetn              (m_aresetn),
                .m_aclk                 (m_aclk),
                .m_axi4_arid            (m_axi4_arid),
                .m_axi4_araddr          (m_axi4_araddr),
                .m_axi4_arlen           (m_axi4_arlen),
                .m_axi4_arsize          (m_axi4_arsize),
                .m_axi4_arburst         (m_axi4_arburst),
                .m_axi4_arlock          (m_axi4_arlock),
                .m_axi4_arcache         (m_axi4_arcache),
                .m_axi4_arprot          (m_axi4_arprot),
                .m_axi4_arqos           (m_axi4_arqos),
                .m_axi4_arregion        (m_axi4_arregion),
                .m_axi4_arvalid         (m_axi4_arvalid),
                .m_axi4_arready         (m_axi4_arready),
                .m_axi4_rid             (m_axi4_rid),
                .m_axi4_rdata           (m_axi4_rdata),
                .m_axi4_rresp           (m_axi4_rresp),
                .m_axi4_rlast           (m_axi4_rlast),
                .m_axi4_rvalid          (m_axi4_rvalid),
                .m_axi4_rready          (m_axi4_rready)
            );
    
    
    // フラグ付与
    generate
    if ( N >= 2 ) begin : blk_read_nd
        jelly_stream_add_syncflag
                #(
                    .FIRST_WIDTH        (N),
                    .LAST_WIDTH         (N),
                    .USER_WIDTH         (S_RDATA_WIDTH),
                    
                    .HAS_FIRST          (1),
                    .HAS_LAST           (1),
                    
                    .ASYNC              (ARASYNC || RASYNC),
                    .FIFO_PTR_WIDTH     (RFLAGFIFO_PTR_WIDTH),
                    .FIFO_DOUT_REGS     (RFLAGFIFO_DOUT_REGS),
                    .FIFO_RAM_TYPE      (RFLAGFIFO_RAM_TYPE),
                    .FIFO_LOW_DEALY     (RFLAGFIFO_LOW_DEALY),
                    .FIFO_S_REGS        (RFLAGFIFO_S_REGS),
                    .FIFO_M_REGS        (RFLAGFIFO_M_REGS),
                    
                    .S_REGS             (SYNCFLAG_S_REGS),
                    .M_REGS             (SYNCFLAG_M_REGS)
                )
            i_stream_add_syncflag
                (
                    .reset                  (~s_arresetn),
                    .clk                    (s_arclk),
                    .cke                    (1'b1),
                    
                    .s_first                (read_first),
                    .s_last                 (read_last),
                    .s_user                 (read_user),
                    .s_valid                (read_valid),
                    .s_ready                (read_ready),
                    
                    .m_first                (),
                    .m_last                 (),
                    .m_added_first          (s_rfirst),
                    .m_added_last           (s_rlast),
                    .m_user                 (s_rdata),
                    .m_valid                (s_rvalid),
                    .m_ready                (s_rready),
                    
                    .s_add_reset            (~s_arresetn),
                    .s_add_clk              (s_arclk),
                    .s_add_first            (cmd1_first),
                    .s_add_last             (cmd1_last),
                    .s_add_valid            (cmd1_valid),
                    .s_add_ready            (cmd1_ready)
                );
    end
    else begin  : blk_read_1d
        assign s_rfirst   = read_first;
        assign s_rlast    = read_last;
        assign s_rdata    = read_user;
        assign s_rvalid   = read_valid;
        assign read_ready = s_rready;
        assign cmd1_ready = 1'b1;
    end
    
    
    
endmodule


`default_nettype wire


// end of file
