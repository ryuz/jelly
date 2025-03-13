// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mat_clamp_core
        #(
            parameter   int     CALC_BITS    = 10                       ,   // 計算時のビット幅
            parameter   type    calc_t       = logic [CALC_BITS-1:0]    
        )
        (
            input   var logic               enable      ,
            input   var calc_t              min_value   ,
            input   var calc_t              max_value   ,
            jelly3_mat_if.s                 s_mat       ,
            jelly3_mat_if.m                 m_mat       
        );

    localparam  int     TAPS      = m_mat.TAPS;
    localparam  int     CH_BITS   = m_mat.CH_BITS;
    localparam  int     CH_DEPTH  = m_mat.CH_DEPTH;
    localparam  int     DE_BITS   = m_mat.DE_BITS;
    localparam  int     USER_BITS = m_mat.USER_BITS;
    localparam  type    ch_t      = logic    [CH_BITS    -1:0];
    localparam  type    de_t      = logic    [DE_BITS    -1:0];
    localparam  type    user_t    = logic    [USER_BITS  -1:0];

    function automatic calc_t clamp(input calc_t value);
        if ( value < min_value ) return min_value;
        if ( value > max_value ) return max_value;
        return value;
    endfunction

    always_ff @(posedge s_mat.clk) begin
        if ( s_mat.reset || m_mat.reset ) begin
            m_mat.rows      <= 'x;
            m_mat.cols      <= 'x;
            m_mat.row_first <= 'x;
            m_mat.row_last  <= 'x;
            m_mat.col_first <= 'x;
            m_mat.col_last  <= 'x;
            m_mat.de        <= 'x;
            m_mat.data      <= 'x;
            m_mat.user      <= 'x;
            m_mat.valid     <= 1'b0;
        end
        else if ( s_mat.cke ) begin
            m_mat.rows      <= s_mat.rows           ;
            m_mat.cols      <= s_mat.cols           ;
            m_mat.row_first <= s_mat.row_first      ;
            m_mat.row_last  <= s_mat.row_last       ;
            m_mat.col_first <= s_mat.col_first      ;
            m_mat.col_last  <= s_mat.col_last       ;
            m_mat.de        <= s_mat.de             ;
            m_mat.user      <= s_mat.user           ;
            m_mat.valid     <= s_mat.valid          ;
            
            for ( int tap = 0; tap < TAPS; tap++) begin
                for ( int ch = 0; ch < CH_DEPTH; ch++) begin
                    if ( enable ) begin
                        m_mat.data[tap][ch] <= ch_t'(clamp(calc_t'(s_mat.data[tap][ch])));
                    end
                    else begin
                        m_mat.data[tap][ch] <= ch_t'(s_mat.data[tap][ch]);
                    end
                end
            end
        end
    end

    // assertion
    initial begin
        sva_taps      : assert ( s_mat.TAPS == m_mat.TAPS ) else $warning("s_mat.TAPS == m_mat.TAPS");
        sva_ch_bits   : assert ( s_mat.CH_DEPTH == m_mat.CH_DEPTH ) else $warning("s_mat.CH_DEPTH == m_mat.CH_DEPTH");
    end
    always_comb begin
        sva_connect_clk : assert (m_mat.clk === s_mat.clk);
        sva_connect_cke : assert (m_mat.cke === s_mat.cke);
    end

endmodule


`default_nettype wire


// end of file
