// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Ultra96V2 udmabuf test
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module zybo_z7_stepping_motor
            #(
                parameter   SUB_PAHSE_WIDTH = 12
            )
            (
                input   wire            in_reset,
                input   wire            in_clk125,
                
                output  wire            bldc_ap_en,
                output  wire            bldc_an_en,
                output  wire            bldc_bp_en,
                output  wire            bldc_bn_en,
                output  wire            bldc_ap_hl,
                output  wire            bldc_an_hl,
                output  wire            bldc_bp_hl,
                output  wire            bldc_bn_hl,
                
                input   wire    [3:1]   push_sw,
                input   wire    [3:0]   dip_sw,
                output  wire    [3:0]   led
            );
    
    wire    reset = in_reset;
    
    wire    clk = in_clk125;
    
    
    
    reg     [31:0]     reg_counter;
    always @(posedge clk) begin
        reg_counter <= reg_counter + 5;
    end
    
    
    wire    out_a;
    wire    out_b;
    stepping_motor_drive
            #(
                .MICROSTEP_WIDTH    (12),
                .ASYNC_UPDATE       (0)
            )
        i_stepping_motor_drive
            (
                .reset              (reset),
                .clk                (clk),
                
                .microstep_en       (dip_sw[1]),
                .phase              (reg_counter[25-3:12-3]),
                .update             (),
                
                .out_a              (out_a),
                .out_b              (out_b)
            );
    
    assign bldc_ap_hl =  out_a;
    assign bldc_an_hl = ~out_a;
    assign bldc_bp_hl =  out_b;
    assign bldc_bn_hl = ~out_b;
    
    
    /*
    wire    [1:0]   in_phase = reg_counter[25:24];
    
    reg     [3:0]   reg_out;
    always @(posedge clk) begin
        case ( in_phase )
        2'b00: reg_out <= 2'b00;
        2'b01: reg_out <= 2'b01;
        2'b10: reg_out <= 2'b11;
        2'b11: reg_out <= 2'b10;
        endcase
    end
    
    assign bldc_ap_hl =  reg_out[0];
    assign bldc_an_hl = ~reg_out[0];
    assign bldc_bp_hl =  reg_out[1];
    assign bldc_bn_hl = ~reg_out[1];
    
    */
    
    assign bldc_ap_en = dip_sw[0];
    assign bldc_an_en = dip_sw[0];
    assign bldc_bp_en = dip_sw[0];
    assign bldc_bn_en = dip_sw[0];
    
    
    
    // -----------------------------
    //  Test LED
    // -----------------------------
    
    assign led[0] = dip_sw[0];
    assign led[1] = bldc_ap_hl;
    assign led[2] = bldc_bp_hl;
    assign led[3] = reg_counter[24];
    
    
endmodule



`default_nettype wire


// end of file
