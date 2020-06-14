// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//  BLDC PWM
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module stepping_motor_drive
        #(
            parameter   MICROSTEP_WIDTH = 12,
            parameter   ASYNC_UPDATE    = 0
        )
        (
            input   wire                            reset,
            input   wire                            clk,
            
            input   wire                            microstep_en,
            input   wire    [2+MICROSTEP_WIDTH-1:0] phase,
            output  wire                            update,
            
            output  wire                            out_a,
            output  wire                            out_b
        );
    
    
    reg     [MICROSTEP_WIDTH-1:0]   st0_counter;
    reg     [1:0]                   st0_phase_main;
    reg     [MICROSTEP_WIDTH-1:0]   st0_phase_sub;
    reg     [1:0]                   st1_phase_main;
    reg     [MICROSTEP_WIDTH-1:0]   st1_phase_sub;
    reg     [1:0]                   st2_out;
    
    always @(posedge clk) begin
        if ( reset ) begin
            st0_counter    <= {MICROSTEP_WIDTH{1'b0}};
            st0_phase_main <= 2'd0;
            st0_phase_sub  <= {MICROSTEP_WIDTH{1'b0}};
            st1_phase_main <= 2'd0;
            st1_phase_sub  <= {MICROSTEP_WIDTH{1'b0}};
            st2_out        <= 2'b00;
        end
        else begin
            // stage 0
            st0_counter <= st0_counter + 1'b1;
            if ( update || ASYNC_UPDATE ) begin
                {st0_phase_main, st0_phase_sub} <= phase;
            end
            
            // stage 1
            if ( microstep_en ) begin
                {st1_phase_main, st1_phase_sub} <= {st0_phase_main, st0_phase_sub} + st0_counter;
            end
            else begin
                {st1_phase_main, st1_phase_sub} <= {st0_phase_main, st0_phase_sub};
            end
            
            // stage 2
            case (st1_phase_main)
            2'd0:   st2_out <= 2'b00;
            2'd1:   st2_out <= 2'b01;
            2'd2:   st2_out <= 2'b11;
            2'd3:   st2_out <= 2'b10;
            endcase
        end
    end
    
    assign update = (st0_counter == {MICROSTEP_WIDTH{1'b1}});
    
    assign out_a = st2_out[0];
    assign out_b = st2_out[1];
    
endmodule


`default_nettype wire


// end of file

