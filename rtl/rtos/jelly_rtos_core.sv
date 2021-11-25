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
            parameter   int                         TASKS        = 15,
            parameter   int                         SEMAPHORES   = 4,
            parameter   int                         TSKPRI_WIDTH = 4,
            parameter   int                         SEMCNT_WIDTH = 4,
            parameter   int                         FLGPTN_WIDTH = 4,
            parameter   int                         SYSTIM_WIDTH = 64,
            parameter   int                         RELTIM_WIDTH = 32,
            parameter   int                         TSKID_WIDTH  = $clog2(TASKS),
            parameter   int                         SEMID_WIDTH  = $clog2(SEMAPHORES),
            parameter   int                         QUECNT_WIDTH = $clog2(TASKS+1),

            parameter   bit     [FLGPTN_WIDTH-1:0]  INIT_FLGPTN  = '0
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            output  reg                                         busy,

            // ready queue              
            output  wire    [TSKID_WIDTH-1:0]                   rdq_top_tskid,
            output  wire    [TSKPRI_WIDTH-1:0]                  rdq_top_tskpri,
            output  wire                                        rdq_top_valid,
            output  wire    [QUECNT_WIDTH-1:0]                  rdq_quecnt,

            // operation id
            input   wire    [TSKID_WIDTH-1:0]                   op_tskid,
            input   wire    [SEMID_WIDTH-1:0]                   op_semid,

            // task             
            input   wire                                        wup_tsk_valid,
            input   wire                                        slp_tsk_valid,
            input   wire                                        rel_wai_valid,
            input   wire    [RELTIM_WIDTH-1:0]                  dly_tsk_dlytim,
            input   wire                                        dly_tsk_valid,
            output  wire    [TASKS-1:0][TSKPRI_WIDTH-1:0]       task_tskpri,
            output  wire    [TASKS-1:0][2:0]                    task_tskstat,

            // semaphore                
            input   wire                                        sig_sem_valid,
            input   wire                                        pol_sem_valid,
            output  reg                                         pol_sem_ack,
            input   wire                                        wai_sem_valid,
            output  wire    [SEMAPHORES-1:0][SEMCNT_WIDTH-1:0]  semaphore_semcnt,
            output  wire    [SEMAPHORES-1:0][QUECNT_WIDTH-1:0]  semaphore_quecnt,
            

            // event flag
            input   wire    [FLGPTN_WIDTH-1:0]                  set_flg,
            input   wire    [FLGPTN_WIDTH-1:0]                  clr_flg,
            input   wire    [0:0]                               wai_flg_wfmode,
            input   wire    [FLGPTN_WIDTH-1:0]                  wai_flg_flgptn,
            input   wire                                        wai_flg_valid,
            output  wire    [FLGPTN_WIDTH-1:0]                  flg_flgptn
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
                .QUE_SIZE           (TASKS),
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

                .top_id             (rdq_top_tskid),
                .top_pri            (rdq_top_tskpri),
                .top_valid          (rdq_top_valid),

                .count              (rdq_quecnt)
            );


    // -----------------------------------------
    //  tasks
    // -----------------------------------------
    
    logic   [TASKS-1:0]              task_busy;

    logic   [TASKS-1:0]              task_rdq_add;
    logic   [TASKS-1:0]              task_rdq_rmv;

    logic   [TASKS-1:0]              task_rdy_tsk = '0;
    logic   [TASKS-1:0]              task_rel_tsk = '0;

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

                    .busy               (task_busy[i]),

                    .tskstat            (task_tskstat[i]),
                    .tskpri             (task_tskpri[i]),

                    .rdq_add            (task_rdq_add[i]),
                    .rdq_rmv            (task_rdq_rmv[i]),

                    .rdy_tsk            (task_rdy_tsk[i]),
                    .rel_tsk            (task_rel_tsk[i]),
                    .flgptn             (flg_flgptn),

                    .run_tskid          (rdq_top_tskid),
                    .op_tskid           (op_tskid),
                    .wup_tsk_valid      (wup_tsk_valid),
                    .slp_tsk_valid      (slp_tsk_valid),
                    .dly_tsk_dlytim     (dly_tsk_dlytim),
                    .dly_tsk_valid      (dly_tsk_valid),
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


    logic   [SEMAPHORES-1:0]                        semaphore_pol_sem_ack;
    logic   [SEMAPHORES-1:0][TSKID_WIDTH-1:0]       semaphore_wakeup_tskid;
    logic   [SEMAPHORES-1:0]                        semaphore_wakeup_valid;

    generate
    for ( genvar i = 0; i < SEMAPHORES; ++i ) begin : loop_sem
        jelly_rtos_semaphore
                #(
                    .QUE_SIZE           (TASKS),
                    .TSKID_WIDTH        (TSKID_WIDTH),
                    .TSKPRI_WIDTH       (TSKPRI_WIDTH),
                    .SEMID_WIDTH        (SEMID_WIDTH),
                    .SEMCNT_WIDTH       (SEMCNT_WIDTH),
                    .SEMID              (SEMID_WIDTH'(i)),
                    .INIT_SEMCNT        (0)
                )
            i_rtos_semaphore
                (
                    .reset              (reset),
                    .clk                (clk),
                    .cke                (cke),

                    .op_semid           (op_semid),
                    .op_tskid           (rdq_top_tskid),
                    .op_tskpri          (rdq_top_tskpri),

                    .sig_sem_valid      (sig_sem_valid),
                    .pol_sem_valid      (pol_sem_valid),
                    .pol_sem_ack        (semaphore_pol_sem_ack[i]),
                    .wai_sem_valid      (wai_sem_valid),
                    .rel_wai_valid      (rel_wai_valid),

                    .wakeup_tskid       (semaphore_wakeup_tskid[i]),
                    .wakeup_valid       (semaphore_wakeup_valid[i]),

                    .semcnt             (semaphore_semcnt[i]),
                    .quecnt             (semaphore_quecnt[i])
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
        for ( int tskid = 0; tskid < TASKS; ++tskid ) begin
            if ( task_rdq_add[tskid] ) begin
                rdq_add_tskid  = TSKID_WIDTH'(tskid);
                rdq_add_tskpri = task_tskpri[tskid];
                rdq_add_valid  = 1'b1;
                break;
            end
        end
    end

    // remove from ready queue
    always_comb begin : blk_rdq_rmv
        rdq_rmv_tskid  = '0;
        rdq_rmv_valid  = 1'b0;
        for ( int tskid = 0; tskid < TASKS; ++tskid ) begin
            if ( task_rdq_rmv[tskid] ) begin
                rdq_rmv_tskid = TSKID_WIDTH'(tskid);
                rdq_rmv_valid = 1'b1;
            end
        end
    end

    // task ready
    always_comb begin : blk_task
        task_rdy_tsk = '0;

        // Ready
        if ( rdq_add_valid ) begin
            task_rdy_tsk[rdq_add_tskid] = 1'b1;
        end
    end

    // wake-up from object
    always_comb begin
        automatic logic [TSKID_WIDTH-1:0]   wakeup_tskid;
        automatic logic                     wakeup_valid;
        wakeup_tskid = '0;
        wakeup_valid = '0;

        task_rel_tsk = '0;

        for ( int semid = 0; semid < SEMAPHORES; ++semid ) begin
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
    always_ff @(posedge clk) begin
        if ( reset ) begin
            busy <= '0;
        end
        else if ( cke ) begin
            busy <= |task_busy;
        end
    end

endmodule


`default_nettype wire


// End of file
