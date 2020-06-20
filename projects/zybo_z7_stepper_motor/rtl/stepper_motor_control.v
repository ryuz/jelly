// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  stepping motor control
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module stepper_motor_control
        #(
            parameter   CORE_ID         = 32'h5a5a_5a5a,
            
            parameter   WB_ADR_WIDTH    = 6,
            parameter   WB_DAT_SIZE     = 3,
            parameter   WB_DAT_WIDTH    = (8 << WB_DAT_SIZE),
            parameter   WB_SEL_WIDTH    = (1 << WB_DAT_SIZE),
            
            parameter   Q_WIDTH         = 16,       // 小数点サイズ
            parameter   MICROSTEP_WIDTH = 12,
            parameter   POS_WIDTH       = 16 + Q_WIDTH,
            parameter   SPEED_WIDTH     = Q_WIDTH,
            parameter   ACC_WIDTH       = Q_WIDTH,
            
            parameter   INIT_CONTROL    = 4'b0000,
            parameter   INIT_CUR_POS    = 0,
            parameter   INIT_CUR_ACC    = 0,
            parameter   INIT_CUR_SPEED  = 0,
            parameter   INIT_MAX_ACC    = 100,
            parameter   INIT_MAX_SPEED  = 100
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,
            
            output  wire                        out_en,
            output  wire                        out_a,
            output  wire                        out_b
        );
    
    
    localparam  ADR_CORE_ID    = 0;
    localparam  ADR_CONTROL    = 2;
    
    localparam  ADR_CUR_ACC    = 4;
    localparam  ADR_CUR_SPEED  = 5;
    localparam  ADR_CUR_POS    = 6;
    
    localparam  ADR_MAX_ACC    = 8;
    localparam  ADR_MAX_SPEED  = 9;
    
    wire                                update;
    
    reg             [3:0]               reg_control;
    reg     signed  [POS_WIDTH-1:0]     reg_cur_pos;
    reg     signed  [ACC_WIDTH-1:0]     reg_cur_acc;
    reg     signed  [SPEED_WIDTH-1:0]   reg_cur_speed;
    reg             [ACC_WIDTH-1:0]     reg_max_acc;
    reg             [SPEED_WIDTH-1:0]   reg_max_speed;
    
    wire    signed  [ACC_WIDTH:0]       max_acc   = {1'b0, reg_max_acc};
    wire    signed  [SPEED_WIDTH:0]     max_speed = {1'b0, reg_max_speed};
    
    reg     signed  [ACC_WIDTH-1:0]     reg_acc;
    reg     signed  [SPEED_WIDTH-1:0]   reg_speed;
    
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
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_control   <= INIT_CONTROL;
            reg_cur_pos   <= INIT_CUR_POS;
            reg_cur_acc   <= INIT_CUR_ACC;
            reg_cur_speed <= INIT_CUR_SPEED;
            reg_max_acc   <= INIT_MAX_ACC;
            reg_max_speed <= INIT_MAX_SPEED;
            
            reg_acc       <= 0;
            reg_speed     <= 0;
        end
        else begin
            // acceleration
            reg_acc   <= reg_cur_acc;
            if ( reg_cur_acc > +max_acc ) begin reg_acc <= +max_acc; end
            if ( reg_cur_acc < -max_acc ) begin reg_acc <= -max_acc; end
            
            // speed
            reg_speed <= reg_cur_speed + reg_acc;
            if ( reg_speed + reg_acc > +max_speed ) begin reg_speed <= +max_speed; end
            if ( reg_speed + reg_acc < -max_speed ) begin reg_speed <= -max_speed; end
            
            // update
            if ( update && reg_control[0] ) begin
                reg_cur_pos   <= reg_cur_pos + reg_speed;
                reg_cur_speed <= reg_speed;
            end
            
            // write
            if ( s_wb_stb_i && s_wb_we_i ) begin
                case ( s_wb_adr_i )
                ADR_CONTROL:    reg_control   <= reg_mask(reg_control,   s_wb_dat_i, s_wb_sel_i);
                ADR_CUR_ACC:    reg_cur_acc   <= reg_mask(reg_cur_acc,   s_wb_dat_i, s_wb_sel_i);
                ADR_CUR_SPEED:  reg_cur_speed <= reg_mask(reg_cur_speed, s_wb_dat_i, s_wb_sel_i);
                ADR_MAX_ACC:    reg_max_acc   <= reg_mask(reg_max_acc,   s_wb_dat_i, s_wb_sel_i);
                ADR_MAX_SPEED:  reg_max_speed <= reg_mask(reg_max_speed, s_wb_dat_i, s_wb_sel_i);
                endcase
            end
        end
    end
    
    assign s_wb_dat_o = (s_wb_adr_i == ADR_CORE_ID  ) ? CORE_ID       :
                        (s_wb_adr_i == ADR_CONTROL  ) ? reg_control   :
                        (s_wb_adr_i == ADR_CUR_POS  ) ? reg_cur_pos   :
                        (s_wb_adr_i == ADR_CUR_ACC  ) ? reg_cur_acc   :
                        (s_wb_adr_i == ADR_CUR_SPEED) ? reg_cur_speed :
                        (s_wb_adr_i == ADR_MAX_ACC  ) ? reg_max_acc   :
                        (s_wb_adr_i == ADR_MAX_SPEED) ? reg_max_speed :
                        0;
    assign s_wb_ack_o = s_wb_stb_i;
    
    
    bipolar_stepper_motor_drive
            #(
                .Q_WIDTH            (Q_WIDTH),
                .MICROSTEP_WIDTH    (MICROSTEP_WIDTH)
            )
        i_bipolar_stepper_motor_drive
            (
                .reset              (reset),
                .clk                (clk),
                
                .microstep_en       (~reg_control[1]),
                .nanostep_en        (~reg_control[2]),
                .asyc_update_en     (reg_control[3]),
                
                .phase              (reg_cur_pos[Q_WIDTH+1:0]),
                .update             (update),
                
                .out_a              (out_a),
                .out_b              (out_b)
            );
    
    assign out_en = reg_control[0];
    
endmodule


`default_nettype wire


// end of file
