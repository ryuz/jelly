// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_rtos_core
        #(
            parameter   int                         TASKS        = 16,
            parameter   int                         SEMAPHORES   = 4,
            parameter   int                         TSKPRI_WIDTH = 4,
            parameter   int                         SEMCNT_WIDTH = 4,
            parameter   int                         FLGPTN_WIDTH = 4,
//            parameter int                         SYSTIM_WIDTH = 64,
//            parameter int                         RELTIM_WIDTH = 32,

            parameter   bit     [FLGPTN_WIDTH-1:0]  INIT_FLGPTN  = '0,

            parameter   int                         TSKID_WIDTH  = $clog2(TASKS),
            parameter   int                         SEMID_WIDTH  = $clog2(SEMAPHORES)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            // ready queue
            output  wire    [TSKID_WIDTH-1:0]   rdq_top_tskid,
            output  wire    [TSKPRI_WIDTH-1:0]  rdq_top_tskpri,
            output  wire                        rdq_top_valid,

            // task
            input   wire    [TSKID_WIDTH-1:0]   wup_tsk_tskid,
            input   wire                        wup_tsk_valid,

            input   wire    [TSKID_WIDTH-1:0]   slp_tsk_tskid,
            input   wire                        slp_tsk_valid,

            input   wire    [TSKID_WIDTH-1:0]   rel_wai_tskid,
            input   wire                        rel_wai_valid,

            // event flag
            input   wire    [FLGPTN_WIDTH-1:0]  set_flg,
            
            input   wire    [FLGPTN_WIDTH-1:0]  clr_flg,

            input   wire    [TSKID_WIDTH-1:0]   wai_flg_tskid,
            input   wire    [0:0]               wai_flg_wfmode,
            input   wire    [FLGPTN_WIDTH-1:0]  wai_flg_flgptn,
            input   wire                        wai_flg_valid,
            output  wire    [FLGPTN_WIDTH-1:0]  evtflg_flgptn,
            
            // semaphore
            input   wire    [SEMAPHORES-1:0]    wai_sem,
            input   wire    [SEMAPHORES-1:0]    sig_sem
        );


    // -----------------------------------------
    //  ready queue
    // -----------------------------------------

    logic   [TSKID_WIDTH-1:0]   rdq_add_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_add_tskpri;
    logic                       rdq_add_valid;

    logic   [TSKID_WIDTH-1:0]   rdq_rmv_tskid;
    logic                       rdq_rmv_valid;

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

                .remove_id      (rdq_rmv_tskid),
                .remove_valid   (rdq_rmv_valid),
                
                .top_id         (rdq_top_tskid),
                .top_pri        (rdq_top_tskpri),
                .top_valid      (rdq_top_valid),

                .count          ()
            );



    // -----------------------------------------
    //  tasks
    // -----------------------------------------
    
    logic   [TASKS-1:0][TSKPRI_WIDTH-1:0]   tsk_tskpri;
    logic   [TASKS-1:0]                     tsk_reqrdy;

    logic   [TASKS-1:0]                     rdy_tsk;
    logic   [TASKS-1:0]                     wup_tsk;
    logic   [TASKS-1:0]                     slp_tsk;
    logic   [TASKS-1:0]                     rel_wai;

    logic   [TASKS-1:0]                     wai_flg;

    generate
    for ( genvar i = 0; i < TASKS; ++i ) begin : loop_tsk
        jelly_rtos_task
                #(
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEMID_WIDTH        (SEMID_WIDTH),
                    .FLGPTN_WIDTH       (FLGPTN_WIDTH),
                    .TSKID              (TSKID_WIDTH'(i))
                )
            i_rtos_task
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .rdy_tsk            (rdy_tsk[i]),
                    .wup_tsk            (wup_tsk[i]),
                    .slp_tsk            (slp_tsk[i]),
                    .rel_wai            (rel_wai[i]),

                    .tskpri             (tsk_tskpri[i]),
                    .req_rdq            (tsk_reqrdy[i]),

                    .evtflg_flgptn      (evtflg_flgptn),
                    .wai_flg_wfmode     (wai_flg_wfmode),
                    .wai_flg_flgptn     (wai_flg_flgptn),
                    .wai_flg            (wai_flg[i])

                    // monitor
//                    .rdq_add_tskid      (rdq_add_tskid),
//                    .rdq_add_valid      (rdq_add_valid),

//                    .rdq_rmv_tskid      (rdq_rmv_tskid),
//                    .rdq_rmv_valid      (rdq_rmv_valid)
                    
//                  .relwai_tskid       (relwai_tskid),
//                  .relwai_valid       (relwai_valid),

//                    .sem_wait_semid     (),
//                    .sem_wait_tskid     (),
//                    .sem_wait_valid     (1'b0)
                );
    end
    endgenerate


    // -----------------------------------------
    //  semaphores
    // -----------------------------------------

    /*
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
//                    .wakeup_valid       (sem_wakeup_valid),

                    .sem_count          (sem_count       [i]),
                    .que_count          ()
                );
    end
    endgenerate
    */


    // -----------------------------------------
    //  Eventflag
    // -----------------------------------------

    jelly_rtos_eventflag
            #(
                .FLGPTN_WIDTH       (FLGPTN_WIDTH),
                .INIT_FLGPTN        (INIT_FLGPTN)
            )
        i_rtos_eventflag
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),

                .flgptn             (evtflg_flgptn),

                .set_flg            (set_flg),
                .clr_flg            (clr_flg)
            );

    
    // -----------------------------------------
    //  control
    // -----------------------------------------

    always_comb begin : blk_core
        rdq_add_tskid  = 'x;
        rdq_add_tskpri = 'x;
        rdq_add_valid  = 1'b0;

        rdq_rmv_tskid = 'x;
        rdq_rmv_valid = 1'b0;

        rdy_tsk = '0;
        wup_tsk = '0;
        slp_tsk = '0;

        // レディーキュー登録要求処理
        for ( int tskid = 0; tskid < TASKS; ++tskid ) begin
            if ( tsk_reqrdy[tskid] ) begin
                rdq_add_tskid  = TSKID_WIDTH'(tskid);
                rdq_add_tskpri = tsk_tskpri[tskid];
                rdq_add_valid  = 1'b1;
                break;
            end
        end

        /*
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
        */

        // Wake-up Task
        if ( wup_tsk_valid ) begin
            wup_tsk[wup_tsk_tskid] = 1'b1;
        end

        // Task Sleep
        if ( slp_tsk_valid ) begin
            slp_tsk[slp_tsk_tskid] = 1'b1;

            // レディーキューにタスクがあれば削除
            rdq_rmv_tskid = slp_tsk_tskid;
            rdq_rmv_valid = 1'b1;
        end

        if ( rdq_add_valid ) begin
            rdy_tsk[rdq_add_tskid] = 1'b1;
        end

        if ( rel_wai_valid ) begin
            rel_wai[rel_wai_tskid] = 1'b1;
        end
    end


endmodule


`default_nettype wire


// End of file
