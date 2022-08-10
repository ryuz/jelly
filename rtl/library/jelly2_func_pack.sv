// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// サイズゼロを許容したパラメータ等のパッキング機能(サイズ上限あり)
module jelly2_func_pack
        #(
            parameter   int     N  = 1,
            parameter   int     W0 = 0,
            parameter   int     W1 = 0,
            parameter   int     W2 = 0,
            parameter   int     W3 = 0,
            parameter   int     W4 = 0,
            parameter   int     W5 = 0,
            parameter   int     W6 = 0,
            parameter   int     W7 = 0,
            parameter   int     W8 = 0,
            parameter   int     W9 = 0,
            
            // local
            localparam  int     IN0_WIDTH = N * W0,
            localparam  int     IN1_WIDTH = N * W1,
            localparam  int     IN2_WIDTH = N * W2,
            localparam  int     IN3_WIDTH = N * W3,
            localparam  int     IN4_WIDTH = N * W4,
            localparam  int     IN5_WIDTH = N * W5,
            localparam  int     IN6_WIDTH = N * W6,
            localparam  int     IN7_WIDTH = N * W7,
            localparam  int     IN8_WIDTH = N * W8,
            localparam  int     IN9_WIDTH = N * W9,
            localparam  int     OUT_WIDTH = N * (W9 + W8 + W7 + W6 + W5 + W4 + W3 + W2 + W1 + W0),
            localparam  int     IN0_BITS = IN0_WIDTH > 0 ? IN0_WIDTH : 1,
            localparam  int     IN1_BITS = IN1_WIDTH > 0 ? IN1_WIDTH : 1,
            localparam  int     IN2_BITS = IN2_WIDTH > 0 ? IN2_WIDTH : 1,
            localparam  int     IN3_BITS = IN3_WIDTH > 0 ? IN3_WIDTH : 1,
            localparam  int     IN4_BITS = IN4_WIDTH > 0 ? IN4_WIDTH : 1,
            localparam  int     IN5_BITS = IN5_WIDTH > 0 ? IN5_WIDTH : 1,
            localparam  int     IN6_BITS = IN6_WIDTH > 0 ? IN6_WIDTH : 1,
            localparam  int     IN7_BITS = IN7_WIDTH > 0 ? IN7_WIDTH : 1,
            localparam  int     IN8_BITS = IN8_WIDTH > 0 ? IN8_WIDTH : 1,
            localparam  int     IN9_BITS = IN9_WIDTH > 0 ? IN9_WIDTH : 1,
            localparam  int     OUT_BITS = OUT_WIDTH > 0 ? OUT_WIDTH : 1
        )
        (
            input   wire    [IN0_BITS-1:0]  in0,
            input   wire    [IN1_BITS-1:0]  in1,
            input   wire    [IN2_BITS-1:0]  in2,
            input   wire    [IN3_BITS-1:0]  in3,
            input   wire    [IN4_BITS-1:0]  in4,
            input   wire    [IN5_BITS-1:0]  in5,
            input   wire    [IN6_BITS-1:0]  in6,
            input   wire    [IN7_BITS-1:0]  in7,
            input   wire    [IN8_BITS-1:0]  in8,
            input   wire    [IN9_BITS-1:0]  in9,
            output  wire    [OUT_BITS-1:0]  out
        );
    
    localparam  [IN0_BITS:0]  MASK0 = (1 << W0) - 1;
    localparam  [IN1_BITS:0]  MASK1 = (1 << W1) - 1;
    localparam  [IN2_BITS:0]  MASK2 = (1 << W2) - 1;
    localparam  [IN3_BITS:0]  MASK3 = (1 << W3) - 1;
    localparam  [IN4_BITS:0]  MASK4 = (1 << W4) - 1;
    localparam  [IN5_BITS:0]  MASK5 = (1 << W5) - 1;
    localparam  [IN6_BITS:0]  MASK6 = (1 << W6) - 1;
    localparam  [IN7_BITS:0]  MASK7 = (1 << W7) - 1;
    localparam  [IN8_BITS:0]  MASK8 = (1 << W8) - 1;
    localparam  [IN9_BITS:0]  MASK9 = (1 << W9) - 1;
    
    localparam IND0 = W0 > 0 ? W0 : 1;
    localparam IND1 = W1 > 0 ? W1 : 1;
    localparam IND2 = W2 > 0 ? W2 : 1;
    localparam IND3 = W3 > 0 ? W3 : 1;
    localparam IND4 = W4 > 0 ? W4 : 1;
    localparam IND5 = W5 > 0 ? W5 : 1;
    localparam IND6 = W6 > 0 ? W6 : 1;
    localparam IND7 = W7 > 0 ? W7 : 1;
    localparam IND8 = W8 > 0 ? W8 : 1;
    localparam IND9 = W9 > 0 ? W9 : 1;
    
    localparam OW   = W9 + W8 + W7 + W6 + W5 + W4 + W3 + W2 + W1 + W0;
    localparam OUTD = OW > 0 ? OW : 1;
    
    wire    [N*IND0-1:0]  ind0;
    wire    [N*IND1-1:0]  ind1;
    wire    [N*IND2-1:0]  ind2;
    wire    [N*IND3-1:0]  ind3;
    wire    [N*IND4-1:0]  ind4;
    wire    [N*IND5-1:0]  ind5;
    wire    [N*IND6-1:0]  ind6;
    wire    [N*IND7-1:0]  ind7;
    wire    [N*IND8-1:0]  ind8;
    wire    [N*IND9-1:0]  ind9;
    wire    [N*OUTD-1:0]  outd;
    
    assign ind0 = (N*IND0)'(in0);
    assign ind1 = (N*IND1)'(in1);
    assign ind2 = (N*IND2)'(in2);
    assign ind3 = (N*IND3)'(in3);
    assign ind4 = (N*IND4)'(in4);
    assign ind5 = (N*IND5)'(in5);
    assign ind6 = (N*IND6)'(in6);
    assign ind7 = (N*IND7)'(in7);
    assign ind8 = (N*IND8)'(in8);
    assign ind9 = (N*IND9)'(in9);
    assign out  = outd;
    
    
    genvar  i;
    generate
    for ( i = 0; i < N; i = i+1 ) begin : loop_pack
        assign outd[i*OUTD +: OUTD] = ((OUTD'(ind0[i*IND0 +: IND0]) & OUTD'(MASK0)) <<                          (0))
                                    | ((OUTD'(ind1[i*IND1 +: IND1]) & OUTD'(MASK1)) <<                         (W0))
                                    | ((OUTD'(ind2[i*IND2 +: IND2]) & OUTD'(MASK2)) <<                      (W1+W0))
                                    | ((OUTD'(ind3[i*IND3 +: IND3]) & OUTD'(MASK3)) <<                   (W2+W1+W0))
                                    | ((OUTD'(ind4[i*IND4 +: IND4]) & OUTD'(MASK4)) <<                (W3+W2+W1+W0))
                                    | ((OUTD'(ind5[i*IND5 +: IND5]) & OUTD'(MASK5)) <<             (W4+W3+W2+W1+W0))
                                    | ((OUTD'(ind6[i*IND6 +: IND6]) & OUTD'(MASK6)) <<          (W5+W4+W3+W2+W1+W0))
                                    | ((OUTD'(ind7[i*IND7 +: IND7]) & OUTD'(MASK7)) <<       (W6+W5+W4+W3+W2+W1+W0))
                                    | ((OUTD'(ind8[i*IND8 +: IND8]) & OUTD'(MASK8)) <<    (W7+W6+W5+W4+W3+W2+W1+W0))
                                    | ((OUTD'(ind9[i*IND9 +: IND9]) & OUTD'(MASK9)) << (W8+W7+W6+W5+W4+W3+W2+W1+W0));
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
