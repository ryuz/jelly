
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
    localparam RATE720 = 1000.0/720.00;
    localparam RATE360 = 1000.0/360.00;
    localparam RATE180 = 1000.0/180.00;
    localparam RATE250 = 1000.0/250.00;
    localparam RATE500 = 1000.0/500.00;

    logic       reset = 1'b1;
    initial #8000 reset = 1'b0;

    logic       clk50 = 1'b1;
    initial forever #(RATE50/2.0) clk50 = ~clk50;
    
    logic       clk72 = 1'b1;
    initial forever #(RATE72/2.0) clk72 = ~clk72;

    logic       clk360 = 1'b1;
    initial forever #(RATE360/2.0) clk360 = ~clk360;

    logic       clk180 = 1'b1;
    initial forever #(RATE180/2.0) clk180 = ~clk180;

    logic       clk250 = 1'b1;
    initial forever #(RATE250/2.0) clk250 = ~clk250;

    logic       clk500 = 1'b1;
    initial forever #(RATE500/2.0) clk500 = ~clk500;


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
    
    logic           mipi_reset_n        ;
    logic           mipi_clk            ;
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

    rtcl_spartan7_python300
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

                .mipi_reset_n           ,
                .mipi_clk               ,
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
    
    assign python_miso = ~python_mosi;

    assign python_clk_p  = clk360;
    assign python_clk_n  = ~python_clk_p;
    assign python_data_n = ~python_data_p;
    assign python_sync_n = ~python_sync_p;

    task send_python_10bit
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

    task send_python_train(input int cycle);
        for ( int i = 0; i < cycle; i++ ) begin
            send_python_10bit(10'h3a6, 10'h3a6, 10'h3a6, 10'h3a6, 10'h3a6);
        end
    endtask

    task send_python_line(
                input [9:0] start_code  ,
                input [9:0] end_code    ,
                input [9:0] data_code   ,
                input [9:0] id_code     ,
                input int   len         
            );
        logic   [9:0] data0;
        logic   [9:0] data1;
        logic   [9:0] data2;
        logic   [9:0] data3;
        data0 = 0;
        data1 = 1;
        data2 = 2;
        data3 = 3;
        send_python_10bit(data0, data1, data2, data3, start_code); data0 += 4; data1 += 4; data2 += 4; data3 += 4;
        send_python_10bit(data0, data1, data2, data3, id_code   ); data0 += 4; data1 += 4; data2 += 4; data3 += 4;
        for ( int i = 0; i < len/4-4; i++ ) begin
            send_python_10bit(data0, data1, data2, data3, data_code); data0 += 4; data1 += 4; data2 += 4; data3 += 4;
        end
        send_python_10bit(data0, data1, data2, data3, end_code); data0 += 4; data1 += 4; data2 += 4; data3 += 4;
        send_python_10bit(data0, data1, data2, data3, id_code ); data0 += 4; data1 += 4; data2 += 4; data3 += 4;
        send_python_10bit(10'h3ff, 10'h3ff, 10'h3ff, 10'h3ff, 10'h059); // CRC

        // balank
        send_python_train(67);
    endtask


    initial begin
        int width, height;
        width  = 640;//256;
        height = 64;

        @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;
        @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;
        @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;
//      @(python_clk_p); #0;  python_data_p = '1; python_sync_p = '1;


        // trainng pattern
        send_python_train(2000);

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



    // MIPI RX
    logic               rxreseths   ;
    logic               rxbyteclkhs ;
    logic   [1:0][7:0]  rxdatahs    ;
    logic   [1:0]       rxvalidhs   ;
    logic   [1:0]       rxactivehs  ;
    logic   [1:0]       rxsynchs    ;

    assign  rxreseths   = u_top.dphy_txbyteclkhs_reset ;
    assign  rxbyteclkhs = u_top.dphy_txbyteclkhs       ;
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

    logic               mipi_ecc_corrected;
    logic               mipi_ecc_error;
    logic               mipi_ecc_valid;
    logic               mipi_crc_error;
    logic               mipi_crc_valid;
    logic               mipi_packet_lost;
    logic               mipi_fifo_overflow;

    logic               axi4s_csi2_tuser ;
    logic               axi4s_csi2_tlast ;
    logic   [7:0]       axi4s_csi2_tdata ;
    logic               axi4s_csi2_tvalid;

    jelly2_mipi_csi2_rx
            #(
                .LANES              (2),
                .DATA_WIDTH         (10),
                .M_FIFO_ASYNC       (1),
                .M_FIFO_PTR_WIDTH   (10)
            )
        u_mipi_csi2_rx
            (
                .aresetn            (~reset             ),
                .aclk               (clk500             ),

                .param_data_type    (8'h2b              ),

                .ecc_corrected      (mipi_ecc_corrected ),
                .ecc_error          (mipi_ecc_error     ),
                .ecc_valid          (mipi_ecc_valid     ),
                .crc_error          (mipi_crc_error     ),
                .crc_valid          (mipi_crc_valid     ),
                .packet_lost        (mipi_packet_lost   ),
                .fifo_overflow      (mipi_fifo_overflow ),
                
                .rxreseths          ,
                .rxbyteclkhs        ,
                .rxdatahs           ,
                .rxvalidhs          ,
                .rxactivehs         ,
                .rxsynchs           ,
                
                .m_axi4s_aresetn    (~reset             ),
                .m_axi4s_aclk       (clk500             ),
                .m_axi4s_tuser      (axi4s_csi2_tuser   ),
                .m_axi4s_tlast      (axi4s_csi2_tlast   ),
                .m_axi4s_tdata      (axi4s_csi2_tdata   ),
                .m_axi4s_tvalid     (axi4s_csi2_tvalid  ),
                .m_axi4s_tready     (1'b1               )  // (axi4s_csi2_tready)
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
        #10000000
        $finish;
    end
    
    /*
    // to stream
    jelly3_axi4s_if
            #(
                .USE_LAST   (1                  ),
                .USE_USER   (1                  ),
                .DATA_BITS  (4*10               ),
                .USER_BITS  (1                  ),
                .DEBUG      ("true"             )
            )
        axi4s
            (
                .aresetn    (~u_top.io_reset    ),
                .aclk       (u_top.python_clk   ),
                .aclken     (1'b1               )
            );

    jelly3_model_axi4s_m
            #(
                .COMPONENTS     (4      ),
                .DATA_BITS      (10     ),
                .IMG_WIDTH      (640/4  ),
                .IMG_HEIGHT     (480    ),
                .H_BLANK        (0      ),
                .V_BLANK        (0      ),
                .X_BITS         (32     ),
                .BUSY_RATE      (60     ),
                .RANDOM_SEED    (0      ),
                .ENDIAN         (0      )
            )
        u_model_axi4s_m
            (
                .enable         (1'b1   ),
                .busy           (       ),
                .m_axi4s        (axi4s  ),
                .out_x          (       ),
                .out_y          (       ),
                .out_f          (       )
            );
    
    initial begin
//        force u_top.axi4s_python.tuser  = axi4s.tuser ;
//        force u_top.axi4s_python.tlast  = axi4s.tlast ;
//        force u_top.axi4s_python.tdata  = axi4s.tdata ;
//        force u_top.axi4s_python.tvalid = axi4s.tvalid;

        force u_top.axi4s_python_tuser  = axi4s.tuser ;
        force u_top.axi4s_python_tlast  = axi4s.tlast ;
        force u_top.axi4s_python_tdata  = axi4s.tdata ;
        force u_top.axi4s_python_tvalid = axi4s.tvalid;
    end
    assign axi4s.tready = u_top.axi4s_python.tready;
    */



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
    localparam  REGADR_CTL_BITSLIP   = 15'h0012;

    initial begin
        logic [15:0] rdata;

        #(I2C_RATE*10);
        cmd_write(REGADR_CTL_BITSLIP, 16'haa55);

        #(I2C_RATE*2);
        cmd_write(15'h4000, 16'habcd);
        #(I2C_RATE);
        cmd_read (15'h4000, rdata);
        #(I2C_RATE);


        #(I2C_RATE*10)  $finish();
    end;


endmodule

`default_nettype wire
