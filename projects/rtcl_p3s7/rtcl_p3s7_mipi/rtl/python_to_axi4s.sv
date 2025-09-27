// ---------------------------------------------------------------------------
//  RTC-lab  PYTHON300 + Spartan7 MIPI Global shutter camera
//
//                                 Copyright (C) 2024-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


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
            input   var logic               csi_mode    ,

            input   var logic   [3:0][9:0]  s_data      ,
            input   var logic        [9:0]  s_sync      ,
            input   var logic               s_valid     ,

            output  var logic               frame_start ,

            jelly3_axi4s_if.m               m_axi4s         // tready は常に 1 の前提
        );

    // parse
    logic               parse_frame_enable  ;
    logic   [1:0]       parse_black_start   ;
    logic   [1:0]       parse_frame_start   ;
    logic   [1:0]       parse_frame_end     ;
    logic   [1:0]       parse_line_start    ;
    logic   [1:0]       parse_line_end      ;
    logic               parse_black_en      ;
    logic               parse_pixel_en      ;
    logic   [3:0][9:0]  parse_data          ;
    logic               parse_valid         ;
    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            parse_frame_enable <= '0        ;
            parse_black_start  <= '0        ;
            parse_frame_start  <= '0        ;
            parse_frame_end    <= '0        ;
            parse_line_start   <= '0        ;
            parse_line_end     <= '0        ;
            parse_black_en     <= '0        ;
            parse_pixel_en     <= '0        ;
            parse_data         <= 'x        ;
            parse_valid        <= 1'b0      ;
        end
        else if ( m_axi4s.aclken ) begin
            if ( s_valid ) begin
                parse_black_start[0] <= (s_sync == 10'h22a);
                parse_frame_start[0] <= (s_sync == 10'h2aa);
                parse_line_start [0] <= (s_sync == 10'h0aa);
                parse_line_end   [0] <= (s_sync == 10'h12a) || (s_sync == 10'h3aa);
                parse_frame_end  [0] <= (s_sync == 10'h3aa);
                parse_black_start[1] <= parse_black_start[0];
                parse_frame_start[1] <= parse_frame_start[0];
                parse_line_start [1] <= parse_line_start [0];
                parse_line_end   [1] <= parse_line_end   [0];
                parse_frame_end  [1] <= parse_frame_end  [0];

                if ( s_sync == 10'h2aa ) begin
                    parse_frame_enable <= 1'b1;
                end
                if ( parse_frame_end[1] ) begin
                    parse_frame_enable <= 1'b0;
                end

            end
            parse_black_en  <= (s_sync == 10'h015);
            parse_pixel_en  <= (s_sync == 10'h035);
            parse_data      <= s_data   ;
            parse_valid     <= s_valid  ;
        end
    end

    // output
    always_ff @(posedge m_axi4s.aclk) begin
        if ( ~m_axi4s.aresetn ) begin
            m_axi4s.tuser  <= '0;
            m_axi4s.tlast  <= 1'bx;
            m_axi4s.tdata  <= 'x;
            m_axi4s.tvalid <= 1'b0;
        end
        else if ( m_axi4s.aclken ) begin
            if ( csi_mode ) begin
                // 有効画素のみライン単位で有効化
                m_axi4s.tuser  <= parse_frame_start[0]  ;
                m_axi4s.tlast  <= parse_line_end   [1]  ;
                m_axi4s.tdata  <= parse_data            ;
                m_axi4s.tvalid <= parse_valid && parse_frame_enable && (|parse_frame_start || |parse_line_start || |parse_line_end || parse_pixel_en);
            end
            else begin
                // ブラック含めた全画素をフレーム単位で有効化
                m_axi4s.tuser  <= parse_black_start[0]  ;
                m_axi4s.tlast  <= parse_frame_end  [1]  ;
                m_axi4s.tdata  <= parse_data            ;
                m_axi4s.tvalid <= parse_valid && (|parse_frame_start || |parse_black_start || |parse_line_start || |parse_line_end || parse_black_en || parse_pixel_en);
            end
        end
    end

    assign frame_start = parse_black_start[0];

endmodule


`default_nettype wire


// end of file
