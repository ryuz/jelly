// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_clamp_core
        #(
            parameter   int     CALC_BITS = 10                      ,
            parameter   type    calc_t    = logic [CALC_BITS-1:0]
        )
        (
            input   var logic               enable,
            input   var calc_t              min_value,
            input   var calc_t              max_value,
            jelly3_img_if.s                 s_img,
            jelly3_img_if.m                 m_img
        );

    localparam  int S_DATA_BITS = s_img.DATA_BITS;
    localparam  int M_DATA_BITS = m_img.DATA_BITS;
    localparam  int DE_BITS     = s_img.DE_BITS;
    localparam  int USER_BITS   = s_img.USER_BITS;

    localparam  type    s_data_t  = logic    [S_DATA_BITS-1:0];
    localparam  type    m_data_t  = logic    [M_DATA_BITS-1:0];
    localparam  type    de_t      = logic    [DE_BITS    -1:0];
    localparam  type    user_t    = logic    [USER_BITS  -1:0];

    function automatic m_data_t clamp(input s_data_t data);
        calc_t v;
        if ( v < min_value ) v = min_value;
        if ( v > max_value ) v = max_value;
        return m_data_t'(v);
    endfunction

    always_ff @(posedge s_img.clk) begin
        if ( s_img.reset ) begin
            m_img.row_first <= 'x;
            m_img.row_last  <= 'x;
            m_img.col_first <= 'x;
            m_img.col_last  <= 'x;
            m_img.de        <= 'x;
            m_img.data      <= 'x;
            m_img.user      <= 'x;
            m_img.valid     <= 1'b0;
        end
        else if ( s_img.cke ) begin
            m_img.row_first <= s_img.row_first      ;
            m_img.row_last  <= s_img.row_last       ;
            m_img.col_first <= s_img.col_first      ;
            m_img.col_last  <= s_img.col_last       ;
            m_img.de        <= s_img.de             ;
            m_img.data      <= m_data_t'(s_img.data);
            m_img.user      <= s_img.user           ;
            m_img.valid     <= s_img.valid          ;
            if ( enable ) begin
                m_img.data <= clamp(s_img.data);
            end
        end
    end

endmodule


`default_nettype wire


// end of file
