// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// 倍速クロック多重化分離部
module jelly_clkx2_demux
        #(
            parameter   DATA_WIDTH = 32
        )
        (
            input   wire                        reset,
            input   wire                        cke,
            input   wire                        clk,
            input   wire                        clkx2,
            input   wire                        phase,
            
            input   wire    [DATA_WIDTH-1:0]    in_data,
            input   wire                        in_valid,
            
            output  wire    [DATA_WIDTH-1:0]    out0_data,
            output  wire                        out0_valid,
            
            output  wire    [DATA_WIDTH-1:0]    out1_data,
            output  wire                        out1_valid
        );
    
    reg     [DATA_WIDTH-1:0]    reg_in_data;
    reg                         reg_in_valid;
    
    reg     [DATA_WIDTH-1:0]    reg_out0_data;
    reg                         reg0_valid;
    reg     [DATA_WIDTH-1:0]    reg1_data;
    reg                         reg1_valid;
    
    always @(posedge clkx2) begin
        if ( reset ) begin
            reg_data  <= {DATA_WIDTH{1'bx}};
            reg_valid <= 1'bx;
        end
        else if ( cke ) begin
            reg_data  <= phase ? in0_data  : in1_data;
            reg_valid <= phase ? in0_valid : in1_valid;
        end
    end
    
    
endmodule


`default_nettype wire


// end of file
