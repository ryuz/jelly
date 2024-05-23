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
module jelly3_img_bayer_shading_core
        #(
            parameter   int     X_BITS      = 14                                        ,
            parameter   int     Y_BITS      = 12                                        ,
            parameter   int     XY2_BITS    = X_BITS > Y_BITS ? X_BITS*2+1 : Y_BITS*2+1 ,
            parameter   type    x_t         = logic signed [X_BITS-1:0]                 ,
            parameter   type    y_t         = logic signed [Y_BITS-1:0]                 ,
            parameter   type    xy2_t       = logic signed [XY2_BITS-1:0]               ,
            parameter   int     DATA_BITS   = 10                                        ,
            parameter   type    data_t      = logic [DATA_BITS-1:0]                     ,
            parameter   int     GAIN_BITS   = 24                                        ,
            parameter   int     GAIN_Q      = 20                                        ,
            parameter   type    gain_t      = logic [GAIN_BITS-1:0]                     ,
            parameter   int     OFFSET_BITS = DATA_BITS + 4                             ,
            parameter   int     OFFSET_Q    = DATA_BITS                                 ,
            parameter   type    offset_t    = logic [OFFSET_BITS-1:0]                   ,
            localparam  type    phase_t     = logic [1:0]                               
        )
        (
            input   var logic               enable,
            input   var x_t                 param_x     ,
            input   var y_t                 param_y     ,
            input   var xy2_t               param_xy2   ,
            input   var phase_t             param_phase ,
            input   var gain_t      [3:0]   param_gain  ,
            input   var offset_t    [3:0]   param_offset,
            jelly3_img_if.s                 s_img,
            jelly3_img_if.m                 m_img
        );

    localparam  int DE_BITS   = s_img.DE_BITS;
    localparam  int USER_BITS = s_img.USER_BITS;

    localparam  type    de_t      = logic    [DE_BITS  -1:0];
    localparam  type    user_t    = logic    [USER_BITS-1:0];

    localparam  int     CALC_BITS = $bits(data_t)+1;
    localparam  type    calc_t    = logic  signed  [CALC_BITS-1:0];
    localparam  type    mul_t     = logic  signed  [$bits(xy2_t)+$bits(gain_t)-1:0];

    localparam  bit     SIGNED    = calc_t'(data_t'(calc_t'(-1))) == calc_t'(-1);
    localparam  mul_t   MAX_VALUE = SIGNED ? calc_t'({1'b0, {($bits(data_t)-1){1'b1}}}) : calc_t'({1'b0, {$bits(data_t){1'b1}}});
    localparam  mul_t   MIN_VALUE = SIGNED ? calc_t'({1'b1, {($bits(data_t)-1){1'b0}}}) : calc_t'({1'b0, {$bits(data_t){1'b0}}});


//    function calc_t mul(calc_t data, gain_t gain);
//        return calc_t'((mul_t'(data) * mul_t'(gain)) >>> GAIN_Q);
//    endfunction


    
    logic       st0_row_first   ;
    logic       st0_row_last    ;
    logic       st0_col_first   ;
    logic       st0_col_last    ;
    de_t        st0_de          ;
    calc_t      st0_data        ;
    user_t      st0_user        ;
    logic       st0_valid       ;

    x_t         st1_x           ;
    y_t         st1_y           ;
    xy2_t       st1_x2          ;
    xy2_t       st1_y2          ;
    phase_t     st1_phase       ;
    logic       st1_row_first   ;
    logic       st1_row_last    ;
    logic       st1_col_first   ;
    logic       st1_col_last    ;
    de_t        st1_de          ;
    calc_t      st1_data        ;
    user_t      st1_user        ;
    logic       st1_valid       ;

    xy2_t       st2_xy2         ;
    gain_t      st2_gain        ;
    offset_t    st2_offset      ;
    logic       st2_row_first   ;
    logic       st2_row_last    ;
    logic       st2_col_first   ;
    logic       st2_col_last    ;
    de_t        st2_de          ;
    mul_t       st2_data        ;
    user_t      st2_user        ;
    logic       st2_valid       ;

    xy2_t       st3_xy2         ;
    gain_t      st3_gain        ;
    offset_t    st3_offset      ;
    logic       st3_row_first   ;
    logic       st3_row_last    ;
    logic       st3_col_first   ;
    logic       st3_col_last    ;
    de_t        st3_de          ;
    mul_t       st3_data        ;
    user_t      st3_user        ;
    logic       st3_valid       ;

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            st0_valid <= 1'b0;
            st1_valid <= 1'b0;
            st2_valid <= 1'b0;
        end
        else if ( s_img.cke ) begin
            st0_valid <= s_img.valid;
            st1_valid <= st0_valid  ;
            st2_valid <= st1_valid  ;
        end
    end

    always_ff @(posedge s_img.clk) begin
        if ( s_img.cke ) begin
            // stage0
            st0_row_first <= s_img.row_first;
            st0_row_last  <= s_img.row_last ;
            st0_col_first <= s_img.col_first;
            st0_col_last  <= s_img.col_last ;
            st0_de        <= s_img.de       ;
            st0_data      <= s_img.data     ;
            st0_user      <= s_img.user     ;


            // stage1
            if ( st0_valid ) begin
                st1_x  <= st1_x + 1;
                st1_x2 <= st1_x2 + st1_x*2 + 1;
                if ( st0_col_first ) begin
                    st1_x  <= param_x;
                    st1_y  <= st1_y + 1;
                    st1_x2 <= st1_y2;
                    st1_y2 <= st1_y2 + st1_y*2 + 1;
                    if ( st0_row_first ) begin
                        st1_y  <= param_y;
                        st1_x2 <= param_xy2;
                        st1_y2 <= param_xy2;
                    end
                end

                st1_phase[0] <= ~st1_phase[0];
                if ( st0_col_first ) begin
                    if ( st0_row_first ) begin
                        st1_phase <= param_phase;
                    end
                    else begin
                        st1_phase[0] <= param_phase[0];
                        st1_phase[1] <= ~st1_phase[1];
                    end
                end
            end

            st1_row_first <= st0_row_first;
            st1_row_last  <= st0_row_last ;
            st1_col_first <= st0_col_first;
            st1_col_last  <= st0_col_last ;
            st1_de        <= st0_de       ;
            st1_data      <= st0_data     ;
            st1_user      <= st0_user     ;


            // stage2
            st2_gain      <= '0                     ;
            st2_offset    <= gain_t'(1 << OFFSET_Q) ;
            st2_row_first <= st1_row_first  ;
            st2_row_last  <= st1_row_last   ;
            st2_col_first <= st1_col_first  ;
            st2_col_last  <= st1_col_last   ;
            st2_data      <= st1_data       ;
            st2_de        <= st1_de         ;
            st2_user      <= st1_user       ;
            st2_valid     <= st1_valid      ;
            if ( enable ) begin
                st2_gain   <= param_gain  [st1_phase];
                st2_offset <= param_offset[st1_phase];
            end

            st3_row_first <= st2_row_first  ;
            st3_row_last  <= st2_row_last   ;
            st3_col_first <= st2_col_first  ;
            st3_col_last  <= st2_col_last   ;
            st3_data      <= (mul_t'(st1_x2) * mul_t'(st2_gain)) >>> GAIN_Q;
            st3_de        <= st2_de         ;
            st3_user      <= st2_user       ;
            st3_valid     <= st2_valid      ;

            if ( enable ) begin
                st2_gain      <= param_gain  [st1_phase];
                st2_offset    <= param_offset[st1_phase];
            end


            // stage3
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
