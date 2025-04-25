
`timescale 1 ns / 1 ps

module design_1
    (
        fan_en      ,
        reset       ,
        clk         ,
        pl_ps_irq0  ,
        pl_ps_irq1
    );

    output          fan_en      ;
    output          reset       ;
    output          clk         ;
    input   [7:0]   pl_ps_irq0  ;
    input   [7:0]   pl_ps_irq1  ;

    wire            fan_en      ;
    wire            reset_n     ;
    wire            clk         ;
    wire    [7:0]   pl_ps_irq0  ;
    wire    [7:0]   pl_ps_irq1  ;

    assign fan_en  = 1'b0  ;

endmodule
