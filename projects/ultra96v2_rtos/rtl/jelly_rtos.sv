// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos
        #(
            parameter int   TASKS        = 16,
            parameter int   SEMAPHORES   = 16,
            parameter int   EVENTFLAGS   = 16,
            parameter int   TSKPRI_WIDTH = 4,
            parameter int   SEMCNT_WIDTH = 4,
            parameter int   EVTFLG_WIDTH = 4,
            parameter int   SYSTIM_WIDTH = 64,
            parameter int   RELTIM_WIDTH = 32,

            parameter int   TSKID_WIDTH  = $clog2(TASKS),
            parameter int   SEMID_WIDTH  = $clog2(SEMAPHORES),
            parameter int   FLGID_WIDTH  = $clog2(EVENTFLAGS),

            parameter int   WB_ADR_WIDTH = 16,
            parameter int   WB_DAT_WIDTH = 32,
            parameter int   WB_SEL_WIDTH = WB_DAT_WIDTH/8
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,

            output  wire                        irq
        );


    // -----------------------------------------
    //  ready queue
    // -----------------------------------------

    logic   [0:0]               rdq_op;  // 0: add, 1: del
    logic   [TSKID_WIDTH-1:0]   rdq_tskid;
    logic   [TSKPRI_WIDTH-1:0]  rdq_tskpri;
    logic                       rdq_valid;

    logic   [TSKID_WIDTH-1:0]   top_id;
    logic   [TSKPRI_WIDTH-1:0]  top_pri;
    logic                       top_valid;

    jelly_priority_queue
            #(
                .N              (TASKS),
                .ID_WIDTH       (TSKID_WIDTH),
                .PRI_WIDTH      (TSKPRI_WIDTH),
                .N_WIDTH        (TSKID_WIDTH)
            )   
        i_ready_queue   
            (   
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),

                .in_op          (rdq_op),    // 0: add, 1: del
                .in_id          (rdq_tskid),
                .in_pri         (rdq_tskpri),
                .in_valid       (in_valid),

                .top_id         (top_id),
                .top_pri        (top_pri),
                .top_valid      (top_valid),

                .size           ()
            );


    // -----------------------------------------
    //  semaphores
    // -----------------------------------------

    logic   [SEMAPHORES-1:0][ID_WIDTH-1:0]      sem_wait_id;
    logic   [SEMAPHORES-1:0][PRI_WIDTH-1:0]     sem_wait_pri;
    logic                                       sem_wait_valid;

    logic   [SEMAPHORES-1:0][ID_WIDTH-1:0]      sem_wakeup_id;
    logic                                       sem_wakeup_valid;

    logic   [SEMAPHORES-1:0][COUNTER_WIDTH-1:0] sem_counter;
    logic   [SEMAPHORES-1:0][N_WIDTH-1:0]       sem_que_siz;

    logic   [SEMAPHORES-1:0][WB_DAT_WIDTH-1:0]  wb_sem_dat_o;
    logic   [SEMAPHORES-1:0]                    wb_sem_stb_i;
    logic   [SEMAPHORES-1:0]                    wb_sem_ack_o;

    generate
    for ( genvar i = 0; i < SEMAPHORES; ++i ) begin : loop_sem
        jelly_semaphore
                #(
                    .N              (TASKS),
                    .N_WIDTH        (TSKID_WIDTH),
                    .ID_WIDTH       (TSKID_WIDTH),
                    .PRI_WIDTH      (TSKPRI_WIDTH),
                    .COUNTER_WIDTH  (SEMCNT_WIDTH),
                    .INIT_COUNTER   (0)
                )
            i_semaphore
                (
                    .reset          (reset),
                    .clk            (clk),
                    .cke            (cke),

                    .signal         (sem_signal      [i]),

                    .wait_id        (sem_wait_id     [i]),
                    .wait_pri       (sem_wait_pri    [i]),
                    .wait_valid     (sem_wait_valid  [i]),

                    .wakeup_id      (sem_wakeup_id   [i]),
                    .wakeup_valid   (sem_wakeup_valid[i]),

                    .counter        (sem_counter     [i]),
                    .que_size       (sem_que_size    [i])
                );
    end
    endgenerate

    
    // -----------------------------------------
    //  Wishbone
    // -----------------------------------------



endmodule


`default_nettype wire


// End of file
