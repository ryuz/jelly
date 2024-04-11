// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
//          parameter   X_NUM = 3280 / 2,
//          parameter   Y_NUM = 2464 / 2
            parameter   X_NUM = 640,
            parameter   Y_NUM = 480,
//          parameter   X_NUM = 640,
//          parameter   Y_NUM = 132,

            parameter   WB_ADR_WIDTH = 37,
            parameter   WB_DAT_WIDTH = 64,
            parameter   WB_SEL_WIDTH = (WB_DAT_WIDTH / 8)
        )
        (
            input   var logic                       reset,
            input   var logic                       clk100,
            input   var logic                       clk200,
            input   var logic                       clk250,
    
            input   var logic   [WB_ADR_WIDTH-1:0]  s_wb_peri_adr_i,
            output  var logic   [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_o,
            input   var logic   [WB_DAT_WIDTH-1:0]  s_wb_peri_dat_i,
            input   var logic   [WB_SEL_WIDTH-1:0]  s_wb_peri_sel_i,
            input   var logic                       s_wb_peri_we_i,
            input   var logic                       s_wb_peri_stb_i,
            output  var logic                       s_wb_peri_ack_o,

            output  var logic   [31:0]              img_x_num,
            output  var logic   [31:0]              img_y_num
        );

    assign img_x_num = X_NUM;
    assign img_y_num = Y_NUM;


    // setting
//  localparam FILE_NAME  = "../../data/img_dump_640x132.pgm";
//  localparam FILE_NAME  = "../../data/dump_img_1000fps_raw10.pgm";
//  localparam FILE_NAME  = "../test_raw10.pgm";
//  localparam FILE_X_NUM = 640;
//  localparam FILE_Y_NUM = 132;

//  localparam FILE_NAME  = "../../../../../../data/images/windowswallpaper/Penguins_640x480_bayer10.pgm";

    localparam FILE_NAME  = "../../mnist_test_640x480.pgm";
    localparam FILE_X_NUM = 640;
    localparam FILE_Y_NUM = 480;
    localparam DATA_WIDTH = 10;

//  localparam FILE_NAME  = "../../mnist_test_160x120.pgm";
//  localparam FILE_X_NUM = 160;
//  localparam FILE_Y_NUM = 120;
//  localparam DATA_WIDTH = 10;


    // cycle counter
    wire    clk = clk100;

    int     sym_cycle = 0;
    always_ff @(posedge clk) begin
        sym_cycle <= sym_cycle + 1;
    end

    
    // -----------------------------------------
    //  top
    // -----------------------------------------
    
    kv260_imx219_mnist_seg
            #(
                .X_NUM          (X_NUM),
                .Y_NUM          (Y_NUM)
            )
        i_top
            (
                .fan_en         (),
                
                .cam_clk_p      (),
                .cam_clk_n      (),
                .cam_data_p     (),
                .cam_data_n     (),
                
                .cam_enable     (),
                .cam_scl        (),
                .cam_sda        (),

                .pmod           ()
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
    always_comb force   i_top.i_mipi_csi2_rx.axi4s_tuser  = axi4s_src_tuser;
    always_comb force   i_top.i_mipi_csi2_rx.axi4s_tlast  = axi4s_src_tlast;
    always_comb force   i_top.i_mipi_csi2_rx.axi4s_tdata  = axi4s_src_tdata;
    always_comb force   i_top.i_mipi_csi2_rx.axi4s_tvalid = axi4s_src_tvalid;
    
 //   assign axi4s_cam_aresetn = i_top.i_mipi_csi2_rx.axi4s_aresetn;
 //   assign axi4s_cam_aclk    = i_top.i_mipi_csi2_rx.axi4s_aclk;
 //   assign axi4s_src_tready  = i_top.i_mipi_csi2_rx.axi4s_tready;
 //   always_comb force   i_top.i_mipi_csi2_rx.axi4s_tuser  = axi4s_src_tuser    ;
 //   always_comb force   i_top.i_mipi_csi2_rx.axi4s_tlast  = axi4s_src_tlast    ;   
 //   always_comb force   i_top.i_mipi_csi2_rx.axi4s_tdata  = axi4s_src_tdata    ;
 //   always_comb force   i_top.i_mipi_csi2_rx.axi4s_tvalid = axi4s_src_tvalid   ;

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

    wire    [0:0]                   axi4s_rgb_tuser;
    wire                            axi4s_rgb_tlast;
    wire    [3:0][DATA_WIDTH-1:0]   axi4s_rgb_tdata;
    wire                            axi4s_rgb_tvalid;
    wire                            axi4s_rgb_tready;
    assign axi4s_rgb_tuser  = i_top.axi4s_rgb_tuser;
    assign axi4s_rgb_tlast  = i_top.axi4s_rgb_tlast;
    assign axi4s_rgb_tdata  = i_top.axi4s_rgb_tdata;
    assign axi4s_rgb_tvalid = i_top.axi4s_rgb_tvalid;
    assign axi4s_rgb_tready = i_top.axi4s_rgb_tready;
    
    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("rgb_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (1) // BGR
            )
        i_axi4s_slave_model_rgb
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_rgb_tuser),
                .s_axi4s_tlast      (axi4s_rgb_tlast),
                .s_axi4s_tdata      (axi4s_rgb_tdata[2:0]),
                .s_axi4s_tvalid     (axi4s_rgb_tvalid & axi4s_rgb_tready),
                .s_axi4s_tready     ()
            );

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P2"),
                .FILE_NAME          ("gray_"),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1)
            )
        i_axi4s_slave_model_gray
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_rgb_tuser),
                .s_axi4s_tlast      (axi4s_rgb_tlast),
                .s_axi4s_tdata      (axi4s_rgb_tdata[3]),
                .s_axi4s_tvalid     (axi4s_rgb_tvalid & axi4s_rgb_tready),
                .s_axi4s_tready     ()
            );


    logic   [0:0]                   axi4s_mnist_tuser;
    logic                           axi4s_mnist_tlast;
    logic   [23:0]                  axi4s_mnist_trgb;
    logic   [10:0]                  axi4s_mnist_tclass;
    logic   [10:0][7:0]             axi4s_mnist_tclass_u8;
    logic                           axi4s_mnist_tvalid;
    logic                           axi4s_mnist_tready;

    assign axi4s_mnist_tuser     = i_top.axi4s_mnist_tuser;
    assign axi4s_mnist_tlast     = i_top.axi4s_mnist_tlast;
    assign axi4s_mnist_trgb      = i_top.axi4s_mnist_trgb;
    assign axi4s_mnist_tclass    = i_top.axi4s_mnist_tclass;
    assign axi4s_mnist_tclass_u8 = i_top.axi4s_mnist_tclass_u8;
    assign axi4s_mnist_tvalid    = i_top.axi4s_mnist_tvalid;
    assign axi4s_mnist_tready    = i_top.axi4s_mnist_tready;

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("mnist_rgb_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (1) // BGR
            )
        i_axi4s_slave_model_mnist_rgb
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_mnist_tuser),
                .s_axi4s_tlast      (axi4s_mnist_tlast),
                .s_axi4s_tdata      (axi4s_mnist_trgb),
                .s_axi4s_tvalid     (axi4s_mnist_tvalid & axi4s_mnist_tready),
                .s_axi4s_tready     ()
            );

    for ( genvar i = 0; i < 10; ++i ) begin
        jelly2_axi4s_slave_model
                #(
                    .COMPONENTS         (1),
                    .DATA_WIDTH         (8),
                    .INIT_FRAME_NUM     (0),
                    .FORMAT             ("P2"),
                    .FILE_NAME          ({"mnist", ("0" + i), "_"}),
                    .FILE_EXT           (".pgm"),
                    .SEQUENTIAL_FILE    (1),
                    .ENDIAN             (1) // BGR
                )
            i_axi4s_slave_model_mnist_0
                (
                    .aresetn            (axi4s_cam_aresetn),
                    .aclk               (axi4s_cam_aclk),
                    .aclken             (1'b1),

                    .param_width        (X_NUM),
                    .param_height       (Y_NUM),
                    .frame_num          (),
                    
                    .s_axi4s_tuser      (axi4s_mnist_tuser),
                    .s_axi4s_tlast      (axi4s_mnist_tlast),
                    .s_axi4s_tdata      (axi4s_mnist_tclass_u8[i]),
                    .s_axi4s_tvalid     (axi4s_mnist_tvalid & axi4s_mnist_tready),
                    .s_axi4s_tready     ()
                );
    end

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P2"),
                .FILE_NAME          ({"mnist_bk_"}),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (1) // BGR
            )
        i_axi4s_slave_model_mnist_bk
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_mnist_tuser),
                .s_axi4s_tlast      (axi4s_mnist_tlast),
                .s_axi4s_tdata      (axi4s_mnist_tclass_u8[10]),
                .s_axi4s_tvalid     (axi4s_mnist_tvalid & axi4s_mnist_tready),
                .s_axi4s_tready     ()
            );


    logic   [0:0]               axi4s_max_tuser;
    logic                       axi4s_max_tlast;
    logic   [2:0][7:0]          axi4s_max_trgb;
    logic   [7:0]               axi4s_max_targmax;
    logic                       axi4s_max_tvalid;
    logic                       axi4s_max_tready;

    assign axi4s_max_tuser   = i_top.axi4s_max_tuser;
    assign axi4s_max_tlast   = i_top.axi4s_max_tlast;
    assign axi4s_max_trgb    = i_top.axi4s_max_trgb;
    assign axi4s_max_targmax = i_top.axi4s_max_targmax;
    assign axi4s_max_tvalid  = i_top.axi4s_max_tvalid;
    assign axi4s_max_tready  = i_top.axi4s_max_tready;

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("max_rgb_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (1) // BGR
            )
        i_axi4s_slave_model_max_rgb
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_max_tuser),
                .s_axi4s_tlast      (axi4s_max_tlast),
                .s_axi4s_tdata      (axi4s_max_trgb),
                .s_axi4s_tvalid     (axi4s_max_tvalid & axi4s_max_tready),
                .s_axi4s_tready     ()
            );

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (8),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("max_argmax_"),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (1) // BGR
            )
        i_axi4s_slave_model_max_argmax
            (
                .aresetn            (axi4s_cam_aresetn),
                .aclk               (axi4s_cam_aclk),
                .aclken             (1'b1),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_axi4s_tuser      (axi4s_max_tuser),
                .s_axi4s_tlast      (axi4s_max_tlast),
                .s_axi4s_tdata      (axi4s_max_targmax),
                .s_axi4s_tvalid     (axi4s_max_tvalid & axi4s_max_tready),
                .s_axi4s_tready     ()
            );

endmodule


`default_nettype wire


// end of file
