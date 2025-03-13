// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly3_mat_buf_blk
        #(
            parameter   int     TAPS         = 1                        ,
            parameter   int     ROWS_BITS    = 16                       ,
            parameter   type    rows_t       = logic [ROWS_BITS-1:0]    ,
            parameter   int     COLS_BITS    = 16                       ,
            parameter   type    cols_t       = logic [COLS_BITS-1:0]    ,
            parameter   int     DE_BITS      = TAPS                     ,
            parameter   type    de_t         = logic [DE_BITS-1:0]      ,
            parameter   int     USER_BITS    = 1                        ,
            parameter   type    user_t       = logic [USER_BITS-1:0]    ,
            parameter   int     DATA_BITS    = 3*8                      ,
            parameter   type    data_t       = logic [DATA_BITS-1:0]    ,
            parameter   int     ROWS         = 3                        ,
            parameter   int     COLS         = 3                        ,
            parameter   int     ROW_ANCHOR   = (ROWS-1) / 2             ,
            parameter   int     COL_ANCHOR   = (COLS-1) / 2             ,
            parameter   int     MAX_COLS     = 1024                     ,
            parameter           BORDER_MODE  = "REPLICATE"              ,   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   data_t  BORDER_VALUE = '0                       ,   // BORDER_MODE == "CONSTANT"
            parameter           RAM_TYPE     = "block"                  ,
            parameter   bit     BYPASS_SIZE  = 1'b1                     ,
            parameter   bit     ENDIAN       = 0                            // 0: little, 1:big
        )
        (
            input   var logic                                   reset               ,
            input   var logic                                   clk                 ,
            input   var logic                                   cke                 ,
            
            input   var rows_t                                  s_mat_rows          ,
            input   var cols_t                                  s_mat_cols          ,
            input   var logic                                   s_mat_row_first     ,
            input   var logic                                   s_mat_row_last      ,
            input   var logic                                   s_mat_col_first     ,
            input   var logic                                   s_mat_col_last      ,
            input   var de_t                                    s_mat_de            ,
            input   var user_t                                  s_mat_user          ,
            input   var data_t  [TAPS-1:0]                      s_mat_data          ,
            input   var logic                                   s_mat_valid         ,
            
            output  var rows_t                                  m_mat_rows          ,
            output  var cols_t                                  m_mat_cols          ,
            output  var logic                                   m_mat_row_first     ,
            output  var logic                                   m_mat_row_last      ,
            output  var logic                                   m_mat_col_first     ,
            output  var logic                                   m_mat_col_last      ,
            output  var de_t                                    m_mat_de            ,
            output  var user_t                                  m_mat_user          ,
            output  var data_t  [TAPS-1:0][ROWS-1:0][COLS-1:0]  m_mat_data          ,
            output  var logic                                   m_mat_valid         
        );


    rows_t                          mat_rbuf_rows       ;
    cols_t                          mat_rbuf_cols       ;
    logic                           mat_rbuf_row_first  ;
    logic                           mat_rbuf_row_last   ;
    logic                           mat_rbuf_col_first  ;
    logic                           mat_rbuf_col_last   ;
    de_t                            mat_rbuf_de         ;
    user_t                          mat_rbuf_user       ;
    data_t  [TAPS-1:0][ROWS-1:0]    mat_rbuf_data       ;
    logic                           mat_rbuf_valid      ;

    jelly3_mat_buf_row
            #(
                .TAPS               (TAPS               ),
                .DE_BITS            ($bits(de_t)        ),
                .USER_BITS          ($bits(user_t)      ),
                .DATA_BITS          ($bits(data_t)      ),
                .ROWS               (ROWS               ),
                .ANCHOR             (ROW_ANCHOR         ),
                .MAX_COLS           (MAX_COLS           ),
                .BORDER_MODE        (BORDER_MODE        ),
                .BORDER_VALUE       (BORDER_VALUE       ),
                .RAM_TYPE           (RAM_TYPE           ),
                .BYPASS_SIZE        (BYPASS_SIZE        ),
                .ENDIAN             (ENDIAN             )
            )
        u_mat_buf_row
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),

                .s_mat_rows         (s_mat_rows         ),
                .s_mat_cols         (s_mat_cols         ),
                .s_mat_row_first    (s_mat_row_first    ),
                .s_mat_row_last     (s_mat_row_last     ),
                .s_mat_col_first    (s_mat_col_first    ),
                .s_mat_col_last     (s_mat_col_last     ),
                .s_mat_de           (s_mat_de           ),
                .s_mat_user         (s_mat_user         ),
                .s_mat_data         (s_mat_data         ),
                .s_mat_valid        (s_mat_valid        ),
                
                .m_mat_rows         (mat_rbuf_rows      ),
                .m_mat_cols         (mat_rbuf_cols      ),
                .m_mat_row_first    (mat_rbuf_row_first ),
                .m_mat_row_last     (mat_rbuf_row_last  ),
                .m_mat_col_first    (mat_rbuf_col_first ),
                .m_mat_col_last     (mat_rbuf_col_last  ),
                .m_mat_de           (mat_rbuf_de        ),
                .m_mat_user         (mat_rbuf_user      ),
                .m_mat_data         (mat_rbuf_data      ),
                .m_mat_valid        (mat_rbuf_valid     )
            );
    

    rows_t                                  mat_cbuf_rows       ;
    cols_t                                  mat_cbuf_cols       ;
    logic                                   mat_cbuf_row_first  ;
    logic                                   mat_cbuf_row_last   ;
    logic                                   mat_cbuf_col_first  ;
    logic                                   mat_cbuf_col_last   ;
    de_t                                    mat_cbuf_de         ;
    user_t                                  mat_cbuf_user       ;
    data_t  [TAPS-1:0][COLS-1:0][ROWS-1:0]  mat_cbuf_data       ;
    logic                                   mat_cbuf_valid      ;

    jelly3_mat_buf_col
            #(
                .TAPS               (TAPS                   ),
                .DE_BITS            ($bits(de_t)            ),
                .USER_BITS          ($bits(user_t)          ),
                .DATA_BITS          ($bits(data_t) * ROWS   ),
                .COLS               (COLS                   ),
                .ANCHOR             (COL_ANCHOR             ),
                .BORDER_MODE        (BORDER_MODE            ),
                .BORDER_VALUE       ({ROWS{BORDER_VALUE}}   ),
                .BYPASS_SIZE        (BYPASS_SIZE            ),
                .ENDIAN             (ENDIAN                 )
            )
        u_mat_buf_col
            (
                .reset              (reset                  ),
                .clk                (clk                    ),
                .cke                (cke                    ),
                
                .s_mat_rows         (mat_rbuf_rows          ),
                .s_mat_cols         (mat_rbuf_cols          ),
                .s_mat_row_first    (mat_rbuf_row_first     ),
                .s_mat_row_last     (mat_rbuf_row_last      ),
                .s_mat_col_first    (mat_rbuf_col_first     ),
                .s_mat_col_last     (mat_rbuf_col_last      ),
                .s_mat_de           (mat_rbuf_de            ),
                .s_mat_user         (mat_rbuf_user          ),
                .s_mat_data         (mat_rbuf_data          ),
                .s_mat_valid        (mat_rbuf_valid         ),

                .m_mat_rows         (mat_cbuf_rows          ),
                .m_mat_cols         (mat_cbuf_cols          ),
                .m_mat_row_first    (mat_cbuf_row_first     ),
                .m_mat_row_last     (mat_cbuf_row_last      ),
                .m_mat_col_first    (mat_cbuf_col_first     ),
                .m_mat_col_last     (mat_cbuf_col_last      ),
                .m_mat_de           (mat_cbuf_de            ),
                .m_mat_user         (mat_cbuf_user          ),
                .m_mat_data         (mat_cbuf_data          ),
                .m_mat_valid        (mat_cbuf_valid         )
            );

    for ( genvar i = 0; i < TAPS; i++ ) begin : tap_loop
        for ( genvar y = 0; y < ROWS; y++ ) begin : row_loop
            for ( genvar x = 0; x < COLS; x++ ) begin : col_loop
                assign m_mat_data[i][y][x] = mat_cbuf_data[i][x][y];
            end
        end
    end

    assign m_mat_rows      = mat_cbuf_rows      ;
    assign m_mat_cols      = mat_cbuf_cols      ;
    assign m_mat_row_first = mat_cbuf_row_first ;
    assign m_mat_row_last  = mat_cbuf_row_last  ;
    assign m_mat_col_first = mat_cbuf_col_first ;
    assign m_mat_col_last  = mat_cbuf_col_last  ;
    assign m_mat_de        = mat_cbuf_de        ;
    assign m_mat_user      = mat_cbuf_user      ;
    assign m_mat_valid     = mat_cbuf_valid     ;

endmodule


`default_nettype wire


// end of file
