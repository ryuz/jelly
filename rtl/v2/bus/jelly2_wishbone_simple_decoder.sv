// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_wishbone_simple_decoder
        #(
            parameter   int     NUM           = 2,
            parameter   int     WB_ADR_WIDTH  = 30,
            parameter   int     WB_DAT_WIDTH  = 32,
            parameter   int     WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8),
            parameter   int     RANGE_SHIFT   = 0,
            parameter   int     RANGE_WIDTH   = WB_ADR_WIDTH + RANGE_SHIFT,
            parameter   int     ADR_WIDTH     = RANGE_WIDTH
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,

            input   wire    [NUM-1:0][1:0][RANGE_WIDTH-1:0] range,

            input   wire    [WB_ADR_WIDTH-1:0]              s_wb_adr_i,
            output  reg     [WB_DAT_WIDTH-1:0]              s_wb_dat_o,
            input   wire                                    s_wb_stb_i,
            output  reg                                     s_wb_ack_o,
            
            input   wire    [NUM-1:0][WB_DAT_WIDTH-1:0]     m_wb_dat_i,
            output  reg     [NUM-1:0]                       m_wb_stb_o,
            input   wire    [NUM-1:0]                       m_wb_ack_i
        );
    

    // address decoder

    generate
    for ( genvar i = 0; i < NUM; ++i ) begin : loop_decode
        always_comb m_wb_stb_o[i] = s_wb_stb_i
                                    && ADR_WIDTH'(s_wb_adr_i << RANGE_SHIFT) >= ADR_WIDTH'(range[i][0])
                                    && ADR_WIDTH'(s_wb_adr_i << RANGE_SHIFT) <= ADR_WIDTH'(range[i][1]);
        
    end
    endgenerate

    always_comb begin
        s_wb_dat_o = '0;
        s_wb_ack_o = s_wb_stb_i;
        for ( int i = 0; i < NUM; ++i ) begin : loop_cmd
            if ( m_wb_stb_o[i] ) begin
                s_wb_dat_o = m_wb_dat_i[i];
                s_wb_ack_o = m_wb_ack_i[i];
            end
        end
    end
    
endmodule



`default_nettype wire


// end of file
