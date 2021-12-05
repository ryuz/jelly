// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_rtos_core
        #(
            parameter   int                                         TMAX_TSKID   = 15,
            parameter   int                                         TMAX_SEMID   = 7,
            parameter   int                                         TMAX_FLGID   = 7,
            parameter   int                                         TSKPRI_WIDTH = 4,
            parameter   int                                         SEMCNT_WIDTH = 4,
            parameter   int                                         FLGPTN_WIDTH = 4,
            parameter   int                                         PRESCL_WIDTH = 32,
            parameter   int                                         SYSTIM_WIDTH = 64,
            parameter   int                                         RELTIM_WIDTH = 32,
            parameter   int                                         WUPCNT_WIDTH = 1,
            parameter   int                                         SUSCNT_WIDTH = 1,
            parameter   int                                         ER_WIDTH     = 8,
            parameter   int                                         TTS_WIDTH    = 4,
            parameter   int                                         TTW_WIDTH    = 4,
            parameter   bit     [WUPCNT_WIDTH-1:0]                  TMAX_WUPCNT  = '1,
            parameter   bit     [SUSCNT_WIDTH-1:0]                  TMAX_SUSCNT  = '1,
            parameter   bit                                         USE_ER       = 1,
            parameter   bit                                         USE_SET_TMO  = 1,
            parameter   bit                                         USE_CHG_PRI  = 1,
            parameter   bit                                         USE_SLP_TSK  = 1,
            parameter   bit                                         USE_SUS_TSK  = 1,
            parameter   bit                                         USE_DLY_TSK  = 1,
            parameter   bit                                         USE_REL_WAI  = 1,
            parameter   bit                                         USE_SIG_SEM  = 1,
            parameter   bit                                         USE_WAI_SEM  = 1,
            parameter   bit                                         USE_POL_SEM  = 1,
            parameter   bit                                         USE_WAI_FLG  = 1,
            parameter   bit                                         USE_SET_PSCL = 1,
            parameter   bit                                         USE_SET_TIM  = 1,
            parameter   int                                         TSKID_WIDTH  = $clog2(TMAX_TSKID+1),
            parameter   int                                         SEMID_WIDTH  = $clog2(TMAX_SEMID+1),
            parameter   int                                         QUECNT_WIDTH = $clog2(TMAX_TSKID),
            parameter   bit     [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    INIT_FLGPTN  = '0,
            parameter   bit     [PRESCL_WIDTH-1:0]                  INIT_PRESCL  = '0,
            parameter   bit     [SYSTIM_WIDTH-1:0]                  INIT_SYSTIM  = '0
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            output  wire                                        busy,

            // ready queue              
            output  wire    [TSKID_WIDTH-1:0]                   rdq_top_tskid,
            output  wire    [TSKPRI_WIDTH-1:0]                  rdq_top_tskpri,
            output  wire    [QUECNT_WIDTH-1:0]                  rdq_quecnt,

            // run task
            input   wire    [TSKID_WIDTH-1:0]                   run_tskid,
            input   wire    [TSKPRI_WIDTH-1:0]                  run_tskpri,

            // operation id
            input   wire    [TSKID_WIDTH-1:0]                   op_tskid,
            input   wire    [SEMID_WIDTH-1:0]                   op_semid,

            // task
            input   wire    [TSKPRI_WIDTH-1:0]                  chg_pri_tskpri,
            input   wire                                        chg_pri_valid,
            input   wire                                        wup_tsk_valid,
            input   wire                                        slp_tsk_valid,
            input   wire                                        rsm_tsk_valid,
            input   wire                                        sus_tsk_valid,
            input   wire                                        rel_wai_valid,
            input   wire    [RELTIM_WIDTH-1:0]                  dly_tsk_dlytim,
            input   wire                                        dly_tsk_valid,
            input   wire    [RELTIM_WIDTH-1:0]                  set_tmo_tmotim,
            input   wire                                        set_tmo_valid,
            output  wire    [TMAX_TSKID:1][TTS_WIDTH-1:0]       task_tskstat,
            output  wire    [TMAX_TSKID:1][TTW_WIDTH-1:0]       task_tskwait,
            output  wire    [TMAX_TSKID:1][TSKPRI_WIDTH-1:0]    task_tskpri,
            output  wire    [TMAX_TSKID:1][WUPCNT_WIDTH-1:0]    task_wupcnt,
            output  wire    [TMAX_TSKID:1][SUSCNT_WIDTH-1:0]    task_suscnt,
            output  wire    [TMAX_TSKID:1][RELTIM_WIDTH-1:0]    task_timcnt,
            output  wire    [TMAX_TSKID:1][ER_WIDTH-1:0]        task_er,

            // semaphore                
            input   wire                                        sig_sem_valid,
            input   wire                                        pol_sem_valid,
            output  reg                                         pol_sem_ack,
            input   wire                                        wai_sem_valid,
            output  wire    [TMAX_SEMID:1][SEMCNT_WIDTH-1:0]    semaphore_semcnt,
            output  wire    [TMAX_SEMID:1][QUECNT_WIDTH-1:0]    semaphore_quecnt,
            

            // event flag
            input   wire    [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    set_flg,
            input   wire    [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    clr_flg,
            input   wire    [0:0]                               wai_flg_wfmode,
            input   wire    [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    wai_flg_flgptn,
            input   wire                                        wai_flg_valid,
            output  wire    [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    flg_flgptn,

            // timer
            input   wire    [PRESCL_WIDTH-1:0]                  set_pscl_scale,
            input   wire                                        set_pscl_valid,
            input   wire    [SYSTIM_WIDTH-1:0]                  set_tim_systim,
            input   wire                                        set_tim_valid,
            output  wire                                        time_tick,
            output  wire    [SYSTIM_WIDTH-1:0]                  systim
        );


    // -----------------------------------------
    //  timer
    // -----------------------------------------

    jelly2_rtos_timer
            #(
                .SYSTIM_WIDTH       (SYSTIM_WIDTH),
                .PRESCL_WIDTH       (PRESCL_WIDTH),
                .USE_SET_PSCL       (USE_SET_PSCL),
                .USE_SET_TIM        (USE_SET_TIM),
                .INIT_SYSTIM        (INIT_SYSTIM), 
                .INIT_PRESCL        (INIT_PRESCL)
            )
        i_rtos_timer
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),

                .time_tick          (time_tick),
                .systim             (systim),

                .set_pscl_scale     (set_pscl_scale),
                .set_pscl_valid     (set_pscl_valid),

                .set_tim_systim     (set_tim_systim),
                .set_tim_valid      (set_tim_valid)
            );

    logic   [TSKID_WIDTH-1:0]   timeout_tskid;
    logic                       timeout_valid;



    // -----------------------------------------
    //  ready queue
    // -----------------------------------------

    logic   [TSKID_WIDTH-1:0]   rdq_add_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_add_tskpri;
    logic                       rdq_add_valid = '0;

    logic   [TSKID_WIDTH-1:0]   rdq_rmv_tskid;
    logic                       rdq_rmv_valid = '0;

    logic   [TSKID_WIDTH-1:0]   rdq_top_tskid_tmp;
    logic                       rdq_top_valid;
    assign rdq_top_tskid = rdq_top_valid ? rdq_top_tskid_tmp : '0;

    jelly2_rtos_queue_priority
            #(
                .QUE_SIZE           (TMAX_TSKID),
                .ID_WIDTH           (TSKID_WIDTH),
                .PRI_WIDTH          (TSKPRI_WIDTH),
                .COUNT_WIDTH        (QUECNT_WIDTH)
            )       
        i_ready_queue
            (       
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),

                .add_id             (rdq_add_tskid),
                .add_pri            (rdq_add_tskpri),
                .add_valid          (rdq_add_valid),

                .remove_id          (rdq_rmv_tskid),
                .remove_valid       (rdq_rmv_valid),

                .top_id             (rdq_top_tskid_tmp),
                .top_pri            (rdq_top_tskpri),
                .top_valid          (rdq_top_valid),

                .count              (rdq_quecnt)
            );


    // -----------------------------------------
    //  tasks
    // -----------------------------------------
    
    logic   [TMAX_TSKID:1]              task_busy;

    logic   [TMAX_TSKID:1]              task_rdq_add_req;
    logic   [TMAX_TSKID:1]              task_rdq_add_ack;
    logic   [TMAX_TSKID:1]              task_rdq_rmv;
    logic   [TMAX_TSKID:1]              task_timeout_req;
    logic   [TMAX_TSKID:1]              task_timeout_ack;

    logic   [TMAX_TSKID:1]              task_rdy_tsk = '0;
    logic   [TMAX_TSKID:1]              task_rel_tsk = '0;

    generate
    for ( genvar i = 1; i <= TMAX_TSKID; ++i ) begin : loop_tsk
        jelly2_rtos_task
                #(
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEMID_WIDTH        (SEMID_WIDTH),
                    .TMAX_FLGID         (TMAX_FLGID),
                    .FLGPTN_WIDTH       (FLGPTN_WIDTH),
                    .RELTIM_WIDTH       (RELTIM_WIDTH),
                    .WUPCNT_WIDTH       (WUPCNT_WIDTH),
                    .SUSCNT_WIDTH       (SUSCNT_WIDTH),
                    .TTS_WIDTH          (TTS_WIDTH),
                    .TTW_WIDTH          (TTW_WIDTH),
                    .TMAX_WUPCNT        (TMAX_WUPCNT),
                    .TMAX_SUSCNT        (TMAX_SUSCNT),
                    .USE_ER             (USE_ER),
                    .USE_CHG_PRI        (USE_CHG_PRI),
                    .USE_SLP_TSK        (USE_SLP_TSK),
                    .USE_SUS_TSK        (USE_SUS_TSK),
                    .USE_DLY_TSK        (USE_DLY_TSK),
                    .USE_REL_WAI        (USE_REL_WAI),
                    .USE_SET_TMO        (USE_SET_TMO),
                    .USE_WAI_SEM        (USE_WAI_SEM),
                    .USE_WAI_FLG        (USE_WAI_FLG),
                    .TSKID              (TSKID_WIDTH'(i)),
                    .INIT_TSKPRI        (TSKPRI_WIDTH'(i))
                )
            i_rtos_task
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .time_tick          (time_tick),

                    .busy               (task_busy[i]),

                    .tskstat            (task_tskstat[i]),
                    .tskwait            (task_tskwait[i]),
                    .tskpri             (task_tskpri[i]),
                    .wupcnt             (task_wupcnt[i]),
                    .suscnt             (task_suscnt[i]),
                    .timcnt             (task_timcnt[i]),
                    .er                 (task_er[i]),

                    .rdq_add_req        (task_rdq_add_req[i]),
                    .rdq_add_ack        (task_rdq_add_ack[i]),
                    .rdq_rmv            (task_rdq_rmv[i]),
                    .timeout_req        (task_timeout_req[i]),
                    .timeout_ack        (task_timeout_ack[i]),
                    .rel_tsk            (task_rel_tsk[i]),

                    .flgptn             (flg_flgptn),

                    .run_tskid          (rdq_top_tskid),
                    .op_tskid           (op_tskid),
                    .chg_pri_tskpri     (chg_pri_tskpri),
                    .chg_pri_valid      (chg_pri_valid),
                    .wup_tsk_valid      (wup_tsk_valid),
                    .slp_tsk_valid      (slp_tsk_valid),
                    .sus_tsk_valid      (sus_tsk_valid),
                    .rsm_tsk_valid      (rsm_tsk_valid),
                    .dly_tsk_dlytim     (dly_tsk_dlytim),
                    .dly_tsk_valid      (dly_tsk_valid),
                    .set_tmo_tmotim     (set_tmo_tmotim),
                    .set_tmo_valid      (set_tmo_valid),
                    .rel_wai_valid      (rel_wai_valid),
                    .wai_sem_valid      (wai_sem_valid),
                    .wai_flg_wfmode     (wai_flg_wfmode),
                    .wai_flg_flgptn     (wai_flg_flgptn),
                    .wai_flg_valid      (wai_flg_valid)
                );
    end
    endgenerate


    // -----------------------------------------
    //  semaphores
    // -----------------------------------------


    logic   [TMAX_SEMID:1]                      semaphore_pol_sem_ack;
    logic   [TMAX_SEMID:1][TSKID_WIDTH-1:0]     semaphore_wakeup_tskid;
    logic   [TMAX_SEMID:1]                      semaphore_wakeup_valid;

    generate
    for ( genvar i = 1; i <= TMAX_SEMID; ++i ) begin : loop_sem
        jelly2_rtos_semaphore
                #(
                    .QUE_SIZE           (TMAX_TSKID),
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEMID_WIDTH        (SEMID_WIDTH),
                    .SEMCNT_WIDTH       (SEMCNT_WIDTH),
                    .USE_TIMEOUT        (USE_SET_TMO),
                    .USE_SIG_SEM        (USE_SIG_SEM),
                    .USE_WAI_SEM        (USE_WAI_SEM),
                    .USE_POL_SEM        (USE_POL_SEM),
                    .USE_REL_WAI        (USE_REL_WAI),
                    .SEMID              (SEMID_WIDTH'(i)),
                    .INIT_SEMCNT        (0)
                )
            i_rtos_semaphore
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .op_semid           (op_semid),
                    .op_tskid           (run_tskid),
                    .op_tskpri          (run_tskpri),

                    .sig_sem_valid      (sig_sem_valid),
                    .pol_sem_valid      (pol_sem_valid),
                    .pol_sem_ack        (semaphore_pol_sem_ack[i]),
                    .wai_sem_valid      (wai_sem_valid),
                    .rel_wai_valid      (rel_wai_valid),

                    .wakeup_tskid       (semaphore_wakeup_tskid[i]),
                    .wakeup_valid       (semaphore_wakeup_valid[i]),

                    .timeout_tskid      (timeout_tskid),
                    .timeout_valid      (timeout_valid),

                    .semcnt             (semaphore_semcnt[i]),
                    .quecnt             (semaphore_quecnt[i])
                );
    end
    endgenerate


    // -----------------------------------------
    //  Eventflag
    // -----------------------------------------

    jelly2_rtos_eventflag
            #(
                .TMAX_FLGID         (TMAX_FLGID),
                .FLGPTN_WIDTH       (FLGPTN_WIDTH),
                .INIT_FLGPTN        (INIT_FLGPTN)
            )
        i_rtos_eventflag
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),

                .flgptn             (flg_flgptn),

                .set_flg            (set_flg),
                .clr_flg            (clr_flg)
            );

    
    // -----------------------------------------
    //  control
    // -----------------------------------------

    // add to ready queue
    always_comb begin : blk_rdq_add
        rdq_add_tskid  = 'x;
        rdq_add_tskpri = 'x;
        rdq_add_valid  = 1'b0;
        task_rdq_add_ack = '0;
        for ( int tskid = 1; tskid <= TMAX_TSKID; ++tskid ) begin
            if ( task_rdq_add_req[tskid] ) begin
                rdq_add_tskid  = TSKID_WIDTH'(tskid);
                rdq_add_tskpri = task_tskpri[tskid];
                rdq_add_valid  = 1'b1;
                task_rdq_add_ack[tskid] = 1'b1;
                break;
            end
        end
    end

    // remove from ready queue
    always_comb begin : blk_rdq_rmv
        rdq_rmv_tskid  = '0;
        rdq_rmv_valid  = 1'b0;
        for ( int tskid = 1; tskid < TMAX_TSKID; ++tskid ) begin
            if ( task_rdq_rmv[tskid] ) begin
                rdq_rmv_tskid = TSKID_WIDTH'(tskid);
                rdq_rmv_valid = 1'b1;
            end
        end
    end

    // timeout
    always_comb begin : blk_timeout
        timeout_tskid  = 'x;
        timeout_valid  = 1'b0;
        task_timeout_ack = '0;
        for ( int tskid = 1; tskid <= TMAX_TSKID; ++tskid ) begin
            if ( task_timeout_req[tskid] ) begin
                timeout_tskid  = TSKID_WIDTH'(tskid);
                timeout_valid  = 1'b1;
                task_timeout_ack[tskid] = 1'b1;
                break;
            end
        end
    end


    // wake-up from object
    always_comb begin
        automatic logic [TSKID_WIDTH-1:0]   wakeup_tskid;
        automatic logic                     wakeup_valid;
        wakeup_tskid = '0;
        wakeup_valid = '0;

        task_rel_tsk = '0;

        for ( int semid = 1; semid < TMAX_SEMID; ++semid ) begin
            wakeup_tskid |= semaphore_wakeup_tskid[semid];
            wakeup_valid |= semaphore_wakeup_valid[semid];
        end
        if ( wakeup_valid ) begin
            task_rel_tsk[wakeup_tskid] = 1'b1;
        end
    end

    // pol_sem
    assign pol_sem_ack = |semaphore_pol_sem_ack;


    // busy
    assign busy = |task_busy;

endmodule


`default_nettype wire


// End of file
