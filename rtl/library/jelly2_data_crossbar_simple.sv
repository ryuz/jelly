// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_data_crossbar_simple
        #(
            parameter   int     S_NUM         = 4,
            parameter   int     S_ID_WIDTH    = 3,
            parameter   int     M_NUM         = 8,
            parameter   int     M_ID_WIDTH    = 3,
            parameter   int     DATA_WIDTH    = 32
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            input   wire                                cke,
            
            input   wire    [S_NUM-1:0][M_ID_WIDTH-1:0] s_id_to,
            input   wire    [S_NUM-1:0][DATA_WIDTH-1:0] s_data,
            input   wire    [S_NUM-1:0]                 s_valid,
            
            output  wire    [M_NUM-1:0][S_ID_WIDTH-1:0] m_id_from,
            output  wire    [M_NUM-1:0][DATA_WIDTH-1:0] m_data,
            output  wire    [M_NUM-1:0]                 m_valid
        );
    
    
    reg     [S_NUM-1:0][DATA_WIDTH-1:0]     st0_data;
    reg     [M_NUM-1:0][S_NUM-1:0]          st0_valid;
    wire    [M_NUM-1:0][S_ID_WIDTH-1:0]     st0_id;
    
    reg     [S_NUM-1:0][DATA_WIDTH-1:0]     st1_data;
    reg     [M_NUM-1:0][S_ID_WIDTH-1:0]     st1_id;
    reg     [M_NUM-1:0]                     st1_valid;
    
    reg     [M_NUM-1:0][S_ID_WIDTH-1:0]     st2_id;
    reg     [M_NUM-1:0][DATA_WIDTH-1:0]     st2_data;
    reg     [M_NUM-1:0]                     st2_valid;

    reg     [S_ID_WIDTH-1:0]                tmp_id;
    
    generate
    for ( genvar i = 0; i < M_NUM; ++i ) begin : loop_encoder
        jelly_bit_encoder
                #(
                    .DATA_WIDTH     (S_NUM),
                    .SEL_WIDTH      (S_ID_WIDTH),
                    .PRIORITYT      (0)
                )
            i_bit_encoder
                (
                    .in_data        (st0_valid[i]),
                    .out_sel        (st0_id   [i])
                );  
    end
    endgenerate
    
    always @(posedge clk) begin
        if ( reset ) begin
            st0_data  <= 'x;
            st0_valid <= '0;
            
            st1_id    <= 'x;
            st1_data  <= 'x;
            st1_valid <= '0;
            
            st2_id    <= 'x;
            st2_data  <= 'x;
            st2_valid <= '0;
        end
        else if ( cke ) begin
            // stage 0
            st0_data  <= s_data;
            st0_valid <= {(S_NUM*M_NUM){1'b0}};
            for ( int s = 0; s < S_NUM; ++s ) begin
                for ( int m = 0; m < M_NUM; ++m ) begin
                    if ( s_id_to[s] == M_ID_WIDTH'(m) ) begin
                        st0_valid[m][s] <= s_valid[s];
                    end
                end
            end
            
            
            // stage 1
            st1_data  <= st0_data;
            st1_id    <= st0_id;
            for ( int m = 0; m < M_NUM; ++m ) begin
                st1_valid[m] <= |st0_valid[m];
            end
            
            // stage 2
            st2_id <= st1_id;
            for ( int m = 0; m < M_NUM; ++m ) begin
                tmp_id = st1_id[m];
                st2_data[m] <= st1_data[tmp_id];
            end
            st2_valid <= st1_valid;
        end
    end
    
    
    assign m_id_from = st2_id;
    assign m_data    = st2_data;
    assign m_valid   = st2_valid;
    
endmodule



`default_nettype wire


// end of file
