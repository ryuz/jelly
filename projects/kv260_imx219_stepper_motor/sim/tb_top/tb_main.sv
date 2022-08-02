// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   X_NUM = 640,   // 3280 / 2,
            parameter   Y_NUM = 132,   // 2464 / 2

            parameter   WB_ADR_WIDTH = 30,
            parameter   WB_DAT_WIDTH = 64,
            parameter   WB_SEL_WIDTH = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        reset,
            input   wire                        clk100,
            input   wire                        clk200,
            input   wire                        clk250,
    
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_peri_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_peri_sel_i,
            input   wire                        s_wb_peri_we_i,
            input   wire                        s_wb_peri_stb_i,
            output  wire                        s_wb_peri_ack_o
        );
    

    // setting
//  localparam FILE_NAME  = "../../data/img_dump_640x132.pgm";
//  localparam FILE_NAME  = "../../data/dump_img_1000fps_raw10.pgm";
    localparam FILE_NAME  = "../test_raw10.pgm";
    localparam FILE_X_NUM = 640;
    localparam FILE_Y_NUM = 132;

    wire    clk = clk100;

    int     sym_cycle = 0;
    always_ff @(posedge clk) begin
        sym_cycle <= sym_cycle + 1;
    end

    localparam  DATA_WIDTH = 10;
    
    // -----------------------------------------
    //  top
    // -----------------------------------------
    
    kv260_imx219_stepper_motor
            #(
                .X_NUM          (X_NUM),
                .Y_NUM          (Y_NUM)
            )
        i_top
            (
                .cam_clk_p      (),
                .cam_clk_n      (),
                .cam_data_p     (),
                .cam_data_n     ()
            );

    
    always_comb force i_top.i_design_1.reset  = reset;
    always_comb force i_top.i_design_1.clk100 = clk100;
    always_comb force i_top.i_design_1.clk200 = clk200;
    always_comb force i_top.i_design_1.clk250 = clk250;

    always_comb force i_top.i_design_1.wb_peri_adr_i = s_wb_peri_adr_i;
    always_comb force i_top.i_design_1.wb_peri_dat_i = s_wb_peri_dat_i;
    always_comb force i_top.i_design_1.wb_peri_sel_i = s_wb_peri_sel_i;
    always_comb force i_top.i_design_1.wb_peri_we_i  = s_wb_peri_we_i;
    always_comb force i_top.i_design_1.wb_peri_stb_i = s_wb_peri_stb_i;

    assign s_wb_peri_dat_o = i_top.i_design_1.wb_peri_dat_o;
    assign s_wb_peri_ack_o = i_top.i_design_1.wb_peri_ack_o;



    // -----------------------------------------
    //  video input
    // -----------------------------------------

    logic                       axi4s_cam_aresetn;
    logic                       axi4s_cam_aclk;

    logic   [0:0]               axi4s_src_tuser;
    logic                       axi4s_src_tlast;
    logic   [DATA_WIDTH-1:0]    axi4s_src_tdata;
    logic                       axi4s_src_tvalid;
    logic                       axi4s_src_tready;

    assign axi4s_cam_aresetn = i_top.axi4s_cam_aresetn;
    assign axi4s_cam_aclk    = i_top.axi4s_cam_aclk;
    assign axi4s_src_tready  = i_top.axi4s_csi2_tready;

    // force を verilator の為に毎回実行する
`ifdef __VERILATOR__
    always_comb begin
`else
    initial begin
