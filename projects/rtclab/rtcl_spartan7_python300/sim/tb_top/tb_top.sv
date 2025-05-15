
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

    rtcl_p3s7_dphy
        u_top
            (
                .in_clk50               (clk50      ),
                .in_clk72               (clk72      ),
                .led                    (           ),
                .pmod                   (           ),
                .sensor_pwr_en_vdd18    (           ),
                .sensor_pwr_en_vdd33    (           ),
                .sensor_pwr_en_pix      (           ),
                .sensor_pgood           (           ),
                .mipi_clk_lp_p          (           ),
                .mipi_clk_lp_n          (           ),
                .mipi_clk_hs_p          (           ),
                .mipi_clk_hs_n          (           ),
                .mipi_data_lp_p         (           ),
                .mipi_data_lp_n         (           ),
                .mipi_data_hs_p         (           ),
                .mipi_data_hs_n         (           ),
                .mipi_reset_n           (           ),
                .mipi_clk               (           ),
                .mipi_scl               (           ),
                .mipi_sda               (           ),
                .python_reset_n         (           ),
                .python_clk_pll         (           ),
                .python_ss_n            (           ),
                .python_mosi            (           ),
                .python_miso            (           ),
                .python_sck             (           ),
                .python_trigger         (           ),
                .python_monitor         (           ),
                .python_clk_p           (           ),
                .python_clk_n           (           ),
                .python_data_p          (           ),
                .python_data_n          (           ),
                .python_sync_p          (           ),
                .python_sync_n          (           )
        );
    
endmodule


`default_nettype wire

