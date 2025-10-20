// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// syncronous reset generator
module jelly3_reset_async
        #(
            parameter   bit     IN_LOW_ACTIVE    = 0,   // in_reset が負論理の時 1 にする
            parameter   bit     OUT_LOW_ACTIVE   = 0,   // out_reset が負論理の時 1 にする
            parameter   int     ASYNC_REGS       = 0    // 内部の非同期リセットレジスタ数
        )
        (
            input   var logic   clk         ,
            input   var logic   cke         ,
            input   var logic   in_reset    ,   // asyncrnous reset
            output  var logic   out_reset       // syncrnous reset
        );

    // input polar
    logic   input_reset;
    assign input_reset = IN_LOW_ACTIVE ? ~in_reset : in_reset;

    // output polar
    localparam  bit     RESET_VALUE = OUT_LOW_ACTIVE ? 1'b0 : 1'b1;

    // ASYNC_REGS
    logic   async_reset;
    if ( ASYNC_REGS > 0 ) begin : async_reg
        (* SYNC_REGS = "true" *)
        logic   [ASYNC_REGS-1:0]    reg_async_reset = {ASYNC_REGS{RESET_VALUE}};
        always_ff @(posedge clk or posedge input_reset) begin
            if ( input_reset ) begin
                reg_async_reset <= {ASYNC_REGS{RESET_VALUE}};
            end
            else if ( cke ) begin
                reg_async_reset <= reg_async_reset >> 1;
                reg_async_reset[ASYNC_REGS-1] <= ~RESET_VALUE;
            end
        end
        assign out_reset = reg_async_reset[0];
    end
    else begin : async_bypass
        assign out_reset = input_reset ? RESET_VALUE : ~RESET_VALUE;
    end
    
endmodule

`default_nettype wire

// end of file
