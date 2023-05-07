
`timescale 1ns / 1ps
`default_nettype none


module timer_trigger_interval_core
        #(
            parameter   int unsigned            TIME_WIDTH     = 32,
            parameter   int unsigned            INTERVAL_WIDTH = TIME_WIDTH,
            parameter   bit [TIME_WIDTH-1:0]    INIT_NEXT_TIME = '0
        )
        (
            input   var logic                           reset,
            input   var logic                           clk,
            input   var logic                           cke,

            input   var logic   [TIME_WIDTH-1:0]        current_time,

            input   var logic                           enable,
            input   var logic   [INTERVAL_WIDTH-1:0]    param_interval,
            input   var logic                           param_next_time_en,
            input   var logic   [TIME_WIDTH-1:0]        param_next_time,

            output  var logic   [TIME_WIDTH-1:0]        out_next_time,
            output  var logic                           out_trigger
        );

    localparam  type    t_time = logic        [TIME_WIDTH-1:0];
    localparam  type    t_diff = logic signed [TIME_WIDTH-1:0];

    t_diff          diff_time;
    assign diff_time = out_next_time - current_time;

    logic   [TIME_WIDTH-1:0]        next_time;
    logic                           trigger;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            trigger   <= 1'b0;
            next_time <= INIT_NEXT_TIME;
        end
        else if ( cke ) begin
            if ( enable ) begin
                trigger   <= 1'b0;
                if ( diff_time < 0 ) begin
                    trigger   <= 1'b1;
                    next_time <= next_time + t_time'(param_interval);
                end
            end
            else begin
                trigger   <= 1'b0;
                if ( param_next_time_en ) begin
                    next_time <= param_next_time;
                end
                else begin
                    next_time <= current_time + t_time'(param_interval);
                end
            end
        end
    end
    assign out_next_time = next_time;
    assign out_trigger   = trigger  ;

endmodule


`default_nettype wire


// end of file
