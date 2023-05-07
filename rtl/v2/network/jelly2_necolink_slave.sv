// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_slave
        #(
            parameter   int unsigned    MAX_NODES               = 4                                     ,
            localparam  int unsigned    MAX_SLAVES              = MAX_NODES - 1                         ,
            parameter   int unsigned    TIMER_WIDTH             = 64                                    , // タイマのbit幅
            parameter   int unsigned    NUMERATOR               = 8                                     , // クロック周期の分子
            parameter   int unsigned    DENOMINATOR             = 1                                     , // クロック周期の分母
            parameter   int unsigned    SYNCTIM_LIMIT_WIDTH     = TIMER_WIDTH                           , // 補正限界のbit幅
            parameter   int unsigned    SYNCTIM_TIMER_WIDTH     = 32                                    , // 補正に使う範囲のタイマ幅
            parameter   int unsigned    SYNCTIM_CYCLE_WIDTH     = 32                                    , // 自クロックサイクルカウンタのbit数
            parameter   int unsigned    SYNCTIM_ERROR_WIDTH     = 32                                    , // 誤差計算時のbit幅
            parameter   int unsigned    SYNCTIM_ERROR_Q         = 8                                     , // 誤差計算時に追加する固定小数点数bit数
            parameter   int unsigned    SYNCTIM_ADJUST_WIDTH    = SYNCTIM_CYCLE_WIDTH + SYNCTIM_ERROR_Q , // 補正周期のbit幅
            parameter   int unsigned    SYNCTIM_ADJUST_Q        = SYNCTIM_ERROR_Q                       , // 補正周期に追加する固定小数点数bit数
            parameter   int unsigned    SYNCTIM_LPF_GAIN_CYCLE  = 6                                     , // 自クロックサイクルカウントLPFの更新ゲイン(1/2^N)
            parameter   int unsigned    SYNCTIM_LPF_GAIN_PERIOD = 6                                     , // 周期補正のLPFの更新ゲイン(1/2^N)
            parameter   int unsigned    SYNCTIM_LPF_GAIN_PHASE  = 6                                     , // 位相補正のLPFの更新ゲイン(1/2^N)
            parameter   int unsigned    GPIO_GLOBAL_BYTES       = 4                                     ,
            parameter   int unsigned    GPIO_LOCAL_OFFSET       = GPIO_GLOBAL_BYTES                     ,
            parameter   int unsigned    GPIO_LOCAL_BYTES        = 4                                     ,
            parameter   int unsigned    GPIO_FULL_BYTES         = GPIO_GLOBAL_BYTES + GPIO_LOCAL_BYTES * MAX_SLAVES,
            parameter   int unsigned    MESSAGE_BYTES           = 64                                    ,
            parameter                   MESSAGE_BUF_RAM_TYPE    = "distributed"                         ,
            parameter   bit             DEBUG                   = 1'b0                                  ,
            parameter   bit             SIMULATION              = 1'b0                             
        )
        (
            input   var logic                                   reset                       ,
            input   var logic                                   clk                         ,
            input   var logic                                   cke                         ,

            output  var logic [TIMER_WIDTH-1:0]                 current_time                ,
            input   var logic                                   timsync_adj_enable          ,

            output  var logic   [7:0]                           node_self                   ,
            output  var logic   [7:0]                           node_last                   ,
            output  var logic                                   network_looped              ,

            input   var logic                                   param_mac_enable            ,
            input   var logic                                   param_set_mac_addr_self     ,
            input   var logic                                   param_set_mac_addr_up       ,
            input   var logic                                   param_set_mac_addr_down     ,
            input   var logic   [5:0][7:0]                      param_mac_addr_self         ,
            input   var logic   [5:0][7:0]                      param_mac_addr_down         ,
            input   var logic   [5:0][7:0]                      param_mac_addr_up           ,

            input   var logic   [SYNCTIM_LIMIT_WIDTH-1:0]       param_synctim_limit_min     ,
            input   var logic   [SYNCTIM_LIMIT_WIDTH-1:0]       param_synctim_limit_max     ,
            input   var logic   [SYNCTIM_ERROR_WIDTH-1:0]       param_synctim_adjust_min    ,
            input   var logic   [SYNCTIM_ERROR_WIDTH-1:0]       param_synctim_adjust_max    ,


            input   var logic   [GPIO_GLOBAL_BYTES-1:0][7:0]    gpio_tx_global_mask         ,
            input   var logic   [GPIO_GLOBAL_BYTES-1:0][7:0]    gpio_tx_global_data         ,
            input   var logic   [GPIO_LOCAL_BYTES-1:0][7:0]     gpio_tx_local_mask          ,
            input   var logic   [GPIO_LOCAL_BYTES-1:0][7:0]     gpio_tx_local_data          ,
            output  var logic                                   gpio_tx_accepted            ,
            output  var logic   [GPIO_GLOBAL_BYTES-1:0][7:0]    m_gpio_rx_global_data       ,
            output  var logic   [GPIO_LOCAL_BYTES-1:0][7:0]     m_gpio_rx_local_data        ,
            output  var logic                                   m_gpio_rx_valid             ,
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

            input   var logic                                   s_up_rx_first               ,
            input   var logic                                   s_up_rx_last                ,
            input   var logic   [7:0]                           s_up_rx_data                ,
            input   var logic                                   s_up_rx_valid               ,
            output  var logic                                   m_up_tx_first               ,
            output  var logic                                   m_up_tx_last                ,
            output  var logic   [7:0]                           m_up_tx_data                ,
            output  var logic                                   m_up_tx_valid               ,
            input   var logic                                   m_up_tx_ready               ,

            input   var logic                                   s_down_rx_first             ,
            input   var logic                                   s_down_rx_last              ,
            input   var logic   [7:0]                           s_down_rx_data              ,
            input   var logic                                   s_down_rx_valid             ,
            output  var logic                                   m_down_tx_first             ,
            output  var logic                                   m_down_tx_last              ,
            output  var logic   [7:0]                           m_down_tx_data              ,
            output  var logic                                   m_down_tx_valid             ,
            input   var logic                                   m_down_tx_ready             
        );

    localparam  bit     [7:0]   PACKET_TYPE_GPIO      = 8'h04;
    localparam  bit     [7:0]   PACKET_TYPE_SYNCTIM   = 8'h20;
    localparam  bit     [7:0]   PACKET_TYPE_MESSAGE   = 8'h22;


    // ---------------------------------
    //  Ring bus
    // ---------------------------------

    localparam  int PAYLOAD_LATENCY = 1;

    // Outer loop
    logic   [5:0][7:0]  outer_rx_mac_dst     ;
    logic   [5:0][7:0]  outer_rx_mac_src     ;
    logic   [15:0]      outer_rx_mac_type    ;
    logic   [7:0]       outer_rx_node        ;
    logic   [7:0]       outer_rx_type        ;
    logic   [15:0]      outer_rx_length      ;

    logic               outer_parse_node     ;
    logic               outer_parse_type     ;
    logic   [7:0]       outer_parse_data     ;
    logic               outer_parse_valid    ;

    logic               outer_start             ;
    logic               outer_finish            ;
    logic               outer_fail              ;
    
    logic               outer_payload_setup     ;
    logic   [15:0]      outer_payload_rx_index  ;
    logic               outer_payload_rx_first  ;
    logic               outer_payload_rx_last   ;
    logic   [7:0]       outer_payload_rx_data   ;
    logic               outer_payload_rx_valid  ;
    logic   [7:0]       outer_payload_tx_data   ;
    logic               outer_payload_tx_valid  ;
    logic               outer_payload_tx_ready  ;

    jelly2_necolink_packet_slave
            #(
                .PAYLOAD_LATENCY        (PAYLOAD_LATENCY        ),
                .NODE_ADD               (1                      ),
                .TYPE_BIT               (8'h00                  ),
                .TYPE_MASK              (8'hff                  ),
                .DEBUG                  (DEBUG                  ),
                .SIMULATION             (SIMULATION             )
            )
        u_necolink_packet_slave_outer
            (
                .reset                  (reset                  ),
                .clk                    (clk                    ),
                .cke                    (cke                    ),

                .s_rx_first             (s_up_rx_first          ),
                .s_rx_last              (s_up_rx_last           ),
                .s_rx_data              (s_up_rx_data           ),
                .s_rx_valid             (s_up_rx_valid          ),
                .s_rx_ready             (                       ),

                .m_tx_first             (m_down_tx_first        ),
                .m_tx_last              (m_down_tx_last         ),
                .m_tx_data              (m_down_tx_data         ),
                .m_tx_valid             (m_down_tx_valid        ),
                .m_tx_ready             (m_down_tx_ready        ),

                .parse_node             (outer_parse_node       ),
                .parse_type             (outer_parse_type       ),
                .parse_data             (outer_parse_data       ),
                .parse_valid            (outer_parse_valid      ),

                .rx_mac_dst             (outer_rx_mac_dst       ),
                .rx_mac_src             (outer_rx_mac_src       ),
                .rx_mac_type            (outer_rx_mac_type      ),
                .rx_node                (outer_rx_node          ),
                .rx_type                (outer_rx_type          ),
                .rx_length              (outer_rx_length        ),

                .param_mac_enable       (param_mac_enable       ),
                .param_set_mac_dst      (param_set_mac_addr_down),
                .param_set_mac_src      (param_set_mac_addr_self),
                .param_set_mac_type     (1'b0                   ),
                
                .tx_mac_dst             (param_mac_addr_down    ),
                .tx_mac_src             (param_mac_addr_self    ),
                .tx_mac_type            ('0                     ),

                .packet_start           (outer_start            ),
                .packet_finish          (outer_finish           ),
                .packet_fail            (outer_fail             ),

                .payload_setup          (outer_payload_setup    ),
                .m_payload_rx_index     (outer_payload_rx_index ),
                .m_payload_rx_first     (outer_payload_rx_first ),
                .m_payload_rx_last      (outer_payload_rx_last  ),
                .m_payload_rx_data      (outer_payload_rx_data  ),
                .m_payload_rx_valid     (outer_payload_rx_valid ),
                .s_payload_tx_data      (outer_payload_tx_data  ),
                .s_payload_tx_valid     (outer_payload_tx_valid ),
                .s_payload_tx_ready     (outer_payload_tx_ready ) 
            );

    logic               outer_enable_gpio   ;
    logic               outer_enable_synctim;
    logic               outer_enable_message;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( outer_parse_valid && outer_parse_type ) begin
                outer_enable_gpio    <= (outer_parse_data == PACKET_TYPE_GPIO   );
                outer_enable_synctim <= (outer_parse_data == PACKET_TYPE_SYNCTIM);
                outer_enable_message <= (outer_parse_data == PACKET_TYPE_MESSAGE);
            end
        end
    end


    // Inner loop
    logic   [5:0][7:0]  inner_rx_mac_dst            ;
    logic   [5:0][7:0]  inner_rx_mac_src            ;
    logic   [15:0]      inner_rx_mac_type           ;
    logic   [7:0]       inner_rx_node               ;
    logic   [7:0]       inner_rx_type               ;
    logic   [15:0]      inner_rx_length             ;

    logic               inner_parse_node            ;
    logic               inner_parse_type            ;
    logic   [7:0]       inner_parse_data            ;
    logic               inner_parse_valid           ;

    logic               inner_start                 ;
    logic               inner_finish                ;
    logic               inner_fail                  ;
    
    logic               inner_payload_setup         ;
    logic   [15:0]      inner_payload_rx_index      ;
    logic               inner_payload_rx_first      ;
    logic               inner_payload_rx_last       ;
    logic   [7:0]       inner_payload_rx_data       ;
    logic               inner_payload_rx_valid      ;
    logic   [7:0]       inner_payload_tx_data       ;
    logic               inner_payload_tx_valid      ;
    logic               inner_payload_tx_ready      ;

    jelly2_necolink_packet_slave
            #(
                .PAYLOAD_LATENCY        (PAYLOAD_LATENCY        ),
                .NODE_ADD               (0                      ),
                .TYPE_BIT               (8'h00                  ),
                .TYPE_MASK              (8'hff                  ),
                .DEBUG                  (DEBUG                  ),
                .SIMULATION             (SIMULATION             )
            )
        u_necolink_packet_slave_inner
            (
                .reset                  (reset                  ),
                .clk                    (clk                    ),
                .cke                    (cke                    ),

                .s_rx_first             (s_down_rx_first        ),
                .s_rx_last              (s_down_rx_last         ),
                .s_rx_data              (s_down_rx_data         ),
                .s_rx_valid             (s_down_rx_valid        ),
                .s_rx_ready             (                       ),

                .m_tx_first             (m_up_tx_first          ),
                .m_tx_last              (m_up_tx_last           ),
                .m_tx_data              (m_up_tx_data           ),
                .m_tx_valid             (m_up_tx_valid          ),
                .m_tx_ready             (m_up_tx_ready          ),

                .parse_node             (inner_parse_node       ),
                .parse_type             (inner_parse_type       ),
                .parse_data             (inner_parse_data       ),
                .parse_valid            (inner_parse_valid      ),

                .rx_mac_dst             (inner_rx_mac_dst       ),
                .rx_mac_src             (inner_rx_mac_src       ),
                .rx_mac_type            (inner_rx_mac_type      ),
                .rx_node                (inner_rx_node          ),
                .rx_type                (inner_rx_type          ),
                .rx_length              (inner_rx_length        ),


                .param_mac_enable       (param_mac_enable       ),
                .param_set_mac_dst      (param_set_mac_addr_up  ),
                .param_set_mac_src      (param_set_mac_addr_self),
                .param_set_mac_type     (1'b0                   ),
                
                .tx_mac_dst             (param_mac_addr_up      ),
                .tx_mac_src             (param_mac_addr_self    ),
                .tx_mac_type            ('0                     ),

                .packet_start           (inner_start            ),
                .packet_finish          (inner_finish           ),
                .packet_fail            (inner_fail             ),

                .payload_setup          (inner_payload_setup    ),
                .m_payload_rx_index     (inner_payload_rx_index ),
                .m_payload_rx_first     (inner_payload_rx_first ),
                .m_payload_rx_last      (inner_payload_rx_last  ),
                .m_payload_rx_data      (inner_payload_rx_data  ),
                .m_payload_rx_valid     (inner_payload_rx_valid ),
                .s_payload_tx_data      (inner_payload_tx_data  ),
                .s_payload_tx_valid     (inner_payload_tx_valid ),
                .s_payload_tx_ready     (inner_payload_tx_ready ) 
            );

    logic               inner_enable_gpio   ;
    logic               inner_enable_synctim;
    logic               inner_enable_message;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( inner_parse_valid && inner_parse_type ) begin
                inner_enable_gpio    <= (inner_parse_data == PACKET_TYPE_GPIO   );
                inner_enable_synctim <= (inner_parse_data == PACKET_TYPE_SYNCTIM);
                inner_enable_message <= (inner_parse_data == PACKET_TYPE_MESSAGE);
            end
        end
    end



    // -------------------------------------
    //  Nodes
    // -------------------------------------

    logic       node_self_enable;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            node_self_enable <= 1'b0;
            node_self <= '0;
            node_last <= '0;
        end
        else if ( cke ) begin
            // 初回のみFCSチェックを待たずに設定
            if ( !node_self_enable ) begin
                if ( outer_parse_valid && outer_parse_node ) begin
                    node_self <= outer_parse_data;
                end
            end

            if ( outer_finish ) begin
                node_self        <= {1'b0, outer_rx_node[6:0]};
                node_self_enable <= 1'b1;
            end
            
            if ( inner_finish ) begin
                node_last      <= {1'b0, inner_rx_node[6:0]};
                network_looped <= inner_rx_node[7];
            end
        end
    end



    // -------------------------------------
    // Functions
    // -------------------------------------
    
    // GPIO
    logic   [7:0]       gpio_cmd_payload_tx_data ;
    logic               gpio_cmd_payload_tx_valid;
    logic   [7:0]       gpio_res_payload_tx_data ;
    logic               gpio_res_payload_tx_valid;

    jelly2_necolink_gpio
            #(
                .MAX_SLAVES                 (MAX_SLAVES                     ),
                .GLOBAL_BYTES               (GPIO_GLOBAL_BYTES              ),
                .LOCAL_OFFSET               (GPIO_LOCAL_OFFSET              ),
                .LOCAL_BYTES                (GPIO_LOCAL_BYTES               ),
                .DEBUG                      (DEBUG                          ),
                .SIMULATION                 (SIMULATION                     )
            )   
        u_necolink_gpio 
            (   
                .reset                      (reset                          ),
                .clk                        (clk                            ),
                .cke                        (cke                            ),

                .node_self                  (node_self                      ),

                .tx_global_mask             (gpio_tx_global_mask            ),
                .tx_global_data             (gpio_tx_global_data            ),
                .tx_local_mask              (gpio_tx_local_mask             ),
                .tx_local_data              (gpio_tx_local_data             ),
                .tx_accepted                (gpio_tx_accepted               ),
                .m_rx_global_data           (m_gpio_rx_global_data          ),
                .m_rx_local_data            (m_gpio_rx_local_data           ),
                .m_rx_valid                 (m_gpio_rx_valid                ),
                .m_res_full_data            (m_gpio_res_full_data           ),
                .m_res_valid                (m_gpio_res_valid               ),

                .cmd_enable                 (outer_enable_gpio              ),
                .cmd_start                  (outer_start                    ),
                .cmd_finish                 (outer_finish                   ),
                .cmd_fail                   (1'b0                           ),
                .cmd_payload_setup          (outer_payload_setup            ),
                .s_cmd_payload_rx_index     (outer_payload_rx_index         ),
                .s_cmd_payload_rx_first     (outer_payload_rx_first         ),
                .s_cmd_payload_rx_last      (outer_payload_rx_last          ),
                .s_cmd_payload_rx_data      (outer_payload_rx_data          ),
                .s_cmd_payload_rx_valid     (outer_payload_rx_valid         ),
                .m_cmd_payload_tx_data      (gpio_cmd_payload_tx_data       ),
                .m_cmd_payload_tx_valid     (gpio_cmd_payload_tx_valid      ),
                .m_cmd_payload_tx_ready     (outer_payload_tx_ready         ),

                .res_enable                 (inner_enable_gpio              ),
                .res_start                  (inner_start                    ),
                .res_finish                 (inner_finish                   ),
                .res_fail                   (inner_fail                     ),
                .res_payload_setup          (inner_payload_setup            ),
                .s_res_payload_rx_index     (inner_payload_rx_index         ),
                .s_res_payload_rx_first     (inner_payload_rx_first         ),
                .s_res_payload_rx_last      (inner_payload_rx_last          ),
                .s_res_payload_rx_data      (inner_payload_rx_data          ),
                .s_res_payload_rx_valid     (inner_payload_rx_valid         ),
                .m_res_payload_tx_data      (gpio_res_payload_tx_data       ),
                .m_res_payload_tx_valid     (gpio_res_payload_tx_valid      ),
                .m_res_payload_tx_ready     (inner_payload_tx_ready         )
            );


    // sync timer
    logic   [7:0]       synctim_cmd_payload_tx_data ;
    logic               synctim_cmd_payload_tx_valid;
    logic   [7:0]       synctim_res_payload_tx_data ;
    logic               synctim_res_payload_tx_valid;

    jelly2_necolink_synctimer_slave
            #(
                .TIMER_WIDTH                (TIMER_WIDTH                    ),
                .NUMERATOR                  (NUMERATOR                      ),
                .DENOMINATOR                (DENOMINATOR                    ),
                .LIMIT_WIDTH                (SYNCTIM_LIMIT_WIDTH            ),
                .CALC_WIDTH                 (SYNCTIM_TIMER_WIDTH            ),
                .CYCLE_WIDTH                (SYNCTIM_CYCLE_WIDTH            ),
                .ERROR_WIDTH                (SYNCTIM_ERROR_WIDTH            ),
                .ERROR_Q                    (SYNCTIM_ERROR_Q                ),
                .ADJUST_WIDTH               (SYNCTIM_ADJUST_WIDTH           ),
                .ADJUST_Q                   (SYNCTIM_ADJUST_Q               ),
                .LPF_GAIN_CYCLE             (SYNCTIM_LPF_GAIN_CYCLE         ),
                .LPF_GAIN_PERIOD            (SYNCTIM_LPF_GAIN_PERIOD        ),
                .LPF_GAIN_PHASE             (SYNCTIM_LPF_GAIN_PHASE         ),
                .DEBUG                      (DEBUG                          ),
                .SIMULATION                 (SIMULATION                     )
            )
        u_necolink_synctimer_slave
            (
                .reset                      (reset                          ),
                .clk                        (clk                            ),
                .cke                        (cke                            ),

                .adj_enable                 (timsync_adj_enable             ),
                .current_time               (current_time                   ),

                .param_limit_min            (param_synctim_limit_min        ),
                .param_limit_max            (param_synctim_limit_max        ),
                .param_adjust_min           (param_synctim_adjust_min       ),
                .param_adjust_max           (param_synctim_adjust_max       ),

                .node_self                  (node_self                      ),

                .cmd_enable                 (outer_enable_synctim           ),
                .cmd_start                  (outer_start                    ),
                .cmd_finish                 (outer_finish                   ),
                .cmd_fail                   (outer_fail                     ),
                .cmd_payload_setup          (outer_payload_setup            ),
                .s_cmd_payload_rx_index     (outer_payload_rx_index         ),
                .s_cmd_payload_rx_first     (outer_payload_rx_first         ),
                .s_cmd_payload_rx_last      (outer_payload_rx_last          ),
                .s_cmd_payload_rx_data      (outer_payload_rx_data          ),
                .s_cmd_payload_rx_valid     (outer_payload_rx_valid         ),
                .m_cmd_payload_tx_data      (synctim_cmd_payload_tx_data    ),
                .m_cmd_payload_tx_valid     (synctim_cmd_payload_tx_valid   ),
                .m_cmd_payload_tx_ready     (outer_payload_tx_ready         ),

                .res_enable                 (inner_enable_synctim           ),
                .res_start                  (inner_start                    ),
                .res_finish                 (inner_finish                   ),
                .res_fail                   (inner_fail                     ),
                .res_payload_setup          (inner_payload_setup            ),
                .s_res_payload_rx_index     (inner_payload_rx_index         ),
                .s_res_payload_rx_first     (inner_payload_rx_first         ),
                .s_res_payload_rx_last      (inner_payload_rx_last          ),
                .s_res_payload_rx_data      (inner_payload_rx_data          ),
                .s_res_payload_rx_valid     (inner_payload_rx_valid         ),
                .m_res_payload_tx_data      (synctim_res_payload_tx_data    ),
                .m_res_payload_tx_valid     (synctim_res_payload_tx_valid   ),
                .m_res_payload_tx_ready     (inner_payload_tx_ready         )
            );


    // message
    logic   [7:0]       message_outer_payload_tx_data ;
    logic               message_outer_payload_tx_valid;
    jelly2_necolink_message
            #(
                .ENABLE_BYPASS              (1'b1                           ),
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

                .recv_enable                (outer_enable_message           ),
                .recv_start                 (outer_start                    ),
                .recv_finish                (outer_finish                   ),
                .recv_fail                  (outer_fail                     ),
                .recv_payload_setup         (outer_payload_setup            ),
                .s_recv_payload_rx_index    (outer_payload_rx_index         ),
                .s_recv_payload_rx_first    (outer_payload_rx_first         ),
                .s_recv_payload_rx_last     (outer_payload_rx_last          ),
                .s_recv_payload_rx_data     (outer_payload_rx_data          ),
                .s_recv_payload_rx_valid    (outer_payload_rx_valid         ),

                .send_enable                (outer_enable_message           ),
                .send_start                 (outer_start                    ),
                .send_finish                (outer_finish                   ),
                .send_fail                  (1'b0                           ),
                .send_payload_setup         (outer_payload_setup            ),
                .s_send_payload_rx_index    (outer_payload_rx_index         ),
                .s_send_payload_rx_first    (outer_payload_rx_first         ),
                .s_send_payload_rx_last     (outer_payload_rx_last          ),
                .s_send_payload_rx_valid    (outer_payload_rx_valid         ),
                .m_send_payload_tx_data     (message_outer_payload_tx_data  ),
                .m_send_payload_tx_valid    (message_outer_payload_tx_valid ),
                .m_send_payload_tx_ready    (outer_payload_tx_ready         )
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

                .recv_enable                (inner_enable_message           ),
                .recv_start                 (inner_start                    ),
                .recv_finish                (inner_finish                   ),
                .recv_fail                  (inner_fail                     ),
                .recv_payload_setup         (inner_payload_setup            ),
                .s_recv_payload_rx_index    (inner_payload_rx_index         ),
                .s_recv_payload_rx_first    (inner_payload_rx_first         ),
                .s_recv_payload_rx_last     (inner_payload_rx_last          ),
                .s_recv_payload_rx_data     (inner_payload_rx_data          ),
                .s_recv_payload_rx_valid    (inner_payload_rx_valid         ),

                .send_enable                (inner_enable_message           ),
                .send_start                 (inner_start                    ),
                .send_finish                (inner_finish                   ),
                .send_fail                  (inner_fail                     ),
                .send_payload_setup         (inner_payload_setup            ),
                .s_send_payload_rx_index    (inner_payload_rx_index         ),
                .s_send_payload_rx_first    (inner_payload_rx_first         ),
                .s_send_payload_rx_last     (inner_payload_rx_last          ),
                .s_send_payload_rx_valid    (inner_payload_rx_valid         ),
                .m_send_payload_tx_data     (message_inner_payload_tx_data  ),
                .m_send_payload_tx_valid    (message_inner_payload_tx_valid ),
                .m_send_payload_tx_ready    (inner_payload_tx_ready         )
            );


    always_comb begin
        outer_payload_tx_data  = 'x;
        outer_payload_tx_valid = 1'b0;
        if ( gpio_cmd_payload_tx_valid ) begin
            outer_payload_tx_data  = gpio_cmd_payload_tx_data ;
            outer_payload_tx_valid = gpio_cmd_payload_tx_valid;
        end
        if ( synctim_cmd_payload_tx_valid ) begin
            outer_payload_tx_data  = synctim_cmd_payload_tx_data ;
            outer_payload_tx_valid = synctim_cmd_payload_tx_valid;
        end
        if ( message_outer_payload_tx_valid ) begin
            outer_payload_tx_data  = message_outer_payload_tx_data ;
            outer_payload_tx_valid = message_outer_payload_tx_valid;
        end
    end

    always_comb begin
        inner_payload_tx_data  = 'x;
        inner_payload_tx_valid = 1'b0;
        if ( gpio_res_payload_tx_valid ) begin
            inner_payload_tx_data  = gpio_res_payload_tx_data ;
            inner_payload_tx_valid = gpio_res_payload_tx_valid;
        end
        if ( synctim_res_payload_tx_valid ) begin
            inner_payload_tx_data  = synctim_res_payload_tx_data ;
            inner_payload_tx_valid = synctim_res_payload_tx_valid;
        end
        if ( message_inner_payload_tx_valid ) begin
            inner_payload_tx_data  = message_inner_payload_tx_data ;
            inner_payload_tx_valid = message_inner_payload_tx_valid;
        end
    end

endmodule


`default_nettype wire


// end of file
