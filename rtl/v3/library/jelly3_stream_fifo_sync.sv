// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Stream Sync-FIFO
module jelly3_stream_fifo_sync
        #(
            parameter   int     PTR_BITS     = 5                    ,
            localparam  int     FIFO_SIZE    = 2 ** PTR_BITS        ,
            parameter   int     SIZE_BITS    = $clog2(FIFO_SIZE + 1),
            parameter   type    size_t       = logic [SIZE_BITS-1:0],
            parameter   int     DATA_BITS    = 8                    ,
            parameter   type    data_t       = logic [DATA_BITS-1:0],
            parameter           RAM_TYPE     = "block"              ,
            parameter   bit     DOUT_REG     = 1'b0                 ,
            parameter           DEVICE       = "RTL"                ,
            parameter           SIMULATION   = "false"              ,
            parameter           DEBUG        = "false"              
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,

            // slave port
            input   var data_t  s_data      ,
            input   var logic   s_valid     ,
            output  var logic   s_ready     ,
            output  var size_t  s_free_size ,

            // master port
            output  var data_t  m_data      ,
            output  var logic   m_valid     ,
            input   var logic   m_ready     ,
            output  var size_t  m_data_size 
        );
    
    if ( PTR_BITS > 0 ) begin : blk_fifo
        // FIFO
        logic       wr_en           ;
        data_t      wr_data         ;
        logic       wr_full         ;
        size_t      wr_free_size    ;
    ;
        logic       rd_en           ;
        logic       rd_regcke       ;
        data_t      rd_data         ;
        logic       rd_empty        ;
        size_t      rd_data_size    ;

        jelly3_fifo_sync
                #(
                    .PTR_BITS       (PTR_BITS       ),
                    .SIZE_BITS      (SIZE_BITS      ),
                    .size_t         (size_t         ),
                    .DATA_BITS      (DATA_BITS      ),
                    .data_t         (data_t         ),
                    .RAM_TYPE       (RAM_TYPE       ),
                    .DOUT_REG       (DOUT_REG       ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_fifo_sync
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),

                    .wr_en          (wr_en          ),
                    .wr_data        (wr_data        ),
                    .wr_full        (wr_full        ),
                    .wr_free_size   (wr_free_size   ),

                    .rd_en          (rd_en          ),
                    .rd_regcke      (rd_regcke      ),
                    .rd_data        (rd_data        ),
                    .rd_empty       (rd_empty       ),
                    .rd_data_size   (rd_data_size   )
                );

        // Write
        assign wr_en       = s_valid && s_ready ;
        assign wr_data     = s_data             ;
        assign s_ready     = !wr_full           ;
        assign s_free_size = wr_free_size       ;


        // Read(FWFT)
        jelly3_fifo_fwft_read
                #(
                    .PTR_BITS       (PTR_BITS       ),
                    .FIFO_SIZE      (FIFO_SIZE      ),
                    .SIZE_BITS      (SIZE_BITS      ),
                    .size_t         (size_t         ),
                    .DATA_BITS      (DATA_BITS      ),
                    .data_t         (data_t         ),
                    .DOUT_REG       (DOUT_REG       ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_fifo_fwft_read
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    .rd_en          (rd_en          ),
                    .rd_regcke      (rd_regcke      ),
                    .rd_data        (rd_data        ),
                    .rd_empty       (rd_empty       ),
                    .rd_data_size   (rd_data_size   ),
                    .m_data         (m_data         ),
                    .m_valid        (m_valid        ),
                    .m_ready        (m_ready        ),
                    .m_data_size    (m_data_size    )
                );
    end
    else begin : bypass
        assign m_data  = s_data     ;
        assign m_valid = s_valid    ;
        assign s_ready = m_ready    ;
        assign s_free_size = 0;
        assign m_data_size = 0;
    end

endmodule


`default_nettype wire


// end of file
