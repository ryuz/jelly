

// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_scheduler
        #(
            parameter int   unsigned    TIMER_WIDTH            = 24     ,
            parameter int   unsigned    SYNCTIM_INTERVAL_WIDTH = 8      ,
            parameter bit               DEBUG                  = 1'b0   ,
            parameter bit               SIMULATION             = 1'b0   
        )
        (
            input   var logic                                   reset                       ,
            input   var logic                                   clk                         ,
            input   var logic                                   cke                         ,

            input   var logic   [TIMER_WIDTH-1:0]               current_time                ,

            input   var logic                                   enable                      ,
            output  var logic                                   busy                        ,

            input   var logic                                   param_start_time_en         ,
            input   var logic   [TIMER_WIDTH-1:0]               param_start_time            ,
            input   var logic   [TIMER_WIDTH-1:0]               param_period_gpio           ,
            input   var logic   [TIMER_WIDTH-1:0]               param_period_message        ,
            input   var logic   [SYNCTIM_INTERVAL_WIDTH-1:0]    param_interval_synctim      ,

            input   var logic   [7:0]                           param_gpio_type             ,
            input   var logic   [15:0]                          param_gpio_length           ,
            input   var logic   [7:0]                           param_synctim_type          ,
            input   var logic   [15:0]                          param_synctim_length        ,
            input   var logic   [7:0]                           param_message_type          ,
            input   var logic   [15:0]                          param_message_length        ,
            
            output  var logic                                   packet_start                ,
            output  var logic   [7:0]                           packet_type                 ,
            output  var logic   [15:0]                          packet_length               

//          output  var logic                                   gpio_start                  ,
//          output  var logic                                   message_start               ,
//          output  var logic                                   synctim_start               ,
//          output  var logic                                   synctim_renew               ,
//          output  var logic                                   synctim_correct             
        );
    
    localparam  type    t_timer = logic         [TIMER_WIDTH-1:0];
    localparam  type    t_diff  = logic signed  [TIMER_WIDTH-1:0];
    
    logic       trigger;
    logic       phase;
    t_timer     next_time;
    t_timer     next_period;
    t_diff      remaining_time;
    assign remaining_time = next_time - current_time;

    always @(posedge clk) begin
        if ( reset ) begin
            busy          <= 1'b0;
            trigger       <= 1'b0;
            phase         <= 1'b0;
            next_time     <= 'x;
            next_period   <= 'x;
        end
        else if ( cke ) begin
            if ( !busy ) begin
                phase       <= 1'bx;
                next_time   <= 'x;
                next_period <= 'x;
                if ( enable ) begin
                    busy  <= 1'b1;
                    phase <= 1'b0;
                    if ( param_start_time_en ) begin
                        next_time   <= param_start_time;
                        next_period <= param_period_gpio;
                    end
                    else begin
                        next_time   <= current_time;
                        next_period <= param_period_gpio;
                    end
                end
            end
            else begin
                trigger <= 1'b0;
                if ( trigger ) begin
                    next_time   <= next_time + next_period;
                    phase       <= ~phase;
                    next_period <= phase ? param_period_message : param_period_gpio;
                end
                else begin
                    trigger <= remaining_time < 0;
                end
            end
        end
    end

    localparam  type    t_interval = logic  [SYNCTIM_INTERVAL_WIDTH-1:0];
    t_interval  synctim_counter;

    always @(posedge clk) begin
        if ( reset ) begin
            packet_type     <= 'x;
            packet_length   <= 'x;
 //           gpio_start      <= 1'b0;
 //           message_start   <= 1'b0;
 //           synctim_start   <= 1'b0;
 //           synctim_renew   <= 1'bx;
 //           synctim_correct <= 1'bx;
            synctim_counter <= '0;
        end
        else begin
            if ( ~busy ) begin
//                synctim_renew   <= 1'b0;
//                synctim_correct <= 1'b0;
                synctim_counter <= '0;
            end

            packet_start  <= 1'b0;
//            gpio_start    <= 1'b0;
//            message_start <= 1'b0;
//            synctim_start <= 1'b0;
            if ( trigger ) begin
                packet_start <= 1'b1;
                if ( phase ) begin
                    synctim_counter <= synctim_counter - 1'b1;
                    if ( synctim_counter == '0 ) begin
                        synctim_counter <= param_interval_synctim;
//                        synctim_start   <= 1'b1;
                        packet_type     <= param_synctim_type;
                        packet_length   <= param_synctim_length;
                    end
                    else begin
                        synctim_counter <= synctim_counter - t_interval'(1);
//                        message_start   <= 1'b1;
                        packet_type     <= param_message_type;
                        packet_length   <= param_message_length;
                    end
                end
                else begin
//                    gpio_start    <= 1'b1;
                    packet_type   <= param_gpio_type;
                    packet_length <= param_gpio_length;
                end
            end
            /*
            if ( synctim_start ) begin
                if ( synctim_renew == 1'b0 && synctim_correct == 1'b0 ) begin
                    synctim_renew   <= 1'b1;
                    synctim_correct <= 1'b0;
                end
                else begin
                    synctim_renew   <= 1'b0;
                    synctim_correct <= 1'b1;
                end
            end
            */
        end
    end

endmodule


`default_nettype wire

// end of file


