
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_sum_tree
        #(
            parameter   int     N            = 16                                       ,
            parameter   int     UNIT         = 2                                        ,
            parameter   int     USER_BITS    = 1                                        ,
            parameter   type    user_t       = logic [USER_BITS-1:0]                    ,
            parameter   int     S_DATA_BITS  = 8                                        ,
            parameter   type    s_data_t     = logic [S_DATA_BITS-1:0]                  ,
            parameter   int     M_DATA_BITS  = $bits(s_data_t) + $clog2(N)              ,
            parameter   type    m_data_t     = logic [M_DATA_BITS-1:0]                  ,
            parameter   int     LATENCY      = ($clog2(N)+$clog2(UNIT)-1)/$clog2(UNIT)  
        )
        (
            input   var logic               reset   ,
            input   var logic               clk     ,
            input   var logic               cke     ,

            input   var logic       [N-1:0] s_en    ,
            input   var s_data_t    [N-1:0] s_data  ,
            input   var user_t              s_user  ,
            input   var logic               s_valid ,

            output  var m_data_t            m_data  ,
            output  var user_t              m_user  ,
            output  var logic               m_valid 
        );
    
    localparam  int     M = (N + UNIT) / UNIT;

    // input data cast
    m_data_t    [M*UNIT-1:0]   in_data  ;
    always_comb begin
        in_data = '0;
        for ( int i = 0; i < N; i++ ) begin
            in_data[i] = s_en[i] ? m_data_t'(s_data[i]) : '0;
        end
    end

    // all sum
    function    m_data_t    sum(input   m_data_t    [M*UNIT-1:0]   data);
        sum = '0;
        for ( int i = 0; i < N; i++ ) begin
            sum += data[i];
        end
    endfunction

    generate
    if ( LATENCY > 0 ) begin : pipeline
        m_data_t    [LATENCY-1:0][M*UNIT-1:0]   stage_data , next_data  ;
        user_t      [LATENCY-1:0]               stage_user , next_user  ;
        logic       [LATENCY-1:0]               stage_valid, next_valid ;

        always_comb begin
            // stage 0
            next_data[0] = '0;
            for ( int j = 0; j < M; j++ ) begin
                for ( int k = 0; k < UNIT; k++ ) begin
                    if ( j*UNIT+k < N ) begin
                        next_data[0][j] += in_data[j*UNIT+k];
                    end
                end
            end
            next_user [0] = s_user;
            next_valid[0] = s_valid;

            // other stage
            for ( int i = 1; i < LATENCY; i++ ) begin
                next_data[i] = '0;
                for ( int j = 0; j < M; j++ ) begin
                    for ( int k = 0; k < UNIT; k++ ) begin
                        next_data[i][j] += stage_data[i-1][j*UNIT+k];
                    end
                end
                next_user [i] = stage_user [i-1];
                next_valid[i] = stage_valid[i-1];
            end

            // final stage
            next_data[LATENCY-1][0] = sum(next_data[LATENCY-1]);
        end


        always_ff @(posedge clk) begin
            if ( reset ) begin
                stage_data  <= 'x;
                stage_user  <= 'x;
                stage_valid <= '0;
            end
            else if ( cke ) begin
                stage_data  <= next_data ;
                stage_user  <= next_user ;
                stage_valid <= next_valid;
            end
        end

        assign m_data  = stage_data [LATENCY-1][0] ;
        assign m_user  = stage_user [LATENCY-1]    ;
        assign m_valid = stage_valid[LATENCY-1]    ;
    end
    else begin : bypass
        assign m_data  = sum(in_data);
        assign m_user  = s_user;
        assign m_valid = s_valid;
    end
    endgenerate

endmodule


`default_nettype wire


// end of file
