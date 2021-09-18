// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


//   フレーム期間中のデータ入力の無い期間は cke を落とすことを
// 前提としてデータ稠密で、メモリを READ_FIRST モードで最適化
//   フレーム末尾で吐き出しのためにブランクデータを入れる際は
// line_first と line_last は正しく制御が必要

module jelly2_img_line_buffer
        #(
            parameter   int                         USER_WIDTH   = 0,
            parameter   int                         DATA_WIDTH   = 8,
            parameter   int                         N            = 3,
            parameter   int                         CENTER       = (N-1) / 2,
            parameter   int                         MAX_COLS     = 1024,
            parameter   string                      BORDER_MODE  = "REPLICATE",         // NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
            parameter   logic   [DATA_WIDTH-1:0]    BORDER_VALUE = {DATA_WIDTH{1'b0}},  // BORDER_MODE == "CONSTANT"
            parameter                               RAM_TYPE     = "block",
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
            output  wire    [N-1:0][DATA_WIDTH-1:0]     m_img_data,
            output  wire                                m_img_valid
        );
    
    localparam  int     C              = ENDIAN ? CENTER : N-1 - CENTER;
    localparam  int     MEM_ADDR_WIDTH = $clog2(MAX_COLS);
    localparam  int     MEM_DATA_WIDTH = USER_WIDTH+DATA_WIDTH;
    localparam  int     MEM_NUM        = N - 1;
    localparam  int     LINE_SEL_WIDTH = $clog2(MEM_NUM);
    localparam  int     POS_WIDTH      = $clog2(MEM_NUM+1);
    
    generate
    if ( N > 1 ) begin : blk_buffer
        // memory
        logic   [MEM_NUM-1:0]                   mem_we;
        logic   [MEM_ADDR_WIDTH-1:0]            mem_addr;
        logic   [USER_BITS-1:0]                 mem_wuser;
        logic   [DATA_WIDTH-1:0]                mem_wdata;
        logic                                   mem_wfirst;
        logic                                   mem_wlast;
        logic   [MEM_NUM-1:0][USER_BITS-1:0]    mem_ruser;
        logic   [MEM_NUM-1:0][DATA_WIDTH-1:0]   mem_rdata;
        
        for ( genvar i = 0; i < MEM_NUM; i = i+1 ) begin : mem_loop
            
            // USER_WIDTHが0の時の為にキャスト
            logic   [MEM_DATA_WIDTH-1:0]        wdata;
            logic   [MEM_DATA_WIDTH-1:0]        rdata;
            assign wdata = MEM_DATA_WIDTH'({mem_wuser, mem_wdata});
            assign {mem_ruser[i], mem_rdata[i]} = (USER_BITS+DATA_WIDTH)'(rdata);
            
            jelly2_ram_singleport
                    #(
                        .ADDR_WIDTH     (MEM_ADDR_WIDTH),
                        .DATA_WIDTH     (MEM_DATA_WIDTH),
                        .MEM_SIZE       (MAX_COLS),
                        .RAM_TYPE       (RAM_TYPE),
                        .DOUT_REGS      (1),
                        .MODE           ("READ_FIRST")  // <- important!
                    )
                i_ram_singleport
                    (
                        .clk            (clk),
                        .en             (cke),
                        .regcke         (cke),
                        .we             (mem_we[i]),
                        .addr           (mem_addr),
                        .din            (wdata),
                        .dout           (rdata)
                    );
            
        end
        
        
        // control
        logic   [MEM_NUM-1:0]               st0_we;
        logic   [MEM_ADDR_WIDTH-1:0]        st0_addr;
        logic                               st0_row_first;
        logic                               st0_row_last;
        logic                               st0_col_first;
        logic                               st0_col_last;
        logic                               st0_de;
        logic   [USER_BITS-1:0]             st0_user;
        logic   [DATA_WIDTH-1:0]            st0_data;
        logic                               st0_valid;
        
        logic                               st1_row_first;
        logic                               st1_row_last;
        logic                               st1_col_first;
        logic                               st1_col_last;
        logic                               st1_de;
        logic   [USER_BITS-1:0]             st1_user;
        logic   [DATA_WIDTH-1:0]            st1_data;
        logic                               st1_valid;
        
        logic   [LINE_SEL_WIDTH-1:0]        st2_sel;
        logic                               st2_row_first;
        logic                               st2_row_last;
        logic                               st2_col_first;
        logic                               st2_col_last;
        logic                               st2_de;
        logic   [USER_BITS-1:0]             st2_user;
        logic   [DATA_WIDTH-1:0]            st2_data;
        logic                               st2_valid;
        
        logic   [N-1:0]                     st3_row_first;
        logic   [N-1:0]                     st3_row_last;
        logic                               st3_col_first;
        logic                               st3_col_last;
        logic   [N-1:0]                     st3_de;
        logic   [N-1:0][USER_BITS-1:0]      st3_user;
        logic   [N-1:0][DATA_WIDTH-1:0]     st3_data;
        logic                               st3_valid;
        
        logic                               st4_row_first;
        logic                               st4_row_last;
        logic                               st4_col_first;
        logic                               st4_col_last;
        logic                               st4_de;
        logic   [USER_BITS-1:0]             st4_user;
        logic   [N-1:0][DATA_WIDTH-1:0]     st4_data;
        logic   [POS_WIDTH-1:0]             st4_pos_first;
        logic   [POS_WIDTH-1:0]             st4_pos_last;
        logic                               st4_valid;
        
        logic                               st5_row_first;
        logic                               st5_row_last;
        logic                               st5_col_first;
        logic                               st5_col_last;
        logic                               st5_de;
        logic   [USER_BITS-1:0]             st5_user;
        logic   [N-1:0][DATA_WIDTH-1:0]     st5_data;
        logic   [N-1:0][POS_WIDTH-1:0]      st5_pos_data;
        logic                               st5_valid;
        
        logic                               st6_row_first;
        logic                               st6_row_last;
        logic                               st6_col_first;
        logic                               st6_col_last;
        logic                               st6_de;
        logic   [USER_BITS-1:0]             st6_user;
        logic   [N-1:0][DATA_WIDTH-1:0]     st6_data;
        logic                               st6_valid;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                st0_we            <= {MEM_NUM{1'b0}};
                st0_we[MEM_NUM-1] <= 1'b1;
                st0_addr          <= {MEM_ADDR_WIDTH{1'b0}};
                st0_row_first     <= 1'b0;
                st0_row_last      <= 1'b0;
                st0_col_first     <= 1'b0;
                st0_col_last      <= 1'b0;
                st0_de            <= 1'b0;
                st0_user          <= {USER_BITS{1'bx}};
                st0_data          <= {DATA_WIDTH{1'bx}};
                st0_valid         <= 1'b0;
                
                st1_row_first     <= 1'b0;
                st1_row_last      <= 1'b0;
                st1_col_first     <= 1'b0;
                st1_col_last      <= 1'b0;
                st1_de            <= 1'b0;
                st1_user          <= {USER_BITS{1'bx}};
                st1_data          <= {DATA_WIDTH{1'bx}};
                st1_valid         <= 1'b0;
                
                st2_sel           <= {LINE_SEL_WIDTH{1'b0}};
                st2_row_first     <= 1'b0;
                st2_row_last      <= 1'b0;
                st2_col_first     <= 1'b0;
                st2_col_last      <= 1'b0;
                st2_de            <= 1'b0;
                st2_user          <= {USER_BITS{1'bx}};
                st2_data          <= {DATA_WIDTH{1'bx}};
                st2_valid         <= 1'b0;
                
                st3_row_first     <= {N{1'b0}};
                st3_row_last      <= {N{1'b0}};
                st3_col_first     <= 1'b0;
                st3_col_last      <= 1'b0;
                st3_de            <= {N{1'b0}};
                st3_user          <= {(N*USER_BITS){1'bx}};
                st3_data          <= {(N*DATA_WIDTH){1'bx}};
                st3_valid         <= 1'b0;
                
                st4_row_first     <= 1'b0;
                st4_row_last      <= 1'b0;
                st4_col_first     <= 1'b0;
                st4_col_last      <= 1'b0;
                st4_de            <= 1'b0;
                st4_user          <= {USER_BITS{1'bx}};
                st4_data          <= {(N*DATA_WIDTH){1'bx}};
                st4_pos_first     <= {POS_WIDTH{1'bx}};
                st4_pos_last      <= {POS_WIDTH{1'bx}};
                st4_valid         <= 1'b0;
                
                st5_row_first     <= 1'b0;
                st5_row_last      <= 1'b0;
                st5_col_first     <= 1'b0;
                st5_col_last      <= 1'b0;
                st5_de            <= 1'b0;
                st5_user          <= {USER_BITS{1'bx}};
                st5_data          <= {(N*DATA_WIDTH){1'bx}};
                st5_pos_data      <= {(N*POS_WIDTH){1'bx}};
                st5_valid         <= 1'b0;
                
                st6_row_first     <= 1'b0;
                st6_row_last      <= 1'b0;
                st6_col_first     <= 1'b0;
                st6_col_last      <= 1'b0;
                st6_de            <= 1'b0;
                st6_user          <= {USER_BITS{1'bx}};
                st6_data          <= {(N*DATA_WIDTH){1'bx}};
                st6_valid         <= 1'b0;
            end
            else if ( cke ) begin
                // stage 0
                if ( s_img_valid && s_img_col_first ) begin
                    st0_we   <= MEM_NUM'({2{st0_we}} >> 1);
                    st0_addr <= {MEM_ADDR_WIDTH{1'b0}};
                end
                else begin
                    st0_addr <= st0_addr + 1'b1;
                end
                
                st0_row_first <= s_img_row_first & s_img_valid;
                st0_row_last  <= s_img_row_last  & s_img_valid;
                st0_col_first <= s_img_col_first & s_img_valid;
                st0_col_last  <= s_img_col_last  & s_img_valid;
                st0_de        <= s_img_de        & s_img_valid;
                st0_user      <= s_img_user;
                st0_data      <= s_img_data;
                st0_valid     <= s_img_valid;
                

                // stage1
                st1_row_first <= st0_row_first;
                st1_row_last  <= st0_row_last;
                st1_col_first <= st0_col_first;
                st1_col_last  <= st0_col_last;
                st1_de        <= st0_de;
                st1_user      <= st0_user;
                st1_data      <= st0_data;
                st1_valid     <= st0_valid;
                

                // stage2
                if ( st1_valid && st1_col_first ) begin
                    st2_sel <= st2_sel - 1'b1;
                    if ( st2_sel == {LINE_SEL_WIDTH{1'b0}} ) begin
                        st2_sel <= LINE_SEL_WIDTH'(MEM_NUM-1);
                    end
                end
                st2_row_first <= st1_row_first;
                st2_row_last  <= st1_row_last;
                st2_col_first <= st1_col_first;
                st2_col_last  <= st1_col_last;
                st2_de        <= st1_de;
                st2_user      <= st1_user;
                st2_data      <= st1_data;
                st2_valid     <= st1_valid;
                

                // stage3
                st3_row_first[0] <= st2_row_first;
                st3_row_last [0] <= st2_row_last;
                st3_de       [0] <= st2_de;
                st3_user     [0] <= st2_user;
                st3_data     [0] <= st2_data;
                for ( int i = 1; i < N; ++i ) begin
                    if ( st2_valid && st2_col_first ) begin
                        st3_row_first[i] <= st3_row_first[i-1];
                        st3_row_last [i] <= st3_row_last [i-1];
                        st3_de       [i] <= st3_de       [i-1];
                    end
                    st3_user[i] <= mem_ruser[(i-1 + int'(st2_sel)) % MEM_NUM];
                    st3_data[i] <= mem_rdata[(i-1 + int'(st2_sel)) % MEM_NUM];
                end
                st3_col_first <= st2_col_first;
                st3_col_last  <= st2_col_last;
                st3_valid     <= st2_valid;
                

                // stage4
                st4_row_first  <= st3_row_first[C];
                st4_row_last   <= st3_row_last[C];
                st4_col_first <= st3_col_first;
                st4_col_last  <= st3_col_last;
                st4_de          <= st3_de[C];
                st4_user        <= st3_user[C*USER_BITS +: USER_BITS];
                st4_data        <= st3_data;
                st4_pos_first   <= POS_WIDTH'(N-1);
                st4_pos_last    <= POS_WIDTH'(0);
                st4_valid       <= st3_valid;
                
                begin : search_first
                    for ( int y = C; y < N; y = y+1 ) begin
                        if ( st3_row_first[y] ) begin
                            st4_pos_first <= POS_WIDTH'(y);
                            disable search_first;
                        end
                    end
                end
                
                begin : search_last
                    for ( int y = C; y >= 0; y = y-1 ) begin
                        if ( st3_row_last[y] ) begin
                            st4_pos_last <= POS_WIDTH'(y);
                            disable search_last;
                        end
                    end
                end
                
                
                // stage5
                st5_row_first  <= st4_row_first;
                st5_row_last   <= st4_row_last;
                st5_col_first <= st4_col_first;
                st5_col_last  <= st4_col_last;
                st5_de          <= st4_de;
                st5_user        <= st4_user;
                st5_data        <= st4_data;
                st5_valid       <= st4_valid;
                
                for ( int y = 0; y < N; y = y+1 ) begin
                    st5_pos_data[y] <= POS_WIDTH'(y);
                    if ( y > C ) begin
                        if ( y > st4_pos_first ) begin
                            if      ( BORDER_MODE == "CONSTANT"    ) begin st5_pos_data[y] <= POS_WIDTH'(N);                       end
                            else if ( BORDER_MODE == "REPLICATE"   ) begin st5_pos_data[y] <= st4_pos_first;                       end
                            else if ( BORDER_MODE == "REFLECT"     ) begin st5_pos_data[y] <= POS_WIDTH'(st4_pos_first*2 - y + 1); end
                            else if ( BORDER_MODE == "REFLECT_101" ) begin st5_pos_data[y] <= POS_WIDTH'(st4_pos_first*2 - y);     end
                        end
                    end
                    else if ( y < C ) begin
                        if ( y < st4_pos_last ) begin
                            if      ( BORDER_MODE == "CONSTANT"    ) begin st5_pos_data[y] <= POS_WIDTH'(N);                       end
                            else if ( BORDER_MODE == "REPLICATE"   ) begin st5_pos_data[y] <= st4_pos_last;                        end
                            else if ( BORDER_MODE == "REFLECT"     ) begin st5_pos_data[y] <= POS_WIDTH'(st4_pos_last*2 - y - 1);  end
                            else if ( BORDER_MODE == "REFLECT_101" ) begin st5_pos_data[y] <= POS_WIDTH'(st4_pos_last*2 - y);      end
                        end
                    end
                end
                

                // stage6
                st6_row_first <= st5_row_first;
                st6_row_last  <= st5_row_last;
                st6_col_first <= st5_col_first;
                st6_col_last  <= st5_col_last;
                st6_de        <= st5_de;
                st6_user      <= st5_user;
                st6_data      <= st5_data;
                for ( int y = 0; y < N; y = y+1 ) begin
                    st6_data[y] <= DATA_WIDTH'({BORDER_VALUE, st5_data} >> (DATA_WIDTH * st5_pos_data[y]));
                end
                st6_valid       <= st5_valid;
            end
        end
        
        assign mem_we     = st0_we;
        assign mem_addr   = st0_addr;
        assign mem_wuser  = st0_user;
        assign mem_wdata  = st0_data;
        assign mem_wfirst = st0_row_first;
        assign mem_wlast  = st0_row_last;
        
        
        wire                                out_row_first;
        wire                                out_row_last;
        wire                                out_col_first;
        wire                                out_col_last;
        wire                                out_de;
        wire    [USER_BITS-1:0]             out_user;
        wire    [N-1:0][DATA_WIDTH-1:0]     out_data;
        wire                                out_valid;
        
        if ( BORDER_MODE == "NONE" ) begin
            assign out_row_first  = st4_row_first;
            assign out_row_last   = st4_row_last;
            assign out_col_first = st4_col_first;
            assign out_col_last  = st4_col_last;
            assign out_de          = st4_de;
            assign out_user        = st4_user;
            assign out_data        = st4_data;
            assign out_valid       = st4_valid;
        end
        else begin
            assign out_row_first  = st6_row_first;
            assign out_row_last   = st6_row_last;
            assign out_col_first = st6_col_first;
            assign out_col_last  = st6_col_last;
            assign out_de          = st6_de;
            assign out_user        = st6_user;
            assign out_data        = st6_data;
            assign out_valid       = st6_valid;
        end
        
        assign m_img_row_first  = out_row_first;
        assign m_img_row_last   = out_row_last;
        assign m_img_col_first = out_col_first;
        assign m_img_col_last  = out_col_last;
        assign m_img_de          = out_de;
        assign m_img_user        = out_user;
        for ( genvar i = 0; i < N; i = i+1 ) begin :loop_endian
            if ( ENDIAN ) begin
                assign m_img_data[i] = out_data[i];
            end
            else begin
                assign m_img_data[i] = out_data[N-1-i];
            end
        end
        assign m_img_valid       = out_valid;
    end
    else begin : blk_bypass
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
