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
            parameter   int                         USER_WIDTH   = 0,
            parameter   int                         DATA_WIDTH   = 36,
            parameter   int                         ROWS         = 3,
            parameter   int                         COLS         = 3,
            parameter   int                         ROW_CENTER   = (ROWS-1) / 2,
            parameter   int                         COL_CENTER   = (COLS-1) / 2,
            parameter   int                         COLS_MAX     = 1024,
            parameter   string                      BORDER_MODE  = "REFLECT_101",   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}},
            parameter   string                      RAM_TYPE     = "block",
            parameter   bit                         ENDIAN       = 0,               // 0: little, 1:big

            localparam  int                         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   logic                                           reset,
            input   logic                                           clk,
            input   logic                                           cke,
            
            input   logic                                           s_img_row_first,
            input   logic                                           s_img_row_last,
            input   logic                                           s_img_col_first,
            input   logic                                           s_img_col_last,
            input   logic                                           s_img_de,
            input   logic   [USER_BITS-1:0]                         s_img_user,
            input   logic   [DATA_WIDTH-1:0]                        s_img_data,
            input   logic                                           s_img_valid,
            
            output  logic                                           m_img_row_first,
            output  logic                                           m_img_row_last,
            output  logic                                           m_img_col_first,
            output  logic                                           m_img_col_last,
            output  logic                                           m_img_de,
            output  logic   [USER_BITS-1:0]                         m_img_user,
            output  logic   [ROWS-1:0][COLS-1:0][DATA_WIDTH-1:0]    m_img_data,
            output  logic                                           m_img_valid
        );
    
    logic                               img_lbuf_row_first;
    logic                               img_lbuf_row_last;
    logic                               img_lbuf_col_first;
    logic                               img_lbuf_col_last;
    logic                               img_lbuf_de;
    logic   [USER_BITS-1:0]             img_lbuf_user;
    logic   [ROWS-1:0][DATA_WIDTH-1:0]  img_lbuf_data;
    logic                               img_lbuf_valid;
    
    jelly2_img_line_buffer
            #(
                .USER_WIDTH             (USER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .ROWS                   (ROWS),
                .ROW_CENTER             (ROW_CENTER),
                .COLS_MAX               (COLS_MAX),
                .BORDER_MODE            (BORDER_MODE),
                .BORDER_VALUE           (BORDER_VALUE),
                .RAM_TYPE               (RAM_TYPE),
                .ENDIAN                 (ENDIAN)
            )
        i_img_line_buffer
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_line_first       (s_img_row_first),
                .s_img_line_last        (s_img_row_last),
                .s_img_pixel_first      (s_img_col_first),
                .s_img_pixel_last       (s_img_col_last),
                .s_img_de               (s_img_de),
                .s_img_user             (s_img_user),
                .s_img_data             (s_img_data),
                .s_img_valid            (s_img_valid),
                
                .m_img_line_first       (img_lbuf_row_first),
                .m_img_line_last        (img_lbuf_row_last),
                .m_img_pixel_first      (img_lbuf_col_first),
                .m_img_pixel_last       (img_lbuf_col_last),
                .m_img_de               (img_lbuf_de),
                .m_img_user             (img_lbuf_user),
                .m_img_data             (img_lbuf_data),
                .m_img_valid            (img_lbuf_valid)
            );
    
    wire                                            img_pbuf_row_first;
    wire                                            img_pbuf_row_last;
    wire                                            img_pbuf_col_first;
    wire                                            img_pbuf_col_last;
    wire                                            img_pbuf_de;
    wire    [USER_BITS-1:0]                         img_pbuf_user;
    wire    [COLS-1:0][ROWS-1:0][DATA_WIDTH-1:0]    img_pbuf_data;
    wire                                            img_pbuf_valid;
    
    jelly2_img_pixel_buffer
            #(
                .USER_WIDTH             (USER_WIDTH),
                .DATA_WIDTH             (ROWS*DATA_WIDTH),
                .PIXEL_NUM              (COLS),
                .PIXEL_CENTER           (COL_CENTER),
                .BORDER_MODE            (BORDER_MODE),
                .BORDER_VALUE           ({ROWS{BORDER_VALUE}}),
                .ENDIAN                 (ENDIAN)
            )
        i_img_pixel_buffer
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_line_first       (img_lbuf_row_first),
                .s_img_line_last        (img_lbuf_row_last),
                .s_img_pixel_first      (img_lbuf_col_first),
                .s_img_pixel_last       (img_lbuf_col_last),
                .s_img_de               (img_lbuf_de),
                .s_img_user             (img_lbuf_user),
                .s_img_data             (img_lbuf_data),
                .s_img_valid            (img_lbuf_valid),
                
                .m_img_line_first       (img_pbuf_row_first),
                .m_img_line_last        (img_pbuf_row_last),
                .m_img_pixel_first      (img_pbuf_col_first),
                .m_img_pixel_last       (img_pbuf_col_last),
                .m_img_de               (img_pbuf_de),
                .m_img_user             (img_pbuf_user),
                .m_img_data             (img_pbuf_data),
                .m_img_valid            (img_pbuf_valid)
            );
    
    assign m_img_row_first = img_pbuf_row_first;
    assign m_img_row_last  = img_pbuf_row_last;
    assign m_img_col_first = img_pbuf_col_first;
    assign m_img_col_last  = img_pbuf_col_last;
    assign m_img_de        = img_pbuf_de;
    assign m_img_user      = img_pbuf_user;
    assign m_img_valid     = img_pbuf_valid;
    
    genvar          x, y;
    generate
    for ( y = 0; y < ROWS; y = y+1 ) begin : y_loop
        for ( x = 0; x < COLS; x = x+1 ) begin : x_loop
            assign m_img_data[(y*COLS+x)*DATA_WIDTH +: DATA_WIDTH] = img_pbuf_data[(x*ROWS+y)*DATA_WIDTH +: DATA_WIDTH];
        end
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
