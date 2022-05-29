// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2015 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_wishbone_address_decoder
        #(
            parameter   int     NUM           = 2,
            parameter   int     WB_ADR_WIDTH  = 12,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            parameter   int     RANGE_SHIFT   = 0,
            parameter   int     RANGE_WIDTH   = WB_ADR_WIDTH + RANGE_SHIFT
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,

            input   wire    [NUM-1:0][1:0][RANGE_WIDTH-1:0] range,

            input   wire    [WB_ADR_WIDTH-1:0]              s_wb_adr_i,
            input   wire    [WB_ADR_WIDTH-1:0]              s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]              s_wb_dat_o,
            input   wire                                    s_wb_stb_i,
            output  wire                                    s_wb_ack_o,
            
            input   wire    [NUM-1:0][WB_DAT_WIDTH-1:0]     m_wb_dat_i,
            output  wire    [NUM-1:0]                       m_wb_stb_o,
            input   wire    [NUM-1:0]                       m_wb_ack_i
        );
    
    always_comb begin
        for ( int i = 0; )
    
    
endmodule



`default_nettype wire


// end of file
