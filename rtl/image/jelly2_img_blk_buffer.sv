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
            parameter   int                         M            = 3,   // block width
            parameter   int                         N            = 3,   // block height
            parameter   int                         USER_WIDTH   = 0,
            parameter   int                         DATA_WIDTH   = 8,
            parameter   int                         CENTER_X     = (M-1) / 2,
            parameter   int                         CENTER_Y     = (N-1) / 2,
            parameter   int                         MAX_COLS     = 1024,
            parameter                               BORDER_MODE  = "REFLECT_101",   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}},
            parameter                               RAM_TYPE     = "block",
            parameter   bit                         ENDIAN       = 0,               // 0: little, 1:big
            
            localparam  int                         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,
            input   wire                                    cke,
            
            input   wire                                    s_img_row_first,
            input   wire                                    s_img_row_last,
            input   wire                                    s_img_col_first,
            input   wire                                    s_img_col_last,
            input   wire                                    s_img_de,
            input   wire    [USER_BITS-1:0]                 s_img_user,
            input   wire    [DATA_WIDTH-1:0]                s_img_data,
            input   wire                                    s_img_valid,
            
            output  wire                                    m_img_row_first,
            output  wire                                    m_img_row_last,
            output  wire                                    m_img_col_first,
            output  wire                                    m_img_col_last,
            output  wire                                    m_img_de,
            output  wire    [USER_BITS-1:0]                 m_img_user,
            output  wire    [N-1:0][M-1:0][DATA_WIDTH-1:0]  m_img_data,
            output  wire                                    m_img_valid
        );
    
    logic                               img_lbuf_row_first;
    logic                               img_lbuf_row_last;
    logic                               img_lbuf_col_first;
    logic                               img_lbuf_col_last;
    logic                               img_lbuf_de;
    logic   [USER_BITS-1:0]             img_lbuf_user;
    logic   [N-1:0][DATA_WIDTH-1:0]     img_lbuf_data;
    logic                               img_lbuf_valid;
    
    jelly2_img_line_buffer
            #(
                .N                      (N),
                .USER_WIDTH             (USER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .CENTER                 (CENTER_Y),
                .MAX_COLS               (MAX_COLS),
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
                
                .s_img_row_first        (s_img_row_first),
                .s_img_row_last         (s_img_row_last),
                .s_img_col_first        (s_img_col_first),
                .s_img_col_last         (s_img_col_last),
                .s_img_de               (s_img_de),
                .s_img_user             (s_img_user),
                .s_img_data             (s_img_data),
                .s_img_valid            (s_img_valid),
                
                .m_img_row_first        (img_lbuf_row_first),
                .m_img_row_last         (img_lbuf_row_last),
                .m_img_col_first        (img_lbuf_col_first),
                .m_img_col_last         (img_lbuf_col_last),
                .m_img_de               (img_lbuf_de),
                .m_img_user             (img_lbuf_user),
                .m_img_data             (img_lbuf_data),
                .m_img_valid            (img_lbuf_valid)
            );
    
    wire                                      img_pbuf_row_first;
    wire                                      img_pbuf_row_last;
    wire                                      img_pbuf_col_first;
    wire                                      img_pbuf_col_last;
    wire                                      img_pbuf_de;
    wire    [USER_BITS-1:0]                   img_pbuf_user;
    wire    [M-1:0][N-1:0][DATA_WIDTH-1:0]    img_pbuf_data;
    wire                                      img_pbuf_valid;
    
    jelly2_img_pixel_buffer
            #(
                .M                      (M),
                .USER_WIDTH             (USER_WIDTH),
                .DATA_WIDTH             (N*DATA_WIDTH),
                .CENTER                 (CENTER_X),
                .BORDER_MODE            (BORDER_MODE),
                .BORDER_VALUE           ({N{BORDER_VALUE}}),
                .ENDIAN                 (ENDIAN)
            )
        i_img_pixel_buffer
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_row_first        (img_lbuf_row_first),
                .s_img_row_last         (img_lbuf_row_last),
                .s_img_col_first        (img_lbuf_col_first),
                .s_img_col_last         (img_lbuf_col_last),
                .s_img_de               (img_lbuf_de),
                .s_img_user             (img_lbuf_user),
                .s_img_data             (img_lbuf_data),
                .s_img_valid            (img_lbuf_valid),
                
                .m_img_row_first        (img_pbuf_row_first),
                .m_img_row_last         (img_pbuf_row_last),
                .m_img_col_first        (img_pbuf_col_first),
                .m_img_col_last         (img_pbuf_col_last),
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
    
    generate
    for ( genvar y = 0; y < N; y = y+1 ) begin : y_loop
        for ( genvar x = 0; x < M; x = x+1 ) begin : x_loop
            assign m_img_data[y][x] = img_pbuf_data[x][y];
        end
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
