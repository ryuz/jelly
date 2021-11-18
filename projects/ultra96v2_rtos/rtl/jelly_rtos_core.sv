// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none

//            parameter int   SYSTIM_WIDTH = 64,
//            parameter int   RELTIM_WIDTH = 32,


module jelly_rtos_core
        #(
            parameter int   TASKS        = 16,
            parameter int   SEMAPHORES   = 4,
            parameter int   TSKPRI_WIDTH = 4,
            parameter int   SEMCNT_WIDTH = 4,
            parameter int   EVTFLG_WIDTH = 4,

            parameter int   TSKID_WIDTH  = $clog2(TASKS),
            parameter int   SEMID_WIDTH  = $clog2(SEMAPHORES)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire    [TASKS-1:0]         wup_tsk,
            input   wire    [TSKID_WIDTH-1:0]   slp_tsk_tskid,
            input   wire                        slp_tsk_valid,
            
            input   wire    [SEMAPHORES-1:0]    wai_sem,
            input   wire    [SEMAPHORES-1:0]    sig_sem,

            input   wire    [TASKS-1:0]         wai_flg,
            input   wire    [0:0]               wai_flgmode,
            input   wire    [EVTFLG_WIDTH-1:0]  wai_flgptn,

            input   wire    [EVTFLG_WIDTH-1:0]  set_flg,
            input   wire    [EVTFLG_WIDTH-1:0]  clr_flg,

            output  wire    [TSKID_WIDTH-1:0]   runtsk_tskid,
            output  wire                        runtsk_valid
        );


    // -----------------------------------------
    //  ready queue
    // -----------------------------------------

    logic   [TSKID_WIDTH-1:0]   remove_tskid;
    logic                       remove_valid;

    logic   [TSKID_WIDTH-1:0]   rdq_add_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_add_tskpri;
    logic                       rdq_add_valid;

    logic   [TSKID_WIDTH-1:0]   rdq_top_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_top_tskpri;
    logic                       rdq_top_valid;

    logic   [TSKID_WIDTH-1:0]   rdq_remove_tskid;
    logic                       rdq_remove_valid;

    jelly_rtos_queue_priority
            #(
                .QUE_SIZE       (TASKS),
                .ID_WIDTH       (TSKID_WIDTH),
                .PRI_WIDTH      (TSKPRI_WIDTH),
                .COUNT_WIDTH    (TSKID_WIDTH)
            )   
        i_ready_queue   
            (   
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),

                .add_id         (rdq_add_tskid),
                .add_pri        (rdq_add_tskpri),
                .add_valid      (rdq_add_valid),

                .remove_id      (rdq_add_tskid),
                .remove_valid   (rdq_add_valid),

                .top_id         (rdq_top_tskid),
                .top_pri        (rdq_top_tskpri),
                .top_valid      (rdq_top_valid),

                .count          ()
            );

    assign runtsk_tskid = rdq_top_tskid;
    assign runtsk_valid = rdq_top_valid;


    // -----------------------------------------
    //  tasks
    // -----------------------------------------
    
    logic   [TASKS-1:0][TSKPRI_WIDTH-1:0]   tsk_tskpri;
    logic   [TASKS-1:0]                     tsk_reqrdy;

    logic   [TSKID_WIDTH-1:0]               wakeup_tskid;
    logic                                   wakeup_valid;

    logic   [EVTFLG_WIDTH-1:0]              event_flag;

    generate
    for ( genvar i = 0; i < TASKS; ++i ) begin : loop_tsk
        jelly_rtos_task
                #(
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEMID_WIDTH        (SEMID_WIDTH),
                    .EVTFLG_WIDTH       (EVTFLG_WIDTH),
                    .TSKID              (TSKID_WIDTH'(i))
                )
            i_rtos_task
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .wup_tsk            (wup_tsk[i]),
                    .slp_tsk            (slp_tsk_valid && (slp_tsk_tskid == TSKID_WIDTH'(i))),

                    .tskpri             (tsk_tskpri[i]),
                    .req_rdq            (tsk_reqrdy[i]),

                    .event_flag         (event_flag),

                    .wait_event_mode    (),
                    .wait_event_flag    (),
                    .wait_event_valid   (1'b0),

                    .rdq_add_tskid      (rdq_add_tskid),
                    .rdq_add_valid      (rdq_add_valid),

                    .remove_tskid       (rdq_remove_tskid),
                    .remove_valid       (rdq_remove_valid),

                    .wakeup_tskid       (wakeup_tskid),
                    .wakeup_valid       (wakeup_valid),

                    .sem_wait_semid     (),
                    .sem_wait_tskid     (),
                    .sem_wait_valid     (1'b0)
                );
    end
    endgenerate


    // -----------------------------------------
    //  semaphores
    // -----------------------------------------

    logic   [TSKID_WIDTH-1:0]                       sem_wait_tskid;
    logic   [TSKPRI_WIDTH-1:0]                      sem_wait_tskpri;
    logic   [SEMAPHORES-1:0]                        sem_wait_valid;

    logic   [SEMAPHORES-1:0][TSKID_WIDTH-1:0]       sem_wakeup_tskid;
    logic                                           sem_wakeup_valid;

    logic   [SEMAPHORES-1:0][SEMCNT_WIDTH-1:0]      sem_count;

    generate
    for ( genvar i = 0; i < SEMAPHORES; ++i ) begin : loop_sem
        jelly_rtos_semaphore
                #(
                    .QUE_SIZE           (TASKS),
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEM_COUNT_WIDTH    (SEMCNT_WIDTH),
                    .INIT_SEM_COUNT     (0)
                )
            i_rtos_semaphore
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .signal             (sig_sem         [i]),

                    .wait_tskid         (sem_wait_tskid),
                    .wait_tskpri        (sem_wait_tskpri),
                    .wait_valid         (sem_wait_valid  [i]),

                    .remove_tskid       (remove_tskid),
                    .remove_valid       (remove_valid),

                    .wakeup_tskid       (sem_wakeup_tskid[i]),
                    .wakeup_valid       (sem_wakeup_valid),

                    .sem_count          (sem_count       [i]),
                    .que_count          ()
                );
    end
    endgenerate

    
    // -----------------------------------------
    //  control
    // -----------------------------------------

    always_comb begin : blk_core
        rdq_remove_tskid = 'x;
        rdq_remove_valid = 1'b0;
        
        rdq_add_tskid  = 'x;
        rdq_add_tskpri = 'x;
        rdq_add_valid  = 1'b0;
        for ( int tskid = 0; tskid < TASKS; ++tskid ) begin
            if ( tsk_reqrdy[tskid] ) begin
                rdq_add_tskid  = TSKID_WIDTH'(tskid);
                rdq_add_tskpri = tsk_tskpri[tskid];
                rdq_add_valid  = 1'b1;
                break;
            end
        end

        // Wake-Up
        wakeup_tskid  = '0;
        wakeup_valid  = 1'b0;
        for ( int semid = 0; semid < SEMAPHORES; ++semid ) begin
            wakeup_tskid |= sem_wakeup_tskid[semid];
            wakeup_valid |= sem_wakeup_valid;
        end

        // Semaphore
        sem_wait_tskid   = rdq_top_tskid;
        sem_wait_tskpri  = rdq_top_tskpri;
        sem_wait_valid   = wai_sem;
        if ( |sem_wait_valid ) begin
            // 起床要求マスク
            rdq_add_valid    = 1'b0;

            // レディーキューにタスクがあれば削除
            rdq_remove_tskid = rdq_top_tskid;
            rdq_remove_valid = 1'b1;
        end

        // Task Sleep
        if ( slp_tsk_valid ) begin
            // レディーキューにタスクがあれば削除
            rdq_remove_tskid = slp_tsk_tskid;
            rdq_remove_valid = 1'b1;
        end
    end

endmodule


`default_nettype wire


// End of file
