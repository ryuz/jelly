
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter bit          DEBUG        = 1'b0,
            parameter bit          SIMULATION   = 1'b0
        )
        (
            input   wire        reset,
            input   wire        clk
        );

    localparam  bit  RAND = 0;

    logic               cke                   ;

    logic               start                 ;

    logic               m_tx_first            ;
    logic               m_tx_last             ;
    logic   [7:0]       m_tx_data             ;
    logic               m_tx_valid            ;
    logic               m_tx_ready            ;

    logic               param_mac_enable      ;
    logic   [5:0][7:0]  tx_mac_dst            ;
    logic   [5:0][7:0]  tx_mac_src            ;
    logic   [15:0]      tx_mac_type           ;
    logic   [7:0]       tx_node               ;
    logic   [7:0]       tx_type               ;
    logic   [15:0]      tx_length             ;

    logic               process_busy          ;
    logic               process_initial       ;
    logic               process_final         ;

    logic               payload_setup         ;
    logic   [15:0]      m_payload_rx_index    ;
    logic               m_payload_rx_first    ;
    logic               m_payload_rx_last     ;
    logic   [7:0]       m_payload_rx_data     ;
    logic               m_payload_rx_valid    ;
    logic   [7:0]       s_payload_tx_data     ;
    logic               s_payload_tx_valid    ;
    logic               s_payload_tx_ready    ;

    jelly2_necolink_packet_master
            #(
                .DEBUG              (DEBUG              ),
                .SIMULATION         (SIMULATION         )
            )
        i_necolink_packet_master
            (
                .reset              (reset              ),
                .clk                (clk                ),
                .cke                (cke                ),

                .start              (start              ),

                .m_tx_first         (m_tx_first         ),
                .m_tx_last          (m_tx_last          ),
                .m_tx_data          (m_tx_data          ),
                .m_tx_valid         (m_tx_valid         ),
                .m_tx_ready         (m_tx_ready         ),

                .param_mac_enable   (param_mac_enable   ),

                .tx_mac_dst         (tx_mac_dst         ),
                .tx_mac_src         (tx_mac_src         ),
                .tx_mac_type        (tx_mac_type        ),
                .tx_node            (tx_node            ),
                .tx_type            (tx_type            ),
                .tx_length          (tx_length          ),


                .process_busy       (process_busy       ),
                .process_initial    (process_initial    ),
                .process_final      (process_final      ),

                .payload_setup      (payload_setup      ),
                .m_payload_rx_index (m_payload_rx_index ),
                .m_payload_rx_first (m_payload_rx_first ),
                .m_payload_rx_last  (m_payload_rx_last  ),
                .m_payload_rx_data  (m_payload_rx_data  ),
                .m_payload_rx_valid (m_payload_rx_valid ),
                .s_payload_tx_data  (s_payload_tx_data  ),
                .s_payload_tx_valid (s_payload_tx_valid ),
                .s_payload_tx_ready (s_payload_tx_ready )
            );

    int     cycle;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            cycle <= 0;
        end
        else if ( cke ) begin
            cycle <= cycle + 1;
        end
    end

    always_ff @(posedge clk) begin
        cke <= RAND ? 1'({$random}) : 1'b1;
    end

    assign start             = (cycle[9:0] == 10'd2);

    assign param_mac_enable  = cycle[10];
    assign tx_mac_dst        = 48'hff_ff_ff_ff_ff_ff;
    assign tx_mac_src        = 48'h00_00_0c_00_53_00;
    assign tx_mac_type       = 16'h8000;
    assign tx_node           = 8'h01;
    assign tx_type           = 8'h12;
    assign tx_length         = 16'h000f;

    always_ff @(posedge clk) begin
        if ( start ) begin
            s_payload_tx_data <= 8'h00;
        end
        else if ( cke ) begin
            if ( s_payload_tx_ready ) begin
                s_payload_tx_data <= s_payload_tx_data + 1'b1;
            end
        end
    end
    assign s_payload_tx_valid   = 1'b1;

    logic   rx_ready;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            rx_ready <= RAND ? 1'({$random}) : 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            if ( m_tx_valid && m_tx_ready ) begin
                $write("%02x ", m_tx_data);
                if ( m_tx_last ) begin
                    $write("\n");
                end
            end
        end
    end


    // Receive
    jelly2_necolink_packet_slave
            #(
                .PAYLOAD_LATENCY        (2          ),
                .NODE_ADD               (1          ),
                .TYPE_BIT               (8'h80      ),
                .TYPE_MASK              (8'hff      ),
                .DEBUG                  (DEBUG      ),
                .SIMULATION             (SIMULATION )
            )
        u_necolink_packet_slave0
            (
                .reset                  (reset              ),
                .clk                    (clk                ),
                .cke                    (cke                ),

                .s_rx_first             (m_tx_first         ),
                .s_rx_last              (m_tx_last          ),
                .s_rx_data              (m_tx_data          ),
                .s_rx_valid             (m_tx_valid         ),
                .s_rx_ready             (m_tx_ready         ),

                .m_tx_first             (),
                .m_tx_last              (),
                .m_tx_data              (),
                .m_tx_valid             (),
                .m_tx_ready             (rx_ready),

                .rx_mac_dst             (),
                .rx_mac_src             (),
                .rx_mac_type            (),
                .rx_node                (),
                .rx_type                (),
                .rx_length              (),

                .param_mac_enable       (param_mac_enable   ),
                .param_set_mac_dst      (1'b1               ),
                .param_set_mac_src      (1'b1               ),
                .param_set_mac_type     (1'b1               ),

                .tx_mac_dst             (48'h112233445566   ),
                .tx_mac_src             (48'h778899aabbcc   ),
                .tx_mac_type            (16'h1234           ),

                .process_busy           (),
                .process_initial        (),
                .process_final          (),
                .process_fail           (),

                .payload_setup          (),
                .m_payload_rx_index     (),
                .m_payload_rx_first     (),
                .m_payload_rx_last      (),
                .m_payload_rx_data      (),
                .m_payload_rx_valid     (),
                .s_payload_tx_data      (),
                .s_payload_tx_valid     (),
                .s_payload_tx_ready     ()
            );


endmodule


`default_nettype wire


// end of file
