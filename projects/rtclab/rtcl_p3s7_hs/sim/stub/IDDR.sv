
`timescale 1ns / 1ps
`default_nettype none

module IDDR
        #(
            parameter DDR_CLK_EDGE = "SAME_EDGE_PIPELINED"  ,
            parameter INIT_Q1      = 1'b0                   ,
            parameter INIT_Q2      = 1'b0                   ,
            parameter SRTYPE       = "SYNC"
        )
        (
            output  var logic Q1    ,
            output  var logic Q2    ,
            input   var logic C     ,
            input   var logic CE    ,
            input   var logic D     ,
            input   var logic R     ,
            input   var logic S     
        );

    logic   ff1 = INIT_Q1;
    always_ff @(posedge C) begin
        if ( S ) begin
            ff1 <= 1'b1;
        end
        else if ( R ) begin
            ff1 <= 1'b0;
        end
        else if ( CE ) begin
            ff1 <= D;
        end
    end

    logic   ff2 = INIT_Q2;
    always_ff @(negedge C) begin
        if ( S ) begin
            ff2 <= 1'b1;
        end
        else if ( R ) begin
            ff2 <= 1'b0;
        end
        else if ( CE ) begin
            ff2 <= D;
        end
    end

    always_ff @(posedge C) begin
        if ( S ) begin
            Q1 <= 1'b1;
            Q2 <= 1'b1;
        end
        else if ( R ) begin
            Q1 <= 1'b0;
            Q2 <= 1'b0;
        end
        else if ( CE ) begin
            Q1 <= ff1;
            Q2 <= ff2;
        end
    end

endmodule

`default_nettype wire

// end of file
