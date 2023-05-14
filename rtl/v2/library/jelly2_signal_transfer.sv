// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// データを持たないFIFO的挙動のカウンタ
// データではなくシグナルの回数だけを伝えるための


module jelly2_signal_transfer
        #(
            parameter   bit     ASYNC         = 1,
            parameter   int     PTR_WIDTH      = 6,
            parameter   int     CAPACITY_WIDTH = 8
        )
        (
            input   wire    s_reset,
            input   wire    s_clk,
            input   wire    s_valid,
            
            input   wire    m_reset,
            input   wire    m_clk,
            output  wire    m_valid,
            input   wire    m_ready
        );
    
    
    generate
    if ( ASYNC ) begin : blk_async
        jelly2_signal_transfer_async
                #(
                    .PTR_WIDTH      (PTR_WIDTH),
                    .CAPACITY_WIDTH (CAPACITY_WIDTH)
                )
            i_signal_transfer_async
                (
                    .s_reset        (s_reset),
                    .s_clk          (s_clk),
                    .s_valid        (s_valid),
                    
                    .m_reset        (m_reset),
                    .m_clk          (m_clk),
                    .m_valid        (m_valid),
                    .m_ready        (m_ready)
                );
    end
    else begin : blk_sync
        jelly2_signal_transfer_sync
                #(
                    .CAPACITY_WIDTH (CAPACITY_WIDTH)
                )
            i_signal_transfer_sync
                (
                    .reset          (s_reset),
                    .clk            (s_clk),
                    .s_valid        (s_valid),
                    
                    .m_valid        (m_valid),
                    .m_ready        (m_ready)
                );
    end
    endgenerate

endmodule


`default_nettype wire


// end of file
