
`timescale 1ns / 1ps
`default_nettype none


module tb_cdc_async_rst();
    
    initial begin
        $dumpfile("tb_cdc_async_rst.vcd");
        $dumpvars(0, tb_cdc_async_rst);
        
        #10000;
            $finish;
    end

    // -------------------------
    //  DUT
    // -------------------------
    
    parameter   DEST_SYNC_FF    = 4         ;
    parameter   RST_ACTIVE_HIGH = 1         ;
//  parameter   DEVICE          = "RTL"     ;
    parameter   DEVICE          = "ULTRASCALE_PLUS";
    parameter   SIMULATION      = "false"   ;
    parameter   DEBUG           = "false"   ;

    logic   src_arst    ;
    logic   dest_clk    ;
    logic   dest_arst   ;

    jelly3_cdc_async_rst
            #(
                .DEST_SYNC_FF       (DEST_SYNC_FF   ),
                .RST_ACTIVE_HIGH    (RST_ACTIVE_HIGH),
                .DEVICE             (DEVICE         ),
                .SIMULATION         (SIMULATION     ),
                .DEBUG              (DEBUG          )
            )
        u_cdc_async_rst
            (
                .src_arst           ,
                .dest_clk           ,
                .dest_arst
              );


    logic   dest_arst_rtl   ;
    jelly3_cdc_async_rst
            #(
                .DEST_SYNC_FF       (DEST_SYNC_FF   ),
                .RST_ACTIVE_HIGH    (RST_ACTIVE_HIGH),
                .DEVICE             ("RTL"          ),
                .SIMULATION         (SIMULATION     ),
                .DEBUG              (DEBUG          )
            )
        u_cdc_async_rst_rtl
            (
                .src_arst           ,
                .dest_clk           ,
                .dest_arst          (dest_arst_rtl  )
              );


    // -------------------------
    //  Simulation
    // -------------------------

    initial begin
        src_arst = RST_ACTIVE_HIGH ? 1'b1 : 1'b0;
        dest_clk = 1'b1;

        for ( int i = 0; i < 10; i++ ) begin
            #10; dest_clk = 1'b0;
            #10; dest_clk = 1'b1;
        end

        #5;  src_arst = RST_ACTIVE_HIGH ? 1'b0 : 1'b1;
        #5;  dest_clk = 1'b0;
        #10; dest_clk = 1'b1;
        for ( int i = 0; i < 10; i++ ) begin
            #10; dest_clk = 1'b0;
            #10; dest_clk = 1'b1;
        end

        #5;  src_arst = RST_ACTIVE_HIGH ? 1'b1 : 1'b0;
        #5;  dest_clk = 1'b0;
        #10; dest_clk = 1'b1;
        for ( int i = 0; i < 10; i++ ) begin
            #10; dest_clk = 1'b0;
            #10; dest_clk = 1'b1;
        end

        #5;  src_arst = RST_ACTIVE_HIGH ? 1'b0 : 1'b1;
        #5;  dest_clk = 1'b0;
        #10; dest_clk = 1'b1;
        for ( int i = 0; i < 10; i++ ) begin
            #10; dest_clk = 1'b0;
            #10; dest_clk = 1'b1;
        end

        $finish;
   end

endmodule


`default_nettype wire


// end of file
