// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// wishbone insert FF
module jelly2_wishbone_to_mem
        #(
            parameter   int     WB_ADR_WIDTH  = 12,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            parameter   int     MEM_ADDR_WIDTH  = 10,
            parameter   int     MEM_DATA_WIDTH  = 128,
            parameter   int     MEM_WE_WIDTH    = MEM_DATA_WIDTH / 8,
            parameter   int     MEM_LATENCY     = 1
        )
        (
            input   var logic                           reset,
            input   var logic                           clk,
            input   var logic                           cke,
            
            input   var logic   [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
            output  var logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
            input   var logic   [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
            input   var logic   [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
            input   var logic                           s_wb_we_i,
            input   var logic                           s_wb_stb_i,
            output  var logic                           s_wb_ack_o,
            
            output  var logic   [MEM_WE_WIDTH-1:0]      m_mem_we,
            output  var logic   [MEM_ADDR_WIDTH-1:0]    m_mem_addr,
            output  var logic   [MEM_DATA_WIDTH-1:0]    m_mem_wdata,
            input   var logic   [MEM_DATA_WIDTH-1:0]    m_mem_rdata
        );

    localparam  int     MEM_SEL_NUM   = MEM_DATA_WIDTH / WB_DAT_WIDTH;
    localparam  int     MEM_ADR_SHIFT = $clog2(MEM_SEL_NUM);
    localparam  int     MEM_SEL_WIDTH = MEM_ADR_SHIFT > 0 ? MEM_ADR_SHIFT : 1;
    localparam  int     MEM_SEL_MASK  = (1 << MEM_ADR_SHIFT) - 1;

    int                                             adr_sel;
    assign adr_sel = (int'(s_wb_adr_i) & MEM_SEL_MASK);

    logic                                           busy;
    logic   [MEM_LATENCY:0]                         mem_re;
    logic   [MEM_LATENCY:0][MEM_SEL_WIDTH-1:0]      mem_sel;


    always_ff @( posedge clk ) begin
        if ( reset ) begin
            busy        <= '0;
            mem_re      <= '0;
            mem_sel     <= 'x;
            s_wb_ack_o  <= '0;
            m_mem_we    <= '0;
            m_mem_addr  <= 'x;
            m_mem_wdata <= 'x;
        end
        else if (cke) begin
            if ( s_wb_ack_o ) begin
                busy <= 1'b0;
            end

            mem_re      <= mem_re  << 1;
            mem_sel     <= mem_sel << MEM_SEL_WIDTH;
            m_mem_we    <= '0;
            m_mem_addr  <= 'x;
            m_mem_wdata <= 'x;
            if ( s_wb_stb_i && !busy ) begin
                busy        <= 1'b1;
                m_mem_addr  <= MEM_ADDR_WIDTH'(s_wb_adr_i >> MEM_ADR_SHIFT);
                if ( s_wb_we_i ) begin
                    m_mem_we   [adr_sel*WB_SEL_WIDTH +: WB_SEL_WIDTH] <= s_wb_sel_i;
                    m_mem_wdata[adr_sel*WB_DAT_WIDTH +: WB_DAT_WIDTH] <= s_wb_dat_i;
                end
                else begin
                    mem_re[0]  <= 1'b1;
                    mem_sel[0] <= MEM_SEL_WIDTH'(adr_sel);
                end
            end

            s_wb_ack_o <= mem_re[MEM_LATENCY] || (!busy && s_wb_stb_i && s_wb_we_i);
            s_wb_dat_o <= m_mem_rdata[mem_sel[MEM_LATENCY] * WB_DAT_WIDTH +: WB_DAT_WIDTH];
        end
    end

endmodule


`default_nettype wire


// end of file
