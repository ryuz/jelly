// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2025 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly3_mipi_csi2_rx_packet_2lane
        (
            input   var logic   [7:0]   param_data_type     ,
            
            output  var logic           out_frame_start     ,
            output  var logic           out_frame_end       ,
            
            output  var logic           out_ecc_corrected   ,
            output  var logic           out_ecc_error       ,
            output  var logic           out_ecc_valid       ,
            
            output  var logic           out_crc_error       ,
            output  var logic           out_crc_valid       ,
            
            output  var logic           out_packet_lost     ,

            jelly3_axi4s_if.s           s_axi4s             ,
            jelly3_axi4s_if.m           m_axi4s             
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
    
    
    // stage 0 (header parser)
    typedef enum logic [0:0] {
        ST0_IDLE   = 1'd0,
        ST0_HEADER = 1'd1
    } st0_state_t;
    
    st0_state_t     st0_state   ;
    logic   [7:0]   st0_id      ;
    logic   [15:0]  st0_wc      ;
    logic   [7:0]   st0_ecc     ;
    logic           st0_ph      ;
    logic           st0_last    ;
    logic   [15:0]  st0_data    ;
    logic           st0_valid   ;
    
    always @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st0_state <= ST0_IDLE   ;
            st0_id    <= 8'hxx      ;
            st0_wc    <= 16'hxxxx   ;
            st0_ecc   <= 8'hxx      ;
            st0_ph    <= 1'bx       ;
            st0_last  <= 1'bx       ;
            st0_data  <= 'x         ;
            st0_valid <= 1'b0       ;
        end
        else if ( s_axi4s.aclken && s_axi4s.tready ) begin
            st0_ph    <= 1'b0;
            st0_last  <= s_axi4s.tlast;
            st0_data  <= s_axi4s.tdata;
            st0_valid <= s_axi4s.tvalid;
            
            if ( s_axi4s.tuser && s_axi4s.tvalid ) begin
                // start
                st0_state             <= ST0_HEADER     ;
                st0_wc                <= 16'hxxxx       ;
                st0_ecc               <= 8'hxx          ;
                {st0_wc[7:0], st0_id} <= s_axi4s.tdata  ;
            end
            else begin
                case ( st0_state )
                ST0_HEADER:
                    begin
                        if ( s_axi4s.tvalid ) begin
                            st0_state               <= ST0_IDLE     ;
                            {st0_ecc, st0_wc[15:8]} <= s_axi4s.tdata;
                            st0_ph                  <= 1'b1;
                        end
                    end
                
                default:
                    begin
                        st0_state <= ST0_IDLE;
                        st0_id    <= 8'hxx;
                        st0_wc    <= 16'hxxxx;
                        st0_ecc   <= 8'hxx;
                    end
                endcase
            end
        end
    end
    
    
    
    logic               ecc_ph          ;
    logic               ecc_last        ;
    logic   [15:0]      ecc_data        ;
    logic   [7:0]       ecc_id          ;
    logic   [15:0]      ecc_wc          ;
    logic               ecc_error       ;
    logic               ecc_corrected   ;
    logic               ecc_valid       ;
    
    jelly3_mipi_ecc24
            #(
                .USER_BITS      (2+16                               )
            )
        u_mipi_ecc24
            (
                .reset          (~s_axi4s.aresetn                   ),
                .clk            (s_axi4s.aclk                       ),
                .cke            (s_axi4s.aclken && s_axi4s.tready   ),
                
                .s_user         ({st0_ph, st0_last, st0_data}       ),
                .s_data         ({st0_wc, st0_id}                   ),
                .s_ecc          (st0_ecc[5:0]                       ),
                .s_valid        (st0_valid                          ),
                
                .m_user         ({ecc_ph, ecc_last, ecc_data}       ),
                .m_data         ({ecc_wc, ecc_id}                   ),
                .m_error        (ecc_error                          ),
                .m_corrected    (ecc_corrected                      ),
                .m_valid        (ecc_valid                          )
            );
    
    
    
    // stage1
    typedef enum logic [1:0] {
        ST1_IDLE  = 2'd0,
        ST1_DATA  = 2'd1,
        ST1_CRC   = 2'd2
    } st1_state_t;
    
    st1_state_t     st1_state       ;
    logic           st1_de          ;
    logic   [15:0]  st1_wc          ;
    logic   [15:0]  st1_counter     ;
    logic   [15:0]  st1_crc         ;
    logic   [15:0]  st1_crc_sum     ;
    logic           st1_first       ;
    logic           st1_last        ;
    logic           st1_end         ;
    logic           st1_user        ;
    logic   [15:0]  st1_data        ;
    logic           st1_valid       ;
    logic           st1_frame_start ;
    logic           st1_frame_end   ;
    logic           st1_crc_error   ;
    logic           st1_crc_valid   ;
    logic           st1_lost        ;
    
    always @(posedge s_axi4s.aclk) begin
        if ( ~s_axi4s.aresetn ) begin
            st1_state       <= ST1_IDLE;
            st1_de          <= 1'bx ;
            st1_wc          <= 'x   ;
            st1_counter     <= 'x   ;
            st1_crc         <= 'x   ;
            st1_crc_sum     <= 'x   ;
            st1_user        <= 1'b0 ;
            st1_data        <= 'x   ;
            st1_first       <= 1'bx ;
            st1_last        <= 1'bx ;
            st1_end         <= 1'bx ;
            st1_valid       <= 1'b0 ;
            st1_frame_start <= 1'b0 ;
            st1_frame_end   <= 1'b0 ;
            st1_crc_error   <= 1'b0 ;
            st1_lost        <= 1'b0 ;
        end
        else if ( s_axi4s.aclken && s_axi4s.tready ) begin
            st1_frame_start <= 1'b0     ;
            st1_frame_end   <= 1'b0     ;
            st1_crc_error   <= 1'b0     ;
            st1_crc_valid   <= 1'b0     ;
            st1_lost        <= 1'b0     ;
            st1_data        <= ecc_data ;
            st1_last        <= ecc_last ;
            st1_end         <= 1'b0     ;
            st1_valid       <= 1'b0     ;

            if ( st1_frame_start ) begin
                st1_user <= 1'b1;
            end
            else if ( m_axi4s.tvalid && m_axi4s.tuser ) begin
                st1_user <= 1'b0;
            end

            if ( ecc_valid ) begin
                if ( ecc_ph && (!ecc_error || ecc_corrected) ) begin
                    if ( ecc_id[5:4] == 2'b00 ) begin
                        // short packet
                        st1_state       <= ST1_IDLE;
                        st1_wc          <= 16'hxxxx;
                        st1_counter     <= 16'hxxxx;
                        st1_crc         <= 16'hxxxx;
                        st1_crc_sum     <= 16'hxxxx;
                        st1_frame_start <= (ecc_id[3:0] == 4'h0);
                        st1_frame_end   <= (ecc_id[3:0] == 4'h1);
                    end
                    else begin
                        // long packet
                        st1_state    <= ST1_DATA    ;
                        st1_de       <= (ecc_id == param_data_type);
                        st1_wc       <= ecc_wc      ;
                        st1_counter  <= 16'h0002    ;
                        st1_crc      <= 16'hxxxx    ;
                        st1_crc_sum  <= 16'hffff    ;
                    end
                end
                else begin
                    case ( st1_state )
                    ST1_DATA:
                        begin
                            st1_valid   <= st1_de               ;
                            st1_counter <= st1_counter + 16'd2  ;
                            st1_crc     <= 16'hxxxx             ;
                            st1_crc_sum <= calc_crc(st1_crc_sum, ecc_data);
                            st1_first   <= (st1_counter == 16'h0002);
                            
                            if ( st1_counter[15:1] == st1_wc[15:1] ) begin
                                st1_state <= ST1_CRC    ;
                                st1_last  <= 1'b1       ;
                            end
                        end
                    
                    ST1_CRC:
                        begin
                            st1_state     <= ST1_IDLE   ;
                            st1_crc       <= ecc_data   ;
                            st1_end       <= 1'b1       ;
                            st1_de        <= 1'b0       ;
                        end
                    
                    default:
                        begin
                            st1_state    <= ST1_IDLE    ;
                            st1_wc       <= 16'hxxxx    ;
                            st1_counter  <= 16'hxxxx    ;
                            st1_crc      <= 16'hxxxx    ;
                            st1_de       <= 1'b0        ;
                        end
                    endcase
                end
            end
            if ( ecc_last ) begin
                st1_state  <= ST1_IDLE  ;
                st1_de     <= 1'b0      ;
                st1_lost   <= (st1_state != ST1_IDLE && st1_state != ST1_CRC);
            end
            
            st1_crc_error <= st1_end && (st1_crc_sum != st1_crc);
            st1_crc_valid <= st1_end;
        end
    end
    
    
    assign out_frame_start  = st1_frame_start   ;
    assign out_frame_end    = st1_frame_end     ;
    
    assign out_ecc_corrected = ecc_corrected                ;
    assign out_ecc_error     = (ecc_error && !ecc_corrected);
    assign out_ecc_valid     = ecc_valid & ecc_ph           ;
    
    assign out_crc_error    = st1_crc_error;
    assign out_crc_valid    = st1_crc_valid;
    
    assign out_packet_lost  = st1_lost;
    
    assign s_axi4s.tready   = !m_axi4s.tvalid | m_axi4s.tready;
    
    assign m_axi4s.tuser    = st1_user & st1_first  ;
    assign m_axi4s.tlast    = st1_last              ;
    assign m_axi4s.tdata    = st1_data              ;
    assign m_axi4s.tvalid   = st1_valid             ;
    
endmodule


`default_nettype wire


// end of file
