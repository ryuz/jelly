// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_wb_accessor
    #(
        parameter   int     WB_ADR_WIDTH   = 14      ,
        parameter   int     WB_DAT_WIDTH   = 64      ,
        parameter   int     WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8)
    )
    (
            input   var logic                           m_wb_rst_i      ,
            input   var logic                           m_wb_clk_i      ,
            output  var logic   [WB_ADR_WIDTH-1:0]      m_wb_adr_o      ,
            input   var logic   [WB_DAT_WIDTH-1:0]      m_wb_dat_i      ,
            output  var logic   [WB_DAT_WIDTH-1:0]      m_wb_dat_o      ,
            output  var logic   [WB_SEL_WIDTH-1:0]      m_wb_sel_o      ,
            output  var logic                           m_wb_we_o       ,
            output  var logic                           m_wb_stb_o      ,
            input   var logic                           m_wb_ack_i      
    );

    localparam EPSILON = 0.01;

    // latch
    logic   [WB_DAT_WIDTH-1:0]      wb_dat;
    logic                           wb_ack;
    always_ff @(posedge m_wb_clk_i) begin
        if ( ~m_wb_we_o & m_wb_stb_o & m_wb_ack_i ) begin
            wb_dat <= m_wb_dat_i;
        end
        wb_ack <= m_wb_ack_i;
    end
    
    // write
    task write(
                input   logic   [WB_ADR_WIDTH-1:0]  adr,
                input   logic   [WB_DAT_WIDTH-1:0]  dat,
                input   logic   [WB_SEL_WIDTH-1:0]  sel
            );
    begin
        $display("WISHBONE_WRITE(adr:0x%h dat:0x%h sel:0b%b)", adr, dat, sel);
        @(posedge m_wb_clk_i); #EPSILON;
            m_wb_adr_o = adr;
            m_wb_dat_o = dat;
            m_wb_sel_o = sel;
            m_wb_we_o  = 1'b1;
            m_wb_stb_o = 1'b1;
        @(posedge m_wb_clk_i); #EPSILON;
            while ( wb_ack == 1'b0 ) begin
                @(posedge m_wb_clk_i); #EPSILON;
            end
            m_wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            m_wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            m_wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            m_wb_we_o  = 1'bx;
            m_wb_stb_o = 1'b0;
    end
    endtask

    // read
    task read(
                input   logic   [WB_ADR_WIDTH-1:0]  adr,
                output  logic   [WB_DAT_WIDTH-1:0]  dat
            );
    begin
        @(posedge m_wb_clk_i); #EPSILON;
            m_wb_adr_o = adr;
            m_wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            m_wb_sel_o = {WB_SEL_WIDTH{1'b1}};
            m_wb_we_o  = 1'b0;
            m_wb_stb_o = 1'b1;
        @(posedge m_wb_clk_i); #EPSILON;
            while ( wb_ack == 1'b0 ) begin
                @(posedge m_wb_clk_i); #EPSILON;
            end
            m_wb_adr_o = {WB_ADR_WIDTH{1'bx}};
            m_wb_dat_o = {WB_DAT_WIDTH{1'bx}};
            m_wb_sel_o = {WB_SEL_WIDTH{1'bx}};
            m_wb_we_o  = 1'bx;
            m_wb_stb_o = 1'b0;
            dat = wb_dat;
            $display("[WISHBONE_read] adr:0x%h => dat:0x%h", adr, wb_dat);
    end
    endtask

endmodule


`default_nettype wire


// end of file
