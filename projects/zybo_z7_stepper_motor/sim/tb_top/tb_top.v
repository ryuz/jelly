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
    
    wire            stm_ap_en;
    wire            stm_an_en;
    wire            stm_bp_en;
    wire            stm_bn_en;
    wire            stm_ap_hl;
    wire            stm_an_hl;
    wire            stm_bp_hl;
    wire            stm_bn_hl;
    
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
                
                .stm_ap_en          (stm_ap_en),
                .stm_an_en          (stm_an_en),
                .stm_bp_en          (stm_bp_en),
                .stm_bn_en          (stm_bn_en),
                .stm_ap_hl          (stm_ap_hl),
                .stm_an_hl          (stm_an_hl),
                .stm_bp_hl          (stm_bp_hl),
                .stm_bn_hl          (stm_bn_hl)
            );
    
    
endmodule


`default_nettype wire


// end of file
