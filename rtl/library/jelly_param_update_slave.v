// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 非同期クロック間でのパラメータアップデート(受け側)
module jelly_param_update_slave
        #(
            parameter   INDEX_WIDTH = 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        in_trigger,
            input   wire                        in_update,
            
            output  wire                        out_update,
            output  wire    [INDEX_WIDTH-1:0]   out_index
        );
    
    // parameter latch
    (* ASYNC_REG="true" *)  reg         ff0_update, ff1_update;
    always @(posedge clk) begin
        ff0_update <= in_update;
        ff1_update <= ff0_update;
    end
    
    reg                         reg_update;
    reg     [INDEX_WIDTH-1:0]   reg_index;
    always @(posedge clk) begin
        if ( reset ) begin
            reg_update <= 1'b0;
            reg_index  <= {INDEX_WIDTH{1'b0}};
        end
        else if ( cke ) begin
            reg_update <= ff1_update;
            if ( reg_update & in_trigger ) begin
                reg_index <= reg_index + 1'b1;
            end
        end
    end
    
    assign out_update = reg_update;
    assign out_index  = reg_index;
    
endmodule


`default_nettype wire


// end of file
