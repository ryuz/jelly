// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuji Fuchikami 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire                        reset,
            input   wire                        clk
        );
    
    int     cycle = 0;
    always_ff @(posedge clk) begin
        cycle <= cycle + 1;
    end

    logic   [31:0]      counter;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= '0;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end

endmodule


`default_nettype wire


// end of file
