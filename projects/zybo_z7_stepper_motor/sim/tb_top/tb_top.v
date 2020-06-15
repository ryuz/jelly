// ---------------------------------------------------------------------------
//
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    localparam RATE = 1000.0/125.0;
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #1000000000
        $finish;
    end
    
    
    reg     reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;
    
    reg     clk = 1'b1;
    always #(RATE/2.0) clk = ~clk;
    
    
    // ----------------------------------
    //  top net
    // ----------------------------------
    
    wire            bldc_ap_en;
    wire            bldc_an_en;
    wire            bldc_bp_en;
    wire            bldc_bn_en;
    wire            bldc_ap_hl;
    wire            bldc_an_hl;
    wire            bldc_bp_hl;
    wire            bldc_bn_hl;
    
    wire    [3:0]   led;
    
    zybo_z7_stepper_motor
            #(
                .MICROSTEP_WIDTH    (8)
            )
        i_top
            (
                .in_reset           (reset),
                .in_clk125          (clk),
                
                .dip_sw             (4'b0111),
                
                .bldc_ap_en         (bldc_ap_en),
                .bldc_an_en         (bldc_an_en),
                .bldc_bp_en         (bldc_bp_en),
                .bldc_bn_en         (bldc_bn_en),
                .bldc_ap_hl         (bldc_ap_hl),
                .bldc_an_hl         (bldc_an_hl),
                .bldc_bp_hl         (bldc_bp_hl),
                .bldc_bn_hl         (bldc_bn_hl)
            );
    
    
endmodule


`default_nettype wire


// end of file
