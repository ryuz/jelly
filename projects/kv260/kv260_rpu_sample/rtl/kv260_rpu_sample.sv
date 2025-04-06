// KV260 sample design

`timescale 1ns / 1ps
`default_nettype none

module kv260_rpu_sample
        #(
            parameter  int COUNT_LIMIT = 50_000_000 // 0.5秒
        )
        (
            output  var logic   [7:0]   pmod    ,
            output  var logic           fan_en
        );
    
    // PS
    logic           reset   ;    // sync reset
    logic           clk     ;    // 100MHz
    logic   [7:0]   irq0    ;
    logic   [7:0]   irq1    ;

    design_1
        u_design_1
            (
                .fan_en     (fan_en ),
                .reset      (reset  ),
                .clk        (clk    ),
                .pl_ps_irq0 (irq0   ),
                .pl_ps_irq1 (irq1   )
            );
    
    // counter
    logic   [26:0]     counter;
    logic   [7:0]      led    ;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            counter <= '0;
            led     <= '0;
        end
        else begin
            counter <= counter + 1'b1;
            if ( counter >= 27'(COUNT_LIMIT - 1) ) begin
                counter <= '0;
                led     <= led + 1'b1;
            end
        end
    end

    assign irq0[0]   = led[0];
    assign irq0[7]   = led[1];
    assign irq0[6:1] = '0;

    assign irq1[0]   = led[2];
    assign irq1[7]   = led[3];
    assign irq1[6:1] = '0;

    // PMOD output
    assign pmod = led;
   
endmodule

`default_nettype wire

// end of file
