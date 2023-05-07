// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_synctimer_master
        #(
            parameter int unsigned  TIMER_WIDTH     = 64    ,   // タイマのbit幅
            parameter int unsigned  NUMERATOR       = 10    ,   // クロック周期の分子
            parameter int unsigned  DENOMINATOR     = 3     ,   // クロック周期の分母
            parameter bit           EXTERNAL_TIMER  = 1'b0  ,   // 外部タイマ利用
            parameter int unsigned  MAX_NODES       = 3     ,   // 最大ノード数
            parameter int unsigned  OFFSET_WIDTH    = 24    ,   // オフセットbit幅
            parameter int unsigned  OFFSET_LPF_GAIN = 8     ,   // オフセット更新LPFのゲイン (1/2^N)
            parameter bit           DEBUG           = 1'b0  ,
            parameter bit           SIMULATION      = 1'b0  
        )
        (
            input   var logic                       reset                   ,
            input   var logic                       clk                     ,
            input   var logic                       cke                     ,

            input   var logic   [TIMER_WIDTH-1:0]   external_time           ,
            output  var logic   [TIMER_WIDTH-1:0]   current_time            ,

            input   var logic   [TIMER_WIDTH-1:0]   set_time                ,
            input   var logic                       set_valid               ,

            input   var logic                       cmd_enable              ,
            input   var logic                       cmd_start               ,
            input   var logic                       cmd_finish              ,
            input   var logic                       cmd_payload_setup       ,
            output  var logic   [7:0]               m_cmd_payload_data      ,
            output  var logic                       m_cmd_payload_valid     ,
            input   var logic                       m_cmd_payload_ready     ,

            input   var logic                       res_enable              ,
            input   var logic                       res_start               ,
            input   var logic                       res_finish              ,
            input   var logic                       res_fail                ,
            input   var logic   [7:0]               res_rx_node             ,
            input   var logic   [7:0]               res_rx_type             ,
            input   var logic   [15:0]              res_rx_length           ,
            input   var logic                       res_payload_setup       ,
            input   var logic   [15:0]              s_res_payload_index     ,
            input   var logic                       s_res_payload_first     ,
            input   var logic                       s_res_payload_last      ,
            input   var logic   [7:0]               s_res_payload_data      ,
            input   var logic                       s_res_payload_valid     
        );

    localparam  int unsigned    MAX_SLAVES = MAX_NODES - 1;


    // -----------------------------------------
    //  Timer
    // -----------------------------------------

    if ( EXTERNAL_TIMER ) begin : timer_ext
        assign current_time = external_time;
    end
    else begin : timer_self
        jellyvl_synctimer_timer
                #(
                    .NUMERATOR      (NUMERATOR      ),
                    .DENOMINATOR    (DENOMINATOR    ),
                    .TIMER_WIDTH    (TIMER_WIDTH    )
                )
            u_synctimer_timer
                (
                    .reset          (reset          ),
                    .clk            (clk            ),
                    
                    .set_time       (set_time       ),
                    .set_valid      (set_valid      ),
                    
                    .adjust_sign    (1'b0           ),
                    .adjust_valid   (1'b0           ),
                    .adjust_ready   (               ),
                    
                    .current_time   (current_time   )
                );
    end


    // -----------------------------------------
    //  Offset time measurement
    // -----------------------------------------

    localparam type t_offset     = logic [OFFSET_WIDTH-1:0];
    localparam type t_offset_q   = logic [OFFSET_WIDTH+OFFSET_LPF_GAIN+1-1:0];
    localparam type t_offset_pkt = logic [3:0][7:0];

    function automatic t_offset CycleToOffset
                (
                    input int unsigned cycle
                );
        return t_offset'((NUMERATOR * cycle / DENOMINATOR));
    endfunction

    t_offset    tx_start_time;
    t_offset    rx_start_time;
    t_offset    rx_end_time  ;
    t_offset    response_time;
    t_offset    packet_time  ;
    
    t_offset    tx_offset_time  [0:MAX_SLAVES-1];
    t_offset    rx_offset_time  [0:MAX_SLAVES-1];

    t_offset    delay_time      [0:MAX_SLAVES-1];
    t_offset    measured_time   [0:MAX_SLAVES-1];
    t_offset_q  offset_gain     [0:MAX_SLAVES-1];
    t_offset_q  offset_time     [0:MAX_SLAVES-1];

    always_ff @ (posedge clk) begin
        if ( cke ) begin
            if ( cmd_start ) begin
                tx_start_time <= t_offset'(current_time);
            end
            if ( res_start ) begin
                rx_start_time <= t_offset'(current_time);
                response_time <= t_offset'(current_time) - tx_start_time;
            end
            if ( res_finish && res_enable ) begin
                rx_end_time <= t_offset'(current_time);
                packet_time <= t_offset'(current_time) - rx_start_time;
            end
        end
    end
    
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            for ( int n = 0; n < MAX_SLAVES; ++n ) begin
                delay_time[n]    <= response_time - rx_offset_time[n];
                measured_time[n] <= delay_time[n] + (packet_time << 1); // 2倍の時間
                offset_gain[n]   <= offset_time[n] - (offset_time[n] >> OFFSET_LPF_GAIN);
            end
        end
    end

    logic               offset_enable;
    logic   [2:0]       offset_stage;
    always_ff @ (posedge clk) begin
        if ( reset ) begin
            offset_enable <= 1'b0;
            offset_stage  <= 3'b000;
            for ( int n = 0; n < MAX_SLAVES; ++n ) begin
                offset_time[n] <= '0;
            end
        end
        else if ( cke ) begin
            offset_stage <= offset_stage << 1;
            if ( res_finish && res_enable ) begin
                offset_stage[0] <= 1'b1;
            end

            if ( offset_stage[2] ) begin
                offset_enable <= 1'b1;
                for ( int n = 0; n < MAX_SLAVES; ++n ) begin
                    if ( offset_enable ) begin
                        offset_time[n] <= offset_gain[n] + t_offset_q'(measured_time[n]);
                    end
                    else begin
                        offset_time[n] <= t_offset_q'(measured_time[n]) << OFFSET_LPF_GAIN;
                    end
                end
            end
        end
    end

    always_comb begin
        for ( int n = 0; n < MAX_SLAVES; ++n ) begin
            tx_offset_time[n] = t_offset'(offset_time[n] >> (OFFSET_LPF_GAIN + 1));
        end
    end



    // -----------------------------------------
    //  Send command
    // -----------------------------------------


    logic   [7:0]   cmd_id;
    always_ff @ (posedge clk) begin
        if ( reset ) begin
            cmd_id <= 8'h00;    // NOP(Offset measurement)
        end
        else if ( cke ) begin
            if ( res_finish && res_enable ) begin
                if ( cmd_id == 8'h00 ) begin
                    cmd_id <= 8'h03;    // correct with renew
                end
                else begin
                    cmd_id <= 8'h01;    // correct
                end
            end
        end
    end


    // packet length
    localparam int  unsigned    CMD_LENGTH  = 1 + 8 + 4 * MAX_SLAVES - 1;

    // current time packet
    localparam type t_time_pkt   = logic [7:0][7:0];
    t_time_pkt  current_time_pkt;
    assign current_time_pkt = t_time_pkt'(current_time);

    // offset time packet
    t_offset_pkt tx_offset_pkt   [0:MAX_SLAVES-1];
    always_comb begin
        for (int n = 0; n < MAX_SLAVES; ++n) begin
            tx_offset_pkt[n] = t_offset_pkt'(tx_offset_time[n]);
        end
    end

    // send
    logic   [CMD_LENGTH-1:0][7:0]   cmd_payload;
    always_ff @ (posedge clk) begin
        if (cke) begin
            if ( cmd_start ) begin
                // make payload
                cmd_payload[0] <= cmd_id;
                for ( int i = 0; i < 8; ++i ) begin
                    cmd_payload[1+i] <= current_time_pkt[i];
                end
                for ( int n = 0; n < MAX_SLAVES-1; ++n ) begin
                    for ( int i = 0; i < 4; ++i ) begin
                        cmd_payload[1+8+n*4+i] <= tx_offset_pkt[n][i];
                    end
                end
            end
            else begin
                // send
                if ( m_cmd_payload_ready ) begin
                    cmd_payload <= cmd_payload >> 8;
                end
            end
        end
    end
    
    assign m_cmd_payload_data  = cmd_payload[0];
    assign m_cmd_payload_valid = cmd_enable;




    // -----------------------------------------
    //  Receive response
    // -----------------------------------------

    logic   [CMD_LENGTH-1:0]    res_payload_flag;
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            if ( res_payload_setup && res_enable ) begin
                res_payload_flag <= CMD_LENGTH'(1);
            end
            else begin
                if ( s_res_payload_valid ) begin
                    res_payload_flag <= res_payload_flag << 1;
                end
            end
        end
    end

    t_offset_pkt    rx_offset_pkt   [0:MAX_SLAVES-1];
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            for ( int n = 0; n < MAX_SLAVES; ++n ) begin
                for ( int i = 0; i < 4; ++i ) begin
                    if ( res_payload_flag[1+8+n*4+i] ) begin
                        rx_offset_pkt[n][i] <= s_res_payload_data;
                    end
                end
            end
        end
    end
    
    always_comb begin
        for ( int n = 0; n < MAX_SLAVES; ++n ) begin
            rx_offset_time[n] = t_offset'(rx_offset_pkt[n]);
        end
    end

endmodule


`default_nettype wire


// end of file
