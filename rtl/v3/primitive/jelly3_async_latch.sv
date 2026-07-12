// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_async_latch
        #(
            parameter   WIDTH          = 1          ,
            parameter   SYNC_FF        = 4          ,
            parameter   DEVICE         = "RTL"      ,
            parameter   SIMULATION     = "false"    ,
            parameter   DEBUG          = "false"    
        )
        (
            input   var logic               clk     ,
            input   var logic   [WIDTH-1:0] in_data ,
            output  var logic   [WIDTH-1:0] out_data
        );

        
    (* ASYNC_REG = "TRUE" *)
    logic   [SYNC_FF-1:0][WIDTH-1:0]   out_reg;
    always_ff @(posedge clk) begin
        out_reg[0] <= in_data;
        for ( int i = 1; i < SYNC_FF; i++ ) begin
            out_reg[i] <= out_reg[i-1];
        end
    end
    assign out_data = out_reg[SYNC_FF-1];

endmodule


`default_nettype wire


// end of file
