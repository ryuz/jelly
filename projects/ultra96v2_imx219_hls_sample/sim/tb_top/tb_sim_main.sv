// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        #(
            parameter   X_NUM = 1024, // 3280 / 2,
            parameter   Y_NUM = 64    //2464 / 2
        )
        (
            input   wire    reset,
            input   wire    clk
        );
    
    // setting
    localparam FILE_NAME  = "../../data/Chrysanthemum_bayer_1024x768.pgm";
    localparam FILE_X_NUM = 1024;
    localparam FILE_Y_NUM = 768;

    int     sym_cycle = 0;
    always_ff @(posedge clk) begin
        sym_cycle <= sym_cycle + 1;            
    end


    // top
    ultra96v2_imx219_hls_sample
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


    logic           axi4s_src_aresetn;
    logic           axi4s_src_aclk;
    logic   [0:0]   axi4s_src_tuser;
    logic           axi4s_src_tlast;
    logic   [9:0]   axi4s_src_tdata;
    logic           axi4s_src_tvalid;
    logic           axi4s_src_tready;

    assign axi4s_src_aresetn = i_top.axi4s_cam_aresetn;
    assign axi4s_src_aclk    = i_top.axi4s_cam_aclk;
    assign axi4s_src_tready  = i_top.axi4s_csi2_tready;

    // force を verilator の為に毎回実行する
    always @(axi4s_src_tuser or axi4s_src_tlast or axi4s_src_tdata or axi4s_src_tvalid) begin
        force i_top.axi4s_csi2_tuser  = axi4s_src_tuser;
        force i_top.axi4s_csi2_tlast  = axi4s_src_tlast;
        force i_top.axi4s_csi2_tdata  = axi4s_src_tdata;
        force i_top.axi4s_csi2_tvalid = axi4s_src_tvalid;
    end

    jelly2_axi4s_master_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (10),
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
                .aresetn            (axi4s_src_aresetn),
                .aclk               (axi4s_src_aclk),
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



    wire            img_reset = i_top.i_image_processing.reset;
    wire            img_clk   = i_top.i_image_processing.clk;
    wire            img_cke   = i_top.i_image_processing.cke;


    wire            img_src_line_first  = i_top.i_image_processing.img_src_line_first ;
    wire            img_src_line_last   = i_top.i_image_processing.img_src_line_last  ;
    wire            img_src_pixel_first = i_top.i_image_processing.img_src_pixel_first;
    wire            img_src_pixel_last  = i_top.i_image_processing.img_src_pixel_last ;
    wire            img_src_de          = i_top.i_image_processing.img_src_de         ;
    wire    [9:0]   img_src_data        = i_top.i_image_processing.img_src_data       ;
    wire            img_src_valid       = i_top.i_image_processing.img_src_valid      ;

    jelly2_img_slave_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (10),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P2"),
                .FILE_NAME          ("src_"),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model_img_src
            (
                .reset              (img_reset),
                .clk                (img_clk),
                .cke                (img_cke),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_img_row_first    (img_src_line_first),
                .s_img_row_last     (img_src_line_last),
                .s_img_col_first    (img_src_pixel_first),
                .s_img_col_last     (img_src_pixel_last),
                .s_img_de           (img_src_de),
                .s_img_data         (img_src_data),
                .s_img_valid        (img_src_valid)
            );


    wire            img_demos_line_first  = i_top.i_image_processing.img_demos_line_first ;
    wire            img_demos_line_last   = i_top.i_image_processing.img_demos_line_last  ;
    wire            img_demos_pixel_first = i_top.i_image_processing.img_demos_pixel_first;
    wire            img_demos_pixel_last  = i_top.i_image_processing.img_demos_pixel_last ;
    wire            img_demos_de          = i_top.i_image_processing.img_demos_de         ;
    wire    [9:0]   img_demos_raw         = i_top.i_image_processing.img_demos_raw        ;
    wire    [9:0]   img_demos_r           = i_top.i_image_processing.img_demos_r          ;
    wire    [9:0]   img_demos_g           = i_top.i_image_processing.img_demos_g          ;
    wire    [9:0]   img_demos_b           = i_top.i_image_processing.img_demos_b          ;
    wire            img_demos_valid       = i_top.i_image_processing.img_demos_valid      ;

    jelly2_img_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (10),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("demos_"),
                .FILE_EXT           (".ppm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0)
            )
        i_img_slave_model_demos
            (
                .reset              (img_reset),
                .clk                (img_clk),
                .cke                (img_cke),

                .param_width        (X_NUM),
                .param_height       (Y_NUM),
                .frame_num          (),
                
                .s_img_row_first    (img_demos_line_first),
                .s_img_row_last     (img_demos_line_last),
                .s_img_col_first    (img_demos_pixel_first),
                .s_img_col_last     (img_demos_pixel_last),
                .s_img_de           (img_demos_de),
                .s_img_data         ({img_demos_b, img_demos_g, img_demos_r}),
                .s_img_valid        (img_demos_valid)
            );

endmodule


`default_nettype wire


// end of file
