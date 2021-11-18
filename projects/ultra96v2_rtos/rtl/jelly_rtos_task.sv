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
            parameter   int                         TSKID_WIDTH  = 4,
            parameter   int                         TSKPRI_WIDTH = 4,
            parameter   int                         SEMID_WIDTH  = 4,
            parameter   int                         EVTFLG_WIDTH = 4,
            parameter   bit     [TSKID_WIDTH-1:0]   TSKID        = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire                        wup_tsk,
            input   wire                        slp_tsk,
            
            output  wire    [TSKPRI_WIDTH-1:0]  tskpri,
            output  reg                         req_rdq,

            input   wire    [EVTFLG_WIDTH-1:0]  event_flag,

            input   wire    [0:0]               wait_event_mode,
            input   wire    [EVTFLG_WIDTH-1:0]  wait_event_flag,
            input   wire                        wait_event_valid,

            // monitoring
            input   wire    [TSKID_WIDTH-1:0]   rdq_add_tskid,
            input   wire                        rdq_add_valid,

            input   wire    [TSKID_WIDTH-1:0]   remove_tskid,
            input   wire                        remove_valid,

            input   wire    [TSKID_WIDTH-1:0]   wakeup_tskid,
            input   wire                        wakeup_valid,

            input   wire    [SEMID_WIDTH-1:0]   sem_wait_semid,
            input   wire    [TSKID_WIDTH-1:0]   sem_wait_tskid,
            input   wire                        sem_wait_valid
        );


    typedef enum {
        TS_IDLE   = 0,
        TS_BUSY   = 4,
        TS_READY  = 1,
        TS_WAISEM = 2,
        TS_WAIFLG = 3
    } task_status_t;


    wire    task_remove = (remove_valid     && (remove_tskid  == TSKID));
    wire    task_ready  = (rdq_add_valid    && (rdq_add_tskid == TSKID));
    wire    task_waisem = (sem_wait_valid   && (rdq_add_tskid == TSKID));
    wire    task_wakeup = (wakeup_valid     && (wakeup_tskid == TSKID));
    wire    task_nop    = (!task_remove && !task_ready && !task_waisem && !task_wakeup);


    task_status_t   status, next_status;

    always_comb begin : blk_status
        next_status = status;

        unique case ( 1'b1 )
        task_remove:    begin   next_status = TS_IDLE;     end
        task_ready:     begin   next_status = TS_READY;    end
        task_waisem:    begin   next_status = TS_WAISEM;   end
        task_wakeup:    begin   next_status = TS_BUSY;     end
        task_nop:       begin   end
        endcase
    end


    always_ff @(posedge clk) begin
        if ( reset ) begin
            status  <= TS_IDLE;
            req_rdq <= 1'b0;
        end
        else if ( cke ) begin
            status  <= next_status;
            req_rdq <= (next_status == TS_BUSY);
        end
    end

endmodule


`default_nettype wire


// End of file
