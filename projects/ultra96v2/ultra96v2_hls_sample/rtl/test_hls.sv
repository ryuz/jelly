// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  Test HLS
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module test_hls
        #(
            parameter   WB_ADR_WIDTH    = 6,
            parameter   WB_DAT_WIDTH    = 32,
            parameter   WB_SEL_WIDTH    = WB_DAT_WIDTH / 8
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  wire                                s_wb_ack_o
        );
    
    
    logic               c_ap_vld;
    logic               ap_start;
    logic               ap_done;
    logic               ap_idle;
    logic               ap_ready;
    logic   [31:0]      a;
    logic   [31:0]      b;
    logic   [31:0]      c;
    
    
    localparam  ADR_CORE_ID = 0;
    localparam  ADR_CONTROL = 4;
    localparam  ADR_STATUS  = 5;
    localparam  ADR_A       = 8;
    localparam  ADR_B       = 9;
    localparam  ADR_C       = 10;
    
    logic   [0:0]       reg_control;
    logic   [31:0]      reg_a;
    logic   [31:0]      reg_b;
    
    function [WB_DAT_WIDTH-1:0] reg_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            reg_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction
    
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_control <= 0;
            reg_a       <= 0;
            reg_b       <= 0;
        end
        else begin
            reg_control <= 1'b0;
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CONTROL:    reg_control <=  1'(reg_mask(WB_DAT_WIDTH'(reg_control), s_wb_dat_i, s_wb_sel_i));
                ADR_A:          reg_a       <= 32'(reg_mask(WB_DAT_WIDTH'(reg_a),       s_wb_dat_i, s_wb_sel_i));
                ADR_B:          reg_b       <= 32'(reg_mask(WB_DAT_WIDTH'(reg_b),       s_wb_dat_i, s_wb_sel_i));
                endcase
            end
        end
    end
    
    assign s_wb_dat_o = (s_wb_adr_i == ADR_CORE_ID) ? WB_DAT_WIDTH'(32'haa551234) :
                        (s_wb_adr_i == ADR_CONTROL) ? WB_DAT_WIDTH'(reg_control)  :
                        (s_wb_adr_i == ADR_STATUS ) ? WB_DAT_WIDTH'(ap_done)      :
                        (s_wb_adr_i == ADR_A      ) ? WB_DAT_WIDTH'(reg_a)        :
                        (s_wb_adr_i == ADR_B      ) ? WB_DAT_WIDTH'(reg_b)        :
                        (s_wb_adr_i == ADR_C      ) ? WB_DAT_WIDTH'(c)            :
                        0;
    assign s_wb_ack_o = s_wb_stb_i;
    
    assign ap_start = reg_control;
    assign a        = reg_a;
    assign b        = reg_b;
    
    divider_0
        i_divider_0
            (
                .c_ap_vld   (c_ap_vld),
                .ap_clk     (clk),
                .ap_rst     (reset),
                .ap_start   (ap_start),
                .ap_done    (ap_done),
                .ap_idle    (ap_idle),
                .ap_ready   (ap_ready),
                .a          (a),
                .b          (b),
                .c          (c)
            );
    
    
    
endmodule


`default_nettype wire


// end of file
