// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4s_packet_smoother
        #(
            parameter   bit     ASYNC          = 1                      ,
            parameter   int     FIFO_PTR_BITS  = 9                      ,
            localparam  int     FIFO_SIZE      = 2 ** FIFO_PTR_BITS     ,
            parameter   int     SIZE_BITS      = $clog2(FIFO_SIZE + 1)  ,
            parameter   type    size_t         = logic [SIZE_BITS-1:0]  ,
            parameter           FIFO_RAM_TYPE  = "block"                ,
            parameter   int     FIFO_S_SYNC_FF = 2                      ,
            parameter   int     FIFO_M_SYNC_FF = 2                      ,
            parameter   bit     FIFO_DOUT_REG  = 1                      ,
            parameter   bit     FIFO_S_REG     = 1                      ,
            parameter   bit     FIFO_M_REG     = 1                      ,
            parameter   int     LIMIT_SIZE     = 2 ** FIFO_PTR_BITS     ,
            parameter           DEVICE         = "RTL"                  ,
            parameter           SIMULATION     = "false"                ,
            parameter           DEBUG          = "false"                
        )
        (
            jelly3_axi4s_if.s   s_axi4s     ,
            output  var size_t  s_free_size ,

            jelly3_axi4s_if.m   m_axi4s     ,
            output  var size_t  m_data_size 
        );
    
    localparam int      COUNT_BITS = FIFO_PTR_BITS + 1      ;
    localparam type     count_t    = logic [COUNT_BITS-1:0] ;


    // --------------------------------
    //  FIFO
    // --------------------------------

    jelly3_axi4s_if
            #(
                .USE_STRB       (m_axi4s.USE_STRB      ),
                .USE_KEEP       (m_axi4s.USE_KEEP      ),
                .USE_LAST       (m_axi4s.USE_LAST      ),
                .USE_ID         (m_axi4s.USE_ID        ),
                .USE_DEST       (m_axi4s.USE_DEST      ),
                .USE_USER       (m_axi4s.USE_USER      ),
                .DATA_BITS      (m_axi4s.DATA_BITS     ),
                .BYTE_BITS      (m_axi4s.BYTE_BITS     ),
                .STRB_BITS      (m_axi4s.STRB_BITS     ),
                .KEEP_BITS      (m_axi4s.KEEP_BITS     ),
                .ID_BITS        (m_axi4s.ID_BITS       ),
                .DEST_BITS      (m_axi4s.DEST_BITS     ),
                .USER_BITS      (m_axi4s.USER_BITS     ),
                .DEVICE         (DEVICE                ),
                .SIMULATION     (SIMULATION            ),
                .DEBUG          (DEBUG                 )
            )
        axi4s_fifo
            (
                .aresetn        (m_axi4s.aresetn       ),
                .aclk           (m_axi4s.aclk          ),
                .aclken         (m_axi4s.aclken        )
            );

    jelly3_axi4s_fifo
            #(
                .ASYNC          (ASYNC          ),
                .PTR_BITS       (FIFO_PTR_BITS  ),
                .RAM_TYPE       (FIFO_RAM_TYPE  ),
                .S_SYNC_FF      (FIFO_S_SYNC_FF ),
                .M_SYNC_FF      (FIFO_M_SYNC_FF ),
                .DOUT_REG       (FIFO_DOUT_REG  ),
                .S_REG          (FIFO_S_REG     ),
                .M_REG          (FIFO_M_REG     ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_axi4s_fifo
            (
                .s_axi4s        (s_axi4s        ),
                .m_axi4s        (axi4s_fifo.m   ),
                .s_free_size    (s_free_size    ),
                .m_data_size    (               )
            );

    // --------------------------------
    //  Smoother
    // --------------------------------

    count_t     wr_count;
    logic       wr_limit;
    logic       wr_valid;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            wr_count <= '0;
            wr_limit <= 1'b0;
        end
        else if ( s_axi4s.aclken ) begin
            if ( s_axi4s.tvalid && s_axi4s.tready ) begin
                wr_count <= wr_count + 1'b1;
                wr_limit <= (wr_count + 1'b1) >= count_t'(LIMIT_SIZE - 1);
            end
            if ( wr_valid ) begin
                wr_count <= '0;
                wr_limit <= 1'b0;
            end
        end
    end
    assign wr_valid = s_axi4s.tvalid && s_axi4s.tready && (s_axi4s.tlast || wr_limit);
    

    count_t     issue_size        ;
    logic       issue_valid       ;
    logic       issue_ready       ;
    jelly3_capacity_async
        #(
                .ASYNC                  (ASYNC              ),
                .CAPACITY_BITS          ($bits(count_t)     ),
                .capacity_t             (count_t            ),
                .REQUEST_BITS           ($bits(count_t)     ),
                .request_t              (count_t            ),
                .ISSUE_BITS             ($bits(count_t)     ),
                .issue_t                (count_t            ),
                .REQUEST_SIZE_OFFSET    (1'b1               ),
                .ISSUE_SIZE_OFFSET      (1'b1               ),
                .INIT_REQUEST           ('0                 )
            )
        u_capacity_async
            (
                .s_reset                (~s_axi4s.aresetn   ),
                .s_clk                  (s_axi4s.aclk       ),
                .s_cke                  (s_axi4s.aclken     ),
                .s_request_size         (wr_count           ),
                .s_request_valid        (wr_valid           ),
                .s_queued_request       (                   ),

                .m_reset                (~m_axi4s.aresetn   ),
                .m_clk                  (m_axi4s.aclk       ),
                .m_cke                  (m_axi4s.aclken     ),
                .m_issue_size           (issue_size         ),
                .m_issue_valid          (issue_valid        ),
                .m_issue_ready          (issue_ready        ),
                .m_queued_request       (                   )
            );
    
    count_t     reg_count , next_count  ;
    logic       reg_enable, next_enable ;
    always_comb begin
        next_count  = reg_count;
        next_enable = reg_enable;
        if ( issue_valid && issue_ready ) begin
            next_count += issue_size + 1'b1;
        end
        if ( m_axi4s.tvalid && m_axi4s.tready ) begin
            next_count--;
        end
        next_enable = (next_count > 0);
    end

    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            reg_count  <= '0;
            reg_enable <= 1'b0;
        end
        else if ( m_axi4s.aclken ) begin
            reg_count  <= next_count ;
            reg_enable <= next_enable;
        end
    end

    assign issue_ready = 1;

    assign m_axi4s.tuser  = axi4s_fifo.tuser                ;
    assign m_axi4s.tlast  = axi4s_fifo.tlast                ;
    assign m_axi4s.tdata  = axi4s_fifo.tdata                ;
    assign m_axi4s.tstrb  = axi4s_fifo.tstrb                ;
    assign m_axi4s.tvalid = axi4s_fifo.tvalid & reg_enable  ;
    assign m_data_size    = size_t'(reg_count)              ;

    assign axi4s_fifo.tready = m_axi4s.tready & reg_enable  ;

 endmodule

`default_nettype wire

