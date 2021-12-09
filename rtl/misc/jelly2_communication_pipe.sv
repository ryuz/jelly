// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_communication_pipe
        #(
            parameter                   CORE_ID            = 32'h527a_f101,
            parameter                   CORE_VERSION       = 32'h0001_0000,
            parameter   int             DATA_WIDTH         = 8,
            parameter   int             FIFO_PTR_WIDTH     = 10,
            parameter                   FIFO_RAM_TYPE      = "block",
            parameter   int             WB_ADR_WIDTH       = 8,
            parameter   int             WB_DAT_WIDTH       = 32,
            parameter   int             WB_SEL_WIDTH       = (WB_DAT_WIDTH / 8),
            parameter   bit     [0:0]   INIT_TX_IRQ_ENABLE = 1'b0,
            parameter   bit     [0:0]   INIT_RX_IRQ_ENABLE = 1'b0
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire                                s_wb_rst_i,
            input   wire                                s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  wire                                s_wb_ack_o,

            output  wire    [0:0]                       irq_tx,
            output  wire    [0:0]                       irq_rx
        );
    
    
    // -------------------------------------
    //  FIFO
    // -------------------------------------
    
    logic   [DATA_WIDTH-1:0]    fifo_s_data;
    logic                       fifo_s_valid;
    logic                       fifo_s_ready;
    logic   [FIFO_PTR_WIDTH:0]  fifo_s_free_count;

    logic   [DATA_WIDTH-1:0]    fifo_m_data;
    logic                       fifo_m_valid;
    logic                       fifo_m_ready;
    logic   [FIFO_PTR_WIDTH:0]  fifo_m_data_count;

    jelly2_fifo_fwtf
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .PTR_WIDTH      (FIFO_PTR_WIDTH),
                .DOUT_REGS      (0),
                .RAM_TYPE       (FIFO_RAM_TYPE),
                .LOW_DEALY      (0),
                .S_REGS         (0),
                .M_REGS         (1)
            )
        i_fifo_fwtf
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         (fifo_s_data),
                .s_valid        (fifo_s_valid),
                .s_ready        (fifo_s_ready),
                .s_free_count   (fifo_s_free_count),

                .m_data         (fifo_m_data),
                .m_valid        (fifo_m_valid),
                .m_ready        (fifo_m_ready),
                .m_data_count   (fifo_m_data_count)
            );
    

    // -------------------------------------
    //  Register
    // -------------------------------------
    
    // register address offset
    localparam  int  ADR_CORE_ID        = 'h00;
    localparam  int  ADR_CORE_VERSION   = 'h01;
    localparam  int  ADR_TX_DATA        = 'h10;
    localparam  int  ADR_TX_STATUS      = 'h11;
    localparam  int  ADR_TX_FREE_COUNT  = 'h12;
    localparam  int  ADR_TX_IRQ_STATUS  = 'h14;
    localparam  int  ADR_TX_IRQ_ENABLE  = 'h15;
    localparam  int  ADR_RX_DATA        = 'h18;
    localparam  int  ADR_RX_STATUS      = 'h19;
    localparam  int  ADR_RX_FREE_COUNT  = 'h1a;
    localparam  int  ADR_RX_IRQ_STATUS  = 'h1c;
    localparam  int  ADR_RX_IRQ_ENABLE  = 'h1d;

    // signals
    logic   [0:0]       tx_irq_status;
    logic   [0:0]       rx_irq_status;

    // registers
    logic   [0:0]       reg_tx_irq_enable;
    logic   [0:0]       reg_rx_irq_enable;

    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] dat,
                                        input [WB_SEL_WIDTH-1:0] sel
                                    );
    begin
        for ( int i = 0; i < WB_DAT_WIDTH; ++i ) begin
            write_mask[i] = sel[i/8] ? dat[i] : org[i];
        end
    end
    endfunction

    always_ff @(posedge s_wb_clk_i ) begin
        if ( s_wb_rst_i ) begin
            reg_tx_irq_enable <= INIT_TX_IRQ_ENABLE;
            reg_rx_irq_enable <= INIT_RX_IRQ_ENABLE;
        end
        else begin
            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( int'(s_wb_adr_i) )
                ADR_TX_IRQ_ENABLE:  reg_tx_irq_enable <= 1'(write_mask(WB_DAT_WIDTH'(reg_tx_irq_enable), s_wb_dat_i, s_wb_sel_i));
                ADR_RX_IRQ_ENABLE:  reg_rx_irq_enable <= 1'(write_mask(WB_DAT_WIDTH'(reg_rx_irq_enable), s_wb_dat_i, s_wb_sel_i));
                default: ;
                endcase
            end
        end
    end
    
    // register read
    always_comb begin : blk_wb_dat_o 
        s_wb_dat_o = '0;
        
        case ( int'(s_wb_adr_i) )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        ADR_TX_DATA:        s_wb_dat_o = '0;
        ADR_TX_STATUS:      s_wb_dat_o = WB_DAT_WIDTH'(fifo_s_ready);
        ADR_TX_FREE_COUNT:  s_wb_dat_o = WB_DAT_WIDTH'(fifo_s_free_count);
        ADR_TX_IRQ_STATUS:  s_wb_dat_o = WB_DAT_WIDTH'(tx_irq_status);
        ADR_TX_IRQ_ENABLE:  s_wb_dat_o = WB_DAT_WIDTH'(reg_tx_irq_enable);
        ADR_RX_DATA:        s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_data);
        ADR_RX_STATUS:      s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_valid);
        ADR_RX_FREE_COUNT:  s_wb_dat_o = WB_DAT_WIDTH'(fifo_m_data_count);
        ADR_RX_IRQ_STATUS:  s_wb_dat_o = WB_DAT_WIDTH'(rx_irq_status);
        ADR_RX_IRQ_ENABLE:  s_wb_dat_o = WB_DAT_WIDTH'(reg_rx_irq_enable);
        default: ;
        endcase
    end
    
    assign s_wb_ack_o = s_wb_stb_i;
    
    assign fifo_s_data  = DATA_WIDTH'(s_wb_dat_i);
    assign fifo_s_valid = (s_wb_stb_i &&  s_wb_we_i && (int'(s_wb_adr_i) == ADR_TX_DATA));
    assign tx_irq_status = fifo_s_ready;
    assign irq_tx = |(tx_irq_status & reg_tx_irq_enable);

    assign fifo_m_ready = (s_wb_stb_i && ~s_wb_we_i && (int'(s_wb_adr_i) == ADR_RX_DATA));
    assign rx_irq_status = fifo_m_valid;
    assign irq_rx = |(rx_irq_status & reg_rx_irq_enable);
    
    
endmodule


`default_nettype wire


// end of file
