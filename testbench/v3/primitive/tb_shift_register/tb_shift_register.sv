
`timescale 1ns / 1ps
`default_nettype none


module tb_shift_register();
   
    initial begin
        $dumpfile("tb_shift_register.vcd");
        $dumpvars(0, tb_shift_register);
        
        #1000000;
            $finish;
    end


    // -------------------------
    //  DUT
    // -------------------------

    parameter   int     DEPTH      = 8                      ;
    parameter   int     ADDR_WIDTH = $clog2(DEPTH)          ;
    parameter   type    addr_t     = logic [ADDR_WIDTH-1:0] ;
    parameter   int     DATA_WIDTH = 8                      ;
    parameter   type    data_t     = logic [DATA_WIDTH-1:0] ;
    parameter           DEVICE     = "ULTRASCALE_PLUS"      ;
//  parameter           DEVICE     = "Topaz"                ;
//  parameter           DEVICE     = "RTL"                  ;
    parameter           SIMULATION = "false"                ;
    parameter           DEBUG      = "false"                ;

    logic     clk       ;
    logic     cke       ;

    addr_t    addr      ;
    data_t    in_data   ;
    data_t    out_data  ;

    jelly3_shift_register
            #(
                .DEPTH          (DEPTH      ),
                .ADDR_WIDTH     (ADDR_WIDTH ),
                .addr_t         (addr_t     ),
                .DATA_WIDTH     (DATA_WIDTH ),
                .data_t         (data_t     ),
                .DEVICE         (DEVICE     ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_shift_register
            (
                .clk            ,
                .cke            ,
                .addr           ,
                .in_data        ,
                .out_data       
            );


    data_t    out_data_trl  ;
    jelly3_shift_register
            #(
                .DEPTH          (DEPTH      ),
                .ADDR_WIDTH     (ADDR_WIDTH ),
                .addr_t         (addr_t     ),
                .DATA_WIDTH     (DATA_WIDTH ),
                .data_t         (data_t     ),
                .DEVICE         ("RTL"      ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_shift_register_rtl
            (
                .clk            ,
                .cke            ,
                .addr           ,
                .in_data        ,
                .out_data       (out_data_trl)
            );

    logic  match_ng;
    always_ff @(posedge clk) begin
        match_ng <= (out_data !== out_data_trl);
    end


    // -------------------------
    //  Simulation
    // -------------------------

    localparam RATE  = 1000.0/200.0;

    initial begin
        clk = 1'b1;
        forever #(RATE/2.0)  clk  = ~clk;
    end

    always_ff @(posedge clk) begin
        cke <= 1;//1'($random);
    end

    always_ff @(posedge clk) begin
        if ( cke ) begin
            addr    <= '0;//addr_t'($random);
            in_data <= data_t'($random);
        end
    end


    initial begin
        #10000;
        $finish;
    end

endmodule


`default_nettype wire


// end of file
