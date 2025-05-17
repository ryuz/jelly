// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//   image processing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module generate_csi_packet
        (
            input   var logic           frame_start     ,
            input   var logic           frame_end       ,

            input   var logic   [7:0]   data_type       ,
            input   var logic   [15:0]  wc              ,

            jelly3_axi4s_if.s           s_axi4s_video   ,
            jelly3_axi4s_if.m           m_axi4s_mipi    
        );
    
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

    typedef enum  {
        IDLE    ,
        HEADER0 ,
        HEADER1 ,
        DATA    
    } state_t;

    state_t         state   ;
    logic   [7:0]   reg_id  ;
    logic   [15:0]  reg_wc  ;
    always_ff @(posedge s_axi4s_video.aclk) begin
        if ( ~s_axi4s_video.aresetn ) begin
            state  <= IDLE  ;
            reg_id <= 'x    ;
            reg_wc <= 'x    ;
            m_axi4s_mipi.tuser  <= 1'bx  ;
            m_axi4s_mipi.tlast  <= 1'bx  ;
            m_axi4s_mipi.tdata  <= 'x    ;
            m_axi4s_mipi.tvalid <= 1'b0  ;
        end
        else if ( s_axi4s_video.aclken ) begin
            if ( !m_axi4s_mipi.tvalid || m_axi4s_mipi.tready ) begin
                m_axi4s_mipi.tvalid <= 1'b0;
                case ( state )
                IDLE:
                    begin
                        if ( frame_start ) begin
                            reg_id <= 8'h00;
                            reg_wc <= '0;
                            state  <= HEADER0;
                        end
                        else if ( frame_end ) begin
                            reg_id <= 8'h01;
                            reg_wc <= '0;
                            state  <= HEADER0;
                        end
                        else if ( s_axi4s_video.tvalid ) begin
                            reg_id <= data_type;
                            reg_wc <= wc;
                            state  <= HEADER0;
                        end
                    end

                HEADER0:
                    begin
                        m_axi4s_mipi.tuser  <= 1'b1;
                        m_axi4s_mipi.tlast  <= 1'b0;
                        m_axi4s_mipi.tdata  <= { reg_wc[7:0], reg_id };
                        m_axi4s_mipi.tvalid <= 1'b1;
                        state <= HEADER1;
                    end
                
                HEADER1:
                    begin
                        m_axi4s_mipi.tuser  <= 1'b1;
                        m_axi4s_mipi.tlast  <= 1'b0;
                        m_axi4s_mipi.tdata  <= { 2'd0, calc_ecc({reg_wc, reg_id}) , reg_wc[15:8] };
                        m_axi4s_mipi.tvalid <= 1'b1;
                        if ( reg_wc == 16'h00 ) begin
                            state <= IDLE;
                        end
                        else begin
                            state <= DATA;
                        end
                    end
                
                DATA:
                    begin
                        m_axi4s_mipi.tuser  <= s_axi4s_video.tuser  ;
                        m_axi4s_mipi.tlast  <= s_axi4s_video.tlast  ;
                        m_axi4s_mipi.tdata  <= s_axi4s_video.tdata  ;
                        m_axi4s_mipi.tvalid <= s_axi4s_video.tvalid ;
                        if ( s_axi4s_video.tlast ) begin
                            state <= IDLE;
                        end
                        state <= DATA;
                    end
                endcase
            end
        end
    end

    assign s_axi4s_video.tready = (!m_axi4s_mipi.tvalid || m_axi4s_mipi.tready) && (state == DATA);

endmodule


`default_nettype wire


// end of file
