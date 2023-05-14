// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// v = i00*(1-s)*(1-t) + i01*s*(1-t) + i10*(1-s)*t + i11*s*t
//   = i00 + (-i00+i01 + (+i00 -i01 -i10 +i11)*t)*s + (-i00 +i10)*t

module jelly2_bilinear_interpolation
        #(
            parameter   int     USER_WIDTH    = 0,
            parameter   int     COMPONENT_NUM = 1,
            parameter   int     RATE_WIDTH    = 8,
            parameter   int     RATE_Q        = RATE_WIDTH,
            parameter   int     S_DATA_WIDTH  = 16,
            parameter   int     S_DATA_Q      = 0,
            parameter   bit     S_DATA_SIGNED = 1,
            parameter   int     M_DATA_WIDTH  = S_DATA_WIDTH,
            parameter   int     M_DATA_Q      = S_DATA_Q,
            parameter   bit     RATE_SIGNED   = 1,
            parameter   bit     DATA_SIGNED   = 1,
            parameter   bit     ROUNDING      = 0,
            
            localparam  int     USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                            reset,
            input   wire                                            clk,
            input   wire                                            cke,
            
            input   wire    [USER_BITS-1:0]                         s_user,
            input   wire    [RATE_WIDTH-1:0]                        s_rate_x,
            input   wire    [RATE_WIDTH-1:0]                        s_rate_y,
            input   wire    [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data00,
            input   wire    [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data01,
            input   wire    [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data10,
            input   wire    [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data11,
            input   wire                                            s_valid,
            
            output  reg     [USER_BITS-1:0]                         m_user,
            output  reg     [COMPONENT_NUM-1:0][M_DATA_WIDTH-1:0]   m_data,
            output  reg                                             m_valid
        );

    localparam  int     Q_WIDTH   = RATE_Q + 1 > RATE_WIDTH ? RATE_Q + 1 : RATE_WIDTH;
    localparam  int     RATE_BITS = RATE_SIGNED ? Q_WIDTH      : Q_WIDTH      + 1;
    localparam  int     DATA_BITS = DATA_SIGNED ? S_DATA_WIDTH : S_DATA_WIDTH + 1;
    localparam  int     MUL_BITS  = 2 + RATE_BITS + RATE_BITS + DATA_BITS;

//    logic   signed  [RATE_BITS-1:0] rate_one        = RATE_BITS'(1 << RATE_Q);
    logic   signed  [MUL_BITS-1:0]  rounding_offset = ROUNDING ? MUL_BITS'((1 << (RATE_Q - S_DATA_Q)) >> 1) : '0;

    // input
    logic   signed  [RATE_BITS-1:0]                     in_rate_x;
    logic   signed  [RATE_BITS-1:0]                     in_rate_y;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   in_data00;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   in_data01;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   in_data10;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   in_data11;
    always_comb begin
        in_rate_x = RATE_SIGNED ? RATE_BITS'($signed(s_rate_x)) : RATE_BITS'($signed({1'b0, s_rate_x}));
        in_rate_y = RATE_SIGNED ? RATE_BITS'($signed(s_rate_y)) : RATE_BITS'($signed({1'b0, s_rate_y}));
        for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
            in_data00[i] = (DATA_SIGNED ? MUL_BITS'($signed(s_data00[i])) : MUL_BITS'($signed({1'b0, s_data00[i]}))) << RATE_Q;
            in_data01[i] = (DATA_SIGNED ? MUL_BITS'($signed(s_data01[i])) : MUL_BITS'($signed({1'b0, s_data01[i]}))) << RATE_Q;
            in_data10[i] = (DATA_SIGNED ? MUL_BITS'($signed(s_data10[i])) : MUL_BITS'($signed({1'b0, s_data10[i]}))) << RATE_Q;
            in_data11[i] = (DATA_SIGNED ? MUL_BITS'($signed(s_data11[i])) : MUL_BITS'($signed({1'b0, s_data11[i]}))) << RATE_Q;
        end
    end

    logic           [USER_BITS-1:0]                     st0_user;
    logic   signed  [RATE_BITS-1:0]                     st0_rate_x;
    logic   signed  [RATE_BITS-1:0]                     st0_rate_y;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st0_data0;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st0_data1;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st0_data2;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st0_data3;
    logic                                               st0_valid;
        
    logic           [USER_BITS-1:0]                     st1_user;
    logic   signed  [RATE_BITS-1:0]                     st1_rate_x;
    logic   signed  [RATE_BITS-1:0]                     st1_rate_y;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st1_data0;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st1_data1;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st1_data2;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st1_data3;
    logic                                               st1_valid;

    logic           [USER_BITS-1:0]                     st2_user;
    logic   signed  [RATE_BITS-1:0]                     st2_rate_x;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st2_data0;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st2_data1;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st2_data2;
    logic                                               st2_valid;

    logic           [USER_BITS-1:0]                     st3_user;
    logic   signed  [RATE_BITS-1:0]                     st3_rate_x;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st3_data0;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st3_data1;
    logic                                               st3_valid;

    logic           [USER_BITS-1:0]                     st4_user;
    logic   signed  [RATE_BITS-1:0]                     st4_rate_x;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st4_data0;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st4_data1;
    logic                                               st4_valid;

    logic           [USER_BITS-1:0]                     st5_user;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st5_data;
    logic                                               st5_valid;

//     a*(s-1)*(t-1) + s*(b - t*(b+c-d)) + c*t

    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage0
            st0_user   <= s_user;
            st0_rate_x <= in_rate_x;
            st0_rate_y <= in_rate_y;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st0_data0[i]  <= $signed(in_data00[i]);
                st0_data1[i]  <= $signed(in_data01[i]) - $signed(in_data00[i]);
                st0_data2[i]  <= $signed(in_data10[i]) - $signed(in_data00[i]);
                st0_data3[i]  <= $signed(in_data11[i]) - $signed(in_data10[i]);
            end

            // stage1
            st1_user   <= st0_user;
            st1_rate_x <= st0_rate_x;
            st1_rate_y <= st0_rate_y;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st1_data0[i] <= $signed(st0_data0[i]);
                st1_data1[i] <= $signed(st0_data1[i]);
                st1_data2[i] <= $signed(st0_data3[i]) - $signed(st0_data1[i]);
                st1_data3[i] <= ($signed(st0_data2[i]) * st0_rate_y) >>> RATE_Q;
            end

            // stage2
            st2_user   <= st1_user;
            st2_rate_x <= st1_rate_x;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st2_data0[i] <= $signed(st1_data0[i]) + $signed(st1_data3[i]);
                st2_data1[i] <= $signed(st1_data1[i]);
                st2_data2[i] <= ($signed(st1_data2[i]) * st1_rate_y) >>> RATE_Q;
            end

            // stage3
            st3_user   <= st2_user;
            st3_rate_x <= st2_rate_x;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st3_data0[i] <= $signed(st2_data0[i]);
                st3_data1[i] <= $signed(st2_data1[i]) + $signed(st2_data2[i]);
            end

            // stage4
            st4_user   <= st3_user;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st4_data0[i] <= $signed(st3_data0[i]);
                st4_data1[i] <= ($signed(st3_data1[i]) * st3_rate_x) >>> RATE_Q;;
            end

            // stage5
            st5_user  <= st4_user;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st5_data[i] <= $signed(st4_data0[i]) + $signed(st4_data1[i]) + rounding_offset;
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_valid <= 1'b0;
            st1_valid <= 1'b0;
            st2_valid <= 1'b0;
            st3_valid <= 1'b0;
            st4_valid <= 1'b0;
            st5_valid <= 1'b0;
        end
        else if ( cke ) begin
            st0_valid <= s_valid;
            st1_valid <= st0_valid;
            st2_valid <= st1_valid;
            st3_valid <= st2_valid;
            st4_valid <= st3_valid;
            st5_valid <= st4_valid;
        end
    end
    
    always_comb begin
        m_user  = st5_user;
        for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
            m_data[i] = M_DATA_WIDTH'(st5_data[i] >>> (RATE_Q - M_DATA_Q));
        end
        m_valid = st5_valid;
    end

endmodule


`default_nettype wire


// end of file
