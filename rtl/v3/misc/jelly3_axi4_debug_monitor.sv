// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module jelly3_axi4_debug_monitor
        #(
            parameter   int     COUNTER_BITS = 16                               ,
            parameter   type    counter_t    = logic signed [COUNTER_BITS-1:0]  ,
            parameter           DEBUG        = "true"                   
        )
        (
            jelly3_axi4_if.mon     mon_axi4
        );
       
    (* MARK_DEBUG=DEBUG *) logic       issue_aw        ;
    (* MARK_DEBUG=DEBUG *) logic       issue_w         ;
    (* MARK_DEBUG=DEBUG *) logic       issue_wlast     ;
    (* MARK_DEBUG=DEBUG *) logic       issue_b         ;
    (* MARK_DEBUG=DEBUG *) logic       issue_ar        ;
    (* MARK_DEBUG=DEBUG *) logic       issue_r         ;
    (* MARK_DEBUG=DEBUG *) logic       issue_rlast     ;
    (* MARK_DEBUG=DEBUG *) counter_t   issue_awlen     ;
    (* MARK_DEBUG=DEBUG *) counter_t   issue_arlen     ;
    assign issue_aw    = mon_axi4.awvalid && mon_axi4.awready                   ;
    assign issue_w     = mon_axi4.wvalid  && mon_axi4.wready                    ;
    assign issue_wlast = mon_axi4.wvalid  && mon_axi4.wready && mon_axi4.wlast  ;
    assign issue_b     = mon_axi4.bvalid  && mon_axi4.bready                    ;
    assign issue_ar    = mon_axi4.arvalid && mon_axi4.arready                   ;
    assign issue_r     = mon_axi4.rvalid  && mon_axi4.rready                    ;
    assign issue_rlast = mon_axi4.rvalid  && mon_axi4.rready &&mon_axi4. rlast  ;
    assign issue_awlen = issue_aw != 0 ? counter_t'(mon_axi4.awlen) + 1 : 0;
    assign issue_arlen = issue_ar != 0 ? counter_t'(mon_axi4.arlen) + 1 : 0;

    (* MARK_DEBUG=DEBUG *)  counter_t   count_aw    ;
    (* MARK_DEBUG=DEBUG *)  counter_t   count_wl    ;
    (* MARK_DEBUG=DEBUG *)  counter_t   count_wc    ;
    (* MARK_DEBUG=DEBUG *)  counter_t   count_ar    ;
    (* MARK_DEBUG=DEBUG *)  counter_t   count_rc    ;

    (* MARK_DEBUG=DEBUG *)  logic       busy_aw     ;
    (* MARK_DEBUG=DEBUG *)  logic       busy_wl     ;
    (* MARK_DEBUG=DEBUG *)  logic       busy_wc     ;
    (* MARK_DEBUG=DEBUG *)  logic       busy_ar     ;
    (* MARK_DEBUG=DEBUG *)  logic       busy_rc     ;

    (* MARK_DEBUG=DEBUG *)  logic       error_aw    ;
    (* MARK_DEBUG=DEBUG *)  logic       error_wl    ;
    (* MARK_DEBUG=DEBUG *)  logic       check_wc    ;
    (* MARK_DEBUG=DEBUG *)  logic       error_ar    ;
    (* MARK_DEBUG=DEBUG *)  logic       error_rc    ;

    always_ff @(posedge mon_axi4.aclk) begin
        if ( ~mon_axi4.aresetn ) begin
            count_aw <= 0;
            count_wl <= 0;
            count_wc <= 0;
            count_ar <= 0;
            count_rc <= 0;
            busy_aw  <= 1'b0;
            busy_wl  <= 1'b0;
            busy_wc  <= 1'b0;
            busy_ar  <= 1'b0;
            busy_rc  <= 1'b0;
            error_aw <= 1'b0;
            error_wl <= 1'b0;
            check_wc <= 1'b0;
            error_ar <= 1'b0;
            error_rc <= 1'b0;

        end
        else begin
            // count
            count_aw <= count_aw + counter_t'(issue_aw   ) - counter_t'(issue_b    );
            count_wl <= count_wl + counter_t'(issue_wlast) - counter_t'(issue_b    );
            count_wc <= count_wc + counter_t'(issue_awlen) - counter_t'(issue_w    );
            count_ar <= count_ar + counter_t'(issue_ar   ) - counter_t'(issue_rlast);
            count_rc <= count_rc + counter_t'(issue_arlen) - counter_t'(issue_r    );

            // busy
            busy_aw  <= count_aw != 0;
            busy_wl  <= count_wl != 0;
            busy_wc  <= count_wc != 0;
            busy_ar  <= count_ar != 0;
            busy_rc  <= count_rc != 0;

            // error
            if ( count_aw + counter_t'(issue_aw   ) < counter_t'(issue_b    ) ) error_aw <= 1'b1;
            if ( count_wl + counter_t'(issue_wlast) < counter_t'(issue_b    ) ) error_wl <= 1'b1;
            if ( count_wc + counter_t'(issue_awlen) < counter_t'(issue_w    ) ) check_wc <= 1'b1;   // 厳密には負になっても良い
            if ( count_ar + counter_t'(issue_ar   ) < counter_t'(issue_rlast) ) error_ar <= 1'b1;
            if ( count_rc + counter_t'(issue_arlen) < counter_t'(issue_r    ) ) error_rc <= 1'b1;
        end
    end
    
endmodule


`default_nettype wire

// end of file
