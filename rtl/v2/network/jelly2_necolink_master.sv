

// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_master
        #(
            parameter   int unsigned    MAX_NODES               = 4                         ,
            localparam  int unsigned    MAX_SLAVES              = MAX_NODES - 1             ,
            parameter   int unsigned    TIMER_WIDTH             = 64                        ,   // タイマのbit幅
            parameter   bit             EXTERNAL_TIMER          = 1'b0                      ,   // 外部タイマ利用
            parameter   int unsigned    NUMERATOR               = 8                         ,   // クロック周期の分子
            parameter   int unsigned    DENOMINATOR             = 1                         ,   // クロック周期の分母
            parameter   int unsigned    SYNCTIM_OFFSET_WIDTH    = 24                        ,   // オフセットbit幅
            parameter   int unsigned    SYNCTIM_OFFSET_LPF_GAIN = 4                         ,   // オフセット更新LPFのゲイン (1/2^N)
            parameter   int unsigned    GPIO_GLOBAL_BYTES       = 4                         ,
            parameter   int unsigned    GPIO_LOCAL_OFFSET       = GPIO_GLOBAL_BYTES         ,
            parameter   int unsigned    GPIO_LOCAL_BYTES        = 4                         ,
            parameter   int unsigned    GPIO_FULL_BYTES         = GPIO_GLOBAL_BYTES + GPIO_LOCAL_BYTES * MAX_SLAVES,
            parameter   int unsigned    MESSAGE_BYTES           = 64                        ,
            parameter                   MESSAGE_BUF_RAM_TYPE    = "distributed"             ,
            parameter   bit             DEBUG                   = 1'b0                      ,
            parameter   bit             SIMULATION              = 1'b1  
        )
        (
            input   var logic                                   reset                       ,
            input   var logic                                   clk                         ,
            input   var logic                                   cke                         ,

            input   var logic   [TIMER_WIDTH-1:0]               external_time               ,
            output  var logic   [TIMER_WIDTH-1:0]               current_time                ,

            output  var logic   [7:0]                           node_self                   ,
            output  var logic   [7:0]                           node_last                   ,
            output  var logic                                   network_looped              ,

            input   var logic                                   param_mac_enable            ,
            input   var logic                                   param_set_mac_addr_self     ,
            input   var logic                                   param_set_mac_addr_up       ,
            input   var logic   [5:0][7:0]                      param_mac_addr_self         ,
            input   var logic   [5:0][7:0]                      param_mac_addr_down         ,
            input   var logic   [5:0][7:0]                      param_mac_addr_up           ,
            input   var logic   [15:0]                          param_mac_type_down         ,
            input   var logic   [15:0]                          param_mac_type_up           ,

            input   var logic   [GPIO_FULL_BYTES-1:0][7:0]      gpio_tx_full_data           ,
            output  var logic                                   gpio_tx_full_accepted       ,
            output  var logic   [GPIO_FULL_BYTES-1:0][7:0]      m_gpio_res_full_data        ,
            output  var logic                                   m_gpio_res_valid            ,

            input   var logic   [7:0]                           s_msg_outer_tx_dst_node     ,
            input   var logic   [7:0]                           s_msg_outer_tx_data         ,
            input   var logic                                   s_msg_outer_tx_valid        ,
            output  var logic                                   s_msg_outer_tx_ready        ,
            output  var logic                                   m_msg_outer_rx_first        ,
            output  var logic                                   m_msg_outer_rx_last         ,
            output  var logic   [7:0]                           m_msg_outer_rx_src_node     ,
            output  var logic   [7:0]                           m_msg_outer_rx_data         ,
            output  var logic                                   m_msg_outer_rx_valid        ,
            input   var logic   [7:0]                           s_msg_inner_tx_dst_node     ,
            input   var logic   [7:0]                           s_msg_inner_tx_data         ,
            input   var logic                                   s_msg_inner_tx_valid        ,
            output  var logic                                   s_msg_inner_tx_ready        ,
            output  var logic                                   m_msg_inner_rx_first        ,
            output  var logic                                   m_msg_inner_rx_last         ,
            output  var logic   [7:0]                           m_msg_inner_rx_src_node     ,
            output  var logic   [7:0]                           m_msg_inner_rx_data         ,
            output  var logic                                   m_msg_inner_rx_valid        ,

            output  var logic                                   m_up_tx_first               ,
            output  var logic                                   m_up_tx_last                ,
            output  var logic   [7:0]                           m_up_tx_data                ,
            output  var logic                                   m_up_tx_valid               ,
            input   var logic                                   m_up_tx_ready               ,
            input   var logic                                   s_up_rx_first               ,
            input   var logic                                   s_up_rx_last                ,
            input   var logic   [7:0]                           s_up_rx_data                ,
            input   var logic                                   s_up_rx_valid               ,

            output  var logic                                   m_down_tx_first             ,
            output  var logic                                   m_down_tx_last              ,
            output  var logic   [7:0]                           m_down_tx_data              ,
            output  var logic                                   m_down_tx_valid             ,
            input   var logic                                   m_down_tx_ready             ,
            input   var logic                                   s_down_rx_first             ,
            input   var logic                                   s_down_rx_last              ,
            input   var logic   [7:0]                           s_down_rx_data              ,
            input   var logic                                   s_down_rx_valid             
        );


    // -------------------------------------
    //  Parameters
    // -------------------------------------

    // Packet Type
    localparam  bit     [7:0]   PACKET_TYPE_GPIO      = 8'h04;
    localparam  bit     [7:0]   PACKET_TYPE_SYNCTIM   = 8'h20;
    localparam  bit     [7:0]   PACKET_TYPE_MESSAGE   = 8'h22;

    // Payload Length (Set 1 less value)
    localparam  bit     [15:0]  PACKET_LENGTH_GPIO    = 16'(GPIO_FULL_BYTES        - 1);
    localparam  bit     [15:0]  PACKET_LENGTH_SYNCTIM = 16'(1 + 8 + 4 * MAX_SLAVES - 1);
    localparam  bit     [15:0]  PACKET_LENGTH_MESSAGE = 16'(2 + MESSAGE_BYTES      - 1);



    // -------------------------------------
    //  Scheduler
    // -------------------------------------
    
    logic                       packet_start    ;
    logic   [7:0]               sender_type     ;
    logic   [15:0]              sender_length   ;

    jelly2_necolink_scheduler
            #(
                .TIMER_WIDTH            (24                     ),
                .SYNCTIM_INTERVAL_WIDTH (8                      ),
                .DEBUG                  (1'b0                   ),
                .SIMULATION             (1'b1                   )
            )               
        u_necolink_scheduler    
            (               
                .reset                  (reset                  ),
                .clk                    (clk                    ),
                .cke                    (cke                    ),

                .current_time           (current_time[23:0]     ),

                .enable                 (1'b1                   ),
                .busy                   (                       ),

                .param_start_time_en    (1'b1                   ),
                .param_start_time       (24'd0                  ),
                .param_period_gpio      (24'd20000              ),
                .param_period_message   (24'd30000              ),
                .param_interval_synctim (4-1                    ),

                .param_gpio_type        (PACKET_TYPE_GPIO       ),
                .param_gpio_length      (PACKET_LENGTH_GPIO     ),
                .param_synctim_type     (PACKET_TYPE_SYNCTIM    ),
                .param_synctim_length   (PACKET_LENGTH_SYNCTIM  ),
                .param_message_type     (PACKET_TYPE_MESSAGE    ),
                .param_message_length   (PACKET_LENGTH_MESSAGE  ),

                .packet_start           (packet_start           ),
                .packet_type            (sender_type            ),
                .packet_length          (sender_length          )
            );



    // -------------------------------------
    //  Ring bus
    // -------------------------------------

    localparam  int PAYLOAD_LATENCY = 1;

    // Sender (Outer loop)
    logic           sender_start;
    logic           sender_finish;

    logic           sender_payload_setup     ;
    logic   [15:0]  sender_payload_rx_index  ;
    logic           sender_payload_rx_first  ;
    logic           sender_payload_rx_last   ;
    logic   [7:0]   sender_payload_rx_data   ;
    logic           sender_payload_rx_valid  ;
    logic           sender_payload_rx_ready  ;
    logic   [7:0]   sender_payload_tx_data   ;
    logic           sender_payload_tx_valid  ;
    logic           sender_payload_tx_ready  ;

    jelly2_necolink_packet_master
            #(
                .DEBUG                  (DEBUG                      ),
                .SIMULATION             (SIMULATION                 )
            )
        u_necolink_packet_master_sender
            (
                .reset                  (reset                      ),
                .clk                    (clk                        ),
                .cke                    (cke                        ),

                .start                  (packet_start               ),

                .param_mac_enable       (param_mac_enable           ),
                .tx_mac_dst             (param_mac_addr_down        ),
                .tx_mac_src             (param_mac_addr_self        ),
                .tx_mac_type            (param_mac_type_down        ),
                .tx_node                (node_self                  ),
                .tx_type                (sender_type                ),
                .tx_length              (sender_length              ),

                .m_tx_first             (m_down_tx_first            ),
                .m_tx_last              (m_down_tx_last             ),
                .m_tx_data              (m_down_tx_data             ),
                .m_tx_valid             (m_down_tx_valid            ),
                .m_tx_ready             (m_down_tx_ready            ),

                .packet_start           (sender_start               ),
                .packet_finish          (sender_finish              ),
                .payload_setup          (sender_payload_setup       ),

                .m_payload_rx_index     (sender_payload_rx_index    ),
                .m_payload_rx_first     (sender_payload_rx_first    ),
                .m_payload_rx_last      (sender_payload_rx_last     ),
                .m_payload_rx_data      (sender_payload_rx_data     ),
                .m_payload_rx_valid     (sender_payload_rx_valid    ),
                .s_payload_tx_data      (sender_payload_tx_data     ),
                .s_payload_tx_valid     (sender_payload_tx_valid    ),
                .s_payload_tx_ready     (sender_payload_tx_ready    )
            );

    logic               sender_enable_gpio      ;
    logic               sender_enable_synctim   ;
    logic               sender_enable_message   ;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( packet_start ) begin
                sender_enable_gpio    <= (sender_type == PACKET_TYPE_GPIO   );
                sender_enable_synctim <= (sender_type == PACKET_TYPE_SYNCTIM);
                sender_enable_message <= (sender_type == PACKET_TYPE_MESSAGE);
            end
        end
    end

    logic               sender_payload_setup_gpio   ;
    logic               sender_payload_setup_synctim;
    logic               sender_payload_setup_message;
    assign  sender_payload_setup_gpio    = sender_payload_setup & sender_enable_gpio   ;
    assign  sender_payload_setup_synctim = sender_payload_setup & sender_enable_synctim;
    assign  sender_payload_setup_message = sender_payload_setup & sender_enable_message;



    // Receiver (Outer loop)
    logic   [5:0][7:0]  receiver_rx_mac_dst        ;
    logic   [5:0][7:0]  receiver_rx_mac_src        ;
    logic   [15:0]      receiver_rx_mac_type       ;
    logic   [7:0]       receiver_rx_node           ;
    logic   [7:0]       receiver_rx_type           ;
    logic   [15:0]      receiver_rx_length         ;

    logic               receiver_parse_node        ;
    logic               receiver_parse_type        ;
    logic   [7:0]       receiver_parse_data        ;
    logic               receiver_parse_valid       ;

    logic               receiver_start             ;
    logic               receiver_finish            ;
    logic               receiver_fail              ;
    
    logic               receiver_payload_setup     ;
    logic   [15:0]      receiver_payload_rx_index  ;
    logic               receiver_payload_rx_first  ;
    logic               receiver_payload_rx_last   ;
    logic   [7:0]       receiver_payload_rx_data   ;
    logic               receiver_payload_rx_valid  ;
    logic   [7:0]       receiver_payload_tx_data   ;
    logic               receiver_payload_tx_valid  ;
    logic               receiver_payload_tx_ready  ;

    jelly2_necolink_packet_slave
            #(
                .PAYLOAD_LATENCY        (PAYLOAD_LATENCY            ),
                .NODE_ADD               (0                          ),
                .TYPE_BIT               (8'h00                      ),
                .TYPE_MASK              (8'hff                      ),
                .DEBUG                  (DEBUG                      ),
                .SIMULATION             (SIMULATION                 )
            )   
        u_necolink_packet_slave_receiver    
            (   
                .reset                  (reset                      ),
                .clk                    (clk                        ),
                .cke                    (cke                        ),

                .s_rx_first             (s_down_rx_first            ),
                .s_rx_last              (s_down_rx_last             ),
                .s_rx_data              (s_down_rx_data             ),
                .s_rx_valid             (s_down_rx_valid            ),
                .s_rx_ready             (                           ),

                .m_tx_first             (                           ),
                .m_tx_last              (                           ),
                .m_tx_data              (                           ),
                .m_tx_valid             (                           ),
                .m_tx_ready             (1'b1                       ),

                .parse_node             (receiver_parse_node        ),
                .parse_type             (receiver_parse_type        ),
                .parse_data             (receiver_parse_data        ),
                .parse_valid            (receiver_parse_valid       ),

                .rx_mac_dst             (receiver_rx_mac_dst        ),
                .rx_mac_src             (receiver_rx_mac_src        ),
                .rx_mac_type            (receiver_rx_mac_type       ),
                .rx_node                (receiver_rx_node           ),
                .rx_type                (receiver_rx_type           ),
                .rx_length              (receiver_rx_length         ),

                .param_mac_enable       (param_mac_enable           ),
                .param_set_mac_dst      ('0                         ),
                .param_set_mac_src      ('0                         ),
                .param_set_mac_type     (1'b0                       ),

                .tx_mac_dst             ('0                         ),
                .tx_mac_src             ('0                         ),
                .tx_mac_type            ('0                         ),

                .packet_start           (receiver_start             ),
                .packet_finish          (receiver_finish            ),
                .packet_fail            (receiver_fail              ),

                .payload_setup          (receiver_payload_setup     ),
                .m_payload_rx_index     (receiver_payload_rx_index  ),
                .m_payload_rx_first     (receiver_payload_rx_first  ),
                .m_payload_rx_last      (receiver_payload_rx_last   ),
                .m_payload_rx_data      (receiver_payload_rx_data   ),
                .m_payload_rx_valid     (receiver_payload_rx_valid  ),
                .s_payload_tx_data      ('0                         ),
                .s_payload_tx_valid     (1'b0                       ),
                .s_payload_tx_ready     () 
            );

    logic               receiver_enable_gpio      ;
    logic               receiver_enable_synctim   ;
    logic               receiver_enable_message   ;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( receiver_parse_valid && receiver_parse_type ) begin
                receiver_enable_gpio    <= (receiver_parse_data == PACKET_TYPE_GPIO   );
                receiver_enable_synctim <= (receiver_parse_data == PACKET_TYPE_SYNCTIM);
                receiver_enable_message <= (receiver_parse_data == PACKET_TYPE_MESSAGE);
            end
        end
    end

//    logic               receiver_payload_setup_gpio   ;
//    logic               receiver_payload_setup_synctim;
//    logic               receiver_payload_setup_message;
//    assign  receiver_payload_setup_gpio    = receiver_payload_setup & receiver_enable_gpio   ;
//    assign  receiver_payload_setup_synctim = receiver_payload_setup & receiver_enable_synctim;
//    assign  receiver_payload_setup_message = receiver_payload_setup & receiver_enable_message;



    // repeater
    logic               repeater_parse_node        ;
    logic               repeater_parse_type        ;
    logic   [7:0]       repeater_parse_data        ;
    logic               repeater_parse_valid       ;

    logic   [5:0][7:0]  repeater_rx_mac_dst        ;
    logic   [5:0][7:0]  repeater_rx_mac_src        ;
    logic   [15:0]      repeater_rx_mac_type       ;
    logic   [7:0]       repeater_rx_node           ;
    logic   [7:0]       repeater_rx_type           ;
    logic   [15:0]      repeater_rx_length         ;

    logic               repeater_start             ;
    logic               repeater_finish            ;
    logic               repeater_fail              ;
    
    logic               repeater_payload_setup     ;
    logic   [15:0]      repeater_payload_rx_index  ;
    logic               repeater_payload_rx_first  ;
    logic               repeater_payload_rx_last   ;
    logic   [7:0]       repeater_payload_rx_data   ;
    logic               repeater_payload_rx_valid  ;
    logic   [7:0]       repeater_payload_tx_data   ;
    logic               repeater_payload_tx_valid  ;
    logic               repeater_payload_tx_ready  ;

    jelly2_necolink_packet_slave
            #(
                .PAYLOAD_LATENCY        (PAYLOAD_LATENCY            ),
                .NODE_ADD               (-1                         ),
                .TYPE_BIT               (8'h00                      ),
                .TYPE_MASK              (8'hff                      ),
                .DEBUG                  (DEBUG                      ),
                .SIMULATION             (SIMULATION                 )
            )   
        u_necolink_packet_slave_repeater
            (   
                .reset                  (reset                      ),
                .clk                    (clk                        ),
                .cke                    (cke                        ),

                .s_rx_first             (s_up_rx_first              ),
                .s_rx_last              (s_up_rx_last               ),
                .s_rx_data              (s_up_rx_data               ),
                .s_rx_valid             (s_up_rx_valid              ),
                .s_rx_ready             (                           ),

                .m_tx_first             (m_up_tx_first              ),
                .m_tx_last              (m_up_tx_last               ),
                .m_tx_data              (m_up_tx_data               ),
                .m_tx_valid             (m_up_tx_valid              ),
                .m_tx_ready             (m_up_tx_ready              ),

                .parse_node             (repeater_parse_node        ),
                .parse_type             (repeater_parse_type        ),
                .parse_data             (repeater_parse_data        ),
                .parse_valid            (repeater_parse_valid       ),

                .rx_mac_dst             (repeater_rx_mac_dst        ),
                .rx_mac_src             (repeater_rx_mac_src        ),
                .rx_mac_type            (repeater_rx_mac_type       ),
                .rx_node                (repeater_rx_node           ),
                .rx_type                (repeater_rx_type           ),
                .rx_length              (repeater_rx_length         ),

                .param_mac_enable       (param_mac_enable           ),
                .param_set_mac_dst      (param_set_mac_addr_up      ),
                .param_set_mac_src      (param_set_mac_addr_self    ),
                .param_set_mac_type     (1'b0                       ),

                .tx_mac_dst             (param_mac_addr_up          ),
                .tx_mac_src             (param_mac_addr_self        ),
                .tx_mac_type            ('0                         ),

                .packet_start           (repeater_start             ),
                .packet_finish          (repeater_finish            ),
                .packet_fail            (repeater_fail              ),

                .payload_setup          (repeater_payload_setup     ),
                .m_payload_rx_index     (repeater_payload_rx_index  ),
                .m_payload_rx_first     (repeater_payload_rx_first  ),
                .m_payload_rx_last      (repeater_payload_rx_last   ),
                .m_payload_rx_data      (repeater_payload_rx_data   ),
                .m_payload_rx_valid     (repeater_payload_rx_valid  ),
                .s_payload_tx_data      (repeater_payload_tx_data   ),
                .s_payload_tx_valid     (repeater_payload_tx_valid  ),
                .s_payload_tx_ready     (repeater_payload_tx_ready  ) 
            );

    logic               repeater_enable_gpio   ;
    logic               repeater_enable_synctim;
    logic               repeater_enable_message;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( receiver_parse_valid && receiver_parse_type ) begin
                repeater_enable_gpio    <= (repeater_parse_data == PACKET_TYPE_GPIO   );
                repeater_enable_synctim <= (repeater_parse_data == PACKET_TYPE_SYNCTIM);
                repeater_enable_message <= (repeater_parse_data == PACKET_TYPE_MESSAGE);
            end
        end
    end

    logic               repeater_payload_setup_gpio   ;
    logic               repeater_payload_setup_synctim;
    logic               repeater_payload_setup_message;
    assign  repeater_payload_setup_gpio    = repeater_payload_setup & repeater_enable_gpio   ;
    assign  repeater_payload_setup_synctim = repeater_payload_setup & repeater_enable_synctim;
    assign  repeater_payload_setup_message = repeater_payload_setup & repeater_enable_message;



    // -------------------------------------
    //  Nodes
    // -------------------------------------

    assign  node_self = 8'h01;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            node_last <= '0;
        end
        else if ( cke ) begin
            if ( receiver_finish ) begin
                node_last      <= {1'b0, receiver_rx_node[6:0]};
                network_looped <= receiver_rx_node[7];
            end
        end
    end



    // -------------------------------------
    //  Functions
    // -------------------------------------


    // GPIO
    logic   [7:0]       gpio_cmd_payload_tx_data ;
    logic               gpio_cmd_payload_tx_valid;
    logic   [7:0]       gpio_res_payload_tx_data ;
    logic               gpio_res_payload_tx_valid;

    jelly2_necolink_gpio
            #(
                .MAX_SLAVES                 (MAX_SLAVES                     ),
                .GLOBAL_BYTES               (GPIO_FULL_BYTES                ),
                .LOCAL_OFFSET               (0                              ),
                .LOCAL_BYTES                (1                              ),
                .FULL_BYTES                 (GPIO_FULL_BYTES                ),
                .DEBUG                      (DEBUG                          ),
                .SIMULATION                 (SIMULATION                     )
            )   
        u_necolink_gpio
            (   
                .reset                      (reset                          ),
                .clk                        (clk                            ),
                .cke                        (cke                            ),

                .tx_global_mask             ('1                             ),
                .tx_global_data             (gpio_tx_full_data              ),
                .tx_local_mask              ('0                             ),
                .tx_local_data              ('0                             ),
                .tx_accepted                (gpio_tx_full_accepted          ),

                .m_rx_global_data           (                               ),
                .m_rx_local_data            (                               ),
                .m_rx_valid                 (                               ),

                .m_res_full_data            (m_gpio_res_full_data           ),
                .m_res_valid                (m_gpio_res_valid               ),
                
                .node_self                  (node_self                      ),

                .cmd_enable                 (sender_enable_gpio             ),
                .cmd_start                  (sender_start                   ),
                .cmd_finish                 (sender_finish                  ),
                .cmd_fail                   (1'b0                           ),
                .cmd_payload_setup          (sender_payload_setup           ),
                .s_cmd_payload_rx_index     (sender_payload_rx_index        ),
                .s_cmd_payload_rx_first     (sender_payload_rx_first        ),
                .s_cmd_payload_rx_last      (sender_payload_rx_last         ),
                .s_cmd_payload_rx_data      (sender_payload_rx_data         ),
                .s_cmd_payload_rx_valid     (sender_payload_rx_valid        ),
                .m_cmd_payload_tx_data      (gpio_cmd_payload_tx_data       ),
                .m_cmd_payload_tx_valid     (gpio_cmd_payload_tx_valid      ),
                .m_cmd_payload_tx_ready     (sender_payload_tx_ready        ),

                .res_enable                 (receiver_enable_gpio           ),
                .res_start                  (receiver_start                 ),
                .res_finish                 (receiver_finish                ),
                .res_fail                   (receiver_fail                  ),
                .res_payload_setup          (receiver_payload_setup         ),
                .s_res_payload_rx_index     (receiver_payload_rx_index      ),
                .s_res_payload_rx_first     (receiver_payload_rx_first      ),
                .s_res_payload_rx_last      (receiver_payload_rx_last       ),
                .s_res_payload_rx_data      (receiver_payload_rx_data       ),
                .s_res_payload_rx_valid     (receiver_payload_rx_valid      ),
                .m_res_payload_tx_data      (gpio_res_payload_tx_data       ),
                .m_res_payload_tx_valid     (gpio_res_payload_tx_valid      ),
                .m_res_payload_tx_ready     (receiver_payload_tx_ready      )
            );


    // sync timer
    logic   [7:0]       synctim_cmd_payload_tx_data ;
    logic               synctim_cmd_payload_tx_valid;
    logic               synctim_cmd_payload_tx_ready;
    logic   [7:0]       synctim_res_payload_tx_data ;
    logic               synctim_res_payload_tx_valid;
    logic               synctim_res_payload_tx_ready;

    jelly2_necolink_synctimer_master
            #(
                .TIMER_WIDTH                (TIMER_WIDTH                    ),
                .EXTERNAL_TIMER             (EXTERNAL_TIMER                 ),
                .NUMERATOR                  (NUMERATOR                      ),
                .DENOMINATOR                (DENOMINATOR                    ),
                .MAX_NODES                  (MAX_NODES                      ),
                .OFFSET_WIDTH               (SYNCTIM_OFFSET_WIDTH           ),
                .OFFSET_LPF_GAIN            (SYNCTIM_OFFSET_LPF_GAIN        ),
                .DEBUG                      (DEBUG                          ),
                .SIMULATION                 (SIMULATION                     )
            )           
        u_necolink_synctimer_master         
            (           
                .reset                      (reset                          ),
                .clk                        (clk                            ),
                .cke                        (cke                            ),

                .external_time              (external_time                  ),
                .current_time               (current_time                   ),

                .set_time                   ('0                             ),
                .set_valid                  (1'b0                           ),

                .cmd_enable                 (sender_enable_synctim          ),
                .cmd_start                  (sender_start                   ),
                .cmd_finish                 (sender_finish                  ),
                .cmd_payload_setup          (sender_payload_setup_synctim   ),
                .m_cmd_payload_data         (synctim_cmd_payload_tx_data    ),
                .m_cmd_payload_valid        (synctim_cmd_payload_tx_valid   ),
                .m_cmd_payload_ready        (sender_payload_tx_ready        ),

                .res_enable                 (receiver_enable_synctim        ),
                .res_start                  (receiver_start                 ),
                .res_finish                 (receiver_finish                ),
                .res_fail                   (receiver_fail                  ),
                .res_rx_node                (receiver_rx_node               ),
                .res_rx_type                (receiver_rx_type               ),
                .res_rx_length              (receiver_rx_length             ),
                .res_payload_setup          (receiver_payload_setup         ),
                .s_res_payload_index        (receiver_payload_rx_index      ),
                .s_res_payload_first        (receiver_payload_rx_first      ),
                .s_res_payload_last         (receiver_payload_rx_last       ),
                .s_res_payload_data         (receiver_payload_rx_data       ),
                .s_res_payload_valid        (receiver_payload_rx_valid      )
            );

    // message
    logic   [7:0]       message_outer_payload_tx_data ;
    logic               message_outer_payload_tx_valid;
    jelly2_necolink_message
            #(
                .ENABLE_BYPASS              (1'b0                           ),
                .MESSAGE_BYTES              (MESSAGE_BYTES                  ),
                .BUF_RAM_TYPE               (MESSAGE_BUF_RAM_TYPE           ),
                .DEBUG                      (DEBUG                          ),
                .SIMULATION                 (SIMULATION                     ) 
            )
        u_necolink_message_outer
            (   
                .reset                      (reset                          ),
                .clk                        (clk                            ),
                .cke                        (cke                            ),

                .node_self                  (node_self                      ),
                
                .m_rx_first                 (m_msg_outer_rx_first           ),
                .m_rx_last                  (m_msg_outer_rx_last            ),
                .m_rx_src_node              (m_msg_outer_rx_src_node        ),
                .m_rx_data                  (m_msg_outer_rx_data            ),
                .m_rx_valid                 (m_msg_outer_rx_valid           ),
                .s_tx_dst_node              (s_msg_outer_tx_dst_node        ),
                .s_tx_data                  (s_msg_outer_tx_data            ),
                .s_tx_valid                 (s_msg_outer_tx_valid           ),
                .s_tx_ready                 (s_msg_outer_tx_ready           ),

                .recv_enable                (repeater_enable_message        ),
                .recv_start                 (repeater_start                 ),
                .recv_finish                (repeater_finish                ),
                .recv_fail                  (repeater_fail                  ),
                .recv_payload_setup         (repeater_payload_setup         ),
                .s_recv_payload_rx_index    (repeater_payload_rx_index      ),
                .s_recv_payload_rx_first    (repeater_payload_rx_first      ),
                .s_recv_payload_rx_last     (repeater_payload_rx_last       ),
                .s_recv_payload_rx_data     (repeater_payload_rx_data       ),
                .s_recv_payload_rx_valid    (repeater_payload_rx_valid      ),

                .send_enable                (sender_enable_message          ),
                .send_start                 (sender_start                   ),
                .send_finish                (sender_finish                  ),
                .send_fail                  (1'b0                           ),
                .send_payload_setup         (sender_payload_setup           ),
                .s_send_payload_rx_index    (sender_payload_rx_index        ),
                .s_send_payload_rx_first    (sender_payload_rx_first        ),
                .s_send_payload_rx_last     (sender_payload_rx_last         ),
                .s_send_payload_rx_valid    (sender_payload_rx_valid        ),
                .m_send_payload_tx_data     (message_outer_payload_tx_data  ),
                .m_send_payload_tx_valid    (message_outer_payload_tx_valid ),
                .m_send_payload_tx_ready    (sender_payload_tx_ready        )
            );

    logic   [7:0]       message_inner_payload_tx_data ;
    logic               message_inner_payload_tx_valid;
    jelly2_necolink_message
            #(
                .ENABLE_BYPASS              (1'b0                           ),
                .MESSAGE_BYTES              (MESSAGE_BYTES                  ),
                .BUF_RAM_TYPE               (MESSAGE_BUF_RAM_TYPE           ),
                .DEBUG                      (DEBUG                          ),
                .SIMULATION                 (SIMULATION                     ) 
            )
        u_necolink_message_inner
            (   
                .reset                      (reset                          ),
                .clk                        (clk                            ),
                .cke                        (cke                            ),

                .node_self                  (node_self                      ),
                
                .m_rx_first                 (m_msg_inner_rx_first           ),
                .m_rx_last                  (m_msg_inner_rx_last            ),
                .m_rx_src_node              (m_msg_inner_rx_src_node        ),
                .m_rx_data                  (m_msg_inner_rx_data            ),
                .m_rx_valid                 (m_msg_inner_rx_valid           ),
                .s_tx_dst_node              (s_msg_inner_tx_dst_node        ),
                .s_tx_data                  (s_msg_inner_tx_data            ),
                .s_tx_valid                 (s_msg_inner_tx_valid           ),
                .s_tx_ready                 (s_msg_inner_tx_ready           ),

                .recv_enable                (receiver_enable_message        ),
                .recv_start                 (receiver_start                 ),
                .recv_finish                (receiver_finish                ),
                .recv_fail                  (receiver_fail                  ),
                .recv_payload_setup         (receiver_payload_setup         ),
                .s_recv_payload_rx_index    (receiver_payload_rx_index      ),
                .s_recv_payload_rx_first    (receiver_payload_rx_first      ),
                .s_recv_payload_rx_last     (receiver_payload_rx_last       ),
                .s_recv_payload_rx_data     (receiver_payload_rx_data       ),
                .s_recv_payload_rx_valid    (receiver_payload_rx_valid      ),

                .send_enable                (repeater_enable_message        ),
                .send_start                 (repeater_start                 ),
                .send_finish                (repeater_finish                ),
                .send_fail                  (repeater_fail                  ),
                .send_payload_setup         (repeater_payload_setup         ),
                .s_send_payload_rx_index    (repeater_payload_rx_index      ),
                .s_send_payload_rx_first    (repeater_payload_rx_first      ),
                .s_send_payload_rx_last     (repeater_payload_rx_last       ),
                .s_send_payload_rx_valid    (repeater_payload_rx_valid      ),
                .m_send_payload_tx_data     (message_inner_payload_tx_data  ),
                .m_send_payload_tx_valid    (message_inner_payload_tx_valid ),
                .m_send_payload_tx_ready    (repeater_payload_tx_ready      )
            );


    always_comb begin
        sender_payload_tx_data  = 'x;
        sender_payload_tx_valid = 1'b0;
        if ( gpio_cmd_payload_tx_valid ) begin
            sender_payload_tx_data  = gpio_cmd_payload_tx_data ;
            sender_payload_tx_valid = gpio_cmd_payload_tx_valid;
        end
        if ( synctim_cmd_payload_tx_valid ) begin
            sender_payload_tx_data  = synctim_cmd_payload_tx_data ;
            sender_payload_tx_valid = synctim_cmd_payload_tx_valid;
        end
        if ( message_outer_payload_tx_valid ) begin
            sender_payload_tx_data  = message_outer_payload_tx_data ;
            sender_payload_tx_valid = message_outer_payload_tx_valid;
        end
    end

    always_comb begin
        repeater_payload_tx_data  = '0;
        repeater_payload_tx_valid = 1'b0;
        if ( message_inner_payload_tx_valid ) begin
            repeater_payload_tx_data  = message_inner_payload_tx_data ;
            repeater_payload_tx_valid = message_inner_payload_tx_valid;
        end
    end

endmodule


`default_nettype wire


// end of file

