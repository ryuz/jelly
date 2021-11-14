// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_semaphore
        #(
            parameter int                       N             = 16,
            parameter int                       N_WIDTH       = $clog2(N+1),
            parameter int                       ID_WIDTH      = 4,
            parameter int                       PRI_WIDTH     = 4,
            parameter int                       COUNTER_WIDTH = 4
            parameter bit   [COUNT_WIDTH-1:0]   INIT_COUNTER  = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire                        signal,

            input   wire    [ID_WIDTH-1:0]      wait_id,
            input   wire    [PRI_WIDTH-1:0]     wait_pri,
            input   wire                        wait_valid,

            output  reg     [ID_WIDTH-1:0]      wakeup_id,
            output  reg                         wakeup_valid,

            output  reg     [COUNTER_WIDTH-1:0] counter,
            output  wire    [N_WIDTH-1:0]       que_size
        );

    logic       que_op;
    logic       que_id;
    logic       que_pri;
    logic       que_valid;

    logic       que_top_id;
    logic       que_top_pri;
    logic       que_top_valid;

    jelly_priority_queue
            #(
                .N          (N),
                .ID_WIDTH   (ID_WIDTH),
                .PRI_WIDTH  (PRI_WIDTH),
                .N_WIDTH    = $clog2(N+1)
            )
        i_queue
            (
                .reset      (reset),
                .clk        (clk),
                .cke        (cke),

                .in_op      (que_op),  // 0: add, 1: del
                .in_id      (que_id),
                .in_pri     (que_pri),
                .in_valid   (que_valid),

                .top_id     (que_top_id),
                .top_pri    (),
                .top_valid  (que_top_valid),

                .size       (que_size)
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
