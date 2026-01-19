// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4l_s
        #(
            parameter   int     MEM_ADDR_BITS    = 16                   ,
            parameter   int     MEM_SIZE         = (1 << MEM_ADDR_BITS) ,
            parameter   bit     READ_DATA_ADDR   = 0                    ,      // リード結果をアドレスとする
            parameter   string  WRITE_LOG_FILE   = ""                   ,
            parameter   string  READ_LOG_FILE    = ""                   ,
            parameter   int     AW_DELAY         = 0                    ,
            parameter   int     AR_DELAY         = 0                    ,
            parameter   int     AW_FIFO_PTR_BITS = 0                    ,
            parameter   int     W_FIFO_PTR_BITS  = 0                    ,
            parameter   int     B_FIFO_PTR_BITS  = 0                    ,
            parameter   int     AR_FIFO_PTR_BITS = 0                    ,
            parameter   int     R_FIFO_PTR_BITS  = 0                    ,
            parameter   int     AW_BUSY_RATE     = 0                    ,
            parameter   int     W_BUSY_RATE      = 0                    ,
            parameter   int     B_BUSY_RATE      = 0                    ,
            parameter   int     AR_BUSY_RATE     = 0                    ,
            parameter   int     R_BUSY_RATE      = 0                    ,
            parameter   int     AW_RAND_SEED     = 0                    ,
            parameter   int     W_RAND_SEED      = 1                    ,
            parameter   int     B_RAND_SEED      = 2                    ,
            parameter   int     AR_RAND_SEED     = 3                    ,
            parameter   int     R_RAND_SEED      = 4                    
        )
        (
            jelly3_axi4l_if.s    s_axi4l
        );
    

    jelly3_axi4_if
            #(
                .ADDR_BITS  (s_axi4l.ADDR_BITS  ),
                .DATA_BITS  (s_axi4l.DATA_BITS  ),
                .LIMIT_AW   (1                  ),
                .LIMIT_W    (1                  ),
                .LIMIT_WC   (1                  ),
                .LIMIT_AR   (1                  ),
                .LIMIT_R    (1                  ),
                .LIMIT_RC   (1                  )
            )
        axi4
            (
                .aresetn    (s_axi4l.aresetn    ),
                .aclk       (s_axi4l.aclk       ),
                .aclken     (s_axi4l.aclken     )
            );

    jelly3_axi4l_to_axi4
        u_axi4l_to_axi4
            (
                .s_axi4l    (s_axi4l            ),
                .m_axi4     (axi4.m             )
            );

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS      (MEM_ADDR_BITS      ),
                .MEM_SIZE           (MEM_SIZE           ),
                .READ_DATA_ADDR     (READ_DATA_ADDR     ),
                .WRITE_LOG_FILE     (WRITE_LOG_FILE     ),
                .READ_LOG_FILE      (READ_LOG_FILE      ),
                .AW_DELAY           (AW_DELAY           ),
                .AR_DELAY           (AR_DELAY           ),
                .AW_FIFO_PTR_BITS   (AW_FIFO_PTR_BITS   ),
                .W_FIFO_PTR_BITS    (W_FIFO_PTR_BITS    ),
                .B_FIFO_PTR_BITS    (B_FIFO_PTR_BITS    ),
                .AR_FIFO_PTR_BITS   (AR_FIFO_PTR_BITS   ),
                .R_FIFO_PTR_BITS    (R_FIFO_PTR_BITS    ),
                .AW_BUSY_RATE       (AW_BUSY_RATE       ),
                .W_BUSY_RATE        (W_BUSY_RATE        ),
                .B_BUSY_RATE        (B_BUSY_RATE        ),
                .AR_BUSY_RATE       (AR_BUSY_RATE       ),
                .R_BUSY_RATE        (R_BUSY_RATE        ),
                .AW_RAND_SEED       (AW_RAND_SEED       ),
                .W_RAND_SEED        (W_RAND_SEED        ),
                .B_RAND_SEED        (B_RAND_SEED        ),
                .AR_RAND_SEED       (AR_RAND_SEED       ),
                .R_RAND_SEED        (R_RAND_SEED        )
            )
        u_model_axi4l_s
            (
                .s_axi4             (axi4.s             )
            );
    
    
endmodule

`default_nettype wire

// end of file
