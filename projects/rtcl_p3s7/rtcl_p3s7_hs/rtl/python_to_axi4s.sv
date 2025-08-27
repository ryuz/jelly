
`timescale 1ns / 1ps
`default_nettype none

// sync
// 10'h3a6  training pattern
// 10'h22a  BL Start
// 10'h015  BL
// 10'h12a  BL End
// 10'h2aa  frame start
// 10'h3aa  frame end ?
// 10'h0aa  line start
// 10'h035  pixel data
// 10'h12a  line end
// 10'h059  CRC
// BL       320 cycle (1280pix)
// IMG      168 cycle (672)
// H-blank  67 cycle (10'h3a6)

// sync[9:7] 3'b101 (0x5 Frame Start)
// sync[9:7] 3'b110 (0x6 Frame End)
// sync[9:7] 3'b001 (0x1 Line Start)
// sync[9:7] 3'b010 (0x2 Line End0)
// sync[6:0] 7'b0101010 (0x2a)

// h-size : max 672  16+640+16 ?
// v-size : max 512  16+480+16 

// tuser[0] : frame start
// tuser[1] : frame end
// tuser[2] : line start
// tuser[3] : black


module python_to_axi4s
        (
            input   var logic   [3:0][9:0]  s_data      ,
            input   var logic        [9:0]  s_sync      ,
            input   var logic               s_valid     ,

            jelly3_axi4s_if.m               m_axi4s
        );

    logic   busy        ;
    logic   id          ;
    logic   line_end    ;
    logic   frame_end   ;
    logic   frame_enable;
    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            busy           <= 1'b0;
            line_end       <= '0;
            frame_end      <= '0;
            frame_enable   <= 1'b0;
            id             <= '0;
            m_axi4s.tuser  <= '0;
            m_axi4s.tlast  <= 1'bx;
            m_axi4s.tdata  <= 'x;
            m_axi4s.tvalid <= 1'b0;
        end
        else begin
            if ( m_axi4s.tvalid && m_axi4s.tready && m_axi4s.tuser[1] ) begin   // frame end
                frame_enable <= 1'b0;
            end

            if ( m_axi4s.tready ) begin
                m_axi4s.tvalid <= 1'b0;
            end
            if ( m_axi4s.tvalid && m_axi4s.tlast ) begin
                busy             <= 1'b0;
                m_axi4s.tuser[3] <= 1'b0;
                m_axi4s.tvalid   <= 1'b0;
            end
            if ( s_valid ) begin
                id        <= 1'b0;
                line_end  <= (s_sync == 10'h12a) || (s_sync == 10'h32a);
                frame_end <= (s_sync == 10'h3aa);

                m_axi4s.tuser[2:0] <= '0                    ;
                m_axi4s.tlast      <= frame_end || line_end ;
                m_axi4s.tuser[1]   <= frame_end;// || (m_axi4s.tuser[3] && line_end);            ;
                m_axi4s.tdata      <= s_data                ;
                m_axi4s.tvalid     <= busy & !(m_axi4s.tvalid && m_axi4s.tlast );
                if ( s_sync == 10'h2aa ) begin   // Frame Start
                    busy             <= 1'b1;
                    id               <= 1'b1;
                    frame_enable     <= 1'b1;
                    m_axi4s.tuser[0] <= ~frame_enable;
                    m_axi4s.tvalid   <= 1'b1;
                end
                if ( s_sync == 10'h0aa ) begin   // Line Start
                    busy             <= 1'b1;
                    id               <= 1'b1;
                    m_axi4s.tuser[2] <= 1'b1;
                    m_axi4s.tvalid   <= 1'b1;
                end
                if ( s_sync == 10'h22a ) begin   // Black Start
                    busy             <= 1'b1;
                    id               <= 1'b1;
                    frame_enable     <= 1'b1;
                    m_axi4s.tuser[0] <= 1'b1;
                    m_axi4s.tuser[3] <= 1'b1;
                    m_axi4s.tvalid   <= 1'b1;
                end
            end
        end
    end

endmodule

`default_nettype wire

// end of file
