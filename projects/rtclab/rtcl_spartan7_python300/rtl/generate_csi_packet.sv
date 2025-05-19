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

            jelly3_axi4s_if.s           s_axi4s         ,
            jelly3_axi4s_if.m           m_axi4s         
        );

    logic   [7:0]   ff_data_type   ;
    logic   [15:0]  ff_wc          ;
    always_ff @(posedge s_axi4s.aclk) begin
        ff_data_type <= data_type;
        ff_wc        <= wc;
    end



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
    always_ff @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            state  <= IDLE  ;
            reg_id <= 'x    ;
            reg_wc <= 'x    ;
            m_axi4s.tuser  <= 1'bx  ;
            m_axi4s.tlast  <= 1'bx  ;
            m_axi4s.tdata  <= 'x    ;
            m_axi4s.tvalid <= 1'b0  ;
        end
        else if ( s_axi4s.aclken ) begin
            if ( !m_axi4s.tvalid || m_axi4s.tready ) begin
                m_axi4s.tvalid <= 1'b0;
                case ( state )
                IDLE:
                    begin
                        if ( frame_start ) begin
                            reg_id <= 8'h00         ;
                            reg_wc <= '0            ;
                            state  <= HEADER0       ;
                        end
                        else if ( frame_end ) begin
                            reg_id <= 8'h01         ;
                            reg_wc <= '0            ;
                            state  <= HEADER0       ;
                        end
                        else if ( s_axi4s.tvalid ) begin
                            reg_id <= ff_data_type  ;
                            reg_wc <= ff_wc         ;
                            state  <= HEADER0       ;
                        end
                    end

                HEADER0:
                    begin
                        m_axi4s.tuser  <= 1'b1                      ;
                        m_axi4s.tlast  <= 1'b0                      ;
                        m_axi4s.tdata  <= { reg_wc[7:0], reg_id }   ;
                        m_axi4s.tvalid <= 1'b1                      ;
                        state <= HEADER1;
                    end
                
                HEADER1:
                    begin
                        m_axi4s.tuser  <= 1'b1;
                        m_axi4s.tlast  <= 1'b0;
                        m_axi4s.tdata  <= { 2'd0, calc_ecc({reg_wc, reg_id}) , reg_wc[15:8] };
                        m_axi4s.tvalid <= 1'b1;
                        if ( reg_wc == 16'h00 ) begin
                            m_axi4s.tlast <= 1'b1;
                            state <= IDLE;
                        end
                        else begin
                            state <= DATA;
                        end
                    end
                
                DATA:
                    begin
                        m_axi4s.tuser  <= s_axi4s.tuser  ;
                        m_axi4s.tlast  <= s_axi4s.tlast  ;
                        m_axi4s.tdata  <= s_axi4s.tdata  ;
                        m_axi4s.tvalid <= s_axi4s.tvalid ;
                        if ( s_axi4s.tlast ) begin
                            state <= IDLE;
                        end
                    end
                endcase
            end
        end
    end

    assign s_axi4s.tready = (!m_axi4s.tvalid || m_axi4s.tready) && (state == DATA);

endmodule


`default_nettype wire


// end of file
