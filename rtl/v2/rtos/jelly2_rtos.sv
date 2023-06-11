// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_rtos
        #(
            parameter   int                                         WB_ADR_WIDTH       = 16,
            parameter   int                                         WB_DAT_WIDTH       = 32,
            parameter   int                                         WB_SEL_WIDTH       = WB_DAT_WIDTH/8,
            parameter   int                                         TMAX_TSKID         = 15,
            parameter   int                                         TMAX_SEMID         = 7,
            parameter   int                                         TMAX_FLGID         = 2,
            parameter   int                                         TSKPRI_WIDTH       = 4,
            parameter   int                                         WUPCNT_WIDTH       = 1,
            parameter   int                                         SUSCNT_WIDTH       = 1,
            parameter   int                                         SEMCNT_WIDTH       = 4,
            parameter   int                                         FLGPTN_WIDTH       = 32,
            parameter   int                                         PRESCL_WIDTH       = 32,
            parameter   int                                         SYSTIM_WIDTH       = 64,
            parameter   int                                         RELTIM_WIDTH       = 32,
            parameter   int                                         ER_WIDTH           = 8,
            parameter   int                                         TTS_WIDTH          = 4,
            parameter   int                                         TTW_WIDTH          = 4,
            parameter   bit     [WUPCNT_WIDTH-1:0]                  TMAX_WUPCNT        = '1,
            parameter   bit     [SUSCNT_WIDTH-1:0]                  TMAX_SUSCNT        = '1,
            parameter   int                                         QUECNT_WIDTH       = $clog2(TMAX_TSKID),
            parameter   int                                         TSKID_WIDTH        = $clog2(TMAX_TSKID+1),
            parameter   int                                         SEMID_WIDTH        = $clog2(TMAX_SEMID+1),
            parameter   int                                         CLOCK_RATE         = 100000000,
            parameter   int                                         SCRATCH0_WIDTH     = WB_DAT_WIDTH,
            parameter   int                                         SCRATCH1_WIDTH     = WB_DAT_WIDTH,
            parameter   int                                         SCRATCH2_WIDTH     = WB_DAT_WIDTH,
            parameter   int                                         SCRATCH3_WIDTH     = WB_DAT_WIDTH,

            parameter   bit                                         USE_CHG_PRI        = 1,
            parameter   bit                                         USE_SLP_TSK        = 1,
            parameter   bit                                         USE_SUS_TSK        = 1,
            parameter   bit                                         USE_DLY_TSK        = 1,
            parameter   bit                                         USE_REL_WAI        = 1,
            parameter   bit                                         USE_SET_TMO        = 1,
            parameter   bit                                         USE_SIG_SEM        = 1,
            parameter   bit                                         USE_WAI_SEM        = 1,
            parameter   bit                                         USE_POL_SEM        = 1,
            parameter   bit                                         USE_SET_FLG        = 1,
            parameter   bit                                         USE_CLR_FLG        = 1,
            parameter   bit                                         USE_POL_FLG        = 1,
            parameter   bit                                         USE_WAI_FLG        = 1,
            parameter   bit                                         USE_EXT_FLG        = 1,
            parameter   bit                                         USE_ENA_FLG_EXT    = 1,
            parameter   bit                                         USE_LVL_FLG_EXT    = 1,
            parameter   bit                                         USE_GET_PRI        = 1,
            parameter   bit                                         USE_SET_PSCL       = 1,
            parameter   bit                                         USE_SET_TIM        = 1,
            parameter   bit                                         USE_GET_TIM        = 1,
            parameter   bit                                         USE_REF_TSKSTAT    = 1,
            parameter   bit                                         USE_REF_TSKWAIT    = 1,
            parameter   bit                                         USE_REF_WUPCNT     = 1,
            parameter   bit                                         USE_REF_SUSCNT     = 1,
            parameter   bit                                         USE_REF_TIMCNT     = 1,
            parameter   bit                                         USE_REF_ERCD       = 1,
            parameter   bit                                         USE_REF_SEMCNT     = 1,
            parameter   bit                                         USE_REF_SEMQUE     = 1,
            parameter   bit                                         USE_REF_FLGPTN     = 1,
            parameter   bit                                         USE_SCRATCH0       = 1,
            parameter   bit                                         USE_SCRATCH1       = 1,
            parameter   bit                                         USE_SCRATCH2       = 1,
            parameter   bit                                         USE_SCRATCH3       = 1,

            parameter   bit     [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    INIT_FLGPTN        = '0,
            parameter   bit     [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    INIT_EXTFLG_ENABLE = '0,
            parameter   bit     [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    INIT_EXTFLG_LEVEL  = '0,
            parameter   bit     [PRESCL_WIDTH-1:0]                  INIT_PRESCL        = '0,
            parameter   bit     [SYSTIM_WIDTH-1:0]                  INIT_SYSTIM        = '0,
            parameter   bit     [SCRATCH0_WIDTH-1:0]                INIT_SCRATCH0      = '0,
            parameter   bit     [SCRATCH1_WIDTH-1:0]                INIT_SCRATCH1      = '0,
            parameter   bit     [SCRATCH2_WIDTH-1:0]                INIT_SCRATCH2      = '0,
            parameter   bit     [SCRATCH3_WIDTH-1:0]                INIT_SCRATCH3      = '0
        )
        (
            input   var logic                                       reset,
            input   var logic                                       clk,
            input   var logic                                       cke,

            input   var logic   [WB_ADR_WIDTH-1:0]                  s_wb_adr_i,
            input   var logic   [WB_DAT_WIDTH-1:0]                  s_wb_dat_i,
            output  var logic   [WB_DAT_WIDTH-1:0]                  s_wb_dat_o,
            input   var logic                                       s_wb_we_i,
            input   var logic   [WB_SEL_WIDTH-1:0]                  s_wb_sel_i,
            input   var logic                                       s_wb_stb_i,
            output  var logic                                       s_wb_ack_o,

            output  var logic                                       irq_n,

            input   var logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    ext_set_flg,

            output  var logic   [TSKID_WIDTH-1:0]                   monitor_top_tskid,
            output  var logic   [TSKID_WIDTH-1:0]                   monitor_run_tskid,
            output  var logic   [TSKPRI_WIDTH-1:0]                  monitor_run_tskpri,
            output  var logic   [TMAX_TSKID:1][TTS_WIDTH-1:0]       monitor_tsk_tskstat,
            output  var logic   [TMAX_TSKID:1][TTW_WIDTH-1:0]       monitor_tsk_tskwait,
            output  var logic   [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    monitor_tsk_wupcnt,
            output  var logic   [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    monitor_tsk_suscnt,
            output  var logic   [TMAX_TSKID:1][RELTIM_WIDTH-1:0]    monitor_tsk_timcnt,
            output  var logic   [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    monitor_sem_quecnt,
            output  var logic   [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    monitor_sem_semcnt,
            output  var logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    monitor_flg_flgptn,
            output  var logic   [SCRATCH0_WIDTH-1:0]                monitor_scratch0,
            output  var logic   [SCRATCH1_WIDTH-1:0]                monitor_scratch1,
            output  var logic   [SCRATCH2_WIDTH-1:0]                monitor_scratch2,
            output  var logic   [SCRATCH3_WIDTH-1:0]                monitor_scratch3
        );


    // -----------------------------------------
    //  Core
    // -----------------------------------------

    // system
    logic                                       core_reset;
    logic                                       core_busy;

    // ready queue
    logic   [TSKID_WIDTH-1:0]                   rdq_top_tskid;
    logic   [TSKPRI_WIDTH-1:0]                  rdq_top_tskpri;
    logic   [QUECNT_WIDTH-1:0]                  rdq_quecnt;

    // run task
    logic   [TSKID_WIDTH-1:0]                   run_tskid;
    logic   [TSKPRI_WIDTH-1:0]                  run_tskpri;

    // operation id
    logic   [TSKID_WIDTH-1:0]                   op_tskid;
    logic   [SEMID_WIDTH-1:0]                   op_semid;

    // task
    logic   [TSKPRI_WIDTH-1:0]                  chg_pri_tskpri;
    logic                                       chg_pri_valid;
    logic                                       wup_tsk_valid;
    logic                                       slp_tsk_valid;
    logic                                       rsm_tsk_valid;
    logic                                       sus_tsk_valid;
    logic                                       rel_wai_valid;
    logic   [RELTIM_WIDTH-1:0]                  dly_tsk_dlytim;
    logic                                       dly_tsk_valid;
    logic   [RELTIM_WIDTH-1:0]                  set_tmo_tmotim;
    logic                                       set_tmo_valid;
    logic   [TMAX_TSKID:1][TTS_WIDTH-1:0]       task_tskstat;
    logic   [TMAX_TSKID:1][TTW_WIDTH-1:0]       task_tskwait;
    logic   [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    task_wupcnt;
    logic   [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    task_suscnt;
    logic   [TMAX_TSKID:1][RELTIM_WIDTH-1:0]    task_timcnt;
    logic   [TMAX_TSKID:1][TSKPRI_WIDTH-1:0]    task_tskpri;
    logic   [TMAX_TSKID:1][ER_WIDTH-1:0]        task_ercd;

    // semaphore                
    logic                                       sig_sem_valid;
    logic                                       wai_sem_valid;
    logic                                       pol_sem_valid;
    logic                                       pol_sem_ack;
    logic   [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    semaphore_semcnt;
    logic   [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    semaphore_quecnt;

    // event flag
    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    set_flg;
    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    clr_flg;
    logic   [0:0]                               wai_flg_wfmode;
    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    wai_flg_flgptn;
    logic                                       wai_flg_valid;
    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    flg_flgptn;

    // timer
    logic   [PRESCL_WIDTH-1:0]                  set_pscl_scale;
    logic                                       set_pscl_valid;
    logic   [SYSTIM_WIDTH-1:0]                  set_tim_systim;
    logic                                       set_tim_valid;
    logic                                       time_tick;
    logic   [SYSTIM_WIDTH-1:0]                  systim;
    logic   [SYSTIM_WIDTH-1:0]                  reg_systim;

    jelly2_rtos_core
            #(
                .TMAX_TSKID         (TMAX_TSKID),
                .TMAX_SEMID         (TMAX_SEMID),
                .TMAX_FLGID         (TMAX_FLGID),
                .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                .SEMCNT_WIDTH       (SEMCNT_WIDTH),
                .FLGPTN_WIDTH       (FLGPTN_WIDTH),
                .PRESCL_WIDTH       (PRESCL_WIDTH),
                .SYSTIM_WIDTH       (SYSTIM_WIDTH),
                .RELTIM_WIDTH       (RELTIM_WIDTH),
                .WUPCNT_WIDTH       (WUPCNT_WIDTH),
                .SUSCNT_WIDTH       (SUSCNT_WIDTH),
                .ER_WIDTH           (ER_WIDTH),
                .TTS_WIDTH          (TTS_WIDTH),
                .TTW_WIDTH          (TTW_WIDTH),
                .TMAX_WUPCNT        (TMAX_WUPCNT),
                .TMAX_SUSCNT        (TMAX_SUSCNT),
                .USE_ERCD           (USE_REF_ERCD),
                .USE_SET_TMO        (USE_SET_TMO),
                .USE_CHG_PRI        (USE_CHG_PRI),
                .USE_SLP_TSK        (USE_SLP_TSK),
                .USE_SUS_TSK        (USE_SUS_TSK),
                .USE_DLY_TSK        (USE_DLY_TSK),
                .USE_REL_WAI        (USE_REL_WAI),
                .USE_SIG_SEM        (USE_SIG_SEM),
                .USE_WAI_SEM        (USE_WAI_SEM),
                .USE_POL_SEM        (USE_POL_SEM),
                .USE_WAI_FLG        (USE_WAI_FLG),
                .USE_SET_PSCL       (USE_SET_PSCL),
                .USE_SET_TIM        (USE_SET_TIM),
                .TSKID_WIDTH        (TSKID_WIDTH),
                .SEMID_WIDTH        (SEMID_WIDTH),
                .QUECNT_WIDTH       (QUECNT_WIDTH),
                .INIT_FLGPTN        (INIT_FLGPTN),
                .INIT_PRESCL        (INIT_PRESCL),
                .INIT_SYSTIM        (INIT_SYSTIM)
            )
        i_rtos_core 
            (
                .reset              (core_reset),
                .clk,   
                .cke,   

                .busy               (core_busy),     

                .rdq_top_tskid,
                .rdq_top_tskpri,
                .rdq_quecnt,

                .run_tskid,
                .run_tskpri,

                .op_tskid,
                .op_semid,

                .chg_pri_tskpri,
                .chg_pri_valid,
                .wup_tsk_valid,
                .slp_tsk_valid,
                .rsm_tsk_valid,
                .sus_tsk_valid,
                .rel_wai_valid,
                .dly_tsk_dlytim,
                .dly_tsk_valid,
                .set_tmo_tmotim,
                .set_tmo_valid,
                .task_tskstat,
                .task_tskwait,
                .task_wupcnt,
                .task_suscnt,
                .task_timcnt,
                .task_tskpri,
                .task_ercd,

                .sig_sem_valid,
                .wai_sem_valid,
                .pol_sem_valid,
                .pol_sem_ack,
                .semaphore_quecnt,
                .semaphore_semcnt,

                .set_flg,
                .clr_flg,
                .wai_flg_wfmode,
                .wai_flg_flgptn,
                .wai_flg_valid,
                .flg_flgptn,

                .set_pscl_scale,
                .set_pscl_valid,
                .set_tim_systim,
                .set_tim_valid,
                .time_tick,
                .systim
            );
    

    // -----------------------------------------
    //  Wishbone
    // -----------------------------------------

    localparam  int                         ID_WIDTH          = 8;
    localparam  int                         OPCODE_WIDTH      = 8;
    localparam  int                         DECODE_ID_POS     = 0;
    localparam  int                         DECODE_OPCODE_POS = DECODE_ID_POS + ID_WIDTH;

    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYS_CFG       = OPCODE_WIDTH'(8'h00);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CPU_CTL       = OPCODE_WIDTH'(8'h01);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WUP_TSK       = OPCODE_WIDTH'(8'h10);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SLP_TSK       = OPCODE_WIDTH'(8'h11);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_RSM_TSK       = OPCODE_WIDTH'(8'h14);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SUS_TSK       = OPCODE_WIDTH'(8'h15);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REL_WAI       = OPCODE_WIDTH'(8'h16);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DLY_TSK       = OPCODE_WIDTH'(8'h18);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CHG_PRI       = OPCODE_WIDTH'(8'h1c);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_TMO       = OPCODE_WIDTH'(8'h1f);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_TSKSTAT   = OPCODE_WIDTH'(8'h90);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_TSKWAIT   = OPCODE_WIDTH'(8'h91);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_WUPCNT    = OPCODE_WIDTH'(8'h92);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SUSCNT    = OPCODE_WIDTH'(8'h93);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_TIMCNT    = OPCODE_WIDTH'(8'h94);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_ERCD      = OPCODE_WIDTH'(8'h98);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_GET_PRI       = OPCODE_WIDTH'(8'h9c);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SIG_SEM       = OPCODE_WIDTH'(8'h21);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_SEM       = OPCODE_WIDTH'(8'h22);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_POL_SEM       = OPCODE_WIDTH'(8'h23);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SEMCNT    = OPCODE_WIDTH'(8'ha0);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_SEMQUE    = OPCODE_WIDTH'(8'ha1);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_FLG       = OPCODE_WIDTH'(8'h31);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CLR_FLG       = OPCODE_WIDTH'(8'h32);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_AND   = OPCODE_WIDTH'(8'h33);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_OR    = OPCODE_WIDTH'(8'h34);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_ENA_FLG_EXT   = OPCODE_WIDTH'(8'h3a);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DIS_FLG_EXT   = OPCODE_WIDTH'(8'h3b);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_LVL_FLG_EXT   = OPCODE_WIDTH'(8'h3c);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_FLGPTN    = OPCODE_WIDTH'(8'hb0);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_EXTFLGENA = OPCODE_WIDTH'(8'hb1);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_EXTFLGLVL = OPCODE_WIDTH'(8'hb2);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_TIM       = OPCODE_WIDTH'(8'h70);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_PSCL      = OPCODE_WIDTH'(8'h72);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_GET_TIM       = OPCODE_WIDTH'(8'hf0);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYSTIM_LO     = OPCODE_WIDTH'(8'hf2);
    localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SYSTIM_HI     = OPCODE_WIDTH'(8'hf3);

    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_CORE_ID      = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_VERSION      = 'h01;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_DATE         = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_CLOCK_RATE   = 'h07;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TMAX_TSKID   = 'h20;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TMAX_SEMID   = 'h21;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TMAX_FLGID   = 'h22;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_TSKPRI_WIDTH = 'h30;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SEMCNT_WIDTH = 'h31;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_FLGPTN_WIDTH = 'h32;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SYSTIM_WIDTH = 'h34;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_RELTIM_WIDTH = 'h35;
    localparam  bit     [ID_WIDTH-1:0]      SYS_CFG_SOFT_RESET   = 'hff;

    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_TOP_TSKID  = 'h00;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_TSKID  = 'h04;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_RUN_TSKPRI = 'h05;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_COPY_TSKID = 'h08;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_EN     = 'h10;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_STS    = 'h11;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_IRQ_FORCE  = 'h1f;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH0   = 'he0;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH1   = 'he1;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH2   = 'he2;
    localparam  bit     [ID_WIDTH-1:0]      CPU_CTL_SCRATCH3   = 'he3;

    localparam  bit     [SYSTIM_WIDTH-1:0]  SYSLIM_LO_MASK = SYSTIM_WIDTH'({WB_DAT_WIDTH{1'b1}});
    localparam  bit     [SYSTIM_WIDTH-1:0]  SYSLIM_HI_MASK = ~SYSLIM_LO_MASK;

    logic   [OPCODE_WIDTH-1:0]      dec_opcode;
    logic   [ID_WIDTH-1:0]          dec_id;
    assign  dec_opcode = s_wb_adr_i[DECODE_OPCODE_POS +: OPCODE_WIDTH];
    assign  dec_id     = s_wb_adr_i[DECODE_ID_POS     +: ID_WIDTH];

    logic   [0:0]                               irq_enable;
    logic   [0:0]                               irq_force;
    logic   [0:0]                               reg_switch;
    logic   [0:0]                               reg_irq;

    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    extflg_enable;
    logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    extflg_level;

    logic   [SCRATCH0_WIDTH-1:0]                scratch0;
    logic   [SCRATCH1_WIDTH-1:0]                scratch1;
    logic   [SCRATCH2_WIDTH-1:0]                scratch2;
    logic   [SCRATCH3_WIDTH-1:0]                scratch3;

    always_ff @(posedge clk) begin
        if ( reset || core_reset ) begin
            core_reset     <= reset;
            run_tskid      <= '0;
            run_tskpri     <= '1;
            irq_enable     <= '0;
            irq_force      <= '0;
            reg_switch     <= '0;
            reg_irq        <= '0;
            extflg_enable  <= INIT_EXTFLG_ENABLE;
            extflg_level   <= INIT_EXTFLG_LEVEL;
            reg_systim     <= INIT_SYSTIM;
            scratch0       <= INIT_SCRATCH0;
            scratch1       <= INIT_SCRATCH1;
            scratch2       <= INIT_SCRATCH2;
            scratch3       <= INIT_SCRATCH3;
        end
        else if ( cke ) begin
            core_reset <= 1'b0;

            // write
            if ( s_wb_ack_o && s_wb_we_i && &s_wb_sel_i ) begin
                case ( dec_opcode )
                OPCODE_SYS_CFG:
                    case ( dec_id )
                    SYS_CFG_SOFT_RESET: begin core_reset <= 1'b1; end
                    default: ;
                    endcase

                OPCODE_CPU_CTL:
                    case ( dec_id )
                    CPU_CTL_RUN_TSKID:  begin run_tskid  <= TSKID_WIDTH'(s_wb_dat_i);  end
                    CPU_CTL_RUN_TSKPRI: begin run_tskpri <= TSKPRI_WIDTH'(s_wb_dat_i); end
                    CPU_CTL_IRQ_EN:     begin irq_enable     <= 1'(s_wb_dat_i); end
                    CPU_CTL_IRQ_FORCE:  begin irq_force      <= 1'(s_wb_dat_i); end
                    CPU_CTL_SCRATCH0:   if ( USE_SCRATCH0 ) begin scratch0 <= SCRATCH0_WIDTH'(s_wb_dat_i); end
                    CPU_CTL_SCRATCH1:   if ( USE_SCRATCH1 ) begin scratch1 <= SCRATCH1_WIDTH'(s_wb_dat_i); end
                    CPU_CTL_SCRATCH2:   if ( USE_SCRATCH2 ) begin scratch2 <= SCRATCH2_WIDTH'(s_wb_dat_i); end
                    CPU_CTL_SCRATCH3:   if ( USE_SCRATCH3 ) begin scratch3 <= SCRATCH3_WIDTH'(s_wb_dat_i); end
                    default: ;
                    endcase

                OPCODE_ENA_FLG_EXT:
                    begin
                        if ( USE_EXT_FLG && USE_ENA_FLG_EXT && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                            extflg_enable[dec_id] <= extflg_enable[dec_id] | FLGPTN_WIDTH'(s_wb_dat_i);
                        end
                    end

                OPCODE_LVL_FLG_EXT:
                    begin
                        if ( USE_EXT_FLG && USE_LVL_FLG_EXT && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                            extflg_enable[dec_id] <= extflg_enable[dec_id] | FLGPTN_WIDTH'(s_wb_dat_i);
                        end
                    end

                OPCODE_DIS_FLG_EXT:
                    begin
                        if ( USE_EXT_FLG && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                            extflg_enable[dec_id] <= extflg_enable[dec_id] & FLGPTN_WIDTH'(s_wb_dat_i);
                        end
                    end

                OPCODE_GET_TIM:     if ( USE_GET_TIM ) begin reg_systim <= systim; end
                OPCODE_SYSTIM_LO:   if ( USE_SET_TIM ) begin reg_systim <= ((reg_systim & SYSLIM_HI_MASK) | SYSTIM_WIDTH'(s_wb_dat_i)); end
                OPCODE_SYSTIM_HI:   if ( USE_SET_TIM ) begin reg_systim <= ((reg_systim & SYSLIM_LO_MASK) | (SYSTIM_WIDTH'(s_wb_dat_i) << WB_DAT_WIDTH)); end

                default: ;
                endcase

            end

            // 読み出しと同時にコピーも実施
            if ( s_wb_ack_o && !s_wb_we_i && dec_opcode == OPCODE_CPU_CTL && dec_id == CPU_CTL_COPY_TSKID ) begin
                run_tskid  <= rdq_top_tskid;
                run_tskpri <= rdq_top_tskpri;
            end

            // 2サイクル不一致が続けば割り込み実施
            if ( !core_busy ) begin
                reg_switch <= (rdq_top_tskid != run_tskid);
                reg_irq    <= (rdq_top_tskid != run_tskid) && reg_switch;
            end
        end
    end
    
    logic       irq;
    assign irq   = ((reg_irq & irq_enable) | irq_force);
    assign irq_n = ~irq;

    always_comb begin : blk_wb_cmd
        op_tskid = 'x;
        op_semid = 'x;

        wup_tsk_valid = '0;
        slp_tsk_valid = '0;
        rsm_tsk_valid = '0;
        sus_tsk_valid = '0;
        rel_wai_valid = '0;
        set_tmo_valid = '0;
        dly_tsk_dlytim = 'x;
        dly_tsk_valid  = '0;

        sig_sem_valid = '0;
        wai_sem_valid = '0;
        pol_sem_valid = '0;

        set_flg        = '0;
        clr_flg        = '1;
        wai_flg_wfmode = 'x;
        wai_flg_flgptn = 'x;
        wai_flg_valid  = '0;

        set_pscl_scale = 'x;
        set_pscl_valid = 1'b0;
        set_tim_systim = 'x;
        set_tim_valid  = 1'b0;

        // write
        if ( s_wb_ack_o && s_wb_we_i && &s_wb_sel_i ) begin
            case ( dec_opcode )
            OPCODE_CHG_PRI: if ( USE_CHG_PRI ) begin chg_pri_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_WUP_TSK: if ( USE_SLP_TSK ) begin wup_tsk_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_SLP_TSK: if ( USE_SLP_TSK ) begin slp_tsk_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_RSM_TSK: if ( USE_SUS_TSK ) begin rsm_tsk_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_SUS_TSK: if ( USE_SUS_TSK ) begin sus_tsk_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_REL_WAI: if ( USE_REL_WAI ) begin rel_wai_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); end
            OPCODE_SET_TMO: if ( USE_SET_TMO ) begin set_tmo_valid = 1'b1; op_tskid = TSKID_WIDTH'(dec_id); set_tmo_tmotim = RELTIM_WIDTH'(s_wb_dat_i); end
            
            OPCODE_SET_FLG:
                begin
                    if ( USE_SET_FLG && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                        set_flg[dec_id] = FLGPTN_WIDTH'(s_wb_dat_i);
                    end
                end

            OPCODE_CLR_FLG:
                begin
                    if ( USE_CLR_FLG && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                        clr_flg[dec_id] = FLGPTN_WIDTH'(s_wb_dat_i);
                    end
                end

            OPCODE_DLY_TSK:
                begin
                    if ( USE_DLY_TSK ) begin
                        op_tskid       = TSKID_WIDTH'(dec_id);
                        dly_tsk_dlytim = RELTIM_WIDTH'(s_wb_dat_i);
                        dly_tsk_valid  = 1'b1;
                    end
                end

            OPCODE_SIG_SEM:
                begin
                    if ( USE_SIG_SEM ) begin
                        op_semid = SEMID_WIDTH'(dec_id);
                        sig_sem_valid = 1'b1;
                    end
                end

            OPCODE_WAI_SEM:
                begin
                    if ( USE_WAI_SEM ) begin
                        op_tskid = run_tskid;
                        op_semid = SEMID_WIDTH'(dec_id);
                        wai_sem_valid = 1'b1;
                    end
                end

            OPCODE_WAI_FLG_AND:
                begin
                    if ( USE_WAI_FLG && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                        op_tskid               = run_tskid;
                        wai_flg_flgptn         = '0;
                        wai_flg_flgptn[dec_id] = FLGPTN_WIDTH'(s_wb_dat_i);
                        wai_flg_wfmode         = 1'b0;
                        wai_flg_valid          = 1'b1;
                    end
                end
            
            OPCODE_WAI_FLG_OR:
                begin
                    if ( USE_WAI_FLG && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_FLGID ) begin
                        op_tskid               = run_tskid;
                        wai_flg_flgptn         = '0;
                        wai_flg_flgptn[dec_id] = FLGPTN_WIDTH'(s_wb_dat_i);
                        wai_flg_wfmode         = 1'b1;
                        wai_flg_valid          = 1'b1;
                    end
                end
            
            OPCODE_SET_PSCL:
                begin
                    set_pscl_scale = PRESCL_WIDTH'(s_wb_dat_i);
                    set_pscl_valid = 1'b1;
                end

            OPCODE_SET_TIM:
                begin
                    set_tim_systim = reg_systim;
                    set_tim_valid  = 1'b0;
                end
            
            default: ;
            endcase
        end

        // read
        if ( s_wb_ack_o && !s_wb_we_i && &s_wb_sel_i ) begin
            case ( dec_opcode )
            OPCODE_POL_SEM:     begin pol_sem_valid = 1'b1; op_semid = SEMID_WIDTH'(dec_id);  end
            default: ;
            endcase
        end

        // external flag
        if ( USE_EXT_FLG ) begin
            set_flg = set_flg | (extflg_enable & ext_set_flg);
            set_flg = set_flg & (~extflg_level | ext_set_flg);
        end
    end
    
    // wishbone read
    always_comb begin : blk_wb_dat_o
        s_wb_dat_o = '0;

        case ( dec_opcode )
        OPCODE_SYS_CFG:
            case ( dec_id )
            SYS_CFG_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(32'h834f5452);
            SYS_CFG_VERSION:        s_wb_dat_o = WB_DAT_WIDTH'(32'h0001_0000);
            SYS_CFG_DATE:           s_wb_dat_o = WB_DAT_WIDTH'(32'h2021_11_28);
            SYS_CFG_CLOCK_RATE:     s_wb_dat_o = WB_DAT_WIDTH'(CLOCK_RATE);
            SYS_CFG_TMAX_TSKID:     s_wb_dat_o = WB_DAT_WIDTH'(TMAX_TSKID);
            SYS_CFG_TMAX_SEMID:     s_wb_dat_o = WB_DAT_WIDTH'(TMAX_SEMID);
            SYS_CFG_TMAX_FLGID:     s_wb_dat_o = WB_DAT_WIDTH'(TMAX_FLGID);
            SYS_CFG_TSKPRI_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(TSKPRI_WIDTH);
            SYS_CFG_SEMCNT_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(SEMCNT_WIDTH);
            SYS_CFG_FLGPTN_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(FLGPTN_WIDTH);
            SYS_CFG_SYSTIM_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(SYSTIM_WIDTH);
            SYS_CFG_RELTIM_WIDTH:   s_wb_dat_o = WB_DAT_WIDTH'(RELTIM_WIDTH);
            default: ;
            endcase

        OPCODE_CPU_CTL:
            case ( dec_id )
            CPU_CTL_TOP_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(rdq_top_tskid);
            CPU_CTL_RUN_TSKID:  s_wb_dat_o = WB_DAT_WIDTH'(run_tskid);
            CPU_CTL_RUN_TSKPRI: s_wb_dat_o = WB_DAT_WIDTH'(run_tskpri);
            CPU_CTL_COPY_TSKID: s_wb_dat_o = WB_DAT_WIDTH'(rdq_top_tskid);
            CPU_CTL_IRQ_EN:     s_wb_dat_o = WB_DAT_WIDTH'(irq_enable);
            CPU_CTL_IRQ_STS:    s_wb_dat_o = WB_DAT_WIDTH'(irq);
            CPU_CTL_SCRATCH0:   s_wb_dat_o = WB_DAT_WIDTH'(scratch0);
            CPU_CTL_SCRATCH1:   s_wb_dat_o = WB_DAT_WIDTH'(scratch1);
            CPU_CTL_SCRATCH2:   s_wb_dat_o = WB_DAT_WIDTH'(scratch2);
            CPU_CTL_SCRATCH3:   s_wb_dat_o = WB_DAT_WIDTH'(scratch3);
            default: ;
            endcase
        
        OPCODE_POL_SEM:     s_wb_dat_o = USE_POL_SEM     ? WB_DAT_WIDTH'(pol_sem_ack)      : '0;
        OPCODE_GET_PRI:     s_wb_dat_o = USE_GET_PRI     ? WB_DAT_WIDTH'(task_tskpri)      : '0;
        OPCODE_REF_TSKSTAT: s_wb_dat_o = USE_REF_TSKSTAT ? WB_DAT_WIDTH'(task_tskstat)     : '0;
        OPCODE_REF_TSKWAIT: s_wb_dat_o = USE_REF_TSKWAIT ? WB_DAT_WIDTH'(task_tskwait)     : '0;
        OPCODE_REF_WUPCNT:  s_wb_dat_o = USE_REF_WUPCNT  ? WB_DAT_WIDTH'(task_wupcnt)      : '0;
        OPCODE_REF_SUSCNT:  s_wb_dat_o = USE_REF_SUSCNT  ? WB_DAT_WIDTH'(task_suscnt)      : '0;
        OPCODE_REF_TIMCNT:  s_wb_dat_o = USE_REF_TIMCNT  ? WB_DAT_WIDTH'(task_timcnt)      : '0;
        OPCODE_REF_ERCD:
            begin
                if ( USE_REF_ERCD && int'(dec_id) >= 1 && int'(dec_id) <= TMAX_TSKID ) begin
                    s_wb_dat_o = WB_DAT_WIDTH'($signed(task_ercd[dec_id]));
                end
            end
        
        OPCODE_REF_SEMCNT:  s_wb_dat_o = USE_REF_SEMCNT  ? WB_DAT_WIDTH'(semaphore_semcnt) : '0;
        OPCODE_REF_SEMQUE:  s_wb_dat_o = USE_REF_SEMQUE  ? WB_DAT_WIDTH'(semaphore_quecnt) : '0;
        
        OPCODE_REF_FLGPTN:  s_wb_dat_o = (USE_POL_FLG || USE_REF_FLGPTN) ? WB_DAT_WIDTH'(flg_flgptn) : '0;

        OPCODE_REF_EXTFLGENA:  s_wb_dat_o = USE_EXT_FLG ? WB_DAT_WIDTH'(extflg_enable) : '0;
        OPCODE_REF_EXTFLGLVL:  s_wb_dat_o = USE_EXT_FLG ? WB_DAT_WIDTH'(extflg_level)  : '0;
        
        OPCODE_SYSTIM_LO:   s_wb_dat_o = USE_GET_TIM     ? WB_DAT_WIDTH'(reg_systim)                 : '0;
        OPCODE_SYSTIM_HI:   s_wb_dat_o = USE_GET_TIM     ? WB_DAT_WIDTH'(reg_systim >> WB_DAT_WIDTH) : '0;
        
        default: ;
        endcase
    end
    
    assign  s_wb_ack_o = s_wb_stb_i && !core_busy;
    
    assign monitor_top_tskid   = rdq_top_tskid;
    assign monitor_run_tskid   = run_tskid;
    assign monitor_run_tskpri  = run_tskpri;
    assign monitor_tsk_tskstat = task_tskstat;
    assign monitor_tsk_tskwait = task_tskwait;
    assign monitor_tsk_wupcnt  = task_wupcnt;
    assign monitor_tsk_suscnt  = task_suscnt;
    assign monitor_tsk_timcnt  = task_timcnt;
    assign monitor_sem_quecnt  = semaphore_quecnt;
    assign monitor_sem_semcnt  = semaphore_semcnt;
    assign monitor_flg_flgptn  = flg_flgptn;
    assign monitor_scratch0    = scratch0;
    assign monitor_scratch1    = scratch1;
    assign monitor_scratch2    = scratch2;
    assign monitor_scratch3    = scratch3;

endmodule


`default_nettype wire


// End of file
