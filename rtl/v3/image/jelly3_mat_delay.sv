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
            parameter   int     LATENCY    = 1                      ,
            parameter   int     ROWS_BITS  = 1                      ,
            parameter   type    rows_t     = logic [ROWS_BITS-1:0]  ,
            parameter   int     COLS_BITS  = 1                      ,
            parameter   type    cols_t     = logic [COLS_BITS-1:0]  ,
            parameter   int     USER_BITS  = 1                      ,
            parameter   type    user_t     = logic [USER_BITS-1:0]  ,
            parameter   user_t  INIT_USER  = 'x                     
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
            input   var logic   s_mat_de            ,
            input   var user_t  s_mat_user          ,
            input   var logic   s_mat_valid         ,
            
            output  var rows_t  m_mat_rows          ,
            output  var cols_t  m_mat_cols          ,
            output  var logic   m_mat_col_first     ,
            output  var logic   m_mat_col_last      ,
            output  var logic   m_mat_row_first     ,
            output  var logic   m_mat_row_last      ,
            output  var logic   m_mat_de            ,
            output  var user_t  m_mat_user          ,
            output  var logic   m_mat_valid         
        );
    

    user_t                  delay_user          ;
    logic                   delay_row_first     ;
    logic                   delay_row_last      ;
    logic                   delay_col_first     ;
    logic                   delay_col_last      ;
    logic                   delay_de            ;
    logic                   delay_valid         ;
    
    jelly3_stream_delay
            #(
                .LATENCY        (LATENCY                ),
                .DATA_BITS      ($bits(s_mat_rows) +
                                 $bits(s_mat_cols) +
                                 $bits(s_mat_user) + 5  )
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
                                    m_mat_rows      ,
                                    m_mat_cols      ,
                                    m_mat_user      ,
                                    m_mat_row_first ,
                                    m_mat_row_last  ,
                                    m_mat_col_first ,
                                    m_mat_col_last  ,
                                    m_mat_de            
                                }),
                .m_valid        (m_mat_valid    )
            );

    
endmodule


`default_nettype wire

// end of file
