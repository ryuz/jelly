// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 Real-Time OS
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_rtos_axi4l
        #(
            parameter  AXI4L_ADDR_WIDTH = 29,
            parameter  AXI4L_DATA_WIDTH = 32,
            parameter  AXI4L_STRB_WIDTH = AXI4L_DATA_WIDTH / 8
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,

            input   wire    [AXI4L_ADDR_WIDTH-1:0]  s_axi4l_awaddr,
            input   wire    [2:0]                   s_axi4l_awprot,
            input   wire                            s_axi4l_awvalid,
            output  wire                            s_axi4l_awready,
            input   wire    [AXI4L_DATA_WIDTH-1:0]  s_axi4l_wdata,
            input   wire    [AXI4L_STRB_WIDTH-1:0]  s_axi4l_wstrb,
            input   wire                            s_axi4l_wvalid,
            output  wire                            s_axi4l_wready,
            output  wire    [1:0]                   s_axi4l_bresp,
            output  wire                            s_axi4l_bvalid,
            input   wire                            s_axi4l_bready,
            input   wire    [AXI4L_ADDR_WIDTH-1:0]  s_axi4l_araddr,
            input   wire    [2:0]                   s_axi4l_arprot,
            input   wire                            s_axi4l_arvalid,
            output  wire                            s_axi4l_arready,
            output  wire    [AXI4L_DATA_WIDTH-1:0]  s_axi4l_rdata,
            output  wire    [1:0]                   s_axi4l_rresp,
            output  wire                            s_axi4l_rvalid,
            input   wire                            s_axi4l_rready,
            
            output  wire    [0:0]                   irq
        );
    
    
    // -----------------------------
    //  WISHBONE
    // -----------------------------
    
    localparam  AXI4L_DATA_SIZE = $clog2(AXI4L_DATA_WIDTH);

    localparam  WB_DAT_SIZE  = AXI4L_DATA_SIZE;
    localparam  WB_ADR_WIDTH = AXI4L_ADDR_WIDTH - WB_DAT_SIZE;
    localparam  WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
    logic                           reset;
    logic                           clk;
    
    logic   [WB_ADR_WIDTH-1:0]      wb_adr_i;
    logic   [WB_DAT_WIDTH-1:0]      wb_dat_i;
    logic   [WB_DAT_WIDTH-1:0]      wb_dat_o;
    logic                           wb_we_i;
    logic   [WB_SEL_WIDTH-1:0]      wb_sel_i;
    logic                           wb_stb_i;
    logic                           wb_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH   (AXI4L_ADDR_WIDTH),
                .AXI4L_DATA_SIZE    (AXI4L_DATA_SIZE)     // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn    (aresetn),
                .s_axi4l_aclk       (aclk),
                .s_axi4l_awaddr     (s_axi4l_awaddr),
                .s_axi4l_awprot     (s_axi4l_awprot),
                .s_axi4l_awvalid    (s_axi4l_awvalid),
                .s_axi4l_awready    (s_axi4l_awready),
                .s_axi4l_wstrb      (s_axi4l_wstrb),
                .s_axi4l_wdata      (s_axi4l_wdata),
                .s_axi4l_wvalid     (s_axi4l_wvalid),
                .s_axi4l_wready     (s_axi4l_wready),
                .s_axi4l_bresp      (s_axi4l_bresp),
                .s_axi4l_bvalid     (s_axi4l_bvalid),
                .s_axi4l_bready     (s_axi4l_bready),
                .s_axi4l_araddr     (s_axi4l_araddr),
                .s_axi4l_arprot     (s_axi4l_arprot),
                .s_axi4l_arvalid    (s_axi4l_arvalid),
                .s_axi4l_arready    (s_axi4l_arready),
                .s_axi4l_rdata      (s_axi4l_rdata),
                .s_axi4l_rresp      (s_axi4l_rresp),
                .s_axi4l_rvalid     (s_axi4l_rvalid),
                .s_axi4l_rready     (s_axi4l_rready),
                
                .m_wb_rst_o         (reset),
                .m_wb_clk_o         (clk),
                .m_wb_adr_o         (wb_adr_i),
                .m_wb_dat_o         (wb_dat_i),
                .m_wb_dat_i         (wb_dat_o),
                .m_wb_we_o          (wb_we_i),
                .m_wb_sel_o         (wb_sel_i),
                .m_wb_stb_o         (wb_stb_i),
                .m_wb_ack_i         (wb_ack_o)
            );
    
    
    // -----------------------------
    //  RTOS
    // -----------------------------

    localparam int                              TMAX_TSKID         = 15;
    localparam int                              TMAX_SEMID         = 7;
    localparam int                              TSKPRI_WIDTH       = 4;
    localparam int                              WUPCNT_WIDTH       = 1;
    localparam int                              SUSCNT_WIDTH       = 1;
    localparam int                              SEMCNT_WIDTH       = 4;
    localparam int                              FLGPTN_WIDTH       = 32;
    localparam int                              SYSTIM_WIDTH       = 64;
    localparam int                              RELTIM_WIDTH       = 32;
    localparam int                              TTS_WIDTH          = 4;
    localparam int                              TTW_WIDTH          = 4;
    localparam int                              QUECNT_WIDTH       = $clog2(TMAX_TSKID);
    localparam int                              TSKID_WIDTH        = $clog2(TMAX_TSKID+1);
    localparam int                              SEMID_WIDTH        = $clog2(TMAX_SEMID+1);

    logic   [FLGPTN_WIDTH-1:0]                  rtos_flg_flgptn;
    logic   [TSKID_WIDTH-1:0]                   monitor_run_tskid;
    logic   [TSKID_WIDTH-1:0]                   monitor_top_tskid;
    logic   [TMAX_TSKID:1][TTS_WIDTH-1:0]       monitor_tsk_tskstat;
    logic   [TMAX_TSKID:1][TTW_WIDTH-1:0]       monitor_tsk_tskwait;
    logic   [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    monitor_tsk_wupcnt;
    logic   [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    monitor_tsk_suscnt;
    logic   [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    monitor_sem_quecnt;
    logic   [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    monitor_sem_semcnt;
    logic   [FLGPTN_WIDTH-1:0]                  monitor_flg_flgptn;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch0;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch1;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch2;
    logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch3;
    
    logic   [WB_DAT_WIDTH-1:0]      wb_rtos_dat_o;
    logic                           wb_rtos_stb_i;
    logic                           wb_rtos_ack_o;

    jelly_rtos
            #(
                .WB_ADR_WIDTH           (WB_ADR_WIDTH),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .TMAX_TSKID             (TMAX_TSKID),
                .TMAX_SEMID             (TMAX_SEMID),
                .TSKPRI_WIDTH           (TSKPRI_WIDTH),
                .WUPCNT_WIDTH           (WUPCNT_WIDTH),
                .SUSCNT_WIDTH           (SUSCNT_WIDTH),
                .SEMCNT_WIDTH           (SEMCNT_WIDTH),
                .FLGPTN_WIDTH           (FLGPTN_WIDTH),
                .SYSTIM_WIDTH           (SYSTIM_WIDTH),
                .RELTIM_WIDTH           (RELTIM_WIDTH),
                .TTS_WIDTH              (TTS_WIDTH),
                .TTW_WIDTH              (TTW_WIDTH),
                .QUECNT_WIDTH           (QUECNT_WIDTH),
                .TSKID_WIDTH            (TSKID_WIDTH),
                .SEMID_WIDTH            (SEMID_WIDTH),
                .CLOCK_RATE             (250_000_000)   // 250MHz
            )   
        i_rtos
            (   
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (1'b1),

                .s_wb_adr_i             (wb_adr_i),
                .s_wb_dat_i             (wb_dat_i),
                .s_wb_dat_o             (wb_dat_o),
                .s_wb_we_i              (wb_we_i ),
                .s_wb_sel_i             (wb_sel_i),
                .s_wb_stb_i             (wb_stb_i),
                .s_wb_ack_o             (wb_ack_o),

                .irq                    (irq),

                .extflg_flgptn          (rtos_flg_flgptn),
                
                .monitor_run_tskid      (monitor_run_tskid), 
                .monitor_top_tskid      (monitor_top_tskid), 
                .monitor_tsk_tskstat    (monitor_tsk_tskstat),
                .monitor_tsk_tskwait    (monitor_tsk_tskwait),
                .monitor_tsk_wupcnt     (monitor_tsk_wupcnt),
                .monitor_tsk_suscnt     (monitor_tsk_suscnt),

                .monitor_sem_quecnt     (monitor_sem_quecnt),
                .monitor_sem_semcnt     (monitor_sem_semcnt),
                .monitor_flg_flgptn     (monitor_flg_flgptn),
                .monitor_scratch0       (monitor_scratch0),
                .monitor_scratch1       (monitor_scratch1),
                .monitor_scratch2       (monitor_scratch2),
                .monitor_scratch3       (monitor_scratch3)
            );
    
endmodule



`default_nettype wire


// end of file
