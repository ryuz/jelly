// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module image_processing
        #(
            parameter   WB_ADR_WIDTH   = 10,
            parameter   WB_DAT_SIZE    = 2,
            parameter   WB_DAT_WIDTH   = (8 << WB_DAT_SIZE),
            parameter   WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8),
            
            parameter   DATA_WIDTH     = 10,
            parameter   TUSER_WIDTH    = 1,
            parameter   S_TDATA_WIDTH  = DATA_WIDTH,
            parameter   M_TDATA_WIDTH  = 4*DATA_WIDTH,
            
            parameter   IMG_X_NUM      = 640,
            parameter   IMG_Y_NUM      = 132,
            parameter   IMG_X_WIDTH    = 14,
            parameter   IMG_Y_WIDTH    = 14,
            
            parameter   CENTER_Q_WIDTH = 0,
            parameter   CENTER_X_WIDTH = IMG_X_WIDTH + CENTER_Q_WIDTH,
            parameter   CENTER_Y_WIDTH = IMG_Y_WIDTH + CENTER_Q_WIDTH
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
            
            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  wire                            s_wb_ack_o,
            
            input   wire    [TUSER_WIDTH-1:0]       s_axi4s_tuser,
            input   wire                            s_axi4s_tlast,
            input   wire    [S_TDATA_WIDTH-1:0]     s_axi4s_tdata,
            input   wire                            s_axi4s_tvalid,
            output  wire                            s_axi4s_tready,
            
            output  wire    [TUSER_WIDTH-1:0]       m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [M_TDATA_WIDTH-1:0]     m_axi4s_tdata,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready,
            
            output  wire    [CENTER_X_WIDTH-1:0]    out_center_x,
            output  wire    [CENTER_Y_WIDTH-1:0]    out_center_y,
            output  wire                            out_center_valid
        );
    
    localparam  USE_VALID = 0;
    
    
    wire                                reset = ~aresetn;
    wire                                clk   = aclk;
    wire                                cke;
    
    wire                                img_src_line_first;
    wire                                img_src_line_last;
    wire                                img_src_pixel_first;
    wire                                img_src_pixel_last;
    wire                                img_src_de;
    wire    [TUSER_WIDTH-1:0]           img_src_user;
    wire    [S_TDATA_WIDTH-1:0]         img_src_data;
    wire                                img_src_valid;
    
    wire                                img_sink_line_first;
    wire                                img_sink_line_last;
    wire                                img_sink_pixel_first;
    wire                                img_sink_pixel_last;
    wire                                img_sink_de;
    wire    [TUSER_WIDTH-1:0]           img_sink_user;
    wire    [M_TDATA_WIDTH-1:0]         img_sink_data;
    wire                                img_sink_valid;
    
    // img
    jelly_axi4s_img
            #(
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (DATA_WIDTH),
                .M_TDATA_WIDTH          (4*DATA_WIDTH),
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
    wire                                img_demosaic_line_first;
    wire                                img_demosaic_line_last;
    wire                                img_demosaic_pixel_first;
    wire                                img_demosaic_pixel_last;
    wire                                img_demosaic_de;
    wire    [TUSER_WIDTH-1:0]           img_demosaic_user;
    wire    [DATA_WIDTH-1:0]            img_demosaic_raw;
    wire    [DATA_WIDTH-1:0]            img_demosaic_r;
    wire    [DATA_WIDTH-1:0]            img_demosaic_g;
    wire    [DATA_WIDTH-1:0]            img_demosaic_b;
    wire                                img_demosaic_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_demosaic_dat_o;
    wire                                wb_demosaic_stb_i;
    wire                                wb_demosaic_ack_o;
    
    jelly_img_demosaic_acpi
            #(
                .USER_WIDTH             (TUSER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .MAX_X_NUM              (4096),
                .RAM_TYPE               ("block"),
                .USE_VALID              (USE_VALID),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_PHASE       (2'b11)
            )
        i_img_demosaic_acpi
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_demosaic_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_demosaic_stb_i),
                .s_wb_ack_o             (wb_demosaic_ack_o),
                
                .s_img_line_first       (img_src_line_first),
                .s_img_line_last        (img_src_line_last),
                .s_img_pixel_first      (img_src_pixel_first),
                .s_img_pixel_last       (img_src_pixel_last),
                .s_img_de               (img_src_de),
                .s_img_user             (img_src_user),
                .s_img_raw              (img_src_data),
                .s_img_valid            (img_src_valid),
                
                .m_img_line_first       (img_demosaic_line_first),
                .m_img_line_last        (img_demosaic_line_last),
                .m_img_pixel_first      (img_demosaic_pixel_first),
                .m_img_pixel_last       (img_demosaic_pixel_last),
                .m_img_de               (img_demosaic_de),
                .m_img_user             (img_demosaic_user),
                .m_img_raw              (img_demosaic_raw),
                .m_img_r                (img_demosaic_r),
                .m_img_g                (img_demosaic_g),
                .m_img_b                (img_demosaic_b),
                .m_img_valid            (img_demosaic_valid)
            );
    
    
    // color matrix
    wire    [WB_DAT_WIDTH-1:0]          wb_matrix_dat_o;
    wire                                wb_matrix_stb_i;
    wire                                wb_matrix_ack_o;
    
    wire                                img_matrix_line_first;
    wire                                img_matrix_line_last;
    wire                                img_matrix_pixel_first;
    wire                                img_matrix_pixel_last;
    wire                                img_matrix_de;
    wire    [TUSER_WIDTH-1:0]           img_matrix_user;
    wire    [M_TDATA_WIDTH-1:0]         img_matrix_data;
    wire                                img_matrix_valid;
    
    jelly_img_color_matrix
            #(
                .USER_WIDTH             (TUSER_WIDTH+10),
                .DATA_WIDTH             (DATA_WIDTH),
                .INTERNAL_WIDTH         (DATA_WIDTH+2),
                
                .COEFF_INT_WIDTH        (9),
                .COEFF_FRAC_WIDTH       (16),
                .COEFF3_INT_WIDTH       (9),
                .COEFF3_FRAC_WIDTH      (16),
                .STATIC_COEFF           (1),
                .DEVICE                 ("7SERIES"),
                
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
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_matrix_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_matrix_stb_i),
                .s_wb_ack_o             (wb_matrix_ack_o),
                
                .s_img_line_first       (img_demosaic_line_first),
                .s_img_line_last        (img_demosaic_line_last),
                .s_img_pixel_first      (img_demosaic_pixel_first),
                .s_img_pixel_last       (img_demosaic_pixel_last),
                .s_img_de               (img_demosaic_de),
                .s_img_user             ({img_demosaic_user, img_demosaic_raw}),
                .s_img_color0           (img_demosaic_r),
                .s_img_color1           (img_demosaic_g),
                .s_img_color2           (img_demosaic_b),
                .s_img_valid            (img_demosaic_valid),
                
                .m_img_line_first       (img_matrix_line_first),
                .m_img_line_last        (img_matrix_line_last),
                .m_img_pixel_first      (img_matrix_pixel_first),
                .m_img_pixel_last       (img_matrix_pixel_last),
                .m_img_de               (img_matrix_de),
                .m_img_user             ({img_matrix_user, img_matrix_data[DATA_WIDTH*3 +: DATA_WIDTH]}),
                .m_img_color0           (img_matrix_data[DATA_WIDTH*2 +: DATA_WIDTH]),
                .m_img_color1           (img_matrix_data[DATA_WIDTH*1 +: DATA_WIDTH]),
                .m_img_color2           (img_matrix_data[DATA_WIDTH*0 +: DATA_WIDTH]),
                .m_img_valid            (img_matrix_valid)
            );
    
    assign img_sink_line_first  = img_matrix_line_first;
    assign img_sink_line_last   = img_matrix_line_last;
    assign img_sink_pixel_first = img_matrix_pixel_first;
    assign img_sink_pixel_last  = img_matrix_pixel_last;
    assign img_sink_de          = img_matrix_de;
    assign img_sink_user        = img_matrix_user;
    assign img_sink_data        = img_matrix_data;
    assign img_sink_valid       = img_matrix_valid;
    
    
    
    // RGB to Gray
    wire                            img_gray_line_first;
    wire                            img_gray_line_last;
    wire                            img_gray_pixel_first;
    wire                            img_gray_pixel_last;
    wire                            img_gray_de;
    wire    [DATA_WIDTH-1:0]        img_gray_gray;
    wire                            img_gray_valid;
    
    jelly_img_rgb_to_gray
            #(
                .USER_WIDTH             (0),
                .DATA_WIDTH             (DATA_WIDTH)
            )
        i_img_rgb_to_gray
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_img_line_first       (img_matrix_line_first),
                .s_img_line_last        (img_matrix_line_last),
                .s_img_pixel_first      (img_matrix_pixel_first),
                .s_img_pixel_last       (img_matrix_pixel_last),
                .s_img_de               (img_matrix_de),
                .s_img_user             (),
                .s_img_rgb              (img_matrix_data[3*DATA_WIDTH-1:0]),
                .s_img_valid            (img_matrix_valid),
                
                .m_img_line_first       (img_gray_line_first),
                .m_img_line_last        (img_gray_line_last),
                .m_img_pixel_first      (img_gray_pixel_first),
                .m_img_pixel_last       (img_gray_pixel_last),
                .m_img_de               (img_gray_de),
                .m_img_user             (),
                .m_img_rgb              (),
                .m_img_gray             (img_gray_gray),
                .m_img_valid            (img_gray_valid)
            );
    
    
    // binarize
    wire                            img_bin_line_first;
    wire                            img_bin_line_last;
    wire                            img_bin_pixel_first;
    wire                            img_bin_pixel_last;
    wire                            img_bin_de;
    wire    [DATA_WIDTH-1:0]        img_bin_data;
    wire                            img_bin_valid;
    
    wire    [WB_DAT_WIDTH-1:0]      wb_bin_dat_o;
    wire                            wb_bin_stb_i;
    wire                            wb_bin_ack_o;
    
    jelly_img_binarizer
            #(
                .USER_WIDTH             (0),
                .DATA_WIDTH             (DATA_WIDTH),
                .BINARY_WIDTH           (DATA_WIDTH),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH)
            )
        i_img_binarizer
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[7:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_bin_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_bin_stb_i),
                .s_wb_ack_o             (wb_bin_ack_o),
                
                .s_img_line_first       (img_gray_line_first),
                .s_img_line_last        (img_gray_line_last),
                .s_img_pixel_first      (img_gray_pixel_first),
                .s_img_pixel_last       (img_gray_pixel_last),
                .s_img_de               (img_gray_de),
                .s_img_user             (),
                .s_img_data             (img_gray_gray),
                .s_img_valid            (img_gray_valid),
                
                .m_img_line_first       (img_bin_line_first),
                .m_img_line_last        (img_bin_line_last),
                .m_img_pixel_first      (img_bin_pixel_first),
                .m_img_pixel_last       (img_bin_pixel_last),
                .m_img_de               (img_bin_de),
                .m_img_user             (),
                .m_img_data             (),
                .m_img_binary           (img_bin_data),
                .m_img_valid            (img_bin_valid)
            );
    
    
    // detect mass center
    wire    [WB_DAT_WIDTH-1:0]      wb_center_dat_o;
    wire                            wb_center_stb_i;
    wire                            wb_center_ack_o;
    
    jelly_img_mass_center
            #(
                .WB_ADR_WIDTH           (6),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .Q_WIDTH                (CENTER_Q_WIDTH),
                .X_WIDTH                (IMG_X_WIDTH),
                .Y_WIDTH                (IMG_Y_WIDTH),
                .OUT_X_WIDTH            (CENTER_X_WIDTH),
                .OUT_Y_WIDTH            (CENTER_Y_WIDTH),
                .X_COUNT_WIDTH          (32),
                .Y_COUNT_WIDTH          (32),
                .N_COUNT_WIDTH          (32)
            )
        i_img_mass_center
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .s_wb_rst_i             (s_wb_rst_i),
                .s_wb_clk_i             (s_wb_clk_i),
                .s_wb_adr_i             (s_wb_adr_i[5:0]),
                .s_wb_dat_i             (s_wb_dat_i),
                .s_wb_dat_o             (wb_center_dat_o),
                .s_wb_we_i              (s_wb_we_i),
                .s_wb_sel_i             (s_wb_sel_i),
                .s_wb_stb_i             (wb_center_stb_i),
                .s_wb_ack_o             (wb_center_ack_o),
                
                .s_img_line_first       (img_bin_line_first),
                .s_img_line_last        (img_bin_line_last),
                .s_img_pixel_first      (img_bin_pixel_first),
                .s_img_pixel_last       (img_bin_pixel_last),
                .s_img_de               (img_bin_de),
                .s_img_data             (img_bin_data),
                .s_img_valid            (img_bin_valid),
                
                .out_x                  (out_center_x),
                .out_y                  (out_center_y),
                .out_valid              (out_center_valid)
            );
    
    
    
    // WISHBONE address decode
    assign wb_demosaic_stb_i = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 0);
    assign wb_matrix_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 1);
    assign wb_bin_stb_i      = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 2);
    assign wb_center_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 3);
    
    assign s_wb_dat_o        = wb_demosaic_stb_i ? wb_demosaic_dat_o :
                               wb_matrix_stb_i   ? wb_matrix_dat_o   :
                               wb_bin_stb_i      ? wb_bin_dat_o      :
                               wb_center_stb_i   ? wb_center_dat_o   :
                               32'h0000_0000;
    
    assign s_wb_ack_o        = wb_demosaic_stb_i ? wb_demosaic_ack_o :
                               wb_matrix_stb_i   ? wb_matrix_ack_o   :
                               wb_bin_stb_i      ? wb_bin_ack_o      :
                               wb_center_stb_i   ? wb_center_ack_o   :
                               s_wb_stb_i;
    
    
endmodule



`default_nettype wire



// end of file
