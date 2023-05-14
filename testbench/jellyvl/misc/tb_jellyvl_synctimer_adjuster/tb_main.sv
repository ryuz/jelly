
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire        reset,
            input   wire        clk,

            input   wire        ref_clk
        );


    parameter int unsigned TIMER_WIDTH     = 20                   ; // タイマのbit幅
    parameter int unsigned CYCLE_WIDTH     = 20                   ; // 自クロックサイクルカウンタのbit数
    parameter int unsigned ERROR_WIDTH     = 20                   ; // 誤差計算時のbit幅
    parameter int unsigned ERROR_Q         = 8                    ; // 誤差計算時に追加する固定小数点数bit数
    parameter int unsigned ADJUST_WIDTH    = CYCLE_WIDTH + ERROR_Q; // 補正周期のbit幅
    parameter int unsigned ADJUST_Q        = ERROR_Q              ; // 補正周期に追加する固定小数点数bit数
    parameter int unsigned LPF_GAIN_CYCLE  = 4                    ; // 自クロックサイクルカウントLPFの更新ゲイン(1/2^N)
    parameter int unsigned LPF_GAIN_PERIOD = 4                    ; // 周期補正のLPFの更新ゲイン(1/2^N)
    parameter int unsigned LPF_GAIN_PHASE  = 4                    ; // 位相補正のLPFの更新ゲイン(1/2^N)
    parameter bit          DEBUG           = 1'b1                 ;
    parameter bit          SIMULATION      = 1'b1                 ;


    logic signed [ERROR_WIDTH-1:0]  param_adjust_min = -1000;
    logic signed [ERROR_WIDTH-1:0]  param_adjust_max = +1000;

    logic [TIMER_WIDTH-1:0]         current_time;

    logic                           correct_renew;
    logic [TIMER_WIDTH-1:0]         correct_time    ;
    logic                           correct_valid   ;

    logic                           adjust_sign ;
    logic                           adjust_valid;
    logic                           adjust_ready;

    jellyvl_synctimer_adjuster
            #(
                .TIMER_WIDTH        (TIMER_WIDTH    ),
                .CYCLE_WIDTH        (CYCLE_WIDTH    ),
                .ERROR_WIDTH        (ERROR_WIDTH    ),
                .ERROR_Q            (ERROR_Q        ),
                .ADJUST_WIDTH       (ADJUST_WIDTH   ),
                .ADJUST_Q           (ADJUST_Q       ),
                .LPF_GAIN_CYCLE     (LPF_GAIN_CYCLE ),
                .LPF_GAIN_PERIOD    (LPF_GAIN_PERIOD),
                .LPF_GAIN_PHASE     (LPF_GAIN_PHASE ),
                .DEBUG              (DEBUG          ),
                .SIMULATION         (SIMULATION     )
            )
        i_synctimer_adjuster
            (
                reset,
                clk  ,

                param_adjust_min,
                param_adjust_max,

                current_time,

                correct_renew,
                correct_time,
                correct_valid,

                adjust_sign ,
                adjust_valid,
                adjust_ready
            );


    int                         cycle;
    int                         count;

    logic   [TIMER_WIDTH-1:0]   mem_correct_time    [0:4095];
    logic   [TIMER_WIDTH-1:0]   mem_current_time    [0:4095];
    logic   [27:0]              mem_adjust          [0:4095];
    logic   [27:0]              mem_x0              [0:4095];
    logic   [27:0]              mem_v0              [0:4095];
    logic   [27:0]              mem_x               [0:4095];
    logic   [27:0]              mem_v               [0:4095];
    initial begin
        $readmemh("../_correct.hex", mem_correct_time);
        $readmemh("../_current.hex", mem_current_time);
        $readmemh("../_adjust.hex",  mem_adjust);
        $readmemh("../_x0.hex",      mem_x0);
        $readmemh("../_v0.hex",      mem_v0);
        $readmemh("../_x.hex",       mem_x);
        $readmemh("../_v.hex",       mem_v);
    end

    logic   [TIMER_WIDTH-1:0]   test_correct_time;
    logic   [TIMER_WIDTH-1:0]   test_current_time;
    logic   [27:0]              test_adjust      ;
    logic   [27:0]              test_x0;
    logic   [27:0]              test_v0;
    logic   [27:0]              test_x;
    logic   [27:0]              test_v;
    assign test_correct_time = mem_correct_time[count];
    assign test_current_time = mem_current_time[count];
    assign test_adjust       = mem_adjust      [count];
    assign test_x0           = mem_x0          [count];
    assign test_v0           = mem_v0          [count];
    assign test_x            = mem_x           [count];
    assign test_v            = mem_v           [count];

    assign correct_time = test_correct_time;
    assign current_time = test_current_time;


    always_ff @(posedge clk) begin
        if ( reset ) begin
            cycle <= '0;
            count <= '0;
            correct_renew <= '0;
            correct_valid <= '0;
        end
        cycle <= cycle + 1;
        if ( correct_valid ) begin
            count <= count + 1'b1;
        end
        correct_valid <= cycle % 100 == 0;
        
        if ( cycle % 100 == 50 ) begin
            if ( count < 10 ) begin
                force i_synctimer_adjuster.error_adjust_value = test_adjust;
                force i_synctimer_adjuster.error_estimate_x0  = test_x0;
                force i_synctimer_adjuster.error_estimate_v0  = test_v0;
                force i_synctimer_adjuster.error_estimate_x   = test_x;
                force i_synctimer_adjuster.error_estimate_v   = test_v;
            end
            else begin
                release i_synctimer_adjuster.error_adjust_value;
                release i_synctimer_adjuster.error_estimate_x0 ;
                release i_synctimer_adjuster.error_estimate_v0 ;
                release i_synctimer_adjuster.error_estimate_x ;
                release i_synctimer_adjuster.error_estimate_v ;
            end
        end

        if ( count > 4096 ) begin
            $finish();
        end
    end

endmodule


`default_nettype wire


// end of file
