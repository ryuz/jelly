
`timescale 1ns / 1ps
`default_nettype none

module rtcl_p3s7_spi
        (
            input   var logic           clk50                   ,
            input   var logic           clk72                   ,
            output  var logic   [1:0]   led                     ,
            output  var logic   [7:0]   pmod                    ,



            output  var logic           sensor_pwr_en_vdd18     ,
            output  var logic           sensor_pwr_en_vdd33     ,
            output  var logic           sensor_pwr_en_pix       ,
            input   var logic           sensor_pgood            ,

//          output  var logic           mipi_clk_lp_p           ,
//          output  var logic           mipi_clk_lp_n           ,
//          output  var logic           mipi_clk_hp_p           ,
//          output  var logic           mipi_clk_hp_n           ,
//          output  var logic   [1:0]   mipi_data_lp_p          ,
//          output  var logic   [1:0]   mipi_data_lp_n          ,
//          output  var logic   [1:0]   mipi_data_hp_p          ,
//          output  var logic   [1:0]   mipi_data_hp_n          ,
            input   var logic           mipi_reset_n            ,
//          input   var logic           mipi_clk                ,
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
    assign mipi_sda_t = 1'b1;

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
    assign enable = timer_enable & mipi_enable;


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


//    assign sensor_pwr_en_vdd18 = 1'b0;
//    assign sensor_pwr_en_vdd33 = 1'b0;
//    assign sensor_pwr_en_pix   = 1'b0;
//    assign python_reset_n      = 1'b0;
//    assign python_clk_pll      = 1'b0;
//    assign python_ss_n         = 1'b0;
//    assign python_mosi         = 1'b0;
//    assign python_sck          = 1'b0;

    logic           python_clk  ;
    logic   [3:0]   python_data ;
    logic           python_sync ;
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

    IBUFDS
        u_ibufds_python_sync
            (
                .I      (python_sync_p)       ,
                .IB     (python_sync_n)       ,
                .O      (python_sync)     
            );


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
    assign led[1] = python_clk_counter[24];//sensor_pgood;

    assign pmod[7:0] = clk50_counter[15:8];


    // --------------------------------
    //  Debug
    // --------------------------------

    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_reset_n;
    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_scl;
    (* MARK_DEBUG = "true" *)   logic   dbg_mipi_sda;
    always_ff @(posedge clk72) begin
        dbg_mipi_reset_n <= mipi_reset_n ;
        dbg_mipi_scl     <= mipi_scl_i ;
        dbg_mipi_sda     <= mipi_sda_i ;
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

endmodule

`default_nettype wire

// end of file
