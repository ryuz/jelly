// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   math
//
//                                 Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly2_unsigned_width_convert
        #(
            parameter  int      S_WIDTH = 8,
            parameter  int      M_WIDTH = 12,
            parameter  bit      STUFF   = 0
        )
        (
           
            input   wire    [S_WIDTH-1:0]   s_data,
            output  reg     [M_WIDTH-1:0]   m_data
        );
    
    always_comb begin
        for ( int i = 0; i < M_WIDTH; ++i ) begin
            m_data[M_WIDTH-1 - i] = s_data[S_WIDTH-1 - (i%S_WIDTH)];
            if ( STUFF && i >= S_WIDTH ) begin
                m_data[M_WIDTH-1 - i] = 1'b0;
            end
        end
    end
    
endmodule


`default_nettype wire


// end of file
