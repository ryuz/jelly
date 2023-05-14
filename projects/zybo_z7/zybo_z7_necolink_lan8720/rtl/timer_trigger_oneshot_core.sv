
`timescale 1ns / 1ps
`default_nettype none

module timer_trigger_oneshot_core
        #(
            parameter   int unsigned    TIME_WIDTH     = 32
        )
        (
            input   var logic                           reset,
            input   var logic                           clk,
            input   var logic                           cke,

            input   var logic                           enable,

            input   var logic   [TIME_WIDTH-1:0]        current_time,
            input   var logic   [TIME_WIDTH-1:0]        next_time,

            output  var logic                           out_trigger
        );

    localparam  type    t_diff = logic signed [TIME_WIDTH-1:0];

    t_diff          diff_time;
    assign diff_time = next_time - current_time;

    logic           ready;
    logic           trigger;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            ready   <= 1'b0;
            trigger <= 1'b0;
        end
        else if ( cke ) begin
            if ( diff_time < 0 ) begin
                ready   <= 1'b0;
                trigger <= ready & enable;
            end
            else begin
                ready   <= 1'b1;
                trigger <= 1'b0;
            end
        end
    end

    assign out_trigger = trigger;

endmodule


`default_nettype wire


// end of file
