// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// shift register lookup table
module jelly2_data_shift_register_lut
        #(
            parameter   int     SEL_WIDTH  = 5,
            parameter   int     NUM        = (1 << SEL_WIDTH),
            parameter   int     DATA_WIDTH = 8,
            parameter           DEVICE     = "RTL"
        )
        (
            input   logic                       clk,
            input   logic                       cke,
            
            input   logic   [SEL_WIDTH-1:0]     sel,
            input   logic   [DATA_WIDTH-1:0]    in_data,
            output  logic   [DATA_WIDTH-1:0]    out_data
        );
    
`ifndef VERILATOR
    localparam bit  VERILATOR = 1'b1;
`else
    localparam bit  VERILATOR = 1'b0;
`endif
    
    generate
    if ( !VERILATOR && SEL_WIDTH <= 5
            && (256'(DEVICE) == 256'("SPARTAN6")
             || 256'(DEVICE) == 256'("VIRTEX6")
             || 256'(DEVICE) == 256'("7SERIES")
             || 256'(DEVICE) == 256'("ULTRASCALE")
             || 256'(DEVICE) == 256'("ULTRASCALE_PLUS_ES1")
             || 256'(DEVICE) == 256'("ULTRASCALE_PLUS_ES2")) ) begin : xilinx_srlc32e
        
        for ( genvar i = 0; i < DATA_WIDTH; i = i+1 ) begin : loop_shift
            // XILINX
            wire    [4:0]   a = sel;
            SRLC32E
                    #(
                        .INIT   (32'h00000000)
                    )
                i_srlc32e
                    (
                        .Q      (out_data[i]),
                        .Q31    (),
                        .A      (a),
                        .CE     (cke),
                        .CLK    (clk),
                        .D      (in_data[i])
                    );
        end
    end
    else begin : blk_rtl
        // RTL
        logic   [NUM*DATA_WIDTH-1:0]    reg_data;
        always_ff @(posedge clk) begin
            if ( cke ) begin
                reg_data <= (NUM*DATA_WIDTH)'({reg_data, in_data});
            end
        end
        
        assign out_data = reg_data[sel*DATA_WIDTH +: DATA_WIDTH];
    end
    endgenerate
    
    
endmodule


// end of file
