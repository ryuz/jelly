// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 Real-Time OS
//
//                                 Copyright (C) 2008-2021 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module kv260_rtos
            (
                output  var logic           fan_en,
                output  var logic   [1:0]   led
            );
    
    
    
    // -----------------------------
    //  ZynqMP PS
    // -----------------------------
    
    localparam  AXI4L_ADDR_WIDTH = 29;
    localparam  AXI4L_DATA_SIZE  = 2;
    localparam  AXI4L_DATA_WIDTH = (8 << AXI4L_DATA_SIZE);
    localparam  AXI4L_STRB_WIDTH = AXI4L_DATA_WIDTH / 8;
    
    logic                           axi4l_aresetn;
    logic                           axi4l_aclk;
    logic   [AXI4L_ADDR_WIDTH-1:0]  axi4l_awaddr;
    logic   [2:0]                   axi4l_awprot;
    logic                           axi4l_awvalid;
    logic                           axi4l_awready;
    logic   [AXI4L_DATA_WIDTH-1:0]  axi4l_wdata;
    logic   [AXI4L_STRB_WIDTH-1:0]  axi4l_wstrb;
    logic                           axi4l_wvalid;
    logic                           axi4l_wready;
    logic   [1:0]                   axi4l_bresp;
    logic                           axi4l_bvalid;
    logic                           axi4l_bready;
    logic   [AXI4L_ADDR_WIDTH-1:0]  axi4l_araddr;
    logic   [2:0]                   axi4l_arprot;
    logic                           axi4l_arvalid;
    logic                           axi4l_arready;
    logic   [AXI4L_DATA_WIDTH-1:0]  axi4l_rdata;
    logic   [1:0]                   axi4l_rresp;
    logic                           axi4l_rvalid;
    logic                           axi4l_rready;
    
    (* mark_debug="true" *)
    logic   [0:0]                   rtos_irq_n;
    
    design_1
        i_design_1
            (
                .fan_en             (fan_en),
                
                .m_axi4l_aresetn    (axi4l_aresetn),
                .m_axi4l_aclk       (axi4l_aclk),
                .m_axi4l_awaddr     (axi4l_awaddr),
                .m_axi4l_awprot     (axi4l_awprot),
                .m_axi4l_awvalid    (axi4l_awvalid),
                .m_axi4l_awready    (axi4l_awready),
                .m_axi4l_wdata      (axi4l_wdata),
                .m_axi4l_wstrb      (axi4l_wstrb),
                .m_axi4l_wvalid     (axi4l_wvalid),
                .m_axi4l_wready     (axi4l_wready),
                .m_axi4l_bresp      (axi4l_bresp),
                .m_axi4l_bvalid     (axi4l_bvalid),
                .m_axi4l_bready     (axi4l_bready),
                .m_axi4l_araddr     (axi4l_araddr),
                .m_axi4l_arprot     (axi4l_arprot),
                .m_axi4l_arvalid    (axi4l_arvalid),
                .m_axi4l_arready    (axi4l_arready),
                .m_axi4l_rdata      (axi4l_rdata),
                .m_axi4l_rresp      (axi4l_rresp),
                .m_axi4l_rvalid     (axi4l_rvalid),
                .m_axi4l_rready     (axi4l_rready),
                
                .nfiq0_lpd_rpu      (1'b1),
                .nirq0_lpd_rpu      (rtos_irq_n),
                .nfiq1_lpd_rpu      (1'b1),
                .nirq1_lpd_rpu      (1'b1)
            );
    
    
    // -----------------------------
    //  Peripheral BUS (WISHBONE)
    // -----------------------------
    
    localparam  WB_DAT_SIZE  = AXI4L_DATA_SIZE;
    localparam  WB_ADR_WIDTH = AXI4L_ADDR_WIDTH - WB_DAT_SIZE;
    localparam  WB_DAT_WIDTH = (8 << WB_DAT_SIZE);
    localparam  WB_SEL_WIDTH = (1 << WB_DAT_SIZE);
    
    logic                           reset;
    logic                           clk;
    
    (* mark_debug="true" *) logic   [WB_ADR_WIDTH-1:0]      wb_adr_i;
    (* mark_debug="true" *) logic   [WB_DAT_WIDTH-1:0]      wb_dat_i;
    (* mark_debug="true" *) logic   [WB_DAT_WIDTH-1:0]      wb_dat_o;
    (* mark_debug="true" *) logic                           wb_we_i;
    (* mark_debug="true" *) logic   [WB_SEL_WIDTH-1:0]      wb_sel_i;
    (* mark_debug="true" *) logic                           wb_stb_i;
    (* mark_debug="true" *) logic                           wb_ack_o;
    
    jelly_axi4l_to_wishbone
            #(
                .AXI4L_ADDR_WIDTH   (AXI4L_ADDR_WIDTH),
                .AXI4L_DATA_SIZE    (AXI4L_DATA_SIZE)     // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ...
            )
        i_axi4l_to_wishbone
            (
                .s_axi4l_aresetn    (axi4l_aresetn),
                .s_axi4l_aclk       (axi4l_aclk),
                .s_axi4l_awaddr     (axi4l_awaddr),
                .s_axi4l_awprot     (axi4l_awprot),
                .s_axi4l_awvalid    (axi4l_awvalid),
                .s_axi4l_awready    (axi4l_awready),
                .s_axi4l_wstrb      (axi4l_wstrb),
                .s_axi4l_wdata      (axi4l_wdata),
                .s_axi4l_wvalid     (axi4l_wvalid),
                .s_axi4l_wready     (axi4l_wready),
                .s_axi4l_bresp      (axi4l_bresp),
                .s_axi4l_bvalid     (axi4l_bvalid),
                .s_axi4l_bready     (axi4l_bready),
                .s_axi4l_araddr     (axi4l_araddr),
                .s_axi4l_arprot     (axi4l_arprot),
                .s_axi4l_arvalid    (axi4l_arvalid),
                .s_axi4l_arready    (axi4l_arready),
                .s_axi4l_rdata      (axi4l_rdata),
                .s_axi4l_rresp      (axi4l_rresp),
                .s_axi4l_rvalid     (axi4l_rvalid),
                .s_axi4l_rready     (axi4l_rready),
                
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

    localparam  int                     TMAX_TSKID         = 5;
    localparam  int                     TMAX_SEMID         = 5;
    localparam  int                     TMAX_FLGID         = 1;
    localparam  int                     TSKPRI_WIDTH       = 4;
    localparam  int                     WUPCNT_WIDTH       = 1;
    localparam  int                     SUSCNT_WIDTH       = 1;
    localparam  int                     SEMCNT_WIDTH       = 4;
    localparam  int                     FLGPTN_WIDTH       = 32;
    localparam  int                     SYSTIM_WIDTH       = 64;
    localparam  int                     RELTIM_WIDTH       = 32;
    localparam  int                     TTS_WIDTH          = 4;
    localparam  int                     TTW_WIDTH          = 4;
    localparam  int                     QUECNT_WIDTH       = $clog2(TMAX_TSKID);
    localparam  int                     TSKID_WIDTH        = $clog2(TMAX_TSKID+1);
    localparam  int                     SEMID_WIDTH        = $clog2(TMAX_SEMID+1);

                                logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    rtos_set_flg;

    (* mark_debug = "true" *)   logic   [TSKID_WIDTH-1:0]                   monitor_top_tskid;
    (* mark_debug = "true" *)   logic   [TSKID_WIDTH-1:0]                   monitor_run_tskid;
    (* mark_debug = "true" *)   logic   [TSKPRI_WIDTH-1:0]                  monitor_run_tskpri;
    (* mark_debug = "true" *)   logic   [TMAX_TSKID:1][TTS_WIDTH-1:0]       monitor_tsk_tskstat;
    (* mark_debug = "true" *)   logic   [TMAX_TSKID:1][TTW_WIDTH-1:0]       monitor_tsk_tskwait;
    (* mark_debug = "true" *)   logic   [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    monitor_tsk_wupcnt;
    (* mark_debug = "true" *)   logic   [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    monitor_tsk_suscnt;
    (* mark_debug = "true" *)   logic   [TMAX_TSKID:1][RELTIM_WIDTH-1:0]    monitor_tsk_timcnt;
    (* mark_debug = "true" *)   logic   [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    monitor_sem_quecnt;
    (* mark_debug = "true" *)   logic   [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    monitor_sem_semcnt;
    (* mark_debug = "true" *)   logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    monitor_flg_flgptn;
    (* mark_debug = "true" *)   logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch0;
    (* mark_debug = "true" *)   logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch1;
    (* mark_debug = "true" *)   logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch2;
    (* mark_debug = "true" *)   logic   [WB_DAT_WIDTH-1:0]                  monitor_scratch3;

    logic   [WB_DAT_WIDTH-1:0]      wb_rtos_dat_o;
    logic                           wb_rtos_stb_i;
    logic                           wb_rtos_ack_o;

    jelly2_rtos
            #(
                .WB_ADR_WIDTH           (WB_ADR_WIDTH),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .TMAX_TSKID             (TMAX_TSKID),
                .TMAX_SEMID             (TMAX_SEMID),
                .TMAX_FLGID             (TMAX_FLGID),
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
                .s_wb_dat_o             (wb_rtos_dat_o),
                .s_wb_we_i              (wb_we_i ),
                .s_wb_sel_i             (wb_sel_i),
                .s_wb_stb_i             (wb_rtos_stb_i),
                .s_wb_ack_o             (wb_rtos_ack_o),

                .irq_n                  (rtos_irq_n),

                .ext_set_flg            (rtos_set_flg),

                .monitor_top_tskid      (monitor_top_tskid), 
                .monitor_run_tskid      (monitor_run_tskid), 
                .monitor_run_tskpri     (monitor_run_tskpri), 
                .monitor_tsk_tskstat    (monitor_tsk_tskstat),
                .monitor_tsk_tskwait    (monitor_tsk_tskwait),
                .monitor_tsk_wupcnt     (monitor_tsk_wupcnt),
                .monitor_tsk_suscnt     (monitor_tsk_suscnt),
                .monitor_tsk_timcnt     (monitor_tsk_timcnt),
                .monitor_sem_quecnt     (monitor_sem_quecnt),
                .monitor_sem_semcnt     (monitor_sem_semcnt),
                .monitor_flg_flgptn     (monitor_flg_flgptn),
                .monitor_scratch0       (monitor_scratch0),
                .monitor_scratch1       (monitor_scratch1),
                .monitor_scratch2       (monitor_scratch2),
                .monitor_scratch3       (monitor_scratch3)
            );
    
    
    
    // -----------------------------
    //  Test LED
    // -----------------------------
    
    logic   [WB_DAT_WIDTH-1:0]      wb_led_dat_o;
    logic                           wb_led_stb_i;
    logic                           wb_led_ack_o;
    
    logic   [0:0]                   reg_led;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_led <= 0;
        end
        else begin
            if (wb_led_stb_i && wb_we_i && wb_sel_i[0]) begin
                reg_led <= wb_dat_i[0:0];
            end
        end
    end
    
    assign wb_led_dat_o = {31'd0, reg_led};
    assign wb_led_ack_o = wb_led_stb_i;
    
    
    logic   [25:0]  reg_clk_count;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_clk_count <= 0;
        end
        else begin
            reg_clk_count <= reg_clk_count + 1;
        end
    end
    
    assign led[0] = reg_led;
    assign led[1] = reg_clk_count[25];
    
    
    
    
    // -----------------------------
    //  Test Timer
    // -----------------------------
    
    logic                           tim_irq;

    logic   [WB_DAT_WIDTH-1:0]      wb_tim_dat_o;
    logic                           wb_tim_stb_i;
    logic                           wb_tim_ack_o;
    
    jelly_interval_timer
            #(
                .WB_ADR_WIDTH       (2),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                .IRQ_LEVEL          (0)
            )
        i_interval_timer
            (
                .reset              (reset),
                .clk                (clk),
                
                .interrupt_req      (tim_irq),
                
                .s_wb_adr_i         (wb_adr_i[1:0]),
                .s_wb_dat_o         (wb_tim_dat_o),
                .s_wb_dat_i         (wb_dat_i),
                .s_wb_we_i          (wb_we_i),
                .s_wb_sel_i         (wb_sel_i),
                .s_wb_stb_i         (wb_tim_stb_i),
                .s_wb_ack_o         (wb_tim_ack_o)
            );
    
    always_comb begin
        rtos_set_flg       = '0;
        rtos_set_flg[1][0] = tim_irq;
    end

    
    // -----------------------------
    //  WISHBONE address decode
    // -----------------------------
    
    assign wb_rtos_stb_i = wb_stb_i & (wb_adr_i[23:16] == 8'h00);
    assign wb_led_stb_i  = wb_stb_i & (wb_adr_i[23:16] == 8'h01);
    assign wb_tim_stb_i  = wb_stb_i & (wb_adr_i[23:16] == 8'h02);
    
    assign wb_dat_o      = wb_rtos_stb_i ? wb_rtos_dat_o :
                           wb_led_stb_i  ? wb_led_dat_o  :
                           wb_tim_stb_i  ? wb_tim_dat_o  :
                           {WB_DAT_WIDTH{1'b0}};
    
    assign wb_ack_o      = wb_rtos_stb_i ? wb_rtos_ack_o :
                           wb_led_stb_i  ? wb_led_ack_o  :
                           wb_tim_stb_i  ? wb_tim_ack_o  :
                           wb_stb_i;
    
    
endmodule



`default_nettype wire


// end of file
