// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_lk_acc_core
        #(
            parameter   int     TAPS        = 1                             ,
            parameter   int     CALC_BITS   = 36                            ,
            parameter   type    calc_t      = logic signed  [CALC_BITS-1:0] ,
            parameter   int     ACC_BITS    = $bits(calc_t) + 20            ,
            parameter   type    acc_t       = logic signed  [ACC_BITS-1:0]  
        )
        (
            input   var logic               reset           ,
            input   var logic               clk             ,
            input   var logic               cke             ,

            input   var logic               in_first        ,
            input   var logic               in_last         ,
            input   var logic   [TAPS-1:0]  in_de           ,
            input   var calc_t  [TAPS-1:0]  in_gx2          ,
            input   var calc_t  [TAPS-1:0]  in_gy2          ,
            input   var calc_t  [TAPS-1:0]  in_gxy          ,
            input   var calc_t  [TAPS-1:0]  in_ex           ,
            input   var calc_t  [TAPS-1:0]  in_ey           ,
            input   var logic               in_valid        ,

            output  var acc_t               out_gx2         ,
            output  var acc_t               out_gy2         ,
            output  var acc_t               out_gxy         ,
            output  var acc_t               out_ex          ,
            output  var acc_t               out_ey          ,
            output  var logic               out_valid       
        );

    // SUM
    logic   sum_first   ;
    logic   sum_last    ;
    logic   sum_de      ;
    calc_t  sum_gx2     ;
    calc_t  sum_gy2     ;
    calc_t  sum_gxy     ;
    calc_t  sum_ex      ;
    calc_t  sum_ey      ;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            calc_t  gx2 ;
            calc_t  gy2 ;
            calc_t  gxy ;
            calc_t  ex  ;
            calc_t  ey  ;
            gx2 = '0;
            gy2 = '0;
            gxy = '0;
            ex  = '0;
            ey  = '0;
            for ( int i = 0; i < TAPS; i = i + 1 ) begin
                if ( in_valid && in_de[i] ) begin
                    gx2 = gx2 + in_gx2[i];
                    gy2 = gy2 + in_gy2[i];
                    gxy = gxy + in_gxy[i];
                    ex  = ex  + in_ex[i];
                    ey  = ey  + in_ey[i];
                end
            end
            sum_first <= in_valid && in_first;
            sum_last  <= in_valid && in_last ;
            sum_gx2   <= gx2  ;
            sum_gy2   <= gy2  ;
            sum_gxy   <= gxy  ;
            sum_ex    <= ex   ;
            sum_ey    <= ey   ;
        end
    end

    // ACC
    acc_t                   acc_gx2         ;
    acc_t                   acc_gy2         ;
    acc_t                   acc_gxy         ;
    acc_t                   acc_ex          ;
    acc_t                   acc_ey          ;
    logic                   acc_valid       ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( sum_first ) begin
                acc_gx2 <= acc_t'(sum_gx2)          ;
                acc_gy2 <= acc_t'(sum_gy2)          ;
                acc_gxy <= acc_t'(sum_gxy)          ;
                acc_ex  <= acc_t'(sum_ex )          ;
                acc_ey  <= acc_t'(sum_ey )          ;
            end
            else begin
                acc_gx2 <= acc_gx2 + acc_t'(sum_gx2);
                acc_gy2 <= acc_gy2 + acc_t'(sum_gy2);
                acc_gxy <= acc_gxy + acc_t'(sum_gxy);
                acc_ex  <= acc_ex  + acc_t'(sum_ex );
                acc_ey  <= acc_ey  + acc_t'(sum_ey );
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            acc_valid <= '0;
        end
        else if ( cke ) begin
            acc_valid <= sum_last;
        end
    end

    assign out_gx2   = acc_gx2  ;
    assign out_gy2   = acc_gy2  ;
    assign out_gxy   = acc_gxy  ;
    assign out_ex    = acc_ex   ;
    assign out_ey    = acc_ey   ;
    assign out_valid = acc_valid;

endmodule


`default_nettype wire


// end of file
