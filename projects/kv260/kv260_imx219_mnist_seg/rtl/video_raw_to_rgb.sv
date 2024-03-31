// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 画像処理
module video_raw_to_rgb
        #(
            parameter   WB_ADR_WIDTH    = 8,
            parameter   WB_DAT_WIDTH    = 32,
            parameter   WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8),
            
            parameter   S_DATA_WIDTH    = 10,
            parameter   M_DATA_WIDTH    = 8,
            
            parameter   X_WIDTH         = 12,
            parameter   Y_WIDTH         = 11,
            parameter   MAX_X_NUM       = 4096,
            parameter   IMG_Y_NUM       = 480,
            parameter   IMG_Y_WIDTH     = 14,
            
            parameter   TUSER_WIDTH     = 1,
            parameter   S_TDATA_WIDTH   = 1*S_DATA_WIDTH,
            parameter   M_TDATA_WIDTH   = 4*M_DATA_WIDTH
        )
        (
            input   var logic                           aresetn,
            input   var logic                           aclk,

            input   var logic   [X_WIDTH-1:0]           param_width,
            input   var logic   [Y_WIDTH-1:0]           param_height,
            
            input   var logic                           in_update_req,
            
            input   var logic                           s_wb_rst_i,
            input   var logic                           s_wb_clk_i,
            input   var logic   [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   var logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  var logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   var logic                           s_wb_we_i,
            input   var logic   [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   var logic                           s_wb_stb_i,
            output  var logic                           s_wb_ack_o,
            
            input   var logic   [TUSER_WIDTH-1:0]       s_axi4s_tuser,
            input   var logic                           s_axi4s_tlast,
            input   var logic   [S_TDATA_WIDTH-1:0]     s_axi4s_tdata,
            input   var logic                           s_axi4s_tvalid,
            output  var logic                           s_axi4s_tready,
            
            output  var logic   [TUSER_WIDTH-1:0]       m_axi4s_tuser,
            output  var logic                           m_axi4s_tlast,
            output  var logic   [M_TDATA_WIDTH-1:0]     m_axi4s_tdata,
            output  var logic                           m_axi4s_tvalid,
            input   var logic                           m_axi4s_tready
        );
    

    localparam  USE_VALID  = 1;
    localparam  USER_WIDTH = (TUSER_WIDTH - 1) >= 0 ? (TUSER_WIDTH - 1) : 0;
    localparam  USER_BITS  = USER_WIDTH > 0 ? USER_WIDTH : 1;

    logic                               reset   ;
    logic                               clk     ;
    logic                               cke     ;
    assign  reset = ~aresetn;
    assign  clk   = aclk;
    
    logic                               img_src_row_first;
    logic                               img_src_row_last;
    logic                               img_src_col_first;
    logic                               img_src_col_last;
    logic                               img_src_de;
    logic   [USER_BITS-1:0]             img_src_user;
    logic   [S_TDATA_WIDTH-1:0]         img_src_data;
    logic                               img_src_valid;
    
    logic                               img_sink_row_first;
    logic                               img_sink_row_last;
    logic                               img_sink_col_first;
    logic                               img_sink_col_last;
    logic                               img_sink_de;
    logic   [USER_BITS-1:0]             img_sink_user;
    logic   [M_TDATA_WIDTH-1:0]         img_sink_data;
    logic                               img_sink_valid;
    
    // axi4s<->img
    jelly2_axi4s_img
            #(
                .SIZE_AUTO              (1'b0),
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (S_TDATA_WIDTH),
                .M_TDATA_WIDTH          (M_TDATA_WIDTH),
                .IMG_X_WIDTH            (X_WIDTH),
                .IMG_Y_WIDTH            (Y_WIDTH),
                .BLANK_Y_WIDTH          (8),
                .IMG_CKE_BUFG           (0)
            )
        u_axi4s_img
            (
                .aresetn                (aresetn),
                .aclk                   (aclk),
                .aclken                 (1'b1),
                
                .param_img_width        (param_width),
                .param_img_height       (param_height),
                .param_blank_height     (8'h0f),
                
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
                .m_img_src_user         (img_src_user),
                .m_img_src_data         (img_src_data),
                .m_img_src_valid        (img_src_valid),
                
                .s_img_sink_row_first   (img_sink_row_first),
                .s_img_sink_row_last    (img_sink_row_last),
                .s_img_sink_col_first   (img_sink_col_first),
                .s_img_sink_col_last    (img_sink_col_last),
                .s_img_sink_user        (img_sink_user),
                .s_img_sink_de          (img_sink_de),
                .s_img_sink_data        (img_sink_data),
                .s_img_sink_valid       (img_sink_valid)
            );
    
    
    // demosaic
    logic                               img_demos_row_first;
    logic                               img_demos_row_last;
    logic                               img_demos_col_first;
    logic                               img_demos_col_last;
    logic                               img_demos_de;
    logic   [USER_BITS-1:0]             img_demos_user;
    logic   [S_DATA_WIDTH-1:0]          img_demos_raw;
    logic   [S_DATA_WIDTH-1:0]          img_demos_r;
    logic   [S_DATA_WIDTH-1:0]          img_demos_g;
    logic   [S_DATA_WIDTH-1:0]          img_demos_b;
    logic                               img_demos_valid;
    
    logic   [WB_DAT_WIDTH-1:0]          wb_demos_dat_o;
    logic                               wb_demos_stb_i;
    logic                               wb_demos_ack_o;
    
    jelly2_img_demosaic_acpi
            #(
                .USER_WIDTH             (USER_BITS),
                .DATA_WIDTH             (S_DATA_WIDTH),
                .MAX_COLS               (4096),
                .RAM_TYPE               ("block"),
                .USE_VALID              (USE_VALID),
                
                .WB_ADR_WIDTH           (6),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_PHASE       (2'b00)
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
                
                .s_img_row_first        (img_src_row_first),
                .s_img_row_last         (img_src_row_last),
                .s_img_col_first        (img_src_col_first),
                .s_img_col_last         (img_src_col_last),
                .s_img_de               (img_src_de),
                .s_img_user             (img_src_user),
                .s_img_raw              (img_src_data),
                .s_img_valid            (img_src_valid),
                
                .m_img_row_first        (img_demos_row_first),
                .m_img_row_last         (img_demos_row_last),
                .m_img_col_first        (img_demos_col_first),
                .m_img_col_last         (img_demos_col_last),
                .m_img_de               (img_demos_de),
                .m_img_user             (img_demos_user),
                .m_img_raw              (img_demos_raw),
                .m_img_r                (img_demos_r),
                .m_img_g                (img_demos_g),
                .m_img_b                (img_demos_b),
                .m_img_valid            (img_demos_valid)
            );
    
    
    // color matrix
    logic                               img_colmat_row_first;
    logic                               img_colmat_row_last;
    logic                               img_colmat_col_first;
    logic                               img_colmat_col_last;
    logic                               img_colmat_de;
    logic   [USER_BITS-1:0]             img_colmat_user;
    logic   [S_DATA_WIDTH-1:0]          img_colmat_raw;
    logic   [S_DATA_WIDTH-1:0]          img_colmat_r;
    logic   [S_DATA_WIDTH-1:0]          img_colmat_g;
    logic   [S_DATA_WIDTH-1:0]          img_colmat_b;
    logic                               img_colmat_valid;
    
    logic   [WB_DAT_WIDTH-1:0]          wb_colmat_dat_o;
    logic                               wb_colmat_stb_i;
    logic                               wb_colmat_ack_o;
    
    jelly2_img_color_matrix
            #(
                .USER_WIDTH             (USER_BITS + S_DATA_WIDTH),
                .DATA_WIDTH             (S_DATA_WIDTH),
                .INTERNAL_WIDTH         (S_DATA_WIDTH+2),
                
                .COEFF_INT_WIDTH        (9),
                .COEFF_FRAC_WIDTH       (16),
                .COEFF3_INT_WIDTH       (9),
                .COEFF3_FRAC_WIDTH      (16),
                .STATIC_COEFF           (1),
                .DEVICE                 ("RTL"),
                
                .WB_ADR_WIDTH           (8),
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
        u_img_color_matrix
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .in_update_req          (in_update_req),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_colmat_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_colmat_stb_i),
                .s_wb_ack_o             (wb_colmat_ack_o),
                
                .s_img_row_first        (img_demos_row_first),
                .s_img_row_last         (img_demos_row_last),
                .s_img_col_first        (img_demos_col_first),
                .s_img_col_last         (img_demos_col_last),
                .s_img_de               (img_demos_de),
                .s_img_user             ({img_demos_user, img_demos_raw}),
                .s_img_color0           (img_demos_r),
                .s_img_color1           (img_demos_g),
                .s_img_color2           (img_demos_b),
                .s_img_valid            (img_demos_valid),
                
                .m_img_row_first        (img_colmat_row_first),
                .m_img_row_last         (img_colmat_row_last),
                .m_img_col_first        (img_colmat_col_first),
                .m_img_col_last         (img_colmat_col_last),
                .m_img_de               (img_colmat_de),
                .m_img_user             ({img_colmat_user, img_colmat_raw}),
                .m_img_color0           (img_colmat_r),
                .m_img_color1           (img_colmat_g),
                .m_img_color2           (img_colmat_b),
                .m_img_valid            (img_colmat_valid)
            );
    
    // gamma correction
    logic                               img_gamma_row_first;
    logic                               img_gamma_row_last;
    logic                               img_gamma_col_first;
    logic                               img_gamma_col_last;
    logic                               img_gamma_de;
    logic   [USER_BITS-1:0]             img_gamma_user;
    logic   [S_DATA_WIDTH-1:0]          img_gamma_raw;
    logic   [3*M_DATA_WIDTH-1:0]        img_gamma_data;
    logic                               img_gamma_valid;
    
    logic   [WB_DAT_WIDTH-1:0]          wb_gamma_dat_o;
    logic                               wb_gamma_stb_i;
    logic                               wb_gamma_ack_o;
    
    jelly_img_gamma_correction
            #(
                .COMPONENTS             (3),
                .USER_WIDTH             (USER_BITS+S_DATA_WIDTH),
                .S_DATA_WIDTH           (S_DATA_WIDTH),
                .M_DATA_WIDTH           (M_DATA_WIDTH),
                .USE_VALID              (USE_VALID),
                .RAM_TYPE               ("block"),
                
                .WB_ADR_WIDTH           (12),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_CTL_CONTROL       (2'b00),
                .INIT_PARAM_ENABLE      (3'b000)
            )
        u_img_gamma_correction
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
                
                .s_img_line_first       (img_colmat_row_first),
                .s_img_line_last        (img_colmat_row_last),
                .s_img_pixel_first      (img_colmat_col_first),
                .s_img_pixel_last       (img_colmat_col_last),
                .s_img_de               (img_colmat_de),
                .s_img_user             ({img_colmat_user, img_colmat_raw}),
                .s_img_data             ({img_colmat_r, img_colmat_g, img_colmat_b}),
                .s_img_valid            (img_colmat_valid),
                
                .m_img_line_first       (img_gamma_row_first),
                .m_img_line_last        (img_gamma_row_last),
                .m_img_pixel_first      (img_gamma_col_first),
                .m_img_pixel_last       (img_gamma_col_last),
                .m_img_de               (img_gamma_de),
                .m_img_user             ({img_gamma_user, img_gamma_raw}),
                .m_img_data             (img_gamma_data),
                .m_img_valid            (img_gamma_valid)
            );
    
    
    // gaussian
    logic                               img_gauss_row_first;
    logic                               img_gauss_row_last;
    logic                               img_gauss_col_first;
    logic                               img_gauss_col_last;
    logic                               img_gauss_de;
    logic   [USER_BITS-1:0]             img_gauss_user;
    logic   [S_DATA_WIDTH-1:0]          img_gauss_raw;
    logic   [3*M_DATA_WIDTH-1:0]        img_gauss_data;
    logic                               img_gauss_valid;
    
    logic   [WB_DAT_WIDTH-1:0]          wb_gauss_dat_o;
    logic                               wb_gauss_stb_i;
    logic                               wb_gauss_ack_o;
    
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
        u_img_gaussian_3x3
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
                
                .s_img_line_first       (img_gamma_row_first),
                .s_img_line_last        (img_gamma_row_last),
                .s_img_pixel_first      (img_gamma_col_first),
                .s_img_pixel_last       (img_gamma_col_last),
                .s_img_de               (img_gamma_de),
                .s_img_user             ({img_gamma_user, img_gamma_raw}),
                .s_img_data             (img_gamma_data),
                .s_img_valid            (img_gamma_valid),
                
                .m_img_line_first       (img_gauss_row_first),
                .m_img_line_last        (img_gauss_row_last),
                .m_img_pixel_first      (img_gauss_col_first),
                .m_img_pixel_last       (img_gauss_col_last),
                .m_img_de               (img_gauss_de),
                .m_img_user             ({img_gauss_user, img_gauss_raw}),
                .m_img_data             (img_gauss_data),
                .m_img_valid            (img_gauss_valid)
            );
    
    
    // RGB to Gray
    logic                               img_gray_row_first;
    logic                               img_gray_row_last;
    logic                               img_gray_col_first;
    logic                               img_gray_col_last;
    logic                               img_gray_de;
    logic   [USER_BITS-1:0]             img_gray_user;
    logic   [2:0][M_DATA_WIDTH-1:0]     img_gray_rgb;
    logic   [M_DATA_WIDTH-1:0]          img_gray_gray;
    logic                               img_gray_valid;
    
    jelly_img_rgb_to_gray
            #(
                .USER_WIDTH             (USER_BITS),
                .DATA_WIDTH             (M_DATA_WIDTH)
            )
        u_img_rgb_to_gray
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_line_first       (img_gauss_row_first),
                .s_img_line_last        (img_gauss_row_last),
                .s_img_pixel_first      (img_gauss_col_first),
                .s_img_pixel_last       (img_gauss_col_last),
                .s_img_de               (img_gauss_de),
                .s_img_user             (img_gauss_user),
                .s_img_rgb              (img_gauss_data),
                .s_img_valid            (img_gauss_valid),
                
                .m_img_line_first       (img_gray_row_first),
                .m_img_line_last        (img_gray_row_last),
                .m_img_pixel_first      (img_gray_col_first),
                .m_img_pixel_last       (img_gray_col_last),
                .m_img_de               (img_gray_de),
                .m_img_user             (img_gray_user),
                .m_img_rgb              (img_gray_rgb),
                .m_img_gray             (img_gray_gray),
                .m_img_valid            (img_gray_valid)
            );

    // selector
    localparam  SEL_N = 4;
    
    logic   [SEL_N-1:0]                     img_sel_row_first;
    logic   [SEL_N-1:0]                     img_sel_row_last;
    logic   [SEL_N-1:0]                     img_sel_col_first;
    logic   [SEL_N-1:0]                     img_sel_col_last;
    logic   [SEL_N-1:0]                     img_sel_de;
    logic   [SEL_N-1:0][USER_BITS-1:0]      img_sel_user;
    logic   [SEL_N-1:0][M_TDATA_WIDTH-1:0]  img_sel_data;
    logic   [SEL_N-1:0]                     img_sel_valid;
    
    assign img_sel_row_first[0] = img_gauss_row_first;
    assign img_sel_row_last [0] = img_gauss_row_last;
    assign img_sel_col_first[0] = img_gauss_col_first;
    assign img_sel_col_last [0] = img_gauss_col_last;
    assign img_sel_de       [0] = img_gauss_de;
    assign img_sel_user     [0] = img_gauss_user;
    assign img_sel_data     [0] = {img_gray_gray, img_gray_rgb};
    assign img_sel_valid    [0] = img_gauss_valid;
        
    assign img_sel_row_first[1] = img_src_row_first;
    assign img_sel_row_last [1] = img_src_row_last;
    assign img_sel_col_first[1] = img_src_col_first;
    assign img_sel_col_last [1] = img_src_col_last;
    assign img_sel_de       [1] = img_src_de;
    assign img_sel_user     [1] = img_src_user;
    assign img_sel_data     [1] = img_src_data;
    assign img_sel_valid    [1] = img_src_valid;

    assign img_sel_row_first[2] = img_gauss_row_first;
    assign img_sel_row_last [2] = img_gauss_row_last;
    assign img_sel_col_first[2] = img_gauss_col_first;
    assign img_sel_col_last [2] = img_gauss_col_last;
    assign img_sel_de       [2] = img_gauss_de;
    assign img_sel_user     [2] = img_gauss_user;
    assign img_sel_data     [2] = {img_gauss_raw[S_DATA_WIDTH-1 -: M_DATA_WIDTH], img_gauss_data};
    assign img_sel_valid    [2] = img_gauss_valid;

    assign img_sel_row_first[3] = img_gray_row_first;
    assign img_sel_row_last [3] = img_gray_row_last;
    assign img_sel_col_first[3] = img_gray_col_first;
    assign img_sel_col_last [3] = img_gray_col_last;
    assign img_sel_de       [3] = img_gray_de;
    assign img_sel_user     [3] = img_gray_user;
    assign img_sel_data     [3] = {4{img_gray_gray}};
    assign img_sel_valid    [3] = img_gray_valid;
    


    
    logic   [WB_DAT_WIDTH-1:0]      wb_sel_dat_o;
    logic                           wb_sel_stb_i;
    logic                           wb_sel_ack_o;
    
    jelly2_img_selector
            #(
                .NUM                    (SEL_N),
                .USER_WIDTH             (USER_BITS),
                .DATA_WIDTH             (M_TDATA_WIDTH),
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .INIT_CTL_SELECT        (0)
            )
        u_img_selector
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
                
                .s_img_row_first        (img_sel_row_first),
                .s_img_row_last         (img_sel_row_last),
                .s_img_col_first        (img_sel_col_first),
                .s_img_col_last         (img_sel_col_last),
                .s_img_de               (img_sel_de),
                .s_img_user             (img_sel_user),
                .s_img_data             (img_sel_data),
                .s_img_valid            (img_sel_valid),
                
                .m_img_row_first        (img_sink_row_first),
                .m_img_row_last         (img_sink_row_last),
                .m_img_col_first        (img_sink_col_first),
                .m_img_col_last         (img_sink_col_last),
                .m_img_de               (img_sink_de),
                .m_img_user             (img_sink_user),
                .m_img_data             (img_sink_data),
                .m_img_valid            (img_sink_valid)
            );
    
    
    
    // WISHBONE
    assign wb_demos_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 0);
    assign wb_colmat_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 1);
    assign wb_gamma_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 2);
    assign wb_gauss_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 4);
    assign wb_sel_stb_i     = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 15);
    
    assign s_wb_dat_o      = wb_demos_stb_i   ? wb_demos_dat_o   :
                             wb_colmat_stb_i  ? wb_colmat_dat_o  :
                             wb_gamma_stb_i   ? wb_gamma_dat_o   :
                             wb_gauss_stb_i   ? wb_gauss_dat_o   :
                             wb_sel_stb_i     ? wb_sel_dat_o     :
                             {WB_DAT_WIDTH{1'b0}};
    
    assign s_wb_ack_o      = wb_demos_stb_i   ? wb_demos_ack_o   :
                             wb_colmat_stb_i  ? wb_colmat_ack_o  :
                             wb_gamma_stb_i   ? wb_gamma_ack_o   :
                             wb_gauss_stb_i   ? wb_gauss_ack_o   :
                             wb_sel_stb_i     ? wb_sel_ack_o     :
                             s_wb_stb_i;
    
    
endmodule



`default_nettype wire



// end of file
