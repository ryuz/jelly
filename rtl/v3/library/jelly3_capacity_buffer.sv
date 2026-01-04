// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 容量伝搬バッファ
module jelly3_capacity_buffer
        #(
            parameter   int     CAPACITY_BITS = 32                          ,   // オーバーフローしないサイズとする
            parameter   type    capacity_t    = logic [CAPACITY_BITS-1:0]   ,
            parameter   int     REQUEST_BITS  = CAPACITY_BITS               ,
            parameter   type    request_t     = logic [REQUEST_BITS-1:0]    ,
            parameter   int     ISSUE_BITS    = CAPACITY_BITS               ,   // CAPACITY_BITS より大きくすること
            parameter   type    issue_t       = logic [ISSUE_BITS-1:0]      ,
            parameter   bit     REQUEST_SIZE_OFFSET = 1'b0                  ,
            parameter   bit     ISSUE_SIZE_OFFSET   = 1'b0                  ,
            parameter   capacity_t INIT_REQUEST = {CAPACITY_BITS{1'b0}}     
        )
        (
            input   var logic       reset           ,
            input   var logic       clk             ,
            input   var logic       cke             ,
            
            output  var capacity_t  queued_request  ,
            
            input   var request_t   s_request_size  ,
            input   var logic       s_request_valid ,
            
            output  var issue_t     m_issue_size    ,
            output  var logic       m_issue_valid   ,
            input   var logic       m_issue_ready   
        );
    
    logic       ready;
    
    capacity_t  reg_queued_request, next_queued_request;
    logic       reg_request_empty,  next_request_empty;
    
    issue_t     reg_issue_size,     next_issue_size;
    logic       reg_issue_valid,    next_issue_valid;
    
    assign ready = (!m_issue_valid || m_issue_ready);
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_queued_request <= INIT_REQUEST          ;
            reg_request_empty  <= (INIT_REQUEST == 0)   ;
            reg_issue_size     <= 'x                    ;
            reg_issue_valid    <= 1'b0                  ;
        end
        else if ( cke ) begin
            reg_queued_request <= next_queued_request   ;
            reg_request_empty  <= next_request_empty    ;
            reg_issue_size     <= next_issue_size       ;
            reg_issue_valid    <= next_issue_valid      ;
        end
    end
    
    always_comb begin
        next_queued_request = reg_queued_request;
        next_request_empty  = reg_request_empty ;
        next_issue_size     = reg_issue_size    ;
        next_issue_valid    = reg_issue_valid   ;
        
        if ( m_issue_ready ) begin
            next_issue_valid = 1'b0;
        end
        
        if ( !next_issue_valid && !next_request_empty ) begin
            next_issue_size     = next_queued_request - issue_t'(ISSUE_SIZE_OFFSET);
            next_issue_valid    = 1'b1  ;
            next_queued_request = 0     ;
            next_request_empty  = 1'b1  ;
        end
        
        if ( s_request_valid ) begin
            next_queued_request = next_queued_request + capacity_t'(s_request_size) + capacity_t'(REQUEST_SIZE_OFFSET);
            next_request_empty  = ((capacity_t'({1'b0, s_request_size}) + capacity_t'(REQUEST_SIZE_OFFSET)) == 0);
        end
    end
    
    assign m_issue_size  = reg_issue_size;
    assign m_issue_valid = reg_issue_valid;
    
    assign queued_request = reg_queued_request;
    
endmodule


`default_nettype wire


// end of file
