
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
    

    assign sensor_pwr_en_vdd18 = 1'b0;
    assign sensor_pwr_en_vdd33 = 1'b0;
    assign sensor_pwr_en_pix   = 1'b0;
    assign python_reset_n      = 1'b0;
    assign python_clk_pll      = 1'b0;
    assign python_ss_n         = 1'b0;
    assign python_mosi         = 1'b0;
    assign python_sck          = 1'b0;

    logic           python_clk  ;
    logic   [3:0]   python_data ;
    logic           python_sync ;
    IBUFDS
        u_ibufds_python_clk
            (
                .I      (python_clk_p)       ,
                .IB     (python_clk_n)       ,
                .O      (python_clk)     
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

    assign led[0] = clk50_counter[24];
//  assign led[1] = clk72_counter[24];
    assign led[1] = sensor_pgood;

    assign pmod[7:0] = clk50_counter[15:8];

endmodule

`default_nettype wire

// end of file
