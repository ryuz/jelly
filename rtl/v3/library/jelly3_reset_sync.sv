// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

// syncronous reset generator
module jelly3_reset_sync
        #(
            parameter   bit     IN_LOW_ACTIVE    = 0,   // in_reset が負論理の時 1 にする
            parameter   bit     OUT_LOW_ACTIVE   = 0,   // out_reset が負論理の時 1 にする
            parameter   int     SYNC_REGS        = 2,   // 内部の同期用レジスタ数
            parameter   int     ADDITIONAL_CYCLE = 0    // 追加リセットサイクル
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
    
    // input REGS
    (* SYNC_REGS = "true" *)   logic   [SYNC_REGS-1:0]    reg_reset = {SYNC_REGS{RESET_VALUE}};
    always_ff @(posedge clk) begin
        if ( input_reset ) begin
            reg_reset <= {SYNC_REGS{RESET_VALUE}};
        end
        else if ( cke ) begin
            reg_reset <= (reg_reset >> 1);
        end
    end
    
    // counter
    logic       counter_reset = RESET_VALUE;
    if ( ADDITIONAL_CYCLE > 0 ) begin : blk_counter
        localparam  int     COUNTER_BITS = $clog2(ADDITIONAL_CYCLE+1);
        localparam  type    counter_t    = logic [COUNTER_BITS-1:0];

        counter_t   reg_counter;
        always_ff @(posedge clk or posedge input_reset) begin
            if ( input_reset ) begin
                out_reset   <= RESET_VALUE      ;
                reg_counter <= ADDITIONAL_CYCLE ;
            end
            else if ( cke ) begin
                if ( reg_reset[0] ) begin
                    out_reset   <= (ADDITIONAL_CYCLE == 0) ? ~RESET_VALUE : RESET_VALUE;
                    reg_counter <= ADDITIONAL_CYCLE - 1;
                end
                else begin
                    out_reset <= (reg_counter != 0);
                    if ( reg_counter > 0 ) begin
                        reg_counter <= reg_counter - 1'b1;
                    end
                end
            end
        end
    end
    else begin : bypass_counter
        assign out_reset = reg_reset[0];
    end
    
endmodule


`default_nettype wire


// end of file
