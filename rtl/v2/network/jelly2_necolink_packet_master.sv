
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_packet_master
        #(
            parameter int   unsigned    PAYLOAD_LATENCY = 1,
            parameter bit               DEBUG           = 1'b0,
            parameter bit               SIMULATION      = 1'b0
        )
        (
            input   var logic               reset                   ,
            input   var logic               clk                     ,
            input   var logic               cke                     ,

            input   var logic               start                   ,

            output  var logic               m_tx_first              ,
            output  var logic               m_tx_last               ,
            output  var logic   [7:0]       m_tx_data               ,
            output  var logic               m_tx_valid              ,
            input   var logic               m_tx_ready              ,


            input   var logic               param_mac_enable        ,

            input   var logic   [5:0][7:0]  tx_mac_dst              ,
            input   var logic   [5:0][7:0]  tx_mac_src              ,
            input   var logic   [15:0]      tx_mac_type             ,
            input   var logic   [7:0]       tx_node                 ,
            input   var logic   [7:0]       tx_type                 ,
            input   var logic   [15:0]      tx_length               ,

            output  var logic               packet_start            ,
            output  var logic               packet_finish           ,

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


    // packet generator
    logic               packet_start_0       ;
    logic               packet_finish_0      ;

    logic   [15:0]      packet_index         ;
    logic               packet_mac_dst       ;
    logic               packet_mac_src       ;
    logic               packet_mac_type      ;
    logic               packet_node          ;
    logic               packet_type          ;
    logic               packet_length        ;
    logic               packet_payload_setup ;
    logic               packet_payload_first ;
    logic               packet_payload_last  ;
    logic               packet_payload       ;
    logic               packet_fcs_first     ;
    logic               packet_fcs_last      ;
    logic               packet_fcs           ;
    logic               packet_crc_first     ;
    logic               packet_crc_last      ;
    logic               packet_crc           ;
    logic               packet_first         ;
    logic               packet_last          ;
    logic   [7:0]       packet_data          ;
    logic               packet_valid         ;

    jelly2_necolink_packet_generator
            #(
                .DEBUG                  (DEBUG                  ),
                .SIMULATION             (SIMULATION             )
            )   
        u_necolink_packet_generator 
            (   
                .reset                  (reset                  ),
                .clk                    (clk                    ),
                .cke                    (cke & local_cke        ),

                .start                  (start                  ),
                .busy                   (                       ),

                .param_mac_enable       (param_mac_enable       ),
                .param_node             (tx_node                ),
                .param_type             (tx_type                ),
                .param_length           (tx_length              ),

                .packet_start           (packet_start_0         ),
                .packet_finish          (packet_finish_0        ),

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
                .m_packet_fcs           (packet_fcs             ),
                .m_packet_fcs_first     (packet_fcs_first       ),
                .m_packet_fcs_last      (packet_fcs_last        ),
                .m_packet_crc           (packet_crc             ),
                .m_packet_crc_first     (packet_crc_first       ),
                .m_packet_crc_last      (packet_crc_last        ),
                .m_packet_first         (packet_first           ),
                .m_packet_last          (packet_last            ),
                .m_packet_data          (packet_data            ),
                .m_packet_valid         (packet_valid           ),
                .m_packet_ready         (1'b1                   )
        );


    // processing
    logic               payload_setup_0     ;
    logic   [15:0]      payload_rx_index    ;
    logic               payload_rx_first    ;
    logic               payload_rx_last     ;
    logic   [7:0]       payload_rx_data     ;
    logic               payload_rx_valid    ;
    logic   [7:0]       payload_tx_data     ;
    logic               payload_tx_valid    ;
    logic               payload_tx_ready    ;
    jelly2_necolink_packet_processor
            #(
                .PAYLOAD_LATENCY        (PAYLOAD_LATENCY     ),
                .NODE_ADD               (1                   ),
                .TYPE_BIT               (8'h00               ),
                .TYPE_MASK              (8'hff               ),
                .DEBUG                  (DEBUG               ),
                .SIMULATION             (SIMULATION          )
            )
        i_necolink_packet_processor
            ( 
                .reset                  (reset               ),
                .clk                    (clk                 ),
                .cke                    (cke & local_cke     ),

                .packet_start           (packet_start_0      ),
                .packet_finish          (packet_finish_0     ),
                .packet_fail            (1'b0                ),

                .param_mac_enable       (param_mac_enable    ),
                .param_set_mac_dst      (1'b1                ),
                .param_set_mac_src      (1'b1                ),
                .param_set_mac_type     (1'b1                ),
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
                
                .payload_setup          (payload_setup_0    ),
                .m_payload_rx_index     (payload_rx_index   ),
                .m_payload_rx_first     (payload_rx_first   ),
                .m_payload_rx_last      (payload_rx_last    ),
                .m_payload_rx_data      (payload_rx_data    ),
                .m_payload_rx_valid     (payload_rx_valid   ),
                .s_payload_tx_data      (payload_tx_data    ),
                .s_payload_tx_valid     (payload_tx_valid   ),
                .s_payload_tx_ready     (payload_tx_ready   )
            );

    assign  packet_start        = packet_start_0    & local_cke ;
    assign  packet_finish       = packet_finish_0   & local_cke ;
    assign  payload_setup       = payload_setup_0   & local_cke ;
    assign  m_payload_rx_index  = payload_rx_index              ;
    assign  m_payload_rx_first  = payload_rx_first              ;
    assign  m_payload_rx_last   = payload_rx_last               ;
    assign  m_payload_rx_data   = payload_rx_data               ;
    assign  m_payload_rx_valid  = payload_rx_valid  & local_cke ;
    assign  payload_tx_data     = s_payload_tx_data             ;
    assign  payload_tx_valid    = s_payload_tx_valid            ;
    assign  s_payload_tx_ready  = payload_tx_ready  & local_cke ;

endmodule


`default_nettype wire 

// end of file
