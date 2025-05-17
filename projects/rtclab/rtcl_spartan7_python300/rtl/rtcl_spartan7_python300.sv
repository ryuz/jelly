
`timescale 1ns / 1ps
`default_nettype none

module rtcl_spartan7_python300
        (
            input   var logic           in_clk50                ,
            input   var logic           in_clk72                ,
            output  var logic   [1:0]   led                     ,
            output  var logic   [7:0]   pmod                    ,

            output  var logic           sensor_pwr_en_vdd18     ,
            output  var logic           sensor_pwr_en_vdd33     ,
            output  var logic           sensor_pwr_en_pix       ,
            input   var logic           sensor_pgood            ,

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
            input   var logic           python_sync_n           ,

            input   var logic           mipi_reset_n            ,
            input   var logic           mipi_clk                ,
            inout   tri logic           mipi_scl                ,
            inout   tri logic           mipi_sda                ,
            output  var logic           mipi_clk_lp_p           ,
            output  var logic           mipi_clk_lp_n           ,
            output  var logic           mipi_clk_hs_p           ,
            output  var logic           mipi_clk_hs_n           ,
            output  var logic   [1:0]   mipi_data_lp_p          ,
            output  var logic   [1:0]   mipi_data_lp_n          ,
            output  var logic   [1:0]   mipi_data_hs_p          ,
            output  var logic   [1:0]   mipi_data_hs_n          
        );

    // ---------------------------------
    //  Clock and Reset
    // ---------------------------------

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


    // -------------------------------------
    //  MIPI GPIO
    // -------------------------------------

    logic  mipi_enable;
    always_ff @(posedge clk72 or negedge mipi_reset_n) begin
        if ( !mipi_reset_n ) begin
            mipi_enable <= 1'b0;
        end
        else begin
            mipi_enable <= 1'b1;
        end
    end

    logic sensor_pwr_enable;
    assign sensor_pwr_enable = mipi_enable;


    // -------------------------------------
    //  MIPI I2C
    // -------------------------------------

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

    logic           i2c_wr_start;
    logic           i2c_wr_en   ;
    logic   [7:0]   i2c_wr_data ;
    logic           i2c_rd_start;
    logic           i2c_rd_req  ;
    logic           i2c_rd_en   ;
    logic   [7:0]   i2c_rd_data ;

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

    // -------------------------
    //  I2C to SPI
    // -------------------------

    logic   [8:0]   spi_addr    ;
    logic           spi_we      ;
    logic   [15:0]  spi_wdata   ;
    logic           spi_valid   ;
    logic           spi_ready   ;
    logic   [15:0]  spi_rdata   ;
    logic           spi_rvalid  ;
    
    jelly3_axi4l_if
            #(
                .ADDR_BITS  (15         ),
                .DATA_BITS  (16         )
            )
        axi4l
            (
                .aresetn    (~reset     ),
                .aclk       (clk72      ),
                .aclken     (1'b1       )
            );

    i2c_to_spi
        u_i2c_to_spi
            (
                .reset          (reset          ),
                .clk            (clk72          ),

                .i2c_wr_start   (i2c_wr_start   ),
                .i2c_wr_en      (i2c_wr_en      ),
                .i2c_wr_data    (i2c_wr_data    ),
                .i2c_rd_start   (i2c_rd_start   ),
                .i2c_rd_req     (i2c_rd_req     ),
                .i2c_rd_en      (i2c_rd_en      ),
                .i2c_rd_data    (i2c_rd_data    ),

                .spi_addr       (spi_addr       ),
                .spi_we         (spi_we         ),
                .spi_wdata      (spi_wdata      ),
                .spi_valid      (spi_valid      ),
                .spi_ready      (spi_ready      ),
                .spi_rdata      (spi_rdata      ),
                .spi_rvalid     (spi_rvalid     ),

                .m_axi4l        (axi4l          )
            );

//    assign axi4l.awready = 1'b1;
//    assign axi4l.wready  = 1'b1;
//    assign axi4l.arready = 1'b1;


                                logic           ctl_iserdes_reset   ;
                                logic   [4:0]   ctl_iserdes_bitslip ;
                                logic           ctl_align_reset     ;
                                logic   [9:0]   ctl_align_pattern   ;
    (* MARK_DEBUG = "true" *)   logic           ctl_calib_done      ;
    (* MARK_DEBUG = "true" *)   logic           ctl_calib_error     ;

    py300_control
        u_py300_control
            (
                .s_axi4l                (axi4l                  ),

                .out_iserdes_reset      (ctl_iserdes_reset      ),
                .out_iserdes_bitslip    (ctl_iserdes_bitslip    ),
                .out_align_reset        (ctl_align_reset        ),
                .out_align_pattern      (ctl_align_pattern      ),
                .in_calib_done          (ctl_calib_done         ),
                .in_calib_error         (ctl_calib_error        )
            );
    


    // -------------------------------------
    //  MIPI DPHY
    // -------------------------------------

    logic   dphy_core_reset          ;
    logic   dphy_core_clk            ;
    logic   dphy_system_reset        ;
    logic   dphy_txbyteclkhs_reset   ;
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
                .txbyteclkhs_reset  (dphy_txbyteclkhs_reset ),
                .txbyteclkhs        (dphy_txbyteclkhs       ),
                .txclkesc           (dphy_txclkesc          ),
                .oserdes_clkdiv     (dphy_oserdes_clkdiv    ),
                .oserdes_clk        (dphy_oserdes_clk       ),
                .oserdes_clk90      (dphy_oserdes_clk90     )
            );

    // MIPI DPHY
    (* mark_debug="true" *)     logic           dphy_init_done              ;
    (* mark_debug="true" *)     logic           dphy_cl_txclkactivehs       ;
    (* mark_debug="true" *)     logic           dphy_cl_txrequesths         ;
    (* mark_debug="true" *)     logic           dphy_cl_stopstate           ;
    (* mark_debug="true" *)     logic           dphy_cl_enable              ;
    (* mark_debug="true" *)     logic           dphy_cl_txulpsclk           ;
    (* mark_debug="true" *)     logic           dphy_cl_txulpsexit          ;
    (* mark_debug="true" *)     logic           dphy_cl_ulpsactivenot       ;
    (* mark_debug="true" *)     logic   [7:0]   dphy_dl0_txdatahs           ;
    (* mark_debug="true" *)     logic           dphy_dl0_txrequesths        ;
    (* mark_debug="true" *)     logic           dphy_dl0_txreadyhs          ;
    (* mark_debug="true" *)     logic           dphy_dl0_forcetxstopmode    ;
    (* mark_debug="true" *)     logic           dphy_dl0_stopstate          ;
    (* mark_debug="true" *)     logic           dphy_dl0_enable             ;
    (* mark_debug="true" *)     logic           dphy_dl0_txrequestesc       ;
    (* mark_debug="true" *)     logic           dphy_dl0_txlpdtesc          ;
    (* mark_debug="true" *)     logic           dphy_dl0_txulpsexit         ;
    (* mark_debug="true" *)     logic           dphy_dl0_ulpsactivenot      ;
    (* mark_debug="true" *)     logic           dphy_dl0_txulpsesc          ;
    (* mark_debug="true" *)     logic   [3:0]   dphy_dl0_txtriggeresc       ;
    (* mark_debug="true" *)     logic   [7:0]   dphy_dl0_txdataesc          ;
    (* mark_debug="true" *)     logic           dphy_dl0_txvalidesc         ;
    (* mark_debug="true" *)     logic           dphy_dl0_txreadyesc         ;
    (* mark_debug="true" *)     logic   [7:0]   dphy_dl1_txdatahs           ;
    (* mark_debug="true" *)     logic           dphy_dl1_txrequesths        ;
    (* mark_debug="true" *)     logic           dphy_dl1_txreadyhs          ;
    (* mark_debug="true" *)     logic           dphy_dl1_forcetxstopmode    ;
    (* mark_debug="true" *)     logic           dphy_dl1_stopstate          ;
    (* mark_debug="true" *)     logic           dphy_dl1_enable             ;
    (* mark_debug="true" *)     logic           dphy_dl1_txrequestesc       ;
    (* mark_debug="true" *)     logic           dphy_dl1_txlpdtesc          ;
    (* mark_debug="true" *)     logic           dphy_dl1_txulpsexit         ;
    (* mark_debug="true" *)     logic           dphy_dl1_ulpsactivenot      ;
    (* mark_debug="true" *)     logic           dphy_dl1_txulpsesc          ;
    (* mark_debug="true" *)     logic   [3:0]   dphy_dl1_txtriggeresc       ;
    (* mark_debug="true" *)     logic   [7:0]   dphy_dl1_txdataesc          ;
    (* mark_debug="true" *)     logic           dphy_dl1_txvalidesc         ;
    (* mark_debug="true" *)     logic           dphy_dl1_txreadyesc         ;

    mipi_dphy_0
        u_mipi_dphy_0
            (
                .core_clk               (dphy_core_clk              ),   //  input  
                .core_rst               (dphy_core_reset            ),   //  input  
                .txclkesc_in            (dphy_txclkesc              ),   //  input  
                .txbyteclkhs_in         (dphy_txbyteclkhs           ),   //  input  
                .oserdes_clkdiv_in      (dphy_oserdes_clkdiv        ),   //  input  
                .oserdes_clk_in         (dphy_oserdes_clk           ),   //  input  
                .oserdes_clk90_in       (dphy_oserdes_clk90         ),   //  input  
                .system_rst_in          (dphy_system_reset          ),   //  input  

                .init_done              (dphy_init_done             ),    // output                           
                .cl_txclkactivehs       (dphy_cl_txclkactivehs      ),    // output                           
                .cl_txrequesths         (dphy_cl_txrequesths        ),    // input                            
                .cl_stopstate           (dphy_cl_stopstate          ),    // output                           
                .cl_enable              (dphy_cl_enable             ),    // input                            
                .cl_txulpsclk           (dphy_cl_txulpsclk          ),    // input                            
                .cl_txulpsexit          (dphy_cl_txulpsexit         ),    // input                            
                .cl_ulpsactivenot       (dphy_cl_ulpsactivenot      ),    // output                           
                .dl0_txdatahs           (dphy_dl0_txdatahs          ),    // input    [7:0]                   
                .dl0_txrequesths        (dphy_dl0_txrequesths       ),    // input                            
                .dl0_txreadyhs          (dphy_dl0_txreadyhs         ),    // output                           
                .dl0_forcetxstopmode    (dphy_dl0_forcetxstopmode   ),    // input                            
                .dl0_stopstate          (dphy_dl0_stopstate         ),    // output                           
                .dl0_enable             (dphy_dl0_enable            ),    // input                            
                .dl0_txrequestesc       (dphy_dl0_txrequestesc      ),    // input                            
                .dl0_txlpdtesc          (dphy_dl0_txlpdtesc         ),    // input                            
                .dl0_txulpsexit         (dphy_dl0_txulpsexit        ),    // input                            
                .dl0_ulpsactivenot      (dphy_dl0_ulpsactivenot     ),    // output                           
                .dl0_txulpsesc          (dphy_dl0_txulpsesc         ),    // input                            
                .dl0_txtriggeresc       (dphy_dl0_txtriggeresc      ),    // input    [3:0]                   
                .dl0_txdataesc          (dphy_dl0_txdataesc         ),    // input    [7:0]                   
                .dl0_txvalidesc         (dphy_dl0_txvalidesc        ),    // input                            
                .dl0_txreadyesc         (dphy_dl0_txreadyesc        ),    // output                           
                .dl1_txdatahs           (dphy_dl1_txdatahs          ),    // input    [7:0]                   
                .dl1_txrequesths        (dphy_dl1_txrequesths       ),    // input                            
                .dl1_txreadyhs          (dphy_dl1_txreadyhs         ),    // output                           
                .dl1_forcetxstopmode    (dphy_dl1_forcetxstopmode   ),    // input                            
                .dl1_stopstate          (dphy_dl1_stopstate         ),    // output                           
                .dl1_enable             (dphy_dl1_enable            ),    // input                            
                .dl1_txrequestesc       (dphy_dl1_txrequestesc      ),    // input                            
                .dl1_txlpdtesc          (dphy_dl1_txlpdtesc         ),    // input                            
                .dl1_txulpsexit         (dphy_dl1_txulpsexit        ),    // input                            
                .dl1_ulpsactivenot      (dphy_dl1_ulpsactivenot     ),    // output                           
                .dl1_txulpsesc          (dphy_dl1_txulpsesc         ),    // input                            
                .dl1_txtriggeresc       (dphy_dl1_txtriggeresc      ),    // input    [3:0]                   
                .dl1_txdataesc          (dphy_dl1_txdataesc         ),    // input    [7:0]                   
                .dl1_txvalidesc         (dphy_dl1_txvalidesc        ),    // input                            
                .dl1_txreadyesc         (dphy_dl1_txreadyesc        ),    // output                           

                .clk_hs_txp             (mipi_clk_hs_p              ),    // output                           
                .clk_hs_txn             (mipi_clk_hs_n              ),    // output                           
                .data_hs_txp            (mipi_data_hs_p             ),    // output    [C_DPHY_LANES -1:0]    
                .data_hs_txn            (mipi_data_hs_n             ),    // output    [C_DPHY_LANES -1:0]    
                .clk_lp_txp             (mipi_clk_lp_p              ),    // output                           
                .clk_lp_txn             (mipi_clk_lp_n              ),    // output                           
                .data_lp_txp            (mipi_data_lp_p             ),    // output    [C_DPHY_LANES -1:0]    
                .data_lp_txn            (mipi_data_lp_n             )     // output    [C_DPHY_LANES -1:0]    
            );

