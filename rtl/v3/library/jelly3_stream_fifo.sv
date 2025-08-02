// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Generic Stream FIFO
module jelly3_stream_fifo
        #(
            parameter   bit     ASYNC        = 1                    ,
            parameter   int     PTR_BITS     = 5                    ,
            localparam  int     FIFO_SIZE    = 2 ** PTR_BITS        ,
            parameter   int     SIZE_BITS    = $clog2(FIFO_SIZE + 1),
            parameter   type    size_t       = logic [SIZE_BITS-1:0],
            parameter   int     DATA_BITS    = 8                    ,
            parameter   type    data_t       = logic [DATA_BITS-1:0],
            parameter   int     S_SYNC_FF    = 2                    ,
            parameter   int     M_SYNC_FF    = 2                    ,
            parameter           RAM_TYPE     = "block"              ,
            parameter   bit     DOUT_REG     = 1'b0                 ,
            parameter           DEVICE       = "RTL"                ,
            parameter           SIMULATION   = "false"              ,
            parameter           DEBUG        = "false"              
        )
        (
            // slave port
            input   var logic   s_reset     ,
            input   var logic   s_clk       ,
            input   var logic   s_cke       ,
            input   var data_t  s_data      ,
            input   var logic   s_valid     ,
            output  var logic   s_ready     ,
            output  var size_t  s_free_size ,

            // master port
            input   var logic   m_reset     ,
            input   var logic   m_clk       ,
            input   var logic   m_cke       ,
            output  var data_t  m_data      ,
            output  var logic   m_valid     ,
            input   var logic   m_ready     ,
            output  var size_t  m_data_size 
        );
    
    if ( ASYNC ) begin : async
        jelly3_stream_fifo_async
                #(
                    .PTR_BITS       (PTR_BITS       ),
                    .SIZE_BITS      (SIZE_BITS      ),
                    .size_t         (size_t         ),
                    .DATA_BITS      (DATA_BITS      ),
                    .data_t         (data_t         ),
                    .S_SYNC_FF      (S_SYNC_FF      ),
                    .M_SYNC_FF      (M_SYNC_FF      ),
                    .RAM_TYPE       (RAM_TYPE       ),
                    .DOUT_REG       (DOUT_REG       ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_stream_fifo_async
                (
                    .s_reset        (s_reset        ),
                    .s_clk          (s_clk          ),
                    .s_cke          (s_cke          ),
                    .s_data         (s_data         ),
                    .s_valid        (s_valid        ),
                    .s_ready        (s_ready        ),
                    .s_free_size    (s_free_size    ),

                    .m_reset        (m_reset        ),
                    .m_clk          (m_clk          ),
                    .m_cke          (m_cke          ),
                    .m_data         (m_data         ),
                    .m_valid        (m_valid        ),
                    .m_ready        (m_ready        ),
                    .m_data_size    (m_data_size    )
                );
    end
    else begin : sync
        if ( string'(RAM_TYPE) == "register" ) begin : sr
            jelly3_stream_fifo_sr
                    #(
                        .PTR_BITS       (PTR_BITS       ),
                        .FIFO_SIZE      (FIFO_SIZE      ),
                        .SIZE_BITS      (SIZE_BITS      ),
                        .size_t         (size_t         ),
                        .DATA_BITS      (DATA_BITS      ),
                        .data_t         (data_t         ),
                        .DEVICE         (DEVICE         ),
                        .SIMULATION     (SIMULATION     ),
                        .DEBUG          (DEBUG          )
                    )
                u_stream_fifo_sr
                    (
                        .reset          (s_reset        ),
                        .clk            (s_clk          ),
                        .cke            (s_cke          ),

                        .s_data         (s_data         ),
                        .s_valid        (s_valid        ),
                        .s_ready        (s_ready        ),
                        .s_free_size    (s_free_size    ),

                        .m_data         (m_data         ),
                        .m_valid        (m_valid        ),
                        .m_ready        (m_ready        ),
                        .m_data_size    (m_data_size    )
                    );
        end
        else begin : fifo
            jelly3_stream_fifo_sync
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
                u_stream_fifo_sync
                    (
                        .reset          (s_reset        ),
                        .clk            (s_clk          ),
                        .cke            (s_cke          ),

                        .s_data         (s_data         ),
                        .s_valid        (s_valid        ),
                        .s_ready        (s_ready        ),
                        .s_free_size    (s_free_size    ),

                        .m_data         (m_data         ),
                        .m_valid        (m_valid        ),
                        .m_ready        (m_ready        ),
                        .m_data_size    (m_data_size    )
                    );
        end
    end

endmodule


`default_nettype wire


// end of file
