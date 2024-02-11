// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns/1ps
`default_nettype none


module jelly3_dma_stream_write
        #(
            // 基本設定
            parameter   int                             N                   = 2,
            parameter   int                             AWADDR_BITS         = 32,

            parameter   int                             AXI4S_BYTE_BITS     = 8,
            parameter   int                             AXI4S_DATA_BITS     = 32,
            parameter   int                             AXI4S_STRB_BITS     = AXI4S_DATA_BITS / AXI4S_BYTE_BITS,

            // control port(AXI4-Lite)
            parameter   bit                             AXI4L_ASYNC         = 1,
            parameter   int                             REGADR_BITS         = 8,

            // write port(AXI4-Stream)
            parameter   bit                             AXI4S_ASYNC          = 1,
            parameter   bit                             AXI4S_VIDEO          = 0,
            parameter   bit                             AXI4S_USE_STRB       = 0,
            parameter   bit                             AXI4S_USE_FIRST      = 0,
            parameter   bit                             AXI4S_USE_LAST       = 0,
            
            // AXI4
            parameter   int                             AXI4_AWID            = 0,
            parameter   bit     [0:0]                   AXI4_AWLOCK          = 1'b0,
            parameter   bit     [3:0]                   AXI4_AWCACHE         = 4'b0001,
            parameter   bit     [2:0]                   AXI4_AWPROT          = 3'b000,
            parameter   int                             AXI4_AWQOS           = 0,
            parameter   bit     [3:0]                   AXI4_AWREGION        = 4'b0000,
            parameter   int                             AXI4_ALIGN           = 12,  // 2^12 = 4k が境界
            
            // レジスタ構成など
            parameter   int                             INDEX_BITS           = 1,
            parameter   bit                             AWLEN_OFFSET         = 1'b1,
            parameter   int                             AWLEN0_BITS          = 32,
            parameter   int                             AWLEN1_BITS          = 32,
            parameter   int                             AWLEN2_BITS          = 32,
            parameter   int                             AWLEN3_BITS          = 32,
            parameter   int                             AWLEN4_BITS          = 32,
            parameter   int                             AWLEN5_BITS          = 32,
            parameter   int                             AWLEN6_BITS          = 32,
            parameter   int                             AWLEN7_BITS          = 32,
            parameter   int                             AWLEN8_BITS          = 32,
            parameter   int                             AWLEN9_BITS          = 32,
            parameter   int                             AWSTEP1_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP2_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP3_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP4_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP5_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP6_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP7_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP8_BITS         = AWADDR_BITS,
            parameter   int                             AWSTEP9_BITS         = AWADDR_BITS,

            
            // レジスタ初期値
            parameter   bit     [3:0]                   INIT_CTL_CONTROL     = 4'b0000,
            parameter   bit     [0:0]                   INIT_IRQ_ENABLE      = 1'b0,
            parameter   bit     [AWADDR_BITS-1:0]       INIT_PARAM_AWADDR    = 0,
            parameter   bit     [AWADDR_BITS-1:0]       INIT_PARAM_AWOFFSET  = 0,
            parameter   int                             INIT_PARAM_AWLEN_MAX = 0,
            parameter   bit     [AWLEN0_BITS-1:0]       INIT_PARAM_AWLEN0    = 0,
//          parameter   bit     [AWSTEP0_BITS-1:0]      INIT_PARAM_AWSTEP0   = 0,
            parameter   bit     [AWLEN1_BITS-1:0]       INIT_PARAM_AWLEN1    = 0,
            parameter   bit     [AWSTEP1_BITS-1:0]      INIT_PARAM_AWSTEP1   = 0,
            parameter   bit     [AWLEN2_BITS-1:0]       INIT_PARAM_AWLEN2    = 0,
            parameter   bit     [AWSTEP2_BITS-1:0]      INIT_PARAM_AWSTEP2   = 0,
            parameter   bit     [AWLEN3_BITS-1:0]       INIT_PARAM_AWLEN3    = 0,
            parameter   bit     [AWSTEP3_BITS-1:0]      INIT_PARAM_AWSTEP3   = 0,
            parameter   bit     [AWLEN4_BITS-1:0]       INIT_PARAM_AWLEN4    = 0,
            parameter   bit     [AWSTEP4_BITS-1:0]      INIT_PARAM_AWSTEP4   = 0,
            parameter   bit     [AWLEN5_BITS-1:0]       INIT_PARAM_AWLEN5    = 0,
            parameter   bit     [AWSTEP5_BITS-1:0]      INIT_PARAM_AWSTEP5   = 0,
            parameter   bit     [AWLEN6_BITS-1:0]       INIT_PARAM_AWLEN6    = 0,
            parameter   bit     [AWSTEP6_BITS-1:0]      INIT_PARAM_AWSTEP6   = 0,
            parameter   bit     [AWLEN7_BITS-1:0]       INIT_PARAM_AWLEN7    = 0,
            parameter   bit     [AWSTEP7_BITS-1:0]      INIT_PARAM_AWSTEP7   = 0,
            parameter   bit     [AWLEN8_BITS-1:0]       INIT_PARAM_AWLEN8    = 0,
            parameter   bit     [AWSTEP8_BITS-1:0]      INIT_PARAM_AWSTEP8   = 0,
            parameter   bit     [AWLEN9_BITS-1:0]       INIT_PARAM_AWLEN9    = 0,
            parameter   bit     [AWSTEP9_BITS-1:0]      INIT_PARAM_AWSTEP9   = 0,

            parameter   bit                             INIT_WSKIP_EN        = 1'b1,
            parameter   bit     [N-1:0]                 INIT_WDETECT_FIRST   = {N{1'b0}},
            parameter   bit     [N-1:0]                 INIT_WDETECT_LAST    = {N{1'b0}},
            parameter   bit                             INIT_WPADDING_EN     = 1'b1,
            parameter   bit     [AXI4S_DATA_BITS-1:0]   INIT_WPADDING_DATA   = {AXI4S_DATA_BITS{1'b0}},
            parameter   bit     [AXI4S_STRB_BITS-1:0]   INIT_WPADDING_STRB   = {AXI4S_STRB_BITS{1'b0}},
            
            // 構成情報
            parameter                                   CORE_ID              = 32'h527a_0110,
            parameter                                   CORE_VERSION         = 32'h0000_0000,
            parameter   bit                             BYPASS_GATE          = 0,
            parameter   bit                             BYPASS_ALIGN         = 0,
            parameter   bit                             WDETECTOR_CHANGE     = 1,
            parameter   bit                             WDETECTOR_ENABLE     = 1,
            parameter   bit                             ALLOW_UNALIGNED      = 1,
            parameter   int                             CAPACITY_BITS        = 32,
            parameter   int                             WFIFO_PTR_BITS       = 9,
            parameter                                   WFIFO_RAM_TYPE       = "block",
            parameter   bit                             WFIFO_LOW_DEALY      = 0,
            parameter   bit                             WFIFO_DOUT_REGS      = 1,
            parameter   bit                             WFIFO_S_REGS         = 0,
            parameter   bit                             WFIFO_M_REGS         = 1,
            parameter   int                             AWFIFO_PTR_BITS      = 4,
            parameter                                   AWFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             AWFIFO_LOW_DEALY     = 1,
            parameter   bit                             AWFIFO_DOUT_REGS     = 0,
            parameter   bit                             AWFIFO_S_REGS        = 1,
            parameter   bit                             AWFIFO_M_REGS        = 1,
            parameter   int                             BFIFO_PTR_BITS      = 4,
            parameter                                   BFIFO_RAM_TYPE       = "distributed",
            parameter   bit                             BFIFO_LOW_DEALY      = 0,
            parameter   bit                             BFIFO_DOUT_REGS      = 0,
            parameter   bit                             BFIFO_S_REGS         = 0,
            parameter   bit                             BFIFO_M_REGS         = 0,
            parameter   int                             SWFIFOPTR_BITS       = 4,
            parameter                                   SWFIFORAM_TYPE       = "distributed",
            parameter   bit                             SWFIFOLOW_DEALY      = 1,
            parameter   bit                             SWFIFODOUT_REGS      = 0,
            parameter   bit                             SWFIFOS_REGS         = 0,
            parameter   bit                             SWFIFOM_REGS         = 0,
            parameter   int                             MBFIFO_PTR_BITS      = 4,
            parameter                                   MBFIFO_RAM_TYPE      = "distributed",
            parameter   bit                             MBFIFO_LOW_DEALY     = 1,
            parameter   bit                             MBFIFO_DOUT_REGS     = 0,
            parameter   bit                             MBFIFO_S_REGS        = 0,
            parameter   bit                             MBFIFO_M_REGS        = 0,
            parameter   int                             WDATFIFO_PTR_BITS    = 4,
            parameter   bit                             WDATFIFO_DOUT_REGS   = 0,
            parameter                                   WDATFIFO_RAM_TYPE    = "distributed",
            parameter   bit                             WDATFIFO_LOW_DEALY   = 1,
            parameter   bit                             WDATFIFO_S_REGS      = 0,
            parameter   bit                             WDATFIFO_M_REGS      = 0,
            parameter   bit                             WDAT_S_REGS          = 0,
            parameter   bit                             WDAT_M_REGS          = 1,
            parameter   int                             BACKFIFO_PTR_BITS    = 4,
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
            input   var logic                       endian,
            
            jelly3_axi4l_if.s                       s_axi4l,
            jelly3_axi4s_if.s                       s_axi4s,
            jelly3_axi4_if.mw                       m_axi4,

            output  var logic                       out_irq,

            output  var logic                       buffer_request,
            output  var logic                       buffer_release,
            input   var logic    [AWADDR_BITS-1:0]  buffer_addr
        );
    
    
    // ---------------------------------
    //  typedef
    // ---------------------------------

    typedef logic   [REGADR_BITS-1:0]           regadr_t;
    typedef logic   [s_axi4l.DATA_BITS-1:0]     axi4l_data_t;
    

    
    // ---------------------------------
    //  Register
    // ---------------------------------

    
    // register address offset
    localparam  regadr_t    REGADR_CORE_ID            = regadr_t'('h00);
    localparam  regadr_t    REGADR_CORE_VERSION       = regadr_t'('h01);
    localparam  regadr_t    REGADR_CORE_CONFIG        = regadr_t'('h03);
    localparam  regadr_t    REGADR_CTL_CONTROL        = regadr_t'('h04);
    localparam  regadr_t    REGADR_CTL_STATUS         = regadr_t'('h05);
    localparam  regadr_t    REGADR_CTL_INDEX          = regadr_t'('h07);
    localparam  regadr_t    REGADR_IRQ_ENABLE         = regadr_t'('h08);
    localparam  regadr_t    REGADR_IRQ_STATUS         = regadr_t'('h09);
    localparam  regadr_t    REGADR_IRQ_CLR            = regadr_t'('h0a);
    localparam  regadr_t    REGADR_IRQ_SET            = regadr_t'('h0b);
    localparam  regadr_t    REGADR_PARAM_AWADDR       = regadr_t'('h10);
    localparam  regadr_t    REGADR_PARAM_AWOFFSET     = regadr_t'('h18);
    localparam  regadr_t    REGADR_PARAM_AWLEN_MAX    = regadr_t'('h1c);
    localparam  regadr_t    REGADR_PARAM_AWLEN0       = regadr_t'('h20);
//  localparam  regadr_t    REGADR_PARAM_AWSTEP0      = regadr_t'('h21);
    localparam  regadr_t    REGADR_PARAM_AWLEN1       = regadr_t'('h24);
    localparam  regadr_t    REGADR_PARAM_AWSTEP1      = regadr_t'('h25);
    localparam  regadr_t    REGADR_PARAM_AWLEN2       = regadr_t'('h28);
    localparam  regadr_t    REGADR_PARAM_AWSTEP2      = regadr_t'('h29);
    localparam  regadr_t    REGADR_PARAM_AWLEN3       = regadr_t'('h2c);
    localparam  regadr_t    REGADR_PARAM_AWSTEP3      = regadr_t'('h2d);
    localparam  regadr_t    REGADR_PARAM_AWLEN4       = regadr_t'('h30);
    localparam  regadr_t    REGADR_PARAM_AWSTEP4      = regadr_t'('h31);
    localparam  regadr_t    REGADR_PARAM_AWLEN5       = regadr_t'('h34);
    localparam  regadr_t    REGADR_PARAM_AWSTEP5      = regadr_t'('h35);
    localparam  regadr_t    REGADR_PARAM_AWLEN6       = regadr_t'('h38);
    localparam  regadr_t    REGADR_PARAM_AWSTEP6      = regadr_t'('h39);
    localparam  regadr_t    REGADR_PARAM_AWLEN7       = regadr_t'('h3c);
    localparam  regadr_t    REGADR_PARAM_AWSTEP7      = regadr_t'('h3d);
    localparam  regadr_t    REGADR_PARAM_AWLEN8       = regadr_t'('h40);
    localparam  regadr_t    REGADR_PARAM_AWSTEP8      = regadr_t'('h41);
    localparam  regadr_t    REGADR_PARAM_AWLEN9       = regadr_t'('h44);
    localparam  regadr_t    REGADR_PARAM_AWSTEP9      = regadr_t'('h45);
    localparam  regadr_t    REGADR_WSKIP_EN           = regadr_t'('h70);
    localparam  regadr_t    REGADR_WDETECT_FIRST      = regadr_t'('h72);
    localparam  regadr_t    REGADR_WDETECT_LAST       = regadr_t'('h73);
    localparam  regadr_t    REGADR_WPADDING_EN        = regadr_t'('h74);
    localparam  regadr_t    REGADR_WPADDING_DATA      = regadr_t'('h75);
    localparam  regadr_t    REGADR_WPADDING_STRB      = regadr_t'('h76);
    localparam  regadr_t    REGADR_SHADOW_AWADDR      = regadr_t'('h90);
    localparam  regadr_t    REGADR_SHADOW_AWOFFSET    = regadr_t'('h98);
    localparam  regadr_t    REGADR_SHADOW_AWLEN_MAX   = regadr_t'('h9c);
    localparam  regadr_t    REGADR_SHADOW_AWLEN0      = regadr_t'('ha0);
//  localparam  regadr_t    REGADR_SHADOW_AWSTEP0     = regadr_t'('ha1);
    localparam  regadr_t    REGADR_SHADOW_AWLEN1      = regadr_t'('ha4);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP1     = regadr_t'('ha5);
    localparam  regadr_t    REGADR_SHADOW_AWLEN2      = regadr_t'('ha8);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP2     = regadr_t'('ha9);
    localparam  regadr_t    REGADR_SHADOW_AWLEN3      = regadr_t'('hac);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP3     = regadr_t'('had);
    localparam  regadr_t    REGADR_SHADOW_AWLEN4      = regadr_t'('hb0);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP4     = regadr_t'('hb1);
    localparam  regadr_t    REGADR_SHADOW_AWLEN5      = regadr_t'('hb4);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP5     = regadr_t'('hb5);
    localparam  regadr_t    REGADR_SHADOW_AWLEN6      = regadr_t'('hb8);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP6     = regadr_t'('hb9);
    localparam  regadr_t    REGADR_SHADOW_AWLEN7      = regadr_t'('hbc);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP7     = regadr_t'('hbd);
    localparam  regadr_t    REGADR_SHADOW_AWLEN8      = regadr_t'('hc0);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP8     = regadr_t'('hc1);
    localparam  regadr_t    REGADR_SHADOW_AWLEN9      = regadr_t'('hc4);
    localparam  regadr_t    REGADR_SHADOW_AWSTEP9     = regadr_t'('hc5);
    
    
    // registers
    logic   [3:0]                   reg_ctl_control;    // bit[0]:enable, bit[1]:update, bit[2]:oneshot, bit[3]:auto_addr
    logic   [0:0]                   reg_ctl_status;
    logic   [INDEX_BITS-1:0]        reg_ctl_index;
    logic   [0:0]                   reg_irq_enable;
    logic   [0:0]                   reg_irq_status;
    logic   [AWADDR_BITS-1:0]       reg_param_awaddr;
    logic   [AWADDR_BITS-1:0]       reg_param_awoffset;
    logic   [m_axi4.LEN_BITS-1:0]   reg_param_awlen_max;
    logic   [AWLEN0_BITS-1:0]       reg_param_awlen0;
//  logic   [AWSTEP0_BITS-1:0]      reg_param_awstep0;
    logic   [AWLEN1_BITS-1:0]       reg_param_awlen1;
    logic   [AWSTEP1_BITS-1:0]      reg_param_awstep1;
    logic   [AWLEN2_BITS-1:0]       reg_param_awlen2;
    logic   [AWSTEP2_BITS-1:0]      reg_param_awstep2;
    logic   [AWLEN3_BITS-1:0]       reg_param_awlen3;
    logic   [AWSTEP3_BITS-1:0]      reg_param_awstep3;
    logic   [AWLEN4_BITS-1:0]       reg_param_awlen4;
    logic   [AWSTEP4_BITS-1:0]      reg_param_awstep4;
    logic   [AWLEN5_BITS-1:0]       reg_param_awlen5;
    logic   [AWSTEP5_BITS-1:0]      reg_param_awstep5;
    logic   [AWLEN6_BITS-1:0]       reg_param_awlen6;
    logic   [AWSTEP6_BITS-1:0]      reg_param_awstep6;
    logic   [AWLEN7_BITS-1:0]       reg_param_awlen7;
    logic   [AWSTEP7_BITS-1:0]      reg_param_awstep7;
    logic   [AWLEN8_BITS-1:0]       reg_param_awlen8;
    logic   [AWSTEP8_BITS-1:0]      reg_param_awstep8;
    logic   [AWLEN9_BITS-1:0]       reg_param_awlen9;
    logic   [AWSTEP9_BITS-1:0]      reg_param_awstep9;
    logic                           reg_wskip_en;
    logic   [N-1:0]                 reg_wdetect_first;
    logic   [N-1:0]                 reg_wdetect_last;
    logic                           reg_wpadding_en;
    logic   [AXI4S_DATA_BITS-1:0]   reg_wpadding_data;
    logic   [AXI4S_STRB_BITS-1:0]   reg_wpadding_strb;
    logic   [AWADDR_BITS-1:0]       reg_shadow_awaddr;
    logic   [AWADDR_BITS-1:0]       reg_shadow_awoffset;
    logic   [m_axi4.LEN_BITS-1:0]   reg_shadow_awlen_max;
    logic   [AWLEN0_BITS-1:0]       reg_shadow_awlen0;
//  logic   [AWSTEP0_BITS-1:0]      reg_shadow_awstep0;
    logic   [AWLEN1_BITS-1:0]       reg_shadow_awlen1;
    logic   [AWSTEP1_BITS-1:0]      reg_shadow_awstep1;
    logic   [AWLEN2_BITS-1:0]       reg_shadow_awlen2;
    logic   [AWSTEP2_BITS-1:0]      reg_shadow_awstep2;
    logic   [AWLEN3_BITS-1:0]       reg_shadow_awlen3;
    logic   [AWSTEP3_BITS-1:0]      reg_shadow_awstep3;
    logic   [AWLEN4_BITS-1:0]       reg_shadow_awlen4;
    logic   [AWSTEP4_BITS-1:0]      reg_shadow_awstep4;
    logic   [AWLEN5_BITS-1:0]       reg_shadow_awlen5;
    logic   [AWSTEP5_BITS-1:0]      reg_shadow_awstep5;
    logic   [AWLEN6_BITS-1:0]       reg_shadow_awlen6;
    logic   [AWSTEP6_BITS-1:0]      reg_shadow_awstep6;
    logic   [AWLEN7_BITS-1:0]       reg_shadow_awlen7;
    logic   [AWSTEP7_BITS-1:0]      reg_shadow_awstep7;
    logic   [AWLEN8_BITS-1:0]       reg_shadow_awlen8;
    logic   [AWSTEP8_BITS-1:0]      reg_shadow_awstep8;
    logic   [AWLEN9_BITS-1:0]       reg_shadow_awlen9;
    logic   [AWSTEP9_BITS-1:0]      reg_shadow_awstep9;
    
    logic                           sig_start;
    logic                           sig_end;
    assign sig_start = !reg_ctl_status && reg_ctl_control[0];
    
    logic   [AWADDR_BITS-1:0]       reg_awaddr;
    logic                           reg_awvalid;
    logic                           s_awready;
    
    logic                           reg_wskip;
    
    assign out_irq        = |(reg_irq_status & reg_irq_enable);
    
    assign buffer_request = (sig_start && reg_ctl_control[3]);
    assign buffer_release = (sig_end || (!sig_start && !reg_ctl_status));
    
    
    function [s_axi4l.DATA_BITS-1:0] write_mask(
                                        input [s_axi4l.DATA_BITS-1:0] org,
                                        input [s_axi4l.DATA_BITS-1:0] data,
                                        input [s_axi4l.STRB_BITS-1:0] strb
                                    );
        for ( int i = 0; i < s_axi4l.DATA_BITS; i++ ) begin
            write_mask[i] = strb[i/8] ? data[i] : org[i];
        end
    endfunction
    

    regadr_t  regadr_write;
    regadr_t  regadr_read;
    assign regadr_write = regadr_t'(s_axi4l.awaddr / s_axi4l.STRB_BITS);
    assign regadr_read  = regadr_t'(s_axi4l.araddr / s_axi4l.STRB_BITS);

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_ctl_control      <= INIT_CTL_CONTROL;
            reg_ctl_status       <= 0;
            reg_ctl_index        <= 0;
            reg_irq_enable       <= INIT_IRQ_ENABLE;
            reg_irq_status       <= 0;
            reg_param_awaddr     <= INIT_PARAM_AWADDR;
            reg_param_awoffset   <= INIT_PARAM_AWOFFSET;
            reg_param_awlen_max  <= m_axi4.LEN_BITS'(INIT_PARAM_AWLEN_MAX);
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
            reg_shadow_awlen_max <= m_axi4.LEN_BITS'(INIT_PARAM_AWLEN_MAX);
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
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                case ( regadr_write )
                REGADR_CTL_CONTROL:        reg_ctl_control      <=                      4'(write_mask(axi4l_data_t'(reg_ctl_control),     s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_IRQ_ENABLE:         reg_irq_enable       <=                      1'(write_mask(axi4l_data_t'(reg_irq_enable ),     s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_IRQ_CLR:            reg_irq_status       <= reg_irq_status &    1'(~write_mask(axi4l_data_t'(0),                   s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_IRQ_SET:            reg_irq_status       <= reg_irq_status |     1'(write_mask(axi4l_data_t'(0),                   s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_AWADDR:       reg_param_awaddr     <=            AWADDR_BITS'(write_mask(axi4l_data_t'(reg_param_awaddr),    s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_AWOFFSET:     reg_param_awoffset   <=            AWADDR_BITS'(write_mask(axi4l_data_t'(reg_param_awoffset),  s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_AWLEN_MAX:    reg_param_awlen_max  <=        m_axi4.LEN_BITS'(write_mask(axi4l_data_t'(reg_param_awlen_max), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_AWLEN0:       reg_param_awlen0     <=            AWLEN0_BITS'(write_mask(axi4l_data_t'(reg_param_awlen0),    s_axi4l.wdata, s_axi4l.wstrb));
//              REGADR_PARAM_AWSTEP0:      reg_param_awstep0    <=                          write_mask(axi4l_data_t'(reg_param_awstep0),   s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_PARAM_AWLEN1:       reg_param_awlen1     <= (N > 1) ?  AWLEN1_BITS'(write_mask(axi4l_data_t'(reg_param_awlen1),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP1:      reg_param_awstep1    <= (N > 1) ? AWSTEP1_BITS'(write_mask(axi4l_data_t'(reg_param_awstep1),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN2:       reg_param_awlen2     <= (N > 2) ?  AWLEN2_BITS'(write_mask(axi4l_data_t'(reg_param_awlen2),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP2:      reg_param_awstep2    <= (N > 2) ? AWSTEP2_BITS'(write_mask(axi4l_data_t'(reg_param_awstep2),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN3:       reg_param_awlen3     <= (N > 3) ?  AWLEN3_BITS'(write_mask(axi4l_data_t'(reg_param_awlen3),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP3:      reg_param_awstep3    <= (N > 3) ? AWSTEP3_BITS'(write_mask(axi4l_data_t'(reg_param_awstep3),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN4:       reg_param_awlen4     <= (N > 4) ?  AWLEN4_BITS'(write_mask(axi4l_data_t'(reg_param_awlen4),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP4:      reg_param_awstep4    <= (N > 4) ? AWSTEP4_BITS'(write_mask(axi4l_data_t'(reg_param_awstep4),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN5:       reg_param_awlen5     <= (N > 5) ?  AWLEN5_BITS'(write_mask(axi4l_data_t'(reg_param_awlen5),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP5:      reg_param_awstep5    <= (N > 5) ? AWSTEP5_BITS'(write_mask(axi4l_data_t'(reg_param_awstep5),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN6:       reg_param_awlen6     <= (N > 6) ?  AWLEN6_BITS'(write_mask(axi4l_data_t'(reg_param_awlen6),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP6:      reg_param_awstep6    <= (N > 6) ? AWSTEP6_BITS'(write_mask(axi4l_data_t'(reg_param_awstep6),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN7:       reg_param_awlen7     <= (N > 7) ?  AWLEN7_BITS'(write_mask(axi4l_data_t'(reg_param_awlen7),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP7:      reg_param_awstep7    <= (N > 7) ? AWSTEP7_BITS'(write_mask(axi4l_data_t'(reg_param_awstep7),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN8:       reg_param_awlen8     <= (N > 8) ?  AWLEN8_BITS'(write_mask(axi4l_data_t'(reg_param_awlen8),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP8:      reg_param_awstep8    <= (N > 8) ? AWSTEP8_BITS'(write_mask(axi4l_data_t'(reg_param_awstep8),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWLEN9:       reg_param_awlen9     <= (N > 9) ?  AWLEN9_BITS'(write_mask(axi4l_data_t'(reg_param_awlen9),    s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                REGADR_PARAM_AWSTEP9:      reg_param_awstep9    <= (N > 9) ? AWSTEP9_BITS'(write_mask(axi4l_data_t'(reg_param_awstep9),   s_axi4l.wdata, s_axi4l.wstrb)) : 0;
                default: ;
                endcase
                
                if ( WDETECTOR_CHANGE ) begin
                case ( regadr_write )
                REGADR_WSKIP_EN:           reg_wskip_en         <=               1'(write_mask(axi4l_data_t'(reg_wskip_en),      s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_WDETECT_FIRST:      reg_wdetect_first    <=               N'(write_mask(axi4l_data_t'(reg_wdetect_first), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_WDETECT_LAST:       reg_wdetect_last     <=               N'(write_mask(axi4l_data_t'(reg_wdetect_last),  s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_WPADDING_EN:        reg_wpadding_en      <=               1'(write_mask(axi4l_data_t'(reg_wpadding_en),   s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_WPADDING_DATA:      reg_wpadding_data    <= AXI4S_DATA_BITS'(write_mask(axi4l_data_t'(reg_wpadding_data), s_axi4l.wdata, s_axi4l.wstrb));
                REGADR_WPADDING_STRB:      reg_wpadding_strb    <= AXI4S_STRB_BITS'(write_mask(axi4l_data_t'(reg_wpadding_strb), s_axi4l.wdata, s_axi4l.wstrb));
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

    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.bvalid <= 0;
        end
        else begin
            if ( s_axi4l.bready ) begin
                s_axi4l.bvalid <= 0;
            end
            if ( s_axi4l.awvalid && s_axi4l.awready ) begin
                s_axi4l.bvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.awready = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.wvalid;
    assign s_axi4l.wready  = (~s_axi4l.bvalid || s_axi4l.bready) && s_axi4l.awvalid;
    assign s_axi4l.bresp   = '0;


    // read
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( s_axi4l.arvalid && s_axi4l.arready ) begin
            case ( regadr_read )
            REGADR_CORE_ID:             s_axi4l.rdata <= axi4l_data_t'(CORE_ID              );
            REGADR_CORE_VERSION:        s_axi4l.rdata <= axi4l_data_t'(CORE_VERSION         );
            REGADR_CORE_CONFIG:         s_axi4l.rdata <= axi4l_data_t'(N                    );
            REGADR_CTL_CONTROL:         s_axi4l.rdata <= axi4l_data_t'(reg_ctl_control      );
            REGADR_CTL_STATUS:          s_axi4l.rdata <= axi4l_data_t'(reg_ctl_status       );
            REGADR_CTL_INDEX:           s_axi4l.rdata <= axi4l_data_t'(reg_ctl_index        );
            REGADR_IRQ_ENABLE:          s_axi4l.rdata <= axi4l_data_t'(reg_irq_enable       );
            REGADR_IRQ_STATUS:          s_axi4l.rdata <= axi4l_data_t'(reg_irq_status       );
            REGADR_PARAM_AWADDR:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awaddr     );
            REGADR_PARAM_AWOFFSET:      s_axi4l.rdata <= axi4l_data_t'(reg_param_awoffset   );
            REGADR_PARAM_AWLEN_MAX:     s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen_max  );
            REGADR_PARAM_AWLEN0:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen0     );
    //      REGADR_PARAM_AWSTEP0:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep0    );
            REGADR_PARAM_AWLEN1:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen1     );
            REGADR_PARAM_AWSTEP1:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep1    );
            REGADR_PARAM_AWLEN2:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen2     );
            REGADR_PARAM_AWSTEP2:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep2    );
            REGADR_PARAM_AWLEN3:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen3     );
            REGADR_PARAM_AWSTEP3:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep3    );
            REGADR_PARAM_AWLEN4:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen4     );
            REGADR_PARAM_AWSTEP4:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep4    );
            REGADR_PARAM_AWLEN5:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen5     );
            REGADR_PARAM_AWSTEP5:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep5    );
            REGADR_PARAM_AWLEN6:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen6     );
            REGADR_PARAM_AWSTEP6:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep6    );
            REGADR_PARAM_AWLEN7:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen7     );
            REGADR_PARAM_AWSTEP7:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep7    );
            REGADR_PARAM_AWLEN8:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen8     );
            REGADR_PARAM_AWSTEP8:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep8    );
            REGADR_PARAM_AWLEN9:        s_axi4l.rdata <= axi4l_data_t'(reg_param_awlen9     );
            REGADR_PARAM_AWSTEP9:       s_axi4l.rdata <= axi4l_data_t'(reg_param_awstep9    );
            REGADR_WSKIP_EN:            s_axi4l.rdata <= axi4l_data_t'(reg_wskip_en         );
            REGADR_WDETECT_FIRST:       s_axi4l.rdata <= axi4l_data_t'(reg_wdetect_first    );
            REGADR_WDETECT_LAST:        s_axi4l.rdata <= axi4l_data_t'(reg_wdetect_last     );
            REGADR_WPADDING_EN:         s_axi4l.rdata <= axi4l_data_t'(reg_wpadding_en      );
            REGADR_WPADDING_DATA:       s_axi4l.rdata <= axi4l_data_t'(reg_wpadding_data    );
            REGADR_WPADDING_STRB:       s_axi4l.rdata <= axi4l_data_t'(reg_wpadding_strb    );
            REGADR_SHADOW_AWADDR:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awaddr    );
            REGADR_SHADOW_AWOFFSET:     s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awoffset  );
            REGADR_SHADOW_AWLEN_MAX:    s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen_max );
            REGADR_SHADOW_AWLEN0:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen0    );
    //      REGADR_SHADOW_AWSTEP0:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep0   );
            REGADR_SHADOW_AWLEN1:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen1    );
            REGADR_SHADOW_AWSTEP1:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep1   );
            REGADR_SHADOW_AWLEN2:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen2    );
            REGADR_SHADOW_AWSTEP2:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep2   );
            REGADR_SHADOW_AWLEN3:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen3    );
            REGADR_SHADOW_AWSTEP3:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep3   );
            REGADR_SHADOW_AWLEN4:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen4    );
            REGADR_SHADOW_AWSTEP4:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep4   );
            REGADR_SHADOW_AWLEN5:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen5    );
            REGADR_SHADOW_AWSTEP5:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep5   );
            REGADR_SHADOW_AWLEN6:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen6    );
            REGADR_SHADOW_AWSTEP6:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep6   );
            REGADR_SHADOW_AWLEN7:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen7    );
            REGADR_SHADOW_AWSTEP7:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep7   );
            REGADR_SHADOW_AWLEN8:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen8    );
            REGADR_SHADOW_AWSTEP8:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep8   );
            REGADR_SHADOW_AWLEN9:       s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awlen9    );
            REGADR_SHADOW_AWSTEP9:      s_axi4l.rdata <= axi4l_data_t'(reg_shadow_awstep9   );
            default: ;
            endcase
        end
    end

    logic           axi4l_rvalid;
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            s_axi4l.rvalid <= 1'b0;
        end
        else begin
            if ( s_axi4l.rready ) begin
                s_axi4l.rvalid <= 1'b0;
            end
            if ( s_axi4l.arvalid && s_axi4l.arready ) begin
                s_axi4l.rvalid <= 1'b1;
            end
        end
    end

    assign s_axi4l.arready = ~s_axi4l.rvalid || s_axi4l.rready;
    assign s_axi4l.rresp   = '0;


    
    
    // read core
    localparam LEN_MAX  = AWADDR_BITS;
    localparam STEP_MAX = AWADDR_BITS;
    
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
    always_ff @(posedge s_axi4l.aclk ) begin
        if ( ~s_axi4l.aresetn ) begin
            reg_wskip_ff0 <= 1'b0;
            reg_wskip_ff1 <= 1'b0;
        end
        else begin
            reg_wskip_ff0 <= reg_wskip;
            reg_wskip_ff1 <= reg_wskip_ff0;
        end
    end
    
    
    logic   [N-1:0]                 s_bfirst;
    logic   [N-1:0]                 s_blast;
    logic                           s_bvalid;
    logic                           s_bready;
    
//    localparam AXI4_DATA_SIZE = $clog2(m_axi4.DATA_BITS/8);
    localparam AXI4_DATA_SIZE = $clog2(m_axi4.STRB_BITS);

    logic   [N-1:0]     s_wfirst;
    logic   [N-1:0]     s_wlast ;
    if ( N >= 2 && AXI4S_VIDEO ) begin
        assign s_wfirst = N'({s_axi4s.tuser[0], 1'b0});
        assign s_wlast  = N'({1'b0, s_axi4s.tlast});
    end
    else begin
        assign s_wfirst = '0;
        assign s_wlast  = '0;
    end


    jelly2_axi4_write_nd
            #(
                .N                      (N                          ),

                .AWASYNC                (AXI4L_ASYNC                ),
                .WASYNC                 (AXI4S_ASYNC                ),
                .BASYNC                 (AXI4L_ASYNC                ),

                .BYTE_WIDTH             (AXI4S_BYTE_BITS            ),
                .BYPASS_GATE            (BYPASS_GATE                ),
                .BYPASS_ALIGN           (BYPASS_ALIGN               ),
                .AXI4_ALIGN             (AXI4_ALIGN                 ),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED            ),
                .WDETECTOR_ENABLE       (WDETECTOR_ENABLE           ),

                .HAS_WSTRB              (AXI4S_USE_STRB             ),
                .HAS_WFIRST             (1'b0                       ),
                .HAS_WLAST              (AXI4S_USE_LAST             ),

                .AXI4_ID_WIDTH          (m_axi4.ID_BITS             ),
                .AXI4_ADDR_WIDTH        (m_axi4.ADDR_BITS           ),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE             ),
                .AXI4_DATA_WIDTH        (m_axi4.DATA_BITS           ),
                .AXI4_STRB_WIDTH        (m_axi4.STRB_BITS           ),
                .AXI4_LEN_WIDTH         (m_axi4.LEN_BITS            ),
                .AXI4_QOS_WIDTH         (m_axi4.QOS_BITS            ),
                .AXI4_AWID              (AXI4_AWID                  ),
                .AXI4_AWSIZE            (3'($clog2(m_axi4.STRB_BITS))),
                .AXI4_AWBURST           (2'b01                      ),
                .AXI4_AWLOCK            (AXI4_AWLOCK                ),
                .AXI4_AWCACHE           (AXI4_AWCACHE               ),
                .AXI4_AWPROT            (AXI4_AWPROT                ),
                .AXI4_AWQOS             (AXI4_AWQOS                 ),
                .AXI4_AWREGION          (AXI4_AWREGION              ),
                .S_WDATA_WIDTH          (s_axi4s.DATA_BITS          ),
                .S_WSTRB_WIDTH          (s_axi4s.STRB_BITS          ),
                .S_AWSTEP_WIDTH         (STEP_MAX                   ),
                .S_AWLEN_WIDTH          (LEN_MAX                    ),
                .S_AWLEN_OFFSET         (AWLEN_OFFSET               ),
                
                .CAPACITY_WIDTH         (CAPACITY_BITS              ),
                .CONVERT_S_REGS         (CONVERT_S_REGS             ),
                
                .WFIFO_PTR_WIDTH        (WFIFO_PTR_BITS             ),
                .WFIFO_RAM_TYPE         (WFIFO_RAM_TYPE             ),
                .WFIFO_LOW_DEALY        (WFIFO_LOW_DEALY            ),
                .WFIFO_DOUT_REGS        (WFIFO_DOUT_REGS            ),
                .WFIFO_S_REGS           (WFIFO_S_REGS               ),
                .WFIFO_M_REGS           (WFIFO_M_REGS               ),
                .AWFIFO_PTR_WIDTH       (AWFIFO_PTR_BITS            ),
                .AWFIFO_RAM_TYPE        (AWFIFO_RAM_TYPE            ),
                .AWFIFO_LOW_DEALY       (AWFIFO_LOW_DEALY           ),
                .AWFIFO_DOUT_REGS       (AWFIFO_DOUT_REGS           ),
                .AWFIFO_S_REGS          (AWFIFO_S_REGS              ),
                .AWFIFO_M_REGS          (AWFIFO_M_REGS              ),
                .BFIFO_PTR_WIDTH        (BFIFO_PTR_BITS             ),
                .BFIFO_RAM_TYPE         (BFIFO_RAM_TYPE             ),
                .BFIFO_LOW_DEALY        (BFIFO_LOW_DEALY            ),
                .BFIFO_DOUT_REGS        (BFIFO_DOUT_REGS            ),
                .BFIFO_S_REGS           (BFIFO_S_REGS               ),
                .BFIFO_M_REGS           (BFIFO_M_REGS               ),
                .SWFIFOPTR_WIDTH        (SWFIFOPTR_BITS             ),
                .SWFIFORAM_TYPE         (SWFIFORAM_TYPE             ),
                .SWFIFOLOW_DEALY        (SWFIFOLOW_DEALY            ),
                .SWFIFODOUT_REGS        (SWFIFODOUT_REGS            ),
                .SWFIFOS_REGS           (SWFIFOS_REGS               ),
                .SWFIFOM_REGS           (SWFIFOM_REGS               ),
                .MBFIFO_PTR_WIDTH       (MBFIFO_PTR_BITS            ),
                .MBFIFO_RAM_TYPE        (MBFIFO_RAM_TYPE            ),
                .MBFIFO_LOW_DEALY       (MBFIFO_LOW_DEALY           ),
                .MBFIFO_DOUT_REGS       (MBFIFO_DOUT_REGS           ),
                .MBFIFO_S_REGS          (MBFIFO_S_REGS              ),
                .MBFIFO_M_REGS          (MBFIFO_M_REGS              ),
                .WDATFIFO_PTR_WIDTH     (WDATFIFO_PTR_BITS          ),
                .WDATFIFO_DOUT_REGS     (WDATFIFO_DOUT_REGS         ),
                .WDATFIFO_RAM_TYPE      (WDATFIFO_RAM_TYPE          ),
                .WDATFIFO_LOW_DEALY     (WDATFIFO_LOW_DEALY         ),
                .WDATFIFO_S_REGS        (WDATFIFO_S_REGS            ),
                .WDATFIFO_M_REGS        (WDATFIFO_M_REGS            ),
                .WDAT_S_REGS            (WDAT_S_REGS                ),
                .WDAT_M_REGS            (WDAT_M_REGS                ),
                .BACKFIFO_PTR_WIDTH     (BACKFIFO_PTR_BITS          ),
                .BACKFIFO_DOUT_REGS     (BACKFIFO_DOUT_REGS         ),
                .BACKFIFO_RAM_TYPE      (BACKFIFO_RAM_TYPE          ),
                .BACKFIFO_LOW_DEALY     (BACKFIFO_LOW_DEALY         ),
                .BACKFIFO_S_REGS        (BACKFIFO_S_REGS            ),
                .BACKFIFO_M_REGS        (BACKFIFO_M_REGS            ),
                .BACK_S_REGS            (BACK_S_REGS                ),
                .BACK_M_REGS            (BACK_M_REGS                )
            )
        i_axi4_write_nd
            (
                .endian                 (endian                     ),
                
                .s_awresetn             (s_axi4l.aresetn            ),
                .s_awclk                (s_axi4l.aclk               ),
                .s_awaddr               (m_axi4.ADDR_BITS'(reg_awaddr)),
                .s_awlen_max            (reg_shadow_awlen_max       ),
                .s_awstep               (s_awstep[N-1:0]            ),
                .s_awlen                (s_awlen [N-1:0]            ),
                .s_awvalid              (reg_awvalid                ),
                .s_awready              (s_awready                  ),
                
                .s_wresetn              (s_axi4s.aresetn            ),
                .s_wclk                 (s_axi4s.aclk               ),
                .s_wdata                (s_axi4s.tdata              ),
                .s_wstrb                (s_axi4s.tstrb              ),
                .s_wfirst               (s_wfirst                   ),
                .s_wlast                (s_wlast                    ),
                .s_wvalid               (s_axi4s.tvalid             ),
                .s_wready               (s_axi4s.tready             ),
                
                .wskip                  (reg_wskip_ff1              ),
                .wdetect_first          (reg_wdetect_first          ),
                .wdetect_last           (reg_wdetect_last           ),
                .wpadding_en            (reg_wpadding_en            ),
                .wpadding_data          (reg_wpadding_data          ),
                .wpadding_strb          (reg_wpadding_strb          ),
                
                .s_bresetn              (s_axi4s.aresetn            ),
                .s_bclk                 (s_axi4s.aclk               ),
                .s_bfirst               (s_bfirst                   ),
                .s_blast                (s_blast                    ),
                .s_bvalid               (s_bvalid                   ),
                .s_bready               (s_bready                   ),
                
                .m_aresetn              (m_axi4.aresetn             ),
                .m_aclk                 (m_axi4.aclk                ),
                .m_axi4_awid            (m_axi4.awid                ),
                .m_axi4_awaddr          (m_axi4.awaddr              ),
                .m_axi4_awlen           (m_axi4.awlen               ),
                .m_axi4_awsize          (m_axi4.awsize              ),
                .m_axi4_awburst         (m_axi4.awburst             ),
                .m_axi4_awlock          (m_axi4.awlock              ),
                .m_axi4_awcache         (m_axi4.awcache             ),
                .m_axi4_awprot          (m_axi4.awprot              ),
                .m_axi4_awqos           (m_axi4.awqos               ),
                .m_axi4_awregion        (m_axi4.awregion            ),
                .m_axi4_awvalid         (m_axi4.awvalid             ),
                .m_axi4_awready         (m_axi4.awready             ),
                .m_axi4_wdata           (m_axi4.wdata               ),
                .m_axi4_wstrb           (m_axi4.wstrb               ),
                .m_axi4_wlast           (m_axi4.wlast               ),
                .m_axi4_wvalid          (m_axi4.wvalid              ),
                .m_axi4_wready          (m_axi4.wready              ),
                .m_axi4_bid             (m_axi4.bid                 ),
                .m_axi4_bresp           (m_axi4.bresp               ),
                .m_axi4_bvalid          (m_axi4.bvalid              ),
                .m_axi4_bready          (m_axi4.bready              )
            );
    
    assign s_bready = 1'b1;
    
    assign sig_end   = s_bvalid & s_bready & s_blast[N-1];
    
    
endmodule


`default_nettype wire


// end of file
