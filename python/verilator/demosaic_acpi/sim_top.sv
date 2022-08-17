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
//          input   wire                            aclken,
 
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
    
    
    // -----------------------------------------
    //  top
    // -----------------------------------------

    localparam  bit                         SIZE_AUTO        = 0;
    localparam  int                         MAX_COLS         = 4096;
    localparam                              RAM_TYPE         = "block";
    localparam  bit     [IMG_Y_WIDTH-1:0]   INIT_Y_NUM       = 480;
    localparam  int                         FIFO_PTR_WIDTH   = IMG_X_WIDTH;
    localparam                              FIFO_RAM_TYPE    = "block";

    localparam  bit     [31:0]              CORE_ID          = 32'h527a_2110;
    localparam  bit     [31:0]              CORE_VERSION     = 32'h0001_0000;
    localparam  int                         INDEX_WIDTH      = 1;

    localparam  bit     [1:0]               INIT_CTL_CONTROL = 2'b00;
    localparam  bit     [1:0]               INIT_PARAM_PHASE = 2'b00;

    logic                           aclken = 1'b1;
    
    // demosaic with ACPI
    jelly2_video_demosaic_acpi
            #(
                .SIZE_AUTO          (SIZE_AUTO),
                .TUSER_WIDTH        (TUSER_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .IMG_X_WIDTH        (IMG_X_WIDTH),
                .IMG_Y_WIDTH        (IMG_Y_WIDTH),
                .MAX_COLS           (MAX_COLS),
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
    

endmodule


`default_nettype wire


// end of file
