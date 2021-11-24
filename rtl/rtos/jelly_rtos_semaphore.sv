// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos_semaphore
        #(
            parameter int                           QUE_SIZE        = 16,
            parameter int                           QUECNT_WIDTH    = $clog2(QUE_SIZE+1),
            parameter int                           TSKID_WIDTH     = 4,
            parameter int                           TSKPRI_WIDTH    = 4,
            parameter int                           SEMID_WIDTH     = 4,
            parameter int                           SEMCNT_WIDTH    = 4,
            parameter bit                           PRIORITY_ORDER  = 1'b0,
            parameter bit   [SEMID_WIDTH-1:0]       SEMID           = '0,
            parameter bit   [SEMCNT_WIDTH-1:0]      INIT_SEMCNT     = '0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            input   wire    [SEMID_WIDTH-1:0]       op_semid,
            input   wire    [TSKID_WIDTH-1:0]       op_tskid,
            input   wire    [TSKPRI_WIDTH-1:0]      op_tskpri,

            input   wire                            sig_sem_valid,
            input   wire                            pol_sem_valid,
            output  reg                             pol_sem_ack,
            input   wire                            wai_sem_valid,
            input   wire                            rel_wai_valid,

            output  reg     [TSKID_WIDTH-1:0]       wakeup_tskid,
            output  reg                             wakeup_valid,

            output  reg     [SEMCNT_WIDTH-1:0]      semcnt,
            output  wire    [QUECNT_WIDTH-1:0]      quecnt
        );

    // wait queue
    logic   [TSKID_WIDTH-1:0]   que_add_tskid;
    logic   [TSKPRI_WIDTH-1:0]  que_add_tskpri;
    logic                       que_add_valid;

    logic   [TSKID_WIDTH-1:0]   que_rmv_tskid;
    logic                       que_rmv_valid;

    logic   [TSKID_WIDTH-1:0]   que_top_tskid;
    logic                       que_top_valid;

    jelly_rtos_queue
            #(
                .PRIORITY_ORDER (PRIORITY_ORDER),
                .QUE_SIZE       (QUE_SIZE),
                .ID_WIDTH       (TSKID_WIDTH),
                .PRI_WIDTH      (TSKPRI_WIDTH),
                .COUNT_WIDTH    (QUECNT_WIDTH)
            )
        i_rtos_queue
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),

                .add_id         (que_add_tskid),
                .add_pri        (que_add_tskpri),
                .add_valid      (que_add_valid),

                .remove_id      (que_rmv_tskid),
                .remove_valid   (que_rmv_valid),

                .top_id         (que_top_tskid),
                .top_valid      (que_top_valid),

                .count          (quecnt)
            );

    logic                       id_valid;
    assign id_valid = (op_semid == SEMID);
    
    logic   [SEMCNT_WIDTH-1:0]  next_semcnt;
    logic                       sem_empty;

    always_comb begin : blk_sem
        next_semcnt    = semcnt;
        que_add_tskid  = 'x;
        que_add_tskpri = 'x;
        que_add_valid  = 1'b0;
        que_rmv_tskid  = 'x;
        que_rmv_valid  = 1'b0;
        wakeup_tskid   = '0;
        wakeup_valid   = 1'b0;

        if ( id_valid ) begin
            case ( 1'b1 )
            sig_sem_valid:
                begin
                    if ( que_top_valid ) begin
                        // キューにあれば取り出す
                        que_rmv_tskid = que_top_tskid;
                        que_rmv_valid = 1'b1;

                        wakeup_tskid = que_top_tskid;
                        wakeup_valid = 1'b1;
                    end
                    else begin
                        next_semcnt++;
                    end
                end

            pol_sem_valid:
                begin
                    if ( !sem_empty ) begin
                        next_semcnt--;
                    end
                end

            wai_sem_valid:
                begin
                    if ( sem_empty ) begin
                        que_add_tskid  = op_tskid;
                        que_add_tskpri = op_tskpri;
                        que_add_valid  = 1'b1;
                    end
                    else begin
                        next_semcnt--;
                        wakeup_tskid = op_tskid;
                        wakeup_valid = 1'b1;
                    end
                end
            
            rel_wai_valid:
                begin
                    que_rmv_tskid = op_tskid;
                    que_rmv_valid = 1'b1;
                end
            
            default: ;
            endcase
        end
    end

    assign pol_sem_ack = id_valid && pol_sem_valid && !sem_empty;


    always_ff @(posedge clk) begin
        if ( reset ) begin
            semcnt    <= INIT_SEMCNT;
            sem_empty <= (INIT_SEMCNT == '0);
        end
        else if ( cke ) begin
            semcnt    <= next_semcnt;
            sem_empty <= (next_semcnt == '0);
        end
    end

endmodule


`default_nettype wire


// End of file
