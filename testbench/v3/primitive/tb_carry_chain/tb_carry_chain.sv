
`timescale 1ns / 1ps
`default_nettype none


module tb_carry_chain();
    localparam RATE    = 1000.0/200.0;
    
    initial begin
        $dumpfile("tb_carry_chain.vcd");
        $dumpvars(0, tb_carry_chain);
        
        #10000;
            $finish;
    end
    
    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    logic   reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;
    

    localparam  int     DATA_BITS  = 13                      ;
    localparam  type    data_t     = logic [DATA_BITS-1:0]   ;
    localparam          DEVICE     = "RTL"                   ;
    localparam          SIMULATION = "true"                  ;
    localparam          DEBUG      = "false"                 ;
    
    logic   cke = 1'b1  ;

    logic   cin         ;
    data_t  sin         ;
    data_t  din         ;

    data_t  dout        ;
    data_t  cout        ;

    jelly3_carry_chain
            #(
                .DATA_BITS      (DATA_BITS          ),
                .data_t         (data_t             ),
                .DEVICE         ("ULTRASCALE_PLUS"  ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_carry_chain
            (
                .cin            ,
                .sin            ,
                .din            ,
                .dout           ,
                .cout           
            );

    data_t  rtl_dout        ;
    data_t  rtl_cout        ;

    jelly3_carry_chain
            #(
                .DATA_BITS      (DATA_BITS  ),
                .data_t         (data_t     ),
                .DEVICE         ("RTL"      ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_carry_chain_rtl
            (
                .cin            ,
                .sin            ,
                .din            ,
                .dout           (rtl_dout   ),
                .cout           (rtl_cout   )
            );

    always_ff @(posedge clk) begin
        cin <= 1'($urandom_range(0, 1));
        sin <= data_t'($urandom_range(0, 2**DATA_BITS-1));
        din <= data_t'($urandom_range(0, 2**DATA_BITS-1));
    end

    always_ff @(posedge clk) begin
        if ( !reset ) begin
            assert (rtl_dout == dout) else $error("dout mismatch");
            assert (rtl_cout == cout) else $error("dout mismatch");
        end
    end

endmodule


`default_nettype wire


// end of file
