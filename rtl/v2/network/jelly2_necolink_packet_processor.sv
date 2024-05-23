// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_packet_processor
        #(
            parameter int   unsigned    PAYLOAD_LATENCY = 1,
            parameter int               NODE_ADD        = 1,
            parameter bit   [7:0]       TYPE_BIT        = 8'h00,
            parameter bit   [7:0]       TYPE_MASK       = 8'hff,
            parameter bit               DEBUG           = 1'b0,
            parameter bit               SIMULATION      = 1'b0
        )
        (
            input   var logic               reset                   ,
            input   var logic               clk                     ,
            input   var logic               cke                     ,
            
            input   var logic               packet_start            ,
            input   var logic               packet_finish           ,
            input   var logic               packet_fail             ,

            input   var logic               param_mac_enable        ,
            input   var logic               param_set_mac_dst       ,
            input   var logic               param_set_mac_src       ,
            input   var logic               param_set_mac_type      ,
            input   var logic   [5:0][7:0]  tx_mac_dst              ,
            input   var logic   [5:0][7:0]  tx_mac_src              ,
            input   var logic   [15:0]      tx_mac_type             ,


            input   var logic   [15:0]      s_rx_index              ,
            input   var logic               s_rx_mac_dst            ,
            input   var logic               s_rx_mac_src            ,
            input   var logic               s_rx_mac_type           ,
            input   var logic               s_rx_node               ,
            input   var logic               s_rx_type               ,
            input   var logic               s_rx_length             ,
            input   var logic               s_rx_payload_setup      ,
            input   var logic               s_rx_payload_first      ,
            input   var logic               s_rx_payload_last       ,
            input   var logic               s_rx_payload            ,
            input   var logic               s_rx_fcs_first          ,
            input   var logic               s_rx_fcs_last           ,
            input   var logic               s_rx_fcs                ,
            input   var logic               s_rx_crc_first          ,
            input   var logic               s_rx_crc_last           ,
            input   var logic               s_rx_crc                ,
            input   var logic               s_rx_first              ,
            input   var logic               s_rx_last               ,
            input   var logic   [7:0]       s_rx_data               ,
            input   var logic               s_rx_valid              ,
            output  var logic               s_rx_ready              ,

            output  var logic               m_tx_first              ,
            output  var logic               m_tx_last               ,
            output  var logic   [7:0]       m_tx_data               ,
            output  var logic               m_tx_valid              ,
            input   var logic               m_tx_ready              ,


            output  var logic               payload_setup           ,
            output  var logic   [15:0]      m_payload_rx_index      ,
            output  var logic               m_payload_rx_first      ,
            output  var logic               m_payload_rx_last       ,
            output  var logic   [7:0]       m_payload_rx_data       ,
            output  var logic               m_payload_rx_valid      ,
            input   var logic   [7:0]       s_payload_tx_data       ,
            input   var logic               s_payload_tx_valid      ,
            output  var logic               s_payload_tx_ready    
        );

    // Handshake
    logic       local_cke;
    assign local_cke  = !m_tx_valid || m_tx_ready;

    assign s_rx_ready = local_cke;


    // payload
    assign payload_setup      = s_rx_valid && s_rx_ready && s_rx_payload_setup & local_cke;
    assign m_payload_rx_index = s_rx_index                                  ;
    assign m_payload_rx_first = s_rx_payload_first                          ;
    assign m_payload_rx_last  = s_rx_payload_last                           ;
    assign m_payload_rx_data  = s_rx_data                                   ;
    assign m_payload_rx_valid = s_rx_valid && s_rx_payload & local_cke      ;

    // delay
    logic   [1:0]       dly_index       ;
    logic               dly_mac_dst     ;
    logic               dly_mac_src     ;
    logic               dly_mac_type    ;
    logic               dly_node        ;
    logic               dly_type        ;
    logic               dly_length      ;
    logic               dly_payload     ;
    logic               dly_fcs         ;
    logic               dly_crc_first   ;
    logic               dly_first       ;
    logic               dly_last        ;
    logic   [7:0]       dly_data        ;
    logic               dly_valid       ;
    jelly2_data_delay
            #(
                .LATENCY                (PAYLOAD_LATENCY    ),
                .DATA_WIDTH             (2+11+8             )
            )
        u_data_delay
            (
                .reset                  (reset              ),
                .clk                    (clk                ),
                .cke                    (cke & local_cke    ),

                .s_data                 ({
                                            s_rx_index[1:0] ,
                                            s_rx_mac_dst    ,
                                            s_rx_mac_src    ,
                                            s_rx_mac_type   ,
                                            s_rx_node       ,
                                            s_rx_type       ,
                                            s_rx_length     ,
                                            s_rx_payload    ,
                                            s_rx_fcs        ,
                                            s_rx_crc_first  ,
                                            s_rx_first      ,
                                            s_rx_last       ,
                                            s_rx_data         
                                        }),
                .s_valid                (s_rx_valid         ),
                .s_ready                (                   ),

                .m_data                 ({
                                            dly_index       ,
                                            dly_mac_dst     ,
                                            dly_mac_src     ,
                                            dly_mac_type    ,
                                            dly_node        ,
                                            dly_type        ,
                                            dly_length      ,
                                            dly_payload     ,
                                            dly_fcs         ,
                                            dly_crc_first   ,
                                            dly_first       ,
                                            dly_last        ,
                                            dly_data        
                                        }),
                .m_valid                (dly_valid          ),
                .m_ready                (1'b1               )
            );

    assign s_payload_tx_ready = dly_payload && dly_valid && local_cke;

    
    // formatting
    logic               reg_param_set_mac_dst   ;
    logic               reg_param_set_mac_src   ;
    logic               reg_param_set_mac_type  ;
    logic   [5:0][7:0]  reg_tx_mac_dst          ;
    logic   [5:0][7:0]  reg_tx_mac_src          ;
    logic   [15:0]      reg_tx_mac_type         ;

    logic   [1:0]       fmt_index               ;
    logic               fmt_mac_dst             ;
    logic               fmt_mac_src             ;
    logic               fmt_mac_type            ;
    logic               fmt_payload             ;
    logic               fmt_fcs                 ;
    logic               fmt_crc_first           ;
    logic               fmt_first               ;
    logic               fmt_last                ;
    logic   [7:0]       fmt_data                ;
    logic               fmt_valid               ;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_param_set_mac_dst   <= 'x;
            reg_param_set_mac_src   <= 'x;
            reg_param_set_mac_type  <= 'x;
            reg_tx_mac_dst          <= 'x;
            reg_tx_mac_src          <= 'x;
            reg_tx_mac_type         <= 'x;
            fmt_index               <= 'x;
            fmt_mac_dst             <= 'x;
            fmt_mac_src             <= 'x;
            fmt_mac_type            <= 'x;
            fmt_payload             <= 'x;
            fmt_fcs                 <= 'x;
            fmt_crc_first           <= 'x;
            fmt_first               <= 'x;
            fmt_last                <= 'x;
            fmt_data                <= 'x;
            fmt_valid               <= 1'b0;
        end
        else if ( cke & local_cke ) begin
            // parameters
            if ( packet_start ) begin
                reg_param_set_mac_dst  <= param_set_mac_dst ;
                reg_param_set_mac_src  <= param_set_mac_src ;
                reg_param_set_mac_type <= param_set_mac_type;
                reg_tx_mac_dst         <= tx_mac_dst ;
                reg_tx_mac_src         <= tx_mac_src ;
                reg_tx_mac_type        <= tx_mac_type;
            end
            if ( fmt_mac_dst  ) begin reg_tx_mac_dst  <= (reg_tx_mac_dst  << 8); end
            if ( fmt_mac_src  ) begin reg_tx_mac_src  <= (reg_tx_mac_src  << 8); end
            if ( fmt_mac_type ) begin reg_tx_mac_type <= (reg_tx_mac_type << 8); end

            // bypass
            fmt_index     <= dly_index      ;
            fmt_mac_dst   <= dly_mac_dst    ;
            fmt_mac_src   <= dly_mac_src    ;
            fmt_mac_type  <= dly_mac_type   ;
            fmt_payload   <= dly_payload    ;
            fmt_fcs       <= dly_fcs        ;
            fmt_crc_first <= dly_crc_first  ;
            fmt_first     <= dly_first      ;
            fmt_last      <= dly_last       ;
            fmt_data      <= dly_data       ;
            fmt_valid     <= dly_valid      ;

            // replace
            if ( dly_mac_dst  && reg_param_set_mac_dst  ) begin fmt_data <= reg_tx_mac_dst[5];                    end
            if ( dly_mac_src  && reg_param_set_mac_src  ) begin fmt_data <= reg_tx_mac_src[5];                    end
            if ( dly_mac_type && reg_param_set_mac_type ) begin fmt_data <= reg_tx_mac_type[15:8];                end
            if ( dly_node                               ) begin fmt_data <= dly_data + 8'(NODE_ADD);              end
            if ( dly_type                               ) begin fmt_data <= (dly_data & TYPE_MASK) | TYPE_BIT;    end
            if ( dly_payload  && s_payload_tx_valid     ) begin fmt_data <= s_payload_tx_data;                    end
        end
    end


    // set FCS
    jelly2_ether_fcs_set
            #(
                .DEBUG                  (DEBUG          ),
                .SIMULATION             (SIMULATION     )
            )
        u_necolink_packet_fcs_set
            (
                .reset                  (reset          ),
                .clk                    (clk            ),
                .cke                    (cke & local_cke),
    
                .s_packet_index         (fmt_index      ),
                .s_packet_fcs           (fmt_fcs        ),
                .s_packet_crc_start     (fmt_crc_first  ),
                .s_packet_first         (fmt_first      ),
                .s_packet_last          (fmt_last       ),
                .s_packet_data          (fmt_data       ),
                .s_packet_valid         (fmt_valid      ),
                .s_packet_ready         (),
    
                .m_packet_first         (m_tx_first     ),
                .m_packet_last          (m_tx_last      ),
                .m_packet_data          (m_tx_data      ),
                .m_packet_valid         (m_tx_valid     ),
                .m_packet_ready         (1'b1           )
            );

endmodule


`default_nettype wire


// end of file
