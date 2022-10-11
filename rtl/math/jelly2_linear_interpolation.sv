// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   math
//
//                                 Copyright (C) 2008-2018 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_linear_interpolation
        #(
            parameter   int     USER_WIDTH    = 0,
            parameter   int     COMPONENT_NUM = 1,
            parameter   int     RATE_WIDTH    = 8,
            parameter   int     RATE_Q        = RATE_WIDTH,
            parameter   int     S_DATA_WIDTH  = 8,
            parameter   int     S_DATA_Q      = 0,
            parameter   bit     S_DATA_SIGNED = 1,
            parameter   int     M_DATA_WIDTH  = S_DATA_WIDTH,
            parameter   int     M_DATA_Q      = S_DATA_Q,
            parameter   bit     RATE_SIGNED   = 0,
            parameter   bit     DATA_SIGNED   = 0,
            parameter   bit     ROUNDING      = 0,
            
            localparam  int     USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                            reset,
            input   wire                                            clk,
            input   wire                                            cke,
            
            input   wire    [USER_BITS-1:0]                         s_user,
            input   wire    [RATE_WIDTH-1:0]                        s_rate,
            input   wire    [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data0,
            input   wire    [COMPONENT_NUM-1:0][S_DATA_WIDTH-1:0]   s_data1,
            input   wire                                            s_valid,
            
            output  reg     [USER_BITS-1:0]                         m_user,
            output  reg     [COMPONENT_NUM-1:0][M_DATA_WIDTH-1:0]   m_data,
            output  reg                                             m_valid
        );

    localparam  int     Q_WIDTH   = RATE_Q + 1 > RATE_WIDTH ? RATE_Q + 1 : RATE_WIDTH;
    localparam  int     RATE_BITS = RATE_SIGNED ? Q_WIDTH      : Q_WIDTH      + 1;
    localparam  int     DATA_BITS = DATA_SIGNED ? S_DATA_WIDTH : S_DATA_WIDTH + 1;
    localparam  int     MUL_BITS  = RATE_BITS + DATA_BITS;

    logic   signed  [RATE_BITS-1:0] rate_one        = RATE_BITS'(1 << RATE_Q);
    logic   signed  [MUL_BITS-1:0]  rounding_offset = ROUNDING ? MUL_BITS'((1 << (RATE_Q - S_DATA_Q)) >> 1) : '0;

    // input
    logic   signed  [RATE_BITS-1:0]                     in_rate;
    logic   signed  [COMPONENT_NUM-1:0][DATA_BITS-1:0]  in_data0;
    logic   signed  [COMPONENT_NUM-1:0][DATA_BITS-1:0]  in_data1;
    always_comb begin
        in_rate = RATE_SIGNED ? RATE_BITS'($signed(s_rate)) : RATE_BITS'($signed({1'b0, s_rate}));
        for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
            in_data0[i] = DATA_SIGNED ? DATA_BITS'($signed(s_data0[i])) : DATA_BITS'($signed({1'b0, s_data0[i]}));
            in_data1[i] = DATA_SIGNED ? DATA_BITS'($signed(s_data1[i])) : DATA_BITS'($signed({1'b0, s_data1[i]}));
        end
    end

    logic           [USER_BITS-1:0]                     st0_user;
    logic   signed  [RATE_BITS-1:0]                     st0_rate0;
    logic   signed  [RATE_BITS-1:0]                     st0_rate1;
    logic   signed  [COMPONENT_NUM-1:0][DATA_BITS-1:0]  st0_data0;
    logic   signed  [COMPONENT_NUM-1:0][DATA_BITS-1:0]  st0_data1;
    logic                                               st0_valid;
        
    logic           [USER_BITS-1:0]                     st1_user;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st1_data0;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st1_data1;
    logic                                               st1_valid;

    logic           [USER_BITS-1:0]                     st2_user;
    logic   signed  [COMPONENT_NUM-1:0][MUL_BITS-1:0]   st2_data;
    logic                                               st2_valid;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            // stage0
            st0_user  <= s_user;
            st0_rate0 <= rate_one - in_rate;
            st0_rate1 <= in_rate;
            st0_data0 <= in_data0;
            st0_data1 <= in_data1;

            // stage1
            st1_user  <= s_user;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st1_data0[i] <= $signed(st0_data0[i]) * st0_rate0;
                st1_data1[i] <= $signed(st0_data1[i]) * st0_rate1;
            end

            // stage2
            st2_user  <= st1_user;
            for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
                st2_data[i] <= $signed(st1_data0[i]) + $signed(st1_data1[i]) + rounding_offset;
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_valid <= 1'b0;
            st1_valid <= 1'b0;
            st2_valid <= 1'b0;
        end
        else if ( cke ) begin
            st0_valid <= s_valid;
            st1_valid <= st0_valid;
            st2_valid <= st1_valid;
        end
    end

    always_comb begin
        m_user  = st2_user;
        for ( int i = 0; i < COMPONENT_NUM; ++i ) begin
            m_data[i] = M_DATA_WIDTH'(st2_data[i] >> (RATE_Q - M_DATA_Q));
        end
        m_valid = st2_valid;
    end

endmodule


`default_nettype wire


// end of file
