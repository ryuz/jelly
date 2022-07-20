// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module image_processing
        #(
            parameter   WB_ADR_WIDTH  = 16,
            parameter   WB_DAT_WIDTH  = 32,
            parameter   WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            
            parameter   S_DATA_WIDTH  = 10,
            parameter   M_DATA_WIDTH  = 8,
            
            parameter   IMG_X_WIDTH   = 12,
            parameter   IMG_Y_WIDTH   = 12,
            
            parameter   TUSER_WIDTH   = 1,
            parameter   S_TDATA_WIDTH = S_DATA_WIDTH,
            parameter   M_TDATA_WIDTH = 4*M_DATA_WIDTH,
            
            parameter   DEVICE        = "RTL"
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            input   wire                        aclken,
            
            input   wire                        in_update_req,

            input   wire    [IMG_X_WIDTH-1:0]   param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]   param_img_height,
                        
            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            
            input   wire    [TUSER_WIDTH-1:0]   s_axi4s_tuser,
            input   wire                        s_axi4s_tlast,
            input   wire    [S_TDATA_WIDTH-1:0] s_axi4s_tdata,
            input   wire                        s_axi4s_tvalid,
            output  wire                        s_axi4s_tready,
            
            output  wire    [TUSER_WIDTH-1:0]   m_axi4s_tuser,
            output  wire                        m_axi4s_tlast,
            output  wire    [M_TDATA_WIDTH-1:0] m_axi4s_tdata,
            output  wire                        m_axi4s_tvalid,
            input   wire                        m_axi4s_tready,

            output  wire                        m_moment_first,
            output  wire                        m_moment_last,
            output  wire   [M0_WIDTH-1:0]       m_moment_m0,
            output  wire   [M1_WIDTH-1:0]       m_moment_m1,
            output  wire                        m_moment_valid
        );
    
    
    localparam  USE_VALID  = 1;
    localparam  DATA_WIDTH = S_DATA_WIDTH;
    
    wire                                reset = ~aresetn;
    wire                                clk   = aclk;
    wire                                cke;
    
    wire                                img_src_row_first;
    wire                                img_src_row_last;
    wire                                img_src_col_first;
    wire                                img_src_col_last;
    wire                                img_src_de;
    wire    [S_TDATA_WIDTH-1:0]         img_src_data;
    wire                                img_src_valid;
    
    wire                                img_sink_row_first;
    wire                                img_sink_row_last;
    wire                                img_sink_col_first;
    wire                                img_sink_col_last;
    wire                                img_sink_de;
    wire    [M_TDATA_WIDTH-1:0]         img_sink_data;
    wire                                img_sink_valid;
    
    // img
    jelly2_axi4s_img_simple
            #(
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (S_TDATA_WIDTH),
                .M_TDATA_WIDTH          (M_TDATA_WIDTH),
                .IMG_X_WIDTH            (IMG_X_WIDTH),
                .IMG_Y_WIDTH            (IMG_Y_WIDTH),
                .BLANK_Y_WIDTH          (4),
                .WITH_DE                (1'b1),
                .WITH_VALID             (USE_VALID),
                .IMG_CKE_BUFG           (1'b0)
            )
        i_axi4s_img_simple
            (
                .aresetn                (aresetn),
                .aclk                   (aclk),
                .aclken                 (aclken),

                .param_img_width        (param_img_width),
                .param_img_height       (param_img_height),
                .param_blank_height     (4'd5),

                .s_axi4s_tdata          (s_axi4s_tdata),
                .s_axi4s_tlast          (s_axi4s_tlast),
                .s_axi4s_tuser          (s_axi4s_tuser),
                .s_axi4s_tvalid         (s_axi4s_tvalid),
                .s_axi4s_tready         (s_axi4s_tready),
                
                .m_axi4s_tdata          (m_axi4s_tdata),
                .m_axi4s_tlast          (m_axi4s_tlast),
                .m_axi4s_tuser          (m_axi4s_tuser),
                .m_axi4s_tvalid         (m_axi4s_tvalid),
                .m_axi4s_tready         (m_axi4s_tready),
                
                
                .img_cke                (cke),
                
                .m_img_src_row_first    (img_src_row_first),
                .m_img_src_row_last     (img_src_row_last),
                .m_img_src_col_first    (img_src_col_first),
                .m_img_src_col_last     (img_src_col_last),
                .m_img_src_de           (img_src_de),
                .m_img_src_user         (),
                .m_img_src_data         (img_src_data),
                .m_img_src_valid        (img_src_valid),
                
                .s_img_sink_row_first   (img_sink_row_first),
                .s_img_sink_row_last    (img_sink_row_last),
                .s_img_sink_col_first   (img_sink_col_first),
                .s_img_sink_col_last    (img_sink_col_last),
                .s_img_sink_user        (1'b0),
                .s_img_sink_de          (img_sink_de),
                .s_img_sink_data        (img_sink_data),
                .s_img_sink_valid       (img_sink_valid)
            );
    
    
    // demosaic
    wire                                img_demos_row_first;
    wire                                img_demos_row_last;
    wire                                img_demos_col_first;
    wire                                img_demos_col_last;
    wire                                img_demos_de;
    wire    [DATA_WIDTH-1:0]            img_demos_raw;
    wire    [DATA_WIDTH-1:0]            img_demos_r;
    wire    [DATA_WIDTH-1:0]            img_demos_g;
    wire    [DATA_WIDTH-1:0]            img_demos_b;
    wire                                img_demos_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_demos_dat_o;
    wire                                wb_demos_stb_i;
    wire                                wb_demos_ack_o;
    
    jelly_img_demosaic_acpi
            #(
                .USER_WIDTH             (TUSER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .MAX_X_NUM              (4096),
                .RAM_TYPE               ("block"),
                .USE_VALID              (USE_VALID),
                
                .WB_ADR_WIDTH           (6),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_PHASE       (2'b11)
            )
        i_img_demosaic_acpi
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[5:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_demos_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_demos_stb_i),
                .s_wb_ack_o             (wb_demos_ack_o),
                
                .s_img_line_first       (img_src_row_first),
                .s_img_line_last        (img_src_row_last),
                .s_img_pixel_first      (img_src_col_first),
                .s_img_pixel_last       (img_src_col_last),
                .s_img_de               (img_src_de),
                .s_img_user             (1'b0),
                .s_img_raw              (img_src_data),
                .s_img_valid            (img_src_valid),
                
                .m_img_line_first       (img_demos_row_first),
                .m_img_line_last        (img_demos_row_last),
                .m_img_pixel_first      (img_demos_col_first),
                .m_img_pixel_last       (img_demos_col_last),
                .m_img_de               (img_demos_de),
                .m_img_user             (),
                .m_img_raw              (img_demos_raw),
                .m_img_r                (img_demos_r),
                .m_img_g                (img_demos_g),
                .m_img_b                (img_demos_b),
                .m_img_valid            (img_demos_valid)
            );
    

    // color matrix
    wire                                img_colmat_row_first;
    wire                                img_colmat_row_last;
    wire                                img_colmat_col_first;
    wire                                img_colmat_col_last;
    wire                                img_colmat_de;
    wire    [DATA_WIDTH-1:0]            img_colmat_raw;
    wire    [DATA_WIDTH-1:0]            img_colmat_r;
    wire    [DATA_WIDTH-1:0]            img_colmat_g;
    wire    [DATA_WIDTH-1:0]            img_colmat_b;
    wire                                img_colmat_valid;

    wire    [WB_DAT_WIDTH-1:0]          wb_colmat_dat_o;
    wire                                wb_colmat_stb_i;
    wire                                wb_colmat_ack_o;
    
    jelly_img_color_matrix
            #(
                .USER_WIDTH             (DATA_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .INTERNAL_WIDTH         (DATA_WIDTH+2),
                
                .COEFF_INT_WIDTH        (9),
                .COEFF_FRAC_WIDTH       (16),
                .COEFF3_INT_WIDTH       (9),
                .COEFF3_FRAC_WIDTH      (16),
                .STATIC_COEFF           (1),
                .DEVICE                 (DEVICE),
                
                .WB_ADR_WIDTH           (6),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_MATRIX00    (2 << 16),
                .INIT_PARAM_MATRIX01    (0),
                .INIT_PARAM_MATRIX02    (0),
                .INIT_PARAM_MATRIX03    (0),
                .INIT_PARAM_MATRIX10    (0),
                .INIT_PARAM_MATRIX11    (1 << 16),
                .INIT_PARAM_MATRIX12    (0),
                .INIT_PARAM_MATRIX13    (0),
                .INIT_PARAM_MATRIX20    (0),
                .INIT_PARAM_MATRIX21    (0),
                .INIT_PARAM_MATRIX22    (2 << 16),
                .INIT_PARAM_MATRIX23    (0),
                .INIT_PARAM_CLIP_MIN0   ({DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX0   ({DATA_WIDTH{1'b1}}),
                .INIT_PARAM_CLIP_MIN1   ({DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX1   ({DATA_WIDTH{1'b1}}),
                .INIT_PARAM_CLIP_MIN2   ({DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX2   ({DATA_WIDTH{1'b1}})
            )
        i_img_color_matrix
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[5:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_colmat_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_colmat_stb_i),
                .s_wb_ack_o             (wb_colmat_ack_o),
                
                .s_img_line_first       (img_demos_row_first),
                .s_img_line_last        (img_demos_row_last),
                .s_img_pixel_first      (img_demos_col_first),
                .s_img_pixel_last       (img_demos_col_last),
                .s_img_de               (img_demos_de),
                .s_img_user             (img_demos_raw),
                .s_img_color0           (img_demos_r),
                .s_img_color1           (img_demos_g),
                .s_img_color2           (img_demos_b),
                .s_img_valid            (img_demos_valid),
                
                .m_img_line_first       (img_colmat_row_first),
                .m_img_line_last        (img_colmat_row_last),
                .m_img_pixel_first      (img_colmat_col_first),
                .m_img_pixel_last       (img_colmat_col_last),
                .m_img_de               (img_colmat_de),
                .m_img_user             (img_colmat_raw),
                .m_img_color0           (img_colmat_r),
                .m_img_color1           (img_colmat_g),
                .m_img_color2           (img_colmat_b),
                .m_img_valid            (img_colmat_valid)
            );


    // gauss
    logic                               img_gauss_row_first;
    logic                               img_gauss_row_last;
    logic                               img_gauss_col_first;
    logic                               img_gauss_col_last;
    logic                               img_gauss_de;
    logic   [DATA_WIDTH-1:0]            img_gauss_raw;
    logic   [DATA_WIDTH-1:0]            img_gauss_r;
    logic   [DATA_WIDTH-1:0]            img_gauss_g;
    logic   [DATA_WIDTH-1:0]            img_gauss_b;
    logic                               img_gauss_valid;
    
    logic   [WB_DAT_WIDTH-1:0]          wb_gauss_dat_o;
    logic                               wb_gauss_stb_i;
    logic                               wb_gauss_ack_o;

    jelly_img_gaussian_3x3
            #(
                .NUM                    (1),
                .USER_WIDTH             (DATA_WIDTH),
                .COMPONENTS             (3),
                .DATA_WIDTH             (DATA_WIDTH),
                .MAX_X_NUM              (4096),
                .RAM_TYPE               ("block"),
                .USE_VALID              (USE_VALID),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .INIT_CTL_CONTROL       (3'b000),
                .INIT_PARAM_ENABLE      (0)
            )
        i_img_gaussian_3x3
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),

                .in_update_req          (in_update_req),

                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_gauss_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_gauss_stb_i),
                .s_wb_ack_o             (wb_gauss_ack_o),

                .s_img_line_first       (img_colmat_row_first),
                .s_img_line_last        (img_colmat_row_last),
                .s_img_pixel_first      (img_colmat_col_first),
                .s_img_pixel_last       (img_colmat_col_last),
                .s_img_de               (img_colmat_de),
                .s_img_user             (img_colmat_raw),
                .s_img_data             ({img_colmat_r, img_colmat_g, img_colmat_b}),
                .s_img_valid            (img_colmat_valid),

                .m_img_line_first       (img_gauss_row_first),
                .m_img_line_last        (img_gauss_row_last),
                .m_img_pixel_first      (img_gauss_col_first),
                .m_img_pixel_last       (img_gauss_col_last),
                .m_img_de               (img_gauss_de),
                .m_img_user             (img_gauss_raw),
                .m_img_data             ({img_gauss_r, img_gauss_g, img_gauss_b}),
                .m_img_valid            (img_gauss_valid)
            );


    // rgb hsv
    logic                               img_hsv_row_first;
    logic                               img_hsv_row_last;
    logic                               img_hsv_col_first;
    logic                               img_hsv_col_last;
    logic                               img_hsv_de;
    logic   [DATA_WIDTH-1:0]            img_hsv_raw;
    logic   [DATA_WIDTH-1:0]            img_hsv_h;
    logic   [DATA_WIDTH-1:0]            img_hsv_s;
    logic   [DATA_WIDTH-1:0]            img_hsv_v;
    logic                               img_hsv_valid;
    
    jelly2_img_rgb2hsv
            #(
                .USER_WIDTH             (DATA_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH)
            )
        i_img_rgb2hsv
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_row_first        (img_colmat_row_first),
                .s_img_row_last         (img_colmat_row_last),
                .s_img_col_first        (img_colmat_col_first),
                .s_img_col_last         (img_colmat_col_last ),
                .s_img_de               (img_colmat_de),
                .s_img_user             (img_colmat_raw),
                .s_img_r                (img_colmat_r),
                .s_img_g                (img_colmat_g),
                .s_img_b                (img_colmat_b),
                .s_img_valid            (img_colmat_valid),

                .m_img_row_first        (img_hsv_row_first),
                .m_img_row_last         (img_hsv_row_last),
                .m_img_col_first        (img_hsv_col_first),
                .m_img_col_last         (img_hsv_col_last),
                .m_img_de               (img_hsv_de),
                .m_img_user             (img_hsv_raw),
                .m_img_h                (img_hsv_h),
                .m_img_s                (img_hsv_s),
                .m_img_v                (img_hsv_v),
                .m_img_valid            (img_hsv_valid)
            );
    

    // binarize
    logic                               img_bin_row_first;
    logic                               img_bin_row_last;
    logic                               img_bin_col_first;
    logic                               img_bin_col_last;
    logic                               img_bin_de;
    logic   [0:0]                       img_bin_data;
    logic                               img_bin_valid;
    
    logic   [WB_DAT_WIDTH-1:0]          wb_bin_dat_o;
    logic                               wb_bin_stb_i;
    logic                               wb_bin_ack_o;

    jelly2_img_binarizer
            #(
                .USER_WIDTH             (0),
                .S_COMPONENTS           (3),
                .S_DATA_WIDTH           (DATA_WIDTH),
                .M_COMPONENTS           (1),
                .M_DATA_WIDTH           (1),
                .WRAP_AROUND            (1'b1),
                .USE_VALID              (USE_VALID),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .INIT_CTL_CONTROL       (2'b11),
                .INIT_PARAM_OR          (1'b0),
                .INIT_PARAM_TH0         ('0),
                .INIT_PARAM_TH1         ('1),
                .INIT_PARAM_INV         ('0),
                .INIT_PARAM_VAL0        ('0),
                .INIT_PARAM_VAL1        ('1)
            )
        i_img_binarize
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),

                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_bin_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_bin_stb_i),
                .s_wb_ack_o             (wb_bin_ack_o),

                .s_img_row_first        (img_hsv_row_first),
                .s_img_row_last         (img_hsv_row_last),
                .s_img_col_first        (img_hsv_col_first),
                .s_img_col_last         (img_hsv_col_last),
                .s_img_de               (img_hsv_de),
                .s_img_user             (1'b0),
                .s_img_data             ({img_hsv_v, img_hsv_s, img_hsv_h}),
                .s_img_valid            (img_hsv_valid),

                .m_img_row_first        (img_bin_row_first),
                .m_img_row_last         (img_bin_row_last ),
                .m_img_col_first        (img_bin_col_first),
                .m_img_col_last         (img_bin_col_last ),
                .m_img_de               (img_bin_de),
                .m_img_user             (),
                .m_img_data             (img_bin_data),
                .m_img_valid            (img_bin_valid)
            );



    jelly2_img_line_moment
            #(
                .M0_WIDTH               (12),
                .M1_WIDTH               (20)
            )
        i_img_line_moment
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),

                .s_img_row_first        (s_img_row_first),
                .s_img_row_last         (s_img_row_last),
                .s_img_col_first        (s_img_col_first),
                .s_img_col_last         (s_img_col_last),
                .s_img_de               (s_img_de),
                .s_img_data             (s_img_data),
                .s_img_valid            (s_img_valid),

                .m_moment_first         (m_moment_first),
                .m_moment_last          (m_moment_last),
                .m_moment_m0            (m_moment_m0),
                .m_moment_m1            (m_moment_m1),
                .m_moment_valid         (m_moment_valid)
            );

    
    // select
    localparam      S_NUM = 5;

    logic   [S_NUM-1:0]                         img_sel_in_row_first;
    logic   [S_NUM-1:0]                         img_sel_in_row_last;
    logic   [S_NUM-1:0]                         img_sel_in_col_first;
    logic   [S_NUM-1:0]                         img_sel_in_col_last;
    logic   [S_NUM-1:0]                         img_sel_in_de;
    logic   [S_NUM-1:0][3:0][M_DATA_WIDTH-1:0]  img_sel_in_data;
    logic   [S_NUM-1:0]                         img_sel_in_valid;

    assign img_sel_in_row_first[0]    = img_src_row_first;
    assign img_sel_in_row_last [0]    = img_src_row_last;
    assign img_sel_in_col_first[0]    = img_src_col_first;
    assign img_sel_in_col_last [0]    = img_src_col_last;
    assign img_sel_in_de       [0]    = img_src_de;
    assign img_sel_in_data     [0]    = M_TDATA_WIDTH'(img_src_data);
    assign img_sel_in_valid    [0]    = img_src_valid;

    assign img_sel_in_row_first[1]    = img_colmat_row_first;
    assign img_sel_in_row_last [1]    = img_colmat_row_last;
    assign img_sel_in_col_first[1]    = img_colmat_col_first;
    assign img_sel_in_col_last [1]    = img_colmat_col_last;
    assign img_sel_in_de       [1]    = img_colmat_de;
    assign img_sel_in_data     [1][0] = img_colmat_b[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [1][1] = img_colmat_g[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [1][2] = img_colmat_r[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [1][3] = '0;
    assign img_sel_in_valid    [1]    = img_colmat_valid;

    assign img_sel_in_row_first[2]    = img_gauss_row_first;
    assign img_sel_in_row_last [2]    = img_gauss_row_last;
    assign img_sel_in_col_first[2]    = img_gauss_col_first;
    assign img_sel_in_col_last [2]    = img_gauss_col_last;
    assign img_sel_in_de       [2]    = img_gauss_de;
    assign img_sel_in_data     [2][0] = img_gauss_b[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [2][1] = img_gauss_g[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [2][2] = img_gauss_r[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [2][3] = '0;
    assign img_sel_in_valid    [2]    = img_gauss_valid;

    assign img_sel_in_row_first[3]    = img_hsv_row_first;
    assign img_sel_in_row_last [3]    = img_hsv_row_last;
    assign img_sel_in_col_first[3]    = img_hsv_col_first;
    assign img_sel_in_col_last [3]    = img_hsv_col_last;
    assign img_sel_in_de       [3]    = img_hsv_de;
    assign img_sel_in_data     [3][0] = img_hsv_h[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [3][1] = img_hsv_s[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [3][2] = img_hsv_v[S_DATA_WIDTH-1 -: M_DATA_WIDTH];
    assign img_sel_in_data     [3][3] = '0;
    assign img_sel_in_valid    [3]    = img_hsv_valid;

    assign img_sel_in_row_first[4]    = img_bin_row_first;
    assign img_sel_in_row_last [4]    = img_bin_row_last;
    assign img_sel_in_col_first[4]    = img_bin_col_first;
    assign img_sel_in_col_last [4]    = img_bin_col_last;
    assign img_sel_in_de       [4]    = img_bin_de;
    assign img_sel_in_data     [4]    = {M_TDATA_WIDTH{img_bin_data}};
    assign img_sel_in_valid    [4]    = img_bin_valid;


    logic                               img_select_row_first;
    logic                               img_select_row_last;
    logic                               img_select_col_first;
    logic                               img_select_col_last;
    logic                               img_select_de;
    logic   [M_TDATA_WIDTH-1:0]         img_select_data;
    logic                               img_select_valid;

    logic   [WB_DAT_WIDTH-1:0]          wb_select_dat_o;
    logic                               wb_select_stb_i;
    logic                               wb_select_ack_o;

    jelly_img_selector
            #(
                .NUM                    (S_NUM),
                .USER_WIDTH             (0),
                .DATA_WIDTH             (M_TDATA_WIDTH),
                .WB_ADR_WIDTH           (6),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .INIT_CTL_SELECT        (1)
            )
        i_img_selector
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),

                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[5:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_select_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_select_stb_i),
                .s_wb_ack_o             (wb_select_ack_o),

                .s_img_line_first       (img_sel_in_row_first),
                .s_img_line_last        (img_sel_in_row_last),
                .s_img_pixel_first      (img_sel_in_col_first),
                .s_img_pixel_last       (img_sel_in_col_last),
                .s_i