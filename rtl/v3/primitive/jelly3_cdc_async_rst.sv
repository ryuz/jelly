// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_cdc_async_rst
        #(
            parameter   DEST_SYNC_FF    = 4         ,
            parameter   RST_ACTIVE_HIGH = 0         ,
            parameter   DEVICE          = "RTL"     ,
            parameter   SIMULATION      = "false"   ,
            parameter   DEBUG           = "false"   
        )
        (
            input   var logic   src_arst    ,
            input   var logic   dest_clk    ,
            output  var logic   dest_arst
        );

    if (
        // verilator lint_off WIDTHEXPAND
           DEVICE == "SPARTAN6"
        || DEVICE == "VIRTEX6"
        || DEVICE == "7SERIES"
        || DEVICE == "ULTRASCALE"
        || DEVICE == "ULTRASCALE_PLUS"
        || DEVICE == "ULTRASCALE_PLUS_ES1"
        || DEVICE == "ULTRASCALE_PLUS_ES2"
        || DEVICE == "VERSAL_AI_CORE"
        || DEVICE == "VERSAL_AI_CORE_ES1"
        || DEVICE == "VERSAL_AI_CORE_ES2"
        || DEVICE == "VERSAL_PRIME"
        || DEVICE == "VERSAL_PRIME_ES1"
        || DEVICE == "VERSAL_PRIME_ES2"
        // verilator lint_on WIDTHEXPAND
    ) begin : xilinx
        xpm_cdc_async_rst
                #(
                    .DEST_SYNC_FF       (DEST_SYNC_FF       ),
                    .RST_ACTIVE_HIGH    (RST_ACTIVE_HIGH    )
                )
            u_xpm_cdc_async_rst
                (
                    .src_arst           (src_arst           ),
                    .dest_clk           (dest_clk           ),
                    .dest_arst          (dest_arst          )
                );
    end
    else begin : rtl
        if ( RST_ACTIVE_HIGH ) begin : active_high
            (* ASYNC_REG = "TRUE" *)
            logic   [DEST_SYNC_FF-1:0]  dest_arst_regs = '1;
            always_ff @(posedge dest_clk or posedge src_arst) begin
                if ( src_arst ) begin
                    dest_arst_regs <= '1;
                end
                else begin
                    dest_arst_regs[0] <= 1'b0;
                    for ( int i = 1; i < DEST_SYNC_FF; i++ ) begin
                        dest_arst_regs[i] <= dest_arst_regs[i-1];
                    end
                end
            end
            assign dest_arst = dest_arst_regs[DEST_SYNC_FF-1];
        end
        else begin : active_low
            (* ASYNC_REG = "TRUE" *)
            logic   [DEST_SYNC_FF-1:0]  dest_arst_regs = '0;
            always_ff @(posedge dest_clk or negedge src_arst) begin
                if ( !src_arst ) begin
                    dest_arst_regs <= '0;
                end
                else begin
                    dest_arst_regs[0] <= 1'b1;
                    for ( int i = 1; i < DEST_SYNC_FF; i++ ) begin
                        dest_arst_regs[i] <= dest_arst_regs[i-1];
                    end
                end
            end
            assign dest_arst = dest_arst_regs[DEST_SYNC_FF-1];
        end
    end

endmodule


`default_nettype wire


// end of file
