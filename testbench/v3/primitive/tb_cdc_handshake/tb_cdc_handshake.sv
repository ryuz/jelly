
`timescale 1ns / 1ps
`default_nettype none


module tb_cdc_handshake();
   
    initial begin
        $dumpfile("tb_cdc_handshake.vcd");
        $dumpvars(0, tb_cdc_handshake);
        
        #1000000;
            $finish;
    end


    // -------------------------
    //  DUT
    // -------------------------

    parameter   DEST_EXT_HSK   = 1              ;
    parameter   DEST_SYNC_FF   = 3              ;
    parameter   SIM_ASSERT_CHK = 0              ;
    parameter   SRC_SYNC_FF    = 4              ;
    parameter   WIDTH          = 8              ;
//    parameter   DEVICE         = "RTL"          ;
    parameter   DEVICE         = "ULTRASCALE_PLUS";
    parameter   SIMULATION     = "false"        ;
    parameter   DEBUG          = "false"        ;

    logic               src_clk     = 1'b1;
    logic   [WIDTH-1:0] src_in      ;
    logic               src_send    ;
    logic               src_rcv     ;
    logic               dest_clk    = 1'b1;
    logic               dest_req    ;
    logic               dest_ack    ;
    logic   [WIDTH-1:0] dest_out    ;

    jelly3_cdc_handshake
            #(
                .DEST_EXT_HSK   (DEST_EXT_HSK   ),
                .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                .SRC_SYNC_FF    (SRC_SYNC_FF    ),
                .WIDTH          (WIDTH          ),
                .DEVICE         (DEVICE         ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_cdc_handshake
            (
                .src_clk        ,
                .src_in         ,
                .src_send       ,
                .src_rcv        ,
                .dest_clk       ,
                .dest_req       ,
                .dest_ack       ,
                .dest_out       
            );

    logic               src_rcv_rtl     ;
    logic               dest_req_rtl    ;
    logic   [WIDTH-1:0] dest_out_rtl    ;
    jelly3_cdc_handshake
            #(
                .DEST_EXT_HSK   (DEST_EXT_HSK   ),
                .DEST_SYNC_FF   (DEST_SYNC_FF   ),
                .SIM_ASSERT_CHK (SIM_ASSERT_CHK ),
                .SRC_SYNC_FF    (SRC_SYNC_FF    ),
                .WIDTH          (WIDTH          ),
                .DEVICE         ("RTL"          ),
                .SIMULATION     (SIMULATION     ),
                .DEBUG          (DEBUG          )
            )
        u_cdc_handshake_rtl
            (
                .src_clk        ,
                .src_in         ,
                .src_send       ,
                .src_rcv        (src_rcv_rtl    ),
                .dest_clk       ,
                .dest_req       (dest_req_rtl   ),
                .dest_ack       ,
                .dest_out       (dest_out_rtl   )
            );


    logic   reset = 1'b1;
    initial #100 reset = 1'b0;
    jelly2_data_async
            #(
                .ASYNC          (1          ),
                .DATA_WIDTH     (WIDTH      )
            )
        u_data_async
            (
                .s_reset        (reset      ),
                .s_clk          (src_clk    ),
                .s_data         (src_in     ),
                .s_valid        (1'b1       ),
                .s_ready        (           ),
                .m_reset        (reset      ),
                .m_clk          (dest_clk   ),
                .m_data         (),
                .m_valid        (),
                .m_ready        (1'b1       )
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
        src_in   = '0;
        src_send = '0;

        #100;
        @(posedge src_clk); #0;

        for ( int i = 0; i < 100; i++ ) begin
            src_in++;
            src_send = 1'b1;
            @(posedge src_clk); #0;
            while (src_rcv == 1'b0) begin
                @(posedge src_clk); #0;
            end
            src_send = 1'b0;
            @(posedge src_clk); #0;
            while (src_rcv == 1'b1) begin
                @(posedge src_clk); #0;
            end
        end

        #1000;
        $finish;
    end

    if ( DEST_EXT_HSK ) begin
        initial begin
            dest_ack = 1'b0;

            #100;
            @(posedge src_clk); #0;

            forever begin
                dest_ack = dest_req;
                @(posedge dest_clk); #0;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
