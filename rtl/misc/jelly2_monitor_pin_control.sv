// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_monitor_pin_control
        #(
            parameter   int                         OUTPUT_WIDTH     = 8,
            parameter   int                         INPUT_WIDTH      = 32,
            parameter   int                         SELECT_WIDTH     = $clog2(INPUT_WIDTH),

            parameter   int                         WB_ADR_WIDTH     = 8,
            parameter   int                         WB_DAT_WIDTH     = 32,
            parameter   int                         WB_SEL_WIDTH     = (WB_DAT_WIDTH / 8),
            
            parameter   bit     [WB_ADR_WIDTH-1:0]  CONFIG_BASE      = WB_ADR_WIDTH'('h20),
            parameter   bit     [WB_DAT_WIDTH-1:0]  CORE_ID          = WB_DAT_WIDTH'(32'h527a_f012),
            parameter   bit     [WB_DAT_WIDTH-1:0]  CORE_VERSION     = WB_DAT_WIDTH'(32'h0001_0000),
            parameter   bit     [OUTPUT_WIDTH-1:0]  INIT_OVERRIDE    = '0,
            parameter   bit     [OUTPUT_WIDTH-1:0]  INIT_OUT_VALUE   = '0
        )
        (
            input   wire    [INPUT_WIDTH-1:0]           in_data,
            output  reg     [OUTPUT_WIDTH-1:0]          out_data,
            
            input   wire                                s_wb_rst_i,
            input   wire                                s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]          s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]          s_wb_dat_i,
            output  reg     [WB_DAT_WIDTH-1:0]          s_wb_dat_o,
            input   wire                                s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]          s_wb_sel_i,
            input   wire                                s_wb_stb_i,
            output  reg                                 s_wb_ack_o
        );
    
    
    // -------------------------------------
    //  Register
    // -------------------------------------
    
    // register address offset
    localparam  bit [WB_ADR_WIDTH-1:0]  ADR_CORE_ID        = WB_ADR_WIDTH'('h00);
    localparam  bit [WB_ADR_WIDTH-1:0]  ADR_CORE_VERSION   = WB_ADR_WIDTH'('h01);
    localparam  bit [WB_ADR_WIDTH-1:0]  ADR_IN_DATA        = WB_ADR_WIDTH'('h10);
    localparam  bit [WB_ADR_WIDTH-1:0]  CONFIG_STEP        = WB_ADR_WIDTH'('h04);
    localparam  bit [WB_ADR_WIDTH-1:0]  OFFSET_SELECT      = WB_ADR_WIDTH'('h00);
    localparam  bit [WB_ADR_WIDTH-1:0]  OFFSET_OVERRIDE    = WB_ADR_WIDTH'('h01);
    localparam  bit [WB_ADR_WIDTH-1:0]  OFFSET_OUT_VALUE   = WB_ADR_WIDTH'('h02);
    localparam  bit [WB_ADR_WIDTH-1:0]  OFFSET_MONITOR     = WB_ADR_WIDTH'('h03);
    
    // registers
    logic   [INPUT_WIDTH-1:0]                       reg_in_data;
    logic   [OUTPUT_WIDTH-1:0][SELECT_WIDTH-1:0]    reg_select;
    logic   [OUTPUT_WIDTH-1:0]                      reg_override;
    logic   [OUTPUT_WIDTH-1:0]                      reg_out_value;
    logic   [OUTPUT_WIDTH-1:0]                      reg_monitor;

    function [WB_DAT_WIDTH-1:0] reg_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] wdat,
                                        input [WB_SEL_WIDTH-1:0] msk
                                    );
    begin
        for ( int i = 0; i < WB_DAT_WIDTH; ++i ) begin
            reg_mask[i] = msk[i/8] ? wdat[i] : org[i];
        end
    end
    endfunction

    always_ff @(posedge s_wb_clk_i ) begin
        if ( s_wb_rst_i ) begin
            for ( int i = 0; i < OUTPUT_WIDTH; ++i ) begin
                reg_select   [i] <= SELECT_WIDTH'(i);
                reg_override [i] <= INIT_OVERRIDE[i];
                reg_out_value[i] <= INIT_OUT_VALUE[i];
            end
        end
        else begin
            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                for ( int i = 0; i < OUTPUT_WIDTH; ++i ) begin
                    case ( s_wb_adr_i - (CONFIG_BASE  + CONFIG_STEP * WB_ADR_WIDTH'(i)) )
                    OFFSET_SELECT:     reg_select   [i] <=  SELECT_WIDTH'(reg_mask(WB_DAT_WIDTH'(reg_select   [i]), s_wb_dat_i, s_wb_sel_i));
                    OFFSET_OVERRIDE:   reg_override [i] <=             1'(reg_mask(WB_DAT_WIDTH'(reg_override [i]), s_wb_dat_i, s_wb_sel_i));
                    OFFSET_OUT_VALUE:  reg_out_value[i] <=             1'(reg_mask(WB_DAT_WIDTH'(reg_out_value[i]), s_wb_dat_i, s_wb_sel_i));
                    default: ;
                    endcase
                end
            end
        end
    end

    always_ff @(posedge s_wb_clk_i ) begin
        reg_in_data <= in_data;
        reg_monitor <= out_data;
    end
    
    // register read
    always_comb begin : blk_wb_dat_o 
        s_wb_dat_o = '0;
        
        case (s_wb_adr_i)
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(CORE_ID);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(CORE_VERSION);
        default: ;
        endcase

        for ( int i = 0; i < (INPUT_WIDTH+1)/WB_DAT_WIDTH; ++i ) begin
            if ( s_wb_adr_i == ADR_IN_DATA + WB_ADR_WIDTH'(i) ) begin
                s_wb_dat_o = WB_DAT_WIDTH'(reg_in_data >> (WB_DAT_WIDTH * i));
            end
        end

        for ( int i = 0; i < OUTPUT_WIDTH; ++i ) begin
            case ( s_wb_adr_i - (CONFIG_BASE  + CONFIG_STEP * WB_ADR_WIDTH'(i)) )
            OFFSET_SELECT:    s_wb_dat_o = WB_DAT_WIDTH'(reg_select   [i]);
            OFFSET_OVERRIDE:  s_wb_dat_o = WB_DAT_WIDTH'(reg_override [i]);
            OFFSET_OUT_VALUE: s_wb_dat_o = WB_DAT_WIDTH'(reg_out_value[i]);
            OFFSET_MONITOR:   s_wb_dat_o = WB_DAT_WIDTH'(out_data     [i]);
            default: ;
            endcase
        end
    end
    
    always_comb s_wb_ack_o = s_wb_stb_i;
    
    always_comb begin
        for ( int i = 0; i < OUTPUT_WIDTH; ++i ) begin
            if ( reg_override[i] ) begin
                out_data[i] = reg_out_value[i];
            end
            else begin
                out_data[i] = in_data[reg_select[i]];
            end
        end
    end

endmodule


`default_nettype wire


// end of file
