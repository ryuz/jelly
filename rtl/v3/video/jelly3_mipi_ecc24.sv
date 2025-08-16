// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mipi_ecc24
        #(
            parameter   int     USER_BITS = 0                       ,
            parameter   type    user_t    = logic [USER_BITS-1:0]   ,
            localparam  type    data_t    = logic [23:0]            ,
            localparam  type    ecc_t     = logic [5:0]             
        )
        (
            input   var logic       reset       ,
            input   var logic       clk         ,
            input   var logic       cke         ,
            
            input   var user_t      s_user      ,
            input   var data_t      s_data      ,
            input   var ecc_t       s_ecc       ,
            input   var logic       s_valid     ,
            
            output  var user_t      m_user      ,
            output  var data_t      m_data      ,
            output  var logic       m_error     ,
            output  var logic       m_corrected ,
            output  var logic       m_valid     
        );
    
    
    // ecc table
    ecc_t   ecc_tbl_0  = 6'h07;
    ecc_t   ecc_tbl_1  = 6'h0b;
    ecc_t   ecc_tbl_2  = 6'h0d;
    ecc_t   ecc_tbl_3  = 6'h0e;
    ecc_t   ecc_tbl_4  = 6'h13;
    ecc_t   ecc_tbl_5  = 6'h15;
    ecc_t   ecc_tbl_6  = 6'h16;
    ecc_t   ecc_tbl_7  = 6'h19;
    ecc_t   ecc_tbl_8  = 6'h1a;
    ecc_t   ecc_tbl_9  = 6'h1c;
    ecc_t   ecc_tbl_10 = 6'h23;
    ecc_t   ecc_tbl_11 = 6'h25;
    ecc_t   ecc_tbl_12 = 6'h26;
    ecc_t   ecc_tbl_13 = 6'h29;
    ecc_t   ecc_tbl_14 = 6'h2a;
    ecc_t   ecc_tbl_15 = 6'h2c;
    ecc_t   ecc_tbl_16 = 6'h31;
    ecc_t   ecc_tbl_17 = 6'h32;
    ecc_t   ecc_tbl_18 = 6'h34;
    ecc_t   ecc_tbl_19 = 6'h38;
    ecc_t   ecc_tbl_20 = 6'h1f;
    ecc_t   ecc_tbl_21 = 6'h2f;
    ecc_t   ecc_tbl_22 = 6'h37;
    ecc_t   ecc_tbl_23 = 6'h3b;
    
    
    user_t      st0_user        ;
    data_t      st0_data        ;
    ecc_t       st0_ecc         ;
    logic       st0_valid       ;
    
    user_t      st1_user        ;
    data_t      st1_data        ;
    ecc_t       st1_recv_ecc    ;
    ecc_t       st1_calc_ecc    ;
    logic       st1_valid       ;
    
    user_t      st2_user        ;
    data_t      st2_data        ;
    ecc_t       st2_syndrome    ;
    logic       st2_valid       ;
    
    user_t      st3_user        ;
    data_t      st3_data        ;
    data_t      st3_xor         ;
    logic       st3_error       ;
    logic       st3_crrected    ;
    logic       st3_valid       ;
    
    user_t      st4_user        ;
    data_t      st4_data        ;
    logic       st4_error       ;
    logic       st4_corrected   ;
    logic       st4_valid       ;
    
    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage 0
            st0_user      <= s_user ;
            st0_data      <= s_data ;
            st0_ecc       <= s_ecc  ;
            
            // stage 1
            st1_user      <= st0_user;
            st1_data      <= st0_data;
            st1_recv_ecc  <= st0_ecc;
            st1_calc_ecc  <= (st0_data[0]  ? ecc_tbl_0  : 6'd0)
                           ^ (st0_data[1]  ? ecc_tbl_1  : 6'd0)
                           ^ (st0_data[2]  ? ecc_tbl_2  : 6'd0)
                           ^ (st0_data[3]  ? ecc_tbl_3  : 6'd0)
                           ^ (st0_data[4]  ? ecc_tbl_4  : 6'd0)
                           ^ (st0_data[5]  ? ecc_tbl_5  : 6'd0)
                           ^ (st0_data[6]  ? ecc_tbl_6  : 6'd0)
                           ^ (st0_data[7]  ? ecc_tbl_7  : 6'd0)
                           ^ (st0_data[8]  ? ecc_tbl_8  : 6'd0)
                           ^ (st0_data[9]  ? ecc_tbl_9  : 6'd0)
                           ^ (st0_data[10] ? ecc_tbl_10 : 6'd0)
                           ^ (st0_data[11] ? ecc_tbl_11 : 6'd0)
                           ^ (st0_data[12] ? ecc_tbl_12 : 6'd0)
                           ^ (st0_data[13] ? ecc_tbl_13 : 6'd0)
                           ^ (st0_data[14] ? ecc_tbl_14 : 6'd0)
                           ^ (st0_data[15] ? ecc_tbl_15 : 6'd0)
                           ^ (st0_data[16] ? ecc_tbl_16 : 6'd0)
                           ^ (st0_data[17] ? ecc_tbl_17 : 6'd0)
                           ^ (st0_data[18] ? ecc_tbl_18 : 6'd0)
                           ^ (st0_data[19] ? ecc_tbl_19 : 6'd0)
                           ^ (st0_data[20] ? ecc_tbl_20 : 6'd0)
                           ^ (st0_data[21] ? ecc_tbl_21 : 6'd0)
                           ^ (st0_data[22] ? ecc_tbl_22 : 6'd0)
                           ^ (st0_data[23] ? ecc_tbl_23 : 6'd0);
            
            // stage 2
            st2_user      <= st1_user                       ;
            st2_data      <= st1_data                       ;
            st2_syndrome  <= st1_recv_ecc ^ st1_calc_ecc    ;
            
            // stage 3
            st3_user      <= st2_user;
            st3_data      <= st2_data;
            st3_xor[0]    <= (st2_syndrome == ecc_tbl_0)    ;
            st3_xor[1]    <= (st2_syndrome == ecc_tbl_1)    ;
            st3_xor[2]    <= (st2_syndrome == ecc_tbl_2)    ;
            st3_xor[3]    <= (st2_syndrome == ecc_tbl_3)    ;
            st3_xor[4]    <= (st2_syndrome == ecc_tbl_4)    ;
            st3_xor[5]    <= (st2_syndrome == ecc_tbl_5)    ;
            st3_xor[6]    <= (st2_syndrome == ecc_tbl_6)    ;
            st3_xor[7]    <= (st2_syndrome == ecc_tbl_7)    ;
            st3_xor[8]    <= (st2_syndrome == ecc_tbl_8)    ;
            st3_xor[9]    <= (st2_syndrome == ecc_tbl_9)    ;
            st3_xor[10]   <= (st2_syndrome == ecc_tbl_10)   ;
            st3_xor[11]   <= (st2_syndrome == ecc_tbl_11)   ;
            st3_xor[12]   <= (st2_syndrome == ecc_tbl_12)   ;
            st3_xor[13]   <= (st2_syndrome == ecc_tbl_13)   ;
            st3_xor[14]   <= (st2_syndrome == ecc_tbl_14)   ;
            st3_xor[15]   <= (st2_syndrome == ecc_tbl_15)   ;
            st3_xor[16]   <= (st2_syndrome == ecc_tbl_16)   ;
            st3_xor[17]   <= (st2_syndrome == ecc_tbl_17)   ;
            st3_xor[18]   <= (st2_syndrome == ecc_tbl_18)   ;
            st3_xor[19]   <= (st2_syndrome == ecc_tbl_19)   ;
            st3_xor[20]   <= (st2_syndrome == ecc_tbl_20)   ;
            st3_xor[21]   <= (st2_syndrome == ecc_tbl_21)   ;
            st3_xor[22]   <= (st2_syndrome == ecc_tbl_22)   ;
            st3_xor[23]   <= (st2_syndrome == ecc_tbl_23)   ;
            st3_error     <= (st2_syndrome != 0)            ;
            st3_crrected  <= (st2_syndrome == 6'b000001)
                          || (st2_syndrome == 6'b000010)
                          || (st2_syndrome == 6'b000100)
                          || (st2_syndrome == 6'b001000)
                          || (st2_syndrome == 6'b010000)
                          || (st2_syndrome == 6'b100000)    ;
            
            // stage 4
            st4_user      <= st3_user                       ;
            st4_data      <= st3_data ^ st3_xor             ;
            st4_error     <= st3_error                      ;
            st4_corrected <= st3_crrected || (st3_xor != 0) ;
        end
    end
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_valid <= 1'b0;
            st1_valid <= 1'b0;
            st2_valid <= 1'b0;
            st3_valid <= 1'b0;
            st4_valid <= 1'b0;
        end
        else if ( cke ) begin
            st0_valid <= s_valid        ;
            st1_valid <= st0_valid      ;
            st2_valid <= st1_valid      ;
            st3_valid <= st2_valid      ;
            st4_valid <= st3_valid      ;
        end
    end
    
    assign m_user      = st4_user       ;
    assign m_data      = st4_data       ;
    assign m_error     = st4_error      ;
    assign m_corrected = st4_corrected  ;
    assign m_valid     = st4_valid      ;
    
endmodule


`default_nettype wire


// end of file
