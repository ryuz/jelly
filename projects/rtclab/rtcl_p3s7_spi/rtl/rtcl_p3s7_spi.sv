
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

    // 時限タイマ
    logic [31:0] timer_counter;
    logic        enable       ;
    always_ff @(posedge clk72) begin
        if ( reset ) begin
            timer_counter <= '0;
            enable        <= 1'b0;
        end
        else begin
            if ( timer_counter != '1 ) begin
                timer_counter <= timer_counter + 1;
            end
            enable <= timer_counter < 72_000_000 * 10;
        end
    end


    // Sensor Power Management
    logic ready;
    sensor_pwr_mng
        u_sensor_pwr_mng
            (
                .reset                   (reset                 ),
                .clk72                   (clk72                 ),
                
                .enable                  (enable                ),
                .ready                   (ready                 ),

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

                .s_addr         (9'b000000000   ),
                .s_we           ('0             ),
                .s_wdata        (16'h0000       ),
                .s_valid        (ready          ),
                .s_ready        (               ),
                .m_rdata        (               ),
                .m_rvalid       (               ),

                .spi_ss_n       (python_ss_n    ),
                .spi_sck        (python_sck     ),
                .spi_mosi       (python_mosi    ),
                .spi_miso       (python_miso    )
            );

    (* MARK_DEBUG = "true" *)   logic   spi_ss_n  ;
    (* MARK_DEBUG = "true" *)   logic   spi_sck   ;
    (* MARK_DEBUG = "true" *)   logic   spi_mosi  ;
    (* MARK_DEBUG = "true" *)   logic   spi_miso  ;
    always_ff @(posedge clk72) begin
        spi_ss_n <= python_ss_n ;
        spi_sck  <= python_sck  ;
        spi_mosi <= python_mosi ;
        spi_miso <= python_miso ;
    end




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

//  assign led[0] = clk50_counter[24];
//  assign led[1] = clk72_counter[24];
    assign led[0] = enable;
    assign led[1] = sensor_pgood;

    assign pmod[7:0] = clk50_counter[15:8];

endmodule

`default_nettype wire

// end of file
