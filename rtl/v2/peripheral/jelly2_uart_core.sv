// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// uart
module jelly2_uart_core
        #(
            parameter  bit  ASYNC             = 1,
            parameter  int  TX_FIFO_PTR_WIDTH = 4,
            parameter  int  RX_FIFO_PTR_WIDTH = 4,
            parameter       RAM_TYPE          = "distributed",
            parameter  int  DIVIDER_WIDTH     = 8,
            parameter  bit  SIMULATION        = 0,
            parameter  bit  DEBUG             = 1
        )
        (
            input   var logic                           reset,
            input   var logic                           clk,
            
            input   var logic                           uart_reset,
            input   var logic                           uart_clk,
            output  var logic                           uart_tx,
            input   var logic                           uart_rx,
            input   var logic   [DIVIDER_WIDTH-1:0]     divider,
            
            input   var logic   [7:0]                   tx_data,
            input   var logic                           tx_valid,
            output  var logic                           tx_ready,
            
            output  var logic   [7:0]                   rx_data,
            output  var logic                           rx_valid,
            input   var logic                           rx_ready,
            
            output  var logic   [TX_FIFO_PTR_WIDTH:0]   tx_fifo_free_count,
            output  var logic   [RX_FIFO_PTR_WIDTH:0]   rx_fifo_data_count
        );
    
    localparam  int TX_FIFO_SIZE = (1 << TX_FIFO_PTR_WIDTH);
    localparam  int RX_FIFO_SIZE = (1 << RX_FIFO_PTR_WIDTH);
    
    
    
    // -------------------------
    //  Clock divider
    // -------------------------
    
    logic                       dv_pulse;
    logic   [DIVIDER_WIDTH-1:0] dv_counter;
    always_ff @ ( posedge uart_clk ) begin
        if ( uart_reset ) begin
            dv_pulse   <= 1'b0;
            dv_counter <= 0;
        end
        else begin
            if ( dv_counter == divider ) begin
                dv_pulse   <= 1'b1;
                dv_counter <= 0;
            end
            else begin
                dv_pulse   <= 1'b0;
                dv_counter <= dv_counter + 1'b1;
            end
        end
    end
    
    
    // -------------------------
    //  TX
    // -------------------------
    
    // TX
    logic   [7:0]           tx_fifo_rd_data;
    logic                   tx_fifo_rd_valid;
    logic                   tx_fifo_rd_ready;
    
    // FIFO
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC          (ASYNC),
                .DATA_WIDTH     (8),
                .PTR_WIDTH      (TX_FIFO_PTR_WIDTH),
                .RAM_TYPE       (RAM_TYPE)
            )
        i_fifo_tx
            (
                .s_reset        (reset),
                .s_clk          (clk),
                .s_cke          (1'b1),
                .s_data         (tx_data),
                .s_valid        (tx_valid),
                .s_ready        (tx_ready),
                .s_free_count   (tx_fifo_free_count),
                
                .m_reset        (uart_reset),
                .m_clk          (uart_clk),
                .m_cke          (1'b1),
                .m_data         (tx_fifo_rd_data),
                .m_valid        (tx_fifo_rd_valid),
                .m_ready        (tx_fifo_rd_ready),
                .m_data_count   ()
            );
    
    // transmitter
    jelly2_uart_tx
        i_uart_tx
            (
                .reset          (uart_reset),
                .clk            (uart_clk),
                .dv_pulse       (dv_pulse),
                
                .uart_tx        (uart_tx),
                
                .tx_valid       (tx_fifo_rd_valid),
                .tx_data        (tx_fifo_rd_data),
                .tx_ready       (tx_fifo_rd_ready)
            );
    
    
    
    
    // -------------------------
    //  RX
    // -------------------------
    
    logic   [7:0]               rx_fifo_wr_data;
    logic                       rx_fifo_wr_valid;
//  logic                       rx_fifo_wr_ready;
    
    // FIFO
    jelly2_fifo_generic_fwtf
            #(
                .ASYNC          (ASYNC),
                .DATA_WIDTH     (8),
                .PTR_WIDTH      (RX_FIFO_PTR_WIDTH),
                .RAM_TYPE       (RAM_TYPE)
            )
        i_fifo_rx
            (
                .s_reset        (uart_reset),
                .s_clk          (uart_clk),
                .s_cke          (1'b1),
                .s_data         (rx_fifo_wr_data),
                .s_valid        (rx_fifo_wr_valid),
                .s_ready        (),
                .s_free_count   (),
                
                .m_reset        (reset),
                .m_clk          (clk),
                .m_cke          (1'b1),
                .m_data         (rx_data),
                .m_valid        (rx_valid),
                .m_ready        (rx_ready),
                .m_data_count   (rx_fifo_data_count)
            );
    
    // double latch
    (* ASYNC_REG = "true" *)    logic   [2:0]   ff_uart_rx;
    always_ff @(posedge uart_clk) begin
        if ( uart_reset ) begin
            ff_uart_rx <= 3'b111;
        end
        else begin
            ff_uart_rx <= {ff_uart_rx[1:0], uart_rx};
        end
    end
    
    // receiver
    jelly2_uart_rx
        i_uart_rx
            (
                .reset          (uart_reset),
                .clk            (uart_clk),
                .dv_pulse       (dv_pulse),
                
                .uart_rx        (ff_uart_rx[2]),
                
                .rx_valid       (rx_fifo_wr_valid),
                .rx_data        (rx_fifo_wr_data)
            );
    
    
    // -------------------------
    //  Debug
    // -------------------------
    
    generate
    if ( SIMULATION & DEBUG ) begin
        always_ff @ ( posedge clk ) begin
            if ( rx_valid & rx_ready ) begin
                if ( rx_data >= 8'h20 && rx_data <= 8'h7e ) begin
                    $display("%m : [UART-RX] %h %c", rx_data, rx_data);
                end
                else begin
                    $display("%m : [UART-RX] %h", rx_data);
                end
            end
            
            if ( tx_valid & tx_ready ) begin
                if ( tx_data >= 8'h20 && tx_data <= 8'h7e ) begin
                    $display("%m : [UART-TX] %h %c", tx_data, tx_data);
                end
                else begin
                    $display("%m : [UART-TX] %h", tx_data);
                end
            end
        end
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
