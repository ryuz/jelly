



`timescale 1ns / 1ps
`default_nettype none

module kv260_sample
            (
                output  wire    [7:0]   pmod
            );
    

    wire            clk;

    design_1
        i_design_1
            (
                .pl_clk     (clk)
            );
    
    logic   [27:0]     counter = '0;
    always_ff @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    assign pmod[3:0] = counter[11:8];
    assign pmod[7:4] = counter[27:24];
    
endmodule


`default_nettype wire

// end of file