`endif
        force i_top.axi4s_csi2_tuser  = axi4s_src_tuser;
        force i_top.axi4s_csi2_tlast  = axi4s_src_tlast;
        force i_top.axi4s_csi2_tdata  = axi4s_src_tdata;
        force i_top.axi4s_csi2_tvalid = axi4s_src_tvalid;
    end

    jelly2_axi4s_master_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (DATA_WIDTH),
                .X_NUM              (X_NUM),
                .Y_NUM              (Y_NUM),
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
                .BUSY_RATE          (0),
                .RANDOM_SEED        (0),
                .ENDIAN             (0)
            )
        i_axi4s_master_model
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),
                
                .enable             (sym_cycle > 4000),
                .busy               (),
                
                .m_axi4s_tuser      (axi4s_src_tuser),
                .m_axi4s_tlast      (axi4s_src_tlast),
                .m_axi4s_tdata      (axi4s_src_tdata),
                .m_axi4s_tx         (),
                .m_axi4s_ty         (),
                .m_axi4s_tf         (),
                .m_axi4s_tvalid     (axi4s_src_tvalid),
                .m_axi4s_tready     (axi4s_src_tready)
            );


    // -----------------------------------------
    //  dump output
    // -----------------------------------------

    wire    [0:0]               axi4s_img_tuser;
    wire                        axi4s_img_tlast;
    wire    [31:0]              axi4s_img_tdata;
    wire                        axi4s_img_tvalid;
    wire                        axi4s_img_tready;
    assign axi4s_img_tuser  = i_top.axi4s_img_tuser;
    assign axi4s_img_tlast  = i_top.axi4s_img_tlast;
    assign axi4s_img_tdata  = i_top.axi4s_img_tdata;
    assign axi4s_img_tvalid = i_top.axi4s_img_tvalid;
    assign axi4s_img_tready = i_top.axi4s_img_tready;
  
    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("img_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_axi4s_slave_model
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_img_tuser),
                .s_axi4s_tlast      (axi4s_img_tlast),
                .s_axi4s_tdata      (axi4s_img_tdata),
                .s_axi4s_tvalid     (axi4s_img_tvalid & axi4s_img_tready),
                .s_axi4s_tready     ()
            );

    // -----------------------------------------
    //  image
    // -----------------------------------------

    logic                               img_reset;
    logic                               img_clk;
    logic                               img_cke;

    // -----------------------------------------
    //  RGB image
    // -----------------------------------------

    always_comb img_reset = i_top.i_image_processing.reset;
    always_comb img_clk   = i_top.i_image_processing.clk;
    always_comb img_cke   = i_top.i_image_processing.cke;


    logic                               img_rgb_row_first;
    logic                               img_rgb_row_last;
    logic                               img_rgb_col_first;
    logic                               img_rgb_col_last;
    logic                               img_rgb_de;
    logic   [DATA_WIDTH-1:0]            img_rgb_r;
    logic   [DATA_WIDTH-1:0]            img_rgb_g;
    logic   [DATA_WIDTH-1:0]            img_rgb_b;
    logic                               img_rgb_valid;

    always_comb img_rgb_row_first = i_top.i_image_processing.img_colmat_row_first;
    always_comb img_rgb_row_last  = i_top.i_image_processing.img_colmat_row_last;
    always_comb img_rgb_col_first = i_top.i_image_processing.img_colmat_col_first;
    always_comb img_rgb_col_last  = i_top.i_image_processing.img_colmat_col_last;
    always_comb img_rgb_de        = i_top.i_image_processing.img_colmat_de;
    always_comb img_rgb_r         = i_top.i_image_processing.img_colmat_r;
    always_comb img_rgb_g         = i_top.i_image_processing.img_colmat_g;
    always_comb img_rgb_b         = i_top.i_image_processing.img_colmat_b;
    always_comb img_rgb_valid     = i_top.i_image_processing.img_colmat_valid;
    
    jelly2_img_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FORMAT             ("P3"),
                .FILE_NAME          ("rgb_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model_rgb
            (
                .reset              (img_reset),
                .clk                (img_clk),
                .cke                (img_cke),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_img_row_first    (img_rgb_row_first),
                .s_img_row_last     (img_rgb_row_last),
                .s_img_col_first    (img_rgb_col_first),
                .s_img_col_last     (img_rgb_col_last),
                .s_img_de           (img_rgb_de),
                .s_img_data         ({img_rgb_b, img_rgb_g, img_rgb_r}),
                .s_img_valid        (img_rgb_valid)
            );

    // -----------------------------------------
    //  Gauss image
    // -----------------------------------------

    logic                               img_gauss_row_first;
    logic                               img_gauss_row_last;
    logic                               img_gauss_col_first;
    logic                               img_gauss_col_last;
    logic                               img_gauss_de;
    logic   [DATA_WIDTH-1:0]            img_gauss_r;
    logic   [DATA_WIDTH-1:0]            img_gauss_g;
    logic   [DATA_WIDTH-1:0]            img_gauss_b;
    logic                               img_gauss_valid;

    always_comb img_gauss_row_first = i_top.i_image_processing.img_gauss_row_first;
    always_comb img_gauss_row_last  = i_top.i_image_processing.img_gauss_row_last;
    always_comb img_gauss_col_first = i_top.i_image_processing.img_gauss_col_first;
    always_comb img_gauss_col_last  = i_top.i_image_processing.img_gauss_col_last;
    always_comb img_gauss_de        = i_top.i_image_processing.img_gauss_de;
    always_comb img_gauss_r         = i_top.i_image_processing.img_gauss_r;
    always_comb img_gauss_g         = i_top.i_image_processing.img_gauss_g;
    always_comb img_gauss_b         = i_top.i_image_processing.img_gauss_b;
    always_comb img_gauss_valid     = i_top.i_image_processing.img_gauss_valid;
    
    jelly2_img_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FORMAT             ("P3"),
                .FILE_NAME          ("gauss_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model_gauss
            (
                .reset              (img_reset),
                .clk                (img_clk),
                .cke                (img_cke),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_img_row_first    (img_gauss_row_first),
                .s_img_row_last     (img_gauss_row_last),
                .s_img_col_first    (img_gauss_col_first),
                .s_img_col_last     (img_gauss_col_last),
                .s_img_de           (img_gauss_de),
                .s_img_data         ({img_gauss_b, img_gauss_g, img_gauss_r}),
                .s_img_valid        (img_gauss_valid)
            );
    
    // -----------------------------------------
    //  HSV image
    // -----------------------------------------

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

    always_comb img_hsv_row_first = i_top.i_image_processing.img_hsv_row_first;
    always_comb img_hsv_row_last  = i_top.i_image_processing.img_hsv_row_last;
    always_comb img_hsv_col_first = i_top.i_image_processing.img_hsv_col_first;
    always_comb img_hsv_col_last  = i_top.i_image_processing.img_hsv_col_last;
    always_comb img_hsv_de        = i_top.i_image_processing.img_hsv_de;
    always_comb img_hsv_raw       = i_top.i_image_processing.img_hsv_raw;
    always_comb img_hsv_h         = i_top.i_image_processing.img_hsv_h;
    always_comb img_hsv_s         = i_top.i_image_processing.img_hsv_s;
    always_comb img_hsv_v         = i_top.i_image_processing.img_hsv_v;
    always_comb img_hsv_valid     = i_top.i_image_processing.img_hsv_valid;
  
    jelly2_img_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FORMAT             ("P3"),
                .FILE_NAME          ("hsv_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model_hsv
            (
                .reset              (img_reset),
                .clk                (img_clk),
                .cke                (img_cke),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_img_row_first    (img_hsv_row_first),
                .s_img_row_last     (img_hsv_row_last),
                .s_img_col_first    (img_hsv_col_first),
                .s_img_col_last     (img_hsv_col_last),
                .s_img_de           (img_hsv_de),
                .s_img_data         ({img_hsv_v, img_hsv_s, img_hsv_h}),
                .s_img_valid        (img_hsv_valid)
            );


    // -----------------------------------------
    //  Binary
    // -----------------------------------------

    logic                               img_bin_row_first;
    logic                               img_bin_row_last;
    logic                               img_bin_col_first;
    logic                               img_bin_col_last;
    logic                               img_bin_de;
    logic   [0:0]                       img_bin_data;
    logic                               img_bin_valid;

    always_comb img_bin_row_first = i_top.i_image_processing.img_bin_row_first;
    always_comb img_bin_row_last  = i_top.i_image_processing.img_bin_row_last;
    always_comb img_bin_col_first = i_top.i_image_processing.img_bin_col_first;
    always_comb img_bin_col_last  = i_top.i_image_processing.img_bin_col_last;
    always_comb img_bin_de        = i_top.i_image_processing.img_bin_de;
    always_comb img_bin_data      = i_top.i_image_processing.img_bin_data;
    always_comb img_bin_valid     = i_top.i_image_processing.img_bin_valid;
  
    jelly2_img_slave_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (1),
                .INIT_FRAME_NUM     (0),
                .X_WIDTH            (32),
                .Y_WIDTH            (32),
                .F_WIDTH            (32),
                .FORMAT             ("P2"),
                .FILE_NAME          ("bin_"),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model_bin
            (
                .reset              (img_reset),
                .clk                (img_clk),
                .cke                (img_cke),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_img_row_first    (img_bin_row_first),
                .s_img_row_last     (img_bin_row_last),
                .s_img_col_first    (img_bin_col_first),
                .s_img_col_last     (img_bin_col_last),
                .s_img_de           (img_bin_de),
                .s_img_data         (img_bin_data),
                .s_img_valid        (img_bin_valid)
            );


endmodule


`default_nettype wire


// end of file
