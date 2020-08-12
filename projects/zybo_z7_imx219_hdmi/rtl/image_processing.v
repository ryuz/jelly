// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// ‰æ‘œˆ—
module image_processing
        #(
            parameter   WB_ADR_WIDTH  = 8,
            parameter   WB_DAT_WIDTH  = 32,
            parameter   WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            
            parameter   S_DATA_WIDTH  = 10,
            parameter   M_DATA_WIDTH  = 8,
            
            parameter   MAX_X_NUM     = 4096,
            parameter   IMG_Y_NUM     = 480,
            parameter   IMG_Y_WIDTH   = 14,
            
            parameter   TUSER_WIDTH   = 1,
            parameter   S_TDATA_WIDTH = 1*S_DATA_WIDTH,
            parameter   M_TDATA_WIDTH = 4*M_DATA_WIDTH
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            
            input   wire                        in_update_req,
            
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
            input   wire                        m_axi4s_tready
        );
    
    localparam  USE_VALID  = 0;
    localparam  USER_WIDTH = (TUSER_WIDTH - 1) >= 0 ? (TUSER_WIDTH - 1) : 0;
    localparam  USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1;
    
    wire                                reset = ~aresetn;
    wire                                clk   = aclk;
    wire                                cke;
    
    wire                                img_src_line_first;
    wire                                img_src_line_last;
    wire                                img_src_pixel_first;
    wire                                img_src_pixel_last;
    wire                                img_src_de;
    wire    [USER_BITS-1:0]             img_src_user;
    wire    [S_TDATA_WIDTH-1:0]         img_src_data;
    wire                                img_src_valid;
    
    wire                                img_sink_line_first;
    wire                                img_sink_line_last;
    wire                                img_sink_pixel_first;
    wire                                img_sink_pixel_last;
    wire                                img_sink_de;
    wire    [USER_BITS-1:0]             img_sink_user;
    wire    [M_TDATA_WIDTH-1:0]         img_sink_data;
    wire                                img_sink_valid;
    
    // axi4s<->img
    jelly_axi4s_img
            #(
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (S_TDATA_WIDTH),
                .M_TDATA_WIDTH          (M_TDATA_WIDTH),
                .IMG_Y_NUM              (IMG_Y_NUM),
                .IMG_Y_WIDTH            (IMG_Y_WIDTH),
                .BLANK_Y_WIDTH          (8),
                .IMG_CKE_BUFG           (0)
            )
        jelly_axi4s_img
            (
                .reset                  (reset),
                .clk                    (clk),
                
                .param_blank_num        (8'h00),
                
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
                
                .src_img_line_first     (img_src_line_first),
                .src_img_line_last      (img_src_line_last),
                .src_img_pixel_first    (img_src_pixel_first),
                .src_img_pixel_last     (img_src_pixel_last),
                .src_img_de             (img_src_de),
                .src_img_user           (img_src_user),
                .src_img_data           (img_src_data),
                .src_img_valid          (img_src_valid),
                
                .sink_img_line_first    (img_sink_line_first),
                .sink_img_line_last     (img_sink_line_last),
                .sink_img_pixel_first   (img_sink_pixel_first),
                .sink_img_pixel_last    (img_sink_pixel_last),
                .sink_img_user          (img_sink_user),
                .sink_img_de            (img_sink_de),
                .sink_img_data          (img_sink_data),
                .sink_img_valid         (img_sink_valid)
            );
    
    
    // demosaic
    wire                                img_demos_line_first;
    wire                                img_demos_line_last;
    wire                                img_demos_pixel_first;
    wire                                img_demos_pixel_last;
    wire                                img_demos_de;
    wire    [USER_BITS-1:0]             img_demos_user;
    wire    [S_DATA_WIDTH-1:0]          img_demos_raw;
    wire    [S_DATA_WIDTH-1:0]          img_demos_r;
    wire    [S_DATA_WIDTH-1:0]          img_demos_g;
    wire    [S_DATA_WIDTH-1:0]          img_demos_b;
    wire                                img_demos_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_demos_dat_o;
    wire                                wb_demos_stb_i;
    wire                                wb_demos_ack_o;
    
    jelly_img_demosaic_acpi
            #(
                .USER_WIDTH             (USER_BITS),
                .DATA_WIDTH             (S_DATA_WIDTH),
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
                
                .s_img_line_first       (img_src_line_first),
                .s_img_line_last        (img_src_line_last),
                .s_img_pixel_first      (img_src_pixel_first),
                .s_img_pixel_last       (img_src_pixel_last),
                .s_img_de               (img_src_de),
                .s_img_user             (img_src_user),
                .s_img_raw              (img_src_data),
                .s_img_valid            (img_src_valid),
                
                .m_img_line_first       (img_demos_line_first),
                .m_img_line_last        (img_demos_line_last),
                .m_img_pixel_first      (img_demos_pixel_first),
                .m_img_pixel_last       (img_demos_pixel_last),
                .m_img_de               (img_demos_de),
                .m_img_user             (img_demos_user),
                .m_img_raw              (img_demos_raw),
                .m_img_r                (img_demos_r),
                .m_img_g                (img_demos_g),
                .m_img_b                (img_demos_b),
                .m_img_valid            (img_demos_valid)
            );
    
    
    // color matrix
    wire                                img_colmat_line_first;
    wire                                img_colmat_line_last;
    wire                                img_colmat_pixel_first;
    wire                                img_colmat_pixel_last;
    wire                                img_colmat_de;
    wire    [USER_BITS-1:0]             img_colmat_user;
    wire    [S_DATA_WIDTH-1:0]          img_colmat_raw;
    wire    [S_DATA_WIDTH-1:0]          img_colmat_r;
    wire    [S_DATA_WIDTH-1:0]          img_colmat_g;
    wire    [S_DATA_WIDTH-1:0]          img_colmat_b;
    wire                                img_colmat_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_colmat_dat_o;
    wire                                wb_colmat_stb_i;
    wire                                wb_colmat_ack_o;
    
    jelly_img_color_matrix
            #(
                .USER_WIDTH             (USER_BITS + S_DATA_WIDTH),
                .DATA_WIDTH             (S_DATA_WIDTH),
                .INTERNAL_WIDTH         (S_DATA_WIDTH+2),
                
                .COEFF_INT_WIDTH        (9),
                .COEFF_FRAC_WIDTH       (16),
                .COEFF3_INT_WIDTH       (9),
                .COEFF3_FRAC_WIDTH      (16),
                .STATIC_COEFF           (1),
                .DEVICE                 ("7SERIES"),
                
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
                .INIT_PARAM_CLIP_MIN0   ({S_DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX0   ({S_DATA_WIDTH{1'b1}}),
                .INIT_PARAM_CLIP_MIN1   ({S_DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX1   ({S_DATA_WIDTH{1'b1}}),
                .INIT_PARAM_CLIP_MIN2   ({S_DATA_WIDTH{1'b0}}),
                .INIT_PARAM_CLIP_MAX2   ({S_DATA_WIDTH{1'b1}})
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
                
                .s_img_line_first       (img_demos_line_first),
                .s_img_line_last        (img_demos_line_last),
                .s_img_pixel_first      (img_demos_pixel_first),
                .s_img_pixel_last       (img_demos_pixel_last),
                .s_img_de               (img_demos_de),
                .s_img_user             ({img_demos_user, img_demos_raw}),
                .s_img_color0           (img_demos_r),
                .s_img_color1           (img_demos_g),
                .s_img_color2           (img_demos_b),
                .s_img_valid            (img_demos_valid),
                
                .m_img_line_first       (img_colmat_line_first),
                .m_img_line_last        (img_colmat_line_last),
                .m_img_pixel_first      (img_colmat_pixel_first),
                .m_img_pixel_last       (img_colmat_pixel_last),
                .m_img_de               (img_colmat_de),
                .m_img_user             ({img_colmat_user, img_colmat_raw}),
                .m_img_color0           (img_colmat_r),
                .m_img_color1           (img_colmat_g),
                .m_img_color2           (img_colmat_b),
                .m_img_valid            (img_colmat_valid)
            );
    
    // gamma correction
    wire                                img_gamma_line_first;
    wire                                img_gamma_line_last;
    wire                                img_gamma_pixel_first;
    wire                                img_gamma_pixel_last;
    wire                                img_gamma_de;
    wire    [USER_BITS-1:0]             img_gamma_user;
    wire    [S_DATA_WIDTH-1:0]          img_gamma_raw;
    wire    [3*M_DATA_WIDTH-1:0]        img_gamma_data;
    wire                                img_gamma_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_gamma_dat_o;
    wire                                wb_gamma_stb_i;
    wire                                wb_gamma_ack_o;
    
    jelly_img_gamma_correction
            #(
                .COMPONENTS             (3),
                .USER_WIDTH             (USER_BITS+S_DATA_WIDTH),
                .S_DATA_WIDTH           (S_DATA_WIDTH),
                .M_DATA_WIDTH           (M_DATA_WIDTH),
                .USE_VALID              (USE_VALID),
                .RAM_TYPE               ("block"),
                
                .WB_ADR_WIDTH           (12),
                .WB_DAT_WIDTH           (32),
                
                .INIT_CTL_CONTROL       (2'b00),
                .INIT_PARAM_ENABLE      (3'b000)
            )
        i_img_gamma_correction
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[11:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_gamma_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_gamma_stb_i),
                .s_wb_ack_o             (wb_gamma_ack_o),
                
                .s_img_line_first       (img_colmat_line_first),
                .s_img_line_last        (img_colmat_line_last),
                .s_img_pixel_first      (img_colmat_pixel_first),
                .s_img_pixel_last       (img_colmat_pixel_last),
                .s_img_de               (img_colmat_de),
                .s_img_user             ({img_colmat_user, img_colmat_raw}),
                .s_img_data             ({img_colmat_r, img_colmat_g, img_colmat_b}),
                .s_img_valid            (img_colmat_valid),
                
                .m_img_line_first       (img_gamma_line_first),
                .m_img_line_last        (img_gamma_line_last),
                .m_img_pixel_first      (img_gamma_pixel_first),
                .m_img_pixel_last       (img_gamma_pixel_last),
                .m_img_de               (img_gamma_de),
                .m_img_user             ({img_gamma_user, img_gamma_raw}),
                .m_img_data             (img_gamma_data),
                .m_img_valid            (img_gamma_valid)
            );
    
    
    // gaussian
    wire                                img_gauss_line_first;
    wire                                img_gauss_line_last;
    wire                                img_gauss_pixel_first;
    wire                                img_gauss_pixel_last;
    wire                                img_gauss_de;
    wire    [USER_BITS-1:0]             img_gauss_user;
    wire    [S_DATA_WIDTH-1:0]          img_gauss_raw;
    wire    [3*M_DATA_WIDTH-1:0]        img_gauss_data;
    wire                                img_gauss_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_gauss_dat_o;
    wire                                wb_gauss_stb_i;
    wire                                wb_gauss_ack_o;
    
    jelly_img_gaussian_3x3
            #(
                .NUM                    (3),
                .USER_WIDTH             (USER_BITS+S_DATA_WIDTH),
                .COMPONENTS             (3),
                .DATA_WIDTH             (M_DATA_WIDTH),
                .MAX_X_NUM              (MAX_X_NUM),
                .RAM_TYPE               ("block"),
                .USE_VALID              (USE_VALID),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_CTL_CONTROL       (3'b000),
                .INIT_PARAM_ENABLE      (3'b000)
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
                
                .s_img_line_first       (img_gamma_line_first),
                .s_img_line_last        (img_gamma_line_last),
                .s_img_pixel_first      (img_gamma_pixel_first),
                .s_img_pixel_last       (img_gamma_pixel_last),
                .s_img_de               (img_gamma_de),
                .s_img_user             ({img_gamma_user, img_gamma_raw}),
                .s_img_data             (img_gamma_data),
                .s_img_valid            (img_gamma_valid),
                
                .m_img_line_first       (img_gauss_line_first),
                .m_img_line_last        (img_gauss_line_last),
                .m_img_pixel_first      (img_gauss_pixel_first),
                .m_img_pixel_last       (img_gauss_pixel_last),
                .m_img_de               (img_gauss_de),
                .m_img_user             ({img_gauss_user, img_gauss_raw}),
                .m_img_data             (img_gauss_data),
                .m_img_valid            (img_gauss_valid)
            );
    
    
    // RGB to Gray
    wire                                img_gray_line_first;
    wire                                img_gray_line_last;
    wire                                img_gray_pixel_first;
    wire                                img_gray_pixel_last;
    wire                                img_gray_de;
    wire    [USER_BITS-1:0]             img_gray_user;
    wire    [M_DATA_WIDTH-1:0]          img_gray_data;
    wire                                img_gray_valid;
    
    jelly_img_rgb_to_gray
            #(
                .USER_WIDTH             (USER_BITS),
                .DATA_WIDTH             (M_DATA_WIDTH)
            )
        i_img_rgb_to_gray
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_line_first       (img_gauss_line_first),
                .s_img_line_last        (img_gauss_line_last),
                .s_img_pixel_first      (img_gauss_pixel_first),
                .s_img_pixel_last       (img_gauss_pixel_last),
                .s_img_de               (img_gauss_de),
                .s_img_user             (img_gauss_user),
                .s_img_rgb              (img_gauss_data),
                .s_img_valid            (img_gauss_valid),
                
                .m_img_line_first       (img_gray_line_first),
                .m_img_line_last        (img_gray_line_last),
                .m_img_pixel_first      (img_gray_pixel_first),
                .m_img_pixel_last       (img_gray_pixel_last),
                .m_img_de               (img_gray_de),
                .m_img_user             (img_gray_user),
                .m_img_rgb              (),
                .m_img_gray             (img_gray_data),
                .m_img_valid            (img_gray_valid)
            );
    
    
    // canny
    wire                                img_canny_line_first;
    wire                                img_canny_line_last;
    wire                                img_canny_pixel_first;
    wire                                img_canny_pixel_last;
    wire                                img_canny_de;
    wire    [USER_BITS-1:0]             img_canny_user;
    wire    [0:0]                       img_canny_binary;
    wire    [7:0]                       img_canny_angle;
    wire                                img_canny_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_canny_dat_o;
    wire                                wb_canny_stb_i;
    wire                                wb_canny_ack_o;
    
    jelly_img_canny
            #(
                .USER_WIDTH             (USER_BITS),
                .DATA_WIDTH             (M_DATA_WIDTH),
                .ANGLE_WIDTH            (8),
                .GRAD_X_WIDTH           (M_DATA_WIDTH),
                .GRAD_Y_WIDTH           (M_DATA_WIDTH),
                .TH_WIDTH               (16),
                .SCALED_RADIAN          (1),
                .MAX_X_NUM              (MAX_X_NUM),
                .RAM_TYPE               ("block"),
                .USE_VALID              (USE_VALID),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_CTL_CONTROL       (3'b000),
                .INIT_PARAM_TH          (127*127)
            )
     i_img_canny
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_canny_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_canny_stb_i),
                .s_wb_ack_o             (wb_canny_ack_o),
                
                .s_img_line_first       (img_gray_line_first),
                .s_img_line_last        (img_gray_line_last),
                .s_img_pixel_first      (img_gray_pixel_first),
                .s_img_pixel_last       (img_gray_pixel_last),
                .s_img_de               (img_gray_de),
                .s_img_user             (img_gray_user),
                .s_img_data             (img_gray_data),
                .s_img_valid            (img_gray_valid),
                
                .m_img_line_first       (img_canny_line_first),
                .m_img_line_last        (img_canny_line_last),
                .m_img_pixel_first      (img_canny_pixel_first),
                .m_img_pixel_last       (img_canny_pixel_last),
                .m_img_de               (img_canny_de),
                .m_img_user             (img_canny_user),
                .m_img_data             (),
                .m_img_binary           (img_canny_binary),
                .m_img_angle            (img_canny_angle),
                .m_img_valid            (img_canny_valid)
        );
    
    
    // color map
    wire                                img_colmap_line_first;
    wire                                img_colmap_line_last;
    wire                                img_colmap_pixel_first;
    wire                                img_colmap_pixel_last;
    wire                                img_colmap_de;
    wire    [USER_BITS-1:0]             img_colmap_user;
    wire    [0:0]                       img_colmap_binary;
    wire    [23:0]                      img_colmap_data;
    wire                                img_colmap_valid;
    
    jelly_img_colormap_core
            #(
                .COLORMAP               ("HSV"),
                .USER_WIDTH             (USER_BITS+1),
                .USE_VALID              (USE_VALID)
            )
        i_img_colormap_core
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_line_first       (img_canny_line_first),
                .s_img_line_last        (img_canny_line_last),
                .s_img_pixel_first      (img_canny_pixel_first),
                .s_img_pixel_last       (img_canny_pixel_last),
                .s_img_de               (img_canny_de),
                .s_img_user             ({img_canny_user, img_canny_binary}),
                .s_img_data             (img_canny_angle),
                .s_img_valid            (img_canny_valid),
                
                .m_img_line_first       (img_colmap_line_first),
                .m_img_line_last        (img_colmap_line_last),
                .m_img_pixel_first      (img_colmap_pixel_first),
                .m_img_pixel_last       (img_colmap_pixel_last),
                .m_img_de               (img_colmap_de),
                .m_img_user             ({img_colmap_user, img_colmap_binary}),
                .m_img_data             (img_colmap_data),
                .m_img_valid            (img_colmap_valid)
            );
    
    
    
    // selector
    localparam  SEL_N = 6;
    localparam  SEL_U = USER_BITS;
    localparam  SEL_D = M_TDATA_WIDTH;
    
    wire    [SEL_N-1:0]         img_sel_line_first;
    wire    [SEL_N-1:0]         img_sel_line_last;
    wire    [SEL_N-1:0]         img_sel_pixel_first;
    wire    [SEL_N-1:0]         img_sel_pixel_last;
    wire    [SEL_N-1:0]         img_sel_de;
    wire    [SEL_N*SEL_U-1:0]   img_sel_user;
    wire    [SEL_N*SEL_D-1:0]   img_sel_data;
    wire    [SEL_N-1:0]         img_sel_valid;
    
    
    assign img_sel_line_first [0]                = img_gauss_line_first;
    assign img_sel_line_last  [0]                = img_gauss_line_last;
    assign img_sel_pixel_first[0]                = img_gauss_pixel_first;
    assign img_sel_pixel_last [0]                = img_gauss_pixel_last;
    assign img_sel_de         [0]                = img_gauss_de;
    assign img_sel_user       [0*SEL_U +: SEL_U] = img_gauss_user;
    assign img_sel_data       [0*SEL_D +: SEL_D] = {img_gauss_raw[S_DATA_WIDTH-1 -: M_DATA_WIDTH], img_gauss_data};
    assign img_sel_valid      [0]                = img_gauss_valid;
    
    assign img_sel_line_first [1]                = img_src_line_first;
    assign img_sel_line_last  [1]                = img_src_line_last;
    assign img_sel_pixel_first[1]                = img_src_pixel_first;
    assign img_sel_pixel_last [1]                = img_src_pixel_last;
    assign img_sel_de         [1]                = img_src_de;
    assign img_sel_user       [1*SEL_U +: SEL_U] = img_src_user;
    assign img_sel_data       [1*SEL_D +: SEL_D] = {4{img_src_data[S_DATA_WIDTH-1 -: M_DATA_WIDTH]}};
    assign img_sel_valid      [1]                = img_src_valid;
    
    assign img_sel_line_first [2]                = img_gray_line_first;
    assign img_sel_line_last  [2]                = img_gray_line_last;
    assign img_sel_pixel_first[2]                = img_gray_pixel_first;
    assign img_sel_pixel_last [2]                = img_gray_pixel_last;
    assign img_sel_de         [2]                = img_gray_de;
    assign img_sel_user       [2*SEL_U +: SEL_U] = img_gray_user;
    assign img_sel_data       [2*SEL_D +: SEL_D] = {4{img_gray_data}};
    assign img_sel_valid      [2]                = img_gray_valid;
    
    assign img_sel_line_first [3]                = img_canny_line_first;
    assign img_sel_line_last  [3]                = img_canny_line_last;
    assign img_sel_pixel_first[3]                = img_canny_pixel_first;
    assign img_sel_pixel_last [3]                = img_canny_pixel_last;
    assign img_sel_de         [3]                = img_canny_de;
    assign img_sel_user       [3*SEL_U +: SEL_U] = img_canny_user;
    assign img_sel_data       [3*SEL_D +: SEL_D] = {SEL_D{img_canny_binary}};
    assign img_sel_valid      [3]                = img_canny_valid;
    
    assign img_sel_line_first [4]                = img_colmap_line_first;
    assign img_sel_line_last  [4]                = img_colmap_line_last;
    assign img_sel_pixel_first[4]                = img_colmap_pixel_first;
    assign img_sel_pixel_last [4]                = img_colmap_pixel_last;
    assign img_sel_de         [4]                = img_colmap_de;
    assign img_sel_user       [4*SEL_U +: SEL_U] = img_colmap_user;
    assign img_sel_data       [4*SEL_D +: SEL_D] = img_colmap_data;
    assign img_sel_valid      [4]                = img_colmap_valid;
    
    assign img_sel_line_first [5]                = img_colmap_line_first;
    assign img_sel_line_last  [5]                = img_colmap_line_last;
    assign img_sel_pixel_first[5]                = img_colmap_pixel_first;
    assign img_sel_pixel_last [5]                = img_colmap_pixel_last;
    assign img_sel_de         [5]                = img_colmap_de;
    assign img_sel_user       [5*SEL_U +: SEL_U] = img_colmap_user;
    assign img_sel_data       [5*SEL_D +: SEL_D] = img_colmap_binary ? img_colmap_data : 0;
    assign img_sel_valid      [5]                = img_colmap_valid;
    
    wire    [WB_DAT_WIDTH-1:0]      wb_sel_dat_o;
    wire                            wb_sel_stb_i;
    wire                            wb_sel_ack_o;
    
    jelly_img_selector
            #(
                .NUM                    (SEL_N),
                .USER_WIDTH             (SEL_U),
                .DATA_WIDTH             (SEL_D),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .INIT_CTL_SELECT        (0)
            )
        i_img_selector
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_sel_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_sel_stb_i),
                .s_wb_ack_o             (wb_sel_ack_o),
                
                .s_img_line_first       (img_sel_line_first),
                .s_img_line_last        (img_sel_line_last),
                .s_img_pixel_first      (img_sel_pixel_first),
                .s_img_pixel_last       (img_sel_pixel_last),
                .s_img_de               (img_sel_de),
                .s_img_user             (img_sel_user),
                .s_img_data             (img_sel_data),
                .s_img_valid            (img_sel_valid),
                
                .m_img_line_first       (img_sink_line_first),
                .m_img_line_last        (img_sink_line_last),
                .m_img_pixel_first      (img_sink_pixel_first),
                .m_img_pixel_last       (img_sink_pixel_last),
                .m_img_de               (img_sink_de),
                .m_img_user             (img_sink_user),
                .m_img_data             (img_sink_data),
                .m_img_valid            (img_sink_valid)
            );
    
    
    
    // WISHBONE
    assign wb_demos_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:14] == 0);
    assign wb_colmat_stb_i = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:14] == 1);
    assign wb_gamma_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:14] == 2);
    assign wb_gauss_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:14] == 4);
    assign wb_canny_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:14] == 5);
    assign wb_sel_stb_i    = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:14] == 15);
    
    assign s_wb_dat_o      = wb_demos_stb_i  ? wb_demos_dat_o  :
                             wb_colmat_stb_i ? wb_colmat_dat_o :
                             wb_gamma_stb_i  ? wb_gamma_dat_o  :
                             wb_gauss_stb_i  ? wb_gauss_dat_o  :
                             wb_canny_stb_i  ? wb_canny_dat_o  :
                             wb_sel_stb_i    ? wb_sel_dat_o    :
                             32'h0000_0000;
    
    assign s_wb_ack_o      = wb_demos_stb_i  ? wb_demos_ack_o  :
                             wb_colmat_stb_i ? wb_colmat_ack_o :
                             wb_gamma_stb_i  ? wb_gamma_ack_o  :
                             wb_gauss_stb_i  ? wb_gauss_ack_o  :
                             wb_canny_stb_i  ? wb_canny_ack_o  :
                             wb_sel_stb_i    ? wb_sel_ack_o    :
                             s_wb_stb_i;
    
    
endmodule



`default_nettype wire



// end of file
