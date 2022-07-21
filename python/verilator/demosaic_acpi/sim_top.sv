// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module top
        #(
            parameter   int     IMG_X_WIDTH   = 32,
            parameter   int     IMG_Y_WIDTH   = 32,
            parameter   int     TUSER_WIDTH   = 1,
            parameter   int     DATA_WIDTH    = 10,
            parameter   int     WB_ADR_WIDTH  = 8,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
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
            output  wire    [3:0][DATA_WIDTH-1:0]   m_axi4s_tdata,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready,

            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  wire                            s_wb_ack_o
        );
    
    /*
    localparam                              FILE_NAME  = "dump_img_1000fps_raw10.pgm";
    localparam                              FILE_X_NUM = 640;
    localparam                              FILE_Y_NUM = 132;

    localparam  int                         IMG_WIDTH  = 640;
    localparam  int                         IMG_HEIGHT = 132;
    */

    // -----------------------------------------
    //  top
    // -----------------------------------------

    localparam  bit                         SIZE_AUTO        = 1;
//  localparam  int                         TUSER_WIDTH      = 1;
//  localparam  int                         DATA_WIDTH       = 10;
    localparam  int                         MAX_X_NUM        = 4096;
    localparam                              RAM_TYPE         = "block";
    localparam  bit     [IMG_Y_WIDTH-1:0]   INIT_Y_NUM       = 480;
    localparam  int                         FIFO_PTR_WIDTH   = IMG_X_WIDTH;
    localparam                              FIFO_RAM_TYPE    = "block";

    localparam  bit     [31:0]              CORE_ID          = 32'h527a_2110;
    localparam  bit     [31:0]              CORE_VERSION     = 32'h0001_0000;
    localparam  int                         INDEX_WIDTH      = 1;

    localparam  bit     [1:0]               INIT_CTL_CONTROL = 2'b00;
    localparam  bit     [1:0]               INIT_PARAM_PHASE = 2'b00;

