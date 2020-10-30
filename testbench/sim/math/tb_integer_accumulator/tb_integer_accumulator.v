
`timescale 1ns / 1ps
`default_nettype none


module tb_integer_accumulator();
    localparam RATE    = 1000.0/200.0;
    
    initial begin
        $dumpfile("tb_integer_accumulator.vcd");
        $dumpvars(0, tb_integer_accumulator);
        
        #100000;
            $finish;
    end
    
    reg     clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    reg     reset = 1'b1;
    initial #(RATE*100.5)   reset = 1'b0;
    
    reg     cke = 1'b1;
    always @(posedge clk)   cke <= {$random()};
    
    
    parameter                           SIGEND            = 0;
    parameter                           ACCUMULATOR_WIDTH = 64;
    parameter                           DATA_WIDTH        = 32;
    parameter                           UNIT_WIDTH        = 16;
    parameter   [ACCUMULATOR_WIDTH-1:0] INIT_VALUE        = 0;
    
    reg                                 clear = 0;
    wire                                busy;
    
    reg                                 add_en = 0;
    reg     [DATA_WIDTH-1:0]            add_data;
    
    wire    [ACCUMULATOR_WIDTH-1:0]     accumulator;
    
    reg     [ACCUMULATOR_WIDTH-1:0]     exp_acc;
    
    // アキュムレータ
    jelly_integer_accumulator
            #(
                .SIGEND             (SIGEND),
                .ACCUMULATOR_WIDTH  (ACCUMULATOR_WIDTH),
                .DATA_WIDTH         (DATA_WIDTH),
                .UNIT_WIDTH         (UNIT_WIDTH),
                .INIT_VALUE         (INIT_VALUE)
            )
        i_integer_accumulator
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .clear              (clear),
                .busy               (busy),
                
                .add_en             (add_en),
                .add_data           (add_data),
                
                .accumulator        (accumulator)
            );
    
    always @(posedge clk) begin
        if ( reset ) begin
            add_en   <= 0;
            add_data <= 0;
            exp_acc  <= 0;
        end
        else if ( cke ) begin
            add_en   <= {$random};
            add_data <= {$random};
            
            if ( add_en ) begin
                exp_acc <= exp_acc + add_data;
            end
        end
    end
    
    wire match = (accumulator == exp_acc);
    
    wire ok    = match ^ busy;
    
    
endmodule


`default_nettype wire


// end of file
