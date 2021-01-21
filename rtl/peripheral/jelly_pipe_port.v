// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// pipe
module jelly_pipe_port
        #(
            parameter   CORE_ID        = 32'h527a_ffff,
            parameter   CORE_VERSION   = 32'h0001_0000,
            
            parameter   DATA_WIDTH     = 1 + 8,
            
            parameter   WB_ADR_WIDTH   = 4,
            parameter   WB_DAT_WIDTH   = 32,
            parameter   WB_SEL_WIDTH   = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            output  wire                        irq,
            
            output  wire    [DATA_WIDTH-1:0]    m_tx_data,
            output  wire                        m_tx_valid,
            input   wire                        m_tx_ready,
            
            input   wire    [DATA_WIDTH-1:0]    s_rx_data,
            input   wire                        s_rx_valid,
            output  wire                        s_rx_ready
        );
    
    // register address offset
    localparam  ADR_CORE_ID      = 8'h00;
    localparam  ADR_CORE_VERSION = 8'h01;
    localparam  ADR_DATA         = 8'h04;
    localparam  ADR_STATUS       = 8'h05;
    localparam  ADR_IRQ_EN       = 8'h06;
    
    // registers
    reg     [DATA_WIDTH-1:0]        reg_tx_data;
    reg                             reg_tx_valid;
    reg                             reg_irq_en;
    
    function [WB_DAT_WIDTH-1:0] reg_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            reg_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    
    always @(posedge clk) begin
        if ( s_wb_rst_i ) begin
            reg_tx_data  <= {DATA_WIDTH{1'bx}};
            reg_tx_valid <= 1'b0;
            reg_irq_en   <= 2'b00;
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i && (s_wb_adr_i == ADR_DATA) ) begin
                reg_tx_valid <= 1'b1;
            end
            else if ( fifo_tx_ready ) begin
                reg_tx_valid <= 1'b0;
            end
            
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_DATA:   reg_tx_data <= reg_mask(reg_tx_data, s_wb_dat_i, s_wb_sel_i);
                ADR_IRQ_EN: reg_irq_en  <= reg_mask(reg_irq_en,  s_wb_dat_i, s_wb_sel_i);
                endcase
            end
        end
    end
    
    // read
    assign s_wb_dat_o = (s_wb_adr_i == ADR_CORE_ID)      ? CORE_ID                   :
                        (s_wb_adr_i == ADR_CORE_VERSION) ? CORE_VERSION              :
                        (s_wb_adr_i == ADR_DATA)         ? s_rx_data                 :
                        (s_wb_adr_i == ADR_STATUS)       ? {s_rx_valid, ~m_tx_valid} :
                        (s_wb_adr_i == ADR_IRQ_EN)       ? reg_irq_en                :
                        {WB_DAT_WIDTH{1'b0}};
    
    assign s_wb_ack_o = s_wb_stb_i;
    
    // irq
    assign irq        = (~reg_tx_valid & reg_irq_en[0]) || (s_rx_valid & reg_irq_en[1]);
    
    // comm
    assign m_tx_data  = reg_tx_data;
    assign m_tx_valid = reg_tx_valid;
    assign s_rx_ready = s_wb_stb_i & ~s_wb_we_i & (s_wb_adr_i == ADR_DATA);
    
    
endmodule


`default_nettype wire



// end of file
