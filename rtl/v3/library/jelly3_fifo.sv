// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Generic FIFO
module jelly3_fifo
        #(
            parameter   bit     ASYNC      = 1                      ,
            parameter   int     PTR_BITS   = 5                      ,
            localparam  int     FIFO_SIZE  = 2 ** PTR_BITS          ,
            parameter   int     SIZE_BITS  = $clog2(FIFO_SIZE + 1)  ,
            parameter   type    size_t     = logic [SIZE_BITS-1:0]  ,
            parameter   int     DATA_BITS  = 8                      ,
            parameter   type    data_t     = logic [DATA_BITS-1:0]  ,
            parameter   int     WR_SYNC_FF = 2                      ,
            parameter   int     RD_SYNC_FF = 2                      ,
            parameter           RAM_TYPE   = "block"                ,
            parameter   bit     DOUT_REG   = 1'b0                   ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"                
        )
        (
            input   var logic       wr_reset        ,
            input   var logic       wr_clk          ,
            input   var logic       wr_cke          ,
            input   var logic       wr_en           ,
            input   var data_t      wr_data         ,
            output  var logic       wr_full         ,
            output  var size_t      wr_free_size    ,
            
            input   var logic       rd_reset        ,
            input   var logic       rd_clk          ,
            input   var logic       rd_cke          ,
            input   var logic       rd_en           ,
            input   var logic       rd_regcke       ,
            output  var data_t      rd_data         ,
            output  var logic       rd_empty        ,
            output  var size_t      rd_data_size    
        );

    if ( ASYNC ) begin : async
        jelly3_fifo_async
                #(
                    .PTR_BITS       (PTR_BITS       ),
                    .SIZE_BITS      (SIZE_BITS      ),
                    .size_t         (size_t         ),
                    .DATA_BITS      (DATA_BITS      ),
                    .data_t         (data_t         ),
                    .WR_SYNC_FF     (WR_SYNC_FF     ),
                    .RD_SYNC_FF     (RD_SYNC_FF     ),
                    .RAM_TYPE       (RAM_TYPE       ),
                    .DOUT_REG       (DOUT_REG       ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_fifo_async
                (
                    .wr_reset       (wr_reset       ),
                    .wr_clk         (wr_clk         ),
                    .wr_cke         (wr_cke         ),
                    .wr_en          (wr_en          ),
                    .wr_data        (wr_data        ),
                    .wr_full        (wr_full        ),
                    .wr_free_size   (wr_free_size   ),
                    .rd_reset       (rd_reset       ),
                    .rd_clk         (rd_clk         ),
                    .rd_cke         (rd_cke         ),
                    .rd_en          (rd_en          ),
                    .rd_regcke      (rd_regcke      ),
                    .rd_data        (rd_data        ),
                    .rd_empty       (rd_empty       ),
                    .rd_data_size   (rd_data_size   )
                );
    end
    else begin : sync
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
                    .reset          (wr_reset       ),
                    .clk            (wr_clk         ),
                    .cke            (wr_cke         ),
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
    end

endmodule

`default_nettype wire


// end of file
