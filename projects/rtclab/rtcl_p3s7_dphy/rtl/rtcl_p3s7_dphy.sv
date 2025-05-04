
`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_dphy
        (
            input   var logic           in_clk50                ,
            input   var logic           in_clk72                ,
            output  var logic   [1:0]   led                     ,
            output  var logic   [7:0]   pmod                    ,



            output  var logic           sensor_pwr_en_vdd18     ,
            output  var logic           sensor_pwr_en_vdd33     ,
            output  var logic           sensor_pwr_en_pix       ,
            input   var logic           sensor_pgood            ,

            output  var logic           mipi_clk_lp_p           ,
            output  var logic           mipi_clk_lp_n           ,
            output  var logic           mipi_clk_hs_p           ,
            output  var logic           mipi_clk_hs_n           ,
            output  var logic   [1:0]   mipi_data_lp_p          ,
            output  var logic   [1:0]   mipi_data_lp_n          ,
            output  var logic   [1:0]   mipi_data_hs_p          ,
            output  var logic   [1:0]   mipi_data_hs_n          ,
            input   var logic           mipi_reset_n            ,
            input   var logic           mipi_clk                ,
            inout   tri logic           mipi_scl                ,
            inout   tri logic           mipi_sda                ,

            output  var logic           python_reset_n          ,
            output  var logic           python_clk_pll          ,
            output  var logic           python_ss_n             ,
            output  var logic           python_mosi             ,
            input   var logic           python_miso             ,
            output  var logic           python_sck              ,
            input   var logic   [2:0]   python_trigger          ,
            input   var logic   [1:0]   python_monitor          ,
            input   var logic           python_clk_p            ,
            input   var logic           python_clk_n            ,
            input   var logic   [3:0]   python_data_p           ,
            input   var logic   [3:0]   python_data_n           ,
            input   var logic           python_sync_p           ,
            input   var logic           python_sync_n           
        );
    
    // 初期リセット生成
    logic   [7:0]   reset_counter = '0;
    logic           reset = 1'b1;
    always_ff @(posedge clk72) begin
        if ( reset_counter == '1 ) begin
            reset <= 1'b0;
        end
        else begin
            reset_counter <= reset_counter + 1;
        end
    end

    /*
    logic   clk50   ;
    logic   clk100  ;
    logic   clk200  ;
    clk_wiz_0
        u_clk_wiz_0
             (
                .clk_in1    (in_clk50   ),
                .clk_out1   (clk50      ),
                .clk_out2   (clk100     ),
                .clk_out3   (clk200     )
            );
    */

//    logic clk50;
//    assign clk50 = in_clk50;


    logic clk50;
    BUFG
        u_bufg_clk50
            (
                .I  (in_clk50   ),
                .O  (clk50      )
            );

    logic clk72;
    BUFG
        u_bufg_clk72
            (
                .I  (in_clk72   ),
                .O  (clk72      )
            );



    logic   dphy_core_reset          ;
    logic   dphy_core_clk            ;
    logic   dphy_system_reset        ;
    logic   dphy_txbyteclkhs         ;
    logic   dphy_txclkesc            ;
    logic   dphy_oserdes_clkdiv      ;
    logic   dphy_oserdes_clk         ;
    logic   dphy_oserdes_clk90       ;

    mipi_dphy_clk_gen
        u_mipi_dphy_clk_gen
            (
                .reset              (reset                  ),
                .clk50              (clk50                  ),

                .core_reset         (dphy_core_reset        ),
                .core_clk           (dphy_core_clk          ),
                .system_reset       (dphy_system_reset      ),
                .txbyteclkhs        (dphy_txbyteclkhs       ),
                .txclkesc           (dphy_txclkesc          ),
                .oserdes_clkdiv     (dphy_oserdes_clkdiv    ),
                .oserdes_clk        (dphy_oserdes_clk       ),
                .oserdes_clk90      (dphy_oserdes_clk90     )
            );



    // MIPI DPHY
    /*
    mipi_dphy_0
        u_mipi_dphy_0
            (
                .core_clk                (clk200            ),    // input                            
                .core_rst                (reset             ),    // input                            
                .txclkesc_out            (                  ),    // output                           
                .txbyteclkhs             (                  ),    // output                           
                .oserdes_clkdiv_out      (                  ),    // output                           
                .oserdes_clk_out         (                  ),    // output                           
                .oserdes_clk90_out       (                  ),    // output                           
                .mmcm_lock_out           (                  ),    // output                           
                .system_rst_out          (                  ),    // output                           
                .init_done               (                  ),    // output                           
                .cl_txclkactivehs        (                  ),    // output                           
                .cl_txrequesths          ('1                ),    // input                            
                .cl_stopstate            (                  ),    // output                           
                .cl_enable               ('1                ),    // input                            
                .cl_txulpsclk            ('0                ),    // input                            
                .cl_txulpsexit           ('0                ),    // input                            
                .cl_ulpsactivenot        (                  ),    // output                           
                .dl0_txdatahs            ('0                ),    // input    [7:0]                   
                .dl0_txrequesths         ('0                ),    // input                            
                .dl0_txreadyhs           (                  ),    // output                           
                .dl0_forcetxstopmode     ('0                ),    // input                            
                .dl0_stopstate           (                  ),    // output                           
                .dl0_enable              ('1                ),    // input                            
                .dl0_txrequestesc        ('0                ),    // input                            
                .dl0_txlpdtesc           ('0                ),    // input                            
                .dl0_txulpsexit          ('0                ),    // input                            
                .dl0_ulpsactivenot       (                  ),    // output                           
                .dl0_txulpsesc           ('0                ),    // input                            
                .dl0_txtriggeresc        ('0                ),    // input    [3:0]                   
                .dl0_txdataesc           ('0                ),    // input    [7:0]                   
                .dl0_txvalidesc          ('0                ),    // input                            
                .dl0_txreadyesc          (                  ),    // output                           
                .dl1_txdatahs            ('0                ),    // input    [7:0]                   
                .dl1_txrequesths         ('0                ),    // input                            
                .dl1_txreadyhs           (                  ),    // output                           
                .dl1_forcetxstopmode     ('0                ),    // input                            
                .dl1_stopstate           (                  ),    // output                           
                .dl1_enable              ('0                ),    // input                            
                .dl1_txrequestesc        ('0                ),    // input                            
                .dl1_txlpdtesc           ('0                ),    // input                            
                .dl1_txulpsexit          ('0                ),    // input                            
                .dl1_ulpsactivenot       (                  ),    // output                           
                .dl1_txulpsesc           ('0                ),    // input                            
                .dl1_txtriggeresc        ('0                ),    // input    [3:0]                   
                .dl1_txdataesc           ('0                ),    // input    [7:0]                   
                .dl1_txvalidesc          ('0                ),    // input                            
                .dl1_txreadyesc          (                  ),    // output                           

                .clk_hs_txp              (mipi_clk_hs_p     ),    // output                           
                .clk_hs_txn              (mipi_clk_hs_n     ),    // output                           
                .data_hs_txp             (mipi_data_hs_p    ),    // output    [C_DPHY_LANES -1:0]    
                .data_hs_txn             (mipi_data_hs_n    ),    // output    [C_DPHY_LANES -1:0]    
                .clk_lp_txp              (mipi_clk_lp_p     ),    // output                           
                .clk_lp_txn              (mipi_clk_lp_n     ),    // output                           
                .data_lp_txp             (mipi_data_lp_p    ),    // output    [C_DPHY_LANES -1:0]    
                .data_lp_txn             (mipi_data_lp_n    )     // output    [C_DPHY_LANES -1:0]    
            );
    */
    mipi_dphy_0
        u_mipi_dphy_0
            (
                .core_clk               (dphy_core_clk      ),   //  input  
                .core_rst               (dphy_core_reset    ),   //  input  
                .txclkesc_in            (dphy_txclkesc      ),   //  input  
                .txbyteclkhs_in         (dphy_txbyteclkhs   ),   //  input  
                .oserdes_clkdiv_in      (dphy_oserdes_clkdiv),   //  input  
                .oserdes_clk_in         (dphy_oserdes_clk   ),   //  input  
                .oserdes_clk90_in       (dphy_oserdes_clk90 ),   //  input  
                .system_rst_in          (dphy_system_reset  ),   //  input  

                .init_done               (                  ),    // output                           
                .cl_txclkactivehs        (                  ),    // output                           
                .cl_txrequesths          ('1                ),    // input                            
                .cl_stopstate            (                  ),    // output                           
                .cl_enable               ('1                ),    // input                            
                .cl_txulpsclk            ('0                ),    // input                            
                .cl_txulpsexit           ('0                ),    // input                            
                .cl_ulpsactivenot        (                  ),    // output                           

                .dl0_txdatahs            ('0                ),    // input    [7:0]                   
                .dl0_txrequesths         ('0                ),    // input                            
                .dl0_txreadyhs           (                  ),    // output                           
                .dl0_forcetxstopmode     ('0                ),    // input                            
                .dl0_stopstate           (                  ),    // output                           
                .dl0_enable              ('1                ),    // input                            
                .dl0_txrequestesc        ('0                ),    // input                            
                .dl0_txlpdtesc           ('0                ),    // input                            
                .dl0_txulpsexit          ('0                ),    // input                            
                .dl0_ulpsactivenot       (                  ),    // output                           
                .dl0_txulpsesc           ('0                ),    // input                            
                .dl0_txtriggeresc        ('0                ),    // input    [3:0]                   
                .dl0_txdataesc           ('0                ),    // input    [7:0]                   
                .dl0_txvalidesc          ('0                ),    // input                            
                .dl0_txreadyesc          (                  ),    // output                           
                .dl1_txdatahs            ('0                ),    // input    [7:0]                   
                .dl1_txrequesths         ('0                ),    // input                            
                .dl1_txreadyhs           (                  ),    // output                           
                .dl1_forcetxstopmode     ('0                ),    // input                            
                .dl1_stopstate           (                  ),    // output                           
                .dl1_enable              ('0                ),    // input                            
                .dl1_txrequestesc        ('0                ),    // input                            
                .dl1_txlpdtesc           ('0                ),    // input                            
                .dl1_txulpsexit          ('0                ),    // input                            
                .dl1_ulpsactivenot       (                  ),    // output                           
                .dl1_txulpsesc           ('0                ),    // input                            
                .dl1_txtriggeresc        ('0                ),    // input    [3:0]                   
                .dl1_txdataesc           ('0                ),    // input    [7:0]                   
                .dl1_txvalidesc          ('0                ),    // input                            
                .dl1_txreadyesc          (                  ),    // output                           

                .clk_hs_txp              (mipi_clk_hs_p     ),    // output                           
                .clk_hs_txn              (mipi_clk_hs_n     ),    // output                           
                .data_hs_txp             (mipi_data_hs_p    ),    // output    [C_DPHY_LANES -1:0]    
                .data_hs_txn             (mipi_data_hs_n    ),    // output    [C_DPHY_LANES -1:0]    
                .clk_lp_txp              (mipi_clk_lp_p     ),    // output                           
                .clk_lp_txn              (mipi_clk_lp_n     ),    // output                           
                .data_lp_txp             (mipi_data_lp_p    ),    // output    [C_DPHY_LANES -1:0]    
                .data_lp_txn             (mipi_data_lp_n    )     // output    [C_DPHY_LANES -1:0]    
            );

    // MIPI
    logic mipi_scl_i;
    logic mipi_scl_t;
    logic mipi_sda_i;
    logic mipi_sda_t;
    IOBUF
        u_iobuf_mipi_scl
            (
                .IO     (mipi_scl   ),
                .I      (1'b0       ),
                .O      (mipi_scl_i ),
                .T      (mipi_scl_t )
            );

    IOBUF
        u_iobuf_mipi_sda
            (
                .IO     (mipi_sda   ),
                .I      (1'b0       ),
                .O      (mipi_sda_i ),
                .T      (mipi_sda_t )
            );

    assign mipi_scl_t = 1'b1;
//  assign mipi_sda_t = 1'b1;

    (* MARK_DEBUG = "true" *)   logic           i2c_wr_start;
    (* MARK_DEBUG = "true" *)   logic           i2c_wr_en   ;
    (* MARK_DEBUG = "true" *)   logic   [7:0]   i2c_wr_data ;
    (* MARK_DEBUG = "true" *)   logic           i2c_rd_start;
    (* MARK_DEBUG = "true" *)   logic           i2c_rd_req  ;
    (* MARK_DEBUG = "true" *)   logic           i2c_rd_en   ;
    (* MARK_DEBUG = "true" *)   logic   [7:0]   i2c_rd_data ;

    jelly2_i2c_slave_core
            #(
                .DIVIDER_WIDTH  (8)
            )
        u_i2c_slave_core
            (
                .reset      (reset          ),
                .clk        (clk72          ),

                .i2c_scl    (mipi_scl_i     ),
                .i2c_sda    (mipi_sda_i     ),
                .i2c_sda_t  (mipi_sda_t     ),

                .divider    (8              ),
                .dev        (7'h10          ),

                .wr_start   (i2c_wr_start   ),
                .wr_en      (i2c_wr_en      ),
                .wr_data    (i2c_wr_data    ),
                .rd_start   (i2c_rd_start   ),
                .rd_req     (i2c_rd_req     ),
                .rd_en      (i2c_rd_en      ),
                .rd_data    (i2c_rd_data    )
            );


    logic  mipi_enable;
    always_ff @(posedge clk72 or negedge mipi_reset_n) begin
        if ( !mipi_reset_n ) begin
            mipi_enable <= 1'b0;
        end
        else begin
            mipi_enable <= 1'b1;
        end
    end

    
    // 時限タイマ
    logic [31:0] timer_counter  ;
    logic        timer_enable   ;
    always_ff @(posedge clk72) begin
        if ( reset ) begin
            timer_counter <= '0;
            timer_enable  <= 1'b0;
        end
        else begin
            if ( timer_counter != '1 ) begin
                timer_counter <= timer_counter + 1;
            end
            timer_enable <= timer_counter < 72_000_000 * 10;
        end
    end
    logic enable;
    assign enable = mipi_enable; // && timer_enable;


    // Sensor Power Management
    logic sensor_ready;
    sensor_pwr_mng
        u_sensor_pwr_mng
            (
                .reset                   (reset                 ),
                .clk72                   (clk72                 ),
                
                .enable                  (enable                ),
                .ready                   (sensor_ready          ),

                .sensor_pwr_en_vdd18     (sensor_pwr_en_vdd18   ),
                .sensor_pwr_en_vdd33     (sensor_pwr_en_vdd33   ),
                .sensor_pwr_en_pix       (sensor_pwr_en_pix     ),
                .sensor_pgood            (sensor_pgood          ),
                .python_reset_n          (python_reset_n        ),
                .python_clk_pll          (python_clk_pll        )
            );



    (* MARK_DEBUG = "true" *)   logic   [8:0]   spi_addr    ;
    (* MARK_DEBUG = "true" *)   logic           spi_we      ;
    (* MARK_DEBUG = "true" *)   logic   [15:0]  spi_wdata   ;
    (* MARK_DEBUG = "true" *)   logic           spi_valid   ;
    (* MARK_DEBUG = "true" *)   logic           spi_ready   ;
    (* MARK_DEBUG = "true" *)   logic   [15:0]  spi_rdata   ;
    (* MARK_DEBUG = "true" *)   logic           spi_rvalid  ;

    python_spi
        u_python_spi
            (
                .reset          (reset          ),
                .clk            (clk72          ),

                .s_addr         (spi_addr       ),
                .s_we           (spi_we         ),
                .s_wdata        (spi_wdata      ),
                .s_valid        (spi_valid      ),
                .s_ready        (spi_ready      ),
                .m_rdata        (spi_rdata      ),
                .m_rvalid       (spi_rvalid     ),

                .spi_ss_n       (python_ss_n    ),
                .spi_sck        (python_sck     ),
                .spi_mosi       (python_mosi    ),
                .spi_miso       (python_miso    )
            );

    /*
    spi_cmd
        u_spi_cmd
            (
                .reset          (reset          ),
                .clk            (clk72          ),

                .enable         (sensor_ready   ),

                .m_spi_addr     (spi_addr       ),
                .m_spi_we       (spi_we         ),
                .m_spi_wdata    (spi_wdata      ),
                .m_spi_valid    (spi_valid      ),
                .m_spi_ready    (spi_ready      )
            );
    */

    // -------------------------
    //  I2C to SPI
    // -------------------------

    logic   [1:0]    cmd_wcnt    ;
    logic   [31:0]   cmd_wdata   ;
    logic   [15:0]   cmd_rdata   ;
    always_ff @(posedge clk72) begin
        if ( reset ) begin
            cmd_wcnt  <= '0;
            cmd_wdata <= 'x;
            cmd_rdata <= 'x;
            spi_valid <= 1'b0;
        end
        else begin
            if ( spi_ready ) begin
                spi_valid <= 1'b0;
            end
            if ( i2c_wr_start ) begin
                cmd_wcnt <= '0;
            end
            if ( i2c_wr_en ) begin
                cmd_wcnt  <= cmd_wcnt + 1;
                cmd_wdata <= {cmd_wdata[23:0], i2c_wr_data};
                spi_valid <= (cmd_wcnt == 2'd3);
            end
            if ( i2c_rd_req ) begin
                cmd_rdata <= (cmd_rdata >> 8);
            end
            if ( spi_rvalid ) begin
                cmd_rdata <= spi_rdata;
            end
        end
    end

    assign spi_we    = cmd_wdata[31];
    assign spi_addr  = cmd_wdata[16 +:  9];
    assign spi_wdata = cmd_wdata[ 0 +: 16];

    assign i2c_rd_en   = i2c_rd_req;
    assign i2c_rd_data = cmd_rdata[7:0];



//    assign sensor_pwr_en_vdd18 = 1'b0;
//    assign sensor_pwr_en_vdd33 = 1'b0;
//    assign sensor_pwr_en_pix   = 1'b0;
//    assign python_reset_n      = 1'b0;
//    assign python_clk_pll      = 1'b0;
//    assign python_ss_n         = 1'b0;
//    assign python_mosi         = 1'b0;
//    assign python_sck          = 1'b0;

    /*
    logic           python_clk  ;
    logic   [3:0]   python_data ;
    IBUFDS
        u_ibufds_python_clk
            (
                .I      (python_clk_p   ),
                .IB     (python_clk_n   ),
                .O      (python_clk     ) 
            );
    
    for ( genvar i = 0; i < 4; i++ ) begin
        IBUFDS
            u_ibufds_python_data
                (
                    .I      (python_data_p[i])   ,
                    .IB     (python_data_n[i])   ,
                    .O      (python_data[i])     
                );
    end
    
    logic           python_sync ;
    IBUFDS
        u_ibufds_python_sync
            (
                .I      (python_sync_p)       ,
                .IB     (python_sync_n)       ,
                .O      (python_sync)     
            );
    */

    logic            io_reset           ;
    logic            python_clk         ;
    logic   [19:0]   python_data_tmp    ;
    selectio_wiz_0
        u_selectio_wiz_0
            (
                .clk_reset              (reset          ),
                .io_reset               (io_reset       ),
//              .ref_clock              (clk200         ),
//              .delay_locked           (               ),

                .clk_in_p               (python_clk_p   ),
                .clk_in_n               (python_clk_n   ),
                .data_in_from_pins_p    ({python_sync_p, python_data_p}),
                .data_in_from_pins_n    ({python_sync_n, python_data_n}),

                .clk_div_out            (python_clk     ),
                .data_in_to_device      (python_data_tmp),
                .bitslip                ('0             )
            );

    logic   [7:0]   io_reset_cnt;
    always_ff @(posedge python_clk or posedge reset) begin
        if ( reset ) begin
            io_reset_cnt <= '1;
            io_reset     <= 1'b1;
        end
        else begin
            if ( io_reset_cnt > 0 ) begin
                io_reset_cnt <= io_reset_cnt - 1;
            end
            io_reset <= (io_reset_cnt != 0);
        end
    end

    /*
    logic   [4:0][3:0]   python_data    ;
    for ( genvar i = 0; i < 5; i++ ) begin
        for ( genvar j = 0; j < 4; j++ ) begin
            assign python_data[i][j] = python_data_tmp[j*5 + i];
        end
    end
    */

    // Blinking LED
    logic   [24:0]     clk50_counter; // リセットがないので初期値を設定
    always_ff @(posedge clk50) begin
        clk50_counter <= clk50_counter + 1;
    end

    logic   [24:0]     clk72_counter; // リセットがないので初期値を設定
    always_ff @(posedge clk72) begin
        clk72_counter <= clk72_counter + 1;
    end

    logic   [24:0]     python_clk_counter; // リセットがないので初期値を設定
    always_ff @(posedge python_clk) begin
        python_clk_counter <= python_clk_counter + 1;
    end


//  assign led[0] = clk50_counter[24];
//  assign led[1] = clk72_counter[24];
    assign led[0] = enable;
//  assign led[1] = mipi_enable;
//  assign led[1] = sensor_pgood;
    assign led[1] = python_clk_counter[24];

    assign pmod[7:0] = clk50_counter[15:8];


    // --------------------------------
    //  Debug
    // --------------------------------

    /*
    (* MARK_DEBUG = "true" *)   logic   [7:0]   dbg_clk72_counter;
    always_ff @(posedge clk72) begin
        dbg_clk72_counter <= dbg_clk72_counter + 1;
    end

    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_reset_n;
    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_scl;
    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_sda;
    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_sda_t;
    always_ff @(posedge clk72) begin
        dbg_mipi_reset_n <= mipi_reset_n ;
        dbg_mipi_scl     <= mipi_scl_i ;
        dbg_mipi_sda     <= mipi_sda_i ;
        dbg_mipi_sda_t   <= mipi_sda_t ;
    end

    (* MARK_DEBUG = "true" *)   logic   dbg_sensor_ready    ;
    (* MARK_DEBUG = "true" *)   logic   dbg_spi_ss_n        ;
    (* MARK_DEBUG = "true" *)   logic   dbg_spi_sck         ;
    (* MARK_DEBUG = "true" *)   logic   dbg_spi_mosi        ;
    (* MARK_DEBUG = "true" *)   logic   dbg_spi_miso        ;
    always_ff @(posedge clk72) begin
        dbg_sensor_ready <= sensor_ready ;
        dbg_spi_ss_n <= python_ss_n ;
        dbg_spi_sck  <= python_sck  ;
        dbg_spi_mosi <= python_mosi ;
        dbg_spi_miso <= python_miso ;
    end

    (* MARK_DEBUG = "true" *)   logic   [3:0]   dbg_python_data0;
    (* MARK_DEBUG = "true" *)   logic   [3:0]   dbg_python_data1;
    (* MARK_DEBUG = "true" *)   logic   [3:0]   dbg_python_data2;
    (* MARK_DEBUG = "true" *)   logic   [3:0]   dbg_python_data3;
    (* MARK_DEBUG = "true" *)   logic   [3:0]   dbg_python_sync;
    always_ff @(posedge python_clk) begin
        dbg_python_data0 <= python_data[0];
        dbg_python_data1 <= python_data[1];
        dbg_python_data2 <= python_data[2];
        dbg_python_data3 <= python_data[3];
        dbg_python_sync  <= python_data[4];
    end
    */

endmodule

`default_nettype wire

// end of file
