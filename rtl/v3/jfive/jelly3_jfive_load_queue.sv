// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_jfive_load_queue
        #(
            parameter   int     QUE_SIZE    = 4                                 ,
            parameter   int     XLEN        = 32                                ,
            parameter   int     ID_BITS     = 4                                 ,
            parameter   type    id_t        = logic         [ID_BITS-1:0]       ,
            parameter   int     PC_BITS     = 32                                ,
            parameter   type    pc_t        = logic         [PC_BITS-1:0]       ,
            parameter   int     INSTR_BITS  = 32                                ,
            parameter   type    instr_t     = logic         [INSTR_BITS-1:0]    ,
            parameter   type    ridx_t      = logic         [4:0]               ,
            parameter   int     ALIGN_BITS  = $clog2(XLEN / 8)                  ,
            parameter   type    align_t     = logic         [ALIGN_BITS-1:0]    ,
            parameter   type    size_t      = logic         [1:0]               ,
            parameter           DEVICE      = "RTL"                             ,
            parameter           SIMULATION  = "false"                           ,
            parameter           DEBUG       = "false"                           
        )
        (
            input   var logic                   reset           ,
            input   var logic                   clk             ,
            input   var logic                   cke             ,

            output  var id_t    [QUE_SIZE-1:0]  que_id          ,
            output  var pc_t    [QUE_SIZE-1:0]  que_pc          ,
            output  var instr_t [QUE_SIZE-1:0]  que_instr       ,
            output  var logic   [QUE_SIZE-1:0]  que_rd_en       ,
            output  var ridx_t  [QUE_SIZE-1:0]  que_rd_idx      ,
            output  var align_t [QUE_SIZE-1:0]  que_align       ,
            output  var size_t  [QUE_SIZE-1:0]  que_size        ,
            output  var logic   [QUE_SIZE-1:0]  que_unsigned    ,
            output  var logic   [QUE_SIZE-1:0]  que_valid       ,

            // input
            input   var id_t                    s_id            ,
            input   var pc_t                    s_pc            ,
            input   var instr_t                 s_instr         ,
            input   var ridx_t                  s_rd_idx        ,
            input   var align_t                 s_align         ,
            input   var size_t                  s_size          ,
            input   var logic                   s_unsigned      ,
            input   var logic                   s_valid         ,
            output  var logic                   s_ready    ,

            // output
            output  var id_t                    m_id            ,
            output  var pc_t                    m_pc            ,
            output  var instr_t                 m_instr         ,
            output  var ridx_t                  m_rd_idx        ,
            output  var align_t                 m_align         ,
            output  var size_t                  m_size          ,
            output  var logic                   m_unsigned      ,
            output  var logic                   m_valid         ,
            input   var logic                   m_ready    
        );

    localparam  int     COUNT_BITS = $clog2(QUE_SIZE + 1)       ;
    localparam  type    count_t    = logic  [COUNT_BITS-1:0]    ;


    id_t    [QUE_SIZE-1:0]  next_id         ;
    pc_t    [QUE_SIZE-1:0]  next_pc         ;
    instr_t [QUE_SIZE-1:0]  next_instr      ;
    ridx_t  [QUE_SIZE-1:0]  next_rd_idx     ;
    align_t [QUE_SIZE-1:0]  next_align      ;
    size_t  [QUE_SIZE-1:0]  next_size       ;
    logic   [QUE_SIZE-1:0]  next_unsigned   ;
    logic   [QUE_SIZE-1:0]  next_valid      ;
    always_comb begin
        next_id       = que_id      ;
        next_pc       = que_pc      ;
        next_instr    = que_instr   ;
        next_rd_idx   = que_rd_idx  ;
        next_align    = que_align   ;
        next_size     = que_size    ;
        next_unsigned = que_unsigned;
        next_valid    = que_valid   ;
        if ( m_valid && m_ready ) begin
            for ( int i = 0; i < QUE_SIZE-1; i++ ) begin
                next_id      [i] = next_id      [i+1];
                next_pc      [i] = que_pc       [i+1];
                next_instr   [i] = que_instr    [i+1];
                next_rd_idx  [i] = next_rd_idx  [i+1];
                next_align   [i] = next_align   [i+1];
                next_size    [i] = next_size    [i+1];
                next_unsigned[i] = next_unsigned[i+1];
                next_valid   [i] = next_valid   [i+1];
            end
            next_id      [QUE_SIZE-1] = 'x;
            next_pc      [QUE_SIZE-1] = 'x;
            next_instr   [QUE_SIZE-1] = 'x;
            next_rd_idx  [QUE_SIZE-1] = 'x;
            next_align   [QUE_SIZE-1] = 'x;
            next_size    [QUE_SIZE-1] = 'x;
            next_unsigned[QUE_SIZE-1] = 'x;
            next_valid   [QUE_SIZE-1] = '0;
        end
        if ( s_ready ) begin
            for ( int i = 0; i < QUE_SIZE; i++ ) begin
                if ( !next_valid[i] ) begin
                    next_id      [i] = s_id      ;
                    next_pc      [i] = s_pc      ;
                    next_instr   [i] = s_instr   ;
                    next_rd_idx  [i] = s_rd_idx  ;
                    next_align   [i] = s_align   ;
                    next_size    [i] = s_size    ;
                    next_unsigned[i] = s_unsigned;
                    next_valid   [i] = s_valid   ;
                    break;
                end
            end
        end
    end

    always_ff @(posedge clk ) begin
        if ( reset ) begin
            que_id       <= 'x;
            que_pc       <= 'x;
            que_instr    <= 'x;
            que_rd_en    <= '0;
            que_rd_idx   <= 'x;
            que_align    <= 'x;
            que_size     <= 'x;
            que_unsigned <= 'x;
            que_valid    <= '0;
        end
        else if ( cke ) begin
            que_id       <= next_id       ;
            que_pc       <= next_pc       ;
            que_instr    <= next_instr    ;
            que_rd_en    <= next_valid    ;
            que_rd_idx   <= next_rd_idx   ;
            que_align    <= next_align    ;
            que_size     <= next_size     ;
            que_unsigned <= next_unsigned ;
            que_valid    <= next_valid    ;
        end
    end
    
    assign s_ready = !que_valid[QUE_SIZE-1]; // && !m_ready;

    assign m_id         = que_id      [0] ;
    assign m_pc         = que_pc      [0] ;
    assign m_instr      = que_instr   [0] ;
    assign m_rd_idx     = que_rd_idx  [0] ;
    assign m_align      = que_align   [0] ;
    assign m_size       = que_size    [0] ;
    assign m_unsigned   = que_unsigned[0] ;
    assign m_valid      = que_valid   [0] ;

endmodule


`default_nettype wire


// End of file
