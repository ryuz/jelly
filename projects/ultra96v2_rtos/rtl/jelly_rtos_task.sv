// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos_task
        #(
            parameter   int                 TSKID_WIDTH  = 4,
            parameter   int                 SEMID_WIDTH  = 4,
            parameter   int                 FLGID_WIDTH  = 4,
            parameter   int                 TSKPRI_WIDTH = 4,
            parameter   bit [ID_WIDTH-1:0]  TSKID        = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire                        activate,
            input   wire                        sleep,
            
            output  wire                        tsk_pri,
            output  wire                        req_ready,

            // monitoring
            input   wire    [0:0]               rdq_ctl_op,  // 0: add, 1: del
            input   wire    [TSKID_WIDTH-1:0]   rdq_ctl_tskid,
            input   wire                        rdq_ctl_valid

            input   wire    [0:0]               sem_ctl_op,
            input   wire    [SEMID_WIDTH-1:0]   sem_ctl_semid,
            input   wire    [TSKID_WIDTH-1:0]   sem_ctl_tskid,
            input   wire                        sem_ctl_valid,
            input   wire    [TSKID_WIDTH-1:0]   sem_wakeup_tskid,
            input   wire                        sem_wakeup_valid,

            input   wire    [0:0]               sem_ctl_op,
            input   wire    [SEMID_WIDTH-1:0]   sem_ctl_semid,
            input   wire    [TSKID_WIDTH-1:0]   sem_ctl_tskid,
            input   wire                        sem_ctl_valid,
            input   wire    [TSKID_WIDTH-1:0]   sem_wakeup_tskid,
            input   wire                        sem_wakeup_valid,

        );

    enum {
        TS_IDLE,
        TS_BUSY,
        TS_READY,
        TS_WAISEM,
        TS_WAIFLG
    }

    wire    rdq_push   = rdq_valid && rdq_op == 1'b0 && (rdq_tskid == TSKID);
    wire    rdq_pop    = rdq_valid && rdq_op == 1'b1 && (rdq_tskid == TSKID);
    wire    sem_wait   = flg_wait_valid   && (sem_wait_tskid   == TSKID);
    wire    sem_wakeup = flg_wakeup_valid && (sem_wakeup_tskid == TSKID);
    wire    flg_wait   = flg_wait_valid   && (flg_wait_tskid   == TSKID);
    wire    flg_wakeup = flg_wakeup_valid && (flg_wait_tskid   == TSKID);

    always_ff @(posedge clk) begin
        if ( reset ) begin
            status <= TS_IDLE;
        end
        else if ( cke ) begin
            if ( rdq_valid && rdq_id == id ) begin
                if ( rdq_op == 1'b0 ) begin
                    status <= TS_READY;
                end
                if ( rdq_op == 1'b1 ) begin
                    status <= TS_WAIT;
                end
            end



        end
    end

endmodule


`default_nettype wire


// End of file
