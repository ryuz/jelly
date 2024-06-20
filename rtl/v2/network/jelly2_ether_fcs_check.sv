
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuji Fuchikami
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

module jelly2_ether_fcs_check
        #(
            parameter int          DATA_WIDTH   = 8,
            parameter bit          DEBUG        = 1'b0,
            parameter bit          SIMULATION   = 1'b0
        )
        (
            input   var logic                       reset               ,
            input   var logic                       clk                 ,
            input   var logic                       cke                 ,

            output  var logic                       crc_ok              ,
            output  var logic                       crc_ng              ,

            input   var logic                       s_packet_crc_start  ,
            input   var logic                       s_packet_last       ,
            input   var logic   [DATA_WIDTH-1:0]    s_packet_data       ,
            input   var logic                       s_packet_valid
        );

    logic   [3:0][7:0]      crc_value;

    jelly2_calc_crc
        #(
            .DATA_WIDTH     (DATA_WIDTH),
            .CRC_WIDTH      (32),
            .POLY_REPS      (32'h04c11db7),
            .REVERSED       (0)
        )
    u_cacl_crc
        (
            .reset          (reset),
            .clk            (clk),
            .cke            (cke),

            .in_update      (~s_packet_crc_start),
            .in_data        (s_packet_data),
            .in_valid       (s_packet_valid),

            .out_crc        (crc_value)
        );

    logic       last;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            last   <= 1'b0;
            crc_ok <= 1'b0;
            crc_ng <= 1'b0;
        end
        else if ( cke ) begin
            last   <= s_packet_valid & s_packet_last;

            crc_ok <= 1'b0;
            crc_ng <= 1'b0;
            if ( last ) begin
                if ( crc_value == 32'h2144df1c ) begin
                    crc_ok <= 1'b1;
                end
                else begin
                    crc_ng <= 1'b1;
                end
            end
        end
    end

endmodule


`default_nettype wire

// end of file

