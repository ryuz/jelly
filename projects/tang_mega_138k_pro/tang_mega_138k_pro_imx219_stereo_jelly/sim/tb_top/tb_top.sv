
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #10000000
        $finish();
    end


    localparam RATE_SYS  = 1000.0/50.0  ;
    localparam RATE_DPHY = 1000.0/91.2  ;
    localparam RATE_TX   = 1000.0/200.0 ;
    localparam RATE_CAM  = 1000.0/50.0  ;
    localparam RATE_DVI  = 1000.0/25.0  ;

    logic   reset = 1'b1;
    initial #(RATE_SYS*100)  reset = 1'b0;

    logic   sys_clk = 1'b1;
    initial forever #(RATE_SYS/2.0)   sys_clk = ~sys_clk;

    logic   dphy_clk = 1'b1;
    initial forever #(RATE_DPHY/2.0)  dphy_clk = ~dphy_clk;

    logic   tx_clk = 1'b1;
    initial forever #(RATE_TX/2.0)  tx_clk = ~tx_clk;

    logic   cam_clk = 1'b1;
    initial forever #(RATE_CAM/2.0)  cam_clk = ~cam_clk;

    logic   dvi_clk = 1'b1;
    initial forever #(RATE_DVI/2.0)  dvi_clk = ~dvi_clk;



    // -----------------------------
    //  main
    // -----------------------------
    
    tb_main
        u_tb_main
            (
                .reset      ,
                .sys_clk    ,
                .dphy_clk   ,
                .tx_clk     ,
                .cam_clk    ,
                .dvi_clk    
            );
    

endmodule


`default_nettype wire


// end of file
