// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_uart_rx
        (
            // system
            input   var logic           reset,
            input   var logic           clk,
            input   var logic           dv_pulse,
            
            // UART
            input   var logic           uart_rx,
            
            // control
            output  var logic   [7:0]   rx_data,
            output  var logic           rx_valid
        );
    
    // recv
    logic                       rx_ff_buf;
    logic   [8:0]               rx_buf;
    logic                       rx_busy;
    logic   [7:0]               rx_count;
    logic                       rx_wr_valid;
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            rx_ff_buf   <= 1'b1;
            rx_buf      <= {9{1'bx}};
            rx_busy     <= 1'b0;
            rx_count    <= 0;
            rx_wr_valid <= 1'b0;
        end
        else if ( dv_pulse ) begin
            rx_ff_buf <= uart_rx;
            
            if ( !rx_busy ) begin
                rx_wr_valid <= 1'b0;
                if ( rx_ff_buf == 1'b0 ) begin
                    rx_busy  <= 1'b1;
                    rx_count <= 0;
                end
            end
            else begin
                rx_count <= rx_count + 1'b1;
                if ( rx_count[2:0] == 3'h3 ) begin
                    rx_buf <= {rx_ff_buf, rx_buf[8:1]};
                    if ( rx_count[6:3] == 9 ) begin
                        rx_busy     <= 1'b0;
                        rx_wr_valid <= 1'b1;
                    end
                end
            end
        end
    end
    
    assign rx_valid = rx_wr_valid & dv_pulse;
    assign rx_data  = rx_buf[7:0];
    
endmodule


`default_nettype wire


// end of file