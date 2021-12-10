// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_communication_pipes
        #(
            parameter                           NUM                = 1,
            parameter                           CORE_ID            = 32'h527a_f101,
            parameter                           CORE_VERSION       = 32'h0001_0000,
            parameter   int                     DATA_WIDTH         = 8,
            parameter   int                     FIFO_PTR_WIDTH     = 10,
            parameter                           FIFO_RAM_TYPE      = "block",
            parameter   int                     SUB_ADR_WIDTH      = 5,
            parameter   int                     WB_ADR_WIDTH       = 8,
            parameter   int                     WB_DAT_WIDTH       = 32,
            parameter   int                     WB_SEL_WIDTH       = (WB_DAT_WIDTH / 8),
            parameter   bit     [NUM-1:0][0:0]  INIT_TX_IRQ_ENABLE = {NUM{1'b0}},
            parameter   bit     [NUM-1:0][0:0]  INIT_RX_IRQ_ENABLE = {NUM{1'b0}}
        )
        (
            input   wire                                s_wb_rst_i,
            input   wire                                s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  reg                                 s_wb_ack_o,

            output  wire    [NUM-1:0][0:0]              irq_tx,
            output  wire    [NUM-1:0][0:0]              irq_rx
        );


    logic   [NUM-1:0][WB_DAT_WIDTH-1:0]     wb_dat_o;
    logic   [NUM-1:0]                       wb_stb_i;
    logic   [NUM-1:0]                       wb_ack_o;

    generate
    for ( genvar i = 0; i < NUM; ++i ) begin
        jelly2_communication_pipe
                #(
                    .CORE_ID            (CORE_ID),
                    .CORE_VERSION       (CORE_VERSION),
                    .CORE_SERIAL        (i),
                    .DATA_WIDTH         (DATA_WIDTH),
                    .FIFO_PTR_WIDTH     (FIFO_PTR_WIDTH),
                    .FIFO_RAM_TYPE      (FIFO_RAM_TYPE),
                    .WB_ADR_WIDTH       (SUB_ADR_WIDTH),
                    .WB_DAT_WIDTH       (WB_DAT_WIDTH),
                    .WB_SEL_WIDTH       (WB_SEL_WIDTH),
                    .INIT_TX_IRQ_ENABLE (INIT_TX_IRQ_ENABLE[i]),
                    .INIT_RX_IRQ_ENABLE (INIT_RX_IRQ_ENABLE[i])
                )
            i_communication_pipe
                (
                    .s_wb_rst_i,
                    .s_wb_clk_i,
                    .s_wb_adr_i         (s_wb_adr_i[SUB_ADR_WIDTH-1:0]),
                    .s_wb_dat_i,
                    .s_wb_dat_o         (wb_dat_o[i]),
                    .s_wb_we_i,
                    .s_wb_sel_i,
                    .s_wb_stb_i         (wb_stb_i[i]),
                    .s_wb_ack_o         (wb_ack_o[i]),

                    .irq_tx             (irq_tx[i]),
                    .irq_rx             (irq_rx[i])
                );
    end
    endgenerate

    always_comb begin : blk_wb
        wb_stb_i = '0;
        s_wb_dat_o = '0;
        s_wb_ack_o = '0;
        for ( int i = 0; i < NUM; ++i ) begin
            if ( s_wb_stb_i && int'(s_wb_adr_i[WB_ADR_WIDTH-1:SUB_ADR_WIDTH]) == i ) begin
                wb_stb_i[i] = 1'b1;
                s_wb_dat_o = wb_dat_o[i];
                s_wb_ack_o = wb_ack_o[i];
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
