// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// uart
module jelly2_uart
        #(
            parameter  bit  ASYNC             = 1,
            parameter  int  TX_FIFO_PTR_WIDTH = 4,
            parameter  int  RX_FIFO_PTR_WIDTH = 4,
            parameter       RAM_TYPE          = "distributed",
            
            parameter  int  WB_ADR_WIDTH      = 2,
            parameter  int  WB_DAT_WIDTH      = 32,
            parameter  int  WB_SEL_WIDTH      = (WB_DAT_WIDTH / 8),
            
            parameter  int  DIVIDER_WIDTH     = 8,
            parameter  int  DIVIDER_INIT      = 54-1,
            
            parameter  bit  SIMULATION        = 0,
            parameter  bit  DEBUG             = 1
        )
        (
            input   var logic                       reset,
            input   var logic                       clk,
            
            // UART
            input   var logic                       uart_reset,
            input   var logic                       uart_clk,
            output  var logic                       uart_tx,
            input   var logic                       uart_rx,
            
            output  var logic                       irq_rx,
            output  var logic                       irq_tx,
            
            // control
            input   var logic   [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            output  var logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   var logic   [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            input   var logic                       s_wb_we_i,
            input   var logic   [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   var logic                       s_wb_stb_i,
            output  var logic                       s_wb_ack_o
        );
    
    // FIFO size
    localparam  TX_FIFO_SIZE = (1 << TX_FIFO_PTR_WIDTH);
    localparam  RX_FIFO_SIZE = (1 << RX_FIFO_PTR_WIDTH);
    

    // register address
    localparam  UART_ADR_TX      = 2'b00;
    localparam  UART_ADR_RX      = 2'b00;
    localparam  UART_ADR_STATUS  = 2'b01;
    localparam  UART_ADR_DIVIDER = 2'b10;
    
    
    // -------------------------
    //   Core
    // -------------------------
    
    logic   [DIVIDER_WIDTH-1:0]     divider;
    
    logic   [7:0]                   tx_data;
    logic                           tx_valid;
    logic                           tx_ready;

    logic   [7:0]                   rx_data;
    logic                           rx_valid;
    logic                           rx_ready;
    
    logic   [TX_FIFO_PTR_WIDTH:0]   tx_fifo_free_count;
//  logic   [RX_FIFO_PTR_WIDTH:0]   rx_fifo_data_count;
    
    jelly2_uart_core
            #(
                .ASYNC              (ASYNC),
                .TX_FIFO_PTR_WIDTH  (TX_FIFO_PTR_WIDTH),
                .RX_FIFO_PTR_WIDTH  (RX_FIFO_PTR_WIDTH),
                .RAM_TYPE           (RAM_TYPE),
                .DIVIDER_WIDTH      (DIVIDER_WIDTH),
                .SIMULATION         (SIMULATION),
                .DEBUG              (DEBUG)
            )
        i_uart_core
            (
                .reset              (reset),
                .clk                (clk),
                
                .uart_reset         (uart_reset),
                .uart_clk           (uart_clk),
                .uart_tx            (uart_tx),
                .uart_rx            (uart_rx),
                .divider            (divider),
                
                .tx_data            (tx_data),
                .tx_valid           (tx_valid),
                .tx_ready           (tx_ready),
                
                .rx_data            (rx_data),
                .rx_valid           (rx_valid),
                .rx_ready           (rx_ready),
                
                .tx_fifo_free_count (tx_fifo_free_count),
                .rx_fifo_data_count ()//(rx_fifo_data_count)
            );
    
    
    // irq
    assign irq_tx = (tx_fifo_free_count == TX_FIFO_SIZE);
    assign irq_rx = rx_valid;
    
    
    // -------------------------
    //  register
    // -------------------------
    
    // TX
    assign tx_valid = s_wb_stb_i & s_wb_we_i & (s_wb_adr_i == UART_ADR_TX);
    assign tx_data  = s_wb_dat_i[7:0];
    
    // RX
    assign rx_ready = s_wb_stb_i & !s_wb_we_i & (s_wb_adr_i == UART_ADR_RX);
    
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            divider <= DIVIDER_WIDTH'(DIVIDER_INIT);
        end
        else begin
            if ( s_wb_stb_i && s_wb_we_i && (s_wb_adr_i == 2) ) begin
                divider <= s_wb_dat_i[DIVIDER_WIDTH-1:0];
            end
        end
    end
    
    assign s_wb_dat_o = (s_wb_stb_i && (s_wb_adr_i == UART_ADR_RX))      ? WB_DAT_WIDTH'(rx_data             ) :
                        (s_wb_stb_i && (s_wb_adr_i == UART_ADR_STATUS))  ? WB_DAT_WIDTH'({tx_ready, rx_valid}) :
                        (s_wb_stb_i && (s_wb_adr_i == UART_ADR_DIVIDER)) ? WB_DAT_WIDTH'(divider             ) :
                        {WB_DAT_WIDTH{1'b0}};
    
    assign s_wb_ack_o = s_wb_stb_i;
    
endmodule


`default_nettype wire


// end of file
