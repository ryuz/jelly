
`timescale 1ns / 1ps
`default_nettype none

module timer_generate_pulse_core
        #(
            parameter   int unsigned    TIME_WIDTH     = 32,
            parameter   int unsigned    DURATION_WIDTH = TIME_WIDTH
        )
        (
            input   var logic                           reset,
            input   var logic                           clk,
            input   var logic                           cke,

            input   var logic   [TIME_WIDTH-1:0]        current_time,
            input   var logic                           trigger,

            input   var logic                           enable,
            input   var logic   [DURATION_WIDTH-1:0]    param_duration,

            output  var logic                           out_pulse
        );

    localparam  type    t_time = logic        [TIME_WIDTH-1:0];
    localparam  type    t_diff = logic signed [TIME_WIDTH-1:0];

    t_time          end_time;
    t_diff          diff_time;
    assign diff_time = end_time - current_time;

    logic   pulse;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            pulse    <= 1'b0;
            end_time <= 'x;
        end
        else if ( cke ) begin
            if ( !pulse ) begin
                pulse    <= trigger && enable;
                end_time <= current_time + t_diff'(param_duration);
            end
            else begin
                if ( diff_time < 0 ) begin
                    pulse    <= 1'b0;
                    end_time <= 'x;
                end
            end
        end
    end

    assign out_pulse = pulse;

endmodule


`default_nettype wire


// end of file
