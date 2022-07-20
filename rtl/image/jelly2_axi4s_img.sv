// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_axi4s_img
        #(
            parameter   bit                         SIZE_AUTO      = 1,
            parameter   int                         TUSER_WIDTH    = 1,
            parameter   int                         S_TDATA_WIDTH  = 8,
            parameter   int                         M_TDATA_WIDTH  = 24,
            parameter   int                         IMG_X_WIDTH    = 10,
            parameter   int                         IMG_Y_WIDTH    = 9,
            parameter   int                         BLANK_Y_WIDTH  = IMG_Y_WIDTH,
            parameter   bit                         WITH_DE        = 1,
            parameter   bit                         WITH_VALID     = 1,
            parameter   bit                         IMG_CKE_BUFG   = 0,
            parameter   bit     [IMG_Y_WIDTH-1:0]   INIT_Y_NUM     = 480,
            parameter   int                         FIFO_PTR_WIDTH = 9,
            parameter                               FIFO_RAM_TYPE  = "block",
            
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
    
    generate
    if ( SIZE_AUTO ) begin : blk_auto
        jelly2_axi4s_img_auto
                #(
                    .TUSER_WIDTH            (TUSER_WIDTH),
                    .S_TDATA_WIDTH          (S_TDATA_WIDTH),
                    .M_TDATA_WIDTH          (M_TDATA_WIDTH),
                    .IMG_X_WIDTH            (IMG_X_WIDTH),
                    .IMG_Y_WIDTH            (IMG_Y_WIDTH),
                    .WITH_DE                (WITH_DE),
                    .WITH_VALID             (WITH_VALID),
                    .BLANK_Y_WIDTH          (BLANK_Y_WIDTH),
                    .INIT_Y_NUM             (INIT_Y_NUM),
                    .FIFO_PTR_WIDTH         (FIFO_PTR_WIDTH),
                    .FIFO_RAM_TYPE          (FIFO_RAM_TYPE),
                    .IMG_CKE_BUFG           (IMG_CKE_BUFG),
                )
            i_axi4s_img_auto
                (
                    .aresetn,
                    .aclk,
                    .aclken,
                    
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

    end
    else begin : blk_simple
        jelly2_axi4s_img_simple
                #(
                    .TUSER_WIDTH            (TUSER_WIDTH), 
                    .S_TDATA_WIDTH          (S_TDATA_WIDTH), 
                    .M_TDATA_WIDTH          (M_TDATA_WIDTH), 
                    .IMG_X_WIDTH            (IMG_X_WIDTH), 
                    .IMG_Y_WIDTH            (IMG_Y_WIDTH), 
                    .BLANK_Y_WIDTH          (BLANK_Y_WIDTH), 
                    .WITH_DE                (WITH_DE), 
                    .WITH_VALID             (WITH_VALID), 
                    .IMG_CKE_BUFG           (IMG_CKE_BUFG) 
                )
            i_axi4s_img_simple
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
    end
    endgenerate

endmodule


`default_nettype wire


// end of file
