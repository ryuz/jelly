// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_video_box_filter
        #(
            parameter   bit                                                                 SIZE_AUTO         = 0,
            parameter   int                                                                 TUSER_WIDTH       = 1,
            parameter   int                                                                 COMPONENTS        = 3,
            parameter   int                                                                 DATA_WIDTH        = 8,
            parameter   int                                                                 ROWS              = 3,
            parameter   int                                                                 COLS              = 3,
            parameter   int                                                                 CENTER_Y          = (ROWS-1) / 2,
            parameter   int                                                                 CENTER_X          = (COLS-1) / 2,
            parameter   int                                                                 MAX_COLS          = 4096,
            parameter   int                                                                 USER_WIDTH        = 0,
            parameter   int                                                                 COEFF_WIDTH       = 18,
            parameter   int                                                                 COEFF_FRAC        = 8,
            parameter   int                                                                 MAC_WIDTH         = DATA_WIDTH + COEFF_WIDTH,
            parameter   bit                                                                 SIGNED            = 0,
            parameter                                                                       BORDER_MODE       = "REPLICATE",
            parameter   bit         [COMPONENTS-1:0][DATA_WIDTH-1:0]                        BORDER_VALUE      = '0,
            parameter                                                                       RAM_TYPE          = "block",
            parameter   int                                                                 IMG_X_WIDTH       = 10,
            parameter   int                                                                 IMG_Y_WIDTH       = 9,
            parameter   bit         [IMG_Y_WIDTH-1:0]                                       INIT_Y_NUM        = 480,
            parameter   int                                                                 FIFO_PTR_WIDTH    = IMG_X_WIDTH,
            parameter                                                                       FIFO_RAM_TYPE     = "block",
            parameter   bit                                                                 ENDIAN            = 0,
            parameter   bit                                                                 USE_VALID         = 1,

            parameter   bit         [31:0]                                                  CORE_ID           = 32'h527a_2300,
            parameter   bit         [31:0]                                                  CORE_VERSION      = 32'h0001_0000,
            parameter   int                                                                 INDEX_WIDTH       = 1,

            parameter   int                                                                 WB_ADR_WIDTH      = 8,
            parameter   int                                                                 WB_DAT_WIDTH      = 32,
            parameter   int                                                                 WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8),

            parameter   bit         [1:0]                                                   INIT_CTL_CONTROL  = 2'b00,
            parameter   bit         [DATA_WIDTH-1:0]                                        INIT_PARAM_MIN    = '0,
            parameter   bit         [DATA_WIDTH-1:0]                                        INIT_PARAM_MAX    = '1,
            parameter   bit signed  [COMPONENTS-1:0][ROWS-1:0][COLS-1:0][COEFF_WIDTH-1:0]   INIT_PARAM_COEFF  = '0
        )
        (
            input   wire                                        aresetn,
            input   wire                                        aclk,
            input   wire                                        aclken,

            input   wire                                        in_update_req,

            input   wire    [IMG_X_WIDTH-1:0]                   param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]                   param_img_height,

            input   wire    [TUSER_WIDTH-1:0]                   s_axi4s_tuser,
            input   wire                                        s_axi4s_tlast,
            input   wire    [COMPONENTS-1:0][DATA_WIDTH-1:0]    s_axi4s_tdata,
            input   wire                                        s_axi4s_tvalid,
            output  wire                                        s_axi4s_tready,
            
            output  wire    [TUSER_WIDTH-1:0]                   m_axi4s_tuser,
            output  wire                                        m_axi4s_tlast,
            output  wire    [COMPONENTS-1:0][DATA_WIDTH-1:0]    m_axi4s_tdata,
            output  wire                                        m_axi4s_tvalid,
            input   wire                                        m_axi4s_tready,

            input   wire                                        s_wb_rst_i,
            input   wire                                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]                  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]                  s_wb_dat_o,
            input   wire                                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]                  s_wb_sel_i,
            input   wire                                        s_wb_stb_i,
            output  wire                                        s_wb_ack_o
        );

    localparam  BLANK_Y_WIDTH = $clog2(ROWS+1);

    // axi4 -> img
    logic                                       img_cke;

    logic                                       img_src_row_first;
    logic                                       img_src_row_last;
    logic                                       img_src_col_first;
    logic                                       img_src_col_last;
    logic                                       img_src_de;
    logic   [TUSER_WIDTH-1:0]                   img_src_user;
    logic   [COMPONENTS-1:0][DATA_WIDTH-1:0]    img_src_data;
    logic                                       img_src_valid;

    logic                                       img_sink_row_first;
    logic                                       img_sink_row_last;
    logic                                       img_sink_col_first;
    logic                                       img_sink_col_last;
    logic                                       img_sink_de;
    logic   [TUSER_WIDTH-1:0]                   img_sink_user;
    logic   [COMPONENTS-1:0][DATA_WIDTH-1:0]    img_sink_data;
    logic                                       img_sink_valid;

    jelly2_axi4s_img
            #(
                .SIZE_AUTO              (SIZE_AUTO),
                .TUSER_WIDTH            (TUSER_WIDTH),
                .S_TDATA_WIDTH          (COMPONENTS*DATA_WIDTH),
                .M_TDATA_WIDTH          (COMPONENTS*DATA_WIDTH),
                .IMG_X_WIDTH            (IMG_X_WIDTH),
                .IMG_Y_WIDTH            (IMG_Y_WIDTH),
                .BLANK_Y_WIDTH          (BLANK_Y_WIDTH),
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
                .param_blank_height     (BLANK_Y_WIDTH'(ROWS)),
                
                .s_axi4s_tuser,
                .s_axi4s_tlast,
                .s_axi4s_tdata,
                .s_axi4s_tvalid,
                .s_axi4s_tready,
                
                .m_axi4s_tuser,
                .m_axi4s_tlast,
                .m_axi4s_tdata,
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
    

    jelly2_img_box
            #(
                .COMPONENTS             (COMPONENTS),
                .ROWS                   (ROWS),
                .COLS                   (COLS),
                .CENTER_Y               (CENTER_Y),
                .CENTER_X               (CENTER_X),
                .MAX_COLS               (MAX_COLS),
                .USER_WIDTH             (TUSER_WIDTH),
                .DATA_WIDTH             (DATA_WIDTH),
                .COEFF_WIDTH            (COEFF_WIDTH),
                .COEFF_FRAC             (COEFF_FRAC),
                .MAC_WIDTH              (MAC_WIDTH),
                .SIGNED                 (SIGNED),
                .BORDER_MODE            (BORDER_MODE),
                .BORDER_VALUE           (BORDER_VALUE),
                .RAM_TYPE               (RAM_TYPE),
                .ENDIAN                 (ENDIAN),
                .USE_VALID              (USE_VALID),
                .CORE_ID                (CORE_ID),
                .CORE_VERSION           (CORE_VERSION),
                .INDEX_WIDTH            (INDEX_WIDTH),
                .WB_ADR_WIDTH           (WB_ADR_WIDTH),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH),
                .WB_SEL_WIDTH           (WB_SEL_WIDTH),
                .INIT_CTL_CONTROL       (INIT_CTL_CONTROL),
                .INIT_PARAM_MIN         (INIT_PARAM_MIN),
                .INIT_PARAM_MAX         (INIT_PARAM_MAX),
                .INIT_PARAM_COEFF       (INIT_PARAM_COEFF)
            )
        i_img_box
            (
                .reset                  (~aresetn),
                .clk                    (aclk),
                .cke                    (aclken),
                
                .in_update_req,
                
                .s_img_row_first        (img_src_row_first),
                .s_img_row_last         (img_src_row_last),
                .s_img_col_first        (img_src_col_first),
                .s_img_col_last         (img_src_col_last),
                .s_img_de               (img_src_de),
                .s_img_user             (img_src_user),
                .s_img_data             (img_src_data),
                .s_img_valid            (img_src_valid),
                
                .m_img_row_first        (img_sink_row_first),
                .m_img_row_last         (img_sink_row_last),
                .m_img_col_first        (img_sink_col_first),
                .m_img_col_last         (img_sink_col_last),
                .m_img_de               (img_sink_de),
                .m_img_user             (img_sink_user),
                .m_img_data             (img_sink_data),
                .m_img_valid            (img_sink_valid),

                .s_wb_rst_i,
                .s_wb_clk_i,
                .s_wb_adr_i,
                .s_wb_dat_i,
                .s_wb_dat_o,
                .s_wb_we_i,
                .s_wb_sel_i,
                .s_wb_stb_i,
                .s_wb_ack_o
        );
    
    
    
endmodule


`default_nettype wire


// end of file
