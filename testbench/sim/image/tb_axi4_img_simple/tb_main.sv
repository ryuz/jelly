// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );
    
    
    // -----------------------------------------
    //  top
    // -----------------------------------------

    parameter   int                         TUSER_WIDTH    = 1;
    parameter   int                         S_TDATA_WIDTH  = 8;
    parameter   int                         M_TDATA_WIDTH  = 8;
    parameter   int                         IMG_X_WIDTH    = 10;
    parameter   int                         IMG_Y_WIDTH    = 9;
    parameter   int                         BLANK_Y_WIDTH  = 7;
    parameter   bit                         WITH_DE        = 1;
    parameter   bit                         WITH_VALID     = 1;
    parameter   bit                         IMG_CKE_BUFG   = 0;
    localparam  int                         USER_WIDTH     = TUSER_WIDTH > 1 ? TUSER_WIDTH - 1 : 1;

    logic                               aresetn;
    logic                               aclk;
    logic                               aclken;

    logic   [IMG_X_WIDTH-1:0]           param_img_width;
    logic   [IMG_Y_WIDTH-1:0]           param_img_height;
    logic   [BLANK_Y_WIDTH-1:0]         param_blank_height;

    wire    [TUSER_WIDTH-1:0]           s_axi4s_tuser;
    wire                                s_axi4s_tlast;
    wire    [S_TDATA_WIDTH-1:0]         s_axi4s_tdata;
    wire                                s_axi4s_tvalid;
    wire                                s_axi4s_tready;

    wire    [TUSER_WIDTH-1:0]           m_axi4s_tuser;
    wire                                m_axi4s_tlast;
    wire    [M_TDATA_WIDTH-1:0]         m_axi4s_tdata;
    wire                                m_axi4s_tvalid;
    wire                                m_axi4s_tready;

    wire                                img_cke;

    wire                                m_img_src_row_first;
    wire                                m_img_src_row_last;
    wire                                m_img_src_col_first;
    wire                                m_img_src_col_last;
    wire                                m_img_src_de;
    wire    [USER_WIDTH-1:0]            m_img_src_user;
    wire    [S_TDATA_WIDTH-1:0]         m_img_src_data;
    wire                                m_img_src_valid;

    wire                                s_img_sink_row_first;
    wire                                s_img_sink_row_last;
    wire                                s_img_sink_col_first;
    wire                                s_img_sink_col_last;
    wire                                s_img_sink_de;
    wire    [USER_WIDTH-1:0]            s_img_sink_user;
    wire    [M_TDATA_WIDTH-1:0]         s_img_sink_data;
    wire                                s_img_sink_valid;

    assign aresetn = ~reset;
    assign aclk    = clk;
    always_ff @(posedge clk) aclken <= 1'($random());

    jelly2_axi4s_img_simple
            #(
                .TUSER_WIDTH    (TUSER_WIDTH  ),
                .S_TDATA_WIDTH  (S_TDATA_WIDTH),
                .M_TDATA_WIDTH  (M_TDATA_WIDTH),
                .IMG_X_WIDTH    (IMG_X_WIDTH  ),
                .IMG_Y_WIDTH    (IMG_Y_WIDTH  ),
                .BLANK_Y_WIDTH  (BLANK_Y_WIDTH),
                .WITH_DE        (WITH_DE      ),
                .WITH_VALID     (WITH_VALID   ),
                .IMG_CKE_BUFG   (IMG_CKE_BUFG )
            )
        i_top
            (
                .aresetn,
                .aclk,
                .aclken,
                .param_img_width,
                .param_img_height,
                .param_blank_height,
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
                .m_img_src_row_first,
                .m_img_src_row_last,
                .m_img_src_col_first,
                .m_img_src_col_last,
                .m_img_src_de,
                .m_img_src_user,
                .m_img_src_data,
                .m_img_src_valid,
                .s_img_sink_row_first,
                .s_img_sink_row_last,
                .s_img_sink_col_first,
                .s_img_sink_col_last,
                .s_img_sink_de,
                .s_img_sink_user,
                .s_img_sink_data,
                .s_img_sink_valid
            );
    
    
    // -----------------------------------------
    //  video input
    // -----------------------------------------

    localparam  X_NUM = 128;
    localparam  Y_NUM = 64;

    assign  param_img_width    = IMG_X_WIDTH'(X_NUM);
    assign  param_img_height   = IMG_Y_WIDTH'(Y_NUM);
    assign  param_blank_height = BLANK_Y_WIDTH'(7);

    assign  s_img_sink_row_first = m_img_src_row_first;
    assign  s_img_sink_row_last  = m_img_src_row_last;
    assign  s_img_sink_col_first = m_img_src_col_first;
    assign  s_img_sink_col_last  = m_img_src_col_last;
    assign  s_img_sink_de        = m_img_src_de;
    assign  s_img_sink_user      = m_img_src_user;
    assign  s_img_sink_data      = M_TDATA_WIDTH'(m_img_src_data);
    assign  s_img_sink_valid     = m_img_src_valid;

    jelly2_axi4s_master_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (S_TDATA_WIDTH),
                .X_NUM              (X_NUM),
                .Y_NUM              (Y_NUM),
                .X_BLANK            (128),
                .Y_BLANK            (16),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FILE_NAME          (""),
                .FILE_EXT           (""),
                .FILE_X_NUM         (X_NUM),
                .FILE_Y_NUM         (Y_NUM),
                .SEQUENTIAL_FILE    (0),
                .BUSY_RATE          (20),
                .RANDOM_SEED        (1),
                .ENDIAN             (0)
            )
        i_axi4s_master_model
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (aclken),
                
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
                .COMPONENTS         (1),
                .DATA_WIDTH         (M_TDATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P2"),
                .FILE_NAME          ("img_"),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0),
                .BUSY_RATE          (30),
                .RANDOM_SEED        (732)
            )
        i_axi4s_slave_model
            (
                .aresetn            (aresetn),
                .aclk               (aclk),
                .aclken             (aclken),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (m_axi4s_tuser),
                .s_axi4s_tlast      (m_axi4s_tlast),
                .s_axi4s_tdata      (m_axi4s_tdata),
                .s_axi4s_tvalid     (m_axi4s_tvalid),
                .s_axi4s_tready     (m_axi4s_tready)
            );

endmodule


`default_nettype wire


// end of file
