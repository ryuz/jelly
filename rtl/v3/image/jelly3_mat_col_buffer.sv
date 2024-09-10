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
            output  var logic                           m_img_de            ,
            output  var user_t                          m_img_user          ,
            output  var data_t  [TAPS-1:0][COLS-1:0]    m_img_data          ,
            output  var logic                           m_img_valid         
        );
    
    localparam  bit     REFLECT     = string'(BORDER_MODE) == "REFLECT" || string'(BORDER_MODE) == "REFLECT_101";
    localparam  int     REF101      = string'(BORDER_MODE) == "REFLECT_101" ? 1 : 0;
    localparam  int     A           = ENDIAN ? ANCHOR : COLS-1 - ANCHOR;
    localparam  int     L_MARGIN0   = A;
    localparam  int     R_MARGIN0   = COLS-A;
    localparam  int     L_MARGIN1   = REFLECT ? R_MARGIN0 - TAPS - 1 + REF101 : 0;
    localparam  int     R_MARGIN1   = REFLECT ? L_MARGIN0 - TAPS - 1 + REF101 : 0;
    localparam  int     L_MARGIN    = L_MARGIN0 > L_MARGIN1 ? L_MARGIN0 : L_MARGIN1;
    localparam  int     R_MARGIN    = R_MARGIN0 > R_MARGIN1 ? R_MARGIN0 : R_MARGIN1;
    localparam  int     L           = (L_MARGIN + TAPS - 1) / TAPS;
    localparam  int     R           = (R_MARGIN + TAPS - 1) / TAPS;
    localparam  int     BUFS        = L + 1 + R;


    // endian swap
    data_t  [TAPS-1:0]  s_img_data0  ;
    if ( ENDIAN ) begin : s_data_big
        for ( genvar i = 0; i < TAPS; i++ ) begin : s_data_loop
            assign s_img_data0[i] = s_img_data[TAPS-1 - i];
        end
    end
    else begin : s_data_little
        assign s_img_data0 = s_img_data;
    end

    if ( COLS > 1 ) begin : blk_border
        // stage 0
        logic   [BUFS-1:0]          st0_row_first   ;
        logic   [BUFS-1:0]          st0_row_last    ;
        logic   [BUFS-1:0]          st0_col_first   ;
        logic   [BUFS-1:0]          st0_col_last    ;
        de_t    [BUFS-1:0]          st0_de          ;
        user_t  [BUFS-1:0]          st0_user        ;
        data_t  [BUFS*TAPS-1:0]     st0_data        ;
        logic   [BUFS-1:0]          st0_valid       ;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_row_first <= 'x;
                st0_row_last  <= 'x;
                st0_col_first <= 'x;
                st0_col_last  <= 'x;
                st0_de        <= 'x;
                st0_user      <= 'x;
                st0_data      <= 'x;
                st0_valid     <= '0;
            end
            else if ( cke ) begin
                st0_row_first <= $bits(st0_row_first)'({s_img_row_first ,   st0_row_first} >> $bits(s_img_row_first));
                st0_row_last  <= $bits(st0_row_last )'({s_img_row_last  ,   st0_row_last } >> $bits(s_img_row_last ));
                st0_col_first <= $bits(st0_col_first)'({s_img_col_first ,   st0_col_first} >> $bits(s_img_col_first));
                st0_col_last  <= $bits(st0_col_last )'({s_img_col_last  ,   st0_col_last } >> $bits(s_img_col_last ));
                st0_de        <= $bits(st0_de       )'({s_img_de        ,   st0_de       } >> $bits(s_img_de       ));
                st0_user      <= $bits(st0_user     )'({s_img_user      ,   st0_user     } >> $bits(s_img_user     ));
                st0_data      <= $bits(st0_data     )'({s_img_data0     ,   st0_data     } >> $bits(s_img_data     ));
                st0_valid     <= $bits(st0_valid    )'({s_img_valid     ,   st0_valid    } >> $bits(s_img_valid    ));
            end
        end

        // border
        data_t  [BUFS*TAPS-1:0] st0_data0  ;
        always_comb begin
            st0_data0 = st0_data;
            if ( st0_col_first[L] ) begin
                for ( int i = 0; i < L*TAPS; i++ ) begin
                    automatic int j;
                    st0_data0[L*TAPS-1 - i] = 'x;
                    if ( string'(BORDER_MODE) == "CONSTANT" ) begin
                        st0_data0[L*TAPS-1 - i] = BORDER_VALUE;
                    end
                    else if ( string'(BORDER_MODE) == "REPLICATE" ) begin
                        st0_data0[L*TAPS-1 - i] = st0_data[L*TAPS];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT" ) begin
                        st0_data0[L*TAPS-1 - i] = st0_data[L*TAPS + i];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin
                        st0_data0[L*TAPS-1 - i] = st0_data[L*TAPS + 1 + i];
                    end
                end
            end
            if ( st0_col_last[L] ) begin
                for ( int i = 0; i < R*TAPS; i++ ) begin
                    automatic int j;
                    st0_data0[(L+BUFS)*TAPS + i] = 'x;
                    if ( string'(BORDER_MODE) == "CONSTANT" ) begin
                        st0_data0[(L+BUFS)*TAPS + i] = BORDER_VALUE;
                    end
                    else if ( string'(BORDER_MODE) == "REPLICATE" ) begin
                        st0_data0[(L+BUFS)*TAPS + i] = st0_data[(L+BUFS)*TAPS-1];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT" ) begin
                        st0_data0[(L+BUFS)*TAPS + i] = st0_data[(L+BUFS)*TAPS-1 - i];
                    end
                    else if ( string'(BORDER_MODE) == "REFLECT_101" ) begin
                        st0_data0[(L+BUFS)*TAPS + i] = st0_data[(L+BUFS)*TAPS-2 - i];
                    end
                end
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
            else begin
                st1_row_first <= st0_row_first[L];
                st1_row_last  <= st0_row_last [L];
                st1_col_first <= st0_col_first[L];
                st1_col_last  <= st0_col_last [L];
                st1_de        <= st0_de       [L];
                st1_user      <= st0_user     [L];
                st1_valid     <= st0_valid    [L];

                for ( int i = 0; i < TAPS; i++ ) begin
                    for ( int j = 0; j < COLS; j++ ) begin
                        st1_data[i][j] = st0_data0[L*TAPS + i + j - A];
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
        if ( ENDIAN ) begin : m_data_big
            for ( genvar i = 0; i < TAPS; i++ ) begin : m_data_loop1
                for ( genvar j = 0; j < COLS; j++ ) begin : m_data_loop2
                    assign m_img_data[i][j] = st1_data[i][COLS - 1 - j];
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
