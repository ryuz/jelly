
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_max_tree
        #(
            parameter   int     N            = 16                                       ,
            parameter   int     UNIT         = 2                                        ,
            parameter   int     USER_BITS    = 1                                        ,
            parameter   type    user_t       = logic [USER_BITS-1:0]                    ,
            parameter   int     DATA_BITS    = 8                                        ,
            parameter   type    data_t       = logic [DATA_BITS-1:0]                    ,
            parameter   bit     IS_SIGNED    = (data_t'(-1) < 0)                        ,
            parameter   int     LATENCY      = ($clog2(N)+$clog2(UNIT)-1)/$clog2(UNIT)  
        )
        (
            input   var logic               reset   ,
            input   var logic               clk     ,
            input   var logic               cke     ,

            input   var logic       [N-1:0] s_en    ,
            input   var data_t      [N-1:0] s_data  ,
            input   var user_t              s_user  ,
            input   var logic               s_valid ,

            output  var data_t              m_data  ,
            output  var user_t              m_user  ,
            output  var logic               m_valid 
        );

    localparam  data_t  MIN_VALUE = IS_SIGNED ? (data_t'(1) << ($bits(data_t) - 1)) : data_t'(0);

    localparam  int     M = (N + UNIT - 1) / UNIT;

    // max with explicit signedness control
    function    automatic   data_t  max(input data_t v0, input data_t v1);
        if ( IS_SIGNED ) begin
            return $signed(v0) > $signed(v1) ? v0 : v1;
        end else begin
            return $unsigned(v0) > $unsigned(v1) ? v0 : v1;
        end
    endfunction

    // max all 
    function    automatic   data_t  max_all(input   data_t    [M*UNIT-1:0]   data);
        data_t max_val = MIN_VALUE;
        for ( int i = 0; i < N; i++ ) begin
            max_val = max(data[i], max_val);
        end
        return max_val;
    endfunction

    // input data cast
    data_t    [M*UNIT-1:0]   in_data  ;
    always_comb begin
        for ( int i = 0; i < M*UNIT; i++ ) begin
            in_data[i] = MIN_VALUE;
        end
        for ( int i = 0; i < N; i++ ) begin
            in_data[i] = s_en[i] ? data_t'(s_data[i]) : MIN_VALUE;
        end
    end

    generate
    if ( LATENCY > 0 ) begin : pipeline
        data_t      [LATENCY-1:0][M*UNIT-1:0]   stage_data , next_data  ;
        user_t      [LATENCY-1:0]               stage_user , next_user  ;
        logic       [LATENCY-1:0]               stage_valid, next_valid ;

        always_comb begin
            // 初期化
            for ( int i = 0; i < LATENCY; i++ ) begin
                for ( int j = 0; j < M*UNIT; j++ ) begin
                    next_data[i][j] = MIN_VALUE;
                end
            end

            // stage 0
            for ( int j = 0; j < M; j++ ) begin
                next_data[0][j] = MIN_VALUE;
                for ( int k = 0; k < UNIT; k++ ) begin
                    if ( j*UNIT+k < N ) begin
                        next_data[0][j] = max(in_data[j*UNIT+k], next_data[0][j]);
                    end
                end
            end
            next_user [0] = s_user;
            next_valid[0] = s_valid;

            // other stage
            for ( int i = 1; i < LATENCY; i++ ) begin
                for ( int j = 0; j < M; j++ ) begin
                    next_data[i][j] = MIN_VALUE;
                    for ( int k = 0; k < UNIT; k++ ) begin
                        next_data[i][j] = max(stage_data[i-1][j*UNIT+k], next_data[i][j]);
                    end
                end
                next_user [i] = stage_user [i-1];
                next_valid[i] = stage_valid[i-1];
            end

            // final stage
            next_data[LATENCY-1][0] = max_all(next_data[LATENCY-1]);
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
        assign m_data  = max_all(in_data);
        assign m_user  = s_user;
        assign m_valid = s_valid;
    end
    endgenerate

endmodule


`default_nettype wire


// end of file
