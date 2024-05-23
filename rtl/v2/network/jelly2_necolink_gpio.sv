// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_necolink_gpio
        #(
            parameter   int unsigned    MAX_SLAVES   = 4                                            ,
            parameter   int unsigned    GLOBAL_BYTES = 4                                            ,
            parameter   int unsigned    LOCAL_OFFSET = GLOBAL_BYTES                                 ,
            parameter   int unsigned    LOCAL_BYTES  = 4                                            ,
            parameter   int unsigned    FULL_BYTES   = GLOBAL_BYTES + LOCAL_BYTES * MAX_SLAVES      ,
            parameter   bit             DEBUG        = 1'b0                                         ,
            parameter   bit             SIMULATION   = 1'b0
        )
        (
            input   var logic                               reset                   ,
            input   var logic                               clk                     ,
            input   var logic                               cke                     ,

            input   var logic   [GLOBAL_BYTES-1:0][7:0]     tx_global_mask          ,
            input   var logic   [GLOBAL_BYTES-1:0][7:0]     tx_global_data          ,
            input   var logic   [LOCAL_BYTES-1:0][7:0]      tx_local_mask           ,
            input   var logic   [LOCAL_BYTES-1:0][7:0]      tx_local_data           ,
            output  var logic                               tx_accepted             ,

            output  var logic   [GLOBAL_BYTES-1:0][7:0]     m_rx_global_data        ,
            output  var logic   [LOCAL_BYTES-1:0][7:0]      m_rx_local_data         ,
            output  var logic                               m_rx_valid              ,

            output  var logic   [FULL_BYTES-1:0][7:0]       m_res_full_data         ,
            output  var logic                               m_res_valid             ,

            input   var logic   [7:0]                       node_self               ,
            
            // command 
            input   var logic                               cmd_enable              ,
            input   var logic                               cmd_start               ,
            input   var logic                               cmd_finish              ,
            input   var logic                               cmd_fail                ,
            input   var logic                               cmd_payload_setup       ,
            input   var logic   [15:0]                      s_cmd_payload_rx_index  ,
            input   var logic                               s_cmd_payload_rx_first  ,
            input   var logic                               s_cmd_payload_rx_last   ,
            input   var logic   [7:0]                       s_cmd_payload_rx_data   ,
            input   var logic                               s_cmd_payload_rx_valid  ,
            output  var logic   [7:0]                       m_cmd_payload_tx_data   ,
            output  var logic                               m_cmd_payload_tx_valid  ,
            input   var logic                               m_cmd_payload_tx_ready  ,
            
            // response
            input   var logic                               res_enable              ,
            input   var logic                               res_start               ,
            input   var logic                               res_finish              ,
            input   var logic                               res_fail                ,
            input   var logic                               res_payload_setup       ,
            input   var logic   [15:0]                      s_res_payload_rx_index  ,
            input   var logic                               s_res_payload_rx_first  ,
            input   var logic                               s_res_payload_rx_last   ,
            input   var logic   [7:0]                       s_res_payload_rx_data   ,
            input   var logic                               s_res_payload_rx_valid  ,
            output  var logic   [7:0]                       m_res_payload_tx_data   ,
            output  var logic                               m_res_payload_tx_valid  ,
            input   var logic                               m_res_payload_tx_ready  
        );



    // ---------------------------------
    //  Receive Command
    // ---------------------------------

    logic   [GLOBAL_BYTES-1:0]  cmd_rx_flags_global;
    logic   [LOCAL_BYTES-1:0]   cmd_rx_flags_local;
    logic                       cmd_tx_flag_global;
    logic                       cmd_tx_flag_local;

    logic   [15:0]              cmd_offset_local;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            cmd_offset_local <= 16'(LOCAL_OFFSET) + (16'(node_self) - 16'd2) * 16'(LOCAL_BYTES);
        end
    end
    
    jelly2_packet_position
            #(
                .INDEX_WIDTH    (16                                 ),
                .OFFSET_WIDTH   (1                                  ),
                .FLAG_WIDTH     (GLOBAL_BYTES                       )
            )                   
        jelly2_packet_position_cmd_global
            (           
                .reset          (reset                              ),
                .clk            (clk                                ),
                .cke            (cke                                ),

                .setup          (cmd_payload_setup & cmd_enable     ),
                .s_index        (s_cmd_payload_rx_index             ),
                .s_valid        (s_cmd_payload_rx_valid             ),

                .offset         ('0                                 ),
                .flags          (cmd_rx_flags_global                ),
                .flag           (cmd_tx_flag_global                 )
        );

    jelly2_packet_position
            #(
                .INDEX_WIDTH    (16                                 ),
                .OFFSET_WIDTH   (16                                 ),
                .FLAG_WIDTH     (LOCAL_BYTES                        )
            )                   
        jelly2_packet_position_cmd_local
            (           
                .reset          (reset                              ),
                .clk            (clk                                ),
                .cke            (cke                                ),

                .setup          (cmd_payload_setup & cmd_enable     ),
                .s_index        (s_cmd_payload_rx_index             ),
                .s_valid        (s_cmd_payload_rx_valid             ),

                .offset         (cmd_offset_local                   ),
                .flags          (cmd_rx_flags_local                 ),
                .flag           (cmd_tx_flag_local                  )
            );

    // recive
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            for ( int i = 0; i < GLOBAL_BYTES; ++i ) begin
                if ( cmd_rx_flags_global[i] ) begin
                    m_rx_global_data[i] <= s_cmd_payload_rx_data;
                end
            end

            for ( int i = 0; i < LOCAL_BYTES; ++i ) begin
                if ( cmd_rx_flags_local[i] ) begin
                    m_rx_local_data[i] <= s_cmd_payload_rx_data;
                end
            end
        end
    end

    assign m_rx_valid = cmd_finish & cmd_enable;


    // send
    logic   [GLOBAL_BYTES-1:0][7:0]     cmd_tx_global_mask ;
    logic   [GLOBAL_BYTES-1:0][7:0]     cmd_tx_global_data ;
    logic   [LOCAL_BYTES-1:0][7:0]      cmd_tx_local_mask  ;
    logic   [LOCAL_BYTES-1:0][7:0]      cmd_tx_local_data  ;

    logic   [7:0]                       cmd_payload_tx_data ;
    logic                               cmd_payload_tx_valid;

    always_comb begin
        cmd_payload_tx_data  = s_cmd_payload_rx_data;
        cmd_payload_tx_valid = 1'b0;
        if ( cmd_tx_flag_global ) begin
            cmd_payload_tx_data  = (cmd_payload_tx_data & ~cmd_tx_global_mask[0]) | (cmd_tx_global_data[0] & cmd_tx_global_mask[0]);
            cmd_payload_tx_valid = s_cmd_payload_rx_valid;
        end
        if ( cmd_tx_flag_local ) begin
            cmd_payload_tx_data  = (cmd_payload_tx_data & ~cmd_tx_local_mask[0]) | (cmd_tx_local_data[0] & cmd_tx_local_mask[0]);
            cmd_payload_tx_valid = s_cmd_payload_rx_valid;
        end
    end

    always_ff @ (posedge clk) begin
        if ( cmd_payload_setup & cmd_enable ) begin
            cmd_tx_global_mask <= tx_global_mask;
            cmd_tx_global_data <= tx_global_data;
            cmd_tx_local_mask  <= tx_local_mask ;
            cmd_tx_local_data  <= tx_local_data ;
        end
        else if ( cke ) begin
            if ( m_cmd_payload_tx_ready ) begin
                m_cmd_payload_tx_valid <= 1'b0;
            end
            if ( s_cmd_payload_rx_valid ) begin
                m_cmd_payload_tx_data  <= cmd_payload_tx_data;
                m_cmd_payload_tx_valid <= cmd_payload_tx_valid;
            end

            if ( s_cmd_payload_rx_valid ) begin
                if ( cmd_tx_flag_global ) begin
                    cmd_tx_global_mask <= cmd_tx_global_mask >> 8;
                    cmd_tx_global_data <= cmd_tx_global_data >> 8;
                end
                if ( cmd_tx_flag_local ) begin

                    cmd_tx_local_mask <= cmd_tx_local_mask >> 8;
                    cmd_tx_local_data <= cmd_tx_local_data >> 8;
                end
            end
        end
    end

    assign tx_accepted = cmd_payload_setup & cmd_enable;



    // ---------------------------------
    //  Send response
    // ---------------------------------

    logic   [FULL_BYTES-1:0]    res_flags_full;

    jelly2_packet_position
            #(
                .INDEX_WIDTH    (16                                 ),
                .OFFSET_WIDTH   (1                                  ),
                .FLAG_WIDTH     (FULL_BYTES                         )
            )                   
        jelly2_packet_position_res_full
            (           
                .reset          (reset                              ),
                .clk            (clk                                ),
                .cke            (cke                                ),

                .setup          (res_payload_setup & res_enable     ),
                .s_index        (s_res_payload_rx_index             ),
                .s_valid        (s_res_payload_rx_valid             ),

                .offset         ('0                                 ),
                .flags          (res_flags_full                     ),
                .flag           (                                   )
        );

    // recive
    always_ff @ (posedge clk) begin
        if ( cke ) begin
            for ( int i = 0; i < FULL_BYTES; ++i ) begin
                if ( res_flags_full[i] ) begin
                    m_res_full_data[i] <= s_res_payload_rx_data;
                end
            end
        end
    end

    assign m_res_valid = res_finish & res_enable;
    
    assign m_res_payload_tx_data  = 'x;
    assign m_res_payload_tx_valid = 1'b0;

endmodule


`default_nettype wire

// end of file

