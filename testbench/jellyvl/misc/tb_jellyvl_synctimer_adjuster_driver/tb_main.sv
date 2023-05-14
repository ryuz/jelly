
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   wire        reset,
            input   wire        clk
        );

    parameter int unsigned CYCLE_WIDTH  = 24                   ; // 自クロックサイクルカウンタのbit数
    parameter int unsigned CYCLE_Q      = 8                    ; // 自クロックサイクルカウンタに追加する固定小数点数bit数
    parameter int unsigned ERROR_WIDTH  = 24                   ; // 誤差計算時のbit幅
    parameter int unsigned ERROR_Q      = 8                    ; // 誤差計算時に追加する固定小数点数bit数
    parameter int unsigned ADJUST_WIDTH = CYCLE_WIDTH + ERROR_Q; // 補正周期のbit幅
    parameter int unsigned ADJUST_Q     = ERROR_Q              ; // 補正周期に追加する固定小数点数bit数
    parameter bit          DEBUG        = 1'b1                 ;
    parameter bit          SIMULATION   = 1'b1             ;

    logic signed [ERROR_WIDTH + ERROR_Q-1:0] request_value;
    logic        [CYCLE_WIDTH + CYCLE_Q-1:0] request_cycle;
    logic                                    request_valid;

    logic adjust_sign;
    logic adjust_valid;
    logic adjust_ready;

    jellyvl_synctimer_adjust_gensig
        #(
                .CYCLE_WIDTH    (CYCLE_WIDTH ),
                .CYCLE_Q        (CYCLE_Q     ),
                .ERROR_WIDTH    (ERROR_WIDTH ),
                .ERROR_Q        (ERROR_Q     ),
                .ADJUST_WIDTH   (ADJUST_WIDTH),
                .ADJUST_Q       (ADJUST_Q    ),
                .DEBUG          (DEBUG       ),
                .SIMULATION     (SIMULATION  )
            )
        u_jellyvl_synctimer_adjust_gensig
            (
                .reset,
                .clk  ,

                .request_value,
                .request_cycle,
                .request_valid,

                .adjust_sign ,
                .adjust_valid,
                .adjust_ready
            );

    localparam type t_error   = logic signed [ERROR_WIDTH + ERROR_Q-1:0];
    localparam type t_cycle   = logic [CYCLE_WIDTH + CYCLE_Q-1:0];

    t_error     value_table[0:7];

    initial begin
        value_table[0] = t_error'(0); 
        value_table[1] = t_error'(+1); 
        value_table[2] = t_error'(-1); 
        value_table[3] = +t_error'(2 << ERROR_Q); 
        value_table[4] = -t_error'(3 << ERROR_Q); 
        value_table[5] = +t_error'(4 << ERROR_Q);
        value_table[6] = -t_error'(5 << ERROR_Q); 
        value_table[7] = +t_error'(6 << ERROR_Q);
//        value_table[6] = 32'h7fffffff;
//        value_table[7] = 32'h80000000;
    end


    logic   [9:0]       count;
    logic   [2:0]       rand_sel;
    always_ff @(posedge clk) begin
        if (reset) begin
            count         <= '0;
            request_valid <= '0;
            adjust_ready  <= '0;
            rand_sel      <= '0;
        end
        else begin
            count <= count + 1;
            adjust_ready = ~adjust_ready;

            request_valid <= (count == '0);

            if ( request_valid ) begin
                rand_sel <= 3'({$random()});
            end
        end
    end

    assign request_value = request_valid ? value_table[rand_sel] : 'x;
    assign request_cycle = request_valid ? 1024 << CYCLE_Q  : 'x;

endmodule


`default_nettype wire


// end of file
