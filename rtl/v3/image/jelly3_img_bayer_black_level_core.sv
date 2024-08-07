// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Black Level Correction
module jelly3_img_bayer_black_level_core
        #(
            parameter   int     S_DATA_BITS = 10                            ,
            parameter   type    s_data_t    = logic [S_DATA_BITS-1:0]       ,
            parameter   int     M_DATA_BITS = S_DATA_BITS + 1               ,
            parameter   type    m_data_t    = logic signed [M_DATA_BITS-1:0],
            parameter   int     OFFSET_BITS = S_DATA_BITS                   ,
            parameter   type    offset_t    = logic [OFFSET_BITS-1:0]       ,
            localparam  type    phase_t     = logic [1:0]                   
        )
        (
            input   var logic               enable,
            input   var phase_t             param_phase,
            input   var offset_t    [3:0]   param_offset,
            jelly3_img_if.s                 s_img,
            jelly3_img_if.m                 m_img
        );

    localparam  int DE_BITS   = s_img.DE_BITS;
    localparam  int USER_BITS = s_img.USER_BITS;

    localparam  type    de_t      = logic    [DE_BITS  -1:0];
    localparam  type    user_t    = logic    [USER_BITS-1:0];

    localparam  int     CALC_BITS = ($bits(s_data_t) > $bits(m_data_t)) ? $bits(s_data_t)+1 : $bits(m_data_t)+1;
    localparam  type    calc_t    = logic  signed  [CALC_BITS-1:0];
    localparam  bit     SIGNED    = calc_t'(s_data_t'(calc_t'(-1))) == calc_t'(-1);

    localparam calc_t   MAX_VALUE = SIGNED ? calc_t'({1'b0, {($bits(m_data_t)-1){1'b1}}}) : calc_t'({1'b0, {$bits(m_data_t){1'b1}}});
    localparam calc_t   MIN_VALUE = SIGNED ? calc_t'({1'b1, {($bits(m_data_t)-1){1'b0}}}) : calc_t'({1'b0, {$bits(m_data_t){1'b0}}});

    
    phase_t             reg_param_phase ;

    phase_t     st0_phase       ;
    logic       st0_row_first   ;
    logic       st0_row_last    ;
    logic       st0_col_first   ;
    logic       st0_col_last    ;
    de_t        st0_de          ;
    calc_t      st0_data        ;
    user_t      st0_user        ;
    logic       st0_valid       ;

    logic       st1_row_first   ;
    logic       st1_row_last    ;
    logic       st1_col_first   ;
    logic       st1_col_last    ;
    de_t        st1_de          ;
    calc_t      st1_data        ;
    user_t      st1_user        ;
    logic       st1_valid       ;

    logic       st2_row_first   ;
    logic       st2_row_last    ;
    logic       st2_col_first   ;
    logic       st2_col_last    ;
    de_t        st2_de          ;
    calc_t      st2_data        ;
    user_t      st2_user        ;
    logic       st2_valid       ;

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            reg_param_phase  <= 'x;

            st0_phase     <= 'x;
            st0_row_first <= 'x;
            st0_row_last  <= 'x;
            st0_col_first <= 'x;
            st0_col_last  <= 'x;
            st0_de        <= 'x;
            st0_data      <= 'x;
            st0_user      <= 'x;
            st0_valid     <= 1'b0;

            st1_row_first <= 'x;
            st1_row_last  <= 'x;
            st1_col_first <= 'x;
            st1_col_last  <= 'x;
            st1_de        <= 'x;
            st1_data      <= 'x;
            st1_user      <= 'x;
            st1_valid     <= 1'b0;

            st2_row_first <= 'x;
            st2_row_last  <= 'x;
            st2_col_first <= 'x;
            st2_col_last  <= 'x;
            st2_de        <= 'x;
            st2_data      <= 'x;
            st2_user      <= 'x;
            st2_valid     <= 1'b0;
        end
        else if ( s_img.cke ) begin
            // stage0
            st0_phase[0] <= ~st0_phase[0];
            if ( s_img.valid && s_img.col_first ) begin
                if ( s_img.row_first ) begin
                    reg_param_phase  <= param_phase;
                    st0_phase        <= param_phase;
                end
                else begin
                    st0_phase[0] <= reg_param_phase[0];
                    st0_phase[1] <= ~st0_phase[1];
                end
            end
            st0_row_first <= s_img.row_first        ;
            st0_row_last  <= s_img.row_last         ;
            st0_col_first <= s_img.col_first        ;
            st0_col_last  <= s_img.col_last         ;
            st0_de        <= s_img.de               ;
            st0_data      <= calc_t'(s_img.data)    ;
            st0_user      <= s_img.user             ;
            st0_valid     <= s_img.valid            ;

            // stage1
            st1_row_first <= st0_row_first  ;
            st1_row_last  <= st0_row_last   ;
            st1_col_first <= st0_col_first  ;
            st1_col_last  <= st0_col_last   ;
            st1_data      <= st0_data       ;
            st1_de        <= st0_de         ;
            st1_user      <= st0_user       ;
            st1_valid     <= st0_valid      ;
            if ( enable ) begin
                st1_data      <= st0_data - calc_t'(param_offset[st0_phase]);
            end

            // stage2
            st2_row_first <= st1_row_first  ;
            st2_row_last  <= st1_row_last   ;
            st2_col_first <= st1_col_first  ;
            st2_col_last  <= st1_col_last   ;
            st2_data      <= st1_data       ;
            st2_de        <= st1_de         ;
            st2_user      <= st1_user       ;
            st2_valid     <= st1_valid      ;
            if ( st1_data < MIN_VALUE ) st2_data <= MIN_VALUE;
            if ( st1_data > MAX_VALUE ) st2_data <= MAX_VALUE;
        end
    end

    assign m_img.row_first = st2_row_first          ;
    assign m_img.row_last  = st2_row_last           ;
    assign m_img.col_first = st2_col_first          ;
    assign m_img.col_last  = st2_col_last           ;
    assign m_img.de        = st2_de                 ;
    assign m_img.data      = m_data_t'(st2_data)    ;
    assign m_img.user      = st2_user               ;
    assign m_img.valid     = st2_valid              ;

endmodule


`default_nettype wire


// end of file
