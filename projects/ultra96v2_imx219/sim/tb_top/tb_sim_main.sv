// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_sim_main
        #(
            parameter   X_NUM = 1024,   // 3280 / 2,
            parameter   Y_NUM = 64,     // 2464 / 2

            parameter   WB_ADR_WIDTH = 30,
            parameter   WB_DAT_WIDTH = 64,
            parameter   WB_SEL_WIDTH = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        reset,
            input   wire                        clk100,
            input   wire                        clk200,
            input   wire                        clk250,
    
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_we_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o
        );
    

    // setting
    localparam FILE_NAME  = "../../data/Chrysanthemum_bayer_1024x768.pgm";
    localparam FILE_X_NUM = 1024;
    localparam FILE_Y_NUM = 768;

    wire    clk = clk100;

    int     sym_cycle = 0;
    always_ff @(posedge clk) begin
        sym_cycle <= sym_cycle + 1;
    end

    
    // -----------------------------------------
    //  top
    // -----------------------------------------
    
    ultra96v2_imx219
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

    always_comb force i_top.i_design_1.wb_adr_i = s_wb_adr_i;
    always_comb force i_top.i_design_1.wb_dat_i = s_wb_dat_i;
    always_comb force i_top.i_design_1.wb_sel_i = s_wb_sel_i;
    always_comb force i_top.i_design_1.wb_we_i  = s_wb_we_i;
    always_comb force i_top.i_design_1.wb_stb_i = s_wb_stb_i;

    assign s_wb_dat_o = i_top.i_design_1.wb_dat_o;
    assign s_wb_ack_o = i_top.i_design_1.wb_ack_o;



    // -----------------------------------------
    //  video input
    // -----------------------------------------

    logic           axi4s_cam_aresetn;
    logic           axi4s_cam_aclk;

    logic   [0:0]   axi4s_src_tuser;
    logic           axi4s_src_tlast;
    logic   [9:0]   axi4s_src_tdata;
    logic           axi4s_src_tvalid;
    logic           axi4s_src_tready;

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

    wire    [0:0]               axi4s_rgb_tuser;
    wire                        axi4s_rgb_tlast;
    wire    [39:0]              axi4s_rgb_tdata;
    wire                        axi4s_rgb_tvalid;
    wire                        axi4s_rgb_tready;
    assign axi4s_rgb_tuser  = i_top.axi4s_rgb_tuser;
    assign axi4s_rgb_tlast  = i_top.axi4s_rgb_tlast;
    assign axi4s_rgb_tdata  = i_top.axi4s_rgb_tdata;
    assign axi4s_rgb_tvalid = i_top.axi4s_rgb_tvalid;
    assign axi4s_rgb_tready = i_top.axi4s_rgb_tready;
  
    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (3),
                .DATA_WIDTH         (10),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P3"),
                .FILE_NAME          ("rgb_"),
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
                
                .s_axi4s_tuser      (axi4s_rgb_tuser),
                .s_axi4s_tlast      (axi4s_rgb_tlast),
                .s_axi4s_tdata      (axi4s_rgb_tdata),
                .s_axi4s_tvalid     (axi4s_rgb_tvalid & axi4s_rgb_tready),
                .s_axi4s_tready     ()
            );

endmodule


`default_nettype wire


// end of file
