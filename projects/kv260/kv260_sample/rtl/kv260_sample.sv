// KV260 sample design

`timescale 1ns / 1ps
`default_nettype none

module kv260_sample
            (
                output  var logic   [7:0]   pmod    ,
                output  var logic           fan_en
            );
    
    // PS
    logic           clk;    // 100MHz
    design_1
        u_design_1
            (
                .fan_en     (fan_en ),
                .pl_clk     (clk    )
            );
    
    // counter
    (* MARK_DEBUG = "true" *)   logic   [27:0]     counter = '0;
    always_ff @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    // PMOD output
    assign pmod[3:0] = counter[27:24];
    assign pmod[7:4] = counter[11:8];
    
endmodule


`default_nettype wire


// end of file
