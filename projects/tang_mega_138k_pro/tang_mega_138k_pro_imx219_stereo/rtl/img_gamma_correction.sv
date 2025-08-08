// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module img_gamma_correction
        (
            jelly3_mat_if.s                 s_mat       ,
            jelly3_mat_if.m                 m_mat       
        );

    // gammma
    logic   [2:0][7:0]  gamma_value;
    for ( genvar i = 0; i < 3; i++ ) begin : gamma_table
        gamma_table
            u_gamma_table
                (
                    .addr       (s_mat.data[0][i][9:0]),
                    .data       (gamma_value[i])
                );
    end

    always_ff @(posedge s_mat.clk) begin
        if ( s_mat.reset ) begin
            m_mat.row_first <= 'x;
            m_mat.row_last  <= 'x;
            m_mat.col_first <= 'x;
            m_mat.col_last  <= 'x;
            m_mat.de        <= 'x;
            m_mat.data      <= 'x;
            m_mat.user      <= 'x;
            m_mat.valid     <= '0;
        end
        else if ( s_mat.cke  ) begin
            m_mat.row_first <= s_mat.row_first;
            m_mat.row_last  <= s_mat.row_last ;
            m_mat.col_first <= s_mat.col_first;
            m_mat.col_last  <= s_mat.col_last ;
            m_mat.de        <= s_mat.de       ;
            m_mat.data      <= gamma_value    ;
            m_mat.user      <= s_mat.user     ;
            m_mat.valid     <= s_mat.valid    ;
        end
    end

endmodule


`default_nettype wire


// end of file
