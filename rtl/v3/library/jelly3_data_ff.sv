// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// pipeline insert FF
module jelly3_data_ff
        #(
            parameter   int     DATA_BITS   = 8                     ,
            parameter   type    data_t      = logic [DATA_BITS-1:0] ,
            parameter   bit     S_REGS      = 1                     ,
            parameter   bit     M_REGS      = 1                     ,
            parameter   data_t  INIT_DATA   = 'x                    
        )
        (
            input   var logic   reset       ,
            input   var logic   clk         ,
            input   var logic   cke         ,
            
            // slave port
            input   var data_t  s_data      ,
            input   var logic   s_valid     ,
            output  var logic   s_ready     ,
            
            // master port
            output  var data_t  m_data      ,
            output  var logic   m_valid     ,
            input   var logic   m_ready
        );
    
    // internal signal
    data_t  internal_data;
    logic   internal_valid;
    logic   internal_ready;
    
    // slave port
    if ( S_REGS ) begin : blk_s_ff
        logic   reg_s_ready,   next_s_ready;
        data_t  reg_buf_data,  next_buf_data;
        logic   reg_buf_valid, next_buf_valid;
        
        always_comb begin
            next_s_ready   = reg_s_ready;
            next_buf_data  = reg_buf_data;
            next_buf_valid = reg_buf_valid;
            
            if ( !reg_buf_valid && s_valid && !internal_ready ) begin
                // 次のステージに送れない状況でバッファリング
                next_s_ready   = 1'b0;
                next_buf_data  = s_data;
                next_buf_valid = 1'b1;
            end
            else begin
                if ( internal_ready ) begin
                    next_buf_valid = 1'b0;
                end
                if ( !internal_valid || internal_ready ) begin
                    next_s_ready = 1'b1;
                end
            end
        end
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_s_ready   <= 1'b0;
                reg_buf_valid <= 1'b0;
                reg_buf_data  <= INIT_DATA;
            end
            else if ( cke ) begin
                reg_s_ready   <= next_s_ready;
                reg_buf_data  <= next_buf_data;
                reg_buf_valid <= next_buf_valid;
            end
        end

        assign internal_data   = reg_buf_valid ? reg_buf_data : s_data;
        assign internal_valid  = reg_buf_valid ? 1'b1         : s_valid & reg_s_ready;
        assign s_ready         = reg_s_ready;
    end
    else begin : blk_s_bypass
        assign internal_data   = s_data;
        assign internal_valid  = s_valid;
        assign s_ready         = internal_ready;
    end
    
    
    // master port
    if ( M_REGS ) begin : blk_m_ff
        data_t  reg_m_data;
        logic   reg_m_valid;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_m_data  <= INIT_DATA;
                reg_m_valid <= 1'b0;
            end
            else if ( cke ) begin
                if ( ~m_valid || m_ready ) begin
                    reg_m_data  <= internal_data;
                    reg_m_valid <= internal_valid;
                end
            end
        end
        
        assign internal_ready = (!m_valid || m_ready);
        assign m_data         = reg_m_data;
        assign m_valid        = reg_m_valid;
    end
    else begin : blk_m_bypass
        assign internal_ready = m_ready;
        assign m_data         = internal_data;
        assign m_valid        = internal_valid;
    end
    
endmodule


`default_nettype wire


// end of file
