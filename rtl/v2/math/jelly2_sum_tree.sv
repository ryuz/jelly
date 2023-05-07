
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_sum_tree
        #(
            parameter   int     N            = 16,
            parameter   int     USER_WIDTH   = 0,
            parameter   int     S_DATA_WIDTH = 8,
            parameter   int     M_DATA_WIDTH = S_DATA_WIDTH + $clog2(N),
            parameter   bit     SIGNED       = 0,
            parameter   int     LATENCY      = $clog2(N),

            localparam  int     USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,

            input   wire    [USER_BITS-1:0]             s_user,
            input   wire    [N-1:0][S_DATA_WIDTH-1:0]   s_data,
            input   wire                                s_valid,

            output  reg     [USER_BITS-1:0]             m_user,
            output  reg     [M_DATA_WIDTH-1:0]          m_data,
            output  reg                                 m_valid
        );
    
    localparam  int     CALC_WIDTH = SIGNED ? M_DATA_WIDTH : M_DATA_WIDTH + 1;
    localparam  int     M          = (N + 1) / 2;

    logic   signed  [2*M-1:0][CALC_WIDTH-1:0] in_data;
    always_comb begin
        in_data = '0;
        for ( int i = 0; i < N; ++i ) begin
            in_data[i] = SIGNED ? CALC_WIDTH'($signed(s_data[i])) : CALC_WIDTH'($signed({1'b0, s_data[i]}));
        end
    end

    function    signed  [CALC_WIDTH-1:0]    sum(input   signed    [2*M-1:0][CALC_WIDTH-1:0] data);
        sum = '0;
        for ( int i = 0; i < N; ++i ) begin
            sum += data[i];
        end
    endfunction

    generate
    if ( LATENCY > 0 ) begin : array
        logic           [LATENCY-1:0]         [USER_BITS-1:0]   array_user;
        logic   signed  [LATENCY-1:0][2*M-1:0][CALC_WIDTH-1:0]  array_data;
        logic           [LATENCY-1:0]                           array_valid;

        always_ff @(posedge clk) begin
            if ( reset ) begin
                array_user  <= 'x;
                array_data  <= 'x;
                array_valid <= '0;
            end
            else if ( cke ) begin
                for ( int i = 0; i < LATENCY; ++i ) begin
                    array_data [i] <= '0;
                    if ( i == 0 ) begin
                        array_user [i] <= s_user;
                        array_valid[i] <= s_valid;
                        for ( int j = 0; j < M; ++j ) begin
                            // 1st stage
                            array_data[i][j] <= in_data[2*j] + in_data[2*j+1];
                        end
                    end
                    else begin
                        array_user [i] <= array_user [i-1];
                        array_valid[i] <= array_valid[i-1];
                        if ( i == LATENCY-1 ) begin
                            // final stage
                            array_data[i][0] <= sum(array_data[i-1]);
                        end
                        else begin
                            for ( int j = 0; j < M; ++j ) begin
                                // other stage
                                array_data[i][j] <= array_data[i-1][2*j] + array_data[i-1][2*j+1];
                            end
                        end
                    end
                end
            end
        end

        always_comb begin
            m_data  = M_DATA_WIDTH'(array_data[LATENCY-1][0]);
            m_user  = array_user[LATENCY-1];
            m_valid = array_valid[LATENCY-1];
        end
    end
    else begin : blk_bypass
        always_comb begin
            m_data  = M_DATA_WIDTH'(sum(in_data));
            m_user  = s_user;
            m_valid = s_valid;
        end
    end
    endgenerate

endmodule


`default_nettype wire


// end of file
