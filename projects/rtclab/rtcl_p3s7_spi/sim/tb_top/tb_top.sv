
`timescale 1ns / 1ps
`default_nettype none

module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #100_000_000
        $finish;
    end
    
    // ---------------------------------
    //  reset and clock
    // ---------------------------------

    localparam RATE50 = 1000.0/50.00;
    localparam RATE72 = 1000.0/72.00;

    logic       clk50 = 1'b1;
    initial forever #(RATE50/2.0) clk50 = ~clk50;
    
    logic       clk72 = 1'b1;
    initial forever #(RATE72/2.0) clk72 = ~clk72;

    
    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic   [1:0]   led                 ;
    logic   [7:0]   pmod                ;
    logic           sensor_pwr_en_vdd18 ;
    logic           sensor_pwr_en_vdd33 ;
    logic           sensor_pwr_en_pix   ;
    logic           sensor_pgood        ;
    logic           python_reset_n      ;
    logic           python_clk_pll      ;
    logic           python_ss_n         ;
    logic           python_mosi         ;
    logic           python_miso         ;
    logic           python_sck          ;
    logic   [2:0]   python_trigger      ;
    logic   [1:0]   python_monitor      ;
    logic           python_clk_p        ;
    logic           python_clk_n        ;
    logic   [3:0]   python_data_p       ;
    logic   [3:0]   python_data_n       ;
    logic           python_sync_p       ;
    logic           python_sync_n       ;

    rtcl_p3s7_spi
        u_top
            (
                .clk50                  ,
                .clk72                  ,
                .led                    ,
                .pmod                   ,
                .sensor_pwr_en_vdd18    ,
                .sensor_pwr_en_vdd33    ,
                .sensor_pwr_en_pix      ,
                .sensor_pgood           ,
                .python_reset_n         ,
                .python_clk_pll         ,
                .python_ss_n            ,
                .python_mosi            ,
                .python_miso            ,
                .python_sck             ,
                .python_trigger         ,
                .python_monitor         ,
                .python_clk_p           ,
                .python_clk_n           ,
                .python_data_p          ,
                .python_data_n          ,
                .python_sync_p          ,
                .python_sync_n          
            );
    

    // ---------------------------------
    //  Testbench
    // ---------------------------------

    initial begin
        sensor_pgood = 1'b0;
      #100000
        sensor_pgood = 1'b1;
      #10000000
        sensor_pgood = 1'b0;
      #1000000
        $finish;
    end

endmodule

`default_nettype wire
