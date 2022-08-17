// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2017 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_texture_cache_l2
        #(
            parameter   int                             COMPONENT_NUM          = 3,
            parameter   int                             COMPONENT_DATA_WIDTH   = 8,
            parameter   int                             COMPONENT_DATA_SIZE    = $clog2(COMPONENT_DATA_WIDTH/8),

            parameter   int                             ADDR_WIDTH             = 24,
            parameter   int                             STRIDE_C_WIDTH         = 14,
            parameter   int                             STRIDE_X_WIDTH         = 14,
            parameter   int                             STRIDE_Y_WIDTH         = 14,

            parameter   int                             PARALLEL_SIZE          = 2,     // 0:1, 1:2, 2:4, 2:4, 3:8 ....
            parameter   int                             ADDR_X_WIDTH           = 12,
            parameter   int                             ADDR_Y_WIDTH           = 12,
            parameter   int                             BLK_X_SIZE             = 3, // 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
            parameter   int                             BLK_Y_SIZE             = 3, // 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
            parameter   int                             WAY_NUM                = 1,
            parameter   int                             TAG_ADDR_WIDTH         = 6,
            parameter                                   TAG_RAM_TYPE           = "distributed",
            parameter                                   TAG_ALGORITHM          = PARALLEL_SIZE > 0 ? "SUDOKU" : "TWIST",
            parameter   bit                             TAG_M_SLAVE_REGS       = 0,
            parameter   bit                             TAG_M_MASTER_REGS      = 0,
            parameter                                   MEM_RAM_TYPE           = "block",

            parameter   bit                             USE_LOOK_AHEAD         = 0,
            parameter   bit                             USE_S_RREADY           = 1, // 0: s_rready is always 1'b1.   1: handshake mode.
            parameter   bit                             USE_M_RREADY           = 0, // 0: m_rready is always 1'b1.   1: handshake mode.

            parameter   int                             S_NUM                  = 8,
            parameter   int                             S_DATA_SIZE            = 1,
            parameter   int                             S_BLK_X_NUM            = 2,
            parameter   int                             S_BLK_Y_NUM            = 2,
            
            parameter   int                             M_AXI4_ID_WIDTH        = 6,
            parameter   int                             M_AXI4_ADDR_WIDTH      = 32,
            parameter   int                             M_AXI4_DATA_SIZE       = 3,  // 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
            parameter   int                             M_AXI4_DATA_WIDTH      = (8 << M_AXI4_DATA_SIZE),
            parameter   int                             M_AXI4_LEN_WIDTH       = 8,
            parameter   int                             M_AXI4_QOS_WIDTH       = 4,
            parameter   bit     [M_AXI4_ID_WIDTH-1:0]   M_AXI4_ARID            = {M_AXI4_ID_WIDTH{1'b0}},
            parameter   bit     [2:0]                   M_AXI4_ARSIZE          = 3'(M_AXI4_DATA_SIZE),
            parameter   bit     [1:0]                   M_AXI4_ARBURST         = 2'b01,
            parameter   bit     [0:0]                   M_AXI4_ARLOCK          = 1'b0,
            parameter   bit     [3:0]                   M_AXI4_ARCACHE         = 4'b0001,
            parameter   bit     [2:0]                   M_AXI4_ARPROT          = 3'b000,
            parameter   bit     [M_AXI4_QOS_WIDTH-1:0]  M_AXI4_ARQOS           = 0,
            parameter   bit     [3:0]                   M_AXI4_ARREGION        = 4'b0000,
            parameter   bit                             M_AXI4_REGS            = 1,
            
            parameter   int                             QUE_FIFO_PTR_WIDTH     = USE_LOOK_AHEAD ? BLK_Y_SIZE + BLK_X_SIZE : 0,
            parameter                                   QUE_FIFO_RAM_TYPE      = "distributed",
            parameter   bit                             QUE_FIFO_S_REGS        = 0,
            parameter   bit                             QUE_FIFO_M_REGS        = 0,
            
            parameter   int                             AR_FIFO_PTR_WIDTH      = 0,
            parameter                                   AR_FIFO_RAM_TYPE       = "distributed",
            parameter   bit                             AR_FIFO_S_REGS         = 0,
            parameter   bit                             AR_FIFO_M_REGS         = 0,
            
            parameter   int                             R_FIFO_PTR_WIDTH       = BLK_Y_SIZE + BLK_X_SIZE - (M_AXI4_DATA_SIZE - COMPONENT_DATA_SIZE),
            parameter                                   R_FIFO_RAM_TYPE        = "distributed",
            parameter   bit                             R_FIFO_S_REGS          = 0,
            parameter   bit                             R_FIFO_M_REGS          = 0,

            parameter   int                             DMA_QUE_FIFO_PTR_WIDTH = 6,
            parameter                                   DMA_QUE_FIFO_RAM_TYPE  = "distributed",
            parameter   bit                             DMA_QUE_FIFO_S_REGS    = 0,
            parameter   bit                             DMA_QUE_FIFO_M_REGS    = 1,     
            parameter   bit                             DMA_S_AR_REGS          = 1,
            parameter   bit                             DMA_S_R_REGS           = 1,
            
            parameter   bit                             LOG_ENABLE             = 0,
            parameter                                   LOG_FILE               = "cache_log.txt",
            parameter   int                             LOG_ID                 = 0,
            
            // local
            localparam  int                             CACHE_NUM              = (1 << PARALLEL_SIZE),
            localparam  int                             S_DATA_WIDTH           = ((COMPONENT_NUM * COMPONENT_DATA_WIDTH) << S_DATA_SIZE)
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,

            input   wire                                    endian,

            input   wire    [M_AXI4_ADDR_WIDTH-1:0]         param_addr,
            input   wire    [M_AXI4_LEN_WIDTH-1:0]          param_arlen,
            input   wire    [STRIDE_C_WIDTH-1:0]            param_stride_c,
            input   wire    [STRIDE_X_WIDTH-1:0]            param_stride_x,
            input   wire    [STRIDE_Y_WIDTH-1:0]            param_stride_y,

            input   wire                                    clear_start,
            output  wire                                    clear_busy,

            output  wire    [CACHE_NUM-1:0]                 status_idle,
            output  wire    [CACHE_NUM-1:0]                 status_stall,
            output  wire    [CACHE_NUM-1:0]                 status_access,
            output  wire    [CACHE_NUM-1:0]                 status_hit,
            output  wire    [CACHE_NUM-1:0]                 status_miss,
            output  wire    [CACHE_NUM-1:0]                 status_blank,
            
            input   wire    [S_NUM-1:0][ADDR_X_WIDTH-1:0]   s_araddrx,
            input   wire    [S_NUM-1:0][ADDR_Y_WIDTH-1:0]   s_araddry,
            input   wire    [S_NUM-1:0]                     s_arvalid,
            output  wire    [S_NUM-1:0]                     s_arready,

            output  wire    [S_NUM-1:0]                     s_rlast,
            output  wire    [S_NUM-1:0][S_DATA_WIDTH-1:0]   s_rdata,
            output  wire    [S_NUM-1:0]                     s_rvalid,
            input   wire    [S_NUM-1:0]                     s_rready,


            output  wire    [M_AXI4_ID_WIDTH-1:0]           m_axi4_arid,
            output  wire    [M_AXI4_ADDR_WIDTH-1:0]         m_axi4_araddr,
            output  wire    [M_AXI4_LEN_WIDTH-1:0]          m_axi4_arlen,
            output  wire    [2:0]                           m_axi4_arsize,
            output  wire    [1:0]                           m_axi4_arburst,
            output  wire    [0:0]                           m_axi4_arlock,
            output  wire    [3:0]                           m_axi4_arcache,
            output  wire    [2:0]                           m_axi4_arprot,
            output  wire    [M_AXI4_QOS_WIDTH-1:0]          m_axi4_arqos,
            output  wire    [3:0]                           m_axi4_arregion,
            output  wire                                    m_axi4_arvalid,
            input   wire                                    m_axi4_arready,
            input   wire    [M_AXI4_ID_WIDTH-1:0]           m_axi4_rid,
            input   wire    [M_AXI4_DATA_WIDTH-1:0]         m_axi4_rdata,
            input   wire    [1:0]                           m_axi4_rresp,
            input   wire                                    m_axi4_rlast,
            input   wire                                    m_axi4_rvalid,
            output  wire                                    m_axi4_rready
        );
    
    
    // -----------------------------
    //  localparam
    // -----------------------------
    
    localparam  CACHE_ID_WIDTH      = PARALLEL_SIZE;
    localparam  ID_WIDTH            = M_AXI4_ID_WIDTH;
    localparam  S_ID_WIDTH          = $clog2(S_NUM) > 0 ? $clog2(S_NUM) : 1;
    localparam  COMPONENT_SEL_WIDTH = $clog2(COMPONENT_NUM) > 0 ? $clog2(COMPONENT_NUM) : 1;
    localparam  M_DATA_SIZE    = M_AXI4_DATA_SIZE;
    
    initial if ( M_AXI4_ID_WIDTH < CACHE_ID_WIDTH) $error("M_AXI4_ID_WIDTH is too less");
    

    // -----------------------------
    //  Arbiter
    // -----------------------------
    
    localparam  S_AR_PACKET_WIDTH = ADDR_X_WIDTH + ADDR_Y_WIDTH;
    localparam  S_R_PACKET_WIDTH  = 1 + S_DATA_WIDTH;
    
    
    // コマンドパケット生成
    localparam  BLK_ADDR_X_WIDTH = ADDR_X_WIDTH - BLK_X_SIZE;
    localparam  BLK_ADDR_Y_WIDTH = ADDR_Y_WIDTH - BLK_Y_SIZE;
    
    wire    [S_NUM-1:0][CACHE_ID_WIDTH-1:0]      s_arid;
    wire    [S_NUM-1:0][S_AR_PACKET_WIDTH-1:0]   s_arpacket;
    
    generate
    for ( genvar i = 0; i < S_NUM; ++i ) begin : loop_ar_pack
        //  ID
        wire    [BLK_ADDR_X_WIDTH-1:0]  s_blk_addrx;
        wire    [BLK_ADDR_Y_WIDTH-1:0]  s_blk_addry;
        assign s_blk_addrx = BLK_ADDR_X_WIDTH'(s_araddrx[i] >> BLK_X_SIZE);
        assign s_blk_addry = BLK_ADDR_Y_WIDTH'(s_araddry[i] >> BLK_Y_SIZE);
        
        jelly2_texture_cache_tag_addr
                #(
                    .PARALLEL_SIZE      (PARALLEL_SIZE),
                    
                    .ADDR_X_WIDTH       (BLK_ADDR_X_WIDTH),
                    .ADDR_Y_WIDTH       (BLK_ADDR_Y_WIDTH),
                    .TAG_ADDR_WIDTH     (TAG_ADDR_WIDTH)
                )
            i_texture_cache_tag_addr_cache_id
                (
                    .addrx              (s_blk_addrx),
                    .addry              (s_blk_addry),
                    
                    .unit_id            (s_arid[i]),
                    .tag_addr           (),
                    .index              ()
                );
        
        // packet
        assign s_arpacket[i] = {s_araddrx[i], s_araddry[i]};
    end
    endgenerate
    
    
    // コマンドパケット調停
    wire    [CACHE_NUM-1:0][S_ID_WIDTH-1:0]         arbit_arid;
    wire    [CACHE_NUM-1:0][S_AR_PACKET_WIDTH-1:0]  arbit_arpacket;
    wire    [CACHE_NUM-1:0]                         arbit_arvalid;
    wire    [CACHE_NUM-1:0]                         arbit_arready;
    
    
