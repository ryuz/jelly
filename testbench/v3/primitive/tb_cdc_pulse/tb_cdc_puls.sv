
`timescale 1ns / 1ps
`default_nettype none


module tb_cdc_puls();
   
    initial begin
        $dumpfile("tb_cdc_puls.vcd");
        $dumpvars(0, tb_cdc_puls);
        
        #1000000;
            $finish;
    end


    // -------------------------
    //  DUT
    // -------------------------

    parameter   DEST_SYNC_FF   = 4          ;
    parameter   INIT_SYNC_FF   = 0          ;
    parameter   REG_OUTPUT     = 0          ;
    parameter   RST_USED       = 1          ;
    parameter   SIM_ASSERT_CHK = 0          ;
//    parameter   DEVICE         = "RTL"      ;
    parameter   DEVICE                = "ULTRASCALE_PLUS"   ;
    parameter   SIMULATION     = "false"    ;
    parameter   DEBUG          = "false"    ;

    logic   dest_pulse      ;
    logic   dest_clk        = 1'b1;
    logic   dest_rst        ;
    logic   src_clk         = 1'b1;
    logic   src_pulse       ;
    logic   src_rst         ;

    jelly3_cdc_pulse
            #(
                .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                .INIT_SYNC_FF   (INIT_SYNC_FF   ),
                .REG_OUTPUT     (REG_OUTPUT     ),
                .RST_USED       (RST_USED       ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_cdc_pulse
            (
                .dest_pulse     ,
                .dest_clk       ,
                .dest_rst       ,
                .src_clk        ,
                .src_pulse      ,
                .src_rst        
            );

    logic dest_pulse_rtl;
    jelly3_cdc_pulse
            #(
                .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                .INIT_SYNC_FF   (INIT_SYNC_FF   ),
                .REG_OUTPUT     (REG_OUTPUT     ),
                .RST_USED       (RST_USED       ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                .DEVICE         ("RTL"          ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_cdc_pulse_rtl
            (
                .dest_pulse     (dest_pulse_rtl ),
                .dest_clk       ,
                .dest_rst       ,
                .src_clk        ,
                .src_pulse      ,
                .src_rst        
            );


    // -------------------------
    //  Simulation
    // -------------------------

    localparam RATE0  = 1000.0/200.0;
    localparam RATE1  = 1000.0/123.0;
//  localparam RATE1  = 1000.0/345.0;

    initial forever #(RATE0/2.0)  src_clk  = ~src_clk;
    initial forever #(RATE1/2.0)  dest_clk = ~dest_clk;

    initial begin
        dest_rst = 1'b1;
        src_rst  = 1'b1;
        src_pulse = 1'b0;
        #100;
        dest_rst = 1'b0;
        src_rst  = 1'b0;
        #100;
        @(posedge src_clk); #0;
        src_pulse = 1'b1;
        @(posedge src_clk); #0;
        src_pulse = 1'b0;
        @(posedge src_clk); #0;

        for ( int i = 0; i < 1000; i++ ) begin
            src_pulse = 1'($random);
            @(posedge src_clk); #0;
        end

        for ( int i = 0; i < 1000; i++ ) begin
            src_pulse = 1'b1;
            @(posedge src_clk); #0;
            src_pulse = 1'b0;
            @(posedge src_clk); #0;
        end

        #1000;
        $finish;
    end

endmodule


`default_nettype wire


// end of file
