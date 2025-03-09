// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_bayer_lk_translation
        #(
            parameter   int   RAW_BITS  = 8                             ,
            parameter   type  raw_t     = logic         [RAW_BITS-1:0]  ,
            parameter   int   CALC_BITS = $bits(raw_t) + 4              ,
            parameter   type  calc_t    = logic signed  [CALC_BITS-1:0] 
        )
        (
            input   var logic       reset       ,
            input   var logic       clk         ,
            input   var logic       cke         ,

            input   var calc_t      in_diff     ,
            input   var calc_t      in_gradx    ,
            input   var calc_t      in_grady    ,

            output  var calc_t      out_gx2     ,
            output  var calc_t      out_gy2     ,
            output  var calc_t      out_gxy     ,
            output  var calc_t      out_ex      ,
            output  var calc_t      out_ey      
        );
    
    calc_t  st0_diff    ;
    calc_t  st0_gradx   ;
    calc_t  st0_grady   ;

    calc_t  st1_gx2     ;
    calc_t  st1_gy2     ;
    calc_t  st1_gxy     ;
    calc_t  st1_ex      ;
    calc_t  st1_ey      ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_diff  <= in_diff    ;
            st0_gradx <= in_gradx   ;
            st0_grady <= in_grady   ;

            // stage 1
            st1_gx2   <= st0_gradx * st0_gradx  ;
            st1_gy2   <= st0_grady * st0_grady  ;
            st1_gxy   <= st0_gradx * st0_grady  ;
            st1_ex    <= st0_gradx * in_diff    ;
            st1_ey    <= st0_grady * in_diff    ;
        end
    end

    assign out_gx2 = st1_gx2;
    assign out_gy2 = st1_gy2;
    assign out_gxy = st1_gxy;
    assign out_ex  = st1_ex ;
    assign out_ey  = st1_ey ;
    
endmodule


`default_nettype wire


// end of file
