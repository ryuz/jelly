// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_skid_buffer
        #(
            parameter   int     BUF_SIZE   = 1                      ,
            parameter   int     SIZE_BITS  = $clog2(BUF_SIZE + 1)   ,
            parameter   type    size_t     = logic [SIZE_BITS-1:0]  ,
            parameter   int     DATA_BITS  = 8                      ,
            parameter   type    data_t     = logic [DATA_BITS-1:0]  ,
            parameter           DEVICE     = "RTL"                  ,
            parameter           SIMULATION = "false"                ,
            parameter           DEBUG      = "false"                
        )
        (
            input   var logic   reset           ,
            input   var logic   clk             ,
            input   var logic   cke             ,
            
            // slave port
            input   var data_t  s_data          ,
            input   var logic   s_valid         ,
            output  var logic   s_ready         ,

            // master port
            output  var data_t  m_data          ,
            output  var logic   m_valid         ,
            input   var logic   m_ready         ,

            output  var size_t  current_size    ,
            output  var size_t  next_size       
        );
    
    localparam  type    ptr_t = logic [$bits(size_t)-1:0];

    logic   reg_bufferd ;
    ptr_t   reg_ptr     ;
    logic   next_bufferd;
    ptr_t   next_ptr    ;
    logic   next_valid  ;
    logic   next_ready  ;
    logic   shift_en    ;
    always_comb begin
        next_bufferd = reg_bufferd  ;
        next_ptr    = reg_ptr       ;
        next_size   = current_size  ;
        next_valid  = m_valid       ;
        next_ready  = s_ready       ;
        shift_en    = 1'b0          ;

        if ( s_valid && s_ready ) begin
            next_size++ ;
        end
        if ( m_valid && m_ready ) begin
            next_size-- ;
        end
        next_bufferd = next_size > 0                        ;
        next_ptr     = next_size - 1                        ;
        next_valid   = s_valid || (next_size > 0)           ;
        next_ready   = next_size < size_t'(BUF_SIZE-1)      ;
        shift_en     = s_valid && s_ready && next_bufferd   ;
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_bufferd  <= 1'b0;
            reg_ptr      <= '0;
            current_size <= '0;
            s_ready      <= 1'b0;
            m_valid      <= 1'b0;
        end
        else if ( cke ) begin
            reg_bufferd  <= next_bufferd    ;
            reg_ptr      <= next_ptr        ;
            current_size <= next_size       ;
            s_ready      <= next_ready      ;
            m_valid      <= next_valid      ;
        end
    end
    
    data_t      buf_data;
    jelly3_shift_register
            #(
                .DEPTH      (BUF_SIZE       ),
                .ADDR_WIDTH ($bits(ptr_t)   ),
                .addr_t     (ptr_t          ),
                .DATA_WIDTH ($bits(data_t)  ),
                .data_t     (data_t         ),
                .DEVICE     (DEVICE         ),
                .SIMULATION (SIMULATION     ),
                .DEBUG      (DEBUG          )
            )
        u_shift_register
            (
                .clk       (clk             ),
                .cke       (shift_en && cke ),
                
                .addr      (reg_ptr         ),
                .in_data   (s_data          ),
                .out_data  (buf_data        )
            );

    assign m_data = reg_bufferd ? buf_data : s_data;

endmodule


`default_nettype wire


// end of file
