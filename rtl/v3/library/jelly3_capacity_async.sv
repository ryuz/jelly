// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 容量の非同期伝搬
module jelly3_capacity_async
        #(
            parameter   bit         ASYNC               = 1                         ,   // 非同期伝搬を行う
            parameter   int         CAPACITY_BITS       = 32                        ,   // オーバーフローしないサイズとする
            parameter   type        capacity_t          = logic [CAPACITY_BITS-1:0] ,
            parameter   int         REQUEST_BITS        = CAPACITY_BITS             ,
            parameter   type        request_t           = logic [REQUEST_BITS-1:0]  ,
            parameter   int         ISSUE_BITS          = CAPACITY_BITS             ,   // CAPACITY_BITS より大きくすること
            parameter   type        issue_t             = logic [ISSUE_BITS-1:0]    ,
            parameter   bit         REQUEST_SIZE_OFFSET = 1'b0                      ,
            parameter   bit         ISSUE_SIZE_OFFSET   = 1'b0                      ,
            parameter   capacity_t  INIT_REQUEST        = {CAPACITY_BITS{1'b0}}     
        )
        (
            input   var logic       s_reset             ,
            input   var logic       s_clk               ,
            input   var logic       s_cke               ,
            input   var request_t   s_request_size      ,
            input   var logic       s_request_valid     ,
            output  var capacity_t  s_queued_request    ,
            
            input   var logic       m_reset             ,
            input   var logic       m_clk               ,
            input   var logic       m_cke               ,
            output  var issue_t     m_issue_size        ,
            output  var logic       m_issue_valid       ,
            input   var logic       m_issue_ready       ,
            output  var capacity_t  m_queued_request    
        );
    
    generate
    if ( ASYNC ) begin : blk_async
        capacity_t  s_size  ;
        logic       s_valid ;
        logic       s_ready ;
        
        capacity_t  m_size  ;
        logic       m_valid ;
        
        jelly3_capacity_buffer
                #(
                    .CAPACITY_BITS          (CAPACITY_BITS      ),
                    .REQUEST_BITS           (REQUEST_BITS       ),
                    .ISSUE_BITS             (CAPACITY_BITS      ),
                    .REQUEST_SIZE_OFFSET    (REQUEST_SIZE_OFFSET),
                    .ISSUE_SIZE_OFFSET      (1'b0               ),
                    .INIT_REQUEST           ('0                 )
                )
            u_capacity_buffer_s 
                (
                    .reset                  (s_reset            ),
                    .clk                    (s_clk              ),
                    .cke                    (s_cke              ),
                    
                    .queued_request         (s_queued_request   ),
                    
                    .s_request_size         (s_request_size     ),
                    .s_request_valid        (s_request_valid    ),
                    
                    .m_issue_size           (s_size             ),
                    .m_issue_valid          (s_valid            ),
                    .m_issue_ready          (s_ready            )
                );
        
        jelly3_data_async
                #(
                    .DATA_BITS              (CAPACITY_BITS      )
                )
            u_data_async
                (
                    .s_reset                (s_reset            ),
                    .s_clk                  (s_clk              ),
                    .s_cke                  (s_cke              ),
                    .s_data                 (s_size             ),
                    .s_valid                (s_valid            ),
                    .s_ready                (s_ready            ),
                    
                    .m_reset                (m_reset            ),
                    .m_clk                  (m_clk              ),
                    .m_cke                  (m_cke              ),
                    .m_data                 (m_size             ),
                    .m_valid                (m_valid            ),
                    .m_ready                (1'b1               )
                );
        
        jelly3_capacity_buffer
                #(
                    .CAPACITY_BITS          (CAPACITY_BITS      ),
                    .REQUEST_BITS           (CAPACITY_BITS      ),
                    .ISSUE_BITS             (ISSUE_BITS         ),
                    .REQUEST_SIZE_OFFSET    (1'b0               ),
                    .ISSUE_SIZE_OFFSET      (ISSUE_SIZE_OFFSET  ),
                    
                    .INIT_REQUEST           (INIT_REQUEST       )
                )
            u_capacity_buffer_m
                (
                    .reset                  (m_reset            ),
                    .clk                    (m_clk              ),
                    .cke                    (m_cke              ),
                    
                    .queued_request         (m_queued_request   ),
                    
                    .s_request_size         (m_size             ),
                    .s_request_valid        (m_valid            ),
                    
                    .m_issue_size           (m_issue_size       ),
                    .m_issue_valid          (m_issue_valid      ),
                    .m_issue_ready          (m_issue_ready      )
                );
    end
    else begin : blk_sync
        jelly3_capacity_buffer
                #(
                    .CAPACITY_BITS          (CAPACITY_BITS      ),
                    .REQUEST_BITS           (REQUEST_BITS       ),
                    .ISSUE_BITS             (ISSUE_BITS         ),
                    .REQUEST_SIZE_OFFSET    (REQUEST_SIZE_OFFSET),
                    .ISSUE_SIZE_OFFSET      (ISSUE_SIZE_OFFSET  ),
                    
                    .INIT_REQUEST           (INIT_REQUEST       )
                )
            u_capacity_buffer
                (
                    .reset                  (s_reset            ),
                    .clk                    (s_clk              ),
                    .cke                    (s_cke              ),
                    
                    .queued_request         (m_queued_request   ),
                    
                    .s_request_size         (s_request_size     ),
                    .s_request_valid        (s_request_valid    ),
                    
                    .m_issue_size           (m_issue_size       ),
                    .m_issue_valid          (m_issue_valid      ),
                    .m_issue_ready          (m_issue_ready      )
                );
        
        assign s_queued_request = 0;
    end
    endgenerate
    
    
    // debug (for simulation)
    integer total_request;
    always_ff @(posedge s_clk) begin
        if ( s_reset ) begin
            total_request <= 0;
        end
        else begin
            if ( s_request_valid ) begin
                total_request <= total_request + integer'(s_request_size) + integer'(REQUEST_SIZE_OFFSET);
            end
        end
    end
    
    integer total_issue;
    always_ff @(posedge m_clk) begin
        if ( m_reset ) begin
            total_issue <= 0;
        end
        else begin
            if ( m_issue_valid & m_issue_ready ) begin
                total_issue <= total_issue + integer'(m_issue_size) + integer'(ISSUE_SIZE_OFFSET);
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
