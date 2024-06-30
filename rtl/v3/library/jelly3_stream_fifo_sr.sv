// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// FIFO
module jelly3_stream_fifo_sr
        #(
            parameter   int     PTR_BITS    = 5                     ,
            parameter   type    size_t      = logic [PTR_BITS:0]    ,
            parameter   int     FIFO_SIZE   = 2 ** PTR_BITS         ,
            parameter   int     DATA_BITS   = 8                     ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"                
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,
            
            // slave port
            input   var data_t  s_data      ,
            input   var logic   s_valid     ,
            output  var logic   s_ready     ,
            output  var size_t  s_free_count,

            // master port
            output  var data_t  m_data      ,
            output  var logic   m_valid     ,
            input   var logic   m_ready     ,
            output  var size_t  m_data_count
        );
    
    localparam  type    ptr_t = logic [PTR_BITS-1:0];

    ptr_t   reg_ptr  ,  next_ptr      ;
    logic   reg_valid,  next_valid    ;
    logic   reg_ready,  next_ready    ;
    always_comb begin
        next_ptr   = reg_ptr    ;
        next_valid = reg_valid  ;
        next_ready = 1'b0       ;
        if ( m_valid && m_ready ) begin
            if ( next_ptr == '0 ) begin
                next_ptr   = 'x;
                next_valid = 1'b0;
            end
            else begin
                next_ptr   = reg_ptr - 1;
                next_valid = 1'b1       ;
            end
        end

        if ( s_valid && s_ready ) begin
            if ( next_valid ) begin
                next_ptr   = reg_ptr + 1;
                next_valid = 1'b1       ;
            end
            else begin
                next_ptr   = '0         ;
                next_valid = 1'b1       ;
            end
        end

        next_ready = (int'(next_ptr) < FIFO_SIZE) || m_ready;
    end

    assign s_ready = reg_ready;
    assign m_valid = reg_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_ptr   <= 'x;
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
