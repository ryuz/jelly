
`timescale 1ns / 1ps
`default_nettype none


module tb_cdc_gray();
   
    initial begin
        $dumpfile("tb_cdc_gray.vcd");
        $dumpvars(0, tb_cdc_gray);
        
        #1000000;
            $finish;
    end


    // -------------------------
    //  DUT
    // -------------------------

    parameter   DEST_SYNC_FF          = 4                   ;
    parameter   SIM_ASSERT_CHK        = 0                   ;
    parameter   SIM_LOSSLESS_GRAY_CHK = 0                   ;
    parameter   WIDTH                 = 8                   ;
//  parameter   DEVICE                = "RTL"               ;
    parameter   DEVICE                = "ULTRASCALE_PLUS"   ;
    parameter   SIMULATION            = "false"             ;
    parameter   DEBUG                 = "false"             ;

    logic               src_clk         = 1'b1  ;
    logic   [WIDTH-1:0] src_in_bin              ;
    logic               dest_clk        = 1'b1  ;
    logic   [WIDTH-1:0] dest_out_bin            ;

    jelly3_cdc_gray
            #(
                .DEST_SYNC_FF           (DEST_SYNC_FF           ),
                .SIM_ASSERT_CHK         (SIM_ASSERT_CHK         ),
                .SIM_LOSSLESS_GRAY_CHK  (SIM_LOSSLESS_GRAY_CHK  ),
                .WIDTH                  (WIDTH                  ),
                .DEVICE                 (DEVICE                 ),
                .SIMULATION             (SIMULATION             ),
                .DEBUG                  (DEBUG                  )
            )
        u_cdc_gray
            (
                .src_clk                ,
                .src_in_bin             ,
                .dest_clk               ,
                .dest_out_bin           
            );

    logic   [WIDTH-1:0] dest_out_bin_rtl         ;
    jelly3_cdc_gray
            #(
                .DEST_SYNC_FF           (DEST_SYNC_FF           ),
                .SIM_ASSERT_CHK         (SIM_ASSERT_CHK         ),
                .SIM_LOSSLESS_GRAY_CHK  (SIM_LOSSLESS_GRAY_CHK  ),
                .WIDTH                  (WIDTH                  ),
                .DEVICE                 ("RTL"                  ),
                .SIMULATION             (SIMULATION             ),
                .DEBUG                  (DEBUG                  )
            )
        u_cdc_gray_rtl
            (
                .src_clk                ,
                .src_in_bin             ,
                .dest_clk               ,
                .dest_out_bin           (dest_out_bin_rtl       )
            );

    // -------------------------
    //  Simulation
    // -------------------------

    localparam RATE0  = 1000.0/200.0;
//  localparam RATE1  = 1000.0/123.0;
    localparam RATE1  = 1000.0/345.0;

    initial forever #(RATE0/2.0)  src_clk  = ~src_clk;
    initial forever #(RATE1/2.0)  dest_clk = ~dest_clk;

    initial begin
        src_in_bin = '0;
        #1000;
        for ( int i = 0; i < 1000; i++ ) begin
            @( posedge src_clk ); #0;
            src_in_bin++;
        end
        for ( int i = 0; i < 1000; i++ ) begin
            @( posedge src_clk ); #0;
            src_in_bin--;
        end
        #1000;
        $finish;
    end

endmodule


`default_nettype wire


// end of file
