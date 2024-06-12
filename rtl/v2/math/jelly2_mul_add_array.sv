
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_mul_add_array
        #(
            parameter   int     N           = 8,
            parameter   int     MAC_WIDTH   = 48,
            parameter   int     COEFF_WIDTH = 18,
            parameter   int     DATA_WIDTH  = 18
        )
        (
            input   wire                                        reset,
            input   wire                                        clk,
            input   wire                                        cke,

            input   wire    signed  [N-1:0][COEFF_WIDTH-1:0]    param_coeff,

            input   wire    signed         [MAC_WIDTH-1:0]      s_add,
            input   wire    signed  [N-1:0][DATA_WIDTH-1:0]     s_data,
            input   wire                                        s_valid,

            output  wire    signed         [MAC_WIDTH-1:0]      m_data,
            output  wire                                        m_valid
        );
    
    logic   signed  [1:0][MAC_WIDTH-1:0]            stage_add;
    logic   signed  [N-1:0][N-1:0][DATA_WIDTH-1:0]  stage_data;
    logic   signed  [N+1:0]                         stage_valid;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            stage_add   <= 'x;
            stage_data  <= 'x;
            stage_valid <= '0;
        end
        else if ( cke ) begin
            stage_add[0] <= s_add;
            stage_add[1] <= stage_add[0];

            stage_data[0] <= s_data;
            for ( int i = 1; i < N; ++i ) begin
                stage_data[i] <= stage_data[i-1];
            end

            stage_valid <= {stage_valid[N:0], s_valid};
        end
    end


    logic   signed  [N-1:0][COEFF_WIDTH-1:0]    unit_mul0;
    logic   signed  [N-1:0][DATA_WIDTH-1:0]     unit_mul1;
    logic   signed  [N-1:0][MAC_WIDTH-1:0]      unit_add;
    logic   signed  [N-1:0][MAC_WIDTH-1:0]      unit_data;

    generate
    for ( genvar i = 0; i < N; ++i ) begin : loop_unit
        jelly2_mul_add_array_unit
                #(
                    .MUL0_WIDTH     (COEFF_WIDTH),
                    .MUL1_WIDTH     (DATA_WIDTH),
                    .MAC_WIDTH      (MAC_WIDTH)
                )
            i_mul_add_array_unit
                (
                    .reset,
                    .clk,
                    .cke,

                    .in_mul0        (unit_mul0[i]),
                    .in_mul1        (unit_mul1[i]),
                    .in_add         (unit_add[i]),

                    .out_data       (unit_data[i])
                );
    end
    endgenerate
    
    assign unit_mul0    = param_coeff;
    assign unit_mul1[0] = s_data[0];
    assign unit_add[0]  = stage_add[1];

    generate
    for ( genvar i = 1; i < N; ++i ) begin : loop_connect
        assign unit_mul1[i] = stage_data[i-1][i];
        assign unit_add[i]  = unit_data[i-1];
    end
    endgenerate

    assign m_data  = unit_data[N-1];
    assign m_valid = stage_valid[N+1];

endmodule


`default_nettype wire


// end of file
