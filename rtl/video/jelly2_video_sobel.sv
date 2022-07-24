// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Sobel filter
module jelly2_video_sobel
        #(
            parameter   bit                         SIZE_AUTO      = 1,
            parameter   int                         TUSER_WIDTH    = 1,
            parameter   int                         DATA_WIDTH     = 8,
            parameter   int                         GRAD_X_WIDTH   = DATA_WIDTH,
            parameter   int                         GRAD_Y_WIDTH   = DATA_WIDTH,
            parameter   int                         IMG_X_WIDTH    = 10,
            parameter   int                         IMG_Y_WIDTH    = 9,
            parameter   int                         MAX_X_NUM      = 4096,
            parameter                               RAM_TYPE       = "block",
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
            input   wire    [DATA_WIDTH-1:0]        s_axi4s_tdata,
            input   wire                            s_axi4s_tvalid,
            output  wire                            s_axi4s_tready,
            
            output  wire    [TUSER_WIDTH-1:0]       m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [GRAD_X_WIDTH-1:0]      m_axi4s_tdata_dx,
            output  wire    [GRAD_Y_WIDTH-1:0]      m_axi4s_tdata_dy,
            output  wire    [DATA_WIDTH-1:0]        m_axi4s_tdata,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready
        );

    // axi4 -> img    
    logic                               img_cke;
    
    logic                               img_src_row_first;
    logic                               img_src_row_last;
    logic                               img_src_col_first;
    logic                               img_src_col_last;
    logic                               img_src_de;
    logic   [TUSER_WIDTH-1:0]           img_src_user;
    logic   [DATA_WIDTH-1:0]            img_src_data;
    logic                               img_src_valid;

    logic                               img_sink_row_first;
    logic                               img_sink_row_last;
    logic                               img_sink_col_first;
    logic                               img_sink_col_last;
    logic                               img_sink_de;
    logic   [TUSER_WIDTH-1:0]           img_sink_user;
    logic   [DATA_WIDTH-1:0]            img_sink_data;
    logic   [GRAD_X_WIDTH-1:0]          img_sink_grad_x;
    logic   [GRAD_Y_WIDTH-1:0]          img_sink_grad_y;
    logic                               img_sink_valid;

    jelly2_axi4s_img
            #(
                .SIZE_AUTO              (SIZE_AUTO),
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (DATA_WIDTH),
                .M_TDATA_WIDTH          (DATA_WIDTH+GRAD_Y_WIDTH+GRAD_X_WIDTH),
                .IMG_X_WIDTH            (IMG_X_WIDTH),
                .IMG_Y_WIDTH            (IMG_Y_WIDTH),
                .BLANK_Y_WIDTH          (3),
                .WITH_DE                (1'b1),
                .WITH_VALID             (1'b1),
                .IMG_CKE_BUFG           (1'b0),
                .INIT_Y_NUM             (INIT_Y_NUM),
                .FIFO_PTR_WIDTH         (FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE          (FIFO_RAM_TYPE)
            )
        i_axi4s_img
            (
                .aresetn,
                .aclk,
                .aclken,
                
                .param_img_width,
                .param_img_height,
                .param_blank_height     (3'd3),
                
                .s_axi4s_tuser,
                .s_axi4s_tlast,
                .s_axi4s_tdata,
                .s_axi4s_tvalid,
                .s_axi4s_tready,
                
                .m_axi4s_tuser,
                .m_axi4s_tlast,
                .m_axi4s_tdata          ({m_axi4s_tdata, m_axi4s_tdata_dy, m_axi4s_tdata_dx}),
                .m_axi4s_tvalid,
                .m_axi4s_tready,
                
                
                .img_cke,
                .m_img_src_row_first    (img_src_row_first),
                .m_img_src_row_last     (img_src_row_last),
                .m_img_src_col_first    (img_src_col_first),
                .m_img_src_col_last     (img_src_col_last),
                .m_img_src_de           (img_src_de),
                .m_img_src_user         (img_src_user),
                .m_img_src_data         (img_src_data),
                .m_img_src_valid        (img_src_valid),
                .s_img_sink_row_first   (img_sink_row_first),
                .s_img_sink_row_last    (img_sink_row_last),
                .s_img_sink_col_first   (img_sink_col_first),
                .s_img_sink_col_last    (img_sink_col_last),
                .s_img_sink_de          (img_sink_de),
                .s_img_sink_user        (img_sink_user),
                .s_img_sink_data        (img_sink_data),
                .s_img_sink_valid       (img_sink_valid)
            );
    

    // demosaic with ACPI
    jelly_img_sobel_core
            #(
                .USER_WIDTH             (TUSER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .GRAD_X_WIDTH           (GRAD_X_WIDTH),
                .GRAD_Y_WIDTH           (GRAD_Y_WIDTH),
                .MAX_X_NUM              (MAX_X_NUM),
                .RAM_TYPE               (RAM_TYPE),
                .USE_VALID              (1)
            )
        i_img_sobel_core
            (
                .reset                  (~aresetn),
                .clk                    (aclk),
                .cke                    (img_cke),

                .s_img_line_first       (img_src_row_first),
                .s_img_line_last        (img_src_row_last),
                .s_img_pixel_first      (img_src_col_first),
                .s_img_pixel_last       (img_src_col_last),
                .s_img_de               (img_src_de),
                .s_img_user             (img_src_user),
                .s_img_data             (img_src_data),
                .s_img_valid            (img_src_valid),

                .m_img_line_first       (img_sink_row_first),
                .m_img_line_last        (img_sink_row_last),
                .m_img_pixel_first      (img_sink_col_first),
                .m_img_pixel_last       (img_sink_col_last),
                .m_img_de               (img_sink_de),
                .m_img_user             (img_sink_user),
                .m_img_data             (img_sink_data),
                .m_img_grad_x           (img_sink_grad_x),
                .m_img_grad_y           (img_sink_grad_y),
                .m_img_valid            (img_sink_valid )
            );
    
endmodule


`default_nettype wire


// end of file
