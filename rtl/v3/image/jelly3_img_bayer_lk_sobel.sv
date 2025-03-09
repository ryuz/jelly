// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_bayer_lk_sobel
        #(
            parameter   int   RAW_BITS  = 8                             ,
            parameter   type  raw_t     = logic         [RAW_BITS-1:0]  ,
            parameter   int   SOBEL_BITS = $bits(raw_t) + 4              ,
            parameter   type  sobel_t    = logic signed  [SOBEL_BITS-1:0] 
        )
        (
            input   var logic                   reset           ,
            input   var logic                   clk             ,
            input   var logic                   cke             ,

            input   var raw_t   [4:0][4:0][1:0] in_raw          ,

            output  var raw_t             [1:0] out_raw         ,
            output  var sobel_t                 out_diff        ,
            output  var sobel_t                 out_gradx       ,
            output  var sobel_t                 out_grady       
        );
    
    raw_t   [1:0]   st0_raw     ;
    sobel_t         st0_diff    ;
    sobel_t         st0_mean00  ;
    sobel_t         st0_mean01  ;
    sobel_t         st0_mean02  ;
    sobel_t         st0_mean10  ;
    sobel_t         st0_mean11  ;
    sobel_t         st0_mean12  ;
    sobel_t         st0_mean20  ;
    sobel_t         st0_mean21  ;
    sobel_t         st0_mean22  ;

    raw_t   [1:0]   st1_raw     ;
    sobel_t         st1_diff    ;
    sobel_t         st1_gradx0  ;
    sobel_t         st1_gradx1  ;
    sobel_t         st1_gradx2  ;
    sobel_t         st1_grady0  ;
    sobel_t         st1_grady1  ;
    sobel_t         st1_grady2  ;

    raw_t   [1:0]   st2_raw     ;
    sobel_t         st2_diff    ;
    sobel_t         st2_gradx0  ;
    sobel_t         st2_gradx1  ;
    sobel_t         st2_grady0  ;
    sobel_t         st2_grady1  ;

    raw_t   [1:0]   st3_raw     ;
    sobel_t         st3_diff    ;
    sobel_t         st3_gradx   ;
    sobel_t         st3_grady   ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_raw    <= in_raw[2][2];
            st0_diff   <= sobel_t'(in_raw[2][2][1]) - sobel_t'(in_raw[2][2][0]);
            st0_mean00 <= sobel_t'(in_raw[0][0][1]) + sobel_t'(in_raw[0][0][0]);
            st0_mean01 <= sobel_t'(in_raw[0][2][1]) + sobel_t'(in_raw[0][2][0]);
            st0_mean02 <= sobel_t'(in_raw[0][4][1]) + sobel_t'(in_raw[0][4][0]);
            st0_mean10 <= sobel_t'(in_raw[2][0][1]) + sobel_t'(in_raw[2][0][0]);
            st0_mean11 <= sobel_t'(in_raw[2][2][1]) + sobel_t'(in_raw[2][2][0]);
            st0_mean12 <= sobel_t'(in_raw[2][4][1]) + sobel_t'(in_raw[2][4][0]);
            st0_mean20 <= sobel_t'(in_raw[4][0][1]) + sobel_t'(in_raw[4][0][0]);
            st0_mean21 <= sobel_t'(in_raw[4][2][1]) + sobel_t'(in_raw[4][2][0]);
            st0_mean22 <= sobel_t'(in_raw[4][4][1]) + sobel_t'(in_raw[4][4][0]);

            // stage 1
            st1_raw    <= st0_raw;
            st1_diff   <= st0_diff;
            st1_gradx0 <= st0_mean02 - st0_mean00;
            st1_gradx1 <= st0_mean12 - st0_mean10;
            st1_gradx2 <= st0_mean22 - st0_mean20;
            st1_grady0 <= st0_mean20 - st0_mean00;
            st1_grady1 <= st0_mean21 - st0_mean01;
            st1_grady2 <= st0_mean22 - st0_mean02;

            // stage 2
            st2_raw    <= st1_raw;
            st2_diff   <= st1_diff;
            st2_gradx0 <= st1_gradx0 + st1_gradx2;
            st2_gradx1 <= st1_gradx1 * 2;
            st2_grady0 <= st1_grady0 + st1_grady2;
            st2_grady1 <= st1_grady1 * 2;
            
            // stage 3
            st3_raw   <= st2_raw;
            st3_diff  <= st2_diff;
            st3_gradx <= st2_gradx0 + st2_gradx1;
            st3_grady <= st2_grady0 + st2_grady1;
        end
    end

    assign  out_raw   = st3_raw;
    assign  out_diff  = st3_diff;
    assign  out_gradx = st3_gradx;
    assign  out_grady = st3_grady;
    

endmodule


`default_nettype wire


// end of file
