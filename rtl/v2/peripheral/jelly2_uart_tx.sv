// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_uart_tx
        (
            // system
            input   var logic           reset,
            input   var logic           clk,
            input   var logic           dv_pulse,
            
            // UART
            output  var logic           uart_tx,
            
            // control
            input   var logic   [7:0]   tx_data,
            input   var logic           tx_valid,
            output  var logic           tx_ready
        );
    
    // TX
    logic                       tx_busy;
    logic   [6:0]               tx_count;
    logic   [8:0]               tx_buf;
    
    always_ff @ ( posedge clk ) begin
        if ( reset ) begin
            tx_busy      <= 1'b0;
            tx_count     <= {7{1'bx}};
            tx_buf[0]    <= 1'b1;
            tx_buf[8:1]  <= {8{1'bx}};
        end
        else if ( dv_pulse ) begin
            if ( !tx_busy ) begin
                if ( tx_valid ) begin
                    tx_busy      <= 1'b1;
                    tx_buf[0]    <= 1'b0;
                    tx_buf[8:1]  <= tx_data;
                    tx_count     <= 7'h00;
                end
            end
            else begin
                tx_count <= tx_count + 1'b1;
                if ( tx_count[2:0] == 4'h7 ) begin
                    tx_buf <= {1'b1, tx_buf[8:1]};
                    if ( tx_count[6:3] == 4'ha ) begin
                        tx_busy <= 1'b0;
                    end
                end
            end
        end
    end
    
    assign tx_ready = ~tx_busy & dv_pulse;
    assign uart_tx  = tx_buf[0];
    
endmodule


`default_nettype wire


// end of file
