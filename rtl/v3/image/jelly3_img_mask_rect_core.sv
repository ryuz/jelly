// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_mask_rect_core
        #(
            parameter   int     ROWS_BITS    = 16                       ,
            parameter   type    rows_t       = logic    [ROWS_BITS-1:0] ,
            parameter   int     COLS_BITS    = 16                       ,
            parameter   type    cols_t       = logic    [COLS_BITS-1:0] ,
            parameter   int     TAPS         = 1                        ,
            parameter   int     DE_BITS      = TAPS                     ,
            parameter   type    de_t         = logic    [DE_BITS-1:0]   ,
            parameter   int     DATA_BITS    = 8                        ,
            parameter   type    data_t       = logic    [DATA_BITS-1:0] ,
            parameter   int     USER_BITS    = 1                        ,
            parameter   type    user_t       = logic [USER_BITS-1:0]    ,
            parameter   int     X_BITS       = 10                       ,
            parameter   type    x_t          = logic [X_BITS-1:0]       ,
            parameter   int     Y_BITS       = 10                       ,
            parameter   type    y_t          = logic [Y_BITS-1:0]       ,
            parameter   bit     BYPASS_SIZE  = 1'b1                     
        )
        (
            input   var logic               reset               ,
            input   var logic               clk                 ,
            input   var logic               cke                 ,

            input   var logic               enable              ,

            input   var x_t                 param_x             ,
            input   var y_t                 param_y             ,
            input   var x_t                 param_width         ,
            input   var y_t                 param_height        ,

            input   var rows_t              s_img_rows          ,
            input   var cols_t              s_img_cols          ,
            input   var logic               s_img_row_first     ,
            input   var logic               s_img_row_last      ,
            input   var logic               s_img_col_first     ,
            input   var logic               s_img_col_last      ,
            input   var de_t                s_img_de            ,
            input   var data_t  [TAPS-1:0]  s_img_data          ,
            input   var user_t              s_img_user          ,
            input   var logic               s_img_valid         ,

            output  var logic               m_rect_row_first    ,
            output  var logic               m_rect_row_last     ,
            output  var logic               m_rect_col_first    ,
            output  var logic               m_rect_col_last     ,
            output  var logic               m_rect_de           ,
            
            output  var rows_t              m_img_rows          ,
            output  var cols_t              m_img_cols          ,
            output  var logic               m_img_row_first     ,
            output  var logic               m_img_row_last      ,
            output  var logic               m_img_col_first     ,
            output  var logic               m_img_col_last      ,
            output  var de_t                m_img_de            ,
            output  var data_t  [TAPS-1:0]  m_img_data          ,
            output  var user_t              m_img_user          ,
            output  var logic               m_img_valid         
        );

    x_t         st0_x           ;
    y_t         st0_y           ;
    de_t        st0_de          ;

    de_t        st1_row_first   ;
    de_t        st1_row_last    ;
    de_t        st1_col_first   ;
    de_t        st1_col_last    ;
    de_t        st1_de          ;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_x <= st0_x + x_t'(TAPS);
            if ( s_img_col_first ) begin
                st0_x <= '0;
                st0_y <= st0_y + 1'b1;
                if ( s_img_row_first ) begin
                    st0_y <= '0;
                end
            end
            st0_de <= s_img_de;

            // stage 1
            if ( enable ) begin
                st1_row_first <= st0_y == param_y;
                st1_row_last  <= st0_y == param_y + param_height - 1;
                st1_col_first <= param_x >= st0_x && param_x < st0_x + x_t'(TAPS);
                st1_col_last  <= param_x + param_width - 1 >= st0_x && param_x + param_width - 1 < st0_x + x_t'(TAPS);
                st1_de <= '0;
                for ( int i = 0; i < DE_BITS; i++ ) begin
                    if ( st0_y >= param_y && st0_y < param_y + param_height ) begin
                        if ( st0_x + x_t'(i) >= param_x && st0_x + x_t'(i) < param_x + param_width ) begin
                            st1_de[i] <= st0_de[i];
                        end
                    end
                end
            end
            else begin
                st1_de <= st0_de;
            end
        end
    end

    rows_t              m_mat_rows      ;
    cols_t              m_mat_cols      ;
    logic               m_mat_col_first ;
    logic               m_mat_col_last  ;
    logic               m_mat_row_first ;
    logic               m_mat_row_last  ;
    de_t                m_mat_de        ;
    data_t  [TAPS-1:0]  m_mat_data      ;
    user_t              m_mat_user      ;
    logic               m_mat_valid     ;

    jelly3_mat_delay
            #(
                .TAPS               (TAPS               ),
                .ROWS_BITS          (ROWS_BITS          ),
                .COLS_BITS          (COLS_BITS          ),
                .DE_BITS            (DE_BITS            ),
                .DATA_BITS          (DATA_BITS          ),
                .USER_BITS          (USER_BITS          ),
                .LATENCY            (2                  ),
                .BYPASS_SIZE        (BYPASS_SIZE        )
            )
        u_img_delay
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),
                
                .s_mat_rows         (s_img_rows         ),
                .s_mat_cols         (s_img_cols         ),
                .s_mat_row_first    (s_img_row_first    ),
                .s_mat_row_last     (s_img_row_last     ),
                .s_mat_col_first    (s_img_col_first    ),
                .s_mat_col_last     (s_img_col_last     ),
                .s_mat_de           (s_img_de           ),
                .s_mat_data         (s_img_data         ),
                .s_mat_user         (s_img_user         ),
                .s_mat_valid        (s_img_valid        ),
                
                .m_mat_rows         (m_mat_rows         ),
                .m_mat_cols         (m_mat_cols         ),
                .m_mat_row_first    (m_mat_row_first    ),
                .m_mat_row_last     (m_mat_row_last     ),
                .m_mat_col_first    (m_mat_col_first    ),
                .m_mat_col_last     (m_mat_col_last     ),
                .m_mat_de           (m_mat_de           ),
                .m_mat_data         (m_mat_data         ),
                .m_mat_user         (m_mat_user         ),
                .m_mat_valid        (m_mat_valid        )
            );

    assign m_rect_row_first       = st1_row_first           ;
    assign m_rect_row_last        = st1_row_last            ;
    assign m_rect_col_first       = st1_col_first           ;
    assign m_rect_col_last        = st1_col_last            ;
    assign m_rect_de              = st1_de                  ;

    assign m_img_rows             = m_mat_rows              ;
    assign m_img_cols             = m_mat_cols              ;
    assign m_img_row_first        = m_mat_row_first         ;
    assign m_img_row_last         = m_mat_row_last          ;
    assign m_img_col_first        = m_mat_col_first         ;
    assign m_img_col_last         = m_mat_col_last          ;
    assign m_img_de               = m_mat_de                ;
    assign m_img_data             = m_mat_data              ;
    assign m_img_user             = m_mat_user              ;
    assign m_img_valid            = m_mat_valid             ;

endmodule


`default_nettype wire


// end of file
