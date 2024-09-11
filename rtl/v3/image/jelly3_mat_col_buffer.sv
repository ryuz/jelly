// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mat_col_buffer
        #(
            parameter   int     TAPS         = 1                            ,
            parameter   int     DE_BITS      = TAPS                         ,
            parameter   type    de_t         = logic [DE_BITS-1:0]          ,
            parameter   int     COLS         = 3                            ,
            parameter   int     USER_BITS    = 1                            ,
            parameter   type    user_t       = logic [USER_BITS-1:0]        ,
            parameter   int     DATA_WIDTH   = 3*8                          ,
            parameter   type    data_t       = logic [DATA_WIDTH-1:0]       ,
            parameter   int     ANCHOR       = (COLS-1) / 2                 ,
            parameter           BORDER_MODE  = "REPLICATE"                  ,   // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   data_t  BORDER_VALUE = {DATA_WIDTH{1'b0}}           ,   // BORDER_MODE == "CONSTANT"
            parameter   bit     ENDIAN       = 0                                // 0: little, 1:big
        )
        (
            input   var logic                           reset               ,
            input   var logic                           clk                 ,
            input   var logic                           cke                 ,
            
            input   var logic                           s_img_row_first     ,
            input   var logic                           s_img_row_last      ,
            input   var logic                           s_img_col_first     ,
            input   var logic                           s_img_col_last      ,
            input   var de_t                            s_img_de            ,
            input   var user_t                          s_img_user          ,
            input   var data_t  [TAPS-1:0]              s_img_data          ,
            input   var logic                           s_img_valid         ,
            
            output  var logic                           m_img_row_first     ,
            output  var logic                           m_img_row_last      ,
            output  var logic                           m_img_col_first     ,
            output  var logic                           m_img_col_last      ,
            output  var de_t                            m_img_de            ,
            output  var user_t                          m_img_user          ,
            output  var data_t  [TAPS-1:0][COLS-1:0]    m_img_data          ,
            output  var logic                           m_img_valid         
        );
    
    localparam  bit     REFLECT     = string'(BORDER_MODE) == "REFLECT" || string'(BORDER_MODE) == "REFLECT_101";
    localparam  int     REF101      = string'(BORDER_MODE) == "REFLECT_101" ? 1 : 0;
    localparam  int     A           = ENDIAN ? COLS-1 - ANCHOR : ANCHOR;
    localparam  int     L_MARGIN0   = A;
    localparam  int     R_MARGIN0   = COLS-A;
    localparam  int     L_MARGIN1   = REFLECT ? R_MARGIN0 - TAPS - 1 + REF101 : 0;
    localparam  int     R_MARGIN1   = REFLECT ? L_MARGIN0 - TAPS - 1 + REF101 : 0;
    localparam  int     L_MARGIN    = L_MARGIN0 > L_MARGIN1 ? L_MARGIN0 : L_MARGIN1;
    localparam  int     R_MARGIN    = R_MARGIN0 > R_MARGIN1 ? R_MARGIN0 : R_MARGIN1;
    localparam  int     L           = (L_MARGIN + TAPS - 1) / TAPS;
    localparam  int     R           = (R_MARGIN + TAPS - 1) / TAPS;
    localparam  int     BUFS        = L + 1 + R;
    localparam  int     POS_BITS    = $clog2(BUFS);
    localparam  type    pos_t       = logic [POS_BITS-1:0];

    // endian swap
    data_t  [TAPS-1:0]  s_img_data_endian  ;
    if ( ENDIAN ) begin : s_data_big
        for ( genvar i = 0; i < TAPS; i++ ) begin : s_data_loop
            assign s_img_data_endian[i] = s_img_data[TAPS-1 - i];
        end
    end
    else begin : s_data_little
        assign s_img_data_endian = s_img_data;
    end

    if ( COLS > 1 ) begin : blk_border
        // stage 0
        logic                       st0_border      , next0_border   ;
        pos_t                       st0_last_pos    , next0_last_pos ;
        logic   [BUFS-1:0]          st0_row_first   , next0_row_first;
        logic   [BUFS-1:0]          st0_row_last    , next0_row_last ;
        logic   [BUFS-1:0]          st0_col_first   , next0_col_first;
        logic   [BUFS-1:0]          st0_col_last    , next0_col_last ;
        de_t    [BUFS-1:0]          st0_de          , next0_de       ;
        user_t  [BUFS-1:0]          st0_user        , next0_user     ;
        data_t  [BUFS*TAPS-1:0]     st0_data0       , next0_data0    ;
        data_t  [BUFS*TAPS-1:0]     st0_data1       , next0_data1    ;
        user_t  [BUFS-1:0]          st0_sel         , next0_sel      ;
        logic   [BUFS-1:0]          st0_valid       , next0_valid    ;
        always_comb begin
            automatic int pos = int'(st0_last_pos);
            next0_border    = st0_border;
            next0_last_pos  = st0_last_pos;
            next0_row_first = $bits(next0_row_first)'({s_img_row_first  ,   st0_row_first} >> $bits(s_img_row_first));
            next0_row_last  = $bits(next0_row_last )'({s_img_row_last   ,   st0_row_last } >> $bits(s_img_row_last ));
            next0_col_first = $bits(next0_col_first)'({s_img_col_first  ,   st0_col_first} >> $bits(s_img_col_first));
            next0_col_last  = $bits(next0_col_last )'({s_img_col_last   ,   st0_col_last } >> $bits(s_img_col_last ));
            next0_de        = $bits(next0_de       )'({s_img_de         ,   st0_de       } >> $bits(s_img_de       ));
            next0_user      = $bits(next0_user     )'({s_img_user       ,   st0_user     } >> $bits(s_img_user     ));
            next0_data0     = $bits(next0_data0    )'({s_img_data_endian,   st0_data0    } >> $bits(s_img_data     ));
            next0_data1     = $bits(next0_data1    )'({s_img_data_endian,   st0_data1    } >> $bits(s_img_data     ));
            next0_sel       = $bits(next0_sel      )'({next0_border     ,   st0_sel      } >> $bits(next0_border   ));
            next0_valid     = $bits(next0_valid    )'({s_img_valid      ,   st0_valid    } >> $bits(s_img_valid    ));

            if ( next0_valid[L] && next0_col_first[L] ) begin
                next0_border = 1'b0;
                next0_sel    = '0;
                for ( int i = 0; i < L*TAPS; i++ ) begin
                    next0_data0[L*TAPS-1 - i] = 'x;
                    if ( string'(BORDER_MODE) == "CONSTANT" ) begin
                        next0_data0[L*TAPS-1 - i] = BORDER_VALUE;
                    end
                    else if ( string'(BORDER_MODE) == "REPLICATE" ) begin
                        next0_data0[L*TAPS-1 - i] = next0_data0[L*TAPS];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT" ) begin
                        next0_data0[L*TAPS-1 - i] = next0_data0[L*TAPS + i];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin
                        next0_data0[L*TAPS-1 - i] = next0_data0[L*TAPS + 1 + i];
                    end
                end
            end
            
            if ( st0_border ) begin
                for ( int i = 0; i < TAPS; i++ ) begin
                    next0_data1[(BUFS-1)*TAPS + i] = 'x;
                    if ( string'(BORDER_MODE) == "CONSTANT" ) begin
                        next0_data1[(BUFS-1)*TAPS + i] = BORDER_VALUE;
                    end
                    else if ( string'(BORDER_MODE) == "REPLICATE" ) begin
                        next0_data1[(BUFS-1)*TAPS + i] = st0_data1[(BUFS-pos)*TAPS-1];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT" ) begin
                        next0_data1[(BUFS-1)*TAPS + i] = st0_data1[(BUFS-pos)*TAPS-1 - (pos*TAPS+i)];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin
                        next0_data1[(BUFS-1)*TAPS + i] = st0_data1[(BUFS-pos)*TAPS-1 - (pos*TAPS+i)-1];
                    end
                end
            end

            if ( s_img_valid && s_img_col_last ) begin
                next0_border   = 1'b1;
                next0_last_pos = 0;
            end
        end


        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_border    <= 'x;
                st0_last_pos  <= 'x;
                st0_row_first <= 'x;
                st0_row_last  <= 'x;
                st0_col_first <= 'x;
                st0_col_last  <= 'x;
                st0_de        <= 'x;
                st0_user      <= 'x;
                st0_data0     <= 'x;
                st0_data1     <= 'x;
                st0_sel       <= 'x;
                st0_valid     <= '0;
            end
            else if ( cke ) begin
                st0_border    <= next0_border   ;
                st0_last_pos  <= next0_last_pos ;
                st0_row_first <= next0_row_first;
                st0_row_last  <= next0_row_last ;
                st0_col_first <= next0_col_first;
                st0_col_last  <= next0_col_last ;
                st0_de        <= next0_de       ;
                st0_user      <= next0_user     ;
                st0_data0     <= next0_data0    ;
                st0_data1     <= next0_data1    ;
                st0_sel       <= next0_sel      ;
                st0_valid     <= next0_valid    ;
            end
        end

        // stage1
        logic                           st1_row_first   ;
        logic                           st1_row_last    ;
        logic                           st1_col_first   ;
        logic                           st1_col_last    ;
        de_t                            st1_de          ;
        user_t                          st1_user        ;
        data_t  [TAPS-1:0][COLS-1:0]    st1_data        ;
        logic                           st1_valid       ;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st1_row_first <= 'x;
                st1_row_last  <= 'x;
                st1_col_first <= 'x;
                st1_col_last  <= 'x;
                st1_de        <= 'x;
                st1_user      <= 'x;
                st1_data      <= 'x;
                st1_valid     <= '0;
            end
            else if ( cke ) begin
                st1_row_first <= st0_row_first[L];
                st1_row_last  <= st0_row_last [L];
                st1_col_first <= st0_col_first[L];
                st1_col_last  <= st0_col_last [L];
                st1_de        <= st0_de       [L];
                st1_user      <= st0_user     [L];
                st1_valid     <= st0_valid    [L];

                for ( int i = 0; i < TAPS; i++ ) begin
                    for ( int j = 0; j < COLS; j++ ) begin
                        st1_data[i][j] <= st0_sel[(L*TAPS + i + j - A) / TAPS] ? st0_data1[L*TAPS + i + j - A] : st0_data0[L*TAPS + i + j - A];
                    end
                end
            end
        end

        assign m_img_row_first = st1_row_first;
        assign m_img_row_last  = st1_row_last ;
        assign m_img_col_first = st1_col_first;
        assign m_img_col_last  = st1_col_last ;
        assign m_img_de        = st1_de       ;
        assign m_img_user      = st1_user     ;
        assign m_img_valid     = st1_valid    ;

        if ( ENDIAN ) begin : m_data_big
            for ( genvar i = 0; i < TAPS; i++ ) begin : m_data_loop1
                for ( genvar j = 0; j < COLS; j++ ) begin : m_data_loop2
                    assign m_img_data[i][j] = st1_data[TAPS-1 - i][COLS-1 - j];
                end
            end
        end
        else begin : m_data_little
            assign m_img_data = st1_data;
        end
    end
    else begin : blk_bypass
        // COLS == 1 の時はバイパスする
        assign m_img_row_first = s_img_row_first;
        assign m_img_row_last  = s_img_row_last;
        assign m_img_col_first = s_img_col_first;
        assign m_img_col_last  = s_img_col_last;
        assign m_img_de        = s_img_de;
        assign m_img_user      = s_img_user;
        assign m_img_data      = s_img_data;
        assign m_img_valid     = s_img_valid;
    end
    
endmodule


`default_nettype wire


// end of file
