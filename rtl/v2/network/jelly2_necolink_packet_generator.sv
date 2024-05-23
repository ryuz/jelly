// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_packet_generator
        #(
            parameter bit          DEBUG        = 1'b0,
            parameter bit          SIMULATION   = 1'b0
        )
        (
            input   var logic               reset,
            input   var logic               clk,
            input   var logic               cke,

            input   var logic               start,
            output  var logic               busy,

            input   var logic               param_mac_enable      ,
            input   var logic   [7:0]       param_node            ,
            input   var logic   [7:0]       param_type            ,
            input   var logic   [15:0]      param_length          ,

            output  var logic               packet_start          ,
            output  var logic               packet_finish         ,

            output  var logic   [15:0]      m_packet_index        ,
            output  var logic               m_packet_mac_dst      ,
            output  var logic               m_packet_mac_src      ,
            output  var logic               m_packet_mac_type     ,
            output  var logic               m_packet_node         ,
            output  var logic               m_packet_type         ,
            output  var logic               m_packet_length       ,
            output  var logic               m_packet_payload_setup,
            output  var logic               m_packet_payload_first,
            output  var logic               m_packet_payload_last ,
            output  var logic               m_packet_payload      ,
            output  var logic               m_packet_fcs          ,
            output  var logic               m_packet_fcs_first    ,
            output  var logic               m_packet_fcs_last     ,
            output  var logic               m_packet_crc          ,
            output  var logic               m_packet_crc_first    ,
            output  var logic               m_packet_crc_last     ,
            output  var logic               m_packet_first        ,
            output  var logic               m_packet_last         ,
            output  var logic   [7:0]       m_packet_data         ,
            output  var logic               m_packet_valid        ,
            input   var logic               m_packet_ready        
        );

    // Handshake
    logic               local_cke;
    assign local_cke = !m_packet_valid || m_packet_ready;


    // state
    typedef enum logic [10:0] {
        ST_IDLE     = 11'b00000000000,
        ST_PREAMBLE = 11'b00000000001,
        ST_SFD      = 11'b00000000010,
        ST_MAC_DST  = 11'b00000000100,
        ST_MAC_SRC  = 11'b00000001000,
        ST_MAC_TYPE = 11'b00000010000,
        ST_NODE     = 11'b00000100000,
        ST_TYPE     = 11'b00001000000,
        ST_LENGTH   = 11'b00010000000,
        ST_PAYLOAD  = 11'b00100000000,
        ST_FCS      = 11'b01000000000,
        ST_FINISH   = 11'b10000000000
    } t_state;

    t_state             state;
    logic   [10:0]       state_bit;
    assign state_bit = state;

    wire    flag_preamble = state_bit[ 0];
    wire    flag_sfd      = state_bit[ 1];
    wire    flag_mac_dst  = state_bit[ 2];
    wire    flag_mac_src  = state_bit[ 3];
    wire    flag_mac_type = state_bit[ 4];
    wire    flag_node     = state_bit[ 5];
    wire    flag_type     = state_bit[ 6];
    wire    flag_length   = state_bit[ 7];
    wire    flag_payload  = state_bit[ 8];
    wire    flag_fcs      = state_bit[ 9];
    wire    flag_finish   = state_bit[10];

    // format
    logic               first       ;
    logic               last        ;
    logic   [15:0]      counter     ;
    logic   [15:0]      length      ;
    logic               mac_enable  ;
    logic   [7:0]       reg_node    ;
    logic   [7:0]       reg_type    ;
    logic   [15:0]      reg_length  ;

    logic   [15:0]  counter_next      ;
    assign counter_next = counter + 16'd1;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            state          <= ST_IDLE;
            first          <= 'x;
            last           <= 'x;
            counter        <= 'x;
            length         <= 'x;
            mac_enable     <= 'x;
            reg_node       <= 'x;
            reg_type       <= 'x;
            reg_length     <= 'x;
        end
        else if ( cke && local_cke ) begin
            if ( state == ST_IDLE ) begin
                first          <= 'x;
                last           <= 'x;
                counter        <= 'x;
                mac_enable     <= 'x;
                length         <= 'x;
                reg_node       <= 'x;
                reg_type       <= 'x;
                reg_length     <= 'x;
            
                if ( start ) begin
                    // start
                    state          <= ST_PREAMBLE;
                    first          <= 1'b1;
                    last           <= 1'b0;
                    counter        <= '0;
                    mac_enable     <= param_mac_enable;
                    length         <= param_length    ;
                    reg_node       <= param_node      ;
                    reg_type       <= param_type      ;
                    reg_length     <= param_length    ;
                end
            end
            else begin
                // counter
                counter <= counter_next;
                if ( last ) begin
                    counter <= '0;
                end

                // state last
                last           <= 1'b0;
                if ( flag_preamble && counter_next[2:0] == 3'd4 ) begin last <= 1'b1; end
                if ( flag_mac_dst  && counter_next[2:0] == 3'd5 ) begin last <= 1'b1; end
                if ( flag_mac_src  && counter_next[2:0] == 3'd5 ) begin last <= 1'b1; end
                if ( flag_mac_type && counter_next[0:0] == 1'd1 ) begin last <= 1'b1; end
                if ( flag_length   && counter_next[0:0] == 1'd1 ) begin last <= 1'b1; end
                if ( flag_payload  && counter_next == length    ) begin last <= 1'b1; end
                if ( flag_fcs      && counter_next[1:0] == 2'd3 ) begin last <= 1'b1; end
                if ( flag_finish   && counter_next[0:0] == 1'd1 ) begin last <= 1'b1; end

                // state start
                first <= 1'b0;
                if ( flag_preamble && last   ) begin state <= ST_SFD     ; first <= 1'b1; last <= 1'b1;           end
                if ( flag_sfd &&  mac_enable ) begin state <= ST_MAC_DST ; first <= 1'b1;                         end
                if ( flag_sfd && !mac_enable ) begin state <= ST_NODE    ; first <= 1'b1;                         end
                if ( flag_mac_dst  && last   ) begin state <= ST_MAC_SRC ; first <= 1'b1;                         end
                if ( flag_mac_src  && last   ) begin state <= ST_MAC_TYPE; first <= 1'b1;                         end
                if ( flag_mac_type && last   ) begin state <= ST_NODE    ; first <= 1'b1; last <= 1'b1;           end
                if ( flag_node               ) begin state <= ST_TYPE    ; first <= 1'b1; last <= 1'b1;           end
                if ( flag_type               ) begin state <= ST_LENGTH  ; first <= 1'b1;                         end
                if ( flag_length   && last   ) begin state <= ST_PAYLOAD ; first <= 1'b1; last <= (length == '0); end
                if ( flag_payload  && last   ) begin state <= ST_FCS     ; first <= 1'b1;                         end
                if ( flag_fcs      && last   ) begin state <= ST_FINISH  ; first <= 1'b1; last <= 1'b1;           end
                if ( flag_finish             ) begin state <= ST_IDLE    ;                                        end

                // shift register
//              if ( flag_mac_dst ) begin  reg_mac_dst  <= (reg_mac_dst  << 8); end // big-endian
//              if ( flag_mac_src ) begin  reg_mac_src  <= (reg_mac_src  << 8); end // big-endian
//              if ( flag_mac_type) begin  reg_mac_type <= (reg_mac_type << 8); end // big-endian
                if ( flag_length  ) begin  reg_length   <= (reg_length   >> 8); end // little-endian
            end
        end
    end
    
    assign busy = (state != ST_IDLE && state != ST_FINISH);


    // output
    always_ff @(posedge clk) begin
        if ( reset ) begin
            m_packet_index         <= 'x;
//          m_packet_preamble      <= 'x;
//          m_packet_sfd           <= 'x;
            m_packet_mac_dst       <= 'x;
            m_packet_mac_src       <= 'x;
            m_packet_mac_type      <= 'x;
            m_packet_node          <= 'x;
            m_packet_type          <= 'x;
            m_packet_length        <= 'x;
            m_packet_payload_setup <= 'x;
            m_packet_payload_first <= 'x;
            m_packet_payload_last  <= 'x;
            m_packet_payload       <= 'x;
            m_packet_fcs           <= 'x;
            m_packet_fcs_first     <= 'x;
            m_packet_fcs_last      <= 'x;
            m_packet_crc           <= 'x;
            m_packet_crc_first     <= 'x;
            m_packet_crc_last      <= 'x;
            m_packet_first         <= 'x;
            m_packet_last          <= 'x;
            m_packet_data          <= 'x;
            m_packet_valid         <= 1'b0;
        end
        else if ( cke && local_cke ) begin
            m_packet_index         <= counter              ;
//          m_packet_preamble      <= flag_preamble        ;
//          m_packet_sfd           <= flag_sfd             ;
            m_packet_mac_dst       <= flag_mac_dst         ;
            m_packet_mac_src       <= flag_mac_src         ;
            m_packet_mac_type      <= flag_mac_type        ;
            m_packet_node          <= flag_node            ;
            m_packet_type          <= flag_type            ;
            m_packet_length        <= flag_length          ;
            m_packet_payload_setup <= flag_length   & last ;
            m_packet_payload_first <= flag_payload  & first;
            m_packet_payload_last  <= flag_payload  & last ;
            m_packet_payload       <= flag_payload         ;
            m_packet_fcs           <= flag_fcs             ;
            m_packet_fcs_first     <= flag_fcs      & first;
            m_packet_fcs_last      <= flag_fcs      & last ;
            m_packet_crc           <= flag_mac_dst | flag_mac_src | flag_mac_type | flag_node | flag_type | flag_length | flag_payload;
            m_packet_crc_first     <= (mac_enable ? flag_mac_dst : flag_node) & first;
            m_packet_crc_last      <= flag_payload  & last ;
            m_packet_first         <= flag_preamble & first;
            m_packet_last          <= flag_fcs      & last ;

            case ( state )
            ST_PREAMBLE: begin m_packet_data <= 8'h55;              end
            ST_SFD     : begin m_packet_data <= 8'hd5;              end
//          ST_MAC_DST : begin m_packet_data <= reg_mac_dst[5];     end
//          ST_MAC_SRC : begin m_packet_data <= reg_mac_src[5];     end
//          ST_MAC_TYPE: begin m_packet_data <= reg_mac_type[15:8]; end
            ST_NODE    : begin m_packet_data <= reg_node;           end
            ST_TYPE    : begin m_packet_data <= reg_type;           end
            ST_LENGTH  : begin m_packet_data <= reg_length[7:0];    end
            ST_PAYLOAD : begin m_packet_data <= 8'h00;              end
            ST_FCS     : begin m_packet_data <= 8'h00;              end
            default    : begin m_packet_data <= 8'h00;              end
            endcase

            m_packet_valid <= busy;
        end
    end


//  logic       reg_packet_start ;
    logic       reg_packet_finish;
    always_ff @(posedge clk) begin
        if ( reset ) begin
//          reg_packet_start  <= 1'b0;
            reg_packet_finish <= 1'b0;
        end
        else if ( cke & local_cke ) begin
//          reg_packet_start  <= flag_length && first;
            reg_packet_finish <= flag_finish;
        end
    end

    assign packet_start  = m_packet_valid & m_packet_ready & m_packet_first & local_cke;

//  assign packet_start  = reg_packet_start  & local_cke;
    assign packet_finish = reg_packet_finish & local_cke;


endmodule

`default_nettype wire

// end of file
