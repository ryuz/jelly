// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos_queue
        #(
            parameter bit   PRIORITY_ORDER = 1'b1,
            parameter int   QUE_SIZE       = 16,
            parameter int   ID_WIDTH       = 4,
            parameter int   PRI_WIDTH      = 4,
            parameter int   COUNT_WIDTH    = $clog2(QUE_SIZE+1)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,

            input   wire    [ID_WIDTH-1:0]      add_id,
            input   wire    [PRI_WIDTH-1:0]     add_pri,
            input   wire                        add_valid,

            input   wire    [ID_WIDTH-1:0]      remove_id,
            input   wire                        remove_valid,

            output  wire    [ID_WIDTH-1:0]      top_id,
            output  wire                        top_valid,

            output  reg     [COUNT_WIDTH-1:0]   count
        );

    generate
    if ( PRIORITY_ORDER ) begin : blk_priority
        jelly_rtos_queue_priority
                #(
                    .QUE_SIZE       (QUE_SIZE),
                    .ID_WIDTH       (ID_WIDTH),
                    .PRI_WIDTH      (PRI_WIDTH),
                    .COUNT_WIDTH    (COUNT_WIDTH)
                )
            i_rtos_queue_priority
                (
                    .*,
                    .top_pri        ()
                );
    end
    else begin : blk_fifo
        jelly_rtos_queue_fifo
                #(
                    .QUE_SIZE       (QUE_SIZE),
                    .ID_WIDTH       (ID_WIDTH),
                    .COUNT_WIDTH    (COUNT_WIDTH)
                )
            i_rtos_queue_fifo
                (
                    .*
                );
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
