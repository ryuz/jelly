// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none


module line_trimming
        #(
            parameter   int     LEN_BITS = 12,
            parameter   type    len_t    = logic [LEN_BITS-1:0]

        )
        (
            input var len_t     len     ,
            jelly3_axi4s_if.s   s_axi4s ,
            jelly3_axi4s_if.m   m_axi4s 
        );

    assign s_axi4s.tready = !m_axi4s.tvalid || m_axi4s.tready;

    logic   trimming;
    len_t   count   ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            trimming        <= 1'b0 ;
            count           <= '0   ;
            m_axi4s.tuser   <= 1'bx ;
            m_axi4s.tlast   <= 1'bx ;
            m_axi4s.tdata   <= 'x   ;
            m_axi4s.tvalid  <= 1'b0 ;
        end
        else if ( s_axi4s.tready ) begin
            m_axi4s.tuser   <= s_axi4s.tuser ;
            m_axi4s.tlast   <= s_axi4s.tlast ;
            m_axi4s.tdata   <= s_axi4s.tdata ;
            m_axi4s.tvalid  <= s_axi4s.tvalid & !trimming;
            if ( s_axi4s.tvalid ) begin
                count <= count + 1;
                if ( count == len ) begin
                    m_axi4s.tlast <= 1'b1;
                    trimming      <= 1'b1;
                end
                if ( s_axi4s.tlast ) begin
                    trimming <= 1'b0;
                    count    <= '0;
                end
            end
        end
    end

endmodule

`default_nettype wire


// end of file
