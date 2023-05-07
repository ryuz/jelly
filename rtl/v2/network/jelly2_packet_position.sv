// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                         Copyright (C) 2008-2023 by Ryuz
//                                         https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_packet_position
        #(
            parameter   int unsigned    INDEX_WIDTH     = 16                ,
            parameter   int unsigned    OFFSET_WIDTH    = INDEX_WIDTH       ,
            parameter   int unsigned    FLAG_WIDTH      = 1                 
        )
        ( 
            input   var logic                       reset                   ,
            input   var logic                       clk                     ,
            input   var logic                       cke                     ,

            input   var logic                       setup                   ,
            input   var logic   [INDEX_WIDTH-1:0]   s_index                 ,
            input   var logic                       s_valid                 ,

            input   var logic   [OFFSET_WIDTH-1:0]  offset                  ,
            output  var logic   [FLAG_WIDTH-1:0]    flags                   ,
            output  var logic                       flag                    
        );


    localparam  type    t_index  = logic    [INDEX_WIDTH-1:0];
    localparam  type    t_offset = logic    [OFFSET_WIDTH-1:0];
    localparam  type    t_flag   = logic    [FLAG_WIDTH-1:0];

    logic       offset_en;
    t_offset    offset_index;
    always_ff @(posedge clk) begin
        if ( cke ) begin
            if ( setup ) begin
                if ( offset == '0 ) begin
                    offset_en    <= 1'b0;
                    offset_index <= 'x;
                    flags        <= t_flag'(1);
                    flag         <= 1'b1;
                end
                else begin
                    offset_en    <= 1'b1;
                    offset_index <= offset - t_offset'(1);
                    flags        <= '0;
                    flag         <= 1'b0;
                end
            end
            else begin
                if ( s_valid ) begin
                    flags <= flags << 1;
                    if ( offset_en && s_index == t_index'(offset_index) ) begin
                        offset_en <= 1'b0;
                        flags[0]  <= 1'b1;
                        flag      <= 1'b1;
                    end
                    if ( flags[FLAG_WIDTH-1] ) begin
                        flag      <= 1'b0;
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
