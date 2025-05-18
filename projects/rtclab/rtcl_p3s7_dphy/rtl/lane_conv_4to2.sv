// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module lane_conv_4to2
        (
            jelly3_axi4s_if.s   s_axi4s ,
            jelly3_axi4s_if.m   m_axi4s  
        );
    
    logic   phase;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            phase          <= 1'b0  ;
            m_axi4s.tuser  <= 1'bx  ;
            m_axi4s.tlast  <= 1'bx  ;
            m_axi4s.tdata  <= 'x    ;
            m_axi4s.tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( !m_axi4s.tvalid || m_axi4s.tready ) begin
                m_axi4s.tvalid <= 1'b0;
                if ( s_axi4s.tvalid ) begin
                    if ( phase == 1'b0 ) begin
                        m_axi4s.tuser  <= s_axi4s.tuser         ;
                        m_axi4s.tlast  <= 1'b0                  ;
                        m_axi4s.tdata  <= s_axi4s.tdata[19:0]   ;
                        m_axi4s.tvalid <= 1'b1                  ;
                        phase <= 1'b1;
                    end
                    else begin
                        m_axi4s.tuser  <= 1'b0                  ;
                        m_axi4s.tlast  <= s_axi4s.tlast         ;
                        m_axi4s.tdata  <= s_axi4s.tdata[39:20]  ;
                        m_axi4s.tvalid <= 1'b1                  ;
                        phase          <= 1'b0                  ;
                    end
                end
            end
        end
    end

    assign s_axi4s.tready = (!m_axi4s.tvalid || m_axi4s.tready) && phase;

endmodule


`default_nettype wire


// end of file
