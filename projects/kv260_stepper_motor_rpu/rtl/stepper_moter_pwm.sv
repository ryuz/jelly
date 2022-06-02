// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module stepper_moter_pwm
            #(
                parameter   int                             WB_ADR_WIDTH     = 8,
                parameter   int                             WB_DAT_WIDTH     = 32,
                parameter   int                             WB_SEL_WIDTH     = (WB_DAT_WIDTH / 8),

                parameter   int                             COUNTER_WIDTH    = 16,
                parameter   int                             STEP_WIDTH       = COUNTER_WIDTH,
                parameter   int                             POSITION_WIDTH   = COUNTER_WIDTH + 2,

                parameter   bit     [0:0]                   INIT_CTL_CONTROL = '0,

                parameter   bit     [0:0]                   INIT_IRQ_ENABLE  = '0,

                parameter   bit     [POSITION_WIDTH-1:0]    INIT_POSITION    = '0,
                parameter   bit     [STEP_WIDTH-1:0]        INIT_STEP        = 'd1,
                parameter   bit     [1:0]                   INIT_PHASE       = 2'b00
            )
            (
                input   wire                            reset,
                input   wire                            clk,

                input   wire    [WB_ADR_WIDTH-1:0]      s_wb_adr_i,
                output  reg     [WB_DAT_WIDTH-1:0]      s_wb_dat_o,
                input   wire    [WB_DAT_WIDTH-1:0]      s_wb_dat_i,
                input   wire    [WB_SEL_WIDTH-1:0]      s_wb_sel_i,
                input   wire                            s_wb_we_i,
                input   wire                            s_wb_stb_i,
                output  reg                             s_wb_ack_o,

                output  wire    [0:0]                   out_irq,

                output  reg                             motor_en,
                output  reg     [1:0]                   motor_phase
            );


    // ---------------------------------
    //  Register
    // ---------------------------------
    
    // register address offset
    localparam  ADR_CORE_ID      = 'h00;
    localparam  ADR_CORE_VERSION = 'h01;
    localparam  ADR_CORE_CONFIG  = 'h03;
    localparam  ADR_CTL_CONTROL  = 'h04;
    localparam  ADR_IRQ_ENABLE   = 'h08;
    localparam  ADR_IRQ_STATUS   = 'h09;
    localparam  ADR_IRQ_CLR      = 'h0a;
    localparam  ADR_IRQ_SET      = 'h0b;
    localparam  ADR_POSITION     = 'h10;
    localparam  ADR_STEP         = 'h12;
    localparam  ADR_PHASE        = 'h14;


    // registers
    logic   [0:0]                   reg_ctl_control;

    logic   [0:0]                   reg_irq_enable;
    logic   [0:0]                   reg_irq_status;

    logic   [POSITION_WIDTH-1:0]    reg_position;
    logic   [STEP_WIDTH-1:0]        reg_step;
    logic   [1:0]                   reg_phase;

    logic                           enable;
    logic                           update;

    always_comb enable     = reg_ctl_control[0];
    
    // write mask
    function [WB_DAT_WIDTH-1:0] write_mask(
                                        input [WB_DAT_WIDTH-1:0] org,
                                        input [WB_DAT_WIDTH-1:0] dat,
                                        input [WB_SEL_WIDTH-1:0] sel
                                    );
    integer i;
    begin
        for ( i = 0; i < WB_DAT_WIDTH; i = i+1 ) begin
            write_mask[i] = sel[i/8] ? dat[i] : org[i];
        end
    end
    endfunction
    
    always_ff @(posedge clk ) begin
        if ( reset ) begin
            reg_ctl_control <= INIT_CTL_CONTROL;
            reg_irq_enable  <= INIT_IRQ_ENABLE;
            reg_irq_status  <= '0;
            reg_position    <= INIT_POSITION;
            reg_step        <= INIT_STEP;
            reg_phase       <= INIT_PHASE;
        end
        else begin
            if ( update ) begin
                reg_irq_status <= 1'b1;
            end

            // register write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CTL_CONTROL:    reg_ctl_control <=              1'(write_mask(WB_DAT_WIDTH'(reg_ctl_control), s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_ENABLE:     reg_irq_enable  <=              1'(write_mask(WB_DAT_WIDTH'(reg_irq_enable ), s_wb_dat_i, s_wb_sel_i));
                ADR_IRQ_CLR:        reg_irq_status  <=             ~1'(write_mask(WB_DAT_WIDTH'(0              ), s_wb_dat_i, s_wb_sel_i)) & reg_irq_status;
                ADR_IRQ_SET:        reg_irq_status  <=              1'(write_mask(WB_DAT_WIDTH'(0              ), s_wb_dat_i, s_wb_sel_i)) | reg_irq_status;
                ADR_POSITION:       reg_position    <= POSITION_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_position   ), s_wb_dat_i, s_wb_sel_i));
                ADR_STEP:           reg_step        <=     STEP_WIDTH'(write_mask(WB_DAT_WIDTH'(reg_phase      ), s_wb_dat_i, s_wb_sel_i));
                ADR_PHASE:          reg_phase       <=              2'(write_mask(WB_DAT_WIDTH'(reg_phase      ), s_wb_dat_i, s_wb_sel_i));
                default: ; 
                endcase
            end
          end
    end
    
    always_comb begin
        s_wb_dat_o = '0;
        case ( s_wb_adr_i )
        ADR_CORE_ID:        s_wb_dat_o = WB_DAT_WIDTH'(32'hffff3514);
        ADR_CORE_VERSION:   s_wb_dat_o = WB_DAT_WIDTH'(32'h00000000);
        ADR_CTL_CONTROL:    s_wb_dat_o = WB_DAT_WIDTH'(reg_ctl_control);
        ADR_IRQ_ENABLE:     s_wb_dat_o = WB_DAT_WIDTH'(reg_irq_enable);
        ADR_IRQ_STATUS:     s_wb_dat_o = WB_DAT_WIDTH'(reg_irq_status);
        ADR_IRQ_CLR:        s_wb_dat_o = WB_DAT_WIDTH'('0);
        ADR_IRQ_SET:        s_wb_dat_o = WB_DAT_WIDTH'('0);
        ADR_POSITION:       s_wb_dat_o = WB_DAT_WIDTH'(reg_position);
        ADR_STEP:           s_wb_dat_o = WB_DAT_WIDTH'(reg_step);
        ADR_PHASE:          s_wb_dat_o = WB_DAT_WIDTH'(reg_phase);
        default: ;
        endcase
    end

    always_comb s_wb_ack_o = s_wb_stb_i;
    
    always_comb out_irq = reg_irq_status & reg_irq_enable;



    // ---------------------------------
    //  Control
    // ---------------------------------

    logic   [COUNTER_WIDTH-1:0]     counter, counter_next;
    logic   [POSITION_WIDTH-1:0]    position;

    assign counter_next = counter + COUNTER_WIDTH'(reg_step);

    assign update       = (counter_next < counter);

    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= '0;
        end
        else begin
            if ( enable ) begin
                counter <= counter_next;
                if ( update ) begin
                    position <= reg_position;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            motor_phase <= '0;
        end
        else begin
            automatic   logic   [1:0]    phase;
            phase  = 2'((position + POSITION_WIDTH'(counter)) >> COUNTER_WIDTH);
            phase ^= reg_phase;

            motor_phase <= phase;
        end
    end

    always_comb motor_en = enable;

    
endmodule


