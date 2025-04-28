
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

    logic           mipi_reset_n        ;
    wire            mipi_scl            ;
    wire            mipi_sda            ;

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

    pullup(mipi_scl);
    pullup(mipi_sda);


    rtcl_p3s7_spi
        u_top
            (
                .clk50                  ,
                .clk72                  ,

                .led                    ,
                .pmod                   ,

                .mipi_reset_n           ,
                .mipi_scl               ,
                .mipi_sda               ,

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
    
    assign python_miso = ~python_mosi;

    // ---------------------------------
    //  Testbench
    // ---------------------------------

    initial begin
        sensor_pgood = 1'b0;
      #100000
        sensor_pgood = 1'b1;
      #10000000
        sensor_pgood = 1'b0;
        #10000000
        $finish;
    end
    

    localparam I2C_RATE = 100000;
    logic  scl = 1'b1;
    logic  sda = 1'b1;
    initial begin
        #(I2C_RATE*10);
       
        #(I2C_RATE) scl = 1'b1; sda = 1'b0; // start

        // devadr
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0; // R/W
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        // addr(hi)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        // addr(lo)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        // data(hi)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        // data(lo)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1; sda = 1'b1; // stop


        // read
        #(I2C_RATE*2);
        #(I2C_RATE) scl = 1'b1; sda = 1'b0; // start

        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // R/W
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0; // ACK
//      #(I2C_RATE) scl = 1'b0; sda = 1'b1; // NAK
        #(I2C_RATE) scl = 1'b1;

        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b1;
        #(I2C_RATE) scl = 1'b1;
        #(I2C_RATE) scl = 1'b0; sda = 1'b0; // ACK
        #(I2C_RATE) scl = 1'b1;


//      #(I2C_RATE) scl = 1'b0; sda = 1'b0;
//      #(I2C_RATE) scl = 1'b1; sda = 1'b0;
//      #(I2C_RATE) scl = 1'b1; sda = 1'b1; // stop

        // end
        #(I2C_RATE) scl = 1'b1; sda = 1'b1;

        
    end

    assign mipi_scl = scl ? 1'bz : 1'b0;
    assign mipi_sda = sda ? 1'bz : 1'b0;

endmodule

`default_nettype wire
