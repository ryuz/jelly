
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire        reset,
            input   wire        clk,

            input   wire        ref_clk
        );


    localparam  int unsigned TIMER_WIDTH        = 64                             ; // タイマのbit幅
    localparam  int unsigned NUMERATOR          = 10                             ; // クロック周期の分子
    localparam  int unsigned DENOMINATOR        = 3                              ; // クロック周期の分母
    localparam  int unsigned ADJ_LIMIT_WIDTH    = 20                   ; // 補正限界のbit幅
    localparam  int unsigned ADJ_TIMER_WIDTH    = 32                            ; // 補正に使う範囲のタイマ幅
    localparam  int unsigned ADJ_CYCLE_WIDTH    = 32                            ; // 自クロックサイクルカウンタのbit数
    localparam  int unsigned ADJ_ERROR_WIDTH    = 32                            ; // 誤差計算時のbit幅
    localparam  int unsigned ADJ_ERROR_Q        = 8                             ; // 誤差計算時に追加する固定小数点数bit数
    localparam  int unsigned ADJ_ADJUST_WIDTH   = ADJ_CYCLE_WIDTH + ADJ_ERROR_Q ; // 補正周期のbit幅
    localparam  int unsigned ADJ_ADJUST_Q       = ADJ_ERROR_Q                   ; // 補正周期に追加する固定小数点数bit数
    localparam  int unsigned ADJ_LPF_GAIN_CYCLE = 6                             ; // 自クロックサイクルカウントLPFの更新ゲイン(1/2^N)
    localparam  int unsigned ADJ_LPF_GAIN_PERIOD= 6                             ; // 周期補正のLPFの更新ゲイン(1/2^N)
    localparam  int unsigned ADJ_LPF_GAIN_PHASE = 6                             ; // 位相補正のLPFの更新ゲイン(1/2^N)
    localparam  bit          DEBUG              = 1'b0                          ;
    localparam  bit          SIMULATION         = 1'b0                          ;



    logic   signed  [ADJ_LIMIT_WIDTH-1:0]   adj_param_limit_min ;
    logic   signed  [ADJ_LIMIT_WIDTH-1:0]   adj_param_limit_max ;
    logic   signed  [ADJ_ERROR_WIDTH-1:0]   adj_param_adjust_min;
    logic   signed  [ADJ_ERROR_WIDTH-1:0]   adj_param_adjust_max;

    logic           [TIMER_WIDTH-1:0]       set_time;
    logic                                   set_valid = 1'b0;

    logic           [TIMER_WIDTH-1:0]       current_time;

    logic                                   correct_override;
    logic           [TIMER_WIDTH-1:0]       correct_time;
    logic                                   correct_valid;


    jellyvl_synctimer_core
            #(
                .TIMER_WIDTH        (TIMER_WIDTH        ),
                .NUMERATOR          (NUMERATOR          ),
                .DENOMINATOR        (DENOMINATOR        ),
                .ADJ_LIMIT_WIDTH    (ADJ_LIMIT_WIDTH    ),
                .ADJ_TIMER_WIDTH    (ADJ_TIMER_WIDTH    ),
                .ADJ_CYCLE_WIDTH    (ADJ_CYCLE_WIDTH    ),
                .ADJ_ERROR_WIDTH    (ADJ_ERROR_WIDTH    ),
                .ADJ_ERROR_Q        (ADJ_ERROR_Q        ),
                .ADJ_ADJUST_WIDTH   (ADJ_ADJUST_WIDTH   ),
                .ADJ_ADJUST_Q       (ADJ_ADJUST_Q       ),
                .ADJ_LPF_GAIN_CYCLE (ADJ_LPF_GAIN_CYCLE ),
                .ADJ_LPF_GAIN_PERIOD(ADJ_LPF_GAIN_PERIOD),
                .ADJ_LPF_GAIN_PHASE (ADJ_LPF_GAIN_PHASE ),
                .DEBUG              (DEBUG              ),
                .SIMULATION         (SIMULATION         )
            )
        u_synctimer_core
            (
                .reset,
                .clk,
                
                adj_param_limit_min ,
                adj_param_limit_max ,
                adj_param_adjust_min,
                adj_param_adjust_max,
                
                .set_time,
                .set_valid,
                
                .current_time,

                .correct_override,
                .correct_time,
                .correct_valid
            );


    // -----------------------------------------
    // リファレンス(疑似マスター)
    // -----------------------------------------

    logic   [TIMER_WIDTH-1:0]  ref_time;
    always_ff @(posedge ref_clk) begin
        if ( reset ) begin
            ref_time <= '0;
        end
        else begin
            ref_time <= ref_time + TIMER_WIDTH'(1);
        end
    end
    wire    ref_override = (ref_time == '0);
    wire    ref_valid    = (ref_time % TIMER_WIDTH'(10000) == '0);


    logic   [TIMER_WIDTH-1:0]   rx_time;
    logic                       rx_override;
    logic                       rx_valid;
    jelly2_data_async
            #(
                .ASYNC      (1),
                .DATA_WIDTH (1+64)
            )
        i_data_async
            (
                .s_reset    (reset),
                .s_clk      (ref_clk),
                .s_data     ({ref_override, ref_time}),
                .s_valid    (ref_valid),
                .s_ready    (),
                
                .m_reset    (reset),
                .m_clk      (clk),
                .m_data     ({rx_override, rx_time}),
                .m_valid    (rx_valid),
                .m_ready    (1'b1)
            );

    assign correct_override = rx_override;
    assign correct_time     = rx_time;
    assign correct_valid    = rx_valid;


    // debug
    logic   signed  [TIMER_WIDTH-1:0]   time_error;
    assign time_error = ref_time - current_time;


endmodule


`default_nettype wire


// end of file
