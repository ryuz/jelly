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
            parameter int                           QUE_COUNT_WIDTH = $clog2(QUE_SIZE+1),
            parameter int                           TSKID_WIDTH     = 4,
            parameter int                           TSKPRI_WIDTH    = 4,
            parameter int                           SEM_COUNT_WIDTH = 4,
            parameter bit                           PRIORITY_ORDER  = 1'b0,
            parameter bit   [SEM_COUNT_WIDTH-1:0]   INIT_SEM_COUNT  = 0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            input   wire                            signal,

            input   wire    [TSKID_WIDTH-1:0]       wait_tskid,
            input   wire    [TSKPRI_WIDTH-1:0]      wait_tskpri,
            input   wire                            wait_valid,

            input   wire    [TSKID_WIDTH-1:0]       remove_tskid,
            input   wire                            remove_valid,

            output  reg     [TSKID_WIDTH-1:0]       wakeup_id,
            output  reg                             wakeup_valid,

            output  reg     [SEM_COUNT_WIDTH-1:0]   sem_count,
            output  wire    [QUE_COUNT_WIDTH-1:0]   que_count
        );

    logic   [TSKID_WIDTH-1:0]   que_add_tskid;
    logic   [TSKPRI_WIDTH-1:0]  que_add_tskpri;
    logic                       que_add_valid;

    logic   [ID_WIDTH-1:0]      que_add_tskid;
    logic                       que_add_valid;

    logic   [ID_WIDTH-1:0]      que_top_tskid;
    logic                       que_top_valid;

    jelly_rtos_queue
            #(
                .PRIORITY_ORDER (PRIORITY_ORDER)
                .QUE_SIZE       (QUE_SIZE),
                .ID_WIDTH       (ID_WIDTH),
                .PRI_WIDTH      (PRI_WIDTH),
                .COUNT_WIDTH    (QUE_COUNT_WIDTH)
            )
        i_rtos_queue
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),

                .add_id         (wait_tskid),
                .add_pri        (wait_tskpri),
                .add_valid      (wait_valid),

                .remove_id      (remove_id),
                .remove_valid   (wait_valid),

                .top_id         (que_top_id),
                .top_valid      (que_top_valid),

                .count          (que_count)
            );
    

    
    logic   [COUNTER_WIDTH-1:0] next_counter;
    logic                       que_empty;

    always_comb begin : blk_sem
        next_counter = counter;
        que_op       = 'x;
        que_id       = 'x;
        que_pri      = 'x;
        que_valid    = 1'b0;
        wakeup_id    = '0;
        wakeup_valid = 1'b0;

        // sig_sem と wai_sem は同時に来ない前提
        unique case (1'b1)
        wait_valid:
            begin
                if ( empty ) begin
                    que_op    = 1'b0;
                    que_id    = wait_id;
                    que_pri   = wait_pri;
                    que_valid = 1'b1;
                end
                else begin
                    next_counter--;
                    wakeup_id    = wait_id;
                    wakeup_valid = 1'b1;
                end
            end
        
        signal:
            begin
                if ( que_top_valid ) begin
                    // キューにあれば取り出す
                    que_op       = 1'b1;
                    que_id       = que_top_id;
                    que_valid    = 1'b1;

                    wakeup_id    = que_top_id;
                    wakeup_valid = 1'b1;
                end
                else begin
                    next_counter++;
                end
            end
        endcase

        if ( remove_valid ) begin
            que_op    = 1'b1;
            que_id    = remove_id;
            que_valid = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            count <= INIT_COUNT;
            empty <= (INIT_COUNT == '0);
        end
        else if ( cke ) begin
            count <= next_counter;
            empty <= (next_counter == '0);
        end
    end

endmodule


`default_nettype wire


// End of file
