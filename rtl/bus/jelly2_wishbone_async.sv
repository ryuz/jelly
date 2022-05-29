// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_wishbone_async
        #(
            parameter   bit     ASYNC         = 1,
            parameter   int     WB_ADR_WIDTH  = 30,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8)
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

    logic   busy;
    always_ff @(posedge s_wb_clk_i) begin
        if ( s_wb_rst_i ) begin
            busy <= 1'b0;
        end
        else begin
            busy <= s_wb_stb_i && !s_wb_ack_o;
        end
    end

    jelly_data_async
            #(
                .ASYNC          (ASYNC),
                .DATA_WIDTH     (WB_ADR_WIDTH + WB_DAT_WIDTH + WB_SEL_WIDTH + 1),
            )
        i_data_async_cmd
            (
                .s_reset        (s_wb_rst_i),
                .s_clk          (s_wb_clk_i),
                .s_data         ({s_wb_adr_i, s_wb_dat_i, s_wb_sel_i, s_wb_we_i}),
                .s_valid        (s_wb_stb_i && !busy),
                .s_ready        (),
                
                .m_reset        (m_wb_rst_i),
                .m_clk          (m_wb_clk_i),
                .m_data         ({m_wb_adr_o, m_wb_dat_o, m_wb_sel_o, m_wb_we_o}),
                .m_valid        (m_wb_stb_o),
                .m_ready        (m_wb_ack_i)
            );
    
    jelly_data_async
            #(
                .ASYNC          (ASYNC),
                .DATA_WIDTH     (WB_DAT_WIDTH),
            )
        i_data_async_ack
            (
                .s_reset        (m_wb_rst_i),
                .s_clk          (m_wb_clk_i),
                .s_data         (m_wb_dat_i),
                .s_valid        (m_wb_ack_i),
                .s_ready        (),
                
                .m_reset        (s_wb_rst_i),
                .m_clk          (s_wb_clk_i),
                .m_data         (s_wb_dat_o),
                .m_valid        (s_wb_ack_o),
                .m_ready        (1'b1)
            );

endmodule


`default_nettype wire


// end of file
