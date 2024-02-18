// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


module jelly2_img_blk_buffer
        #(
            parameter   int                         M            = 3            ,   // block width
            parameter   int                         N            = 3            ,   // block height
            parameter   int                         CENTER_X     = (M-1) / 2    ,
            parameter   int                         CENTER_Y     = (N-1) / 2    ,
            parameter   int                         MAX_COLS     = 1024         ,
            parameter                               BORDER_MODE  = "REFLECT_101",   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter                               BORDER_VALUE = 0            ,
            parameter                               RAM_TYPE     = "block"      ,
            parameter   bit                         ENDIAN       = 0                // 0: little, 1:big
        )
        (
            jelly3_img_if.s     s_img,
            jelly3_img_if.m     m_img
        );
    

//  localparam  int     DATA_BITS = $bits(s_img.data);
//  localparam  int     DE_BITS   = $bits(s_img.de  );
//  localparam  int     USER_BITS = $bits(s_img.user);
    localparam  int     DATA_BITS = s_img.DATA_BITS ;
    localparam  int     DE_BITS   = s_img.DE_BITS   ;
    localparam  int     USER_BITS = s_img.USER_BITS ;

    parameter   type    data_t    = logic [DATA_BITS-1:0]   ;
    parameter   type    de_t      = logic [DE_BITS-1:0]     ;
    parameter   type    user_t    = logic [USER_BITS-1:0]   ;

    localparam  data_t  LBUF_BORDER_VALUE = data_t'(BORDER_VALUE);

    logic               img_lbuf_row_first  ;
    logic               img_lbuf_row_last   ;
    logic               img_lbuf_col_first  ;
    logic               img_lbuf_col_last   ;
    de_t                img_lbuf_de         ;
    user_t              img_lbuf_user       ;
    data_t   [N-1:0]    img_lbuf_data       ;
    logic               img_lbuf_valid      ;
    
    jelly2_img_line_buffer
            #(
                .N                      (N                  ),
                .USER_WIDTH             (USER_BITS          ),
                .DATA_WIDTH             (DATA_BITS          ),
                .CENTER                 (CENTER_Y           ),
                .MAX_COLS               (MAX_COLS           ),
                .BORDER_MODE            (BORDER_MODE        ),
                .BORDER_VALUE           (LBUF_BORDER_VALUE  ),
                .RAM_TYPE               (RAM_TYPE           ),
                .ENDIAN                 (ENDIAN             )
            )
        i_img_line_buffer
            (
                .reset                  (s_img.reset        ),
                .clk                    (s_img.clk          ),
                .cke                    (s_img.cke          ),
                
                .s_img_row_first        (s_img.row_first    ),
                .s_img_row_last         (s_img.row_last     ),
                .s_img_col_first        (s_img.col_first    ),
                .s_img_col_last         (s_img.col_last     ),
                .s_img_de               (s_img.de           ),
                .s_img_user             (s_img.user         ),
                .s_img_data             (s_img.data         ),
                .s_img_valid            (s_img.valid        ),
                
                .m_img_row_first        (img_lbuf_row_first ),
                .m_img_row_last         (img_lbuf_row_last  ),
                .m_img_col_first        (img_lbuf_col_first ),
                .m_img_col_last         (img_lbuf_col_last  ),
                .m_img_de               (img_lbuf_de        ),
                .m_img_user             (img_lbuf_user      ),
                .m_img_data             (img_lbuf_data      ),
                .m_img_valid            (img_lbuf_valid     )
            );
    
    localparam  data_t  [N-1:0]     PBUF_BORDER_VALUE = {N{LBUF_BORDER_VALUE}};

    logic                   img_pbuf_row_first  ;
    logic                   img_pbuf_row_last   ;
    logic                   img_pbuf_col_first  ;
    logic                   img_pbuf_col_last   ;
    logic                   img_pbuf_de         ;
    user_t                  img_pbuf_user       ;
    data_t  [M-1:0][N-1:0]  img_pbuf_data       ;
    logic                   img_pbuf_valid      ;
    
    jelly2_img_pixel_buffer
            #(
                .M                      (M                  ),
                .USER_WIDTH             (USER_BITS          ),
                .DATA_WIDTH             (N*DATA_BITS        ),
                .CENTER                 (CENTER_X           ),
                .BORDER_MODE            (BORDER_MODE        ),
                .BORDER_VALUE           (PBUF_BORDER_VALUE  ),
                .ENDIAN                 (ENDIAN             )
            )
        i_img_pixel_buffer
            (
                .reset                  (s_img.reset        ),
                .clk                    (s_img.clk          ),
                .cke                    (s_img.cke          ),
                
                .s_img_row_first        (img_lbuf_row_first ),
                .s_img_row_last         (img_lbuf_row_last  ),
                .s_img_col_first        (img_lbuf_col_first ),
                .s_img_col_last         (img_lbuf_col_last  ),
                .s_img_de               (img_lbuf_de        ),
                .s_img_user             (img_lbuf_user      ),
                .s_img_data             (img_lbuf_data      ),
                .s_img_valid            (img_lbuf_valid     ),
                
                .m_img_row_first        (img_pbuf_row_first ),
                .m_img_row_last         (img_pbuf_row_last  ),
                .m_img_col_first        (img_pbuf_col_first ),
                .m_img_col_last         (img_pbuf_col_last  ),
                .m_img_de               (img_pbuf_de        ),
                .m_img_user             (img_pbuf_user      ),
                .m_img_data             (img_pbuf_data      ),
                .m_img_valid            (img_pbuf_valid     )
            );

    data_t  [M-1:0][N-1:0]  m_img_data;
    for ( genvar y = 0; y < N; y = y+1 ) begin : y_loop
        for ( genvar x = 0; x < M; x = x+1 ) begin : x_loop
            assign m_img_data[y][x] = img_pbuf_data[x][y];
        end
    end

    assign m_img.row_first = img_pbuf_row_first;
    assign m_img.row_last  = img_pbuf_row_last;
    assign m_img.col_first = img_pbuf_col_first;
    assign m_img.col_last  = img_pbuf_col_last;
    assign m_img.de        = img_pbuf_de;
    assign m_img.data      = m_img_data;
    assign m_img.user      = img_pbuf_user;
    assign m_img.valid     = img_pbuf_valid;
    

    // assertion
    initial begin
        sva_data_bits : assert ( m_img.DATA_BITS == s_img.DATA_BITS * M * N ) else $warning("m_img.DATA_BITS != s_img.DATA_BITS * M * N");
    end
    always_comb begin
        sva_connect_clk : assert (m_img.clk === s_img.clk);
    end

endmodule


`default_nettype wire


// end of file
