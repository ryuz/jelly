
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   axi4_aresetn    ,
            input   var logic   axi4_aclk       ,
            input   var logic   bram_reset      ,
            input   var logic   bram_clk        
        );

    // -------------------------
    //  DUT
    // -------------------------

    localparam  int     AXI4_ID_BITS        = 8      ;
    localparam  int     AXI4_ADDR_BITS      = 32     ;
    localparam  int     AXI4_DATA_BITS      = 32     ;

    localparam  int     BRAM_ID_BITS        = 8      ;
    localparam  int     BRAM_ADDR_BITS      = 30     ;
    localparam  int     BRAM_DATA_BITS      = 32     ;

    localparam   bit     ASYNC          = 1                 ;
    localparam   int     CFIFO_PTR_BITS = ASYNC ? 5 : 0     ;
    localparam           CFIFO_RAM_TYPE = "distributed"     ;
    localparam   int     RFIFO_PTR_BITS = ASYNC ? 5 : 0     ;
    localparam           RFIFO_RAM_TYPE = "distributed"     ;
    localparam           DEVICE         = "RTL"             ;
    localparam           SIMULATION     = "false"           ;
    localparam           DEBUG          = "false"           ;

    jelly3_axi4_if
            #(
                .ID_BITS        (AXI4_ID_BITS       ),
                .ADDR_BITS      (AXI4_ADDR_BITS     ),
                .DATA_BITS      (AXI4_DATA_BITS     )
            )
        axi4
            (
                .aresetn        (axi4_aresetn       ),
                .aclk           (axi4_aclk          ),
                .aclken         (1'b1               )
            );
    
    jelly3_bram_if
            #(
                .USE_ID         (1                  ),
                .USE_STRB       (1                  ),
                .USE_LAST       (1                  ),
                .ID_BITS        (BRAM_ID_BITS       ),
                .ADDR_BITS      (BRAM_ADDR_BITS     ),
                .DATA_BITS      (BRAM_DATA_BITS     )
            )
        bram
            (
                .reset          (bram_reset         ),
                .clk            (bram_clk           ),
                .cke            (1'b1               )
            );


    jelly3_axi4_to_bram_bridge
            #(
                .ASYNC          (ASYNC              ),
                .CFIFO_PTR_BITS (CFIFO_PTR_BITS     ),
                .CFIFO_RAM_TYPE (CFIFO_RAM_TYPE     ),
                .RFIFO_PTR_BITS (RFIFO_PTR_BITS     ),
                .RFIFO_RAM_TYPE (RFIFO_RAM_TYPE     ),
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_axi4_to_bram_bridge
            (
                .s_axi4         (axi4.s             ),
                .m_bram         (bram.m             )
            );

    assign bram.rid    = bram.cid   ;
    assign bram.rlast  = bram.clast ;
    assign bram.rdata  = bram.caddr ;
    assign bram.rvalid = bram.cread ;
    assign bram.cready = bram.rready;


    // -------------------------
    //  Model
    // -------------------------

    jelly3_axi4_accessor
            #(
                .RAND_RATE_AW   (0              ),
                .RAND_RATE_W    (0              ),
                .RAND_RATE_B    (0              ),
                .RAND_RATE_AR   (0              ),
                .RAND_RATE_R    (0              )
            )
        u_axi4_accessor
            (
                .m_axi4         (axi4.m         )
            );

    initial begin
        automatic logic [axi4.DATA_BITS-1:0] rdata [];

        #1000;
        u_axi4_accessor.write(
                '0,     // id     
                '0,     // addr   
                4'h2,   // size   
                2'b01,  // burst  
                '0,     // lock   
                '0,     // cache  
                '0,     // prot   
                '0,     // qos    
                '0,     // region 
                '0,     // user   
                '{32'h07060504, 32'h03020100}, // data []
                '{4'hf, 4'hf}                 // strb []
            );

        u_axi4_accessor.read(
                '0,     // id     
                '0,     // addr   
                8'd3,   // len    
                4'h2,   // size   
                2'b01,  // burst  
                '0,     // lock   
                '0,     // cache  
                '0,     // prot   
                '0,     // qos    
                '0,     // region 
                '0,     // user   
                rdata   // data []
            );

    end

endmodule


`default_nettype wire


// end of file
