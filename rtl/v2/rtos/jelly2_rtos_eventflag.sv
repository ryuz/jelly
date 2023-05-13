// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_rtos_eventflag
        #(
            parameter   int                                         TMAX_FLGID   = 1,
            parameter   int                                         FLGPTN_WIDTH = 32,
            parameter   bit     [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    INIT_FLGPTN  = '0
        )
        (
            input   var logic                                       reset,
            input   var logic                                       clk,
            input   var logic                                       cke,

            output  var logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    flgptn,

            input   var logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    set_flg,
            input   var logic   [TMAX_FLGID:1][FLGPTN_WIDTH-1:0]    clr_flg
        );

    always_ff @(posedge clk) begin
        if ( reset ) begin
            flgptn <= INIT_FLGPTN;
        end
        else if ( cke ) begin
            flgptn <= ((flgptn & clr_flg) | set_flg);
        end
    end
    
endmodule


`default_nettype wire


// End of file
