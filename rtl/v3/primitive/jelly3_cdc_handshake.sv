// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module jelly3_cdc_handshake
        #(
            parameter   DEST_EXT_HSK   = 1              ,
            parameter   DEST_SYNC_FF   = 4              ,
            parameter   SIM_ASSERT_CHK = 0              ,
            parameter   SRC_SYNC_FF    = 4              ,
            parameter   WIDTH          = 4              ,
            parameter   DEVICE         = "RTL"          ,
            parameter   SIMULATION     = "false"        ,
            parameter   DEBUG          = "false"        
        )
        (
            input   var logic               src_clk     ,
            input   var logic   [WIDTH-1:0] src_in      ,
            input   var logic               src_send    ,
            output  var logic               src_rcv     ,
            input   var logic               dest_clk    ,
            output  var logic               dest_req    ,
            input   var logic               dest_ack    ,
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
        xpm_cdc_handshake
                #(
                    .DEST_EXT_HSK   (DEST_EXT_HSK   ),
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_SYNC_FF    (SRC_SYNC_FF    ),
                    .WIDTH          (WIDTH          ) 
                )
            u_xpm_cdc_handshake
                (
                    .src_clk        (src_clk        ),
                    .src_in         (src_in         ),
                    .src_send       (src_send       ),
                    .src_rcv        (src_rcv        ),
                    .dest_clk       (dest_clk       ),
                    .dest_req       (dest_req       ),
                    .dest_ack       (dest_ack       ),
                    .dest_out       (dest_out       )
                );
    end
    else begin : rtl
        // source
        logic               src_send_reg = 1'b0 ;
        logic   [WIDTH-1:0] src_in_reg          ;

        always_ff @( posedge src_clk ) begin
            src_send_reg <= src_send;
            if ( ~src_send_reg ) begin
                src_in_reg <= src_in;
            end
        end

        logic       dest_send;
        jelly3_cdc_single
                #(
                    .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_INPUT_REG  (0              ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_single_send
                (
                    .src_clk        (src_clk        ),
                    .src_in         (src_send_reg   ),
                    .dest_clk       (dest_clk       ),
                    .dest_out       (dest_send      )
                );

        (* ASYNC_REG = "TRUE" *)
        logic   [WIDTH-1:0] dest_out_reg;
        always_ff @( posedge dest_clk ) begin
            dest_req <= dest_send;
            if ( {dest_req, dest_send} == 2'b01 ) begin
                dest_out_reg <= src_in_reg;
            end
        end
        assign dest_out = dest_out_reg;

        logic   dest_ack_reg;
        if ( !DEST_EXT_HSK ) begin
            always_ff @( posedge dest_clk ) begin
                dest_ack_reg <= dest_send;
            end
        end
        else begin
            assign dest_ack_reg = dest_ack;
        end
        jelly3_cdc_single
                #(
                    .DEST_SYNC_FF   (SRC_SYNC_FF    ),
                    .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                    .SRC_INPUT_REG  (0              ),
                    .DEVICE         (DEVICE         ),
                    .SIMULATION     (SIMULATION     ),
                    .DEBUG          (DEBUG          )
                )
            u_cdc_single_ack
                (
                    .src_clk        (dest_clk       ),
                    .src_in         (dest_ack_reg   ),
                    .dest_clk       (src_clk        ),
                    .dest_out       (src_rcv        )
                );
    end

endmodule


`default_nettype wire


// end of file
