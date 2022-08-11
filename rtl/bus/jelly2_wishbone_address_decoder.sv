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
            parameter   int     RANGE_WIDTH   = WB_ADR_WIDTH + RANGE_SHIFT,
            parameter   bit     SREG          = 1'b0,
            parameter   bit     MREG          = 1'b0
        )
        (
            input   wire                                    reset,
            input   wire                                    clk,
            input   wire                                    cke,

            input   wire    [NUM-1:0][1:0][RANGE_WIDTH-1:0] range,

            input   wire    [WB_ADR_WIDTH-1:0]              s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]              s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]              s_wb_dat_i,
            input   wire    [WB_SEL_WIDTH-1:0]              s_wb_sel_i,
            input   wire                                    s_wb_we_i,
            input   wire                                    s_wb_stb_i,
            output  wire                                    s_wb_ack_o,
            
            output  wire    [NUM-1:0][WB_ADR_WIDTH-1:0]     m_wb_adr_o,
            input   wire    [NUM-1:0][WB_DAT_WIDTH-1:0]     m_wb_dat_i,
            output  wire    [NUM-1:0][WB_DAT_WIDTH-1:0]     m_wb_dat_o,
            output  wire    [NUM-1:0][WB_SEL_WIDTH-1:0]     m_wb_sel_o,
            output  wire    [NUM-1:0]                       m_wb_we_o,
            output  wire    [NUM-1:0]                       m_wb_stb_o,
            input   wire    [NUM-1:0]                       m_wb_ack_i
        );
    

    // slave port
    logic   [WB_ADR_WIDTH-1:0]              s_ff_adr_i;
    logic   [WB_DAT_WIDTH-1:0]              s_ff_dat_o;
    logic   [WB_DAT_WIDTH-1:0]              s_ff_dat_i;
    logic   [WB_SEL_WIDTH-1:0]              s_ff_sel_i;
    logic                                   s_ff_we_i;
    logic                                   s_ff_stb_i;
    logic                                   s_ff_ack_o;
    jelly2_wishbone_ff
            #(
                .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                .WB_DAT_WIDTH   (WB_DAT_WIDTH),
                .WB_SEL_WIDTH   (WB_SEL_WIDTH),
                .SREG           (SREG),
                .MREG           (1'b0)
            )
        i_wishbone_ff_s
            (
                .reset,
                .clk,
                .cke,

                .s_wb_adr_i,
                .s_wb_dat_o,
                .s_wb_dat_i,
                .s_wb_sel_i,
                .s_wb_we_i,
                .s_wb_stb_i,
                .s_wb_ack_o,

                .m_wb_adr_o     (s_ff_adr_i),
                .m_wb_dat_i     (s_ff_dat_o),
                .m_wb_dat_o     (s_ff_dat_i),
                .m_wb_sel_o     (s_ff_sel_i),
                .m_wb_we_o      (s_ff_we_i),
                .m_wb_stb_o     (s_ff_stb_i),
                .m_wb_ack_i     (s_ff_ack_o)
            );


    // master port
    logic   [NUM-1:0][WB_ADR_WIDTH-1:0]     m_ff_adr_o;
    logic   [NUM-1:0][WB_DAT_WIDTH-1:0]     m_ff_dat_i;
    logic   [NUM-1:0][WB_DAT_WIDTH-1:0]     m_ff_dat_o;
    logic   [NUM-1:0][WB_SEL_WIDTH-1:0]     m_ff_sel_o;
    logic   [NUM-1:0]                       m_ff_we_o;
    logic   [NUM-1:0]                       m_ff_stb_o;
    logic   [NUM-1:0]                       m_ff_ack_i;
    
    generate
    for ( genvar i = 0; i < NUM; ++i ) begin : loop_ff
        jelly2_wishbone_ff
                #(
                    .WB_ADR_WIDTH   (WB_ADR_WIDTH),
                    .WB_DAT_WIDTH   (WB_DAT_WIDTH),
                    .WB_SEL_WIDTH   (WB_SEL_WIDTH),
                    .SREG           (1'b0),
                    .MREG           (MREG)
                )
            i_wishbone_ff_m
                (
                    .reset,
                    .clk,
                    .cke,

                    .s_wb_adr_i     (m_ff_adr_o[i]),
                    .s_wb_dat_o     (m_ff_dat_i[i]),
                    .s_wb_dat_i     (m_ff_dat_o[i]),
                    .s_wb_sel_i     (m_ff_sel_o[i]),
                    .s_wb_we_i      (m_ff_we_o [i]),
                    .s_wb_stb_i     (m_ff_stb_o[i]),
                    .s_wb_ack_o     (m_ff_ack_i[i]),

                    .m_wb_adr_o     (m_wb_adr_o[i]),
                    .m_wb_dat_i     (m_wb_dat_i[i]),
                    .m_wb_dat_o     (m_wb_dat_o[i]),
                    .m_wb_sel_o     (m_wb_sel_o[i]),
                    .m_wb_we_o      (m_wb_we_o [i]),
                    .m_wb_stb_o     (m_wb_stb_o[i]),
                    .m_wb_ack_i     (m_wb_ack_i[i])
                );
    end
    endgenerate


    // address decoder
    localparam ADR_WIDTH = WB_ADR_WIDTH > RANGE_WIDTH ? WB_ADR_WIDTH : RANGE_WIDTH;

    generate
    for ( genvar i = 0; i < NUM; ++i ) begin : loop_decode
        always_comb m_ff_adr_o[i] = s_ff_adr_i;
        always_comb m_ff_dat_o[i] = s_ff_dat_i;
        always_comb m_ff_sel_o[i] = s_ff_sel_i;
        always_comb m_ff_we_o[i]  = s_ff_we_i;
        always_comb m_ff_stb_o[i] = s_ff_stb_i
                                    && ADR_WIDTH'(s_ff_adr_i << RANGE_SHIFT) >= ADR_WIDTH'(range[i][0])
                                    && ADR_WIDTH'(s_ff_adr_i << RANGE_SHIFT) <= ADR_WIDTH'(range[i][1]);
        
    end
    endgenerate

    always_comb begin
        s_ff_dat_o = '0;
        s_ff_ack_o = s_ff_stb_i;
        for ( int i = 0; i < NUM; ++i ) begin : loop_cmd
            if ( m_ff_stb_o[i] ) begin
                s_ff_dat_o = m_ff_dat_i[i];
                s_ff_ack_o = m_ff_ack_i[i];
            end
        end
    end
    
endmodule



`default_nettype wire


// end of file
