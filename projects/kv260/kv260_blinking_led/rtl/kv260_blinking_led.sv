// KV260 sample design

`timescale 1ns / 1ps
`default_nettype none

module kv260_blinking_led
        #(
            parameter  int COUNT_LIMIT = 100000000
        )
        (
            output  var logic   [7:0]   pmod    ,
            output  var logic           fan_en
        );
    
    // PS
    logic           reset   ;    // sync reset
    logic           clk     ;    // 100MHz
    design_1
        u_design_1
            (
                .fan_en     (fan_en ),
                .reset      (reset  ),
                .clk        (clk    )
            );
    
    // counter
    (* MARK_DEBUG = "true" *)   logic   [26:0]     counter;
    (* MARK_DEBUG = "true" *)   logic   [7:0]      led    ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= '0;
            led     <= '0;
        end
        else begin
            counter <= counter + 1'b1;
            if ( counter >= 27'(COUNT_LIMIT - 1) ) begin // 1秒をカウントする
                counter <= '0;
                led     <= led + 1'b1;
            end
        end
    end

    // PMOD output
    assign pmod = led;
   
endmodule

`default_nettype wire

// end of file
