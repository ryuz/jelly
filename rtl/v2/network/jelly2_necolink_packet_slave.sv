// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_packet_slave
        #(
            parameter int           PAYLOAD_LATENCY = 1,
            parameter int           NODE_ADD        = 1,
            parameter bit   [7:0]   TYPE_BIT        = 8'h00,
            parameter bit   [7:0]   TYPE_MASK       = 8'hff,
            parameter bit           DEBUG           = 1'b0,
            parameter bit           SIMULATION      = 1'b0
        )
        (
            input   var logic               reset                   ,
            input   var logic               clk                     ,
            input   var logic               cke                     ,

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

            output  var logic   [7:0]       parse_data              ,
            output  var logic               parse_type              ,
            output  var logic               parse_node              ,
            output  var logic               parse_valid             ,
            
            output  var logic   [5:0][7:0]  rx_mac_dst              ,
            output  var logic   [5:0][7:0]  rx_mac_src              ,
            output  var logic   [15:0]      rx_mac_type             ,
            output  var logic   [7:0]       rx_node                 ,
            output  var logic   [7:0]       rx_type                 ,
            output  var logic   [15:0]      rx_length               ,

            input   var logic               param_mac_enable        ,
            input   var logic               param_set_mac_dst       ,
            input   var logic               param_set_mac_src       ,
            input   var logic               param_set_mac_type      ,

            input   var logic   [5:0][7:0]  tx_mac_dst              ,
            input   var logic   [5:0][7:0]  tx_mac_src              ,
            input   var logic   [15:0]      tx_mac_type             ,

            output  var logic               packet_start            ,
            output  var logic               packet_finish           ,
            output  var logic               packet_fail             ,

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
    assign local_cke = !m_tx_valid || m_tx_ready;


    assign s_rx_ready = local_cke;



    // packet parser
    logic   [15:0]      packet_index        ;
    logic               packet_mac_dst      ;
    logic               packet_mac_src      ;
    logic               packet_mac_type     ;
    logic               packet_node         ;
    logic               packet_type         ;
    logic               packet_length       ;
    logic               packet_payload_setup;
    logic               packet_payload_first;
    logic               packet_payload_last ;
    logic               packet_payload      ;
    logic               packet_fcs_first    ;
    logic               packet_fcs_last     ;
    logic               packet_fcs          ;
    logic               packet_crc_first    ;
    logic               packet_crc_last     ;
    logic               packet_crc          ;
    logic               packet_first        ;
    logic               packet_last         ;
    logic   [7:0]       packet_data         ;
    logic               packet_valid        ;

    jelly2_necolink_packet_parser
            #(
                .DEBUG                  (DEBUG                  ),
                .SIMULATION             (SIMULATION             )
            )   
        u_necolink_packet_parser
            (   
                .reset                  (reset                  ),
                .clk                    (clk                    ),
                .cke                    (cke && local_cke       ),

                .busy                   (                       ),

                .param_mac_enable       (param_mac_enable       ),

                .s_packet_first         (s_rx_first             ),
                .s_packet_last          (s_rx_last              ),
                .s_packet_data          (s_rx_data              ),
                .s_packet_valid         (s_rx_valid             ),
                .s_packet_ready         (                       ),
    
                .m_packet_index         (packet_index           ),
                .m_packet_mac_dst       (packet_mac_dst         ),
                .m_packet_mac_src       (packet_mac_src         ),
                .m_packet_mac_type      (packet_mac_type        ),
                .m_packet_node          (packet_node            ),
                .m_packet_type          (packet_type            ),
                .m_packet_length        (packet_length          ),
                .m_packet_payload_setup (packet_payload_setup   ),
                .m_packet_payload_first (packet_payload_first   ),
                .m_packet_payload_last  (packet_payload_last    ),
                .m_packet_payload       (packet_payload         ),
                .m_packet_fcs_first     (packet_fcs_first       ),
                .m_packet_fcs_last      (packet_fcs_last        ),
                .m_packet_fcs           (packet_fcs             ),
                .m_packet_crc_first     (packet_crc_first       ),
                .m_packet_crc_last      (packet_crc_last        ),
                .m_packet_crc           (packet_crc             ),
                .m_packet_first         (packet_first           ),
                .m_packet_last          (packet_last            ),
                .m_packet_data          (packet_data            ),
                .m_packet_valid         (packet_valid           ),
                .m_packet_ready         (1'b1                   ),

                .packet_start           (packet_start           ),
                .packet_finish          (packet_finish          ),
                .packet_fail            (packet_fail            ),

                .rx_mac_dst             (rx_mac_dst             ),
                .rx_mac_src             (rx_mac_src             ),
                .rx_mac_type            (rx_mac_type            ),
                .rx_node                (rx_node                ),
                .rx_type                (rx_type                ),
                .rx_length              (rx_length              )
            );

    assign parse_data  = packet_data ;
    assign parse_type  = packet_type ;
    assign parse_node  = packet_node ;
    assign parse_valid = packet_valid;
    
    // processing
    jelly2_necolink_packet_processor
        #(
                .PAYLOAD_LATENCY        (PAYLOAD_LATENCY     ),
                .NODE_ADD               (NODE_ADD            ),
                .TYPE_BIT               (TYPE_BIT            ),
                .TYPE_MASK              (TYPE_MASK           ),
                .DEBUG                  (DEBUG               ),
                .SIMULATION             (SIMULATION          )
            ) 
        u_necolink_packet_processor
            ( 
                .reset                  (reset               ),
                .clk                    (clk                 ),
                .cke                    (cke & local_cke     ),

                .packet_start           (packet_start        ),
                .packet_fail            (packet_fail         ),
                .packet_finish          (packet_finish       ),

                .param_mac_enable       (param_mac_enable    ),
                .param_set_mac_dst      (param_set_mac_dst   ),
                .param_set_mac_src      (param_set_mac_src   ),
                .param_set_mac_type     (param_set_mac_type  ),
                .tx_mac_dst             (tx_mac_dst          ),
                .tx_mac_src             (tx_mac_src          ),
                .tx_mac_type            (tx_mac_type         ),

                .s_rx_index             (packet_index        ),
                .s_rx_mac_dst           (packet_mac_dst      ),
                .s_rx_mac_src           (packet_mac_src      ),
                .s_rx_mac_type          (packet_mac_type     ),
                .s_rx_node              (packet_node         ),
                .s_rx_type              (packet_type         ),
                .s_rx_length            (packet_length       ),
                .s_rx_payload_setup     (packet_payload_setup),
                .s_rx_payload_first     (packet_payload_first),
                .s_rx_payload_last      (packet_payload_last ),
                .s_rx_payload           (packet_payload      ),
                .s_rx_fcs_first         (packet_fcs_first    ),
                .s_rx_fcs_last          (packet_fcs_last     ),
                .s_rx_fcs               (packet_fcs          ),
                .s_rx_crc_first         (packet_crc_first    ),
                .s_rx_crc_last          (packet_crc_last     ),
                .s_rx_crc               (packet_crc          ),
                .s_rx_first             (packet_first        ),
                .s_rx_last              (packet_last         ),
                .s_rx_data              (packet_data         ),
                .s_rx_valid             (packet_valid        ),
                .s_rx_ready             (                    ),

                .m_tx_first             (m_tx_first          ),
                .m_tx_last              (m_tx_last           ),
                .m_tx_data              (m_tx_data           ),
                .m_tx_valid             (m_tx_valid          ),
                .m_tx_ready             (1'b1                ),


                .payload_setup          (payload_setup       ),
                .m_payload_rx_index     (m_payload_rx_index  ),
                .m_payload_rx_first     (m_payload_rx_first  ),
                .m_payload_rx_last      (m_payload_rx_last   ),
                .m_payload_rx_data      (m_payload_rx_data   ),
                .m_payload_rx_valid     (m_payload_rx_valid  ), 
                .s_payload_tx_data      (s_payload_tx_data   ),
                .s_payload_tx_valid     (s_payload_tx_valid  ),
                .s_payload_tx_ready     (s_payload_tx_ready  )
            );
    

endmodule


`default_nettype wire


// end of file
