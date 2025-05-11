
`timescale 1ns / 1ps
`default_nettype none

module tb_i2c();
    
    initial begin
        $dumpfile("tb_i2c.vcd");
        $dumpvars(0, tb_i2c);
        
    #100_000_000
        $finish;
    end
    
    // ---------------------------------
    //  reset and clock
    // ---------------------------------

    localparam RATE50  = 1000.0/50.00;
    localparam RATE72  = 1000.0/72.00;
//  localparam RATE720 = 1000.0/720.00;
    localparam RATE360 = 1000.0/360.00;
    localparam RATE180 = 1000.0/180.00;


    logic       clk50 = 1'b1;
    initial forever #(RATE50/2.0) clk50 = ~clk50;
    
    logic       clk72 = 1'b1;
    initial forever #(RATE72/2.0) clk72 = ~clk72;

    logic       clk360 = 1'b1;
    initial forever #(RATE360/2.0) clk360 = ~clk360;

    logic       clk180 = 1'b1;
    initial forever #(RATE180/2.0) clk180 = ~clk180;


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

    rtcl_p3s7_dphy
        u_top
            (
                .in_clk50               (clk50      ),
                .in_clk72               (clk72      ),

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

    assign python_clk_p  = clk360;
    assign python_clk_n  = ~python_clk_p;
    assign python_data_n = ~python_data_p;
    assign python_sync_n = ~python_sync_p;

    initial begin
        python_sync_p = 0;
        forever begin
            @(python_clk_p)  python_data_p = '1;
            @(python_clk_p)  python_data_p = '1;
            
            @(python_clk_p)  python_data_p = '1;
            @(python_clk_p)  python_data_p = '0;
            
            @(python_clk_p)  python_data_p = '1;
            @(python_clk_p)  python_data_p = '0;
            
            @(python_clk_p)  python_data_p = '0;
            @(python_clk_p)  python_data_p = '1;

            @(python_clk_p)  python_data_p = '1;
            @(python_clk_p)  python_data_p = '0;
        end
    end


//  initial begin
//      force u_top.python_clk = clk180;
//  end

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
    

    localparam I2C_RATE = 1000;
    logic  scl = 1'b1;
    logic  sda = 1'b1;

    assign mipi_scl = scl ? 1'bz : 1'b0;
    assign mipi_sda = sda ? 1'bz : 1'b0;

    task i2c_send(input logic [7:0] data);
        for ( int i = 0; i < 8; i++ ) begin
            #(I2C_RATE) scl = 1'b0; sda = data[7-i];
            #(I2C_RATE) scl = 1'b1;
        end
    endtask

    task cmd_send(input logic [15:0] addr, input logic [15:0] data);
        #(I2C_RATE) scl = 1'b1; sda = 1'b0; // start
        
        i2c_send({7'h10, 1'b0});            // devadr
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        i2c_send(addr[15:8]);               // addr(hi)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        i2c_send(addr[7:0]);                // addr(lo)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        i2c_send(data[15:8]);               // data(hi)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        i2c_send(data[7:0]);                // data(lo)
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        #(I2C_RATE) scl = 1'b0; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1; sda = 1'b0;
        #(I2C_RATE) scl = 1'b1; sda = 1'b1; // stop
    endtask

    task cmd_recv(input logic [15:0] addr, output logic [15:0] data);
        #(I2C_RATE) scl = 1'b1; sda = 1'b0; // start
        
        i2c_send({7'h10, 1'b1});            // devadr
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        i2c_send(8'hff);
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        i2c_send(8'hff);
        #(I2C_RATE) scl = 1'b0; sda = 1'b1; // ACK
        #(I2C_RATE) scl = 1'b1;

        #(I2C_RATE) scl = 1'b1; sda = 1'b1;
    endtask


    task cmd_write(input logic [14:0] addr, input logic [15:0] data);
        cmd_send({addr, 1'b1}, data);
    endtask

    task cmd_read(input logic [14:0] addr, output [15:0] data);
        cmd_send({addr, 1'b0}, 16'd0);
    endtask



    localparam  REGADR_CORE_ID       = 15'h0000;
    localparam  REGADR_CORE_VERSION  = 15'h0001;
    localparam  REGADR_CTL_BITSLIP   = 15'h0020;

    initial begin
        logic [15:0] rdata;

        #(I2C_RATE*10);
        cmd_write(REGADR_CTL_BITSLIP, 16'haa55);


        #(I2C_RATE*2);
        cmd_write(15'h4000, 16'habcd);
        #(I2C_RATE);
        cmd_read (15'h4000, rdata);
        #(I2C_RATE);

        /*
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
        */

//      #(I2C_RATE) scl = 1'b0; sda = 1'b0;
//      #(I2C_RATE) scl = 1'b1; sda = 1'b0;
//      #(I2C_RATE) scl = 1'b1; sda = 1'b1; // stop

        // end
        #(I2C_RATE) scl = 1'b1; sda = 1'b1;

        
    end


endmodule

`default_nettype wire
