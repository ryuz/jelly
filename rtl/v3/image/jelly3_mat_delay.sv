// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mat_delay
        #(
            parameter   int     LATENCY     = 1                     ,
            parameter   int     ROWS_BITS   = 1                     ,
            parameter   type    rows_t      = logic [ROWS_BITS-1:0] ,
            parameter   int     COLS_BITS   = 1                     ,
            parameter   type    cols_t      = logic [COLS_BITS-1:0] ,
            parameter   int     DE_BITS     = 1                     ,
            parameter   type    de_t        = logic [DE_BITS-1:0]   ,
            parameter   int     USER_BITS   = 1                     ,
            parameter   type    user_t      = logic [USER_BITS-1:0] ,
            parameter   user_t  INIT_USER   = 'x                    ,
            parameter   bit     BYPASS_SIZE = 1'b0                  
        )
        (
            input   var logic   reset               ,
            input   var logic   clk                 ,
            input   var logic   cke                 ,
            
            input   var rows_t  s_mat_rows          ,
            input   var cols_t  s_mat_cols          ,
            input   var logic   s_mat_col_first     ,
            input   var logic   s_mat_col_last      ,
            input   var logic   s_mat_row_first     ,
            input   var logic   s_mat_row_last      ,
            input   var de_t    s_mat_de            ,
            input   var user_t  s_mat_user          ,
            input   var logic   s_mat_valid         ,
            
            output  var rows_t  m_mat_rows          ,
            output  var cols_t  m_mat_cols          ,
            output  var logic   m_mat_col_first     ,
            output  var logic   m_mat_col_last      ,
            output  var logic   m_mat_row_first     ,
            output  var logic   m_mat_row_last      ,
            output  var de_t    m_mat_de            ,
            output  var user_t  m_mat_user          ,
            output  var logic   m_mat_valid         
        );
    
    if ( LATENCY > 0 ) begin
        rows_t  delay_rows      ;
        cols_t  delay_cols      ;
        user_t  delay_user      ;
        logic   delay_row_first ;
        logic   delay_row_last  ;
        logic   delay_col_first ;
        logic   delay_col_last  ;
        de_t    delay_de        ;
        logic   delay_valid     ;
        
        jelly3_stream_delay
                #(
                    .LATENCY        (LATENCY - 1            ),
                    .DATA_BITS      ($bits(s_mat_rows) +
                                     $bits(s_mat_cols) +
                                     $bits(s_mat_user) + 
                                     $bits(s_mat_de  ) + 4  )
                )
            u_stream_delay
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    .cke            (cke            ),
                    
                    .s_data         ({
                                        s_mat_rows      ,
                                        s_mat_cols      ,
                                        s_mat_user      ,
                                        s_mat_row_first ,
                                        s_mat_row_last  ,
                                        s_mat_col_first ,
                                        s_mat_col_last  ,
                                        s_mat_de        
                                    }),
                    .s_valid        (s_mat_valid),
                    
                    .m_data        ({
                                        delay_rows      ,
                                        delay_cols      ,
                                        delay_user      ,
                                        delay_row_first ,
                                        delay_row_last  ,
                                        delay_col_first ,
                                        delay_col_last  ,
                                        delay_de            
                                    }),
                    .m_valid        (delay_valid    )
                );

        always_ff @(posedge clk )
            if ( reset ) begin
                m_mat_rows      <= 'x;
                m_mat_cols      <= 'x;
                m_mat_user      <= 'x;
                m_mat_row_first <= 'x;
                m_mat_row_last  <= 'x;
                m_mat_col_first <= 'x;
                m_mat_col_last  <= 'x;
                m_mat_de        <= 'x;   
                m_mat_valid     <= 1'b0;
            end
            else if ( cke ) begin
                m_mat_rows      <= delay_rows      ;
                m_mat_cols      <= delay_cols      ;
                m_mat_user      <= delay_user      ;
                m_mat_row_first <= delay_row_first ;
                m_mat_row_last  <= delay_row_last  ;
                m_mat_col_first <= delay_col_first ;
                m_mat_col_last  <= delay_col_last  ;
                m_mat_de        <= delay_de        ;
                m_mat_valid     <= delay_valid     ;
                if ( BYPASS_SIZE && s_mat_row_first && s_mat_col_first && s_mat_valid ) begin
                    m_mat_rows <= s_mat_rows;
                    m_mat_cols <= s_mat_cols;
                end
            end
        end
    else begin  : bypass
        assign  m_mat_rows      = s_mat_rows      ;
        assign  m_mat_cols      = s_mat_cols      ;
        assign  m_mat_user      = s_mat_user      ;
        assign  m_mat_row_first = s_mat_row_first ;
        assign  m_mat_row_last  = s_mat_row_last  ;
        assign  m_mat_col_first = s_mat_col_first ;
        assign  m_mat_col_last  = s_mat_col_last  ;
        assign  m_mat_de        = s_mat_de        ;
        assign  m_mat_valid     = s_mat_valid     ;
    end
    
endmodule


`default_nettype wire

// end of file
