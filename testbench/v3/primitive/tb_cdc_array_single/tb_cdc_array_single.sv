
`timescale 1ns / 1ps
`default_nettype none


module tb_cdc_array_single();
   
    initial begin
        $dumpfile("tb_cdc_array_single.vcd");
        $dumpvars(0, tb_cdc_array_single);
        
        #1000000;
            $finish;
    end


    // -------------------------
    //  DUT
    // -------------------------

    parameter   DEST_SYNC_FF   = 4          ;
    parameter   SIM_ASSERT_CHK = 0          ;
    parameter   SRC_INPUT_REG  = 1          ;
    parameter   WIDTH          = 4          ;
//    parameter   DEVICE         = "RTL"      ;
    parameter   DEVICE         = "ULTRASCALE_PLUS"   ;
    parameter   SIMULATION     = "false"    ;
    parameter   DEBUG          = "false"    ;

    logic               src_clk     = 1'b1;
    logic   [WIDTH-1:0] src_in      ;
    logic               dest_clk    = 1'b1;
    logic   [WIDTH-1:0] dest_out    ;

    jelly3_cdc_array_single
            #(
                .DEST_SYNC_FF   (DEST_SYNC_FF       ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK     ),
                .SRC_INPUT_REG  (SRC_INPUT_REG      ),
                .WIDTH          (WIDTH              ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_cdc_array_single
            (
                .src_clk        ,
                .src_in         ,
                .dest_clk       ,
                .dest_out       
            );

    logic  dest_out0;
    jelly3_cdc_single
            #(
                .DEST_SYNC_FF   (DEST_SYNC_FF       ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK     ),
                .SRC_INPUT_REG  (SRC_INPUT_REG      ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_cdc_single
            (
                .src_clk        ,
                .src_in         (src_in[0]          ),
                .dest_clk       ,
                .dest_out       (dest_out0          )
            );


    logic   [WIDTH-1:0] dest_out_rtl    ;
    jelly3_cdc_array_single
            #(
                .DEST_SYNC_FF   (DEST_SYNC_FF       ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK     ),
                .SRC_INPUT_REG  (SRC_INPUT_REG      ),
                .WIDTH          (WIDTH              ),
                .DEVICE         ("RTL"              ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_cdc_array_single_rtl
            (
                .src_clk        ,
                .src_in         ,
                .dest_clk       ,
                .dest_out       (dest_out_rtl       )
            );

    logic           dest_out0_rtl    ;
    jelly3_cdc_single
            #(
                .DEST_SYNC_FF   (DEST_SYNC_FF       ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK     ),
                .SRC_INPUT_REG  (SRC_INPUT_REG      ),
                .DEVICE         ("RTL"              ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_cdc_single_rtl
            (
                .src_clk        ,
                .src_in         (src_in[0]          ),
                .dest_clk       ,
                .dest_out       (dest_out0_rtl      )
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
        src_in = 0;
        #100;
        @(posedge src_clk); #0;
        for ( int i = 0; i < 1000; i++ ) begin
            src_in++;
            @(posedge src_clk); #0;
        end
        #100;
        @(posedge src_clk); #0;


        #1000;
        $finish;
    end

endmodule


`default_nettype wire


// end of file