//    logic                           aresetn;
//    logic                           aclk;
//    logic                           aclken;
//    logic                           in_update_req;
//    logic   [IMG_X_WIDTH-1:0]       param_img_width;
//    logic   [IMG_Y_WIDTH-1:0]       param_img_height;
    /*
    logic   [TUSER_WIDTH-1:0]       s_axi4s_tuser;
    logic                           s_axi4s_tlast;
    logic   [DATA_WIDTH-1:0]        s_axi4s_tdata;
    logic                           s_axi4s_tvalid;
    logic                           s_axi4s_tready;
    logic   [TUSER_WIDTH-1:0]       m_axi4s_tuser;
    logic                           m_axi4s_tlast;
    logic   [DATA_WIDTH-1:0]        m_axi4s_tdata_r;
    logic   [DATA_WIDTH-1:0]        m_axi4s_tdata_g;
    logic   [DATA_WIDTH-1:0]        m_axi4s_tdata_b;
    logic   [DATA_WIDTH-1:0]        m_axi4s_tdata_raw;
    logic                           m_axi4s_tvalid;
    logic                           m_axi4s_tready;
    logic                           s_wb_rst_i;
    logic                           s_wb_clk_i;
    */

    // demosaic with ACPI
    jelly2_video_demosaic_acpi
            #(
                .SIZE_AUTO          (SIZE_AUTO),
                .TUSER_WIDTH        (TUSER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .IMG_X_WIDTH        (IMG_X_WIDTH),
                .IMG_Y_WIDTH        (IMG_Y_WIDTH),
                .MAX_X_NUM          (MAX_X_NUM),
                .RAM_TYPE           (RAM_TYPE),
                .INIT_Y_NUM         (INIT_Y_NUM),
                .FIFO_PTR_WIDTH     (FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE      (FIFO_RAM_TYPE),
                .WB_ADR_WIDTH       (WB_ADR_WIDTH),
                .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                .WB_SEL_WIDTH       (WB_SEL_WIDTH),
                .CORE_ID            (CORE_ID),
                .CORE_VERSION       (CORE_VERSION),
                .INDEX_WIDTH        (INDEX_WIDTH),
                .INIT_CTL_CONTROL   (INIT_CTL_CONTROL),
                .INIT_PARAM_PHASE   (INIT_PARAM_PHASE)
            )
        i_video_demosaic_acpi
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (aclken),

                .in_update_req      (1'b1),
                
                .param_img_width    (param_img_width),
                .param_img_height   (param_img_height),
                
                .s_axi4s_tuser      (s_axi4s_tuser),
                .s_axi4s_tlast      (s_axi4s_tlast),
                .s_axi4s_tdata      (s_axi4s_tdata),
                .s_axi4s_tvalid     (s_axi4s_tvalid),
                .s_axi4s_tready     (s_axi4s_tready),

                .m_axi4s_tuser      (m_axi4s_tuser),
                .m_axi4s_tlast      (m_axi4s_tlast),
                .m_axi4s_tdata_r    (m_axi4s_tdata[0]),
                .m_axi4s_tdata_g    (m_axi4s_tdata[1]),
                .m_axi4s_tdata_b    (m_axi4s_tdata[2]),
                .m_axi4s_tdata_raw  (m_axi4s_tdata[3]),
                .m_axi4s_tvalid     (m_axi4s_tvalid),
                .m_axi4s_tready     (m_axi4s_tready),

                .s_wb_rst_i         (s_wb_rst_i),
                .s_wb_clk_i         (s_wb_clk_i),
                .s_wb_adr_i         (s_wb_adr_i),
                .s_wb_dat_i         (s_wb_dat_i),
                .s_wb_dat_o         (s_wb_dat_o),
                .s_wb_we_i          (s_wb_we_i ),
                .s_wb_sel_i         (s_wb_sel_i),
                .s_wb_stb_i         (s_wb_stb_i),
                .s_wb_ack_o         (s_wb_ack_o)
            );
    
    /*
    // -----------------------------------------
    //  video input
    // -----------------------------------------

    jelly2_axi4s_master_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (DATA_WIDTH),
                .X_NUM              (IMG_WIDTH),
                .Y_NUM              (IMG_HEIGHT),
                .X_BLANK            (128),
                .Y_BLANK            (16),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FILE_NAME          (FILE_NAME),
                .FILE_EXT           (""),
                .FILE_X_NUM         (FILE_X_NUM),
                .FILE_Y_NUM         (FILE_Y_NUM),
                .SEQUENTIAL_FILE    (0),
                .BUSY_RATE          (20),
                .RANDOM_SEED        (1),
                .ENDIAN             (0)
            )
        i_axi4s_master_model
            (
                .aresetn            (~reset),
                .aclk               (clk),
                .aclken             (1'b1),
                
                .enable             (1'b1),
                .busy               (),
                
                .m_axi4s_tuser      (s_axi4s_tuser),
                .m_axi4s_tlast      (s_axi4s_tlast),
                .m_axi4s_tdata      (s_axi4s_tdata),
                .m_axi4s_tx         (),
                .m_axi4s_ty         (),
                .m_axi4s_tf         (),
                .m_axi4s_tvalid     (s_axi4s_tvalid),
                .m_axi4s_tready     (s_axi4s_tready)
            );


    // -----------------------------------------
    //  dump output
    // -----------------------------------------

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("img_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0),
                .BUSY_RATE          (30),
                .RANDOM_SEED        (732)
            )
        i_axi4s_slave_model
            (
                .aresetn            (~reset),
                .aclk               (clk),
                .aclken             (1'b1),

                .param_width        (IMG_WIDTH),
                .param_height       (IMG_HEIGHT),
                .frame_num          (),
                
                .s_axi4s_tuser      (m_axi4s_tuser),
                .s_axi4s_tlast      (m_axi4s_tlast),
                .s_axi4s_tdata      ({m_axi4s_tdata_b, m_axi4s_tdata_g, m_axi4s_tdata_r}),
                .s_axi4s_tvalid     (m_axi4s_tvalid),
                .s_axi4s_tready     (m_axi4s_tready)
            );
    */

endmodule


`default_nettype wire


// end of file
