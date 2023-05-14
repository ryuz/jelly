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
module image_processing
        #(
            parameter   WB_ADR_WIDTH    = 17,
            parameter   WB_DAT_WIDTH    = 32,
            parameter   WB_SEL_WIDTH    = (WB_DAT_WIDTH / 8),
            
            parameter   AXI4_ID_WIDTH   = 6,
            parameter   AXI4_ADDR_WIDTH = 32,
            parameter   AXI4_DATA_SIZE  = 3,    // 0:8bit, 1:16bit, 2:32bit ...
            parameter   AXI4_DATA_WIDTH = (8 << AXI4_DATA_SIZE),
            parameter   AXI4_STRB_WIDTH = AXI4_DATA_WIDTH / 8,
            parameter   AXI4_LEN_WIDTH  = 8,
            parameter   AXI4_QOS_WIDTH  = 4,
            
            parameter   S_DATA_WIDTH    = 10,
            parameter   M_DATA_WIDTH    = 8,
            
            parameter   MAX_X_NUM       = 4096,
            parameter   IMG_Y_NUM       = 480,
            parameter   IMG_Y_WIDTH     = 14,
            
            parameter   TUSER_WIDTH     = 1,
            parameter   S_TDATA_WIDTH   = 1*S_DATA_WIDTH,
            parameter   M_TDATA_WIDTH   = 4*M_DATA_WIDTH
        )
        (
            input   wire                                aresetn,
            input   wire                                aclk,
            
            input   wire                                in_update_req,
            
            input   wire                                s_wb_rst_i,
            input   wire                                s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  wire                                s_wb_ack_o,
            
            input   wire    [TUSER_WIDTH-1:0]           s_axi4s_tuser,
            input   wire                                s_axi4s_tlast,
            input   wire    [S_TDATA_WIDTH-1:0]         s_axi4s_tdata,
            input   wire                                s_axi4s_tvalid,
            output  wire                                s_axi4s_tready,
            
            output  wire    [TUSER_WIDTH-1:0]           m_axi4s_tuser,
            output  wire                                m_axi4s_tlast,
            output  wire    [M_TDATA_WIDTH-1:0]         m_axi4s_tdata,
            output  wire                                m_axi4s_tvalid,
            input   wire                                m_axi4s_tready,
            
            input   wire                                m_axi4_aresetn,
            input   wire                                m_axi4_aclk,
            output  wire    [AXI4_ID_WIDTH-1:0]         m_axi4_awid,
            output  wire    [AXI4_ADDR_WIDTH-1:0]       m_axi4_awaddr,
            output  wire    [AXI4_LEN_WIDTH-1:0]        m_axi4_awlen,
            output  wire    [2:0]                       m_axi4_awsize,
            output  wire    [1:0]                       m_axi4_awburst,
            output  wire    [0:0]                       m_axi4_awlock,
            output  wire    [3:0]                       m_axi4_awcache,
            output  wire    [2:0]                       m_axi4_awprot,
            output  wire    [AXI4_QOS_WIDTH-1:0]        m_axi4_awqos,
            output  wire    [3:0]                       m_axi4_awregion,
            output  wire                                m_axi4_awvalid,
            input   wire                                m_axi4_awready,
            output  wire    [AXI4_DATA_WIDTH-1:0]       m_axi4_wdata,
            output  wire    [AXI4_STRB_WIDTH-1:0]       m_axi4_wstrb,
            output  wire                                m_axi4_wlast,
            output  wire                                m_axi4_wvalid,
            input   wire                                m_axi4_wready,
            input   wire    [AXI4_ID_WIDTH-1:0]         m_axi4_bid,
            input   wire    [1:0]                       m_axi4_bresp,
            input   wire                                m_axi4_bvalid,
            output  wire                                m_axi4_bready,
            output  wire    [AXI4_ID_WIDTH-1:0]         m_axi4_arid,
            output  wire    [AXI4_ADDR_WIDTH-1:0]       m_axi4_araddr,
            output  wire    [AXI4_LEN_WIDTH-1:0]        m_axi4_arlen,
            output  wire    [2:0]                       m_axi4_arsize,
            output  wire    [1:0]                       m_axi4_arburst,
            output  wire    [0:0]                       m_axi4_arlock,
            output  wire    [3:0]                       m_axi4_arcache,
            output  wire    [2:0]                       m_axi4_arprot,
            output  wire    [AXI4_QOS_WIDTH-1:0]        m_axi4_arqos,
            output  wire    [3:0]                       m_axi4_arregion,
            output  wire                                m_axi4_arvalid,
            input   wire                                m_axi4_arready,
            input   wire    [AXI4_ID_WIDTH-1:0]         m_axi4_rid,
            input   wire    [AXI4_DATA_WIDTH-1:0]       m_axi4_rdata,
            input   wire    [1:0]                       m_axi4_rresp,
            input   wire                                m_axi4_rlast,
            input   wire                                m_axi4_rvalid,
            output  wire                                m_axi4_rready
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
                
                .param_blank_num        (8'h0f),
                
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
                .DEVICE                 ("RTL"),
                
                .WB_ADR_WIDTH           (6),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_MATRIX00    (1 << 16),
                .INIT_PARAM_MATRIX01    (0),
                .INIT_PARAM_MATRIX02    (0),
                .INIT_PARAM_MATRIX03    (0),
                .INIT_PARAM_MATRIX10    (0),
                .INIT_PARAM_MATRIX11    (1 << 16),
                .INIT_PARAM_MATRIX12    (0),
                .INIT_PARAM_MATRIX13    (0),
                .INIT_PARAM_MATRIX20    (0),
                .INIT_PARAM_MATRIX21    (0),
                .INIT_PARAM_MATRIX22    (1 << 16),
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
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
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
    
    

    // selector
    localparam  SEL_N = 2;
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
    
    // 外部メモリは利用しない
    assign m_axi4_awid     = '0;
    assign m_axi4_awaddr   = '0;
    assign m_axi4_awlen    = '0;
    assign m_axi4_awsize   = '0;
    assign m_axi4_awburst  = '0;
    assign m_axi4_awlock   = '0;
    assign m_axi4_awcache  = '0;
    assign m_axi4_awprot   = '0;
    assign m_axi4_awqos    = '0;
    assign m_axi4_awregion = '0;
    assign m_axi4_awvalid  = '0;
    assign m_axi4_wdata    = '0;
    assign m_axi4_wstrb    = '0;
    assign m_axi4_wlast    = '0;
    assign m_axi4_wvalid   = '0;
    assign m_axi4_bready   = '0;
    assign m_axi4_arid     = '0;
    assign m_axi4_araddr   = '0;
    assign m_axi4_arlen    = '0;
    assign m_axi4_arsize   = '0;
    assign m_axi4_arburst  = '0;
    assign m_axi4_arlock   = '0;
    assign m_axi4_arcache  = '0;
    assign m_axi4_arprot   = '0;
    assign m_axi4_arqos    = '0;
    assign m_axi4_arregion = '0;
    assign m_axi4_arvalid  = '0;
    assign m_axi4_rready   = '0;
    
    
    // WISHBONE
    assign wb_demos_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 4'h0);
    assign wb_colmat_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 4'h1);
    assign wb_gamma_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 4'h2);
    assign wb_gauss_stb_i   = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 4'h4);
    assign wb_sel_stb_i     = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:13] == 4'hf);
    
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