//  wire    [CACHE_NUM-1:0][S_ID_WIDTH-1:0]         arbit_aruser;
    wire    [CACHE_NUM-1:0][ADDR_X_WIDTH-1:0]       arbit_araddrx;
    wire    [CACHE_NUM-1:0][ADDR_Y_WIDTH-1:0]       arbit_araddry;
    generate
    for ( genvar i = 0; i < CACHE_NUM; ++i ) begin : loop_ar_unpack
        assign 
            {
//              arbit_aruser  [i],
                arbit_araddrx [i],
                arbit_araddry [i]
            } = arbit_arpacket[i];
    end
    endgenerate
    
    jelly2_data_arbiter_ring_bus
            #(
                .S_NUM              (S_NUM),
                .S_ID_WIDTH         (S_ID_WIDTH),
                .M_NUM              (CACHE_NUM),
                .M_ID_WIDTH         (CACHE_ID_WIDTH),
                .DATA_WIDTH         (S_AR_PACKET_WIDTH)
            )
        i_data_arbiter_ring_bus
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (1'b1),
                
                .s_id_to            (s_arid),
                .s_data             (s_arpacket),
                .s_valid            (s_arvalid),
                .s_ready            (s_arready),
                
                .m_id_from          (arbit_arid),
                .m_data             (arbit_arpacket),
                .m_valid            (arbit_arvalid),
                .m_ready            (arbit_arready)
            );
    
    
    
    // データ用クロスバー
    wire    [CACHE_NUM-1:0][S_ID_WIDTH-1:0]         arbit_rid;
    wire    [CACHE_NUM-1:0]                         arbit_rlast;
    wire    [CACHE_NUM-1:0][S_DATA_WIDTH-1:0]       arbit_rdata;
    wire    [CACHE_NUM-1:0]                         arbit_rvalid;
    wire    [CACHE_NUM-1:0]                         arbit_rready;
    
    wire    [CACHE_NUM-1:0][S_R_PACKET_WIDTH-1:0]   arbit_rpacket;
    
    wire    [S_NUM-1:0][S_R_PACKET_WIDTH-1:0]       s_rpacket;
    
    generate
    for ( genvar i = 0; i < CACHE_NUM; ++i ) begin : loop_r_pack
        assign arbit_rpacket[i] =
            {
                arbit_rlast[i],
                arbit_rdata[i]
            };
    end
    endgenerate
    
    generate
    for ( genvar i = 0; i < S_NUM; ++i ) begin : loop_r_unpack
        assign
            {
                s_rlast[i],
                s_rdata[i]
            } = s_rpacket[i];
    end
    endgenerate
    
    jelly2_data_crossbar_simple
            #(
                .S_NUM          (CACHE_NUM),
                .S_ID_WIDTH     (CACHE_ID_WIDTH),
                .M_NUM          (S_NUM),
                .M_ID_WIDTH     (S_ID_WIDTH),
                .DATA_WIDTH     (S_R_PACKET_WIDTH)
            )
        i_data_crossbar_simple
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (1'b1),
                
                .s_id_to        (arbit_rid),
                .s_data         (arbit_rpacket),
                .s_valid        (arbit_rvalid),
                
                .m_id_from      (),
                .m_data         (s_rpacket),
                .m_valid        (s_rvalid)
            );
    assign arbit_rready = {CACHE_NUM{1'b1}};
    
    // simulation check
    always_ff @(posedge clk) begin
        if ( !reset ) begin
            if ( |(s_rvalid & ~s_rready) ) begin
                $display("L2$ rdata overflow : %b", (s_rvalid & ~s_rready));
            end
        end
    end
    
    
    // -----------------------------
    //  L2 Cahce
    // -----------------------------
    
    localparam  M_AR_PACKET_WIDTH = ADDR_X_WIDTH + ADDR_Y_WIDTH;
    localparam  M_R_PACKET_WIDTH  = 1 + COMPONENT_SEL_WIDTH + M_AXI4_DATA_WIDTH;
    
    // cache
    wire    [CACHE_NUM-1:0]                             cache_clear_busy;
    assign clear_busy = cache_clear_busy[0];
    
    wire    [CACHE_NUM-1:0][M_AR_PACKET_WIDTH-1:0]      cache_arpacket;
    wire    [CACHE_NUM-1:0][ADDR_X_WIDTH-1:0]           cache_araddrx;
    wire    [CACHE_NUM-1:0][ADDR_Y_WIDTH-1:0]           cache_araddry;
    wire    [CACHE_NUM-1:0]                             cache_arvalid;
    wire    [CACHE_NUM-1:0]                             cache_arready;
    
    wire    [CACHE_NUM-1:0][M_R_PACKET_WIDTH-1:0]       cache_rpacket;
    wire    [CACHE_NUM-1:0]                             cache_rlast;
    wire    [CACHE_NUM-1:0][COMPONENT_SEL_WIDTH-1:0]    cache_rcomponent;
    wire    [CACHE_NUM-1:0][COMPONENT_NUM-1:0]          cache_rstrb;
    wire    [CACHE_NUM-1:0][M_AXI4_DATA_WIDTH-1:0]      cache_rdata;
    wire    [CACHE_NUM-1:0]                             cache_rvalid;
    wire    [CACHE_NUM-1:0]                             cache_rready;
    
    
    generate
    for ( genvar i = 0; i < CACHE_NUM; ++i ) begin : cahce_loop
        
        // strobe
        assign  cache_rstrb[i] = (1 << cache_rcomponent[i]);
        
        
        // ar pack
        assign cache_arpacket[i] =
                {
                    cache_araddrx[i],
                    cache_araddry[i]
                };
        
        // r unpack
        assign {
                    cache_rlast     [i],
                    cache_rcomponent[i],
                    cache_rdata     [i]
                } = cache_rpacket[i];
        
        // cahce
        jelly2_texture_cache_unit
                #(
                    .COMPONENT_NUM          (COMPONENT_NUM),
                    .COMPONENT_DATA_WIDTH   (8),
                    
                    .PARALLEL_SIZE          (PARALLEL_SIZE),
                    .ADDR_X_WIDTH           (ADDR_X_WIDTH),
                    .ADDR_Y_WIDTH           (ADDR_Y_WIDTH),
                    .BLK_X_SIZE             (BLK_X_SIZE),
                    .BLK_Y_SIZE             (BLK_Y_SIZE),
                    .WAY_NUM                (WAY_NUM),
                    .TAG_ADDR_WIDTH         (TAG_ADDR_WIDTH),
                    .TAG_RAM_TYPE           (TAG_RAM_TYPE),
                    .TAG_ALGORITHM          (TAG_ALGORITHM), 
                    .TAG_M_SLAVE_REGS       (TAG_M_SLAVE_REGS),
                    .TAG_M_MASTER_REGS      (TAG_M_MASTER_REGS),
                    .MEM_RAM_TYPE           (MEM_RAM_TYPE),
                    
                    .USE_LOOK_AHEAD         (USE_LOOK_AHEAD),
                    .USE_S_RREADY           (USE_S_RREADY),
                    .USE_M_RREADY           (USE_M_RREADY),
                    
                    .S_USER_WIDTH           (S_ID_WIDTH),
                    .S_DATA_SIZE            (S_DATA_SIZE+COMPONENT_DATA_SIZE),  // AXIにあわせてバイト単位に換算
                    .S_BLK_X_NUM            (S_BLK_X_NUM),
                    .S_BLK_Y_NUM            (S_BLK_Y_NUM),
                    
                    .M_DATA_SIZE            (M_AXI4_DATA_SIZE),
                    .M_INORDER              (0),
                    
                    .QUE_FIFO_PTR_WIDTH     (QUE_FIFO_PTR_WIDTH),
                    .QUE_FIFO_RAM_TYPE      (QUE_FIFO_RAM_TYPE),
                    .QUE_FIFO_S_REGS        (QUE_FIFO_S_REGS),
                    .QUE_FIFO_M_REGS        (QUE_FIFO_M_REGS),
                    
                    .AR_FIFO_PTR_WIDTH      (AR_FIFO_PTR_WIDTH),
                    .AR_FIFO_RAM_TYPE       (AR_FIFO_RAM_TYPE),
                    .AR_FIFO_S_REGS         (AR_FIFO_S_REGS),
                    .AR_FIFO_M_REGS         (AR_FIFO_M_REGS),
                    
                    .R_FIFO_PTR_WIDTH       (R_FIFO_PTR_WIDTH),
                    .R_FIFO_RAM_TYPE        (R_FIFO_RAM_TYPE),
                    .R_FIFO_S_REGS          (R_FIFO_S_REGS),
                    .R_FIFO_M_REGS          (R_FIFO_M_REGS),
                    
                    .LOG_ENABLE             (LOG_ENABLE),
                    .LOG_FILE               (LOG_FILE),
                    .LOG_ID                 (LOG_ID + i)
                )
            i_texture_cache_unit
                (
                    .reset                  (reset),
                    .clk                    (clk),
                    
                    .endian                 (endian),
                    
                    .clear_start            (clear_start),
                    .clear_busy             (cache_clear_busy[i]),
                    
                    .param_blank_value      ({S_DATA_WIDTH{1'b0}}),
                    
                    .status_idle            (status_idle  [i]),
                    .status_stall           (status_stall [i]),
                    .status_access          (status_access[i]),
                    .status_hit             (status_hit   [i]),
                    .status_miss            (status_miss  [i]),
                    .status_blank           (status_blank [i]),
                    
                    .s_aruser               (arbit_arid   [i]),
                    .s_araddrx              (arbit_araddrx[i]),
                    .s_araddry              (arbit_araddry[i]),
                    .s_arstrb               (1'b1),
                    .s_arvalid              (arbit_arvalid[i]),
                    .s_arready              (arbit_arready[i]),
                    
                    .s_ruser                (arbit_rid    [i]),
                    .s_rlast                (arbit_rlast  [i]),
                    .s_rdata                (arbit_rdata  [i]),
                    .s_rstrb                (),
                    .s_rvalid               (arbit_rvalid [i]),
                    .s_rready               (arbit_rready [i]),
                    
                    .m_araddrx              (cache_araddrx[i]),
                    .m_araddry              (cache_araddry[i]),
                    .m_arvalid              (cache_arvalid[i]),
                    .m_arready              (cache_arready[i]),
                    
                    .m_rlast                (cache_rlast  [i]),
                    .m_rstrb                (cache_rstrb  [i]),
                    .m_rdata                ({COMPONENT_NUM{cache_rdata[i]}}),
                    .m_rvalid               (cache_rvalid [i]),
                    .m_rready               (cache_rready [i])
                );
    end
    endgenerate
    
    
    
    // -----------------------------
    //  Ring-bus
    // -----------------------------
    
    wire    [CACHE_ID_WIDTH-1:0]        ringbus_arid;
    wire    [M_AR_PACKET_WIDTH-1:0]     ringbus_arpacket;
    wire    [ADDR_X_WIDTH-1:0]          ringbus_araddrx;
    wire    [ADDR_Y_WIDTH-1:0]          ringbus_araddry;
    wire                                ringbus_arvalid;
    wire                                ringbus_arready;
    
    wire    [CACHE_ID_WIDTH-1:0]        ringbus_rid;
    wire    [M_R_PACKET_WIDTH-1:0]      ringbus_rpacket;
    wire                                ringbus_rlast;
    wire    [COMPONENT_SEL_WIDTH-1:0]   ringbus_rcomponent;
    wire    [M_AXI4_DATA_WIDTH-1:0]     ringbus_rdata;
    wire                                ringbus_rvalid;
    wire                                ringbus_rready;
    
    // ar unpack
    assign  {ringbus_araddrx, ringbus_araddry} = ringbus_arpacket;
    
    // r pack
    assign ringbus_rpacket = {ringbus_rlast, ringbus_rcomponent, ringbus_rdata};
    
    jelly2_data_arbiter_ring_bus
            #(
                .S_NUM              (CACHE_NUM),
                .S_ID_WIDTH         (CACHE_ID_WIDTH),
                .M_NUM              (1),
                .M_ID_WIDTH         (1),
                .DATA_WIDTH         (M_AR_PACKET_WIDTH)
            )
        i_data_arbiter_ring_bus_ar
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (1'b1),
                
                .s_id_to            ({CACHE_NUM{1'b0}}),
                .s_data             (cache_arpacket),
                .s_valid            (cache_arvalid),
                .s_ready            (cache_arready),
                
                .m_id_from          (ringbus_arid),
                .m_data             (ringbus_arpacket),
                .m_valid            (ringbus_arvalid),
                .m_ready            (ringbus_arready)
            );

    jelly2_data_switch
            #(
                .NUM                (CACHE_NUM),
                .ID_WIDTH           (CACHE_ID_WIDTH),
                .DATA_WIDTH         (M_R_PACKET_WIDTH),
                .S_REGS             (0),
                .M_REGS             (1)
            )
        i_data_switch_r
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (1'b1),
                
                .s_id               (ringbus_rid),
                .s_data             (ringbus_rpacket),
                .s_valid            (ringbus_rvalid),
                .s_ready            (),
                
                .m_data             (cache_rpacket),
                .m_valid            (cache_rvalid),
                .m_ready            ({CACHE_NUM{1'b1}})
            );
    assign ringbus_rready = 1'b1;
    
    
    // -----------------------------
    //  DMA
    // -----------------------------
    
    wire    [ID_WIDTH-1:0]              dma_arid;
    wire    [ADDR_WIDTH-1:0]            dma_araddr;
    wire                                dma_arvalid;
    wire                                dma_arready;
    
    wire    [ID_WIDTH-1:0]              dma_rid;
    wire                                dma_rlast;
    wire    [COMPONENT_SEL_WIDTH-1:0]   dma_rcomponent;
    wire    [M_AXI4_DATA_WIDTH-1:0]     dma_rdata;
    wire                                dma_rvalid;
    wire                                dma_rready;
    
    jelly2_texture_cache_dma
            #(
                .COMPONENT_NUM          (COMPONENT_NUM),
                .COMPONENT_SEL_WIDTH    (COMPONENT_SEL_WIDTH),
                
                .M_AXI4_ID_WIDTH        (M_AXI4_ID_WIDTH),
                .M_AXI4_ADDR_WIDTH      (M_AXI4_ADDR_WIDTH),
                .M_AXI4_DATA_SIZE       (M_AXI4_DATA_SIZE),
                .M_AXI4_DATA_WIDTH      (M_AXI4_DATA_WIDTH),
                .M_AXI4_LEN_WIDTH       (M_AXI4_LEN_WIDTH),
                .M_AXI4_QOS_WIDTH       (M_AXI4_QOS_WIDTH),
                .M_AXI4_ARSIZE          (M_AXI4_ARSIZE),
                .M_AXI4_ARBURST         (M_AXI4_ARBURST),
                .M_AXI4_ARLOCK          (M_AXI4_ARLOCK),
                .M_AXI4_ARCACHE         (M_AXI4_ARCACHE),
                .M_AXI4_ARPROT          (M_AXI4_ARPROT),
                .M_AXI4_ARQOS           (M_AXI4_ARQOS),
                .M_AXI4_ARREGION        (M_AXI4_ARREGION),
                .M_AXI4_REGS            (M_AXI4_REGS),
                
                .ID_WIDTH               (ID_WIDTH),
                .ADDR_WIDTH             (ADDR_WIDTH),
                .STRIDE_C_WIDTH         (STRIDE_C_WIDTH),
                
                .QUE_FIFO_PTR_WIDTH     (DMA_QUE_FIFO_PTR_WIDTH),
                .QUE_FIFO_RAM_TYPE      (DMA_QUE_FIFO_RAM_TYPE),
                .QUE_FIFO_S_REGS        (DMA_QUE_FIFO_S_REGS),
                .QUE_FIFO_M_REGS        (DMA_QUE_FIFO_M_REGS),
                
                .S_AR_REGS              (DMA_S_AR_REGS),
                .S_R_REGS               (DMA_S_R_REGS)
            )
        i_texture_cache_dma
            (
                .reset                  (reset),
                .clk                    (clk),
                                         
                .param_addr             (param_addr),
                .param_arlen            (param_arlen),
                .param_stride_c         (param_stride_c),
                
                .s_arid                 (dma_arid),
                .s_araddr               (dma_araddr),
                .s_arvalid              (dma_arvalid),
                .s_arready              (dma_arready),
                .s_rid                  (dma_rid),
                .s_rlast                (dma_rlast),
                .s_rcomponent           (dma_rcomponent),
                .s_rdata                (dma_rdata),
                .s_rvalid               (dma_rvalid),
                .s_rready               (dma_rready),
                
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
    
    reg     [ID_WIDTH-1:0]      st0_dma_arid;
    reg     [ADDR_WIDTH-1:0]    st0_dma_araddry;
    reg     [ADDR_WIDTH-1:0]    st0_dma_araddrx;
    reg                         st0_dma_arvalid;
    
    reg     [ID_WIDTH-1:0]      st1_dma_arid;
    reg     [ADDR_WIDTH-1:0]    st1_dma_araddry;
    reg     [ADDR_WIDTH-1:0]    st1_dma_araddrx;
    reg                         st1_dma_arvalid;
    
    reg     [ID_WIDTH-1:0]      st2_dma_arid;
    reg     [ADDR_WIDTH-1:0]    st2_dma_araddr;
    reg                         st2_dma_arvalid;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_dma_arid    <= {ID_WIDTH{1'bx}};
            st0_dma_araddry <= {ADDR_WIDTH{1'bx}};
            st0_dma_araddrx <= {ADDR_WIDTH{1'bx}};
            st0_dma_arvalid <= 1'b0;
            
            st1_dma_arid    <= {ID_WIDTH{1'bx}};
            st1_dma_araddry <= {ADDR_WIDTH{1'bx}};
            st1_dma_araddrx <= {ADDR_WIDTH{1'bx}};
            st1_dma_arvalid <= 1'b0;
            
            st2_dma_arid    <= {ID_WIDTH{1'bx}};
            st2_dma_araddr  <= {ADDR_WIDTH{1'bx}};
            st2_dma_arvalid <= 1'b0;
        end
        else if ( !dma_arvalid || dma_arready ) begin
            st0_dma_arid    <= ID_WIDTH'(ringbus_arid);
            st0_dma_araddry <= ADDR_WIDTH'(64'(ringbus_araddry) >> BLK_Y_SIZE) * ADDR_WIDTH'(param_stride_y);  // + (ringbus_araddrx << (BLK_Y_SIZE + BLK_X_SIZE));
            st0_dma_araddrx <= ADDR_WIDTH'(64'(ringbus_araddrx) >> BLK_X_SIZE) * ADDR_WIDTH'(param_stride_x);
            st0_dma_arvalid <= ringbus_arvalid;
            
            st1_dma_arid    <= st0_dma_arid;
            st1_dma_araddry <= st0_dma_araddry;
            st1_dma_araddrx <= st0_dma_araddrx;
            st1_dma_arvalid <= st0_dma_arvalid;
            
            st2_dma_arid    <= st1_dma_arid;
            st2_dma_araddr  <= st1_dma_araddry + st1_dma_araddrx;
            st2_dma_arvalid <= st1_dma_arvalid; 
        end
    end
    
    assign dma_arid           = st2_dma_arid;
    assign dma_araddr         = st2_dma_araddr;
    assign dma_arvalid        = st2_dma_arvalid;
    assign ringbus_arready    = (!dma_arvalid || dma_arready);
    
    assign ringbus_rid        = CACHE_ID_WIDTH'(dma_rid);
    assign ringbus_rlast      = dma_rlast;
    assign ringbus_rcomponent = dma_rcomponent;
    assign ringbus_rdata      = dma_rdata;
    assign ringbus_rvalid     = dma_rvalid;
    assign dma_rready         = ringbus_rready;
    
    
endmodule


`default_nettype wire


// end of file
