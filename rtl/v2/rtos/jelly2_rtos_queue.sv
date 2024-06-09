// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_rtos_queue
        #(
            parameter bit   PRIORITY_ORDER = 1'b1,
            parameter int   QUE_SIZE       = 16,
            parameter int   ID_WIDTH       = 4,
            parameter int   PRI_WIDTH      = 4,
            parameter int   COUNT_WIDTH    = $clog2(QUE_SIZE+1)
        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            input   var logic                       cke,

            input   var logic   [ID_WIDTH-1:0]      add_id,
            input   var logic   [PRI_WIDTH-1:0]     add_pri,
            input   var logic                       add_valid,

            input   var logic   [ID_WIDTH-1:0]      remove_id,
            input   var logic                       remove_valid,

            output  var logic   [ID_WIDTH-1:0]      top_id,
            output  var logic                       top_valid,

            output  var logic   [COUNT_WIDTH-1:0]   count
        );

    generate
    if ( PRIORITY_ORDER ) begin : blk_priority
        jelly2_rtos_queue_priority
                #(
                    .QUE_SIZE       (QUE_SIZE       ),
                    .ID_WIDTH       (ID_WIDTH       ),
                    .PRI_WIDTH      (PRI_WIDTH      ),
                    .COUNT_WIDTH    (COUNT_WIDTH    )
                )
            i_rtos_queue_priority
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),

                    .add_id         (add_id         ),
                    .add_pri        (add_pri        ),
                    .add_valid      (add_valid      ),

                    .remove_id      (remove_id      ),
                    .remove_valid   (remove_valid   ),

                    .top_id         (top_id         ),
                    .top_pri        (               ),
                    .top_valid      (top_valid      ),

                    .count          (count          )
                );
    end
    else begin : blk_fifo
        jelly2_rtos_queue_fifo
                #(
                    .QUE_SIZE       (QUE_SIZE       ),
                    .ID_WIDTH       (ID_WIDTH       ),
                    .COUNT_WIDTH    (COUNT_WIDTH    )
                )
            i_rtos_queue_fifo
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),

                    .add_id         (add_id         ),
                    .add_valid      (add_valid      ),

                    .remove_id      (remove_id      ),
                    .remove_valid   (remove_valid   ),

                    .top_id         (top_id         ),
                    .top_valid      (top_valid      ),

                    .count          (count          )
                );
    end
    endgenerate

endmodule


`default_nettype wire


// End of file
