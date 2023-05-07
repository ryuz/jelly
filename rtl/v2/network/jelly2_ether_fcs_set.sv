
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module jelly2_ether_fcs_set
        #(
            parameter bit          DEBUG        = 1'b0,
            parameter bit          SIMULATION   = 1'b0
        )
        (
            input   var logic               reset               ,
            input   var logic               clk                 ,
            input   var logic               cke                 ,
    
            input   var logic   [1:0]       s_packet_index      ,
            input   var logic               s_packet_fcs        ,
            input   var logic               s_packet_crc_start  ,
            input   var logic               s_packet_first      ,
            input   var logic               s_packet_last       ,
            input   var logic   [7:0]       s_packet_data       ,
            input   var logic               s_packet_valid      ,
            output      logic               s_packet_ready      ,

            output  var logic               m_packet_first      ,
            output  var logic               m_packet_last       ,
            output  var logic   [7:0]       m_packet_data       ,
            output  var logic               m_packet_valid      ,
            input   var logic               m_packet_ready
        );


    logic               ready;
    assign ready = cke & (!m_packet_valid || m_packet_ready);


    logic   [3:0][7:0]      crc_value;

    jelly2_calc_crc
        #(
            .DATA_WIDTH     (8),
            .CRC_WIDTH      (32),
            .POLY_REPS      (32'h04c11db7),
            .REVERSED       (0)
        )
    u_cacl_crc
        (
            .reset          (reset),
            .clk            (clk),
            .cke            (ready),

            .in_update      (~s_packet_crc_start),
            .in_data        (s_packet_data),
            .in_valid       (s_packet_valid & ~s_packet_fcs),

            .out_crc        (crc_value)
        );

    
    logic   [1:0]   packet_index;
    logic           packet_fcs;
    logic           packet_first;
    logic           packet_last;
    logic   [7:0]   packet_data;
    logic           packet_valid;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            packet_index <= 'x;
            packet_fcs   <= 'x;
            packet_first <= 'x;
            packet_last  <= 'x;
            packet_data  <= 'x;
            packet_valid <= 1'b0;
        end
        else if ( ready ) begin
            packet_index <= s_packet_index;
            packet_fcs   <= s_packet_fcs;
            packet_first <= s_packet_first;
            packet_last  <= s_packet_last;
            packet_data  <= s_packet_data;
            packet_valid <= s_packet_valid;
        end
    end

    assign s_packet_ready = !m_packet_valid || m_packet_ready;

    assign m_packet_first = packet_first;
    assign m_packet_last  = packet_last;
    assign m_packet_data  = packet_fcs ? crc_value[packet_index] : packet_data;
    assign m_packet_valid = packet_valid;

endmodule


`default_nettype wire

