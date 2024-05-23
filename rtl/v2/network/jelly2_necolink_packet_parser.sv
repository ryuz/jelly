// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_packet_parser
        #(
            parameter bit          DEBUG        = 1'b0,
            parameter bit          SIMULATION   = 1'b0
        )
        (
            input   var logic               reset                   ,
            input   var logic               clk                     ,
            input   var logic               cke                     ,

            output  var logic               busy                    ,

            input   var logic               param_mac_enable        ,

            input   var logic               s_packet_first          ,
            input   var logic               s_packet_last           ,
            input   var logic   [7:0]       s_packet_data           ,
            input   var logic               s_packet_valid          ,
            output  var logic               s_packet_ready          ,

            output  var logic   [15:0]      m_packet_index          ,
            output  var logic               m_packet_mac_dst        ,
            output  var logic               m_packet_mac_src        ,
            output  var logic               m_packet_mac_type       ,
            output  var logic               m_packet_node           ,
            output  var logic               m_packet_type           ,
            output  var logic               m_packet_length         ,
            output  var logic               m_packet_payload_setup  ,
            output  var logic               m_packet_payload_first  ,
            output  var logic               m_packet_payload_last   ,
            output  var logic               m_packet_payload        ,
            output  var logic               m_packet_fcs_first      ,
            output  var logic               m_packet_fcs_last       ,
            output  var logic               m_packet_fcs            ,
            output  var logic               m_packet_crc_first      ,
            output  var logic               m_packet_crc_last       ,
            output  var logic               m_packet_crc            ,
            output  var logic               m_packet_first          ,
            output  var logic               m_packet_last           ,
            output  var logic   [7:0]       m_packet_data           ,
            output  var logic               m_packet_valid          ,
            input   var logic               m_packet_ready          ,

            output  var logic               packet_start            ,
            output  var logic               packet_finish           ,
            output  var logic               packet_fail             ,

            output  var logic   [5:0][7:0]  rx_mac_dst              ,
            output  var logic   [5:0][7:0]  rx_mac_src              ,
            output  var logic   [15:0]      rx_mac_type             ,
            output  var logic   [7:0]       rx_node                 ,
            output  var logic   [7:0]       rx_type                 ,
            output  var logic   [15:0]      rx_length               
        );


    logic   [15:0]  counter           ;
    logic   [4:0]   flag_preamble     ;
    logic   [0:0]   flag_sfd          ;
    logic   [5:0]   flag_mac_dst      ;
    logic   [5:0]   flag_mac_src      ;
    logic   [1:0]   flag_mac_type     ;
    logic   [0:0]   flag_node         ;
    logic   [0:0]   flag_type         ;
    logic   [1:0]   flag_length       ;
    logic           flag_payload      ;
    logic           flag_payload_first;
    logic           flag_payload_last ;
    logic           flag_fcs          ;
    logic           flag_fcs_first    ;
    logic           flag_fcs_last     ;
    logic           flag_crc          ;
    logic           flag_crc_first    ;
    logic           flag_crc_last     ;
    logic           flag_last         ;

    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( !busy ) begin
                flag_preamble      <= '0;
                flag_sfd           <= '0;
                flag_mac_dst       <= '0;
                flag_mac_src       <= '0;
                flag_mac_type      <= '0;
                flag_node          <= '0;
                flag_type          <= '0;
                flag_length        <= '0;
                flag_payload       <= '0;
                flag_payload_first <= '0;
                flag_payload_last  <= '0;
                flag_fcs           <= '0;
                flag_crc           <= '0;
                flag_crc_first     <= '0;
                flag_last          <= '0;

                flag_preamble[0] <= 1'b1;
            end
            else if ( s_packet_valid && s_packet_ready ) begin
                if ( param_mac_enable ) begin
                    {flag_length  ,
                     flag_type    ,
                     flag_node    ,
                     flag_mac_type,
                     flag_mac_src ,
                     flag_mac_dst ,
                     flag_sfd     ,
                     flag_preamble} <= {flag_length  ,
                                        flag_type    ,
                                        flag_node    ,
                                        flag_mac_type,
                                        flag_mac_src ,
                                        flag_mac_dst ,
                                        flag_sfd     ,
                                        flag_preamble} << 1;
                end
                else begin
                    {flag_length  ,
                     flag_type    ,
                     flag_node    ,
                     flag_sfd     ,
                     flag_preamble} <= {flag_length  ,
                                        flag_type    ,
                                        flag_node    ,
                                        flag_sfd     ,
                                        flag_preamble} << 1;
                end
            
                flag_crc_first <= 1'b0;
                if ( flag_sfd ) begin
                    flag_crc       <= 1'b1;
                    flag_crc_first <= 1'b1;
                end

                counter <= counter + 1'b1;
                flag_payload_first <= 1'b0;
                flag_fcs_first     <= 1'b0;
                if ( flag_length[1] ) begin
                    counter            <= '0;
                    flag_payload       <= 1'b1;
                    flag_payload_first <= 1'b1;
                    flag_payload_last  <= {s_packet_data, rx_length[7:0]} == 16'd0;
                end
                else if ( flag_payload && counter == rx_length ) begin
                    counter        <= '0;
                    flag_payload   <= 1'b0;
                    flag_crc       <= 1'b0;
                    flag_fcs       <= 1'b1;
                    flag_fcs_first <= 1'b1;
                end
                
                flag_last <= 1'b0;
                if ( flag_fcs && counter[1:0] == 2'd2 ) begin
                    flag_last <= 1'b1;
                end

                // receive
                if ( flag_mac_dst [0] ) begin rx_mac_dst [0]    <= s_packet_data; end
                if ( flag_mac_dst [1] ) begin rx_mac_dst [1]    <= s_packet_data; end
                if ( flag_mac_dst [2] ) begin rx_mac_dst [2]    <= s_packet_data; end
                if ( flag_mac_dst [3] ) begin rx_mac_dst [3]    <= s_packet_data; end
                if ( flag_mac_dst [4] ) begin rx_mac_dst [4]    <= s_packet_data; end
                if ( flag_mac_dst [5] ) begin rx_mac_dst [5]    <= s_packet_data; end
                if ( flag_mac_src [0] ) begin rx_mac_src [0]    <= s_packet_data; end
                if ( flag_mac_src [1] ) begin rx_mac_src [1]    <= s_packet_data; end
                if ( flag_mac_src [2] ) begin rx_mac_src [2]    <= s_packet_data; end
                if ( flag_mac_src [3] ) begin rx_mac_src [3]    <= s_packet_data; end
                if ( flag_mac_src [4] ) begin rx_mac_src [4]    <= s_packet_data; end
                if ( flag_mac_src [5] ) begin rx_mac_src [5]    <= s_packet_data; end
                if ( flag_mac_type[0] ) begin rx_mac_type[7 :0] <= s_packet_data; end
                if ( flag_mac_type[1] ) begin rx_mac_type[15:8] <= s_packet_data; end
                if ( flag_node    [0] ) begin rx_node           <= s_packet_data; end
                if ( flag_type    [0] ) begin rx_type           <= s_packet_data; end
                if ( flag_length  [0] ) begin rx_length  [7 :0] <= s_packet_data; end
                if ( flag_length  [1] ) begin rx_length  [15:8] <= s_packet_data; end
            end
        end
    end

//    assign packet_start = flag_length[0] && m_packet_valid && m_packet_ready;


    logic       reg_busy;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_busy <= 1'b0;
        end
        else if ( cke ) begin
            if ( m_packet_valid & m_packet_ready ) begin
                if ( m_packet_first ) begin
                    reg_busy <= 1'b1;
                end
                if ( m_packet_last ) begin
                    reg_busy <= 1'b0;
                end
            end
        end
    end
    assign busy = reg_busy || (s_packet_valid && s_packet_first);

    logic           parse_error;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            parse_error <= 1'b0;
        end
        else if ( cke ) begin
            parse_error <= 1'b0;
            if ( s_packet_valid && s_packet_ready ) begin
                if ( |flag_preamble && s_packet_data != 8'h55 ) begin parse_error <= 1'b1; end
                if ( |flag_sfd      && s_packet_data != 8'hd5 ) begin parse_error <= 1'b1; end
                if ( s_packet_last  && !flag_last             ) begin parse_error <= 1'b1; end
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( !busy ) begin
                m_packet_mac_dst  <= 1'b0;
                m_packet_mac_src  <= 1'b0;
                m_packet_mac_type <= 1'b0;
                m_packet_length   <= 1'b0;
            end
            else if ( s_packet_valid && s_packet_ready ) begin
                if ( flag_sfd && param_mac_enable ) begin m_packet_mac_dst  <= 1'b1; end
                if ( flag_mac_dst[5]              ) begin m_packet_mac_dst  <= 1'b0; end
                if ( flag_mac_dst[5]              ) begin m_packet_mac_src  <= 1'b1; end
                if ( flag_mac_src[5]              ) begin m_packet_mac_src  <= 1'b0; end
                if ( flag_mac_src[5]              ) begin m_packet_mac_type <= 1'b1; end
                if ( flag_mac_type[1]             ) begin m_packet_mac_type <= 1'b0; end
                if ( flag_type[0]                 ) begin m_packet_length   <= 1'b1; end
                if ( flag_length[1]               ) begin m_packet_length   <= 1'b0; end
            end
        end
    end


    assign m_packet_index          = counter;
    assign m_packet_node           = flag_node                                  ;
    assign m_packet_type           = flag_type                                  ;
    assign m_packet_payload_setup  = flag_length[1]                             ;
    assign m_packet_payload_first  = flag_payload_first                         ;
    assign m_packet_payload_last   = flag_payload_last                          ;
    assign m_packet_payload        = flag_payload                               ;
    assign m_packet_fcs_first      = flag_fcs_first                             ;
    assign m_packet_fcs_last       = flag_last                                  ;
    assign m_packet_fcs            = flag_fcs                                   ;
    assign m_packet_crc            = flag_crc                                   ;
    assign m_packet_crc_first      = flag_crc_first                             ;
    assign m_packet_crc_last       = flag_payload_last                          ;
    assign m_packet_first          = s_packet_first                             ;
    assign m_packet_last           = s_packet_last || flag_last || parse_error  ;
    assign m_packet_data           = s_packet_data                              ;
    assign m_packet_valid          = s_packet_valid && busy                     ;
    assign s_packet_ready          = m_packet_ready                             ;


    // check FCS
    logic           fcs_ok;
    logic           fcs_error;
    jelly2_ether_fcs_check
            #(
                .DEBUG                  (DEBUG                          ),
                .SIMULATION             (SIMULATION                     )
            )
        u_ether_fcs_check
            (
                .reset                  (reset                          ),
                .clk                    (clk                            ),
                .cke                    (cke                            ),

                .crc_ok                 (fcs_ok                         ),
                .crc_ng                 (fcs_error                      ),

                .s_packet_crc_start     (m_packet_crc_first             ),
                .s_packet_last          (m_packet_last                  ),
                .s_packet_data          (m_packet_data                  ),
                .s_packet_valid         (m_packet_valid & m_packet_ready)
            );

    assign packet_start  = m_packet_valid & m_packet_ready & m_packet_first;
    assign packet_finish = fcs_ok;
    assign packet_fail   = fcs_error || parse_error;
    
endmodule


`default_nettype wire


// end of file

