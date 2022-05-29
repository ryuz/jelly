// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_wishbone_bridge
        #(
            parameter   bit     ASYNC         = 1,
            parameter   int     WB_ADR_WIDTH  = 30,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            parameter   bit     SREG          = 0,
            parameter   bit     MREG          = 0
        )
        (
            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_we_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            
            input   wire                        m_wb_rst_i,
            input   wire                        m_wb_clk_i,
            output  wire    [WB_ADR_WIDTH-1:0]  m_wb_adr_o,
            input   wire    [WB_DAT_WIDTH-1:0]  m_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  m_wb_dat_o,
            output  wire    [WB_SEL_WIDTH-1:0]  m_wb_sel_o,
            output  wire                        m_wb_we_o,
            output  wire                        m_wb_stb_o,
            input   wire                        m_wb_ack_i
        );


    logic   [WB_ADR_WIDTH-1:0]  wb_ff_adr_o;
    logic   [WB_DAT_WIDTH-1:0]  wb_ff_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  wb_ff_dat_o;
    logic   [WB_SEL_WIDTH-1:0]  wb_ff_sel_o;
    logic                       wb_ff_we_o;
    logic                       wb_ff_stb_o;
    logic                       wb_ff_ack_i;

    jelly2_wishbone_ff
            #(
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH),
                .WB_SEL_WIDTH   (WB_SEL_WIDTH),
                .SREG           (SREG),
                .MREG           (1'b0),
            )
        i_wishbone_ff_s
            (
                .reset          (s_wb_rst_i),
                .clk            (s_wb_clk_i),
                .cke            (1'b1),
                
                .s_wb_adr_i     (s_wb_adr_i),
                .s_wb_dat_o     (s_wb_dat_o),
                .s_wb_dat_i     (s_wb_dat_i),
                .s_wb_sel_i     (s_wb_sel_i),
                .s_wb_we_i      (s_wb_we_i),
                .s_wb_stb_i     (s_wb_stb_i),
                .s_wb_ack_o     (s_wb_ack_o),
                
                .m_wb_adr_o     (wb_ff_adr_o),
                .m_wb_dat_i     (wb_ff_dat_i),
                .m_wb_dat_o     (wb_ff_dat_o),
                .m_wb_sel_o     (wb_ff_sel_o),
                .m_wb_we_o      (wb_ff_we_o),
                .m_wb_stb_o     (wb_ff_stb_o),
                .m_wb_ack_i     (wb_ff_ack_i)
            );


    logic   [WB_ADR_WIDTH-1:0]  wb_async_adr_o;
    logic   [WB_DAT_WIDTH-1:0]  wb_async_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  wb_async_dat_o;
    logic   [WB_SEL_WIDTH-1:0]  wb_async_sel_o;
    logic                       wb_async_we_o;
    logic                       wb_async_stb_o;
    logic                       wb_async_ack_i;

    jelly2_wishbone_bridge
            #(
                .ASYNC          (ASYNC),
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH),
                .WB_SEL_WIDTH   (WB_SEL_WIDTH),
            )
        i_wishbone_bridge
            (
                .s_wb_rst_i     (s_wb_rst_i),
                .s_wb_clk_i     (s_wb_clk_i),
                .s_wb_adr_i     (wb_ff_adr_o),
                .s_wb_dat_o     (wb_ff_dat_i),
                .s_wb_dat_i     (wb_ff_dat_o),
                .s_wb_sel_i     (wb_ff_sel_o),
                .s_wb_we_i      (wb_ff_we_o),
                .s_wb_stb_i     (wb_ff_stb_o),
                .s_wb_ack_o     (wb_ff_ack_i),

                .m_wb_rst_i     (m_wb_rst_i),
                .m_wb_clk_i     (m_wb_clk_i),
                .m_wb_adr_o     (wb_async_adr_o),
                .m_wb_dat_i     (wb_async_dat_i),
                .m_wb_dat_o     (wb_async_dat_o),
                .m_wb_sel_o     (wb_async_sel_o),
                .m_wb_we_o      (wb_async_we_o ),
                .m_wb_stb_o     (wb_async_stb_o),
                .m_wb_ack_i     (wb_async_ack_i)
            );


    jelly2_wishbone_ff
            #(
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH),
                .WB_SEL_WIDTH   (WB_SEL_WIDTH),
                .SREG           (SREG),
                .MREG           (1'b0),
            )
        i_wishbone_ff
            (
                .reset          (m_wb_rst_i),
                .clk            (m_wb_clk_i),
                .cke            (1'b1),
                
                .s_wb_adr_i     (wb_async_adr_o),
                .s_wb_dat_o     (wb_async_dat_i),
                .s_wb_dat_i     (wb_async_dat_o),
                .s_wb_sel_i     (wb_async_sel_o),
                .s_wb_we_i      (wb_async_we_o),
                .s_wb_stb_i     (wb_async_stb_o),
                .s_wb_ack_o     (wb_async_ack_i),
                
                .m_wb_adr_o     (m_wb_adr_o),
                .m_wb_dat_i     (m_wb_dat_i),
                .m_wb_dat_o     (m_wb_dat_o),
                .m_wb_sel_o     (m_wb_sel_o),
                .m_wb_we_o      (m_wb_we_o),
                .m_wb_stb_o     (m_wb_stb_o),
                .m_wb_ack_i     (m_wb_ack_i)
            );
    
endmodule


`default_nettype wire


// end of file
