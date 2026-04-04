// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_img_moment_core
        #(
            parameter   int     M00_BITS   = 32                      ,  // 総和
            parameter   type    m00_t      = logic [M00_BITS-1:0]    ,
            parameter   int     M10_BITS   = 32                      ,  // X
            parameter   type    m10_t      = logic [M10_BITS-1:0]    ,
            parameter   int     M01_BITS   = 32                      ,  // Y
            parameter   type    m01_t      = logic [M01_BITS-1:0]    
        )
        (
            jelly3_mat_if.s                     s_mat       ,

            output  var m00_t   [CH_DEPTH-1:0]  m_m00       ,
            output  var m10_t   [CH_DEPTH-1:0]  m_m10       ,
            output  var m01_t   [CH_DEPTH-1:0]  m_m01       ,
            output  var logic                   m_valid     
        );


    localparam  int     TAPS       = s_mat.TAPS         ;
    localparam  int     CH_DEPTH   = s_mat.CH_DEPTH     ;
    localparam  int     CH_BITS    = s_mat.CH_BITS      ;
    localparam  type    ch_t       = logic [CH_BITS-1:0];
    localparam  int     DE_BITS    = s_mat.DE_BITS      ;
    localparam  type    de_t       = logic [DE_BITS-1:0];
    localparam  int     X_BITS     = s_mat.COLS_BITS    ;
    localparam  type    x_t        = logic [X_BITS-1:0] ;
    localparam  int     Y_BITS     = s_mat.ROWS_BITS    ;
    localparam  type    y_t        = logic [Y_BITS-1:0] ;


    // st0 : coordinate/counter stage
    x_t     [TAPS-1:0]                  st0_x       ;
    y_t                                 st0_y       ;
    logic                               st0_start   ;
    logic                               st0_end     ;
    de_t                                st0_de      ;
    ch_t    [TAPS-1:0][CH_DEPTH-1:0]    st0_data    ;
    logic                               st0_valid   ;

    // de_t が 1bit の場合は、de[0] が有効であれば全てのタップが有効とみなす
    function automatic logic is_de(input de_t de, input int tap);
        if ( $bits(de_t) == 1 ) begin
            return de[0];
        end
        else begin
            return de[tap];
        end        
    endfunction


    always_ff @(posedge s_mat.clk) begin
        if ( s_mat.reset ) begin
            st0_x     <= 'x   ;
            st0_y     <= 'x   ;
            st0_start <= 1'bx ;
            st0_end   <= 1'bx ;
            st0_de    <= 'x   ;
            st0_data  <= 'x   ;
            st0_valid <= 1'b0 ;
        end
        else if ( s_mat.cke ) begin
            // X coordinate
            for ( int t = 0; t < TAPS; t = t + 1 ) begin
                if ( s_mat.valid && s_mat.col_first ) begin
                    st0_x[t] <= x_t'(t);
                end
                else if ( st0_valid && st0_de != '0 ) begin
                    st0_x[t] <= st0_x[t] + x_t'(TAPS);
                end
            end

            // Y coordinate
            if ( s_mat.valid ) begin
                if ( s_mat.row_first ) begin
                    st0_y <= '0;
                end
                else if ( s_mat.col_first ) begin
                    st0_y <= st0_y + y_t'(1);
                end
            end

            st0_start <= s_mat.valid && s_mat.row_first && s_mat.col_first;
            st0_end   <= s_mat.valid && s_mat.row_last  && s_mat.col_last ;
            st0_de    <= s_mat.de;
            for ( int t = 0; t < TAPS; t = t + 1 ) begin
                st0_data[t] <= s_mat.valid && is_de(s_mat.de, t) ? s_mat.data[t] : '0;
            end
            st0_valid <= s_mat.valid;
        end
    end

    // st1 : multiply/sum stage
    logic                               st1_valid   ;
    logic                               st1_start   ;
    logic                               st1_end     ;
    m00_t   [TAPS-1:0][CH_DEPTH-1:0]    st1_m00     ;
    m10_t   [TAPS-1:0][CH_DEPTH-1:0]    st1_m10     ;
    m01_t   [TAPS-1:0][CH_DEPTH-1:0]    st1_m01     ;

    always_ff @(posedge s_mat.clk) begin
        if ( s_mat.reset ) begin
            st1_start <= 1'bx;
            st1_end   <= 1'bx;
            st1_m00   <= 'x;
            st1_m10   <= 'x;
            st1_m01   <= 'x;
            st1_valid <= 1'b0;
        end
        else if ( s_mat.cke ) begin
            if ( st0_valid ) begin
                for ( int t = 0; t < TAPS; t++ ) begin
                    for ( int c = 0; c < CH_DEPTH; c++ ) begin
                        st1_m00[t][c] <= m00_t'(st0_data[t][c]);
                        st1_m10[t][c] <= m10_t'(st0_data[t][c]) * m10_t'(st0_x[t]);
                        st1_m01[t][c] <= m01_t'(st0_data[t][c]) * m01_t'(st0_y);
                    end
                end
            end
            st1_start <= st0_start  ;
            st1_end   <= st0_end    ;
            st1_valid <= st0_valid  ;
        end
    end

    // st2 : accumulation/output stage
    always_ff @(posedge s_mat.clk) begin
        if ( s_mat.reset ) begin
            m_m00   <= 'x  ;
            m_m10   <= 'x  ;
            m_m01   <= 'x  ;
            m_valid <= 1'b0;
        end
        else if ( s_mat.cke ) begin
            m_valid <= st1_valid && st1_end;

            if ( st1_valid ) begin
                automatic m00_t   [CH_DEPTH-1:0]  sum_m00;
                automatic m10_t   [CH_DEPTH-1:0]  sum_m10;
                automatic m01_t   [CH_DEPTH-1:0]  sum_m01;
                sum_m00 = '0;
                sum_m10 = '0;
                sum_m01 = '0;
                for ( int c = 0; c < CH_DEPTH; c++ ) begin
                    for ( int t = 0; t < TAPS; t++ ) begin
                        sum_m00[c] += st1_m00[t][c];
                        sum_m10[c] += st1_m10[t][c];
                        sum_m01[c] += st1_m01[t][c];
                    end
                end

                for ( int c = 0; c < CH_DEPTH; c++ ) begin
                    if ( st1_start ) begin
                        m_m00[c] <= sum_m00[c];
                        m_m10[c] <= sum_m10[c];
                        m_m01[c] <= sum_m01[c];
                    end
                    else begin
                        m_m00[c] <= m_m00[c] + sum_m00[c];
                        m_m10[c] <= m_m10[c] + sum_m10[c];
                        m_m01[c] <= m_m01[c] + sum_m01[c];
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
