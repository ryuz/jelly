// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_data_delay
        #(
            parameter   int                         LATENCY    = 1,
            parameter   int                         DATA_WIDTH = 8,
            parameter   logic   [DATA_WIDTH-1:0]    DATA_INIT  = {DATA_WIDTH{1'bx}}
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [DATA_WIDTH-1:0]    s_data,
            input   wire                        s_valid,
            output  reg                         s_ready,

            output  reg     [DATA_WIDTH-1:0]    m_data,
            output  reg                         m_valid,
            input   wire                        m_ready
        );
    

    generate
    if ( LATENCY == 0 ) begin
        always_comb s_ready = m_ready;
        always_comb m_data  = s_data;
        always_comb m_valid = s_valid;
    end
    else begin
        logic   [LATENCY-1:0][DATA_WIDTH-1:0]   buf_data;
        logic   [LATENCY-1:0]                   buf_valid;
        always_ff @(posedge clk) begin
            if ( reset ) begin
                for ( int i = 0; i < LATENCY; ++i ) begin
                    buf_data[i]  <= DATA_INIT;
                    buf_valid[i] <= 1'b0;
                end
            end
            else if ( cke ) begin
                automatic logic     ready;
                ready = m_ready;
                for ( int i = LATENCY-1; i >= 1; --i ) begin
                    ready = ready || !buf_valid[i];
                    if ( ready ) begin
                        buf_data[i]  <= buf_data[i-1];
                        buf_valid[i] <= buf_valid[i-1];
                    end
                end

                ready = ready || !buf_valid[0];
                if ( ready ) begin
                    buf_data[0]  <= s_data;
                    buf_valid[0] <= s_valid;
                end
            end
        end

        always_comb s_ready = m_ready || !(&buf_valid);
        always_comb m_valid = buf_valid[LATENCY-1];
        always_comb m_data  = buf_data[LATENCY-1];
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
