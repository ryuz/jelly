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
            parameter int                           SEMCNT_WIDTH    = 4,
            parameter bit                           PRIORITY_ORDER  = 1'b0,
            parameter bit   [SEMCNT_WIDTH-1:0]      INIT_SEMCNT     = '0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            input   wire                            sig_sem,

            input   wire    [TSKID_WIDTH-1:0]       wai_sem_tskid,
            input   wire    [TSKPRI_WIDTH-1:0]      wai_sem_tskpri,
            input   wire                            wai_sem_valid,

            input   wire    [TSKID_WIDTH-1:0]       rel_wai_tskid,
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

                .add_id         (wai_sem_tskid),
                .add_pri        (wai_sem_tskpri),
                .add_valid      (wai_sem_valid),

                .remove_id      (que_rmv_tskid),
                .remove_valid   (que_rmv_valid),

                .top_id         (que_top_tskid),
                .top_valid      (que_top_valid),

                .count          (quecnt)
            );
    

    
    logic   [SEMCNT_WIDTH-1:0]  next_semcnt;
    logic                       sem_empty;
    logic                       sem_nop;

    always_comb begin : blk_sem
        next_semcnt    = semcnt;
        que_add_tskid  = 'x;
        que_add_tskpri = 'x;
        que_add_valid  = 1'b0;
        que_rmv_tskid  = 'x;
        que_rmv_valid  = 1'b0;
        wakeup_tskid   = '0;
        wakeup_valid   = 1'b0;

        // sig_sem と wai_sem は同時に来ない前提
        sem_nop = !wai_sem_valid && !sig_sem && !rel_wai_valid;
        unique case ( 1'b1 )
        wai_sem_valid:
            begin
                if ( sem_empty ) begin
                    que_add_tskid  = wai_sem_tskid;
                    que_add_tskpri = wai_sem_tskpri;
                    que_add_valid  = 1'b1;
                end
                else begin
                    next_semcnt--;
                    wakeup_tskid = wai_sem_tskid;
                    wakeup_valid = 1'b1;
                end
            end
        
        sig_sem:
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
        
        rel_wai_valid:
            begin
                que_rmv_tskid = rel_wai_tskid;
                que_rmv_valid = 1'b1;
            end

        sem_nop: ;
        endcase
    end

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
