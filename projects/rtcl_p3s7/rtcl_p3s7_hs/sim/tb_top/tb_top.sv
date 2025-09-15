
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

    localparam RATE50  = 1000.0/50.00;
    localparam RATE72  = 1000.0/72.00;
//  localparam RATE720 = 1000.0/720.00;
    localparam RATE360 = 1000.0/360.00;
//  localparam RATE180 = 1000.0/180.00;
    localparam RATE250 = 1000.0/250.00;
//  localparam RATE500 = 1000.0/500.00;
    
    logic       reset = 1'b1;
    initial #8000 reset = 1'b0;

    logic       clk50 = 1'b1;
    initial forever #(RATE50/2.0) clk50 = ~clk50;
    
    logic       clk72 = 1'b1;
    initial forever #(RATE72/2.0) clk72 = ~clk72;

    logic       clk360 = 1'b1;
    initial forever #(RATE360/2.0) clk360 = ~clk360;

//  logic       clk180 = 1'b1;
//  initial forever #(RATE180/2.0) clk180 = ~clk180;

    logic       clk250 = 1'b1;
    initial forever #(RATE250/2.0) clk250 = ~clk250;

//  logic       clk500 = 1'b1;
//  initial forever #(RATE500/2.0) clk500 = ~clk500;

    localparam RATE_DPHY = 1000.0/156.25;
    logic       clk_dphy = 1'b1;
    initial forever #(RATE_DPHY/2.0) clk_dphy = ~clk_dphy;


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
    
    logic           mipi_gpio0          ;
    logic           mipi_gpio1          ;
    wire            mipi_scl            ;
    wire            mipi_sda            ;
    logic           mipi_clk_lp_p       ;
    logic           mipi_clk_lp_n       ;
    logic           mipi_clk_hs_p       ;
    logic           mipi_clk_hs_n       ;
    logic   [1:0]   mipi_data_lp_p      ;
    logic   [1:0]   mipi_data_lp_n      ;
    logic   [1:0]   mipi_data_hs_p      ;
    logic   [1:0]   mipi_data_hs_n      ;

    pullup(mipi_scl);
    pullup(mipi_sda);

    rtcl_p3s7_hs
            #(
                .I2C_DIVIDER            (1          ),
                .DEBUG                  ("true"     )
            )
        u_top
            (
                .in_clk50               (clk50      ),
                .in_clk72               (clk72      ),

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
                .python_sync_n          ,

                .mipi_gpio0             ,
                .mipi_gpio1             ,
                .mipi_scl               ,
                .mipi_sda               ,
                .mipi_clk_lp_p          ,
                .mipi_clk_lp_n          ,
                .mipi_clk_hs_p          ,
                .mipi_clk_hs_n          ,
                .mipi_data_lp_p         ,
                .mipi_data_lp_n         ,
                .mipi_data_hs_p         ,
                .mipi_data_hs_n         
            );
    
    assign mipi_gpio0 = ~reset;

    // monitor
    wire    [3:0]  axi4s_recv_tuser  = u_top.axi4s_recv.tuser;
    wire           axi4s_recv_tlast  = u_top.axi4s_recv.tlast;
    wire    [9:0]  axi4s_recv_tdata0 = u_top.axi4s_recv.tdata[0*10 +: 10];
    wire    [9:0]  axi4s_recv_tdata1 = u_top.axi4s_recv.tdata[1*10 +: 10];
    wire    [9:0]  axi4s_recv_tdata2 = u_top.axi4s_recv.tdata[2*10 +: 10];
    wire    [9:0]  axi4s_recv_tdata3 = u_top.axi4s_recv.tdata[3*10 +: 10];
    wire           axi4s_recv_tvalid = u_top.axi4s_recv.tvalid;
    wire           axi4s_recv_tready = u_top.axi4s_recv.tready;

    wire    [3:0]  axi4s_swap_tuser  = u_top.axi4s_swap.tuser;
    wire           axi4s_swap_tlast  = u_top.axi4s_swap.tlast;
    wire    [9:0]  axi4s_swap_tdata0 = u_top.axi4s_swap.tdata[0*10 +: 10];
    wire    [9:0]  axi4s_swap_tdata1 = u_top.axi4s_swap.tdata[1*10 +: 10];
    wire    [9:0]  axi4s_swap_tdata2 = u_top.axi4s_swap.tdata[2*10 +: 10];
    wire    [9:0]  axi4s_swap_tdata3 = u_top.axi4s_swap.tdata[3*10 +: 10];
    wire           axi4s_swap_tvalid = u_top.axi4s_swap.tvalid;
    wire           axi4s_swap_tready = u_top.axi4s_swap.tready;

    wire    [3:0]  axi4s_clip_tuser  = u_top.axi4s_clip.tuser;
    wire           axi4s_clip_tlast  = u_top.axi4s_clip.tlast;
    wire    [9:0]  axi4s_clip_tdata0 = u_top.axi4s_clip.tdata[0*10 +: 10];
    wire    [9:0]  axi4s_clip_tdata1 = u_top.axi4s_clip.tdata[1*10 +: 10];
    wire    [9:0]  axi4s_clip_tdata2 = u_top.axi4s_clip.tdata[2*10 +: 10];
    wire    [9:0]  axi4s_clip_tdata3 = u_top.axi4s_clip.tdata[3*10 +: 10];
    wire           axi4s_clip_tvalid = u_top.axi4s_clip.tvalid;
    wire           axi4s_clip_tready = u_top.axi4s_clip.tready;

    // SPI
    assign python_miso = ~python_mosi;



    // ----------------------------------
    //  PYTHON Sensor Simulation
    // ----------------------------------

    assign python_clk_p  = clk360;
    assign python_clk_n  = ~python_clk_p;
    assign python_data_n = ~python_data_p;
    assign python_sync_n = ~python_sync_p;

    task automatic send_python_10bit
            (
                input [9:0] data0,
                input [9:0] data1,
                input [9:0] data2,
                input [9:0] data3,
                input [9:0] sync
            );
        for ( int i = 0; i < 10; i++ ) begin
            @(python_clk_p); #0;
                python_data_p[0] = data0[9-i];
                python_data_p[1] = data1[9-i];
                python_data_p[2] = data2[9-i];
                python_data_p[3] = data3[9-i];
                python_sync_p    = sync [9-i];
        end
    endtask

    task automatic send_python_train(input int cycle);
        for ( int i = 0; i < cycle; i++ ) begin
            send_python_10bit(10'h3a6, 10'h3a6, 10'h3a6, 10'h3a6, 10'h3a6);
        end
    endtask

    task automatic send_python_line(
                input [9:0] start_code  ,
                input [9:0] end_code    ,
                input [9:0] data_code   ,
                input [9:0] id_code     ,
                input int   len         
            );
        automatic logic   [15:0][9:0] data;
        automatic logic         [3:0] idx;
        idx = 0;
        data[ 0] =  0;
        data[ 1] =  2;
        data[ 2] =  4;
        data[ 3] =  6;
        data[ 4] =  1;
        data[ 5] =  3;
        data[ 6] =  5;
        data[ 7] =  7;
        data[ 8] = 15;
        data[ 9] = 13;
        data[10] = 11;
        data[11] =  9;
        data[12] = 14;
        data[13] = 12;
        data[14] = 10;
        data[15] =  8;
        send_python_10bit(data[idx+0], data[idx+1], data[idx+2], data[idx+3], start_code); for ( int j = 0; j < 4; j++ ) begin data[idx] += 16; idx++; end
        send_python_10bit(data[idx+0], data[idx+1], data[idx+2], data[idx+3], id_code   ); for ( int j = 0; j < 4; j++ ) begin data[idx] += 16; idx++; end
        for ( int i = 0; i < len/4-4; i++ ) begin
            send_python_10bit(data[idx+0], data[idx+1], data[idx+2], data[idx+3], data_code); for ( int j = 0; j < 4; j++ ) begin data[idx] += 16; idx++; end
        end
        send_python_10bit(data[idx+0], data[idx+1], data[idx+2], data[idx+3], end_code); for ( int j = 0; j < 4; j++ ) begin data[idx] += 16; idx++; end
        send_python_10bit(data[idx+0], data[idx+1], data[idx+2], data[idx+3], id_code ); for ( int j = 0; j < 4; j++ ) begin data[idx] += 16; idx++; end
        send_python_10bit(10'h3ff, 10'h3ff, 10'h3ff, 10'h3ff, 10'h059); // CRC

        // balank
        send_python_train(67);
    endtask

    int width  = 640;//256;
    int height = 64;

    logic       calib_pettern_en = 1'b1;
    initial begin
        @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;
        @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;
        @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;
//      @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;

        // trainng pattern
        while ( calib_pettern_en ) begin
            send_python_train(100);
        end

        // frame
        forever begin
            send_python_train(256);     // balank
            send_python_line(10'h22a, 10'h12a, 10'h015, 10'h000, 1280); // OPB
            send_python_line(10'h2aa, 10'h12a, 10'h035, 10'h000, width);  // 1st line
            for ( int l = 0; l < height-2; l++ ) begin
                send_python_line(10'h0aa, 10'h12a, 10'h035, 10'h000, width);  // 1st line
            end
            send_python_line(10'h0aa, 10'h3aa, 10'h035, 10'h000, width);  // 1st line
        end
    end


    // ----------------------------------
    //  MIPI RX
    // ----------------------------------

    logic               rxreseths   ;
    logic               rxbyteclkhs ;
    logic   [1:0][7:0]  rxdatahs    ;
    logic   [1:0]       rxvalidhs   ;
    logic   [1:0]       rxactivehs  ;
    logic   [1:0]       rxsynchs    ;

    assign  rxreseths   = u_top.dphy_reset ;
    assign  rxbyteclkhs = u_top.dphy_clk   ;
    always_ff @(posedge rxbyteclkhs) begin
        if ( rxreseths ) begin
            rxdatahs    <= '0;
            rxvalidhs   <= '0;
        end
        else begin
            rxdatahs    <= {u_top.dphy_dl1_txdatahs,  u_top.dphy_dl0_txdatahs  };
            rxvalidhs   <= {u_top.dphy_dl1_txreadyhs, u_top.dphy_dl0_txreadyhs };
        end
    end

    assign  rxsynchs   = ~rxvalidhs & {u_top.dphy_dl1_txreadyhs, u_top.dphy_dl0_txreadyhs };
    assign  rxactivehs = rxsynchs | rxvalidhs;


    jelly3_axi4s_if
            #(
                .USE_LAST       (1          ),
                .USE_USER       (2          ),
                .DATA_BITS      (10         ),
                .USER_BITS      (2          )
            )
        axi4s_black
            (
                .aresetn        (~reset     ),
                .aclk           (clk250     ),
                .aclken         (1'b1       )
            );

    jelly3_axi4s_if
            #(
                .USE_LAST       (1          ),
                .USE_USER       (2          ),
                .DATA_BITS      (10         ),
                .USER_BITS      (2          )
            )
        axi4s_image
            (
                .aresetn        (~reset     ),
                .aclk           (clk250     ),
                .aclken         (1'b1       )
            );

    rtcl_p3s7_hs_dphy_recv
            #(
                .CHANNELS       (1          ),
                .RAW_BITS       (10         ),
                .DPHY_LANES     (2          ),
                .DEBUG          ("false"    )
            )
        u_rtcl_p3s7_hs_dphy_recv
            (
                .param_black_width  (1280           ),
                .param_black_height (1              ),
                .param_image_width  (width          ),
                .param_image_height (height         ),

                .dphy_reset         (rxreseths      ),
                .dphy_clk           (rxbyteclkhs    ),
                .dphy_data          (rxdatahs       ),
                .dphy_valid         (rxvalidhs[0]   ),

                .m_axi4s_black      (axi4s_black    ),
                .m_axi4s_image      (axi4s_image    )
            );

    assign axi4s_black.tready = 1'b1;
    assign axi4s_image.tready = 1'b1;


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
    


    // ----------------------------------
    //  I2C
    // ----------------------------------

    localparam I2C_RATE = 100;
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


    localparam  REGADR_CORE_ID         = 15'h0000;
    localparam  REGADR_CORE_VERSION    = 15'h0001;
    localparam  REGADR_SENSOR_ENABLE   = 15'h0004;
    localparam  REGADR_SENSOR_READY    = 15'h0008;
    localparam  REGADR_RECV_RESET      = 15'h0010;
    localparam  REGADR_ALIGN_RESET     = 15'h0020;
    localparam  REGADR_ALIGN_PATTERN   = 15'h0022;
    localparam  REGADR_ALIGN_STATUS    = 15'h0028;
//  localparam  REGADR_TRIM_X_START    = 15'h0030;
//  localparam  REGADR_TRIM_X_END      = 15'h0031;
//  localparam  REGADR_CSI_DATA_TYPE   = 15'h0050;
//  localparam  REGADR_CSI_WC          = 15'h0051;
    localparam  REGADR_DPHY_CORE_RESET = 15'h0080;
    localparam  REGADR_DPHY_SYS_RESET  = 15'h0081;
    localparam  REGADR_DPHY_INIT_DONE  = 15'h0088;

    initial begin
        logic [15:0] rdata;

        #10000; // wait for reset
        cmd_write(REGADR_SENSOR_ENABLE  , 16'h0001);

        #10000; // wait for ready
        cmd_write(REGADR_DPHY_CORE_RESET, 16'h0000);
        cmd_write(REGADR_DPHY_SYS_RESET , 16'h0000);
        cmd_write(REGADR_RECV_RESET     , 16'h0000);
        cmd_write(REGADR_ALIGN_RESET    , 16'h0000);
        #1000;
        calib_pettern_en = 1'b0;

        #(I2C_RATE*2);
        cmd_write(15'h4000, 16'habcd);
        #(I2C_RATE);
        cmd_read (15'h4000, rdata);
        #(I2C_RATE);

        cmd_read(REGADR_CORE_ID     , rdata);
        cmd_read(REGADR_CORE_VERSION, rdata);

        #500000;
        cmd_write(REGADR_SENSOR_ENABLE  , 16'h0000);
        #100000;
        $finish();
    end;


endmodule

`default_nettype wire
