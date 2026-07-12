// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_cdc_single
        #(
            parameter   DEST_SYNC_FF   = 4          ,
            parameter   SIM_ASSERT_CHK = 0          ,
            parameter   SRC_INPUT_REG  = 1          ,
            parameter   DEVICE         = "RTL"      ,
            parameter   SIMULATION     = "false"    ,
            parameter   DEBUG          = "false"    
        )
        (
            input   var logic   src_clk ,
            input   var logic   src_in  ,
            input   var logic   dest_clk,
            output  var logic   dest_out
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
        xpm_cdc_single
                #(
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_INPUT_REG  (SRC_INPUT_REG  )
                )
            u_xpm_cdc_single
                (
                    .src_clk        (src_clk        ),
                    .src_in         (src_in         ),
                    .dest_clk       (dest_clk       ),
                    .dest_out       (dest_out       )
                );
    end
    else begin : rtl
        logic   src_in_reg;
        always_ff @(posedge src_clk) begin
            src_in_reg <= src_in;
        end
        
        (* ASYNC_REG = "TRUE" *)
        logic   [DEST_SYNC_FF-1:0]  dest_out_reg;
        always_ff @(posedge dest_clk) begin
            dest_out_reg[0] <= SRC_INPUT_REG ? src_in_reg : src_in;
            for ( int i = 1; i < DEST_SYNC_FF; i++ ) begin
                dest_out_reg[i] <= dest_out_reg[i-1];
            end
        end
        assign dest_out = dest_out_reg[DEST_SYNC_FF-1];
    end

endmodule


`default_nettype wire


// end of file
