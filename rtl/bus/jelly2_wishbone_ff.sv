// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// wishbone insert FF
module jelly2_wishbone_ff
        #(
            parameter   int     WB_ADR_WIDTH  = 30,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            parameter   bit     SREG          = 0,
            parameter   bit     MREG          = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  reg     [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_we_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            
            output  reg     [WB_ADR_WIDTH-1:0]  m_wb_adr_o,
            input   wire    [WB_DAT_WIDTH-1:0]  m_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]  m_wb_dat_o,
            output  reg     [WB_SEL_WIDTH-1:0]  m_wb_sel_o,
            output  reg                         m_wb_we_o,
            output  reg                         m_wb_stb_o,
            input   wire                        m_wb_ack_i
        );
    
    // temporary
    logic   [WB_ADR_WIDTH-1:0]  wb_tmp_adr_o;
    logic   [WB_DAT_WIDTH-1:0]  wb_tmp_dat_i;
    logic   [WB_DAT_WIDTH-1:0]  wb_tmp_dat_o;
    logic   [WB_SEL_WIDTH-1:0]  wb_tmp_sel_o;
    logic                       wb_tmp_we_o;
    logic                       wb_tmp_stb_o;
    logic                       wb_tmp_ack_i;
    
    // slave port
    generate
    if ( SREG ) begin : s_ff
        // insert FF
        always_ff @( posedge clk ) begin
            if ( reset ) begin
                s_wb_dat_o <= 'x;
                s_wb_ack_o <= 1'b0;
            end
            else if ( cke ) begin
                s_wb_dat_o <= wb_tmp_dat_i;
                s_wb_ack_o <= wb_tmp_stb_o & wb_tmp_ack_i;
            end
        end
        
        always_comb wb_tmp_adr_o = s_wb_adr_i;
        always_comb wb_tmp_dat_o = s_wb_dat_i;
        always_comb wb_tmp_sel_o = s_wb_sel_i;
        always_comb wb_tmp_we_o  = s_wb_we_i;
        always_comb wb_tmp_stb_o = s_wb_stb_i & !s_wb_ack_o;
    end
    else begin : s_bypass
        // bypass
        always_comb s_wb_dat_o   = wb_tmp_dat_i;
        always_comb s_wb_ack_o   = wb_tmp_ack_i;

        always_comb wb_tmp_adr_o = s_wb_adr_i;
        always_comb wb_tmp_dat_o = s_wb_dat_i;
        always_comb wb_tmp_sel_o = s_wb_sel_i;
        always_comb wb_tmp_we_o  = s_wb_we_i;
        always_comb wb_tmp_stb_o = s_wb_stb_i;
        
    end
    endgenerate
    
    
    // master port
    generate
    if ( MREG ) begin
        // insert FF
        always_ff @ ( posedge clk ) begin
            if ( reset ) begin
                m_wb_adr_o <= 'x;
                m_wb_dat_o <= 'x;
                m_wb_sel_o <= 'x;
                m_wb_we_o  <= 1'bx;
                m_wb_stb_o <= 1'b0;
            end
            else if ( cke ) begin
                m_wb_adr_o <= wb_tmp_adr_o;
                m_wb_dat_o <= wb_tmp_dat_o;
                m_wb_sel_o <= wb_tmp_sel_o;
                m_wb_we_o  <= wb_tmp_we_o;
                m_wb_stb_o <= wb_tmp_stb_o & !(m_wb_stb_o & wb_tmp_ack_i);
            end
        end
        
        always_comb wb_tmp_dat_i = m_wb_dat_i;
        always_comb wb_tmp_ack_i = m_wb_ack_i;
    end
    else begin
        // bypass
        always_comb m_wb_adr_o   = wb_tmp_adr_o;
        always_comb m_wb_dat_o   = wb_tmp_dat_o;
        always_comb m_wb_sel_o   = wb_tmp_sel_o;
        always_comb m_wb_we_o    = wb_tmp_we_o;
        always_comb m_wb_stb_o   = wb_tmp_stb_o;
                      
        always_comb wb_tmp_dat_i = m_wb_dat_i;
        always_comb wb_tmp_ack_i = m_wb_ack_i;
    end
    endgenerate

endmodule


`default_nettype wire


// end of file
