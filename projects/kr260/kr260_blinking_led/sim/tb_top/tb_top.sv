
`timescale 1ns / 1ps
`default_nettype none

module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #10000000
        $finish;
    end
    
    // ---------------------------------
    //  reset and clock
    // ---------------------------------

    localparam RATE25 = 1000.0/25.00;

    logic       reset = 1'b1;
    initial #(RATE25 * 20) reset = 1'b0;

    logic       clk25 = 1'b1;
    initial forever #(RATE25/2.0) clk25 = ~clk25;

    
    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic   [1:0]   led     ;
    logic           fan_en  ;
    kr260_blinking_led
            #(
                .COUNT_LIMIT(25000  )   // シミュレーション時は高速にする
            )
        u_kr260_blinking_led
            (
                .clk        (clk25  ),
                .led        (led    ),
                .fan_en     (fan_en )
            );
    
    initial begin
        force u_kr260_blinking_led.u_design_1.reset_n  = ~reset;
    end

endmodule

`default_nettype wire
