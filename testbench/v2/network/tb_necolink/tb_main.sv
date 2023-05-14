
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

    // 
    localparam  bit  RAND = 0;


    // master
    parameter int unsigned  MAX_NODES               = 4   ;
    parameter int unsigned  TIMER_WIDTH             = 64  ; // タイマのbit幅
    parameter int unsigned  NUMERATOR               = 8   ; // クロック周期の分子
    parameter int unsigned  DENOMINATOR             = 1   ; // クロック周期の分母
    parameter int unsigned  SYNCTIM_OFFSET_WIDTH    = 24  ; // オフセットbit幅
    parameter int unsigned  SYNCTIM_OFFSET_LPF_GAIN = 4   ; // オフセット更新LPFのゲイン (1/2^N)
    
    logic                       cke                         ;

    logic   [TIMER_WIDTH-1:0]   current_time                ;

    logic                       param_mac_enable            ;
    logic                       param_set_mac_addr_self     ;
    logic                       param_set_mac_addr_up       ;
    logic   [5:0][7:0]          param_mac_addr_self         ;
    logic   [5:0][7:0]          param_mac_addr_down         ;
    logic   [5:0][7:0]          param_mac_addr_up           ;
    logic   [15:0]              param_mac_type_down         ;
    logic   [15:0]              param_mac_type_up           ;

    logic                       m_up_tx_first               ;
    logic                       m_up_tx_last                ;
    logic   [7:0]               m_up_tx_data                ;
    logic                       m_up_tx_valid               ;
    logic                       m_up_tx_ready               = 1'b1;
    logic                       s_up_rx_first               ;
    logic                       s_up_rx_last                ;
    logic   [7:0]               s_up_rx_data                ;
    logic                       s_up_rx_valid               ;

    logic                       m_down_tx_first             ;
    logic                       m_down_tx_last              ;
    logic   [7:0]               m_down_tx_data              ;
    logic                       m_down_tx_valid             ;
    logic                       m_down_tx_ready             = 1'b1;
    logic                       s_down_rx_first             ;
    logic                       s_down_rx_last              ;
    logic   [7:0]               s_down_rx_data              ;
    logic                       s_down_rx_valid             ;

    jelly2_necolink_master
            #(
                .MAX_NODES                  (MAX_NODES                  ),
                .TIMER_WIDTH                (TIMER_WIDTH                ),
                .NUMERATOR                  (NUMERATOR                  ),
                .DENOMINATOR                (DENOMINATOR                ),
                .SYNCTIM_OFFSET_WIDTH       (SYNCTIM_OFFSET_WIDTH       ),
                .SYNCTIM_OFFSET_LPF_GAIN    (SYNCTIM_OFFSET_LPF_GAIN    ),
                .DEBUG                      (DEBUG                      ),
                .SIMULATION                 (SIMULATION                 )
            )
        u_jelly2_necolink_master
            (
                .reset                      (reset                      ),
                .clk                        (clk                        ),
                .cke                        (cke                        ),

                .current_time               (current_time               ),

                .param_mac_enable           (param_mac_enable           ),
                .param_set_mac_addr_self    (param_set_mac_addr_self    ),
                .param_set_mac_addr_up      (param_set_mac_addr_up      ),
                .param_mac_addr_self        (param_mac_addr_self        ),
                .param_mac_addr_down        (param_mac_addr_down        ),
                .param_mac_addr_up          (param_mac_addr_up          ),
                .param_mac_type_down        (param_mac_type_down        ),
                .param_mac_type_up          (param_mac_type_up          ),

                .m_up_tx_first              (m_up_tx_first              ),
                .m_up_tx_last               (m_up_tx_last               ),
                .m_up_tx_data               (m_up_tx_data               ),
                .m_up_tx_valid              (m_up_tx_valid              ),
                .m_up_tx_ready              (m_up_tx_ready              ),
                .s_up_rx_first              (s_up_rx_first              ),
                .s_up_rx_last               (s_up_rx_last               ),
                .s_up_rx_data               (s_up_rx_data               ),
                .s_up_rx_valid              (s_up_rx_valid              ),

                .m_down_tx_first            (m_down_tx_first            ),
                .m_down_tx_last             (m_down_tx_last             ),
                .m_down_tx_data             (m_down_tx_data             ),
                .m_down_tx_valid            (m_down_tx_valid            ),
                .m_down_tx_ready            (m_down_tx_ready            ),
                .s_down_rx_first            (s_down_rx_first            ),
                .s_down_rx_last             (s_down_rx_last             ),
                .s_down_rx_data             (s_down_rx_data             ),
                .s_down_rx_valid            (s_down_rx_valid            )
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

    assign param_mac_enable        = 1'b1;
    assign param_set_mac_addr_self = 1'b0;
    assign param_set_mac_addr_up   = 1'b0;
    assign param_mac_addr_self     = 48'h00_00_0c_00_53_00;
    assign param_mac_addr_down     = 48'hff_ff_ff_ff_ff_ff;
    assign param_mac_addr_up       = 48'hff_ff_ff_ff_ff_ff;
    assign param_mac_type_down     = 16'hAAAA;
    assign param_mac_type_up       = 16'hBBBB;

    always_ff @(posedge clk) begin
        if ( reset ) begin
        end
        else if ( cke ) begin
            if ( m_down_tx_valid ) begin
                $write("%02x ", m_down_tx_data);
                if ( m_down_tx_last ) begin
                    $write("\n");
                end
            end
            
            /*
            if ( s_down_rx_valid ) begin
                $write("%02x ", s_down_rx_data);
                if ( s_down_rx_last ) begin
                    $write("\n");
                end
            end
            */

            /*
            if ( m_up_tx_valid && m_up_tx_ready ) begin
                $write("%02x ", m_up_tx_data);
                if ( m_up_tx_last ) begin
                    $write("\n");
                end
            end

            if ( s_up_rx_valid ) begin
                $write("%02x ", s_up_rx_data);
                if ( s_up_rx_last ) begin
                    $write("\n");
                end
            end
            */
        end
    end




//    parameter   int unsigned    TIMER_WIDTH             = 64                                   ; // タイマのbit幅
//    parameter   int unsigned    NUMERATOR               = 8                                    ; // クロック周期の分子
 //   parameter   int unsigned    DENOMINATOR             = 1                                    ; // クロック周期の分母
    parameter   int unsigned    SYNCTIM_LIMIT_WIDTH     = TIMER_WIDTH                          ; // 補正限界のbit幅
    parameter   int unsigned    SYNCTIM_TIMER_WIDTH     = 32                                   ; // 補正に使う範囲のタイマ幅
    parameter   int unsigned    SYNCTIM_CYCLE_WIDTH     = 32                                   ; // 自クロックサイクルカウンタのbit数
    parameter   int unsigned    SYNCTIM_ERROR_WIDTH     = 32                                   ; // 誤差計算時のbit幅
    parameter   int unsigned    SYNCTIM_ERROR_Q         = 8                                    ; // 誤差計算時に追加する固定小数点数bit数
    parameter   int unsigned    SYNCTIM_ADJUST_WIDTH    = SYNCTIM_CYCLE_WIDTH + SYNCTIM_ERROR_Q; // 補正周期のbit幅
    parameter   int unsigned    SYNCTIM_ADJUST_Q        = SYNCTIM_ERROR_Q                      ; // 補正周期に追加する固定小数点数bit数
    parameter   int unsigned    SYNCTIM_LPF_GAIN_CYCLE  = 6                                    ; // 自クロックサイクルカウントLPFの更新ゲイン(1/2^N)
    parameter   int unsigned    SYNCTIM_LPF_GAIN_PERIOD = 6                                    ; // 周期補正のLPFの更新ゲイン(1/2^N)
    parameter   int unsigned    SYNCTIM_LPF_GAIN_PHASE  = 6                                    ; // 位相補正のLPFの更新ゲイン(1/2^N)
//    parameter   bit             DEBUG                   = 1'b0                                 ;
//    parameter   bit             SIMULATION              = 1'b0                                 ;

    jelly2_necolink_slave
            #(
                .TIMER_WIDTH                (TIMER_WIDTH            ),
                .NUMERATOR                  (NUMERATOR              ),
                .DENOMINATOR                (DENOMINATOR            ),
                .SYNCTIM_LIMIT_WIDTH        (SYNCTIM_LIMIT_WIDTH    ),
                .SYNCTIM_TIMER_WIDTH        (SYNCTIM_TIMER_WIDTH    ),
                .SYNCTIM_CYCLE_WIDTH        (SYNCTIM_CYCLE_WIDTH    ),
                .SYNCTIM_ERROR_WIDTH        (SYNCTIM_ERROR_WIDTH    ),
                .SYNCTIM_ERROR_Q            (SYNCTIM_ERROR_Q        ),
                .SYNCTIM_ADJUST_WIDTH       (SYNCTIM_ADJUST_WIDTH   ),
                .SYNCTIM_ADJUST_Q           (SYNCTIM_ADJUST_Q       ),
                .SYNCTIM_LPF_GAIN_CYCLE     (SYNCTIM_LPF_GAIN_CYCLE ),
                .SYNCTIM_LPF_GAIN_PERIOD    (SYNCTIM_LPF_GAIN_PERIOD),
                .SYNCTIM_LPF_GAIN_PHASE     (SYNCTIM_LPF_GAIN_PHASE ),
                .DEBUG                      (DEBUG                  ),
                .SIMULATION                 (SIMULATION             )
            )
        u_necolink_slave
            (
                .reset                      (reset                  ),
                .clk                        (clk                    ),
                .cke                        (cke                    ),

                .current_time               (                       ),
                .timsync_adj_enable         (1'b1                   ),

                .param_mac_enable           (param_mac_enable       ),
                .param_set_mac_addr_self    ('0                     ),
                .param_set_mac_addr_up      ('0                     ),
                .param_set_mac_addr_down    ('0                     ),
                .param_mac_addr_self        ('0                     ),
                .param_mac_addr_down        ('0                     ),
                .param_mac_addr_up          ('0                     ),

                .s_up_rx_first              (m_down_tx_first        ),
                .s_up_rx_last               (m_down_tx_last         ),
                .s_up_rx_data               (m_down_tx_data         ),
                .s_up_rx_valid              (m_down_tx_valid        ),
                .m_up_tx_first              (s_down_rx_first        ),
                .m_up_tx_last               (s_down_rx_last         ),
                .m_up_tx_data               (s_down_rx_data         ),
                .m_up_tx_valid              (s_down_rx_valid        ),
                .m_up_tx_ready              (1'b1                   ),

                .s_down_rx_first            (m_up_tx_first          ),
                .s_down_rx_last             (m_up_tx_last           ),
                .s_down_rx_data             (m_up_tx_data           ),
                .s_down_rx_valid            (m_up_tx_valid          ),
                .m_down_tx_first            (s_up_rx_first          ),
                .m_down_tx_last             (s_up_rx_last           ),
                .m_down_tx_data             (s_up_rx_data           ),
                .m_down_tx_valid            (s_up_rx_valid          ),
                .m_down_tx_ready            (1'b1                   )
            );


endmodule


`default_nettype wire


// end of file
