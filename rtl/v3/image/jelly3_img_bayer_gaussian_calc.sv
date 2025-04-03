// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_bayer_gaussian_calc
        #(
            parameter   int   S_RAW_BITS = 10                                   ,
            parameter   type  s_raw_t    = logic [S_RAW_BITS-1:0]               ,
            parameter   int   M_RAW_BITS = 10                                   ,
            parameter   type  m_raw_t    = logic [M_RAW_BITS-1:0]               ,
            parameter   int   SHIFT      = $bits(s_raw_t) + 4 - $bits(m_raw_t)  ,
            parameter   bit   ROUND      = 1'b1                                 
        )
        (
            input   var logic               reset       ,
            input   var logic               clk         ,
            input   var logic               cke         ,

            input   var logic               enable      ,

            input   var s_raw_t [4:0][4:0]  s_raw       ,
            output  var m_raw_t             m_raw       
        );
    

    parameter   int     CALC_BITS = $bits(s_raw_t) + 4    ;
    parameter   type    calc_t    = logic [CALC_BITS-1:0] ;

    parameter   calc_t  ROUND_VAL = ROUND ? (1 << SHIFT) >> 1 : 0 ;

    // ガウス係数を適用
    wire    calc_t  s_raw00 = calc_t'(s_raw[0][0]) << 0;
    wire    calc_t  s_raw02 = calc_t'(s_raw[0][2]) << 1;
    wire    calc_t  s_raw04 = calc_t'(s_raw[0][4]) << 0;
    wire    calc_t  s_raw20 = calc_t'(s_raw[2][0]) << 1;
    wire    calc_t  s_raw22 = calc_t'(s_raw[2][2]) << 2;
    wire    calc_t  s_raw24 = calc_t'(s_raw[2][4]) << 1;
    wire    calc_t  s_raw40 = calc_t'(s_raw[4][0]) << 0;
    wire    calc_t  s_raw42 = calc_t'(s_raw[4][2]) << 1;
    wire    calc_t  s_raw44 = calc_t'(s_raw[4][4]) << 0;

    calc_t      st0_raw22   ;
    calc_t      st0_raw0    ;
    calc_t      st0_raw1    ;
    calc_t      st0_raw2    ;
    calc_t      st0_raw3    ;
    
    calc_t      st1_raw22   ;
    calc_t      st1_raw0    ;
    calc_t      st1_raw1    ;
    
    calc_t      st2_raw22   ;
    calc_t      st2_raw0    ;
    
    calc_t      st3_raw     ;
    
    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_raw22 <= s_raw22;
            st0_raw0  <= s_raw00 + s_raw02;
            st0_raw1  <= s_raw04 + s_raw20;
            st0_raw2  <= s_raw24 + s_raw40;
            st0_raw3  <= s_raw42 + s_raw44;

            // stage 1
            st1_raw22 <= st0_raw22;
            st1_raw0  <= st0_raw0 + st0_raw1;
            st1_raw1  <= st0_raw2 + st0_raw3;

            // stage 2
            st2_raw22 <= st1_raw22;
            st2_raw0  <= st1_raw0 + st1_raw1;

            // stage 3
            if ( enable ) begin
                st3_raw <= st2_raw22 + st2_raw0 + ROUND_VAL;
            end
            else begin
                st3_raw <= st2_raw22 << 2;
            end
        end
    end
    
    assign  m_raw  = m_raw_t'(st3_raw >> SHIFT);
    
endmodule


`default_nettype wire


// end of file
