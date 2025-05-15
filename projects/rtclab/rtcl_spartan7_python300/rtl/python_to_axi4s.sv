
`timescale 1ns / 1ps
`default_nettype none


module python_to_axi4s
        (
            input   var logic   [3:0][9:0]  s_data      ,
            input   var logic        [9:0]  s_sync      ,
            input   var logic               s_valid     ,

            jelly3_axi4s_if.m               m_axi4s
        );

    logic   last;
    logic   busy;
    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            last   <= 'x;
            m_axi4s.tuser  <= 'x;
            m_axi4s.tlast  <= 1'bx;
            m_axi4s.tdata  <= 'x;
            m_axi4s.tvalid <= 1'b0;
        end
        else begin
            if ( m_axi4s.tready ) begin
                m_axi4s.tvalid <= 1'b0;
            end
            if ( m_axi4s.tvalid && m_axi4s.tlast ) begin
                busy <= 1'b0;
            end
            if ( s_valid ) begin
                last   <= (s_sync == 10'h12a) || (s_sync == 10'h32a);

                m_axi4s.tuser  <= 1'b0  ;
                m_axi4s.tlast  <= last  ;
                m_axi4s.tdata  <= s_data;
                m_axi4s.tvalid <= busy  ;
                if ( s_sync == 10'h2aa ) begin   // FS
                    busy   <= 1'b1;
                    m_axi4s.tuser  <= 1'b1;
                    m_axi4s.tvalid <= 1'b1;
                end
                if ( s_sync == 10'h0aa ) begin   // LS
                    busy   <= 1'b1;
                    m_axi4s.tvalid <= 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire

// end of file