//  assign dphy_cl_txrequesths      = '1    ;
    assign dphy_cl_enable           = '1    ;
    assign dphy_cl_txulpsclk        = '0    ;
    assign dphy_cl_txulpsexit       = '0    ;
//  assign dphy_dl0_txdatahs        = '0    ;
//  assign dphy_dl0_txrequesths     = '0    ;
    assign dphy_dl0_forcetxstopmode = '0    ;
    assign dphy_dl0_enable          = '1    ;
    assign dphy_dl0_txrequestesc    = '0    ;
    assign dphy_dl0_txlpdtesc       = '0    ;
    assign dphy_dl0_txulpsexit      = '0    ;
    assign dphy_dl0_txulpsesc       = '0    ;
    assign dphy_dl0_txtriggeresc    = '0    ;
    assign dphy_dl0_txdataesc       = '0    ;
    assign dphy_dl0_txvalidesc      = '0    ;
//  assign dphy_dl1_txdatahs        = '0    ;
//  assign dphy_dl1_txrequesths     = '0    ;
    assign dphy_dl1_forcetxstopmode = '0    ;
    assign dphy_dl1_enable          = '1    ;
    assign dphy_dl1_txrequestesc    = '0    ;
    assign dphy_dl1_txlpdtesc       = '0    ;
    assign dphy_dl1_txulpsexit      = '0    ;
    assign dphy_dl1_txulpsesc       = '0    ;
    assign dphy_dl1_txtriggeresc    = '0    ;
    assign dphy_dl1_txdataesc       = '0    ;
    assign dphy_dl1_txvalidesc      = '0    ;

    (* ASYNC_REG="true" *) logic  ff0_init_done, ff1_init_done;
    always_ff @(posedge dphy_txbyteclkhs) begin
        ff0_init_done <= dphy_init_done;
        ff1_init_done <= ff0_init_done;
    end

    logic [7:0]     mipi_test_count;
    always_ff @(posedge dphy_txbyteclkhs) begin
        if ( dphy_txbyteclkhs_reset || !ff1_init_done ) begin
            dphy_cl_txrequesths  <= 1'b0;
            dphy_dl0_txrequesths <= 1'b0;
            dphy_dl1_txrequesths <= 1'b0;

            dphy_dl0_txdatahs    <= '0;
            dphy_dl1_txdatahs    <= '0;

            mipi_test_count      <= '0;
        end
        else begin
            dphy_cl_txrequesths <= 1'b1;
            if ( dphy_cl_txclkactivehs ) begin
                mipi_test_count <= mipi_test_count + 1;
            end
            else begin
                mipi_test_count <= '0;
            end
            dphy_dl0_txrequesths <= mipi_test_count[7];
            dphy_dl1_txrequesths <= mipi_test_count[7];

            if ( dphy_dl0_txreadyhs ) begin
                dphy_dl0_txdatahs <= dphy_dl0_txdatahs + 1;
            end
            if ( dphy_dl1_txreadyhs ) begin
                dphy_dl1_txdatahs <= dphy_dl1_txdatahs - 1;
            end
        end
    end



    // -------------------------------------
    //  PYTHON300 Sensor
    // -------------------------------------

    // Sensor Power Management
    logic sensor_ready;
    sensor_pwr_mng
        u_sensor_pwr_mng
            (
                .reset                   (reset                 ),
                .clk72                   (clk72                 ),
                
                .enable                  (sensor_pwr_enable     ),
                .ready                   (sensor_ready          ),

                .sensor_pwr_en_vdd18     (sensor_pwr_en_vdd18   ),
                .sensor_pwr_en_vdd33     (sensor_pwr_en_vdd33   ),
                .sensor_pwr_en_pix       (sensor_pwr_en_pix     ),
                .sensor_pgood            (sensor_pgood          ),
                .python_reset_n          (python_reset_n        ),
                .python_clk_pll          (python_clk_pll        )
            );

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


                                logic               python_reset    ;
                                logic               python_clk      ;
    (* mark_debug = "true" *)   logic   [3:0][1:0]  python_data     ;
    (* mark_debug = "true" *)   logic        [1:0]  python_sync     ;
    python_receiver
        u_python_receiver
            (
                .in_reset       (ctl_iserdes_reset  ),
                .in_clk_p       (python_clk_p       ),
                .in_clk_n       (python_clk_n       ),
                .in_data_p      (python_data_p      ),
                .in_data_n      (python_data_n      ),
                .in_sync_p      (python_sync_p      ),
                .in_sync_n      (python_sync_n      ),

                .out_reset      (python_reset       ),
                .out_clk        (python_clk         ),
                .out_data       (python_data        ),
                .out_sync       (python_sync        )
            );

    (* MARK_DEBUG = "true" *)   logic   [3:0][9:0]  python_align_data      ;
    (* MARK_DEBUG = "true" *)   logic        [9:0]  python_align_sync      ;
    (* MARK_DEBUG = "true" *)   logic               python_align_valid     ;

    python_align_10bit
        u_python_align_10bit
            (
                .reset          (python_reset       ),
                .clk            (python_clk         ),

                .sw_reset       (ctl_iserdes_reset  ),
                
                .pattern        (ctl_align_pattern  ),
                .calib_done     (ctl_calib_done     ),
                .calib_error    (ctl_calib_error    ),
                
                .s_data         (python_data        ),
                .s_sync         (python_sync        ),
                .s_valid        (1'b1               ),

                .m_data         (python_align_data  ),
                .m_sync         (python_align_sync  ),
                .m_valid        (python_align_valid )
            );

    // to stream
    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (4*10               ),
                .USER_BITS      (1                  ),
                .DEBUG          ("true"             )
            )
        axi4s_python_4lane
            (
                .aresetn        (~python_reset      ),
                .aclk           (python_clk         ),
                .aclken         (1'b1               )
            );

    python_to_axi4s
        u_python_to_axi4s
            (
                .s_data         (python_align_data  ),
                .s_sync         (python_align_sync  ),
                .s_valid        (python_align_valid ),
                .m_axi4s        (axi4s_python_4lane )
            );
//  assign axi4s_python_4lane.tready = 1'b1;

    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (1*10               ),
                .USER_BITS      (1                  ),
                .DEBUG          ("true"             )
            )
        axi4s_python_1lane
            (
                .aresetn        (~python_reset      ),
                .aclk           (python_clk         ),
                .aclken         (1'b1               )
            );
    
    lane_conv_4to1
        u_lane_conv_4to1
            (
                .s_axi4s    (axi4s_python_4lane ),
                .m_axi4s    (axi4s_python_1lane )
            );

//  assign axi4s_python_1lane.tready = 1'b1;

    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (2*8                ),
                .USER_BITS      (1                  ),
                .DEBUG          ("true"             )
            )
        axi4s_csi_raw10
            (
                .aresetn        (~python_reset      ),
                .aclk           (python_clk         ),
                .aclken         (1'b1               )
            );

    pack_csi_raw10
        u_pack_csi_raw10
            (
                .s_axi4s        (axi4s_python_1lane ),
                .m_axi4s        (axi4s_csi_raw10    )
            );

//  assign axi4s_csi_raw10.tready = 1'b1;


    jelly3_axi4s_if
            #(
                .USE_LAST       (1                      ),
                .USE_USER       (1                      ),
                .DATA_BITS      (2*8                    ),
                .USER_BITS      (1                      ),
                .DEBUG          ("true"                 )
            )
        axi4s_csi_fifo
            (
                .aresetn        (~dphy_txbyteclkhs_reset),
                .aclk           (dphy_txbyteclkhs       ),
                .aclken         (1'b1                   )
            );
    
    //
    logic   [9:0]   fifo_data_count;
    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (9                  ),
                .RAM_TYPE       ("block"            ),
                .LOW_DEALY      (0                  ),
                .DOUT_REGS      (1                  ),
                .S_REGS         (1                  ),
                .M_REGS         (1                  )
            )
        u_axi4s_fifo
            (
                .s_axi4s        (axi4s_csi_raw10    ),
                .m_axi4s        (axi4s_csi_fifo     ),
                .s_free_count   (),
                .m_data_count   (fifo_data_count    )
            );

    assign axi4s_csi_fifo.tready = 1;
    
    /*
    // dphy
    jelly3_axi4s_if
            #(
                .USE_LAST   (1                      ),
                .USE_USER   (1                      ),
                .DATA_BITS  (2*10                   ),
                .USER_BITS  (1                      ),
                .DEBUG      ("true"                 )
            )
        axi4s_csi_dphy
            (
                .aresetn    (~dphy_txbyteclkhs_reset),
                .aclk       (dphy_txbyteclkhs       ),
                .aclken     (1'b1                   )
            );
  
    generate_csi_packet
        u_generate_csi_packet
            (
                .frame_start    (1'b0   ),
                .frame_end      (1'b0   ),
                .data_type      (8'h2b  ),
                .wc             (640*5/4),

                .s_axi4s_video  (axi4s_csi_fifo    ),
                .m_axi4s_mipi   (axi4s_csi_dphy    )
            );
    
    assign axi4s_csi_dphy.tready = 1'b1;
    */

    /*
    jelly3_axi4s_if
            #(
                .USE_LAST   (1                      ),
                .USE_USER   (1                      ),
                .DATA_BITS  (2*10                   ),
                .USER_BITS  (1                      ),
                .DEBUG      ("true"                 )
            )
        axi4s_dphy_video
            (
                .aresetn    (~dphy_txbyteclkhs_reset),
                .aclk       (dphy_txbyteclkhs       ),
                .aclken     (1'b1                   )
            );
    
    logic   [9:0]   fifo_data_count;
    jelly3_axi4s_fifo
            #(
                .ASYNC          (1                  ),
                .PTR_BITS       (9                  ),
                .RAM_TYPE       ("block"            ),
                .LOW_DEALY      (0                  ),
                .DOUT_REGS      (1                  ),
                .S_REGS         (1                  ),
                .M_REGS         (1                  )
            )
        u_axi4s_fifo
            (
                .s_axi4s        (axi4s_python_2lane ),
                .m_axi4s        (axi4s_dphy_video   ),
                .s_free_count   (),
                .m_data_count   (fifo_data_count    )
            );
        
//  assign axi4s_dphy_video.tready = 1'b1;
    */

    /*
    jelly3_axi4s_if
            #(
                .USE_LAST   (1                      ),
                .USE_USER   (1                      ),
                .DATA_BITS  (2*10                   ),
                .USER_BITS  (1                      ),
                .DEBUG      ("true"                 )
            )
        axi4s_dphy_csi
            (
                .aresetn    (~dphy_txbyteclkhs_reset),
                .aclk       (dphy_txbyteclkhs       ),
                .aclken     (1'b1                   )
            );
    
    video_to_mipi
        u_video_to_mipi
            (
                .frame_start    (),
                .frame_end      (),
                .data_type      (),
                .wc             (),

                .s_axi4s_video  (axi4s_dphy_video   ),
                .m_axi4s_mipi   ()
            );
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
    assign led[0] = sensor_pwr_enable;
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
    */

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

endmodule

`default_nettype wire

// end of file
