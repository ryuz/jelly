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
            parameter   int     BUF_SIZE   = 1                                          ,
            parameter   int     SIZE_BITS  = BUF_SIZE > 0 ? $clog2(BUF_SIZE + 1) : 1    ,
            parameter   type    size_t     = logic [SIZE_BITS-1:0]                      ,
            parameter   int     DATA_BITS  = 8                                          ,
            parameter   type    data_t     = logic [DATA_BITS-1:0]                      ,
            parameter   bit     M_REG      = 1'b0                                       ,
            parameter           DEVICE     = "RTL"                                      ,
            parameter           SIMULATION = "false"                                    ,
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

    data_t  out_data    ;
    logic   out_valid   ;
    logic   out_ready   ;

    if ( BUF_SIZE > 0 ) begin : buffer
        logic   reg_bufferd ;
        ptr_t   reg_ptr     ;
        logic   next_bufferd;
        ptr_t   next_ptr    ;
        logic   next_ready  ;
        logic   shift_en    ;

        // buffer
        data_t  buf_data;
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


        always_comb begin
            next_bufferd = reg_bufferd  ;
            next_ptr    = reg_ptr       ;
            next_size   = current_size  ;
            next_ready  = s_ready       ;
            shift_en    = 1'b0          ;

            if ( s_valid && s_ready && !out_ready ) begin
                next_size++ ;   // 出力できないときに入力を受けたらバッファする
            end
            if ( reg_bufferd && !(s_valid && s_ready) && out_ready ) begin
                next_size-- ;   // バッファ済みで出力出来て入力が無ければバッファが減る
            end
            next_bufferd = next_size > 0                        ;
            next_ptr     = next_size - 1                        ;
            next_ready   = next_size < size_t'(BUF_SIZE)        ;
            shift_en     = s_valid && s_ready && next_bufferd   ;
        end

        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_bufferd  <= 1'b0;
                reg_ptr      <= '0;
                current_size <= '0;
                s_ready      <= 1'b0;
            end
            else if ( cke ) begin
                reg_bufferd  <= next_bufferd    ;
                reg_ptr      <= next_ptr        ;
                current_size <= next_size       ;
                s_ready      <= next_ready      ;
            end
        end
        
        assign out_data  = reg_bufferd ? buf_data : s_data  ;
        assign out_valid = s_valid || reg_bufferd           ;
    end
    else begin : no_buffer
        assign s_ready      = out_ready;
        assign out_data     = s_data   ;
        assign out_valid    = s_valid  ;
        assign current_size = 0;
        assign next_size    = 0;
    end

    if ( M_REG ) begin : reg_out
        always_ff @(posedge clk) begin
            if ( reset ) begin
                m_data  <= 'x   ;
                m_valid <= 1'b0 ;
            end
            else if ( cke ) begin
                if ( out_ready ) begin
                    m_data  <= out_data ;
                    m_valid <= out_valid;
                end
            end
        end
        assign out_ready = !m_valid || m_ready;
    end
    else begin : no_reg
        assign m_data    = out_data    ;
        assign m_valid   = out_valid   ;
        assign out_ready = m_ready     ;
    end

endmodule


`default_nettype wire


// end of file
