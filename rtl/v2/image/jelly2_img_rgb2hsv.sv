// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_rgb2hsv
        #(
            parameter   USER_WIDTH = 0,
            parameter   DATA_WIDTH = 8,
            
            parameter   USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                         reset,
            input   wire                         clk,
            input   wire                         cke,
            
            input   wire                         s_img_row_first,
            input   wire                         s_img_row_last,
            input   wire                         s_img_col_first,
            input   wire                         s_img_col_last,
            input   wire                         s_img_de,
            input   wire    [USER_BITS-1:0]      s_img_user,
            input   wire    [DATA_WIDTH-1:0]     s_img_r,
            input   wire    [DATA_WIDTH-1:0]     s_img_g,
            input   wire    [DATA_WIDTH-1:0]     s_img_b,
            input   wire                         s_img_valid,
            
            output  wire                         m_img_row_first,
            output  wire                         m_img_row_last,
            output  wire                         m_img_col_first,
            output  wire                         m_img_col_last,
            output  wire                         m_img_de,
            output  wire    [USER_BITS-1:0]      m_img_user,
            output  wire    [DATA_WIDTH-1:0]     m_img_h,
            output  wire    [DATA_WIDTH-1:0]     m_img_s,
            output  wire    [DATA_WIDTH-1:0]     m_img_v,
            output  wire                         m_img_valid
        );
    
    logic                       m_row_first;
    logic                       m_row_last;
    logic                       m_col_first;
    logic                       m_col_last;
    logic                       m_de;
    logic   [USER_BITS-1:0]     m_user;
    logic   [DATA_WIDTH-1:0]    m_h;
    logic   [DATA_WIDTH-1:0]    m_s;
    logic   [DATA_WIDTH-1:0]    m_v;
    logic                       m_valid;

    jelly2_rgb2hsv
            #(
                .USER_WIDTH     (USER_BITS+5),
                .DATA_WIDTH     (DATA_WIDTH)
            )
        i_rgb2hsv
            (
                .reset,
                .clk,
                .cke,
                
                .s_user         ({
                                    s_img_user,
                                    s_img_row_first,
                                    s_img_row_last,
                                    s_img_col_first,
                                    s_img_col_last,
                                    s_img_de
                                }),
                .s_r            (s_img_r),
                .s_g            (s_img_g),
                .s_b            (s_img_b),
                .s_valid        (s_img_valid),
                
                .m_user         ({
                                    m_user,
                                    m_row_first,
                                    m_row_last,
                                    m_col_first,
                                    m_col_last,
                                    m_de
                                }),
                .m_h            (m_h),
                .m_s            (m_s),
                .m_v            (m_v),
                .m_valid        (m_valid)
            );

    assign m_img_row_first = m_row_first  & m_valid;
    assign m_img_row_last  = m_row_last   & m_valid;
    assign m_img_col_first = m_col_first & m_valid;
    assign m_img_col_last  = m_col_last  & m_valid;
    assign m_img_de        = m_de          & m_valid;
    assign m_img_user      = m_user;
    assign m_img_h         = m_h;
    assign m_img_s         = m_s;
    assign m_img_v         = m_v;
    assign m_img_valid     = m_valid;


endmodule


`default_nettype wire


// end of file
