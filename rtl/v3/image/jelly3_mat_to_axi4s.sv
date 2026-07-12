// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mat_to_axi4s
        (
            jelly3_mat_if.s     s_mat   ,
            jelly3_axi4s_if.m   m_axi4s 
        );

    localparam type data_t = logic [m_axi4s.DATA_BITS-1:0];
    localparam type user_t = logic [m_axi4s.USER_BITS-1:0];

    always_ff @(posedge s_mat.clk) begin
        if ( s_mat.reset ) begin
            m_axi4s.tuser  <= 'x    ;
            m_axi4s.tlast  <= 'x    ;
            m_axi4s.tdata  <= 'x    ;
            m_axi4s.tvalid <= 1'b0  ;
        end
        else begin
            m_axi4s.tuser    <= user_t'(s_mat.user << 1)            ;
            if ( m_axi4s.tvalid ) begin
                m_axi4s.tuser[0] <= 1'b0;
            end
            if ( s_mat.valid && s_mat.row_first && s_mat.col_first ) begin
                m_axi4s.tuser[0] <= 1'b1;
            end
            m_axi4s.tlast    <= s_mat.col_last                      ;
            m_axi4s.tdata    <= data_t'(s_mat.data)                 ;
            m_axi4s.tvalid   <= s_mat.de && s_mat.valid && s_mat.cke;
        end
    end
    
endmodule

`default_nettype wire

// end of file
