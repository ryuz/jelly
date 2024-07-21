
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


    localparam  int     MEM_LATENCY = 2;
    logic   [MEM_LATENCY-1:0][AXI4_ID_BITS-1:0]  mem_id     ;
    logic   [MEM_LATENCY-1:0]                    mem_last   ;
    logic   [MEM_LATENCY-1:0]                    mem_valid  ;
    always_ff @ ( posedge bram.clk ) begin
        for (int i = 0; i < MEM_LATENCY; i++ ) begin
            if ( bram.reset ) begin
                mem_id   [i] <= 'x;
                mem_last [i] <= 'x;
                mem_valid[i] <= '0;
            end
            else if ( bram.cready ) begin
                if ( i == 0 ) begin
                    mem_id   [i] <= bram.cid   ;
                    mem_last [i] <= bram.clast ;
                    mem_valid[i] <= bram.cread ;
                end
                else begin
                    mem_id   [i] <= mem_id   [i-1];
                    mem_last [i] <= mem_last [i-1];
                    mem_valid[i] <= mem_valid[i-1];
                end
            end
        end
    end

    assign bram.rid    = mem_id   [MEM_LATENCY-1];
    assign bram.rlast  = mem_last [MEM_LATENCY-1];
    assign bram.rvalid = mem_valid[MEM_LATENCY-1];
    assign bram.cready = !bram.rvalid || bram.rready;

    jelly2_ram_singleport
            #(
                .ADDR_WIDTH     (10             ),
                .DATA_WIDTH     (32             ),
                .WE_WIDTH       (4              ),
                .RAM_TYPE       ("block"        ),
                .DOUT_REGS      (1              ),
                .MODE           ("NO_CHANGE"    ),
                .FILLMEM        (1              ),
                .FILLMEM_DATA   ('0             ),
                .READMEMB       (0              ),
                .READMEMH       (0              ),
                .READMEM_FILE   (""             )
            )
        u_ram_singleport
            (
                .clk            (bram.clk       ),
                .en             (bram.cvalid    ),
                .regcke         (mem_valid[0]   ),
                .we             (bram.cstrb     ),
                .addr           (bram.caddr[9:0]),
                .din            (bram.cdata     ),
                .dout           (bram.rdata     )
            );


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
        automatic logic [axi4.DATA_BITS-1:0] rdatas [];
        automatic logic [axi4.DATA_BITS-1:0] data;

        #1000;
        u_axi4_accessor.write(
                '0,     // id     
                '0,     // addr   
                3'h2,   // size   
                2'b01,  // burst  
                '0,     // lock   
                '0,     // cache  
                '0,     // prot   
                '0,     // qos    
                '0,     // region 
                '0,     // user   
                '{32'h03020100, 32'h07060504},  // data []
                '{4'hf, 4'hf}                   // strb []
            );

        u_axi4_accessor.read(
                '0,     // id     
                '0,     // addr   
                8'd3,   // len    
                3'h2,   // size   
                2'b01,  // burst  
                '0,     // lock   
                '0,     // cache  
                '0,     // prot   
                '0,     // qos    
                '0,     // region 
                '0,     // user   
                rdatas  // data []
            );

        u_axi4_accessor.read(
                '0,     // id     
                4,      // addr   
                8'd3,   // len    
                3'h2,   // size   
                2'b10,  // burst  
                '0,     // lock   
                '0,     // cache  
                '0,     // prot   
                '0,     // qos    
                '0,     // region 
                '0,     // user   
                rdatas  // data []
            );

        u_axi4_accessor.write_reg(0, 8, 32'h55aa55aa, 4'hf);
        u_axi4_accessor.read_reg (0, 8, data);
    end

endmodule


`default_nettype wire


// end of file
