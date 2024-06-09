// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_sobel_core
        #(
            parameter   int                         USER_WIDTH   = 0,
            parameter   int                         DATA_WIDTH   = 8,
            parameter   int                         GRAD_X_WIDTH = DATA_WIDTH,
            parameter   int                         GRAD_Y_WIDTH = DATA_WIDTH,
            parameter                               BORDER_MODE  = "REFLECT_101",   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   bit     [DATA_WIDTH-1:0]    BORDER_VALUE = '0,
            parameter   int                         MAX_COLS     = 1024,
            parameter                               RAM_TYPE     = "block",
            parameter   bit                         USE_VALID    = 0,
            parameter   bit                         SIGNED       = 0,
            
            localparam  int                         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire                                s_img_row_first,
            input   wire                                s_img_row_last,
            input   wire                                s_img_col_first,
            input   wire                                s_img_col_last,
            input   wire                                s_img_de,
            input   wire            [USER_BITS-1:0]     s_img_user,
            input   wire            [DATA_WIDTH-1:0]    s_img_data,
            input   wire                                s_img_valid,
            
            output  wire                                m_img_row_first,
            output  wire                                m_img_row_last,
            output  wire                                m_img_col_first,
            output  wire                                m_img_col_last,
            output  wire                                m_img_de,
            output  wire            [USER_BITS-1:0]     m_img_user,
            output  wire            [DATA_WIDTH-1:0]    m_img_data,
            output  wire    signed  [GRAD_X_WIDTH-1:0]  m_img_grad_x,
            output  wire    signed  [GRAD_Y_WIDTH-1:0]  m_img_grad_y,
            output  wire                                m_img_valid
        );
    
    
    logic                               img_blk_row_first;
    logic                               img_blk_row_last;
    logic                               img_blk_col_first;
    logic                               img_blk_col_last;
    logic   [USER_BITS-1:0]             img_blk_user;
    logic                               img_blk_de;
    logic   [2:0][2:0][DATA_WIDTH-1:0]  img_blk_data;
    logic                               img_blk_valid;
    
    jelly2_img_blk_buffer
            #(
                .M                  (3),
                .N                  (3),
                .USER_WIDTH         (0),
                .DATA_WIDTH         (8),
                .CENTER_X           (1),
                .CENTER_Y           (1),
                .MAX_COLS           (MAX_COLS),
                .BORDER_MODE        (BORDER_MODE),
                .BORDER_VALUE       (BORDER_VALUE),
                .RAM_TYPE           (RAM_TYPE),
                .ENDIAN             (0)
            )
        i_img_blk_buffer
            (
                .reset,
                .clk,
                .cke,
                
                .s_img_row_first,
                .s_img_row_last,
                .s_img_col_first,
                .s_img_col_last,
                .s_img_de,
                .s_img_user,
                .s_img_data,
                .s_img_valid,
                
                .m_img_row_first    (img_blk_row_first),
                .m_img_row_last     (img_blk_row_last),
                .m_img_col_first    (img_blk_col_first),
                .m_img_col_last     (img_blk_col_last),
                .m_img_de           (img_blk_de),
                .m_img_user         (img_blk_user),
                .m_img_data         (img_blk_data),
                .m_img_valid        (img_blk_valid)
            );

    jelly2_img_sobel_calc
            #(
                .DATA_WIDTH         (DATA_WIDTH),
                .GRAD_X_WIDTH       (GRAD_X_WIDTH),
                .GRAD_Y_WIDTH       (GRAD_Y_WIDTH)
            )
        i_img_sobel_calc
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .in_data            (img_blk_data),
                
                .out_data           (m_img_data),
                .out_grad_x         (m_img_grad_x),
                .out_grad_y         (m_img_grad_y)
            );
    
    jelly2_img_delay
            #(
                .USER_WIDTH         (USER_WIDTH),
                .LATENCY            (5),
                .USE_VALID          (USE_VALID)
            )
        i_img_delay
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_img_row_first    (img_blk_row_first),
                .s_img_row_last     (img_blk_row_last),
                .s_img_col_first    (img_blk_col_first),
                .s_img_col_last     (img_blk_col_last),
                .s_img_de           (img_blk_de),
                .s_img_user         (img_blk_user),
                .s_img_valid        (img_blk_valid),
                
                .m_img_row_first    (m_img_row_first),
                .m_img_row_last     (m_img_row_last),
                .m_img_col_first    (m_img_col_first),
                .m_img_col_last     (m_img_col_last),
                .m_img_de           (m_img_de),
                .m_img_user         (m_img_user),
                .m_img_valid        (m_img_valid)
            );
    
endmodule


`default_nettype wire


// end of file
