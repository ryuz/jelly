// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns/1ps
`default_nettype none



module jelly2_dma_stream_write
        #(
            // 基本設定
            parameter int                               N                    = 2,
            parameter int                               BYTE_WIDTH           = 8,
            
            // WISHBONE
            parameter int                               WB_ASYNC             = 1,
            parameter int                               WB_ADR_WIDTH         = 8,
            parameter int                               WB_DAT_WIDTH         = 32,
            parameter int                               WB_SEL_WIDTH         = (WB_DAT_WIDTH / 8),
            
            // write port
            parameter int                               WASYNC               = 1,
            parameter int                               WDATA_WIDTH          = 32,
            parameter int                               WSTRB_WIDTH          = WDATA_WIDTH / BYTE_WIDTH,
            parameter bit                               HAS_WSTRB            = 0,
            parameter bit                               HAS_WFIRST           = 0,
            parameter bit                               HAS_WLAST            = 0,
            
            // AXI4
            parameter int                               AXI4_ID_WIDTH        = 6,
            parameter int                               AXI4_ADDR_WIDTH      = 32,
            parameter int                               AXI4_DATA_SIZE       = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter int                               AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE),
            parameter int                               AXI4_STRB_WIDTH      = AXI4_DATA_WIDTH / BYTE_WIDTH,
            parameter int                               AXI4_LEN_WIDTH       = 8,
            parameter int                               AXI4_QOS_WIDTH       = 4,
            parameter bit   [AXI4_ID_WIDTH-1:0]         AXI4_AWID            = {AXI4_ID_WIDTH{1'b0}},
            parameter bit   [2:0]                       AXI4_AWSIZE          = 3'(AXI4_DATA_SIZE),
            parameter bit   [1:0]                       AXI4_AWBURST         = 2'b01,
            parameter bit   [0:0]                       AXI4_AWLOCK          = 1'b0,
            parameter bit   [3:0]                       AXI4_AWCACHE         = 4'b0001,
            parameter bit   [2:0]                       AXI4_AWPROT          = 3'b000,
            parameter bit   [AXI4_QOS_WIDTH-1:0]        AXI4_AWQOS           = 0,
            parameter bit   [3:0]                       AXI4_AWREGION        = 4'b0000,
            parameter int                               AXI4_ALIGN           = 12,  // 2^12 = 4k が境界
            
            // レジスタ構成など
            parameter   int                             INDEX_WIDTH          = 1,
            parameter   bit                             AWLEN_OFFSET         = 1'b1,
            parameter   int                             AWLEN0_WIDTH         = 32,
            parameter   int                             AWLEN1_WIDTH         = 32,
            parameter   int                             AWLEN2_WIDTH         = 32,
            parameter   int                             AWLEN3_WIDTH         = 32,
            parameter   int                             AWLEN4_WIDTH         = 32,
            parameter   int                             AWLEN5_WIDTH         = 32,
            parameter   int                             AWLEN6_WIDTH         = 32,
            parameter   int                             AWLEN7_WIDTH         = 32,
            parameter   int                             AWLEN8_WIDTH         = 32,
            parameter   int                             AWLEN9_WIDTH         = 32,
            parameter   int                             AWSTEP1_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP2_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP3_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP4_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP5_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP6_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP7_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP8_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             AWSTEP9_WIDTH        = AXI4_ADDR_WIDTH,
            
            // レジスタ初期値
            parameter   bit     [3:0]                   INIT_CTL_CONTROL     = 4'b0000,
            parameter   bit     [0:0]                   INIT_IRQ_ENABLE      = 1'b0,
            parameter   bit     [AXI4_ADDR_WIDTH-1:0]   INIT_PARAM_AWADDR    = 0,
            parameter   bit     [AXI4_ADDR_WIDTH-1:0]   INIT_PARAM_AWOFFSET  = 0,
            parameter   bit     [AXI4_LEN_WIDTH-1:0]    INIT_PARAM_AWLEN_MAX = 0,
            parameter   bit     [AWLEN0_WIDTH-1:0]      INIT_PARAM_AWLEN0    = 0,
//          parameter   bit     [AWSTEP0_WIDTH-1:0]     INIT_PARAM_AWSTEP0   = 0,
            parameter   bit     [AWLEN1_WIDTH-1:0]      INIT_PARAM_AWLEN1    = 0,
            parameter   bit     [AWSTEP1_WIDTH-1:0]     INIT_PARAM_AWSTEP1   = 0,
            parameter   bit     [AWLEN2_WIDTH-1:0]      INIT_PARAM_AWLEN2    = 0,
            parameter   bit     [AWSTEP2_WIDTH-1:0]     INIT_PARAM_AWSTEP2   = 0,
            parameter   bit     [AWLEN3_WIDTH-1:0]      INIT_PARAM_AWLEN3    = 0,
            parameter   bit     [AWSTEP3_WIDTH-1:0]     INIT_PARAM_AWSTEP3   = 0,
            parameter   bit     [AWLEN4_WIDTH-1:0]      INIT_PARAM_AWLEN4    = 0,
            parameter   bit     [AWSTEP4_WIDTH-1:0]     INIT_PARAM_AWSTEP4   = 0,
            parameter   bit     [AWLEN5_WIDTH-1:0]      INIT_PARAM_AWLEN5    = 0,
            parameter   bit     [AWSTEP5_WIDTH-1:0]     INIT_PARAM_AWSTEP5   = 0,
            parameter   bit     [AWLEN6_WIDTH-1:0]      INIT_PARAM_AWLEN6    = 0,
            parameter   bit     [AWSTEP6_WIDTH-1:0]     INIT_PARAM_AWSTEP6   = 0,
            parameter   bit     [AWLEN7_WIDTH-1:0]      INIT_PARAM_AWLEN7    = 0,
            parameter   bit     [AWSTEP7_WIDTH-1:0]     INIT_PARAM_AWSTEP7   = 0,
            parameter   bit     [AWLEN8_WIDTH-1:0]      INIT_PARAM_AWLEN8    = 0,
            parameter   bit     [AWSTEP8_WIDTH-1:0]     INIT_PARAM_AWSTEP8   = 0,
            parameter   bit     [AWLEN9_WIDTH-1:0]      INIT_PARAM_AWLEN9    = 0,
            parameter   bit     [AWSTEP9_WIDTH-1:0]     INIT_PARAM_AWSTEP9   = 0,
            parameter   bit                             INIT_WSKIP_EN        = 1'b1,
            parameter   bit     [N-1:0]                 INIT_WDETECT_FIRST   = {N{1'b0}},
            parameter   bit     [N-1:0]                 INIT_WDETECT_LAST    = {N{1'b0}},
            parameter   bit                             INIT_WPADDING_EN     = 1'b1,
            parameter   bit     [WDATA_WIDTH-1:0]       INIT_WPADDING_DATA   = {WDATA_WIDTH{1'b0}},
            parameter   bit     [WSTRB_WIDTH-1:0]       INIT_WPADDING_STRB   = {WSTRB_WIDTH{1'b0}},
            
            // 構成情報
            parameter                                   CORE_ID              = 32'h527a_0110,
            parameter                                   CORE_VERSION         = 32'h0000_0000,
            parameter   bit                             BYPASS_GATE          = 0,
            parameter   bit                             BYPASS_ALIGN         = 0,
            parameter   bit                             WDETECTOR_CHANGE     = 1,
            parameter   bit                             WDETECTOR_ENABLE     = 1,
            parameter   bit                             ALLOW_UNALIGNED      = 1,
            parameter   int                             CAPACITY_WIDTH       = 32,
            parameter   int                             WFIFO_PTR_WIDTH      = 9,
            parameter                                   WFIFO_RAM_TYPE       = "block",
            parameter   bit                             WFIFO_LOW_DEALY      = 0,
            parameter   bit                             WFIFO_DOUT_REGS      = 1,
            parameter   bit                             WFIFO_S_REGS         = 0,
            parameter   bit                             WFIFO_M_REGS         = 1,
            parameter   int                             AWFIFO_PTR_WIDTH     = 4,
            parameter                                   AWFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             AWFIFO_LOW_DEALY     = 1,
            parameter   bit                             AWFIFO_DOUT_REGS     = 0,
            parameter   bit                             AWFIFO_S_REGS        = 1,
            parameter   bit                             AWFIFO_M_REGS        = 1,
            parameter   int                             BFIFO_PTR_WIDTH      = 4,
            parameter                                   BFIFO_RAM_TYPE       = "distributed",
            parameter   bit                             BFIFO_LOW_DEALY      = 0,
            parameter   bit                             BFIFO_DOUT_REGS      = 0,
            parameter   bit                             BFIFO_S_REGS         = 0,
            parameter   bit                             BFIFO_M_REGS         = 0,
            parameter   int                             SWFIFOPTR_WIDTH      = 4,
            parameter                                   SWFIFORAM_TYPE       = "distributed",
            parameter   bit                             SWFIFOLOW_DEALY      = 1,
            parameter   bit                             SWFIFODOUT_REGS      = 0,
            parameter   bit                             SWFIFOS_REGS         = 0,
            parameter   bit                             SWFIFOM_REGS         = 0,
            parameter   int                             MBFIFO_PTR_WIDTH     = 4,
            parameter                                   MBFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             MBFIFO_LOW_DEALY     = 1,
            parameter   bit                             MBFIFO_DOUT_REGS     = 0,
            parameter   bit                             MBFIFO_S_REGS        = 0,
            parameter   bit                             MBFIFO_M_REGS        = 0,
            parameter   int                             WDATFIFO_PTR_WIDTH   = 4,
            parameter   bit                             WDATFIFO_DOUT_REGS   = 0,
            parameter                                   WDATFIFO_RAM_TYPE    = "distributed",
            parameter   bit                             WDATFIFO_LOW_DEALY   = 1,
            parameter   bit                             WDATFIFO_S_REGS      = 0,
            parameter   bit                             WDATFIFO_M_REGS      = 0,
            parameter   bit                             WDAT_S_REGS          = 0,
            parameter   bit                             WDAT_M_REGS          = 1,
            parameter   int                             BACKFIFO_PTR_WIDTH   = 4,
            parameter   bit                             BACKFIFO_DOUT_REGS   = 0,
            parameter                                   BACKFIFO_RAM_TYPE    = "distributed",
            parameter   bit                             BACKFIFO_LOW_DEALY   = 1,
            parameter   bit                             BACKFIFO_S_REGS      = 0,
            parameter   bit                             BACKFIFO_M_REGS      = 0,
            parameter   bit                             BACK_S_REGS          = 0,
            parameter   bit                             BACK_M_REGS          = 1,
            parameter   bit                             CONVERT_S_REGS       = 0
        )
        (
            input   wire                            endian,
            
            // WISHBONE (register access)
            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  reg                             s_wb_ack_o,
            output  wire    [0:0]                   out_irq,
            
            output  wire                            buffer_request,
            output  wire                            buffer_release,
            input   wire    [AXI4_ADDR_WIDTH-1:0]   buffer_addr,
            
            // write stream
            input   wire                            s_wresetn,
            input   wire                            s_wclk,
            input   wire    [WDATA_WIDTH-1:0]       s_wdata,
            input   wire    [WSTRB_WIDTH-1:0]       s_wstrb,
            input   wire    [N-1:0]                 s_wfirst,
            input   wire    [N-1:0]                 s_wlast,
            input   wire                            s_wvalid,
            output  wire                            s_wready,
            
            // AXI4
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
    
    
    // address mask
    localparam  [AXI4_ADDR_WIDTH-1:0]   ADDR_MASK = ~((1 << AXI4_DATA_SIZE) - 1);
    
    
    // ---------------------------------
    //  Register
    // ---------------------------------
    
    // register address offset
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_ID             = WB_ADR_WIDTH'('h00);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION        = WB_ADR_WIDTH'('h01);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CORE_CONFIG         = WB_ADR_WIDTH'('h03);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CTL_CONTROL         = WB_ADR_WIDTH'('h04);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CTL_STATUS          = WB_ADR_WIDTH'('h05);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_CTL_INDEX           = WB_ADR_WIDTH'('h07);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_IRQ_ENABLE          = WB_ADR_WIDTH'('h08);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_IRQ_STATUS          = WB_ADR_WIDTH'('h09);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_IRQ_CLR             = WB_ADR_WIDTH'('h0a);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_IRQ_SET             = WB_ADR_WIDTH'('h0b);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWADDR        = WB_ADR_WIDTH'('h10);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWOFFSET      = WB_ADR_WIDTH'('h18);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN_MAX     = WB_ADR_WIDTH'('h1c);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN0        = WB_ADR_WIDTH'('h20);
//  localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP0       = WB_ADR_WIDTH'('h21);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN1        = WB_ADR_WIDTH'('h24);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP1       = WB_ADR_WIDTH'('h25);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN2        = WB_ADR_WIDTH'('h28);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP2       = WB_ADR_WIDTH'('h29);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN3        = WB_ADR_WIDTH'('h2c);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP3       = WB_ADR_WIDTH'('h2d);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN4        = WB_ADR_WIDTH'('h30);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP4       = WB_ADR_WIDTH'('h31);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN5        = WB_ADR_WIDTH'('h34);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP5       = WB_ADR_WIDTH'('h35);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN6        = WB_ADR_WIDTH'('h38);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP6       = WB_ADR_WIDTH'('h39);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN7        = WB_ADR_WIDTH'('h3c);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP7       = WB_ADR_WIDTH'('h3d);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN8        = WB_ADR_WIDTH'('h40);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP8       = WB_ADR_WIDTH'('h41);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWLEN9        = WB_ADR_WIDTH'('h44);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_PARAM_AWSTEP9       = WB_ADR_WIDTH'('h45);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_WSKIP_EN            = WB_ADR_WIDTH'('h70);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_WDETECT_FIRST       = WB_ADR_WIDTH'('h72);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_WDETECT_LAST        = WB_ADR_WIDTH'('h73);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_WPADDING_EN         = WB_ADR_WIDTH'('h74);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_WPADDING_DATA       = WB_ADR_WIDTH'('h75);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_WPADDING_STRB       = WB_ADR_WIDTH'('h76);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWADDR       = WB_ADR_WIDTH'('h90);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWOFFSET     = WB_ADR_WIDTH'('h98);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN_MAX    = WB_ADR_WIDTH'('h9c);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN0       = WB_ADR_WIDTH'('ha0);
//  localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP0      = WB_ADR_WIDTH'('ha1);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN1       = WB_ADR_WIDTH'('ha4);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP1      = WB_ADR_WIDTH'('ha5);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN2       = WB_ADR_WIDTH'('ha8);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP2      = WB_ADR_WIDTH'('ha9);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN3       = WB_ADR_WIDTH'('hac);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP3      = WB_ADR_WIDTH'('had);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN4       = WB_ADR_WIDTH'('hb0);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP4      = WB_ADR_WIDTH'('hb1);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN5       = WB_ADR_WIDTH'('hb4);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP5      = WB_ADR_WIDTH'('hb5);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN6       = WB_ADR_WIDTH'('hb8);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP6      = WB_ADR_WIDTH'('hb9);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN7       = WB_ADR_WIDTH'('hbc);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP7      = WB_ADR_WIDTH'('hbd);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN8       = WB_ADR_WIDTH'('hc0);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP8      = WB_ADR_WIDTH'('hc1);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWLEN9       = WB_ADR_WIDTH'('hc4);
    localparam  [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AWSTEP9      = WB_ADR_WIDTH'('hc5);
    
    
    // registers
    reg     [3:0]                   reg_ctl_control;    // bit[0]:enable, bit[1]:update, bit[2]:oneshot, bit[3]:auto_addr
    reg     [0:0]                   reg_ctl_status;
    reg     [INDEX_WIDTH-1:0]       reg_ctl_index;
    reg     [0:0]                   reg_irq_enable;
    reg     [0:0]                   reg_irq_status;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_param_awaddr;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_param_awoffset;
    reg     [AXI4_LEN_WIDTH-1:0]    reg_param_awlen_max;
    reg     [AWLEN0_WIDTH-1:0]      reg_param_awlen0;
//  reg     [AWSTEP0_WIDTH-1:0]     reg_param_awstep0;
    reg     [AWLEN1_WIDTH-1:0]      reg_param_awlen1;
    reg     [AWSTEP1_WIDTH-1:0]     reg_param_awstep1;
    reg     [AWLEN2_WIDTH-1:0]      reg_param_awlen2;
    reg     [AWSTEP2_WIDTH-1:0]     reg_param_awstep2;
    reg     [AWLEN3_WIDTH-1:0]      reg_param_awlen3;
    reg     [AWSTEP3_WIDTH-1:0]     reg_param_awstep3;
    reg     [AWLEN4_WIDTH-1:0]      reg_param_awlen4;
    reg     [AWSTEP4_WIDTH-1:0]     reg_param_awstep4;
    reg     [AWLEN5_WIDTH-1:0]      reg_param_awlen5;
    reg     [AWSTEP5_WIDTH-1:0]     reg_param_awstep5;
    reg     [AWLEN6_WIDTH-1:0]      reg_param_awlen6;
    reg     [AWSTEP6_WIDTH-1:0]     reg_param_awstep6;
    reg     [AWLEN7_WIDTH-1:0]      reg_param_awlen7;
    reg     [AWSTEP7_WIDTH-1:0]     reg_param_awstep7;
    reg     [AWLEN8_WIDTH-1:0]      reg_param_awlen8;
    reg     [AWSTEP8_WIDTH-1:0]     reg_param_awstep8;
    reg     [AWLEN9_WIDTH-1:0]      reg_param_awlen9;
    reg     [AWSTEP9_WIDTH-1:0]     reg_param_awstep9;
    reg                             reg_wskip_en;
    reg     [N-1:0]                 reg_wdetect_first;
    reg     [N-1:0]                 reg_wdetect_last;
    reg                             reg_wpadding_en;
    reg     [WDATA_WIDTH-1:0]       reg_wpadding_data;
    reg     [WSTRB_WIDTH-1:0]       reg_wpadding_strb;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_shadow_awaddr;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_shadow_awoffset;
    reg     [AXI4_LEN_WIDTH-1:0]    reg_shadow_awlen_max;
    reg     [AWLEN0_WIDTH-1:0]      reg_shadow_awlen0;
//  reg     [AWSTEP0_WIDTH-1:0]     reg_shadow_awstep0;
    reg     [AWLEN1_WIDTH-1:0]      reg_shadow_awlen1;
    reg     [AWSTEP1_WIDTH-1:0]     reg_shadow_awstep1;
    reg     [AWLEN2_WIDTH-1:0]      reg_shadow_awlen2;
    reg     [AWSTEP2_WIDTH-1:0]     reg_shadow_awstep2;
    reg     [AWLEN3_WIDTH-1:0]      reg_shadow_awlen3;
    reg     [AWSTEP3_WIDTH-1:0]     reg_shadow_awstep3;
    reg     [AWLEN4_WIDTH-1:0]      reg_shadow_awlen4;
    reg     [AWSTEP4_WIDTH-1:0]     reg_shadow_awstep4;
    reg     [AWLEN5_WIDTH-1:0]      reg_shadow_awlen5;
    reg     [AWSTEP5_WIDTH-1:0]     reg_shadow_awstep5;
    reg     [AWLEN6_WIDTH-1:0]      reg_shadow_awlen6;
    reg     [AWSTEP6_WIDTH-1:0]     reg_shadow_awstep6;
    reg     [AWLEN7_WIDTH-1:0]      reg_shadow_awlen7;
    reg     [AWSTEP7_WIDTH-1:0]     reg_shadow_awstep7;
    reg     [AWLEN8_WIDTH-1:0]      reg_shadow_awlen8;
    reg     [AWSTEP8_WIDTH-1:0]     reg_shadow_awstep8;
    reg     [AWLEN9_WIDTH-1:0]      reg_shadow_awlen9;
    reg     [AWSTEP9_WIDTH-1:0]     reg_shadow_awstep9;
    
    wire                            sig_start = !reg_ctl_status && reg_ctl_control[0];
    wire                            sig_end;
    
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_awaddr;
    reg                             reg_awvalid;
    wire                            s_awready;
    
    reg                             reg_wskip;
    
    assign out_irq        = out_irq & reg_irq_enable;
    
    assign buffer_request = (sig_start && reg_ctl_control[3]);
    assign buffer_release = (sig_end || (!sig_start && !reg_ctl_status));
    
    
    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] dat,
                                        input [WB_SEL_WIDTH-1:0] sel
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            write_mask[i] = sel[i/8] ? dat[i] : org[i];
        end
    end
    endfunction
    
    always @(posedge s_wb_clk_i ) begin
        if ( s_wb_rst_i ) begin
            reg_ctl_control      <= INIT_CTL_CONTROL;
            reg_ctl_status       <= 0;
            reg_ctl_index        <= 0;
            reg_irq_enable       <= INIT_IRQ_ENABLE;
            reg_irq_status       <= 0;
            reg_param_awaddr     <= INIT_PARAM_AWADDR;
            reg_param_awoffset   <= INIT_PARAM_AWOFFSET;
            reg_param_awlen_max  <= INIT_PARAM_AWLEN_MAX;
            reg_param_awlen0     <= INIT_PARAM_AWLEN0;
//          reg_param_awstep0    <= INIT_PARAM_AWSTEP0;
            reg_param_awlen1     <= (N > 1) ? INIT_PARAM_AWLEN1  : '0;
            reg_param_awstep1    <= (N > 1) ? INIT_PARAM_AWSTEP1 : '0;
            reg_param_awlen2     <= (N > 2) ? INIT_PARAM_AWLEN2  : '0;
            reg_param_awstep2    <= (N > 2) ? INIT_PARAM_AWSTEP2 : '0;
            reg_param_awlen3     <= (N > 3) ? INIT_PARAM_AWLEN3  : '0;
            reg_param_awstep3    <= (N > 3) ? INIT_PARAM_AWSTEP3 : '0;
            reg_param_awlen4     <= (N > 4) ? INIT_PARAM_AWLEN4  : '0;
            reg_param_awstep4    <= (N > 4) ? INIT_PARAM_AWSTEP4 : '0;
            reg_param_awlen5     <= (N > 5) ? INIT_PARAM_AWLEN5  : '0;
            reg_param_awstep5    <= (N > 5) ? INIT_PARAM_AWSTEP5 : '0;
            reg_param_awlen6     <= (N > 6) ? INIT_PARAM_AWLEN6  : '0;
            reg_param_awstep6    <= (N > 6) ? INIT_PARAM_AWSTEP6 : '0;
            reg_param_awlen7     <= (N > 7) ? INIT_PARAM_AWLEN7  : '0;
            reg_param_awstep7    <= (N > 7) ? INIT_PARAM_AWSTEP7 : '0;
            reg_param_awlen8     <= (N > 8) ? INIT_PARAM_AWLEN8  : '0;
            reg_param_awstep8    <= (N > 8) ? INIT_PARAM_AWSTEP8 : '0;
            reg_param_awlen9     <= (N > 9) ? INIT_PARAM_AWLEN9  : '0;
            reg_param_awstep9    <= (N > 9) ? INIT_PARAM_AWSTEP9 : '0;
            reg_wskip_en         <= INIT_WSKIP_EN;
            reg_wdetect_first    <= INIT_WDETECT_FIRST;
            reg_wdetect_last     <= INIT_WDETECT_LAST;
            reg_wpadding_en      <= INIT_WPADDING_EN;
            reg_wpadding_data    <= INIT_WPADDING_DATA;
            reg_wpadding_strb    <= INIT_WPADDING_STRB;
            reg_shadow_awaddr    <= INIT_PARAM_AWADDR;
            reg_shadow_awoffset  <= INIT_PARAM_AWOFFSET;
            reg_shadow_awlen_max <= INIT_PARAM_AWLEN_MAX;
            reg_shadow_awlen0    <= INIT_PARAM_AWLEN0;
//          reg_shadow_awstep0   <= INIT_PARAM_AWSTEP0;
            reg_shadow_awlen1    <= (N > 1) ? INIT_PARAM_AWLEN1  : 0;
            reg_shadow_awstep1   <= (N > 1) ? INIT_PARAM_AWSTEP1 : 0;
            reg_shadow_awlen2    <= (N > 2) ? INIT_PARAM_AWLEN2  : 0;
            reg_shadow_awstep2   <= (N > 2) ? INIT_PARAM_AWSTEP2 : 0;
            reg_shadow_awlen3    <= (N > 3) ? INIT_PARAM_AWLEN3  : 0;
            reg_shadow_awstep3   <= (N > 3) ? INIT_PARAM_AWSTEP3 : 0;
            reg_shadow_awlen4    <= (N > 4) ? INIT_PARAM_AWLEN4  : 0;
            reg_shadow_awstep4   <= (N > 4) ? INIT_PARAM_AWSTEP4 : 0;
            reg_shadow_awlen5    <= (N > 5) ? INIT_PARAM_AWLEN5  : 0;
            reg_shadow_awstep5   <= (N > 5) ? INIT_PARAM_AWSTEP5 : 0;
            reg_shadow_awlen6    <= (N > 6) ? INIT_PARAM_AWLEN6  : 0;
            reg_shadow_awstep6   <= (N > 6) ? INIT_PARAM_AWSTEP6 : 0;
            reg_shadow_awlen7    <= (N > 7) ? INIT_PARAM_AWLEN7  : 0;
            reg_shadow_awstep7   <= (N > 7) ? INIT_PARAM_AWSTEP7 : 0;
            reg_shadow_awlen8    <= (N > 8) ? INIT_PARAM_AWLEN8  : 0;
            reg_shadow_awstep8   <= (N > 8) ? INIT_PARAM_AWSTEP8 : 0;
            reg_shadow_awlen9    <= (N > 9) ? INIT_PARAM_AWLEN9  : 0;
            reg_shadow_awstep9   <= (N > 9) ? INIT_PARAM_AWSTEP9 : 0;
            
            reg_awaddr           <= INIT_PARAM_AWADDR + INIT_PARAM_AWOFFSET;
            reg_awvalid          <= 1'b0;
            reg_wskip            <= 1'b0;
        end
        else begin
            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:        reg_ctl_control      <=                       4'(write_mask(WB_DAT_WIDTH'(reg_ctl_control),     s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_ENABLE:         reg_irq_enable       <=                       1'(write_mask(WB_DAT_WIDTH'(reg_irq_enable ),     s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_CLR:            reg_irq_status       <= reg_irq_status &     1'(~write_mask(WB_DAT_WIDTH'(0),                   s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_SET:            reg_irq_status       <= reg_irq_status |     1'( write_mask(WB_DAT_WIDTH'(0),                   s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_AWADDR:       reg_param_awaddr     <=         AXI4_ADDR_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awaddr),    s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_AWOFFSET:     reg_param_awoffset   <=         AXI4_ADDR_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awoffset),  s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_AWLEN_MAX:    reg_param_awlen_max  <=          AXI4_LEN_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen_max), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_AWLEN0:       reg_param_awlen0     <=            AWLEN0_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen0),    s_wb_dat_i, s_wb_sel_i));
//              ADR_PARAM_AWSTEP0:      reg_param_awstep0    <=                          write_mask(WB_DAT_WIDTH'(reg_param_awstep0),   s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_AWLEN1:       reg_param_awlen1     <= (N > 1) ?  AWLEN1_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen1),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP1:      reg_param_awstep1    <= (N > 1) ? AWSTEP1_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep1),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN2:       reg_param_awlen2     <= (N > 2) ?  AWLEN2_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen2),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP2:      reg_param_awstep2    <= (N > 2) ? AWSTEP2_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep2),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN3:       reg_param_awlen3     <= (N > 3) ?  AWLEN3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen3),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP3:      reg_param_awstep3    <= (N > 3) ? AWSTEP3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep3),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN4:       reg_param_awlen4     <= (N > 4) ?  AWLEN4_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen4),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP4:      reg_param_awstep4    <= (N > 4) ? AWSTEP4_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep4),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN5:       reg_param_awlen5     <= (N > 5) ?  AWLEN5_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen5),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP5:      reg_param_awstep5    <= (N > 5) ? AWSTEP5_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep5),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN6:       reg_param_awlen6     <= (N > 6) ?  AWLEN6_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen6),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP6:      reg_param_awstep6    <= (N > 6) ? AWSTEP6_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep6),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN7:       reg_param_awlen7     <= (N > 7) ?  AWLEN7_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen7),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP7:      reg_param_awstep7    <= (N > 7) ? AWSTEP7_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep7),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN8:       reg_param_awlen8     <= (N > 8) ?  AWLEN8_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen8),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP8:      reg_param_awstep8    <= (N > 8) ? AWSTEP8_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep8),   s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWLEN9:       reg_param_awlen9     <= (N > 9) ?  AWLEN9_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awlen9),    s_wb_dat_i, s_wb_sel_i)) : 0;
                ADR_PARAM_AWSTEP9:      reg_param_awstep9    <= (N > 9) ? AWSTEP9_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_awstep9),   s_wb_dat_i, s_wb_sel_i)) : 0;
                default: ;
                endcase
                
                if ( WDETECTOR_CHANGE ) begin
                case ( s_wb_adr_i )
                ADR_WSKIP_EN:           reg_wskip_en         <=           1'(write_mask(WB_DAT_WIDTH'(reg_wskip_en),      s_wb_dat_i, s_wb_sel_i));
                ADR_WDETECT_FIRST:      reg_wdetect_first    <=           N'(write_mask(WB_DAT_WIDTH'(reg_wdetect_first), s_wb_dat_i, s_wb_sel_i));
                ADR_WDETECT_LAST:       reg_wdetect_last     <=           N'(write_mask(WB_DAT_WIDTH'(reg_wdetect_last),  s_wb_dat_i, s_wb_sel_i));
                ADR_WPADDING_EN:        reg_wpadding_en      <=           1'(write_mask(WB_DAT_WIDTH'(reg_wpadding_en),   s_wb_dat_i, s_wb_sel_i));
                ADR_WPADDING_DATA:      reg_wpadding_data    <= WDATA_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_wpadding_data), s_wb_dat_i, s_wb_sel_i));
                ADR_WPADDING_STRB:      reg_wpadding_strb    <= WSTRB_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_wpadding_strb), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
                end
            end
            
            if ( s_awready ) begin
                reg_awvalid <= 1'b0;
            end
            
            // start
            if ( sig_start ) begin
                reg_ctl_status <= 1'b1;
                reg_awvalid    <= 1'b1;
                
                if ( reg_ctl_control[1] ) begin // update
                    reg_ctl_control[1]   <= 1'b0;
                    reg_ctl_index        <= reg_ctl_index + 1'b1;
                    
                    reg_awaddr           <= reg_param_awaddr + reg_param_awoffset;
                    
                    reg_shadow_awaddr    <= reg_param_awaddr;
                    reg_shadow_awoffset  <= reg_param_awoffset;
                    reg_shadow_awlen_max <= reg_param_awlen_max;
                    reg_shadow_awlen0    <= reg_param_awlen0;
//                  reg_shadow_awstep0   <= reg_param_awstep0;
                    reg_shadow_awlen1    <= reg_param_awlen1;
                    reg_shadow_awstep1   <= reg_param_awstep1;
                    reg_shadow_awlen2    <= reg_param_awlen2;
                    reg_shadow_awstep2   <= reg_param_awstep2;
                    reg_shadow_awlen3    <= reg_param_awlen3;
                    reg_shadow_awstep3   <= reg_param_awstep3;
                    reg_shadow_awlen4    <= reg_param_awlen4;
                    reg_shadow_awstep4   <= reg_param_awstep4;
                    reg_shadow_awlen5    <= reg_param_awlen5;
                    reg_shadow_awstep5   <= reg_param_awstep5;
                    reg_shadow_awlen6    <= reg_param_awlen6;
                    reg_shadow_awstep6   <= reg_param_awstep6;
                    reg_shadow_awlen7    <= reg_param_awlen7;
                    reg_shadow_awstep7   <= reg_param_awstep7;
                    reg_shadow_awlen8    <= reg_param_awlen8;
                    reg_shadow_awstep8   <= reg_param_awstep8;
                    reg_shadow_awlen9    <= reg_param_awlen9;
                    reg_shadow_awstep9   <= reg_param_awstep9;
                end
                
                if ( buffer_request ) begin
                    reg_awaddr        <= buffer_addr + reg_shadow_awoffset;
                    reg_shadow_awaddr <= buffer_addr;
                end
                
            end
            
            // end
            if ( sig_end ) begin
                reg_ctl_status <= 1'b0;
                if ( reg_ctl_control[2] ) begin // oneshot
                    reg_ctl_control[0] <= 1'b0;
                end
            end
            
            // skip
            reg_wskip <= reg_wskip_en && !reg_ctl_control[0] && !reg_ctl_status;
        end
    end
    
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:            s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID              );
        ADR_CORE_VERSION:       s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION         );
        ADR_CORE_CONFIG:        s_wb_dat_o = WB_DAT_WIDTH'(N                    );
        ADR_CTL_CONTROL:        s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control      );
        ADR_CTL_STATUS:         s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_status       );
        ADR_CTL_INDEX:          s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_index        );
        ADR_IRQ_ENABLE:         s_wb_dat_o = WB_DAT_WIDTH'(reg_irq_enable       );
        ADR_IRQ_STATUS:         s_wb_dat_o = WB_DAT_WIDTH'(reg_irq_status       );
        ADR_PARAM_AWADDR:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awaddr     );
        ADR_PARAM_AWOFFSET:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awoffset   );
        ADR_PARAM_AWLEN_MAX:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen_max  );
        ADR_PARAM_AWLEN0:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen0     );
//      ADR_PARAM_AWSTEP0:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep0    );
        ADR_PARAM_AWLEN1:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen1     );
        ADR_PARAM_AWSTEP1:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep1    );
        ADR_PARAM_AWLEN2:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen2     );
        ADR_PARAM_AWSTEP2:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep2    );
        ADR_PARAM_AWLEN3:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen3     );
        ADR_PARAM_AWSTEP3:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep3    );
        ADR_PARAM_AWLEN4:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen4     );
        ADR_PARAM_AWSTEP4:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep4    );
        ADR_PARAM_AWLEN5:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen5     );
        ADR_PARAM_AWSTEP5:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep5    );
        ADR_PARAM_AWLEN6:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen6     );
        ADR_PARAM_AWSTEP6:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep6    );
        ADR_PARAM_AWLEN7:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen7     );
        ADR_PARAM_AWSTEP7:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep7    );
        ADR_PARAM_AWLEN8:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen8     );
        ADR_PARAM_AWSTEP8:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep8    );
        ADR_PARAM_AWLEN9:       s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awlen9     );
        ADR_PARAM_AWSTEP9:      s_wb_dat_o = WB_DAT_WIDTH'(reg_param_awstep9    );
        ADR_WSKIP_EN:           s_wb_dat_o = WB_DAT_WIDTH'(reg_wskip_en         );
        ADR_WDETECT_FIRST:      s_wb_dat_o = WB_DAT_WIDTH'(reg_wdetect_first    );
        ADR_WDETECT_LAST:       s_wb_dat_o = WB_DAT_WIDTH'(reg_wdetect_last     );
        ADR_WPADDING_EN:        s_wb_dat_o = WB_DAT_WIDTH'(reg_wpadding_en      );
        ADR_WPADDING_DATA:      s_wb_dat_o = WB_DAT_WIDTH'(reg_wpadding_data    );
        ADR_WPADDING_STRB:      s_wb_dat_o = WB_DAT_WIDTH'(reg_wpadding_strb    );
        ADR_SHADOW_AWADDR:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awaddr    );
        ADR_SHADOW_AWOFFSET:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awoffset  );
        ADR_SHADOW_AWLEN_MAX:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen_max );
        ADR_SHADOW_AWLEN0:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen0    );
//      ADR_SHADOW_AWSTEP0:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep0   );
        ADR_SHADOW_AWLEN1:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen1    );
        ADR_SHADOW_AWSTEP1:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep1   );
        ADR_SHADOW_AWLEN2:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen2    );
        ADR_SHADOW_AWSTEP2:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep2   );
        ADR_SHADOW_AWLEN3:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen3    );
        ADR_SHADOW_AWSTEP3:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep3   );
        ADR_SHADOW_AWLEN4:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen4    );
        ADR_SHADOW_AWSTEP4:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep4   );
        ADR_SHADOW_AWLEN5:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen5    );
        ADR_SHADOW_AWSTEP5:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep5   );
        ADR_SHADOW_AWLEN6:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen6    );
        ADR_SHADOW_AWSTEP6:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep6   );
        ADR_SHADOW_AWLEN7:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen7    );
        ADR_SHADOW_AWSTEP7:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep7   );
        ADR_SHADOW_AWLEN8:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen8    );
        ADR_SHADOW_AWSTEP8:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep8   );
        ADR_SHADOW_AWLEN9:      s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awlen9    );
        ADR_SHADOW_AWSTEP9:     s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_awstep9   );
        default: ;
        endcase
    end

    always_comb s_wb_ack_o = s_wb_stb_i;
    
    
    
    // read core
    localparam LEN_MAX  = AXI4_ADDR_WIDTH;
    localparam STEP_MAX = AXI4_ADDR_WIDTH;
    
    wire    [10-1:0][LEN_MAX-1:0]       s_awlen;
    wire    [10-1:0][STEP_MAX-1:0]      s_awstep;
    
    assign s_awlen[0] = LEN_MAX'(reg_shadow_awlen0);
    assign s_awlen[1] = LEN_MAX'(reg_shadow_awlen1);
    assign s_awlen[2] = LEN_MAX'(reg_shadow_awlen2);
    assign s_awlen[3] = LEN_MAX'(reg_shadow_awlen3);
    assign s_awlen[4] = LEN_MAX'(reg_shadow_awlen4);
    assign s_awlen[5] = LEN_MAX'(reg_shadow_awlen5);
    assign s_awlen[6] = LEN_MAX'(reg_shadow_awlen6);
    assign s_awlen[7] = LEN_MAX'(reg_shadow_awlen7);
    assign s_awlen[8] = LEN_MAX'(reg_shadow_awlen8);
    assign s_awlen[9] = LEN_MAX'(reg_shadow_awlen9);
    
    assign s_awstep[0] = STEP_MAX'(1);
    assign s_awstep[1] = STEP_MAX'(reg_shadow_awstep1);
    assign s_awstep[2] = STEP_MAX'(reg_shadow_awstep2);
    assign s_awstep[3] = STEP_MAX'(reg_shadow_awstep3);
    assign s_awstep[4] = STEP_MAX'(reg_shadow_awstep4);
    assign s_awstep[5] = STEP_MAX'(reg_shadow_awstep5);
    assign s_awstep[6] = STEP_MAX'(reg_shadow_awstep6);
    assign s_awstep[7] = STEP_MAX'(reg_shadow_awstep7);
    assign s_awstep[8] = STEP_MAX'(reg_shadow_awstep8);
    assign s_awstep[9] = STEP_MAX'(reg_shadow_awstep9);
    
    
    (* ASYNC_REG = "true" *)    reg         reg_wskip_ff0, reg_wskip_ff1;
    always @(posedge s_wclk ) begin
        if ( ~s_wresetn ) begin
            reg_wskip_ff0 <= 1'b0;
            reg_wskip_ff1 <= 1'b0;
        end
        else begin
            reg_wskip_ff0 <= reg_wskip;
            reg_wskip_ff1 <= reg_wskip_ff0;
        end
    end
    
    
    wire    [N-1:0]                 s_bfirst;
    wire    [N-1:0]                 s_blast;
    wire                            s_bvalid;
    wire                            s_bready;
    
    jelly2_axi4_write_nd
            #(
                .N                      (N),
                
                .AWASYNC                (WB_ASYNC),
                .WASYNC                 (WASYNC),
                .BASYNC                 (WB_ASYNC),
                
                .BYTE_WIDTH             (BYTE_WIDTH),
                .BYPASS_GATE            (BYPASS_GATE),
                .BYPASS_ALIGN           (BYPASS_ALIGN),
                .AXI4_ALIGN             (AXI4_ALIGN),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED),
                .WDETECTOR_ENABLE       (WDETECTOR_ENABLE),
                
                .HAS_WSTRB              (HAS_WSTRB),
                .HAS_WFIRST             (HAS_WFIRST),
                .HAS_WLAST              (HAS_WLAST),
                
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
                .S_WDATA_WIDTH          (WDATA_WIDTH),
                .S_WSTRB_WIDTH          (WSTRB_WIDTH),
                .S_AWSTEP_WIDTH         (STEP_MAX),
                .S_AWLEN_WIDTH          (LEN_MAX),
                .S_AWLEN_OFFSET         (AWLEN_OFFSET),
                
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
                .CONVERT_S_REGS         (CONVERT_S_REGS),
                
                .WFIFO_PTR_WIDTH        (WFIFO_PTR_WIDTH),
                .WFIFO_RAM_TYPE         (WFIFO_RAM_TYPE),
                .WFIFO_LOW_DEALY        (WFIFO_LOW_DEALY),
                .WFIFO_DOUT_REGS        (WFIFO_DOUT_REGS),
                .WFIFO_S_REGS           (WFIFO_S_REGS),
                .WFIFO_M_REGS           (WFIFO_M_REGS),
                .AWFIFO_PTR_WIDTH       (AWFIFO_PTR_WIDTH),
                .AWFIFO_RAM_TYPE        (AWFIFO_RAM_TYPE),
                .AWFIFO_LOW_DEALY       (AWFIFO_LOW_DEALY),
                .AWFIFO_DOUT_REGS       (AWFIFO_DOUT_REGS),
                .AWFIFO_S_REGS          (AWFIFO_S_REGS),
                .AWFIFO_M_REGS          (AWFIFO_M_REGS),
                .BFIFO_PTR_WIDTH        (BFIFO_PTR_WIDTH),
                .BFIFO_RAM_TYPE         (BFIFO_RAM_TYPE),
                .BFIFO_LOW_DEALY        (BFIFO_LOW_DEALY),
                .BFIFO_DOUT_REGS        (BFIFO_DOUT_REGS),
                .BFIFO_S_REGS           (BFIFO_S_REGS),
                .BFIFO_M_REGS           (BFIFO_M_REGS),
                .SWFIFOPTR_WIDTH        (SWFIFOPTR_WIDTH),
                .SWFIFORAM_TYPE         (SWFIFORAM_TYPE),
                .SWFIFOLOW_DEALY        (SWFIFOLOW_DEALY),
                .SWFIFODOUT_REGS        (SWFIFODOUT_REGS),
                .SWFIFOS_REGS           (SWFIFOS_REGS),
                .SWFIFOM_REGS           (SWFIFOM_REGS),
                .MBFIFO_PTR_WIDTH       (MBFIFO_PTR_WIDTH),
                .MBFIFO_RAM_TYPE        (MBFIFO_RAM_TYPE),
                .MBFIFO_LOW_DEALY       (MBFIFO_LOW_DEALY),
                .MBFIFO_DOUT_REGS       (MBFIFO_DOUT_REGS),
                .MBFIFO_S_REGS          (MBFIFO_S_REGS),
                .MBFIFO_M_REGS          (MBFIFO_M_REGS),
                .WDATFIFO_PTR_WIDTH     (WDATFIFO_PTR_WIDTH),
                .WDATFIFO_DOUT_REGS     (WDATFIFO_DOUT_REGS),
                .WDATFIFO_RAM_TYPE      (WDATFIFO_RAM_TYPE),
                .WDATFIFO_LOW_DEALY     (WDATFIFO_LOW_DEALY),
                .WDATFIFO_S_REGS        (WDATFIFO_S_REGS),
                .WDATFIFO_M_REGS        (WDATFIFO_M_REGS),
                .WDAT_S_REGS            (WDAT_S_REGS),
                .WDAT_M_REGS            (WDAT_M_REGS),
                .BACKFIFO_PTR_WIDTH     (BACKFIFO_PTR_WIDTH),
                .BACKFIFO_DOUT_REGS     (BACKFIFO_DOUT_REGS),
                .BACKFIFO_RAM_TYPE      (BACKFIFO_RAM_TYPE),
                .BACKFIFO_LOW_DEALY     (BACKFIFO_LOW_DEALY),
                .BACKFIFO_S_REGS        (BACKFIFO_S_REGS),
                .BACKFIFO_M_REGS        (BACKFIFO_M_REGS),
                .BACK_S_REGS            (BACK_S_REGS),
                .BACK_M_REGS            (BACK_M_REGS)
            )
        i_axi4_write_nd
            (
                .endian                 (endian),
                
                .s_awresetn             (~s_wb_rst_i),
                .s_awclk                (s_wb_clk_i),
                .s_awaddr               (reg_awaddr),
                .s_awlen_max            (reg_shadow_awlen_max),
                .s_awstep               (s_awstep[N-1:0]),
                .s_awlen                (s_awlen [N-1:0]),
                .s_awvalid              (reg_awvalid),
                .s_awready              (s_awready),
                
                .s_wresetn              (s_wresetn),
                .s_wclk                 (s_wclk),
                .s_wdata                (s_wdata),
                .s_wstrb                (s_wstrb),
                .s_wfirst               (s_wfirst),
                .s_wlast                (s_wlast),
                .s_wvalid               (s_wvalid),
                .s_wready               (s_wready),
                
                .wskip                  (reg_wskip_ff1),
                .wdetect_first          (reg_wdetect_first),
                .wdetect_last           (reg_wdetect_last),
                .wpadding_en            (reg_wpadding_en),
                .wpadding_data          (reg_wpadding_data),
                .wpadding_strb          (reg_wpadding_strb),
                
                .s_bresetn              (~s_wb_rst_i),
                .s_bclk                 (s_wb_clk_i),
                .s_bfirst               (s_bfirst),
                .s_blast                (s_blast),
                .s_bvalid               (s_bvalid),
                .s_bready               (s_bready),
                
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
                .m_axi4_bid             (m_axi4_bid),
                .m_axi4_bresp           (m_axi4_bresp),
                .m_axi4_bvalid          (m_axi4_bvalid),
                .m_axi4_bready          (m_axi4_bready)
            );
    
    assign s_bready = 1'b1;
    
    assign sig_end   = s_bvalid & s_bready & s_blast[N-1];
    
    
endmodule


`default_nettype wire


// end of file
