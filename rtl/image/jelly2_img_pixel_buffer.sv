// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_img_pixel_buffer
        #(
            parameter   int                         M            = 3,
            parameter   int                         USER_WIDTH   = 0,
            parameter   int                         DATA_WIDTH   = 3*8,
            parameter   int                         CENTER       = (M-1) / 2,
            parameter                               BORDER_MODE  = "REPLICATE",         // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}},  // BORDER_MODE == "CONSTANT"
            parameter   bit                         ENDIAN       = 0,                   // 0: little, 1:big
            
            localparam  int                         USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire                                s_img_row_first,
            input   wire                                s_img_row_last,
            input   wire                                s_img_col_first,
            input   wire                                s_img_col_last,
            input   wire                                s_img_de,
            input   wire    [USER_BITS-1:0]             s_img_user,
            input   wire    [DATA_WIDTH-1:0]            s_img_data,
            input   wire                                s_img_valid,
            
            output  wire                                m_img_row_first,
            output  wire                                m_img_row_last,
            output  wire                                m_img_col_first,
            output  wire                                m_img_col_last,
            output  wire                                m_img_de,
            output  wire    [USER_BITS-1:0]             m_img_user,
            output  wire    [M-1:0][DATA_WIDTH-1:0]     m_img_data,
            output  wire                                m_img_valid
        );
    
    localparam  C      = ENDIAN ? CENTER : M-1 - CENTER;
    localparam  REFLECT_NUM = (C > 0 ? C+1 : 1) + 1;
        
    wire    in_img_row_first = s_img_valid & s_img_row_first;
    wire    in_img_row_last  = s_img_valid & s_img_row_last;
    wire    in_img_col_first = s_img_valid & s_img_col_first;
    wire    in_img_col_last  = s_img_valid & s_img_col_last;
    wire    in_img_de        = s_img_valid & s_img_de;
    
    generate
    if ( M > 1 ) begin : blk_border
        logic   [C-1:0]                             st0_buf_row_first;
        logic   [C-1:0]                             st0_buf_row_last;
        logic   [C-1:0]                             st0_buf_col_first;
        logic   [C-1:0]                             st0_buf_col_last;
        logic   [C-1:0]                             st0_buf_de;
        logic   [C-1:0][USER_BITS-1:0]              st0_buf_user;
        logic   [(M-1)-1:0][DATA_WIDTH-1:0]         st0_buf_data;
        logic   [C-1:0]                             st0_buf_valid;

        wire    [C:0]                               st0_row_first  = {st0_buf_row_first,  in_img_row_first};
        wire    [C:0]                               st0_row_last   = {st0_buf_row_last,   in_img_row_last};
        wire    [C:0]                               st0_col_first  = {st0_buf_col_first,  in_img_col_first};
        wire    [C:0]                               st0_col_last   = {st0_buf_col_last,   in_img_col_last};
        wire    [C:0]                               st0_de         = {st0_buf_de,         in_img_de};
        wire    [C:0][USER_BITS-1:0]                st0_user       = {st0_buf_user,       s_img_user};
        wire    [M-1:0][DATA_WIDTH-1:0]             st0_data       = {st0_buf_data,       s_img_data};
        wire    [C:0]                               st0_valid      = {st0_buf_valid,      s_img_valid};
        
        logic   [REFLECT_NUM-1:0][DATA_WIDTH-1:0]   st0_reflect;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_buf_row_first  <= '0;
                st0_buf_row_last   <= '0;
                st0_buf_col_first  <= '0;
                st0_buf_col_last   <= '0;
                st0_buf_de         <= '0;
                st0_buf_user       <= 'x;
                st0_buf_data       <= 'x;
                st0_buf_valid      <= '0;
            end
            else if ( cke ) begin
                st0_buf_row_first[0] <= s_img_valid & s_img_row_first;
                st0_buf_row_last [0] <= s_img_valid & s_img_row_last;
                st0_buf_col_first[0] <= s_img_valid & s_img_col_first;
                st0_buf_col_last [0] <= s_img_valid & s_img_col_last;
                st0_buf_de       [0] <= s_img_valid & s_img_de;
                st0_buf_user     [0] <= s_img_user;
                st0_buf_data     [0] <= s_img_data;
                st0_buf_valid    [0] <= s_img_valid;
                for ( int i = 1; i <= C; ++i ) begin
                    st0_buf_row_first[i] <= st0_buf_row_first[i-1];
                    st0_buf_row_last [i] <= st0_buf_row_last [i-1];
                    st0_buf_col_first[i] <= st0_buf_col_first[i-1];
                    st0_buf_col_last [i] <= st0_buf_col_last [i-1];
                    st0_buf_de       [i] <= st0_buf_de       [i-1];
                    st0_buf_user     [i] <= st0_buf_user     [i-1];
                    st0_buf_data     [i] <= st0_buf_data     [i-1];
                    st0_buf_valid    [i] <= st0_buf_valid    [i-1];
                end

                st0_reflect <= (st0_reflect >> DATA_WIDTH);
                if ( st0_col_last[0] ) begin
                    st0_reflect <= st0_data[REFLECT_NUM-1:0];
                end
            end
        end
        
        
        logic                               st1_row_first;
        logic                               st1_row_last;
        logic                               st1_col_first;
        logic                               st1_col_last;
        logic                               st1_de;
        logic   [USER_BITS-1:0]             st1_user;
        logic   [M-1:0][DATA_WIDTH-1:0]     st1_data;
        logic                               st1_last_en;
        logic                               st1_valid;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st1_row_first  <= 1'b0;
                st1_row_last   <= 1'b0;
                st1_col_first  <= 1'b0;
                st1_col_last   <= 1'b0;
                st1_de         <= 1'b0;
                st1_user       <= {USER_BITS{1'bx}};
                st1_data       <= {(M*DATA_WIDTH){1'bx}};
                st1_last_en    <= 1'bx;
                st1_valid      <= 1'b0;
            end
            else if ( cke ) begin
                st1_row_first <= st0_row_first[C];
                st1_row_last  <= st0_row_last[C];
                st1_col_first <= st0_col_first[C];
                st1_col_last  <= st0_col_last[C];
                st1_de        <= st0_de[C];
                st1_user      <= st0_user[C];
                st1_valid     <= st0_valid[C];
                if ( st0_col_first[C] ) begin
                    st1_data  <= st0_data;
                end
                else begin
                    st1_data  <= (M*DATA_WIDTH)'({st1_data, st0_data[0]});
                end
                
                
                // left border
                if ( st0_col_first[C] ) begin
                    for ( int j = C+1; j < M; j=j+1 ) begin
                        if ( 256'(BORDER_MODE) == 256'("CONSTANT") ) begin
                            st1_data[j] <= BORDER_VALUE;
                        end
                        else if ( 256'(BORDER_MODE) == 256'("REPLICATE") ) begin
                            st1_data[j] <= st0_data[C];
                        end
                        else if ( 256'(BORDER_MODE) == 256'("REFLECT") ) begin
                            int k;
                            k = C + 1 - (j - C);
                            if ( k < 0 ) begin k = 0; end
                            st1_data[j] <= st0_data[k];
                        end
                        else if ( 256'(BORDER_MODE) == 256'("REFLECT_101") ) begin
                            int k;
                            k = C - (j - C);
                            if ( k < 0 ) begin k = 0; end
                            st1_data[j] <= st0_data[k];
                        end
                    end
                end
                
                
                // right border
                if ( st0_col_first[C] ) begin
                    st1_last_en <= 1'b0;
                end
                else if ( st0_col_last[0] ) begin
                    st1_last_en <= 1'b1;
                end
                
                if ( !st0_col_first[C] && st1_last_en ) begin
                    if ( 256'(BORDER_MODE) == 256'("CONSTANT") ) begin
                        st1_data[0] <= BORDER_VALUE;
                    end
                    else if ( 256'(BORDER_MODE) == 256'("REPLICATE") ) begin
                        st1_data[0] <= st1_data[0];
                    end
                    else if ( 256'(BORDER_MODE) == 256'("REFLECT") ) begin
                        st1_data[0] <= st0_reflect[0];
                    end
                    else if ( 256'(BORDER_MODE) == 256'("REFLECT_101") ) begin
                        st1_data[0] <= st0_reflect[1];
                    end
                end
            end
        end
        
        // ボーダー処理しない時は stage1 をスキップ
        logic                               out_row_first;
        logic                               out_row_last;
        logic                               out_col_first;
        logic                               out_col_last;
        logic                               out_de;
        logic   [USER_BITS-1:0]             out_user;
        logic   [M-1:0][DATA_WIDTH-1:0]     out_data;
        logic                               out_valid;
        
        if ( BORDER_MODE == "NONE" ) begin
            assign out_row_first  = st0_row_first[C];
            assign out_row_last   = st0_row_last[C];
            assign out_col_first  = st0_col_first[C];
            assign out_col_last   = st0_col_last[C];
            assign out_de         = st0_de[C];
            assign out_user       = st0_user[C];
            assign out_data       = st0_data;
            assign out_valid      = st0_valid[C];
        end
        else begin
            assign out_row_first = st1_row_first;
            assign out_row_last  = st1_row_last;
            assign out_col_first = st1_col_first;
            assign out_col_last  = st1_col_last;
            assign out_de        = st1_de;
            assign out_user      = st1_user;
            assign out_data      = st1_data;
            assign out_valid     = st1_valid;
        end
        
        
        assign m_img_row_first = out_row_first;
        assign m_img_row_last  = out_row_last;
        assign m_img_col_first = out_col_first;
        assign m_img_col_last  = out_col_last;
        assign m_img_de        = out_de;
        assign m_img_user      = out_user;
        assign m_img_valid     = out_valid;
        for ( genvar i = 0; i < M; i = i+1 ) begin :loop_endian
            if ( ENDIAN ) begin
                assign m_img_data[i] = out_data[i];
            end
            else begin
                assign m_img_data[i] = out_data[M-1-i];
            end
        end
    end
    else begin : blk_bypass
        // M == 1 の時はバイパスする
        assign m_img_row_first = s_img_row_first;
        assign m_img_row_last  = s_img_row_last;
        assign m_img_col_first = s_img_col_first;
        assign m_img_col_last  = s_img_col_last;
        assign m_img_de        = s_img_de;
        assign m_img_user      = s_img_user;
        assign m_img_data      = s_img_data;
        assign m_img_valid     = s_img_valid;
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
