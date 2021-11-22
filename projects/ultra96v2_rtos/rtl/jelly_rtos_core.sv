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
            parameter   int                         SYSTIM_WIDTH = 64,
            parameter   int                         RELTIM_WIDTH = 32,
            parameter   int                         TSKID_WIDTH  = $clog2(TASKS),
            parameter   int                         SEMID_WIDTH  = $clog2(SEMAPHORES),

            parameter   bit     [FLGPTN_WIDTH-1:0]  INIT_FLGPTN  = '0
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

            input   wire    [TSKID_WIDTH-1:0]   dly_tsk_tskid,
            input   wire    [RELTIM_WIDTH-1:0]  dly_tsk_dlytim,
            input   wire                        dly_tsk_valid,


            // semaphore
            input   wire    [SEMID_WIDTH-1:0]   wai_sem_semid,
            input   wire                        wai_sem_valid,

            input   wire    [SEMID_WIDTH-1:0]   sig_sem_semid,
            input   wire                        sig_sem_valid,
            
            // event flag
            input   wire    [FLGPTN_WIDTH-1:0]  set_flg,
            
            input   wire    [FLGPTN_WIDTH-1:0]  clr_flg,

            input   wire    [0:0]               wai_flg_wfmode,
            input   wire    [FLGPTN_WIDTH-1:0]  wai_flg_flgptn,
            input   wire                        wai_flg_valid,
            
            output  wire    [FLGPTN_WIDTH-1:0]  evtflg_flgptn
        );


    // -----------------------------------------
    //  ready queue
    // -----------------------------------------

    logic   [TSKID_WIDTH-1:0]   rdq_add_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_add_tskpri;
    logic                       rdq_add_valid = '0;

    logic   [TSKID_WIDTH-1:0]   rdq_rmv_tskid;
    logic                       rdq_rmv_valid = '0;

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
    
    (* mark_debug="true" *) logic   [TASKS-1:0][2:0]                task_tskstat;
    (* mark_debug="true" *) logic   [TASKS-1:0][TSKPRI_WIDTH-1:0]   task_tskpri;

    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_req_rdy;

    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_rel_tsk;

    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_rdy_tsk;
    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_wup_tsk;
    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_slp_tsk;
    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_rel_wai;

    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_dly_tsk;
                            logic   [RELTIM_WIDTH-1:0]              task_dly_tsk_dlytim;

    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_wai_sem;
    (* mark_debug="true" *) logic   [TASKS-1:0]                     task_wai_flg;

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

                    .tskstat            (task_tskstat[i]),
                    .tskpri             (task_tskpri[i]),
                    
                    .req_rdq            (task_req_rdy[i]),

                    .rel_tsk            (task_rel_tsk[i]),

                    .rdy_tsk            (task_rdy_tsk[i]),
                    .wup_tsk            (task_wup_tsk[i]),
                    .slp_tsk            (task_slp_tsk[i]),
                    .rel_wai            (task_rel_wai[i]),

                    .dly_tsk            (task_dly_tsk[i]),
                    .dly_tsk_dlytim     (task_dly_tsk_dlytim),

                    .wai_sem            (task_wai_sem[i]),

                    .evtflg_flgptn      (evtflg_flgptn),
                    .wai_flg_wfmode     (wai_flg_wfmode),
                    .wai_flg_flgptn     (wai_flg_flgptn),
                    .wai_flg            (task_wai_flg[i])
                );
    end
    endgenerate


    // -----------------------------------------
    //  semaphores
    // -----------------------------------------

    logic   [SEMAPHORES-1:0]                        semaphore_sig_sem_valid;

    logic   [TSKID_WIDTH-1:0]                       semaphore_wai_sem_tskid;
    logic   [TSKPRI_WIDTH-1:0]                      semaphore_wai_sem_tskpri;
    logic   [SEMAPHORES-1:0]                        semaphore_wai_sem_valid;

    logic   [SEMAPHORES-1:0][TSKID_WIDTH-1:0]       semaphore_wakeup_tskid;
    logic   [SEMAPHORES-1:0]                        semaphore_wakeup_valid;

    logic   [SEMAPHORES-1:0][SEMCNT_WIDTH-1:0]      semaphore_semcnt;

    generate
    for ( genvar i = 0; i < SEMAPHORES; ++i ) begin : loop_sem
        jelly_rtos_semaphore
                #(
                    .QUE_SIZE           (TASKS),
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEMCNT_WIDTH       (SEMCNT_WIDTH),
                    .INIT_SEMCNT        (0)
                )
            i_rtos_semaphore
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .sig_sem            (semaphore_sig_sem_valid[i]),

                    .wai_sem_tskid      (semaphore_wai_sem_tskid),
                    .wai_sem_tskpri     (semaphore_wai_sem_tskpri),
                    .wai_sem_valid      (semaphore_wai_sem_valid[i]),

                    .rel_wai_tskid      (rel_wai_tskid),
                    .rel_wai_valid      (rel_wai_valid),

                    .wakeup_tskid       (semaphore_wakeup_tskid[i]),
                    .wakeup_valid       (semaphore_wakeup_valid[i]),

                    .semcnt             (semaphore_semcnt[i]),
                    .quecnt             ()
                );
    end
    endgenerate


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

        task_rdy_tsk = '0;
        task_wup_tsk = '0;
        task_slp_tsk = '0;
        task_rel_wai = '0;
        task_wai_sem = '0;
        task_wai_flg = '0;

        task_dly_tsk        = '0;
        task_dly_tsk_dlytim = 'x;

        semaphore_sig_sem_valid  = '0;
        semaphore_wai_sem_tskid  = 'x;
        semaphore_wai_sem_tskpri = 'x;
        semaphore_wai_sem_valid  = '0;

        // レディーキュー登録要求処理
        for ( int tskid = 0; tskid < TASKS; ++tskid ) begin
            if ( task_req_rdy[tskid] ) begin
                rdq_add_tskid  = TSKID_WIDTH'(tskid);
                rdq_add_tskpri = task_tskpri[tskid];
                rdq_add_valid  = 1'b1;
                break;
            end
        end

        // wup_tsk
        if ( wup_tsk_valid ) begin
            task_wup_tsk[wup_tsk_tskid] = 1'b1;
        end

        // slp_tsk
        if ( slp_tsk_valid ) begin
            task_slp_tsk[slp_tsk_tskid] = 1'b1;
            rdq_rmv_tskid = slp_tsk_tskid;
            rdq_rmv_valid = 1'b1;
        end

        // dly_tsk
        if ( dly_tsk_valid ) begin
            task_dly_tsk[dly_tsk_tskid] = 1'b1;
            task_dly_tsk_dlytim         = dly_tsk_dlytim;
        end

        // sig_sem
        if ( sig_sem_valid ) begin
            semaphore_sig_sem_valid[sig_sem_semid] = 1'b1;
        end

        // wait for semsphore
        if ( wai_sem_valid ) begin
            task_wai_sem[rdq_top_tskid] = 1'b1;
            semaphore_wai_sem_tskid  = rdq_top_tskid;
            semaphore_wai_sem_tskpri = rdq_top_tskpri;
            semaphore_wai_sem_valid[wai_sem_semid] = 1'b1;
            rdq_rmv_tskid = rdq_top_tskid;
            rdq_rmv_valid = 1'b1;
        end


        // wait for event-flag
        if ( wai_flg_valid ) begin
            task_wai_flg[rdq_top_tskid] = 1'b1;
            rdq_rmv_tskid = rdq_top_tskid;
            rdq_rmv_valid = 1'b1;
        end


        // Ready
        if ( rdq_add_valid ) begin
            task_rdy_tsk[rdq_add_tskid] = 1'b1;
        end

        // Release Wait
        if ( rel_wai_valid ) begin
            task_rel_wai[rel_wai_tskid] = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            task_rel_tsk <= '0;
        end
        else if ( cke ) begin
            automatic logic [TSKID_WIDTH-1:0]   wakeup_tskid;
            automatic logic                     wakeup_valid;

            task_rel_tsk <= '0;

            wakeup_tskid = '0;
            wakeup_valid = '0;
            for ( int semid = 0; semid < SEMAPHORES; ++semid ) begin
                wakeup_tskid |= semaphore_wakeup_tskid[semid];
                wakeup_valid |= semaphore_wakeup_valid[semid];
            end
            if ( wakeup_valid ) begin
                task_rel_tsk[wakeup_tskid] <= 1'b1;
            end
        end
    end

endmodule


`default_nettype wire


// End of file
