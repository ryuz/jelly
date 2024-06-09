// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns/1ps
`default_nettype none



module jelly2_dma_stream_read
        #(
            // 基本設定
            parameter   int                             N                    = 2,
            parameter   int                             BYTE_WIDTH           = 8,
            
            // WISHBONE
            parameter   int                             WB_ASYNC             = 1,
            parameter   int                             WB_ADR_WIDTH         = 8,
            parameter   int                             WB_DAT_WIDTH         = 32,
            parameter   int                             WB_SEL_WIDTH         = (WB_DAT_WIDTH / 8),
            
            // read port
            parameter   bit                             RASYNC               = 1,
            parameter   int                             RDATA_WIDTH          = 32,
            parameter   bit                             HAS_RFIRST           = 0,
            parameter   bit                             HAS_RLAST            = 1,
            
            // AXI4
            parameter   int                             AXI4_ID_WIDTH        = 6,
            parameter   int                             AXI4_ADDR_WIDTH      = 32,
            parameter   int                             AXI4_DATA_SIZE       = 2,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter   int                             AXI4_DATA_WIDTH      = (BYTE_WIDTH << AXI4_DATA_SIZE),
            parameter   int                             AXI4_LEN_WIDTH       = 8,
            parameter   int                             AXI4_QOS_WIDTH       = 4,
            parameter   bit     [AXI4_ID_WIDTH-1:0]     AXI4_ARID            = {AXI4_ID_WIDTH{1'b0}},
            parameter   bit     [2:0]                   AXI4_ARSIZE          = 3'(AXI4_DATA_SIZE),
            parameter   bit     [1:0]                   AXI4_ARBURST         = 2'b01,
            parameter   bit     [0:0]                   AXI4_ARLOCK          = 1'b0,
            parameter   bit     [3:0]                   AXI4_ARCACHE         = 4'b0001,
            parameter   bit     [2:0]                   AXI4_ARPROT          = 3'b000,
            parameter   bit     [AXI4_QOS_WIDTH-1:0]    AXI4_ARQOS           = 0,
            parameter   bit     [3:0]                   AXI4_ARREGION        = 4'b0000,
            parameter   int                             AXI4_ALIGN           = 12,  // 2^12 = 4k が境界
            
            // レジスタ構成など
            parameter   int                             INDEX_WIDTH          = 1,
            parameter   bit                             ARLEN_OFFSET         = 1'b1,
            parameter   int                             ARLEN0_WIDTH         = 32,
            parameter   int                             ARLEN1_WIDTH         = 32,
            parameter   int                             ARLEN2_WIDTH         = 32,
            parameter   int                             ARLEN3_WIDTH         = 32,
            parameter   int                             ARLEN4_WIDTH         = 32,
            parameter   int                             ARLEN5_WIDTH         = 32,
            parameter   int                             ARLEN6_WIDTH         = 32,
            parameter   int                             ARLEN7_WIDTH         = 32,
            parameter   int                             ARLEN8_WIDTH         = 32,
            parameter   int                             ARLEN9_WIDTH         = 32,
            parameter   int                             ARSTEP1_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP2_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP3_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP4_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP5_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP6_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP7_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP8_WIDTH        = AXI4_ADDR_WIDTH,
            parameter   int                             ARSTEP9_WIDTH        = AXI4_ADDR_WIDTH,
            
            // レジスタ初期値
            parameter   bit     [3:0]                   INIT_CTL_CONTROL     = 4'b0000,
            parameter   bit     [0:0]                   INIT_IRQ_ENABLE      = 1'b0,
            parameter   bit     [AXI4_ADDR_WIDTH-1:0]   INIT_PARAM_ARADDR    = 0,
            parameter   bit     [AXI4_ADDR_WIDTH-1:0]   INIT_PARAM_AROFFSET  = 0,
            parameter   bit     [AXI4_LEN_WIDTH-1:0]    INIT_PARAM_ARLEN_MAX = 0,
            parameter   bit     [ARLEN0_WIDTH-1:0]      INIT_PARAM_ARLEN0    = 0,
//          parameter   bit     [ARSTEP0_WIDTH-1:0]     INIT_PARAM_ARSTEP0   = 0,
            parameter   bit     [ARLEN1_WIDTH-1:0]      INIT_PARAM_ARLEN1    = 0,
            parameter   bit     [ARSTEP1_WIDTH-1:0]     INIT_PARAM_ARSTEP1   = 0,
            parameter   bit     [ARLEN2_WIDTH-1:0]      INIT_PARAM_ARLEN2    = 0,
            parameter   bit     [ARSTEP2_WIDTH-1:0]     INIT_PARAM_ARSTEP2   = 0,
            parameter   bit     [ARLEN3_WIDTH-1:0]      INIT_PARAM_ARLEN3    = 0,
            parameter   bit     [ARSTEP3_WIDTH-1:0]     INIT_PARAM_ARSTEP3   = 0,
            parameter   bit     [ARLEN4_WIDTH-1:0]      INIT_PARAM_ARLEN4    = 0,
            parameter   bit     [ARSTEP4_WIDTH-1:0]     INIT_PARAM_ARSTEP4   = 0,
            parameter   bit     [ARLEN5_WIDTH-1:0]      INIT_PARAM_ARLEN5    = 0,
            parameter   bit     [ARSTEP5_WIDTH-1:0]     INIT_PARAM_ARSTEP5   = 0,
            parameter   bit     [ARLEN6_WIDTH-1:0]      INIT_PARAM_ARLEN6    = 0,
            parameter   bit     [ARSTEP6_WIDTH-1:0]     INIT_PARAM_ARSTEP6   = 0,
            parameter   bit     [ARLEN7_WIDTH-1:0]      INIT_PARAM_ARLEN7    = 0,
            parameter   bit     [ARSTEP7_WIDTH-1:0]     INIT_PARAM_ARSTEP7   = 0,
            parameter   bit     [ARLEN8_WIDTH-1:0]      INIT_PARAM_ARLEN8    = 0,
            parameter   bit     [ARSTEP8_WIDTH-1:0]     INIT_PARAM_ARSTEP8   = 0,
            parameter   bit     [ARLEN9_WIDTH-1:0]      INIT_PARAM_ARLEN9    = 0,
            parameter   bit     [ARSTEP9_WIDTH-1:0]     INIT_PARAM_ARSTEP9   = 0,
            
            // 構成情報
            parameter                                   CORE_ID              = 32'h527a_0120,
            parameter                                   CORE_VERSION         = 32'h0000_0000,
            parameter   bit                             BYPASS_GATE          = 0,
            parameter   bit                             BYPASS_ALIGN         = 0,
            parameter   bit                             ALLOW_UNALIGNED      = 1,
            parameter   int                             CAPACITY_WIDTH       = 32,
            parameter   int                             RFIFO_PTR_WIDTH      = 9,
            parameter                                   RFIFO_RAM_TYPE       = "block",
            parameter   bit                             RFIFO_LOW_DEALY      = 0,
            parameter   bit                             RFIFO_DOUT_REGS      = 1,
            parameter   bit                             RFIFO_S_REGS         = 0,
            parameter   bit                             RFIFO_M_REGS         = 1,
            parameter                                   ARFIFO_PTR_WIDTH     = 4,
            parameter                                   ARFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             ARFIFO_LOW_DEALY     = 1,
            parameter   bit                             ARFIFO_DOUT_REGS     = 0,
            parameter   bit                             ARFIFO_S_REGS        = 0,
            parameter   bit                             ARFIFO_M_REGS        = 0,
            parameter   int                             SRFIFO_PTR_WIDTH     = 4,
            parameter                                   SRFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             SRFIFO_LOW_DEALY     = 0,
            parameter   bit                             SRFIFO_DOUT_REGS     = 0,
            parameter   bit                             SRFIFO_S_REGS        = 0,
            parameter   bit                             SRFIFO_M_REGS        = 0,
            parameter   int                             MRFIFO_PTR_WIDTH     = 4,
            parameter                                   MRFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             MRFIFO_LOW_DEALY     = 1,
            parameter   bit                             MRFIFO_DOUT_REGS     = 0,
            parameter   bit                             MRFIFO_S_REGS        = 0,
            parameter   bit                             MRFIFO_M_REGS        = 0,
            parameter   int                             RACKFIFO_PTR_WIDTH   = 4,
            parameter   bit                             RACKFIFO_DOUT_REGS   = 0,
            parameter                                   RACKFIFO_RAM_TYPE    = "distributed",
            parameter   bit                             RACKFIFO_LOW_DEALY   = 1,
            parameter   bit                             RACKFIFO_S_REGS      = 0,
            parameter   bit                             RACKFIFO_M_REGS      = 0,
            parameter   bit                             RACK_S_REGS          = 0,
            parameter   bit                             RACK_M_REGS          = 1,
            parameter   int                             CACKFIFO_PTR_WIDTH   = 4,
            parameter   bit                             CACKFIFO_DOUT_REGS   = 0,
            parameter                                   CACKFIFO_RAM_TYPE    = "distributed",
            parameter   bit                             CACKFIFO_LOW_DEALY   = 1,
            parameter   bit                             CACKFIFO_S_REGS      = 0,
            parameter   bit                             CACKFIFO_M_REGS      = 0,
            parameter   bit                             CACK_S_REGS          = 0,
            parameter   bit                             CACK_M_REGS          = 1,
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
            
            
            // read stream
            input   wire                            s_rresetn,
            input   wire                            s_rclk,
            output  wire    [RDATA_WIDTH-1:0]       s_rdata,
            output  wire    [N-1:0]                 s_rfirst,
            output  wire    [N-1:0]                 s_rlast,
            output  wire                            s_rvalid,
            input   wire                            s_rready,
            
            // AXI4
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
    
    
    // address mask
    localparam  [AXI4_ADDR_WIDTH-1:0]   ADDR_MASK = ~((1 << AXI4_DATA_SIZE) - 1);
    
    
    // ---------------------------------
    //  Register
    // ---------------------------------
    
    // register address offset
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_ID          = WB_ADR_WIDTH'('h00);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION     = WB_ADR_WIDTH'('h01);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CORE_CONFIG      = WB_ADR_WIDTH'('h03);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_CONTROL      = WB_ADR_WIDTH'('h04);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_STATUS       = WB_ADR_WIDTH'('h05);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_CTL_INDEX        = WB_ADR_WIDTH'('h07);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_IRQ_ENABLE       = WB_ADR_WIDTH'('h08);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_IRQ_STATUS       = WB_ADR_WIDTH'('h09);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_IRQ_CLR          = WB_ADR_WIDTH'('h0a);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_IRQ_SET          = WB_ADR_WIDTH'('h0b);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARADDR     = WB_ADR_WIDTH'('h10);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_AROFFSET   = WB_ADR_WIDTH'('h18);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN_MAX  = WB_ADR_WIDTH'('h1c);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN0     = WB_ADR_WIDTH'('h20);
//  localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP0    = WB_ADR_WIDTH'('h21);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN1     = WB_ADR_WIDTH'('h24);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP1    = WB_ADR_WIDTH'('h25);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN2     = WB_ADR_WIDTH'('h28);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP2    = WB_ADR_WIDTH'('h29);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN3     = WB_ADR_WIDTH'('h2c);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP3    = WB_ADR_WIDTH'('h2d);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN4     = WB_ADR_WIDTH'('h30);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP4    = WB_ADR_WIDTH'('h31);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN5     = WB_ADR_WIDTH'('h34);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP5    = WB_ADR_WIDTH'('h35);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN6     = WB_ADR_WIDTH'('h38);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP6    = WB_ADR_WIDTH'('h39);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN7     = WB_ADR_WIDTH'('h3c);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP7    = WB_ADR_WIDTH'('h3d);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN8     = WB_ADR_WIDTH'('h40);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP8    = WB_ADR_WIDTH'('h41);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARLEN9     = WB_ADR_WIDTH'('h44);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_PARAM_ARSTEP9    = WB_ADR_WIDTH'('h45);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARADDR    = WB_ADR_WIDTH'('h90);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_AROFFSET  = WB_ADR_WIDTH'('h98);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN_MAX = WB_ADR_WIDTH'('h9c);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN0    = WB_ADR_WIDTH'('ha0);
//  localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP0   = WB_ADR_WIDTH'('ha1);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN1    = WB_ADR_WIDTH'('ha4);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP1   = WB_ADR_WIDTH'('ha5);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN2    = WB_ADR_WIDTH'('ha8);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP2   = WB_ADR_WIDTH'('ha9);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN3    = WB_ADR_WIDTH'('hac);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP3   = WB_ADR_WIDTH'('had);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN4    = WB_ADR_WIDTH'('hb0);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP4   = WB_ADR_WIDTH'('hb1);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN5    = WB_ADR_WIDTH'('hb4);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP5   = WB_ADR_WIDTH'('hb5);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN6    = WB_ADR_WIDTH'('hb8);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP6   = WB_ADR_WIDTH'('hb9);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN7    = WB_ADR_WIDTH'('hbc);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP7   = WB_ADR_WIDTH'('hbd);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN8    = WB_ADR_WIDTH'('hc0);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP8   = WB_ADR_WIDTH'('hc1);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARLEN9    = WB_ADR_WIDTH'('hc4);
    localparam  bit     [WB_ADR_WIDTH-1:0]  ADR_SHADOW_ARSTEP9   = WB_ADR_WIDTH'('hc5);
    
    
    // registers
    reg     [3:0]                   reg_ctl_control;    // bit[0]:enable, bit[1]:update, bit[2]:oneshot, bit[3]:auto_addr
    reg     [0:0]                   reg_ctl_status;
    reg     [INDEX_WIDTH-1:0]       reg_ctl_index;
    reg     [0:0]                   reg_irq_enable;
    reg     [0:0]                   reg_irq_status;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_param_araddr;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_param_aroffset;
    reg     [AXI4_LEN_WIDTH-1:0]    reg_param_arlen_max;
    reg     [ARLEN0_WIDTH-1:0]      reg_param_arlen0;
//  reg     [ARSTEP0_WIDTH-1:0]     reg_param_arstep0;
    reg     [ARLEN1_WIDTH-1:0]      reg_param_arlen1;
    reg     [ARSTEP1_WIDTH-1:0]     reg_param_arstep1;
    reg     [ARLEN2_WIDTH-1:0]      reg_param_arlen2;
    reg     [ARSTEP2_WIDTH-1:0]     reg_param_arstep2;
    reg     [ARLEN3_WIDTH-1:0]      reg_param_arlen3;
    reg     [ARSTEP3_WIDTH-1:0]     reg_param_arstep3;
    reg     [ARLEN4_WIDTH-1:0]      reg_param_arlen4;
    reg     [ARSTEP4_WIDTH-1:0]     reg_param_arstep4;
    reg     [ARLEN5_WIDTH-1:0]      reg_param_arlen5;
    reg     [ARSTEP5_WIDTH-1:0]     reg_param_arstep5;
    reg     [ARLEN6_WIDTH-1:0]      reg_param_arlen6;
    reg     [ARSTEP6_WIDTH-1:0]     reg_param_arstep6;
    reg     [ARLEN7_WIDTH-1:0]      reg_param_arlen7;
    reg     [ARSTEP7_WIDTH-1:0]     reg_param_arstep7;
    reg     [ARLEN8_WIDTH-1:0]      reg_param_arlen8;
    reg     [ARSTEP8_WIDTH-1:0]     reg_param_arstep8;
    reg     [ARLEN9_WIDTH-1:0]      reg_param_arlen9;
    reg     [ARSTEP9_WIDTH-1:0]     reg_param_arstep9;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_shadow_araddr;
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_shadow_aroffset;
    reg     [AXI4_LEN_WIDTH-1:0]    reg_shadow_arlen_max;
    reg     [ARLEN0_WIDTH-1:0]      reg_shadow_arlen0;
//  reg     [ARSTEP0_WIDTH-1:0]     reg_shadow_arstep0;
    reg     [ARLEN1_WIDTH-1:0]      reg_shadow_arlen1;
    reg     [ARSTEP1_WIDTH-1:0]     reg_shadow_arstep1;
    reg     [ARLEN2_WIDTH-1:0]      reg_shadow_arlen2;
    reg     [ARSTEP2_WIDTH-1:0]     reg_shadow_arstep2;
    reg     [ARLEN3_WIDTH-1:0]      reg_shadow_arlen3;
    reg     [ARSTEP3_WIDTH-1:0]     reg_shadow_arstep3;
    reg     [ARLEN4_WIDTH-1:0]      reg_shadow_arlen4;
    reg     [ARSTEP4_WIDTH-1:0]     reg_shadow_arstep4;
    reg     [ARLEN5_WIDTH-1:0]      reg_shadow_arlen5;
    reg     [ARSTEP5_WIDTH-1:0]     reg_shadow_arstep5;
    reg     [ARLEN6_WIDTH-1:0]      reg_shadow_arlen6;
    reg     [ARSTEP6_WIDTH-1:0]     reg_shadow_arstep6;
    reg     [ARLEN7_WIDTH-1:0]      reg_shadow_arlen7;
    reg     [ARSTEP7_WIDTH-1:0]     reg_shadow_arstep7;
    reg     [ARLEN8_WIDTH-1:0]      reg_shadow_arlen8;
    reg     [ARSTEP8_WIDTH-1:0]     reg_shadow_arstep8;
    reg     [ARLEN9_WIDTH-1:0]      reg_shadow_arlen9;
    reg     [ARSTEP9_WIDTH-1:0]     reg_shadow_arstep9;
    
    wire                            sig_start = !reg_ctl_status && reg_ctl_control[0];
    wire                            sig_end;
    
    reg     [AXI4_ADDR_WIDTH-1:0]   reg_araddr;
    reg                             reg_arvalid;
    wire                            s_arready;
    
    assign out_irq        = |(reg_irq_status & reg_irq_enable);
    
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
    
    always_ff @(posedge s_wb_clk_i ) begin
        if ( s_wb_rst_i ) begin
            reg_ctl_control      <= INIT_CTL_CONTROL;
            reg_ctl_status       <= 0;
            reg_ctl_index        <= 0;
            reg_irq_enable       <= INIT_IRQ_ENABLE;
            reg_irq_status       <= 0;
            reg_param_araddr     <= INIT_PARAM_ARADDR;
            reg_param_aroffset   <= INIT_PARAM_AROFFSET;
            reg_param_arlen_max  <= INIT_PARAM_ARLEN_MAX;
            reg_param_arlen0     <= INIT_PARAM_ARLEN0;
//          reg_param_arstep0    <= INIT_PARAM_ARSTEP0;
            reg_param_arlen1     <= (N > 1) ? INIT_PARAM_ARLEN1  : 0;
            reg_param_arstep1    <= (N > 1) ? INIT_PARAM_ARSTEP1 : 0;
            reg_param_arlen2     <= (N > 2) ? INIT_PARAM_ARLEN2  : 0;
            reg_param_arstep2    <= (N > 2) ? INIT_PARAM_ARSTEP2 : 0;
            reg_param_arlen3     <= (N > 3) ? INIT_PARAM_ARLEN3  : 0;
            reg_param_arstep3    <= (N > 3) ? INIT_PARAM_ARSTEP3 : 0;
            reg_param_arlen4     <= (N > 4) ? INIT_PARAM_ARLEN4  : 0;
            reg_param_arstep4    <= (N > 4) ? INIT_PARAM_ARSTEP4 : 0;
            reg_param_arlen5     <= (N > 5) ? INIT_PARAM_ARLEN5  : 0;
            reg_param_arstep5    <= (N > 5) ? INIT_PARAM_ARSTEP5 : 0;
            reg_param_arlen6     <= (N > 6) ? INIT_PARAM_ARLEN6  : 0;
            reg_param_arstep6    <= (N > 6) ? INIT_PARAM_ARSTEP6 : 0;
            reg_param_arlen7     <= (N > 7) ? INIT_PARAM_ARLEN7  : 0;
            reg_param_arstep7    <= (N > 7) ? INIT_PARAM_ARSTEP7 : 0;
            reg_param_arlen8     <= (N > 8) ? INIT_PARAM_ARLEN8  : 0;
            reg_param_arstep8    <= (N > 8) ? INIT_PARAM_ARSTEP8 : 0;
            reg_param_arlen9     <= (N > 9) ? INIT_PARAM_ARLEN9  : 0;
            reg_param_arstep9    <= (N > 9) ? INIT_PARAM_ARSTEP9 : 0;
            reg_shadow_araddr    <= INIT_PARAM_ARADDR;
            reg_shadow_aroffset  <= INIT_PARAM_AROFFSET;
            reg_shadow_arlen_max <= INIT_PARAM_ARLEN_MAX;
            reg_shadow_arlen0    <= INIT_PARAM_ARLEN0;
//          reg_shadow_arstep0   <= INIT_PARAM_ARSTEP0;
            reg_shadow_arlen1    <= (N > 1) ? INIT_PARAM_ARLEN1  : 0;
            reg_shadow_arstep1   <= (N > 1) ? INIT_PARAM_ARSTEP1 : 0;
            reg_shadow_arlen2    <= (N > 2) ? INIT_PARAM_ARLEN2  : 0;
            reg_shadow_arstep2   <= (N > 2) ? INIT_PARAM_ARSTEP2 : 0;
            reg_shadow_arlen3    <= (N > 3) ? INIT_PARAM_ARLEN3  : 0;
            reg_shadow_arstep3   <= (N > 3) ? INIT_PARAM_ARSTEP3 : 0;
            reg_shadow_arlen4    <= (N > 4) ? INIT_PARAM_ARLEN4  : 0;
            reg_shadow_arstep4   <= (N > 4) ? INIT_PARAM_ARSTEP4 : 0;
            reg_shadow_arlen5    <= (N > 5) ? INIT_PARAM_ARLEN5  : 0;
            reg_shadow_arstep5   <= (N > 5) ? INIT_PARAM_ARSTEP5 : 0;
            reg_shadow_arlen6    <= (N > 6) ? INIT_PARAM_ARLEN6  : 0;
            reg_shadow_arstep6   <= (N > 6) ? INIT_PARAM_ARSTEP6 : 0;
            reg_shadow_arlen7    <= (N > 7) ? INIT_PARAM_ARLEN7  : 0;
            reg_shadow_arstep7   <= (N > 7) ? INIT_PARAM_ARSTEP7 : 0;
            reg_shadow_arlen8    <= (N > 8) ? INIT_PARAM_ARLEN8  : 0;
            reg_shadow_arstep8   <= (N > 8) ? INIT_PARAM_ARSTEP8 : 0;
            reg_shadow_arlen9    <= (N > 9) ? INIT_PARAM_ARLEN9  : 0;
            reg_shadow_arstep9   <= (N > 9) ? INIT_PARAM_ARSTEP9 : 0;
            
            reg_araddr           <= INIT_PARAM_ARADDR + INIT_PARAM_AROFFSET;
            reg_arvalid          <= 1'b0;
        end
        else begin
            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:        reg_ctl_control      <=                      4'( write_mask(WB_DAT_WIDTH'(reg_ctl_control),     s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_ENABLE:         reg_irq_enable       <=                      1'( write_mask(WB_DAT_WIDTH'(reg_irq_enable ),     s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_CLR:            reg_irq_status       <= reg_irq_status &     1'(~write_mask(WB_DAT_WIDTH'(0),                   s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_SET:            reg_irq_status       <= reg_irq_status |     1'( write_mask(WB_DAT_WIDTH'(0),                   s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_ARADDR:       reg_param_araddr     <=         AXI4_ADDR_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_araddr),    s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_AROFFSET:     reg_param_aroffset   <=         AXI4_ADDR_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_aroffset),  s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_ARLEN_MAX:    reg_param_arlen_max  <=          AXI4_LEN_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen_max), s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_ARLEN0:       reg_param_arlen0     <=            ARLEN0_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen0),    s_wb_dat_i, s_wb_sel_i));
//              ADR_PARAM_ARSTEP0:      reg_param_arstep0    <=                          write_mask(WB_DAT_WIDTH'(reg_param_arstep0),   s_wb_dat_i, s_wb_sel_i));
                ADR_PARAM_ARLEN1:       reg_param_arlen1     <= (N > 1) ?  ARLEN1_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen1 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP1:      reg_param_arstep1    <= (N > 1) ? ARSTEP1_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep1),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN2:       reg_param_arlen2     <= (N > 2) ?  ARLEN2_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen2 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP2:      reg_param_arstep2    <= (N > 2) ? ARSTEP2_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep2),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN3:       reg_param_arlen3     <= (N > 3) ?  ARLEN3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen3 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP3:      reg_param_arstep3    <= (N > 3) ? ARSTEP3_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep3),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN4:       reg_param_arlen4     <= (N > 4) ?  ARLEN4_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen4 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP4:      reg_param_arstep4    <= (N > 4) ? ARSTEP4_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep4),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN5:       reg_param_arlen5     <= (N > 5) ?  ARLEN5_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen5 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP5:      reg_param_arstep5    <= (N > 5) ? ARSTEP5_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep5),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN6:       reg_param_arlen6     <= (N > 6) ?  ARLEN6_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen6 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP6:      reg_param_arstep6    <= (N > 6) ? ARSTEP6_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep6),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN7:       reg_param_arlen7     <= (N > 7) ?  ARLEN7_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen7 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP7:      reg_param_arstep7    <= (N > 7) ? ARSTEP7_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep7),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN8:       reg_param_arlen8     <= (N > 8) ?  ARLEN8_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen8 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP8:      reg_param_arstep8    <= (N > 8) ? ARSTEP8_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep8),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARLEN9:       reg_param_arlen9     <= (N > 9) ?  ARLEN9_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arlen9 ),   s_wb_dat_i, s_wb_sel_i)) : '0;
                ADR_PARAM_ARSTEP9:      reg_param_arstep9    <= (N > 9) ? ARSTEP9_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_param_arstep9),   s_wb_dat_i, s_wb_sel_i)) : '0;
                default: ;
                endcase
            end
            
            if ( s_arready ) begin
                reg_arvalid <= 1'b0;
            end
            
            // start
            if ( sig_start ) begin
                reg_ctl_status <= 1'b1;
                reg_arvalid    <= 1'b1;
                
                if ( reg_ctl_control[1] ) begin // update
                    reg_ctl_control[1]   <= 1'b0;
                    reg_ctl_index        <= reg_ctl_index + 1'b1;
                    
                    reg_araddr           <= reg_param_araddr + reg_param_aroffset;
                    
                    reg_shadow_araddr    <= reg_param_araddr;
                    reg_shadow_aroffset  <= reg_param_aroffset;
                    reg_shadow_arlen_max <= reg_param_arlen_max;
                    reg_shadow_arlen0    <= reg_param_arlen0;
//                  reg_shadow_arstep0   <= reg_param_arstep0;
                    reg_shadow_arlen1    <= reg_param_arlen1;
                    reg_shadow_arstep1   <= reg_param_arstep1;
                    reg_shadow_arlen2    <= reg_param_arlen2;
                    reg_shadow_arstep2   <= reg_param_arstep2;
                    reg_shadow_arlen3    <= reg_param_arlen3;
                    reg_shadow_arstep3   <= reg_param_arstep3;
                    reg_shadow_arlen4    <= reg_param_arlen4;
                    reg_shadow_arstep4   <= reg_param_arstep4;
                    reg_shadow_arlen5    <= reg_param_arlen5;
                    reg_shadow_arstep5   <= reg_param_arstep5;
                    reg_shadow_arlen6    <= reg_param_arlen6;
                    reg_shadow_arstep6   <= reg_param_arstep6;
                    reg_shadow_arlen7    <= reg_param_arlen7;
                    reg_shadow_arstep7   <= reg_param_arstep7;
                    reg_shadow_arlen8    <= reg_param_arlen8;
                    reg_shadow_arstep8   <= reg_param_arstep8;
                    reg_shadow_arlen9    <= reg_param_arlen9;
                    reg_shadow_arstep9   <= reg_param_arstep9;
                end
                
                if ( buffer_request ) begin
                    reg_araddr           <= buffer_addr + reg_shadow_aroffset;
                    reg_shadow_araddr    <= buffer_addr;
                end
                
            end
            
            // end
            if ( sig_end ) begin
                reg_ctl_status <= 1'b0;
                if ( reg_ctl_control[2] ) begin // oneshot
                    reg_ctl_control[0] <= 1'b0;
                end
            end
        end
    end
    
    always_comb begin
        s_wb_dat_o = '0;
        case (s_wb_adr_i )
        ADR_CORE_ID:          s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID             );
        ADR_CORE_VERSION:     s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION        );
        ADR_CORE_CONFIG:      s_wb_dat_o = WB_DAT_WIDTH'(N                   );
        ADR_CTL_CONTROL:      s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control     );
        ADR_CTL_STATUS:       s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_status      );
        ADR_CTL_INDEX:        s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_index       );
        ADR_IRQ_ENABLE:       s_wb_dat_o = WB_DAT_WIDTH'(reg_irq_enable      );
        ADR_IRQ_STATUS:       s_wb_dat_o = WB_DAT_WIDTH'(reg_irq_status      );
        ADR_PARAM_ARADDR:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_araddr    );
        ADR_PARAM_AROFFSET:   s_wb_dat_o = WB_DAT_WIDTH'(reg_param_aroffset  );
        ADR_PARAM_ARLEN_MAX:  s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen_max );
        ADR_PARAM_ARLEN0:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen0    );
//      ADR_PARAM_ARSTEP0:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep0   );
        ADR_PARAM_ARLEN1:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen1    );
        ADR_PARAM_ARSTEP1:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep1   );
        ADR_PARAM_ARLEN2:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen2    );
        ADR_PARAM_ARSTEP2:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep2   );
        ADR_PARAM_ARLEN3:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen3    );
        ADR_PARAM_ARSTEP3:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep3   );
        ADR_PARAM_ARLEN4:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen4    );
        ADR_PARAM_ARSTEP4:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep4   );
        ADR_PARAM_ARLEN5:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen5    );
        ADR_PARAM_ARSTEP5:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep5   );
        ADR_PARAM_ARLEN6:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen6    );
        ADR_PARAM_ARSTEP6:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep6   );
        ADR_PARAM_ARLEN7:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen7    );
        ADR_PARAM_ARSTEP7:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep7   );
        ADR_PARAM_ARLEN8:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen8    );
        ADR_PARAM_ARSTEP8:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep8   );
        ADR_PARAM_ARLEN9:     s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arlen9    );
        ADR_PARAM_ARSTEP9:    s_wb_dat_o = WB_DAT_WIDTH'(reg_param_arstep9   );
        ADR_SHADOW_ARADDR:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_araddr   );
        ADR_SHADOW_AROFFSET:  s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_aroffset );
        ADR_SHADOW_ARLEN_MAX: s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen_max);
        ADR_SHADOW_ARLEN0:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen0   );
//      ADR_SHADOW_ARSTEP0:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep0  );
        ADR_SHADOW_ARLEN1:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen1   );
        ADR_SHADOW_ARSTEP1:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep1  );
        ADR_SHADOW_ARLEN2:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen2   );
        ADR_SHADOW_ARSTEP2:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep2  );
        ADR_SHADOW_ARLEN3:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen3   );
        ADR_SHADOW_ARSTEP3:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep3  );
        ADR_SHADOW_ARLEN4:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen4   );
        ADR_SHADOW_ARSTEP4:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep4  );
        ADR_SHADOW_ARLEN5:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen5   );
        ADR_SHADOW_ARSTEP5:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep5  );
        ADR_SHADOW_ARLEN6:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen6   );
        ADR_SHADOW_ARSTEP6:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep6  );
        ADR_SHADOW_ARLEN7:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen7   );
        ADR_SHADOW_ARSTEP7:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep7  );
        ADR_SHADOW_ARLEN8:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen8   );
        ADR_SHADOW_ARSTEP8:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep8  );
        ADR_SHADOW_ARLEN9:    s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arlen9   );
        ADR_SHADOW_ARSTEP9:   s_wb_dat_o = WB_DAT_WIDTH'(reg_shadow_arstep9  );
        default: ;
        endcase
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    
    
    
    // read core
    localparam LEN_MAX  = AXI4_ADDR_WIDTH;
    localparam STEP_MAX = AXI4_ADDR_WIDTH;
    
    wire    [10-1:0][LEN_MAX-1:0]     s_arlen;
    wire    [10-1:0][STEP_MAX-1:0]    s_arstep;
    
    assign s_arlen[0]  = LEN_MAX'(reg_shadow_arlen0);
    assign s_arlen[1]  = LEN_MAX'(reg_shadow_arlen1);
    assign s_arlen[2]  = LEN_MAX'(reg_shadow_arlen2);
    assign s_arlen[3]  = LEN_MAX'(reg_shadow_arlen3);
    assign s_arlen[4]  = LEN_MAX'(reg_shadow_arlen4);
    assign s_arlen[5]  = LEN_MAX'(reg_shadow_arlen5);
    assign s_arlen[6]  = LEN_MAX'(reg_shadow_arlen6);
    assign s_arlen[7]  = LEN_MAX'(reg_shadow_arlen7);
    assign s_arlen[8]  = LEN_MAX'(reg_shadow_arlen8);
    assign s_arlen[9]  = LEN_MAX'(reg_shadow_arlen9);
    
    assign s_arstep[0] = STEP_MAX'(1);
    assign s_arstep[1] = STEP_MAX'(reg_shadow_arstep1);
    assign s_arstep[2] = STEP_MAX'(reg_shadow_arstep2);
    assign s_arstep[3] = STEP_MAX'(reg_shadow_arstep3);
    assign s_arstep[4] = STEP_MAX'(reg_shadow_arstep4);
    assign s_arstep[5] = STEP_MAX'(reg_shadow_arstep5);
    assign s_arstep[6] = STEP_MAX'(reg_shadow_arstep6);
    assign s_arstep[7] = STEP_MAX'(reg_shadow_arstep7);
    assign s_arstep[8] = STEP_MAX'(reg_shadow_arstep8);
    assign s_arstep[9] = STEP_MAX'(reg_shadow_arstep9);
    
    
    wire    [N-1:0]                 s_cfirst;
    wire    [N-1:0]                 s_clast;
    wire                            s_cvalid;
    wire                            s_cready;
    
    jelly2_axi4_read_nd
            #(
                .N                      (N),
                .ARASYNC                (WB_ASYNC),
                .RASYNC                 (RASYNC),
                .CASYNC                 (WB_ASYNC),
                .BYTE_WIDTH             (BYTE_WIDTH),
                .BYPASS_GATE            (BYPASS_GATE),
                .BYPASS_ALIGN           (BYPASS_ALIGN),
                .AXI4_ALIGN             (AXI4_ALIGN),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED),
                .HAS_RFIRST             (HAS_RFIRST),
                .HAS_RLAST              (HAS_RLAST),
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
                .S_RDATA_WIDTH          (RDATA_WIDTH),
                .S_ARSTEP_WIDTH         (STEP_MAX),
                .S_ARLEN_WIDTH          (LEN_MAX),
                .S_ARLEN_OFFSET         (ARLEN_OFFSET),
                .CAPACITY_WIDTH         (CAPACITY_WIDTH),
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
                .RACKFIFO_PTR_WIDTH     (RACKFIFO_PTR_WIDTH),
                .RACKFIFO_DOUT_REGS     (RACKFIFO_DOUT_REGS),
                .RACKFIFO_RAM_TYPE      (RACKFIFO_RAM_TYPE),
                .RACKFIFO_LOW_DEALY     (RACKFIFO_LOW_DEALY),
                .RACKFIFO_S_REGS        (RACKFIFO_S_REGS),
                .RACKFIFO_M_REGS        (RACKFIFO_M_REGS),
                .RACK_S_REGS            (RACK_S_REGS),
                .RACK_M_REGS            (RACK_M_REGS),
                .CACKFIFO_PTR_WIDTH     (CACKFIFO_PTR_WIDTH),
                .CACKFIFO_DOUT_REGS     (CACKFIFO_DOUT_REGS),
                .CACKFIFO_RAM_TYPE      (CACKFIFO_RAM_TYPE),
                .CACKFIFO_LOW_DEALY     (CACKFIFO_LOW_DEALY),
                .CACKFIFO_S_REGS        (CACKFIFO_S_REGS),
                .CACKFIFO_M_REGS        (CACKFIFO_M_REGS),
                .CACK_S_REGS            (CACK_S_REGS),
                .CACK_M_REGS            (CACK_M_REGS)
            )
        i_axi4_read_nd
            (
                .endian                 (endian),
                
                .s_arresetn             (~s_wb_rst_i),
                .s_arclk                (s_wb_clk_i),
                .s_araddr               (reg_araddr),
                .s_arlen_max            (reg_shadow_arlen_max),
                .s_arstep               (s_arstep[N-1:0]),
                .s_arlen                (s_arlen[N-1:0]),
                .s_arvalid              (reg_arvalid),
                .s_arready              (s_arready),
                
                .s_rresetn              (s_rresetn),
                .s_rclk                 (s_rclk),
                .s_rdata                (s_rdata),
                .s_rfirst               (s_rfirst),
                .s_rlast                (s_rlast),
                .s_rvalid               (s_rvalid),
                .s_rready               (s_rready),
                
                .s_cresetn              (~s_wb_rst_i),
                .s_cclk                 (s_wb_clk_i),
                .s_cfirst               (s_cfirst),
                .s_clast                (s_clast),
                .s_cvalid               (s_cvalid),
                .s_cready               (s_cready),
                
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
    
    // 終了検出
    assign s_cready = 1'b1;
    assign sig_end  = s_cvalid & s_cready & s_clast[N-1];
    
    
endmodule


`default_nettype wire


// end of file
