// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

// MIPI-CSI 2lane データ生成
module jelly3_mipi_csi2_tx_packet_2lane
        #(
            parameter   DEVICE         = "RTL"      ,
            parameter   SIMULATION     = "false"    ,
            parameter   DEBUG          = "false"    
        )
        (
            input   var logic   [7:0]   param_type      ,
            input   var logic   [15:0]  param_wc        ,

            input   var logic           frame_start     ,
            input   var logic           frame_end       ,


            jelly3_axi4s_if.s           s_axi4s         ,   // 16bit幅であること
            jelly3_axi4s_if.m           m_axi4s             // 16bit幅であること
        );

    // parameter check
    initial begin
        if (s_axi4s.DATA_BITS != 16) begin
            $error("s_axi4s.DATA_BITS must be 16, but it is %0d", s_axi4s.DATA_BITS);
        end
        if (m_axi4s.DATA_BITS != 16) begin
            $error("m_axi4s.DATA_BITS must be 16, but it is %0d", m_axi4s.DATA_BITS);
        end
    end

    // ECC
    logic   [5:0]   ecc_tbl [0:23] = '{
        6'h07, 6'h0b, 6'h0d, 6'h0e, 6'h13, 6'h15, 6'h16, 6'h19,
        6'h1a, 6'h1c, 6'h23, 6'h25, 6'h26, 6'h29, 6'h2a, 6'h2c,
        6'h31, 6'h32, 6'h34, 6'h38, 6'h1f, 6'h2f, 6'h37, 6'h3b
    };
    function automatic logic [5:0] calc_ecc( input logic [23:0] data );
        calc_ecc = '0;
        for ( int i = 0; i < 24; i++ ) begin
            if ( data[i] ) begin
                calc_ecc = calc_ecc ^ ecc_tbl[i];
            end
        end
    endfunction

    // CRC (16bit input, process two bytes at once)
    function automatic [15:0] calc_crc(input [15:0] crc, input [1:0][7:0] data);
        for (int j = 0; j < 2; j++) begin
            for (int i = 0; i < 8; i++) begin
                if ( crc[0] ^ data[j][i]) begin
                    crc = (crc >> 1) ^ 16'h8408;
                end else begin
                    crc = crc >> 1;
                end
            end
        end
        return crc;
    endfunction

    typedef enum  {
        IDLE    ,
        HEADER0 ,
        HEADER1 ,
        DATA    ,
        CRC     
    } state_t;

    state_t         state   ;
    logic   [7:0]   reg_id  ;
    logic   [15:0]  reg_wc  ;
    logic           reg_last;
    logic   [15:0]  reg_crc ;
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            state          <= IDLE  ;
            reg_id         <= 'x    ;
            reg_wc         <= 'x    ;
            reg_last       <= 1'bx  ;
            reg_crc        <= 'x    ;
            m_axi4s.tuser  <= 1'bx  ;
            m_axi4s.tlast  <= 1'bx  ;
            m_axi4s.tdata  <= '0    ;
            m_axi4s.tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( !m_axi4s.tvalid || m_axi4s.tready ) begin
                m_axi4s.tdata  <= '0    ;
                m_axi4s.tvalid <= 1'b0  ;
                case ( state )
                IDLE:
                    begin
                        reg_id         <= 'x    ;
                        reg_wc         <= 'x    ;
                        reg_last       <= 1'bx  ;
                        reg_crc        <= 'x    ;
                        m_axi4s.tuser  <= 1'bx  ;
                        m_axi4s.tlast  <= 1'bx  ;
                        m_axi4s.tdata  <= '0    ;
                        m_axi4s.tvalid <= 1'b0  ;

                        if ( frame_start ) begin
                            state    <= HEADER0     ;
                            reg_id   <= 8'h00       ;
                            reg_wc   <= '0          ;
                        end
                        else if ( frame_end ) begin
                            state    <= HEADER0     ;
                            reg_id   <= 8'h01       ;
                            reg_wc   <= '0          ;
                        end
                        else if ( s_axi4s.tvalid ) begin
                            state    <= HEADER0     ;
                            reg_id   <= param_type  ;
                            reg_wc   <= param_wc    ;
                        end
                    end

                HEADER0:
                    begin
                        state          <= HEADER1                   ;
                        reg_last       <= 1'bx                      ;
                        reg_crc        <= 'x                        ;
                        m_axi4s.tuser  <= 1'b1                      ;
                        m_axi4s.tlast  <= 1'b0                      ;
                        m_axi4s.tdata  <= { reg_wc[7:0], reg_id }   ;
                        m_axi4s.tvalid <= 1'b1                      ;
                    end
                
                HEADER1:
                    begin
                        m_axi4s.tuser  <= 1'b1  ;
                        m_axi4s.tlast  <= 1'b0  ;
                        m_axi4s.tdata  <= { 2'd0, calc_ecc({reg_wc, reg_id}) , reg_wc[15:8] };
                        m_axi4s.tvalid <= 1'b1  ;
                        if ( reg_wc == 16'h00 ) begin
                            state         <= IDLE   ;
                            reg_last      <= 1'bx   ;
                            reg_crc       <= 'x     ;
                            m_axi4s.tlast <= 1'b1   ;
                        end
                        else begin
                            state         <= DATA        ;
                            reg_last      <= 1'b0        ;
                            reg_crc       <= 16'hffff    ;
                        end
                    end
                
                DATA:
                    begin
                        reg_crc        <= calc_crc(reg_crc, s_axi4s.tdata);
                        reg_last       <= s_axi4s.tlast  ;
                        m_axi4s.tuser  <= 1'b0           ;
                        m_axi4s.tlast  <= 1'b0           ;
                        m_axi4s.tdata  <= s_axi4s.tdata  ;
                        m_axi4s.tvalid <= s_axi4s.tvalid ;
                        if ( m_axi4s.tvalid && s_axi4s.tlast ) begin
                            state <= CRC;
                        end
                    end

                CRC:
                    begin
                        state          <= IDLE          ;
                        m_axi4s.tuser  <= 1'b0          ;
                        m_axi4s.tlast  <= 1'b1          ;
                        m_axi4s.tdata  <= reg_crc       ;
                        m_axi4s.tvalid <= 1'b1          ;
                    end
                endcase
            end
        end
    end

    assign s_axi4s.tready = (!m_axi4s.tvalid || m_axi4s.tready) && (state == DATA);

endmodule


`default_nettype wire


// end of file
