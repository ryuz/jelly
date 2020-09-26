// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// AXI4 N次元データ読出しコア
module jelly_axi4_read_nd
        #(
            parameter N                   = 1,
            
            parameter ARASYNC             = 1,
            parameter RASYNC              = 1,
            parameter RBASYNC             = 1,
            
            parameter BYTE_WIDTH          = 8,
            parameter BYPASS_GATE         = 1,
            parameter BYPASS_ALIGN        = 0,
            parameter AXI4_ALIGN          = 12,  // 2^12 = 4k が境界
            parameter ALLOW_UNALIGNED     = 0,
            
            parameter HAS_S_RFIRST        = 0,
            parameter HAS_S_RLAST         = 0,
            parameter HAS_M_RFIRST        = 0,
            parameter HAS_M_RLAST         = 1,
            
            parameter AXI4_ID_WIDTH       = 6,
            parameter AXI4_ADDR_WIDTH     = 32,
            parameter AXI4_DATA_SIZE      = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter AXI4_DATA_WIDTH     = (BYTE_WIDTH << AXI4_DATA_SIZE),
            parameter AXI4_LEN_WIDTH      = 8,
            parameter AXI4_QOS_WIDTH      = 4,
            parameter AXI4_ARID           = {AXI4_ID_WIDTH{1'b0}},
            parameter AXI4_ARSIZE         = AXI4_DATA_SIZE,
            parameter AXI4_ARBURST        = 2'b01,
            parameter AXI4_ARLOCK         = 1'b0,
            parameter AXI4_ARCACHE        = 4'b0001,
            parameter AXI4_ARPROT         = 3'b000,
            parameter AXI4_ARQOS          = 0,
            parameter AXI4_ARREGION       = 4'b0000,
            
            parameter S_RDATA_WIDTH       = 32,
            parameter S_ARSTEP_WIDTH      = AXI4_ADDR_WIDTH,
            parameter S_ARLEN_WIDTH       = AXI4_ADDR_WIDTH,
            parameter S_ARLEN_OFFSET      = 1'b1,
            
            parameter ARLEN_WIDTH         = AXI4_ADDR_WIDTH,   // 内部キューイング用
            parameter ARLEN_OFFSET        = S_ARLEN_OFFSET,
            
            parameter CONVERT_S_REGS      = 0,
            
            parameter RFIFO_PTR_WIDTH     = 9,
            parameter RFIFO_RAM_TYPE      = "block",
            parameter RFIFO_LOW_DEALY     = 0,
            parameter RFIFO_DOUT_REGS     = 1,
            parameter RFIFO_S_REGS        = 0,
            parameter RFIFO_M_REGS        = 1,
            
            parameter ARFIFO_PTR_WIDTH    = 4,
            parameter ARFIFO_RAM_TYPE     = "distributed",
            parameter ARFIFO_LOW_DEALY    = 1,
            parameter ARFIFO_DOUT_REGS    = 0,
            parameter ARFIFO_S_REGS       = 0,
            parameter ARFIFO_M_REGS       = 0,
            
            parameter SRFIFO_PTR_WIDTH    = 4,
            parameter SRFIFO_RAM_TYPE     = "distributed",
            parameter SRFIFO_LOW_DEALY    = 0,
            parameter SRFIFO_DOUT_REGS    = 0,
            parameter SRFIFO_S_REGS       = 0,
            parameter SRFIFO_M_REGS       = 0,
            
            parameter MRFIFO_PTR_WIDTH    = 4,
            parameter MRFIFO_RAM_TYPE     = "distributed",
            parameter MRFIFO_LOW_DEALY    = 1,
            parameter MRFIFO_DOUT_REGS    = 0,
            parameter MRFIFO_S_REGS       = 0,
            parameter MRFIFO_M_REGS       = 0,
            
            parameter RACKFIFO_PTR_WIDTH  = 4,
            parameter RACKFIFO_DOUT_REGS  = 0,
            parameter RACKFIFO_RAM_TYPE   = "distributed",
            parameter RACKFIFO_LOW_DEALY  = 1,
            parameter RACKFIFO_S_REGS     = 0,
            parameter RACKFIFO_M_REGS     = 0,
            parameter RACK_S_REGS         = 0,
            parameter RACK_M_REGS         = 1,
            
            parameter RBACKFIFO_PTR_WIDTH = 4,
            parameter RBACKFIFO_DOUT_REGS = 0,
            parameter RBACKFIFO_RAM_TYPE  = "distributed",
            parameter RBACKFIFO_LOW_DEALY = 1,
            parameter RBACKFIFO_S_REGS    = 0,
            parameter RBACKFIFO_M_REGS    = 0,
            parameter RBACK_S_REGS        = 0,
            parameter RBACK_M_REGS        = 1
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
            
            input   wire                            s_rbresetn,
            input   wire                            s_rbclk,
            output  wire    [N-1:0]                 s_rbfirst,
            output  wire    [N-1:0]                 s_rblast,
            output  wire                            s_rbvalid,
            input   wire                            s_rbready,
            
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
    
    // command
    wire    [AXI4_ADDR_WIDTH-1:0]   cmd_araddr;
    wire    [ARLEN_WIDTH-1:0]       cmd_arlen;
    wire    [AXI4_LEN_WIDTH-1:0]    cmd_arlen_max;
    wire                            cmd_arvalid;
    wire                            cmd_arready;
    
    // read
    wire    [S_RDATA_WIDTH-1:0]     read_rdata;
    wire                            read_rfirst;
    wire                            read_rlast;
    wire                            read_rvalid;
    wire                            read_rready;
    
    wire                            read_rbvalid;
    wire                            read_rbready;
    
    generate
    if ( N >= 2 ) begin : blk_adrgen_nd
        // 2D以上のアドレッシング
        
        wire    [AXI4_ADDR_WIDTH-1:0]   adrgen_araddr;
        wire    [ARLEN_WIDTH-1:0]       adrgen_arlen;
        wire    [AXI4_LEN_WIDTH-1:0]    adrgen_arlen_max;
        wire    [N-1:0]                 adrgen_arfirst;
        wire    [N-1:0]                 adrgen_arlast;
        wire                            adrgen_arvalid;
        wire                            adrgen_arready;
        
        wire    [N-1:0]                 ack0_arfirst;
        wire    [N-1:0]                 ack0_arlast;
        wire                            ack0_arvalid;
        wire                            ack0_arready;
        
        wire    [N-1:0]                 ack1_arfirst;
        wire    [N-1:0]                 ack1_arlast;
        wire                            ack1_arvalid;
        wire                            ack1_arready;
        
        jelly_address_generator_nd
                #(
                    .N                      (N-1),
                    .ADDR_WIDTH             (AXI4_ADDR_WIDTH),
                    .STEP_WIDTH             (S_ARSTEP_WIDTH),
                    .LEN_WIDTH              (S_ARLEN_WIDTH),
                    .LEN_OFFSET             (S_ARLEN_OFFSET),
                    .USER_WIDTH             (S_ARLEN_WIDTH + AXI4_LEN_WIDTH)
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
                    
                    .m_addr                 (adrgen_araddr),
                    .m_first                (adrgen_arfirst[N-1:1]),
                    .m_last                 (adrgen_arlast[N-1:1]),
                    .m_user                 ({adrgen_arlen, adrgen_arlen_max}),
                    .m_valid                (adrgen_arvalid),
                    .m_ready                (adrgen_arready)
                );
        assign adrgen_arfirst[0] = 1'b1;
        assign adrgen_arlast[0]  = 1'b1;
        
        // コマンド分割
        jelly_data_split_pack2
                #(
                    .NUM                    (3),
                    .DATA0_0_WIDTH          (AXI4_ADDR_WIDTH),
                    .DATA0_1_WIDTH          (ARLEN_WIDTH),
                    .DATA0_2_WIDTH          (AXI4_LEN_WIDTH),
                    .DATA1_0_WIDTH          (N),
                    .DATA1_1_WIDTH          (N),
                    .DATA2_0_WIDTH          (N),
                    .DATA2_1_WIDTH          (N)
                )
            i_data_split_pack2
                (
                    .reset                  (~s_arresetn),
                    .clk                    (s_arclk),
                    .cke                    (1'b1),
                    
                    .s_data0_0              (adrgen_araddr),
                    .s_data0_1              (adrgen_arlen),
                    .s_data0_2              (adrgen_arlen_max),
                    .s_data1_0              (adrgen_arfirst),
                    .s_data1_1              (adrgen_arlast),
                    .s_data2_0              (adrgen_arfirst),
                    .s_data2_1              (adrgen_arlast),
                    .s_valid                (adrgen_arvalid),
                    .s_ready                (adrgen_arready),
                    
                    .m0_data0               (cmd_araddr),
                    .m0_data1               (cmd_arlen),
                    .m0_data2               (cmd_arlen_max),
                    .m0_valid               (cmd_arvalid),
                    .m0_ready               (cmd_arready),
                    
                    .m1_data0               (ack0_arfirst),
                    .m1_data1               (ack0_arlast),
                    .m1_valid               (ack0_arvalid),
                    .m1_ready               (ack0_arready),
                    
                    .m2_data0               (ack1_arfirst),
                    .m2_data1               (ack1_arlast),
                    .m2_valid               (ack1_arvalid),
                    .m2_ready               (ack1_arready)
                );
        
        // r ポートにフラグ付与
        jelly_stream_add_syncflag
                #(
                    .FIRST_WIDTH            (N),
                    .LAST_WIDTH             (N),
                    .USER_WIDTH             (S_RDATA_WIDTH),
                    .HAS_FIRST              (1),
                    .HAS_LAST               (1),
                    .ASYNC                  (ARASYNC || RASYNC),
                    .FIFO_PTR_WIDTH         (RACKFIFO_PTR_WIDTH),
                    .FIFO_DOUT_REGS         (RACKFIFO_DOUT_REGS),
                    .FIFO_RAM_TYPE          (RACKFIFO_RAM_TYPE),
                    .FIFO_LOW_DEALY         (RACKFIFO_LOW_DEALY),
                    .FIFO_S_REGS            (RACKFIFO_S_REGS),
                    .FIFO_M_REGS            (RACKFIFO_M_REGS),
                    
                    .S_REGS                 (RACK_S_REGS),
                    .M_REGS                 (RACK_M_REGS)
                )
            i_stream_add_syncflag_r
                (
                    .reset                  (~s_rresetn),
                    .clk                    (s_rclk),
                    .cke                    (1'b1),
                    
                    .s_first                (read_rfirst),
                    .s_last                 (read_rlast),
                    .s_user                 (read_rdata),
                    .s_valid                (read_rvalid),
                    .s_ready                (read_rready),
                    
                    .m_first                (),
                    .m_last                 (),
                    .m_added_first          (s_rfirst),
                    .m_added_last           (s_rlast),
                    .m_user                 (s_rdata),
                    .m_valid                (s_rvalid),
                    .m_ready                (s_rready),
                    
                    .s_add_reset            (~s_arresetn),
                    .s_add_clk              (s_arclk),
                    .s_add_first            (ack0_arfirst),
                    .s_add_last             (ack0_arlast),
                    .s_add_valid            (ack0_arvalid),
                    .s_add_ready            (ack0_arready)
                );
        
        // rb ポートにフラグ付与
        jelly_stream_add_syncflag
                #(
                    .FIRST_WIDTH            (N),
                    .LAST_WIDTH             (N),
                    .USER_WIDTH             (0),
                    .HAS_FIRST              (1),
                    .HAS_LAST               (1),
                    .ASYNC                  (ARASYNC || RASYNC),
                    .FIFO_PTR_WIDTH         (RBACKFIFO_PTR_WIDTH),
                    .FIFO_DOUT_REGS         (RBACKFIFO_DOUT_REGS),
                    .FIFO_RAM_TYPE          (RBACKFIFO_RAM_TYPE),
                    .FIFO_LOW_DEALY         (RBACKFIFO_LOW_DEALY),
                    .FIFO_S_REGS            (RBACKFIFO_S_REGS),
                    .FIFO_M_REGS            (RBACKFIFO_M_REGS),
                    .S_REGS                 (RBACK_S_REGS),
                    .M_REGS                 (RBACK_M_REGS)
                )
            i_stream_add_syncflag_rb
                (
                    .reset                  (~s_rbresetn),
                    .clk                    (s_rbclk),
                    .cke                    (1'b1),
                    
                    .s_first                (1'b1),
                    .s_last                 (1'b1),
                    .s_user                 (1'b0),
                    .s_valid                (read_rbvalid),
                    .s_ready                (read_rbready),
                    
                    .m_first                (),
                    .m_last                 (),
                    .m_added_first          (s_rbfirst),
                    .m_added_last           (s_rblast),
                    .m_user                 (),
                    .m_valid                (s_rbvalid),
                    .m_ready                (s_rbready),
                    
                    .s_add_reset            (~s_arresetn),
                    .s_add_clk              (s_arclk),
                    .s_add_first            (ack1_arfirst),
                    .s_add_last             (ack1_arlast),
                    .s_add_valid            (ack1_arvalid),
                    .s_add_ready            (ack1_arready)
                );
        
    end
    else begin : blk_adrgen_1d
        // 1D
        assign cmd_araddr    = s_araddr;
        assign cmd_arlen     = s_arlen[ARLEN_WIDTH-1:0];
        assign cmd_arlen_max = s_arlen_max;
        assign cmd_arvalid   = s_arvalid;
        assign s_arready     = cmd_arready;
        
        assign s_rfirst      = read_rfirst;
        assign s_rlast       = read_rlast;
        assign s_rdata       = read_rdata;
        assign s_rvalid      = read_rvalid;
        assign read_rready   = s_rready;
    end
    endgenerate
    
    
    // read
    jelly_axi4_read
            #(
                .ARASYNC                (ARASYNC),
                .RASYNC                 (RASYNC),
                .BYTE_WIDTH             (BYTE_WIDTH),
                .BYPASS_GATE            (BYPASS_GATE && N==1),
                .BYPASS_ALIGN           (BYPASS_ALIGN),
                .AXI4_ALIGN             (AXI4_ALIGN),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED),
                .HAS_S_RFIRST           (1),
                .HAS_S_RLAST            (1),
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
                .S_ARLEN_WIDTH          (AXI4_ADDR_WIDTH),
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
                .MRFIFO_M_REGS          (MRFIFO_M_REGS)
            )
        i_axi4_read
            (
                .endian                 (endian),
                
                .s_arresetn             (s_arresetn),
                .s_arclk                (s_arclk),
                .s_araddr               (cmd_araddr),
                .s_arlen                (cmd_arlen),
                .s_arlen_max            (cmd_arlen_max),
                .s_arvalid              (cmd_arvalid),
                .s_arready              (cmd_arready),
                
                .s_rresetn              (s_rresetn),
                .s_rclk                 (s_rclk),
                .s_rdata                (read_rdata),
                .s_rfirst               (read_rfirst),
                .s_rlast                (read_rlast),
                .s_rvalid               (read_rvalid),
                .s_rready               (read_rready),
                
                .s_rbresetn             (s_rbresetn),
                .s_rbclk                (s_rbclk),
                .s_rbvalid              (read_rbvalid),
                .s_rbready              (read_rbready),
                
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
    
    
endmodule


`default_nettype wire


// end of file
