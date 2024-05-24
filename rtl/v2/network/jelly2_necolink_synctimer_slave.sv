// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_synctimer_slave
        #(
            parameter   int unsigned    TIMER_WIDTH     = 64                    , // タイマのbit幅
            parameter   int unsigned    NUMERATOR       = 10                    , // クロック周期の分子
            parameter   int unsigned    DENOMINATOR     = 3                     , // クロック周期の分母
            parameter   int unsigned    LIMIT_WIDTH     = TIMER_WIDTH           , // 補正限界のbit幅
            parameter   int unsigned    CALC_WIDTH      = 32                    , // 補正に使う範囲のタイマ幅
            parameter   int unsigned    CYCLE_WIDTH     = 32                    , // 自クロックサイクルカウンタのbit数
            parameter   int unsigned    ERROR_WIDTH     = 32                    , // 誤差計算時のbit幅
            parameter   int unsigned    ERROR_Q         = 8                     , // 誤差計算時に追加する固定小数点数bit数
            parameter   int unsigned    ADJUST_WIDTH    = CYCLE_WIDTH + ERROR_Q , // 補正周期のbit幅
            parameter   int unsigned    ADJUST_Q        = ERROR_Q               , // 補正周期に追加する固定小数点数bit数
            parameter   int unsigned    LPF_GAIN_CYCLE  = 6                     , // 自クロックサイクルカウントLPFの更新ゲイン(1/2^N)
            parameter   int unsigned    LPF_GAIN_PERIOD = 6                     , // 周期補正のLPFの更新ゲイン(1/2^N)
            parameter   int unsigned    LPF_GAIN_PHASE  = 6                     , // 位相補正のLPFの更新ゲイン(1/2^N)
            parameter   bit             DEBUG           = 1'b0                  ,
            parameter   bit             SIMULATION      = 1'b0             
        ) 
        ( 
            input   var logic                       reset                   ,
            input   var logic                       clk                     ,
            input   var logic                       cke                     ,

            input   var logic                       adj_enable              ,

            output  var logic   [TIMER_WIDTH-1:0]   current_time            ,

            input   var logic   [LIMIT_WIDTH-1:0]   param_limit_min         ,
            input   var logic   [LIMIT_WIDTH-1:0]   param_limit_max         ,
            input   var logic   [ERROR_WIDTH-1:0]   param_adjust_min        ,
            input   var logic   [ERROR_WIDTH-1:0]   param_adjust_max        ,

            input   var logic   [7:0]               node_self               ,

            // command
            input   var logic                       cmd_enable              ,
            input   var logic                       cmd_start               ,
            input   var logic                       cmd_finish              ,
            input   var logic                       cmd_fail                ,
            input   var logic                       cmd_payload_setup       ,
            input   var logic   [15:0]              s_cmd_payload_rx_index  ,
            input   var logic                       s_cmd_payload_rx_first  ,
            input   var logic                       s_cmd_payload_rx_last   ,
            input   var logic   [7:0]               s_cmd_payload_rx_data   ,
            input   var logic                       s_cmd_payload_rx_valid  ,
            output  var logic   [7:0]               m_cmd_payload_tx_data   ,
            output  var logic                       m_cmd_payload_tx_valid  ,
            input   var logic                       m_cmd_payload_tx_ready  ,
            
            // response
            input   var logic                       res_enable              ,
            input   var logic                       res_start               ,
            input   var logic                       res_finish              ,
            input   var logic                       res_fail                ,
            input   var logic                       res_payload_setup       ,
            input   var logic   [15:0]              s_res_payload_rx_index  ,
            input   var logic                       s_res_payload_rx_first  ,
            input   var logic                       s_res_payload_rx_last   ,
            input   var logic   [7:0]               s_res_payload_rx_data   ,
            input   var logic                       s_res_payload_rx_valid  ,
            output  var logic   [7:0]               m_res_payload_tx_data   ,
            output  var logic                       m_res_payload_tx_valid  ,
            input   var logic                       m_res_payload_tx_ready  
        );

    // type
    localparam type t_time        = logic [TIMER_WIDTH-1:0];
    localparam type t_offset      = logic [31:0];
    localparam type t_time_pkt    = logic [7:0][7:0];
    localparam type t_offset_pkt  = logic [3:0][7:0];


    // ---------------------------------
    //  Timer
    // ---------------------------------

    localparam type t_adj_limit   = logic [LIMIT_WIDTH-1:0];
    localparam type t_adj_error   = logic [ERROR_WIDTH-1:0];

    t_time                  correct_time ;
    logic                   correct_renew;
    logic                   correct_valid;

    // main timer
    jellyvl_synctimer_core
            #(
                .TIMER_WIDTH        (TIMER_WIDTH                ),
                .NUMERATOR          (NUMERATOR                  ),
                .DENOMINATOR        (DENOMINATOR                ),
                .LIMIT_WIDTH        (LIMIT_WIDTH                ),
                .CALC_WIDTH         (CALC_WIDTH                 ),
                .CYCLE_WIDTH        (CYCLE_WIDTH                ),
                .ERROR_WIDTH        (ERROR_WIDTH                ),
                .ERROR_Q            (ERROR_Q                    ),
                .ADJUST_WIDTH       (ADJUST_WIDTH               ),
                .ADJUST_Q           (ADJUST_Q                   ),
                .LPF_GAIN_CYCLE     (LPF_GAIN_CYCLE             ),
                .LPF_GAIN_PERIOD    (LPF_GAIN_PERIOD            ),
                .LPF_GAIN_PHASE     (LPF_GAIN_PHASE             ),
                .DEBUG              (DEBUG                      ),
                .SIMULATION         (SIMULATION                 )
            )
        u_synctimer_core
            (
                .rst                (reset                      ),
                .clk                (clk                        ),
                .param_limit_min    (param_limit_min            ),
                .param_limit_max    (param_limit_max            ),
                .param_adjust_min   (param_adjust_min           ),
                .param_adjust_max   (param_adjust_max           ),
                .set_time           ('0                         ),
                .set_valid          (1'b0                       ),
                .current_time       (current_time               ),
                .correct_time       (correct_time               ),
                .correct_renew      (correct_renew              ),
                .correct_valid      (correct_valid & adj_enable )
            );


    // free run timer
    t_time                  free_run_time   ;
    logic                   tmp_adjust_ready;
    jellyvl_synctimer_timer
            #(
                .NUMERATOR          (NUMERATOR          ),
                .DENOMINATOR        (DENOMINATOR        ),
                .TIMER_WIDTH        (TIMER_WIDTH        )
            )
        u_synctimer_timer_free_run
            (
                .rst                (reset              ),
                .clk                (clk                ),
                .set_time           ('0                 ),
                .set_valid          (1'b0               ),
                .adjust_sign        ('0                 ),
                .adjust_valid       ('0                 ),
                .adjust_ready       (tmp_adjust_ready   ),
                .current_time       (free_run_time      )
            );

    // 応答時間補正
    t_offset    start_time  ;
    t_offset    elapsed_time;

    always_ff @ (posedge clk) begin
        if ( cmd_start) begin
            start_time <= t_offset'(free_run_time);
        end

        if ( res_start ) begin
            elapsed_time <= t_offset'(free_run_time) - start_time;
        end
    end


    // ---------------------------------
    //  Receive Command
    // ---------------------------------

    logic   [15:0]      offset_pos;
    always_ff @(posedge clk) begin
        if ( cmd_start ) begin
            offset_pos <= 16'd9 + (16'(node_self) - 16'd2) * 16'd4 ;
        end
    end
    
    logic   cmd_busy;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            cmd_busy <= 1'b0;
        end
        else if ( cke ) begin
            if ( cmd_payload_setup && cmd_enable ) begin
                cmd_busy <= 1'b1;
            end
            if ( cmd_finish || cmd_fail ) begin
                cmd_busy <= 1'b0;
            end
        end
    end


    logic   [0:0]       cmd_flags_cmd_id;
    logic   [7:0]       cmd_flags_time;
    logic   [3:0]       cmd_flags_offset;

    jelly2_packet_position
            #(
                .INDEX_WIDTH    (16                                 ),
                .OFFSET_WIDTH   (1                                  ),
                .FLAG_WIDTH     (1+8                                )
            )                   
        jelly2_packet_position_cmd_header
            (           
                .reset          (reset                              ),
                .clk            (clk                                ),
                .cke            (cke                                ),

                .setup          (cmd_payload_setup && cmd_enable    ),
                .s_index        (s_cmd_payload_rx_index             ),
                .s_valid        (s_cmd_payload_rx_valid             ),

                .offset         ('0                                 ),
                .flags          ({cmd_flags_time, cmd_flags_cmd_id} ),
                .flag           (                                   )
        );

    jelly2_packet_position
            #(
                .INDEX_WIDTH    (16                                 ),
                .OFFSET_WIDTH   (16                                 ),
                .FLAG_WIDTH     (4                                  )
            )                   
        jelly2_packet_position_cmd_offset_time
            (           
                .reset          (reset                              ),
                .clk            (clk                                ),
                .cke            (cke                                ),

                .setup          (cmd_payload_setup && cmd_enable    ),
                .s_index        (s_cmd_payload_rx_index             ),
                .s_valid        (s_cmd_payload_rx_valid             ),

                .offset         (offset_pos                         ),
                .flags          (cmd_flags_offset                   ),
                .flag           (                                   )
            );

    logic      [7:0]    cmd_rx_cmd_id    ;
    t_time_pkt          cmd_rx_time_pkt  ;
    t_offset_pkt        cmd_rx_offset_pkt;

    t_time              cmd_rx_time;
    t_offset            cmd_rx_offset;
    assign cmd_rx_time   = t_time'(cmd_rx_time_pkt);
    assign cmd_rx_offset = t_offset'(cmd_rx_offset_pkt);

    always_ff @ (posedge clk) begin
        if ( cke ) begin
            if ( cmd_flags_cmd_id[0] ) begin
                cmd_rx_cmd_id <= s_cmd_payload_rx_data;
            end

            for ( int i = 0; i < 8; ++i ) begin
                if ( cmd_flags_time[i] ) begin
                    cmd_rx_time_pkt[i] <= s_cmd_payload_rx_data;
                end
            end

            for ( int i = 0; i < 4; ++i ) begin
                if ( cmd_flags_offset[i] ) begin
                    cmd_rx_offset_pkt[i] <= s_cmd_payload_rx_data;
                end
            end
        end
    end

    assign m_cmd_payload_tx_data  = 'x;
    assign m_cmd_payload_tx_valid = 1'b0;

    
    always_ff @( posedge clk ) begin
        if ( reset ) begin
            correct_time  <= 'x;
        end
        else if ( cke ) begin
            correct_time  <= cmd_rx_time + t_time'(cmd_rx_offset);
        end
    end

    assign correct_renew = cmd_rx_cmd_id[1];
    assign correct_valid = cmd_finish & cmd_rx_cmd_id[0] & cmd_busy;

    
    // ---------------------------------
    //  Send response
    // ---------------------------------

    logic       res_flag;

    jelly2_packet_position
            #(
                .INDEX_WIDTH    (16                                 ),
                .OFFSET_WIDTH   (16                                 ),
                .FLAG_WIDTH     (4                                  )
            )                   
        jelly2_packet_position_res_offset_time
            (           
                .reset          (reset                              ),
                .clk            (clk                                ),
                .cke            (cke                                ),

                .setup          (res_payload_setup && res_enable    ),
                .s_index        (s_res_payload_rx_index             ),
                .s_valid        (s_res_payload_rx_valid             ),

                .offset         (offset_pos                         ),
                .flags          (                                   ),
                .flag           (res_flag                           )
            );

    t_offset_pkt    res_offset;    
    always_ff @ (posedge clk) begin
        if ( res_payload_setup && res_enable ) begin
            res_offset <= elapsed_time;
        end
        else if ( cke ) begin
            m_res_payload_tx_data  <= 'x;
            m_res_payload_tx_valid <= 1'b0;
            if ( s_res_payload_rx_valid && res_flag ) begin
                res_offset             <= res_offset >> 8;
                m_res_payload_tx_data  <= res_offset[0];
                m_res_payload_tx_valid <= 1'b1;
            end
        end
    end
    
endmodule


`default_nettype wire

// end of file

