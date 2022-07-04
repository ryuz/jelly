// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4s_img_bridge
        #(
            parameter   int                         TUSER_WIDTH    = 1,
            parameter   int                         S_TDATA_WIDTH  = 8,
            parameter   int                         M_TDATA_WIDTH  = 24,
            parameter   int                         IMG_X_WIDTH    = 10,
            parameter   int                         IMG_Y_WIDTH    = 9,
            parameter   int                         BLANK_Y_WIDTH  = IMG_Y_WIDTH,
            parameter   bit                         WITH_DE        = 1,
            parameter   bit                         WITH_VALID     = 1,

            parameter   int                         FIFO_PTR_WIDTH = 9,
            parameter                               FIFO_RAM_TYPE  = "block",
            parameter   bit                         IMG_CKE_BUFG   = 0,
            
            localparam  int                         USER_WIDTH     = TUSER_WIDTH > 1 ? TUSER_WIDTH - 1 : 1
        )
        (
            input   wire                                aresetn,
            input   wire                                aclk,
            input   wire                                aclken,
            
            input   wire    [IMG_X_WIDTH-1:0]           param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]           param_img_height,
            input   wire    [BLANK_Y_WIDTH-1:0]         param_blank_height,
            
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
            
            
            output  wire                                img_cke,
            
            output  wire                                m_img_src_row_first,
            output  wire                                m_img_src_row_last,
            output  wire                                m_img_src_col_first,
            output  wire                                m_img_src_col_last,
            output  wire                                m_img_src_de,
            output  wire    [USER_WIDTH-1:0]            m_img_src_user,
            output  wire    [S_TDATA_WIDTH-1:0]         m_img_src_data,
            output  wire                                m_img_src_valid,
            
            input   wire                                s_img_sink_row_first,
            input   wire                                s_img_sink_row_last,
            input   wire                                s_img_sink_col_first,
            input   wire                                s_img_sink_col_last,
            input   wire                                s_img_sink_de,
            input   wire    [USER_WIDTH-1:0]            s_img_sink_user,
            input   wire    [M_TDATA_WIDTH-1:0]         s_img_sink_data,
            input   wire                                s_img_sink_valid
        );
    
    
    // 画像処理用のフォーマットに変換
    logic                           cke;

    jelly2_axi4s_to_img_simple
            #(
                .TUSER_WIDTH        (TUSER_WIDTH),
                .TDATA_WIDTH        (S_TDATA_WIDTH),
                .IMG_X_WIDTH        (IMG_X_WIDTH),
                .IMG_Y_WIDTH        (IMG_Y_WIDTH),
                .BLANK_Y_WIDTH      (BLANK_Y_WIDTH),
                .IMG_CKE_BUFG       (IMG_CKE_BUFG),
                .WITH_VALID         (WITH_VALID)
            )
        i_axi4s_to_img_simple
            (
                .reset              (~aresetn),
                .clk                (aclk),
                .cke                (cke),
                
                .param_img_width,
                .param_img_height,
                .param_blank_height,
                
                .s_axi4s_tuser,
                .s_axi4s_tlast,
                .s_axi4s_tdata,
                .s_axi4s_tvalid     (s_axi4s_tvalid && aclken),
                .s_axi4s_tready,
                
                .m_img_cke          (img_cke),
                .m_img_row_first    (m_img_src_row_first),
                .m_img_row_last     (m_img_src_row_last),
                .m_img_col_first    (m_img_src_col_first),
                .m_img_col_last     (m_img_src_col_last),
                .m_img_de           (m_img_src_de),
                .m_img_user         (m_img_src_user),
                .m_img_data         (m_img_src_data),
                .m_img_valid        (m_img_src_valid)
        );
    
    
    wire    [M_TDATA_WIDTH-1:0] axi4s_0_tdata;
    wire                        axi4s_0_tlast;
    wire    [TUSER_WIDTH-1:0]   axi4s_0_tuser;
    wire                        axi4s_0_tvalid;
    
    jelly2_img_to_axi4s
            #(
                .TUSER_WIDTH        (TUSER_WIDTH),
                .TDATA_WIDTH        (M_TDATA_WIDTH),
                .WITH_DE            (WITH_DE),
                .WITH_VALID         (WITH_VALID)
            )
        i_img_to_axi4s
            (
                .reset              (~aresetn),
                .clk                (aclk),
                .cke                (img_cke),
                
                .s_img_row_first    (s_img_sink_row_first),
                .s_img_row_last     (s_img_sink_row_last),
                .s_img_col_first    (s_img_sink_col_first),
                .s_img_col_last     (s_img_sink_col_last),
                .s_img_de           (s_img_sink_de),
                .s_img_user         (s_img_sink_user),
                .s_img_data         (s_img_sink_data),
                .s_img_valid        (s_img_sink_valid),
                
                .m_axi4s_tuser      (axi4s_0_tuser),
                .m_axi4s_tlast      (axi4s_0_tlast),
                .m_axi4s_tdata      (axi4s_0_tdata),
                .m_axi4s_tvalid     (axi4s_0_tvalid)
            );
    
    wire    [M_TDATA_WIDTH-1:0] axi4s_1_tdata;
    wire                        axi4s_1_tlast;
    wire    [TUSER_WIDTH-1:0]   axi4s_1_tuser;
    wire                        axi4s_1_tvalid;
    wire                        axi4s_1_tready;
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (TUSER_WIDTH+1+M_TDATA_WIDTH)
            )
        i_pipeline_insert_ff_0
            (
                .reset              (~aresetn),
                .clk                (aclk),
                .cke                (1'b1),
                
                .s_data             ({axi4s_0_tuser, axi4s_0_tlast, axi4s_0_tdata}),
                .s_valid            (axi4s_0_tvalid),
                .s_ready            (),
                
                .m_data             ({axi4s_1_tuser, axi4s_1_tlast, axi4s_1_tdata}),
                .m_valid            (axi4s_1_tvalid),
                .m_ready            (axi4s_1_tready),
                
                .buffered           (),
                .s_ready_next       ()
            );
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH         (TUSER_WIDTH+1+M_TDATA_WIDTH)
            )
        i_pipeline_insert_ff_1
            (
                .reset              (~aresetn),
                .clk                (aclk),
                .cke                (1'b1),
                
                .s_data             ({axi4s_1_tuser, axi4s_1_tlast, axi4s_1_tdata}),
                .s_valid            (axi4s_1_tvalid),
                .s_ready            (axi4s_1_tready),
                
                .m_data             ({m_axi4s_tuser, m_axi4s_tlast, m_axi4s_tdata}),
                .m_valid            (m_axi4s_tvalid),
                .m_ready            (m_axi4s_tready & aclken),
                
                .buffered           (),
                .s_ready_next       (cke)
            );
    
endmodule


`default_nettype wire


// end of file
