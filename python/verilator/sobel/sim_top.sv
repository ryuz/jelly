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
            parameter   int     S_DATA_WIDTH  = 8,
            parameter   int     M_DATA_WIDTH  = 16,
            parameter   int     WB_ADR_WIDTH  = 8,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                            aresetn,
            input   wire                            aclk,
 
            input   wire    [IMG_X_WIDTH-1:0]       param_img_width,
            input   wire    [IMG_Y_WIDTH-1:0]       param_img_height,

            input   wire    [TUSER_WIDTH-1:0]       s_axi4s_tuser,
            input   wire                            s_axi4s_tlast,
            input   wire    [S_DATA_WIDTH-1:0]      s_axi4s_tdata,
            input   wire                            s_axi4s_tvalid,
            output  wire                            s_axi4s_tready,

            output  wire    [TUSER_WIDTH-1:0]       m_axi4s_tuser,
            output  wire                            m_axi4s_tlast,
            output  wire    [2:0][M_DATA_WIDTH-1:0] m_axi4s_tdata,
            output  wire                            m_axi4s_tvalid,
            input   wire                            m_axi4s_tready,

            input   wire                            s_wb_rst_i,
            input   wire                            s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   wire                            s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   wire                            s_wb_stb_i,
            output  reg                             s_wb_ack_o
        );
    

    // -----------------------------------------
    //  top
    // -----------------------------------------

    logic                           aclken = 1'b1;

    logic   [M_DATA_WIDTH-1:0]      sobel_dx;
    logic   [M_DATA_WIDTH-1:0]      sobel_dy;
    logic   [S_DATA_WIDTH-1:0]      sobel_data;

    jelly2_video_sobel
            #(
                .SIZE_AUTO          (0),
                .TUSER_WIDTH        (1),
                .DATA_WIDTH         (S_DATA_WIDTH),
                .GRAD_X_WIDTH       (M_DATA_WIDTH),
                .GRAD_Y_WIDTH       (M_DATA_WIDTH),
                .IMG_X_WIDTH        (IMG_X_WIDTH),
                .IMG_Y_WIDTH        (IMG_Y_WIDTH),
                .MAX_COLS           (4096),
                .RAM_TYPE           ("block"),
                .INIT_Y_NUM         (480),
                .FIFO_PTR_WIDTH     (IMG_X_WIDTH),
                .FIFO_RAM_TYPE      ("block")
            )
        i_video_sobel
            (
                .aresetn,
                .aclk,
                .aclken,

                .param_img_width,
                .param_img_height,
                
                .s_axi4s_tuser,
                .s_axi4s_tlast,
                .s_axi4s_tdata,
                .s_axi4s_tvalid,
                .s_axi4s_tready,
                
                .m_axi4s_tuser,
                .m_axi4s_tlast,
                .m_axi4s_tdata_dx   (sobel_dx),
                .m_axi4s_tdata_dy   (sobel_dy),
                .m_axi4s_tdata      (sobel_data),
                .m_axi4s_tvalid,
                .m_axi4s_tready
            );
    
    always_comb begin
        m_axi4s_tdata[0] = sobel_dx;
        m_axi4s_tdata[1] = sobel_dy;
        m_axi4s_tdata[2] = M_DATA_WIDTH'(sobel_data);
    end
    

    always_comb s_wb_dat_o = '0;
    always_comb s_wb_ack_o = s_wb_stb_i;

endmodule


`default_nettype wire


// end of file
