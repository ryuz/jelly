
`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_hs
        #(
            parameter   int     I2C_DIVIDER = 8                 ,
            parameter           DEBUG       = "true"
        )
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
            output  var logic   [2:0]   python_trigger          ,
            input   var logic   [1:0]   python_monitor          ,
            input   var logic           python_clk_p            ,
            input   var logic           python_clk_n            ,
            input   var logic   [3:0]   python_data_p           ,
            input   var logic   [3:0]   python_data_n           ,
            input   var logic           python_sync_p           ,
            input   var logic           python_sync_n           ,

            input   var logic           mipi_gpio0              ,
            input   var logic           mipi_gpio1              ,
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


    logic in_reset_n;
    assign in_reset_n = mipi_gpio0;

    // リセット同期化
    (* ASYNC_REG = "true" *)
    logic    [1:0]   ff_reset_n = 2'b00;
    logic            reset_n;
    always_ff @(posedge clk72 or negedge in_reset_n) begin
        if ( ~in_reset_n ) begin
            ff_reset_n <= 2'b00;
        end
        else begin
            ff_reset_n[0] <= 1'b1;
            ff_reset_n[1] <= ff_reset_n[0];
        end
    end
    assign reset_n = ff_reset_n[1];

    // リセット期間
    logic           reset = 1'b1;
    logic   [7:0]   reset_counter = '0;
    always_ff @(posedge clk72) begin
        if  ( ~reset_n ) begin
            reset <= 1'b0;
            reset_counter <= '0;
        end
        else begin
            if ( reset_counter == '1 ) begin
                reset <= 1'b0;
            end
            else begin
                reset_counter <= reset_counter + 1;
            end
        end
    end

    // DPHY clock
    logic   dphy_core_reset         ;
    logic   dphy_core_clk           ;
    logic   dphy_system_reset       ;
//  logic   dphy_txhs_reset         ;
    logic   dphy_clk                ;
    logic   dphy_txclkesc           ;
    logic   dphy_oserdes_clkdiv     ;
    logic   dphy_oserdes_clk        ;
    logic   dphy_oserdes_clk90      ;

    mipi_dphy_clk_gen
        u_mipi_dphy_clk_gen
            (
                .reset              (reset                  ),
                .clk50              (clk50                  ),

                .core_reset         (dphy_core_reset        ),
                .core_clk           (dphy_core_clk          ),
                .system_reset       (dphy_system_reset      ),
//              .dphy_reset         (                       ),
                .dphy_clk           (dphy_clk               ),
                .txclkesc           (dphy_txclkesc          ),
                .oserdes_clkdiv     (dphy_oserdes_clkdiv    ),
                .oserdes_clk        (dphy_oserdes_clk       ),
                .oserdes_clk90      (dphy_oserdes_clk90     )
            );


    logic       idelayctrl_rdy;
    (* IODELAY_GROUP = "IODELAY_GRP_LVDS" *)
    IDELAYCTRL
        u_idleyctrl_lvds
            (
                .RDY        (idelayctrl_rdy     ),
                .REFCLK     (dphy_core_clk      ),
                .RST        (dphy_core_reset    )
            );

    
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
                .DIVIDER_WIDTH  (8                  )
            )
        u_i2c_slave_core
            (
                .reset          (reset              ),
                .clk            (clk72              ),

                .i2c_scl        (mipi_scl_i         ),
                .i2c_sda        (mipi_sda_i         ),
                .i2c_sda_t      (mipi_sda_t         ),

                .divider        (8'(I2C_DIVIDER)    ),
                .dev            (7'h10              ),

                .wr_start       (i2c_wr_start       ),
                .wr_en          (i2c_wr_en          ),
                .wr_data        (i2c_wr_data        ),
                .rd_start       (i2c_rd_start       ),
                .rd_req         (i2c_rd_req         ),
                .rd_en          (i2c_rd_en          ),
                .rd_data        (i2c_rd_data        )
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
                .ADDR_BITS      (15             ),
                .DATA_BITS      (16             )
            )
        axi4l
            (
                .aresetn        (~reset         ),
                .aclk           (clk72          ),
                .aclken         (1'b1           )
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


    // controller
                                logic           ctl_sensor_enable   ;
                                logic           ctl_sensor_ready    ;
                                logic           ctl_recv_reset      ;
                                logic           ctl_align_reset     ;
                                logic   [9:0]   ctl_align_pattern   ;
    (* MARK_DEBUG = DEBUG *)    logic           ctl_align_done      ;
    (* MARK_DEBUG = DEBUG *)    logic           ctl_align_error     ;
                                logic           ctl_dphy_core_reset ;
                                logic           ctl_dphy_sys_reset  ;
                                logic           ctl_dphy_init_done  ;

    system_control
            #(
                .CORE_ID                (16'h527a               ),
                .CORE_VERSION           (16'h0100               ),
                .INIT_RECV_RESET        (1'b1                   ),
                .INIT_ALIGN_RESET       (1'b1                   ),
                .INIT_ALIGN_PATTERN     (10'h3a6                ),
                .INIT_CSI_DATA_TYPE     (8'h2b                  ),
                .INIT_CSI_WC            (16'(256*5/4)           ),
                .INIT_DPHY_CORE_RESET   (1'b1                   ),
                .INIT_DPHY_SYS_RESET    (1'b1                   )
            )
        u_system_control
            (
                .s_axi4l                (axi4l                  ),

                .out_sensor_enable      (ctl_sensor_enable      ),
                .in_sensor_ready        (ctl_sensor_ready       ),
                .out_recv_reset         (ctl_recv_reset         ),
                .out_align_reset        (ctl_align_reset        ),
                .out_align_pattern      (ctl_align_pattern      ),
                .in_align_done          (ctl_align_done         ),
                .in_align_error         (ctl_align_error        ),
                .out_dphy_core_reset    (ctl_dphy_core_reset    ),
                .out_dphy_sys_reset     (ctl_dphy_sys_reset     ),
                .in_dphy_init_done      (ctl_dphy_init_done     )
            );
    


    // -------------------------------------
    //  MIPI DPHY
    // -------------------------------------

    localparam  DPHY_DATA_BITS = 8  ;
    localparam  DPHY_LANES     = 2  ;

    // MIPI DPHY
    (* mark_debug = DEBUG *)    logic           dphy_init_done              ;
    (* mark_debug = DEBUG *)    logic           dphy_cl_txclkactivehs       ;
    (* mark_debug = DEBUG *)    logic           dphy_cl_txrequesths         ;
    (* mark_debug = DEBUG *)    logic           dphy_cl_stopstate           ;
    (* mark_debug = DEBUG *)    logic           dphy_cl_enable              ;
                                logic           dphy_cl_txulpsclk           ;
                                logic           dphy_cl_txulpsexit          ;
                                logic           dphy_cl_ulpsactivenot       ;
    (* mark_debug = DEBUG *)    logic   [7:0]   dphy_dl0_txdatahs           ;
    (* mark_debug = DEBUG *)    logic           dphy_dl0_txrequesths        ;
    (* mark_debug = DEBUG *)    logic           dphy_dl0_txreadyhs          ;
                                logic           dphy_dl0_forcetxstopmode    ;
                                logic           dphy_dl0_stopstate          ;
                                logic           dphy_dl0_enable             ;
                                logic           dphy_dl0_txrequestesc       ;
                                logic           dphy_dl0_txlpdtesc          ;
                                logic           dphy_dl0_txulpsexit         ;
                                logic           dphy_dl0_ulpsactivenot      ;
                                logic           dphy_dl0_txulpsesc          ;
                                logic   [3:0]   dphy_dl0_txtriggeresc       ;
                                logic   [7:0]   dphy_dl0_txdataesc          ;
                                logic           dphy_dl0_txvalidesc         ;
                                logic           dphy_dl0_txreadyesc         ;
    (* mark_debug = DEBUG *)    logic   [7:0]   dphy_dl1_txdatahs           ;
    (* mark_debug = DEBUG *)    logic           dphy_dl1_txrequesths        ;
    (* mark_debug = DEBUG *)    logic           dphy_dl1_txreadyhs          ;
                                logic           dphy_dl1_forcetxstopmode    ;
                                logic           dphy_dl1_stopstate          ;
                                logic           dphy_dl1_enable             ;
                                logic           dphy_dl1_txrequestesc       ;
                                logic           dphy_dl1_txlpdtesc          ;
                                logic           dphy_dl1_txulpsexit         ;
                                logic           dphy_dl1_ulpsactivenot      ;
                                logic           dphy_dl1_txulpsesc          ;
                                logic   [3:0]   dphy_dl1_txtriggeresc       ;
                                logic   [7:0]   dphy_dl1_txdataesc          ;
                                logic           dphy_dl1_txvalidesc         ;
                                logic           dphy_dl1_txreadyesc         ;

    mipi_dphy_0
        u_mipi_dphy_0
            (
                .core_clk               (dphy_core_clk              ),   //  input
                .core_rst               (dphy_core_reset   || ctl_dphy_core_reset),   //  input
                .txclkesc_in            (dphy_txclkesc              ),   //  input
                .txbyteclkhs_in         (dphy_clk                   ),   //  input
                .oserdes_clkdiv_in      (dphy_oserdes_clkdiv        ),   //  input
                .oserdes_clk_in         (dphy_oserdes_clk           ),   //  input
                .oserdes_clk90_in       (dphy_oserdes_clk90         ),   //  input
                .system_rst_in          (dphy_system_reset || ctl_dphy_sys_reset ),   //  input

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

    assign ctl_dphy_init_done = dphy_init_done;
    
    logic   dphy_reset;
    jelly3_reset
        u_reset_core
            (
                .clk                (dphy_clk                   ),
                .cke                (1'b1                       ),
                .in_reset           (reset || ~dphy_init_done   ),
                .out_reset          (dphy_reset                 )
            );


    assign dphy_cl_txrequesths      = '1    ;
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


    // -------------------------------------
    //  PYTHON300 Sensor
    // -------------------------------------

    // 4 LVDS RAW10
    localparam  int     CHANNELS = 4            ;
    localparam  type    raw10_t  = logic [9:0]  ;
    localparam  type    sync10_t = logic [9:0]  ;

    // -------------------------------------
    //  MIPI GPIO
    // -------------------------------------

    // pwr enable
    logic sensor_pwr_enable = 1'b0;
    always_ff @(posedge clk72 ) begin
        if ( ~reset_n ) begin
            sensor_pwr_enable <= 1'b0;
        end
        else begin
            sensor_pwr_enable <= ctl_sensor_enable;
        end
    end

    // Sensor Power Management
    logic sensor_ready;
    sensor_pwr_mng
        u_sensor_pwr_mng
            (
                .reset              (reset                 ),
                .clk72              (clk72                 ),
                
                .enable             (sensor_pwr_enable     ),
                .ready              (sensor_ready          ),

                .sensor_pwr_en_vdd18(sensor_pwr_en_vdd18   ),
                .sensor_pwr_en_vdd33(sensor_pwr_en_vdd33   ),
                .sensor_pwr_en_pix  (sensor_pwr_en_pix     ),
                .sensor_pgood       (sensor_pgood          ),
                .python_reset_n     (python_reset_n        ),
                .python_clk_pll     (python_clk_pll        )
            );
    assign ctl_sensor_ready = sensor_ready;

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

    // Trigger
    assign python_trigger[0] = mipi_gpio1   ; // Trigger 0
    assign python_trigger[1] = 1'b0         ; // Trigger 1
    assign python_trigger[2] = 1'b0         ; // Trigger 2

    // Receiver(ISERDES)
                                logic                       python_reset    ;
                                logic                       python_clk      ;
    (* mark_debug = DEBUG *)    raw10_t   [CHANNELS-1:0]    python_rx_data  ;
    (* mark_debug = DEBUG *)    sync10_t                    python_rx_sync  ;
    (* mark_debug = DEBUG *)    logic                       bitslip         ;
    python_receiver_10bit
        u_python_receiver_10bit
            (
                .in_reset       (reset              ),
                .in_clk_p       (python_clk_p       ),
                .in_clk_n       (python_clk_n       ),
                .in_data_p      (python_data_p      ),
                .in_data_n      (python_data_n      ),
                .in_sync_p      (python_sync_p      ),
                .in_sync_n      (python_sync_n      ),
                .sw_reset       (ctl_recv_reset     ),

                .bitslip        (bitslip            ),
                .out_reset      (python_reset       ),
                .out_clk        (python_clk         ),
                .out_data       (python_rx_data     ),
                .out_sync       (python_rx_sync     )
            );

    // Alignment
    (* MARK_DEBUG = DEBUG *)    raw10_t   [CHANNELS-1:0]    python_align_data   ;
    (* MARK_DEBUG = DEBUG *)    sync10_t                    python_align_sync   ;
    (* MARK_DEBUG = DEBUG *)    logic                       python_align_valid  ;
    python_alignment
            #(
                .CHANNELS       (CHANNELS           ),
                .DATA_BITS      ($bits(raw10_t)     ),
                .SLIP_INTERVAL  (15                 )
            )
        u_python_alignment
            (
                .reset          (python_reset       ),
                .clk            (python_clk         ),

                .sw_reset       (ctl_align_reset    ),
                
                .pattern        (ctl_align_pattern  ),
                .align_done     (ctl_align_done     ),
                .align_error    (ctl_align_error    ),
                
                .bitslip        (bitslip            ),

                .s_data         (python_rx_data     ),
                .s_sync         (python_rx_sync     ),
                .s_valid        (1'b1               ),

                .m_data         (python_align_data  ),
                .m_sync         (python_align_sync  ),
                .m_valid        (python_align_valid )
        );


    // to AXI-Stream
    localparam  AXI4S_TDATA_BITS = CHANNELS * $bits(raw10_t);
    localparam  AXI4S_TUSER_BITS = 4;
    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (AXI4S_TDATA_BITS   ),
                .USER_BITS      (AXI4S_TUSER_BITS   ),
                .DEBUG          (DEBUG              )
            )
        axi4s_recv
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
                .m_axi4s        (axi4s_recv         )
            );

    // pixel swap
    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (AXI4S_TDATA_BITS   ),
                .USER_BITS      (AXI4S_TUSER_BITS   ),
                .DEBUG          (DEBUG              )
            )
        axi4s_swap
            (
                .aresetn        (~python_reset      ),
                .aclk           (python_clk         ),
                .aclken         (1'b1               )
            );
    
    pixel_swap
        u_pixel_swap
            (
                .s_axi4s        (axi4s_recv         ),
                .m_axi4s        (axi4s_swap         )
            );

    // pixel clip
    jelly3_axi4s_if
            #(
                .USE_LAST       (1                  ),
                .USE_USER       (1                  ),
                .DATA_BITS      (AXI4S_TDATA_BITS   ),
                .USER_BITS      (AXI4S_TUSER_BITS   ),
                .DEBUG          (DEBUG              )
            )
        axi4s_clip
            (
                .aresetn        (~python_reset      ),
                .aclk           (python_clk         ),
                .aclken         (1'b1               )
            );
    
    pixel_clip
        u_pixel_clip
            (
                .s_axi4s        (axi4s_swap.s        ),
                .m_axi4s        (axi4s_clip.m        )
            );

    // DPHY TX
    logic   [1:0][7:0]  dphy_data   ;
    logic               dphy_request  ;
    logic               dphy_ready  ;
    axi4s_to_dphy
            #(
                .CHANNELS       (CHANNELS           ),
                .RAW_BITS       ($bits(raw10_t)     ),
                .DPHY_LANES     (DPHY_LANES         ),
                .DEBUG          (DEBUG              )
            )
        u_axi4s_to_dphy
            (
                .s_axi4s        (axi4s_clip         ),

                .dphy_reset     (dphy_reset         ),
                .dphy_clk       (dphy_clk           ),
                .dphy_data      (dphy_data          ),
                .dphy_request   (dphy_request       ),
                .dphy_ready     (dphy_ready         )
            );

    assign dphy_dl0_txdatahs    = dphy_data[0];
    assign dphy_dl1_txdatahs    = dphy_data[1];
    assign dphy_dl0_txrequesths = dphy_request;
    assign dphy_dl1_txrequesths = dphy_request;
    assign dphy_ready = dphy_dl1_txreadyhs & dphy_dl0_txreadyhs;


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

    logic   python_frame_toggle;
    always_ff @(posedge python_clk) begin
        if ( python_reset ) begin
            python_frame_toggle <= 1'b0;
        end
        else begin
            if ( python_rx_sync == 10'h22a ) begin
                python_frame_toggle <= ~python_frame_toggle;
            end
        end
    end


  assign led[0] = clk50_counter[24];
  assign led[1] = clk72_counter[24];
//    assign led[0] = sensor_pwr_enable;
//  assign led[1] = mipi_enable;
//  assign led[1] = sensor_pgood;
//    assign led[1] = python_clk_counter[24] & sensor_pwr_enable;

    assign pmod[0] = python_monitor[0]      ;
    assign pmod[1] = python_monitor[1]      ;
    assign pmod[2] = python_trigger[0]      ;
    assign pmod[3] = axi4s_recv.tvalid      ;
    assign pmod[4] = python_frame_toggle    ;
    assign pmod[5] = dphy_dl0_txrequesths   ;
    assign pmod[6] = dphy_dl0_txreadyhs     ;
    assign pmod[7] = '0;


    // --------------------------------
    //  Debug
    // --------------------------------

    (* MARK_DEBUG = "true" *)   logic   [3:0][9:0]  dbg_python_align_data   ;
    (* MARK_DEBUG = "true" *)   logic        [9:0]  dbg_python_align_sync   ;
    (* MARK_DEBUG = "true" *)   logic               dbg_python_align_valid  ;
   jelly2_fifo_async_fwtf
            #(
                .DATA_WIDTH     (4*10+10                    ),
                .PTR_WIDTH      (3                          ),
                .DOUT_REGS      (0                          ),
                .RAM_TYPE       ("distributed"              ),
                .S_REGS         (0                          ),
                .M_REGS         (1                          )
            )
        u_fifo_async_fwtf_dbg
            (
                .s_reset        (python_reset               ),
                .s_clk          (python_clk                 ),
                .s_cke          (1'b1                       ),
                .s_data         ({
                                    python_align_data,
                                    python_align_sync
                                }),
                .s_valid        (python_align_valid         ),
                .s_ready        (                           ),
                .s_free_count   (                           ),
                
                .m_reset        (dphy_reset                 ),
                .m_clk          (dphy_clk                   ),
                .m_cke          (1'b1                       ),
                .m_data         ({
                                    dbg_python_align_data,
                                    dbg_python_align_sync
                                }),
                .m_valid        (dbg_python_align_valid     ),
                .m_ready        (1'b1                       ),
                .m_data_count   (                           )
            );


    (* mark_debug = DEBUG *)    logic           dbg_ctl_dphy_core_reset     ;
    (* mark_debug = DEBUG *)    logic           dbg_ctl_dphy_sys_reset      ;
    (* mark_debug = DEBUG *)    logic           dbg_dphy_init_done          ;
    always_ff @(posedge dphy_clk) begin
        dbg_ctl_dphy_core_reset <= ctl_dphy_core_reset;
        dbg_ctl_dphy_sys_reset  <= ctl_dphy_sys_reset ;
        dbg_dphy_init_done      <= dphy_init_done     ;
    end


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

    /*
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
