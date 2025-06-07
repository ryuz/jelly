// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// FIFO
module jelly3_fifo_async
        #(
            parameter   int     PTR_BITS     = 5                    ,
            parameter   int     FIFO_SIZE    = 2 ** PTR_BITS        ,
            parameter   int     SIZE_BITS    = $clog2(FIFO_SIZE + 1),
            parameter   type    size_t       = logic [SIZE_BITS-1:0],
            parameter   int     DATA_BITS    = 8                    ,
            parameter   type    data_t       = logic [DATA_BITS-1:0],
            parameter   int     SYNC_FF      = 2                    ,
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
    
    localparam  type    ptr_t = logic [PTR_BITS-1:0];

    ptr_t   wr_wptr  ;
    ptr_t   wr_rptr  ;
    ptr_t   rd_wptr  ;
    ptr_t   rd_rptr  ;

    jelly3_cdc_gray
            #(
                .DEST_SYNC_FF   (SYNC_FF        ),
                .WIDTH          ($bits(data_t)  ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          ),
            )
        u_cdc_gray_wptr
        (
            input   var logic               src_clk     ,
            input   var logic   [WIDTH-1:0] src_in_bin  ,
            input   var logic               dest_clk    ,
            output  var logic   [WIDTH-1:0] dest_out_bin
        );



    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_ptr   <= '0;
            reg_valid <= 1'b0;
            reg_ready <= 1'b0;
        end
        else if ( cke ) begin
            reg_ptr   <= next_ptr  ;
            reg_valid <= next_valid;
            reg_ready <= next_ready;
        end
    end
    
    jelly3_shift_register
            #(
                .DEPTH      (FIFO_SIZE                  ),
                .ADDR_WIDTH ($bits(ptr_t)               ),
                .addr_t     (ptr_t                      ),
                .DATA_WIDTH ($bits(data_t)              ),
                .data_t     (data_t                     ),
                .DEVICE     (DEVICE                     ),
                .SIMULATION (SIMULATION                 ),
                .DEBUG      (DEBUG                      )
            )
        u_shift_register
            (
                .clk       ,
                .cke       (cke && s_valid && s_ready   ),
                
                .addr      (reg_ptr                     ),
                .in_data   (s_data                      ),
                .out_data  (m_data                      )
            );
    
endmodule


`default_nettype wire


// end of file
