// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module video_raw_to_rgb
        #(
            parameter   WB_ADR_WIDTH  = 10,
            parameter   WB_DAT_WIDTH  = 32,
            parameter   WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            
            parameter   DATA_WIDTH    = 10,
            
            parameter   X_WIDTH       = 13,
            parameter   Y_WIDTH       = 12,
            
            parameter   TUSER_WIDTH   = 1,
            parameter   S_TDATA_WIDTH = DATA_WIDTH,
            parameter   M_TDATA_WIDTH = 4*DATA_WIDTH,
            
            parameter   DEVICE        = "RTL"
        )
        (
            input   wire                        aresetn,
            input   wire                        aclk,
            
            input   wire                        in_update_req,

            input   wire    [X_WIDTH-1:0]       param_width,
            input   wire    [Y_WIDTH-1:0]       param_height,

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

            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );
    
    
    wire                                reset = ~aresetn;
    wire                                clk   = aclk;
    wire                                cke;
    
    wire                                img_src_row_first;
    wire                                img_src_row_last;
    wire                                img_src_col_first;
    wire                                img_src_col_last;
    wire                                img_src_de;
    wire    [TUSER_WIDTH-1:0]           img_src_user;
    wire    [S_TDATA_WIDTH-1:0]         img_src_data;
    wire                                img_src_valid;
    
    wire                                img_sink_row_first;
    wire                                img_sink_row_last;
    wire                                img_sink_col_first;
    wire                                img_sink_col_last;
    wire                                img_sink_de;
    wire    [TUSER_WIDTH-1:0]           img_sink_user;
    wire    [M_TDATA_WIDTH-1:0]         img_sink_data;
    wire                                img_sink_valid;
    
    // img
    jelly2_axi4s_img
            #(
                .SIZE_AUTO              (0),
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (S_TDATA_WIDTH),
                .M_TDATA_WIDTH          (M_TDATA_WIDTH),
                .IMG_X_WIDTH            (X_WIDTH),
                .IMG_Y_WIDTH            (Y_WIDTH),
                .BLANK_Y_WIDTH          (4),
                .WITH_DE                (1),
                .WITH_VALID             (1),
                .IMG_CKE_BUFG           (0)
            )   
        i_axi4s_img 
            (   
                .aresetn                (aresetn),
                .aclk                   (aclk),
                .aclken                 (1'b1),

                .param_img_width        (param_width),
                .param_img_height       (param_height),
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
    wire                                img_demos_row_first;
    wire                                img_demos_row_last;
    wire                                img_demos_col_first;
    wire                                img_demos_col_last;
    wire                                img_demos_de;
    wire    [TUSER_WIDTH-1:0]           img_demos_user;
    wire    [DATA_WIDTH-1:0]            img_demos_raw;
    wire    [DATA_WIDTH-1:0]            img_demos_r;
    wire    [DATA_WIDTH-1:0]            img_demos_g;
    wire    [DATA_WIDTH-1:0]            img_demos_b;
    wire                                img_demos_valid;
    
    wire    [WB_DAT_WIDTH-1:0]          wb_demos_dat_o;
    wire                                wb_demos_stb_i;
    wire                                wb_demos_ack_o;
    
    jelly2_img_demosaic_acpi
            #(
                .USER_WIDTH             (TUSER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .MAX_COLS               (4096),
                .RAM_TYPE               ("block"),
                
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
    
    
    wire    [WB_DAT_WIDTH-1:0]          wb_colmat_dat_o;
    wire                                wb_colmat_stb_i;
    wire                                wb_colmat_ack_o;
    
    jelly2_img_color_matrix
            #(
                .USER_WIDTH             (TUSER_WIDTH+10),
                .DATA_WIDTH             (DATA_WIDTH),
                .INTERNAL_WIDTH         (DATA_WIDTH+2),
                
                .COEFF_INT_WIDTH        (9),
                .COEFF_FRAC_WIDTH       (16),
                .COEFF3_INT_WIDTH       (9),
                .COEFF3_FRAC_WIDTH      (16),
                .STATIC_COEFF           (1),
                .DEVICE                 (DEVICE),
                
                .WB_ADR_WIDTH           (8),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                
                .INIT_PARAM_MATRIX00    (25'h010000),
                .INIT_PARAM_MATRIX01    (25'h000000),
                .INIT_PARAM_MATRIX02    (25'h000000),
                .INIT_PARAM_MATRIX03    (25'h000000),
                .INIT_PARAM_MATRIX10    (25'h000000),
                .INIT_PARAM_MATRIX11    (25'h010000),
                .INIT_PARAM_MATRIX12    (25'h000000),
                .INIT_PARAM_MATRIX13    (25'h000000),
                .INIT_PARAM_MATRIX20    (25'h000000),
                .INIT_PARAM_MATRIX21    (25'h000000),
                .INIT_PARAM_MATRIX22    (25'h010000),
                .INIT_PARAM_MATRIX23    (25'h000000),
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
                
                .m_img_row_first        (img_sink_row_first),
                .m_img_row_last         (img_sink_row_last),
                .m_img_col_first        (img_sink_col_first),
                .m_img_col_last         (img_sink_col_last),
                .m_img_de               (img_sink_de),
                .m_img_user             ({img_sink_user, img_sink_data[DATA_WIDTH*3 +: DATA_WIDTH]}),
                .m_img_color0           (img_sink_data[DATA_WIDTH*2 +: DATA_WIDTH]),
                .m_img_color1           (img_sink_data[DATA_WIDTH*1 +: DATA_WIDTH]),
                .m_img_color2           (img_sink_data[DATA_WIDTH*0 +: DATA_WIDTH]),
                .m_img_valid            (img_sink_valid)
            );
    
    assign wb_demos_stb_i  = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 0);
    assign wb_colmat_stb_i = s_wb_stb_i & (s_wb_adr_i[WB_ADR_WIDTH-1:8] == 1);
    
    assign s_wb_dat_o      = wb_demos_stb_i  ? wb_demos_dat_o  :
                             wb_colmat_stb_i ? wb_colmat_dat_o :
                             '0;
    
    assign s_wb_ack_o      = wb_demos_stb_i  ? wb_demos_ack_o  :
                             wb_colmat_stb_i ? wb_colmat_ack_o :
                             s_wb_stb_i;
    
    
endmodule



`default_nettype wire



// end of file
