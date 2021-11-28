// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_rtos_timer
        #(
            parameter   int                         SYSTIM_WIDTH = 64,
            parameter   int                         PRESCL_WIDTH = 32,
            parameter   bit                         USE_SET_PSCL = 1,
            parameter   bit                         USE_SET_TIM  = 1,
            parameter   bit     [SYSTIM_WIDTH-1:0]  INIT_SYSTIM  = '0,
            parameter   bit     [PRESCL_WIDTH-1:0]  INIT_PRESCL  = '0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            input   wire                            cke,

            output  reg                             time_tick,
            output  reg     [SYSTIM_WIDTH-1:0]      systim,

            input   wire    [PRESCL_WIDTH-1:0]      set_pscl_scale,
            input   wire                            set_pscl_valid,

            input   wire    [SYSTIM_WIDTH-1:0]      set_tim_systim,
            input   wire                            set_tim_valid
        );

    logic           set_pscl;
    logic           set_tim;
    assign set_pscl = set_pscl_valid & USE_SET_PSCL;
    assign set_tim  = set_tim_valid  & USE_SET_TIM;


    // prescaler
    logic   [PRESCL_WIDTH-1:0]  prescaler_scale;
    logic   [PRESCL_WIDTH-1:0]  prescaler_count_next;
    logic   [PRESCL_WIDTH-1:0]  prescaler_count;

    always_comb begin : blk_prescaler
        prescaler_count_next = prescaler_count;
        if ( prescaler_count_next != '0 ) begin
            prescaler_count_next = prescaler_count - 1'b1;
        end
        else begin
            prescaler_count_next = prescaler_scale;
        end
    end

    always_ff @(posedge clk) begin
        if ( reset ) begin
            time_tick       <= (INIT_PRESCL == '0);
            prescaler_scale <= INIT_PRESCL;
            prescaler_count <= INIT_PRESCL;
        end
        else if ( cke ) begin
            prescaler_count <= prescaler_count_next;
            time_tick       <= (prescaler_count_next == '0);

            if ( set_pscl ) begin
                prescaler_scale <= set_pscl_scale;
            end
        end
    end


    // system timer
    always_ff @(posedge clk) begin
        if ( reset ) begin
            systim <= INIT_SYSTIM;
        end
        else if ( cke ) begin
            systim <= systim + 1'b1;

            if ( set_tim ) begin
                systim <= set_tim_systim;
            end
        end
    end

endmodule


`default_nettype wire


// End of file
