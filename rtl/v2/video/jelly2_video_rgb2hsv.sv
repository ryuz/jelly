// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_video_rgb2hsv
        #(
            parameter   bit                         SIZE_AUTO      = 0,
            parameter   int                         TUSER_WIDTH    = 1,
            parameter   int                         DATA_WIDTH     = 8,
            parameter   int                         IMG_X_WIDTH    = 10,
            parameter   int                         IMG_Y_WIDTH    = 9,
            parameter   bit     [IMG_Y_WIDTH-1:0]   INIT_Y_NUM     = 480,
            parameter   int                         FIFO_PTR_WIDTH = IMG_X_WIDTH,
            parameter                               FIFO_RAM_TYPE  = "block"
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            input   wire                            aclken,

            input   wire    [IMG_X_WIDTH-1:0]       param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]       param_img_height,
            
            input   wire    [TUSER_WIDTH-1:0]       s_axi4s_tuser,
            input   wire                            s_axi4s_tlast,
            input   wire    [DATA_WIDTH-1:0]        s_axi4s_tdata_r,
            input   wire    [DATA_WIDTH-1:0]        s_axi4s_tdata_g,
            input   wire    [DATA_WIDTH-1:0]        s_axi4s_tdata_b,
            input   wire                            s_axi4s_tvalid,
            output  wire                            s_axi4s_tready,
            
            output  wire    [TUSER_WIDTH-1:0]       m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata_h,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata_s,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata_v,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata_r,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata_g,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata_b,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready
        );

    jelly2_rgb2hsv
            #(
                .USER_WIDTH     (DATA_WIDTH*3+TUSER_WIDTH+1),
                .DATA_WIDTH     (DATA_WIDTH)
            )
        i_rgb2hsv
            (
                .reset          (~aresetn),
                .clk            (aclk),
                .cke            (aclken & s_axi4s_tready),
                
                .s_user         ({s_axi4s_tdata_b, s_axi4s_tdata_g, s_axi4s_tdata_r, s_axi4s_tuser, s_axi4s_tlast}),
                .s_r            (s_axi4s_tdata_r),
                .s_g            (s_axi4s_tdata_g),
                .s_b            (s_axi4s_tdata_b),
                .s_valid        (s_axi4s_tvalid),
                
                .m_user         ({m_axi4s_tdata_b, m_axi4s_tdata_g, m_axi4s_tdata_r, m_axi4s_tuser, m_axi4s_tlast}),
                .m_h            (m_axi4s_tdata_h),
                .m_s            (m_axi4s_tdata_s),
                .m_v            (m_axi4s_tdata_v),
                .m_valid        (m_axi4s_tvalid)
            );
    
    assign s_axi4s_tready = !m_axi4s_tvalid || m_axi4s_tready;

endmodule


`default_nettype wire


// end of file
