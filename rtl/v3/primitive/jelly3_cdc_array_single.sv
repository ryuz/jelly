// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_cdc_array_single
        #(
            parameter   DEST_SYNC_FF   = 4          ,
            parameter   SIM_ASSERT_CHK = 0          ,
            parameter   SRC_INPUT_REG  = 1          ,
            parameter   WIDTH          = 2          ,
            parameter   DEVICE         = "RTL"      ,
            parameter   SIMULATION     = "false"    ,
            parameter   DEBUG          = "false"    
        )
        (
            input   var logic               src_clk ,
            input   var logic   [WIDTH-1:0] src_in  ,
            input   var logic               dest_clk,
            output  var logic   [WIDTH-1:0] dest_out
        );

    if (   string'(DEVICE) == "SPARTAN6"
        || string'(DEVICE) == "VIRTEX6"
        || string'(DEVICE) == "7SERIES"
        || string'(DEVICE) == "ULTRASCALE"
        || string'(DEVICE) == "ULTRASCALE_PLUS"
        || string'(DEVICE) == "ULTRASCALE_PLUS_ES1"
        || string'(DEVICE) == "ULTRASCALE_PLUS_ES2"
        || string'(DEVICE) == "VERSAL_AI_CORE"
        || string'(DEVICE) == "VERSAL_AI_CORE_ES1"
        || string'(DEVICE) == "VERSAL_AI_CORE_ES2"
        || string'(DEVICE) == "VERSAL_PRIME"
        || string'(DEVICE) == "VERSAL_PRIME_ES1"
        || string'(DEVICE) == "VERSAL_PRIME_ES2"
    ) begin : xilinx
        xpm_cdc_array_single
                #(
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_INPUT_REG  (SRC_INPUT_REG  ),
                    .WIDTH          (WIDTH          )
                )
            u_xpm_cdc_array_single
                (
                    .src_clk        (src_clk        ),
                    .src_in         (src_in         ),
                    .dest_clk       (dest_clk       ),
                    .dest_out       (dest_out       )
                );
    end
    else begin : rtl
        logic   [WIDTH-1:0]   src_in_reg;
        always_ff @(posedge src_clk) begin
            src_in_reg <= src_in;
        end
        
        (* ASYNC_REG = "TRUE" *)
        logic   [DEST_SYNC_FF-1:0][WIDTH-1:0]   dest_out_reg;
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
