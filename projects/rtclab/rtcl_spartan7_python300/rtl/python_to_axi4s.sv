
`timescale 1ns / 1ps
`default_nettype none

// sync
// 10'h3a6  training pattern
// 10'h22a  OPB Start
// 10'h015  OPB 
// 10'h12a  OPB End
// 10'h2aa  frame start
// 10'h3aa  frame end ? 
// 10'h0aa  line start
// 10'h035  pixel data
// 10'h12a  line end
// 10'h059  CRC
// OPB     320 cycle (1280pix)
// H-blank  67 cycle (10'h3a6)

// sync[9:7] 3'b101 (0x5 Frame Start)
// sync[9:7] 3'b110 (0x6 Frame End)
// sync[9:7] 3'b001 (0x1 Line Start)
// sync[9:7] 3'b010 (0x2 Line End0)
// sync[6:0] 7'b0101010 (0x2a)


module python_to_axi4s
        (
            input   var logic   [3:0][9:0]  s_data      ,
            input   var logic        [9:0]  s_sync      ,
            input   var logic               s_valid     ,

            jelly3_axi4s_if.m               m_axi4s
        );

    logic   busy    ;
    logic   id      ;
    logic   last    ;
    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            busy   <= 1'b0;
            last   <= '0;
            id     <= '0;
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
                id     <= 1'b0;
//              last   <= (s_sync == 10'h12a) || (s_sync == 10'h32a) || (s_sync == 10'h3aa);
                last   <= busy && !id && (s_sync != 10'h035);

                m_axi4s.tuser  <= 1'b0  ;
                m_axi4s.tlast  <= last  ;
                m_axi4s.tdata  <= s_data;
                m_axi4s.tvalid <= busy  ;
                if ( s_sync == 10'h2aa ) begin   // FS
                    busy   <= 1'b1;
                    id     <= 1'b1;
                    m_axi4s.tuser  <= 1'b1;
                    m_axi4s.tvalid <= 1'b1;
                end
                if ( s_sync == 10'h0aa ) begin   // LS
                    busy   <= 1'b1;
                    id     <= 1'b1;
                    m_axi4s.tvalid <= 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire

// end of file
