// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_cdc_pulse
        #(
            parameter   DEST_SYNC_FF   = 4      ,
            parameter   INIT_SYNC_FF   = 0      ,
            parameter   REG_OUTPUT     = 0      ,
            parameter   RST_USED       = 1      ,
            parameter   SIM_ASSERT_CHK = 0      ,
            parameter   DEVICE         = "RTL"  ,
            parameter   SIMULATION     = "false",
            parameter   DEBUG          = "false"
        )
        (
            output  var logic   dest_pulse  ,
            input   var logic   dest_clk    ,
            input   var logic   dest_rst    ,
            input   var logic   src_clk     ,
            input   var logic   src_pulse   ,
            input   var logic   src_rst     
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
        xpm_cdc_pulse
                #(
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .INIT_SYNC_FF   (INIT_SYNC_FF   ),
                    .REG_OUTPUT     (REG_OUTPUT     ),
                    .RST_USED       (RST_USED       ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ) 
                )
            u_xpm_cdc_pulse
                (
                    .dest_pulse     (dest_pulse     ),
                    .dest_clk       (dest_clk       ),
                    .dest_rst       (dest_rst       ),
                    .src_clk        (src_clk        ),
                    .src_pulse      (src_pulse      ),
                    .src_rst        (src_rst        )
                );
    end
    else begin : rtl
        // source
        logic       src_pulse_reg   = 1'b0 ;
        logic       src_toggle_reg  = 1'b0 ;
        always_ff @( posedge src_clk ) begin
            if ( RST_USED && src_rst ) begin
                src_pulse_reg  <= 1'b0;
                src_toggle_reg <= 1'b0;
            end
            else begin
                src_pulse_reg <= src_pulse;
                if ( {src_pulse_reg, src_pulse} == 2'b01 ) begin
                    src_toggle_reg <= ~src_toggle_reg;
                end
            end
        end

        logic       dest_toggle;
        jelly3_cdc_single
                #(
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_INPUT_REG  (0              ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_single
                (
                    .src_clk        (src_clk        ),
                    .src_in         (src_toggle_reg ),
                    .dest_clk       (dest_clk       ),
                    .dest_out       (dest_toggle    )
                );

        logic   dest_toggle_reg = 1'b0;
        always_ff @( posedge dest_clk ) begin
            if ( RST_USED && dest_rst ) begin
                dest_toggle_reg <= 1'b0;
                dest_pulse      <= 1'b0;
            end
            else begin
                if ( dest_toggle != dest_toggle_reg ) begin
                    dest_toggle_reg <= ~dest_toggle;
                    dest_pulse      <= 1'b1;
                end
                else begin
                    dest_pulse      <= 1'b0;
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
