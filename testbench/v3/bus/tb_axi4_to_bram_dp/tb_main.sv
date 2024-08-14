
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset   ,
            input   var logic   clk     
        );

    // -------------------------
    //  DUT
    // -------------------------

    localparam  int     AXI4_ID_BITS        = 8      ;
    localparam  int     AXI4_ADDR_BITS      = 12     ;
    localparam  int     AXI4_DATA_BITS      = 32     ;

    localparam  int     BRAM_ID_BITS        = 8                 ;
    localparam  int     BRAM_ADDR_BITS      = 10                ;
    localparam  int     BRAM_DATA_BITS      = 32                ;
    localparam  int     BRAM_STRB_BITS      = BRAM_DATA_BITS / 8;

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
                .aresetn        (~reset             ),
                .aclk           (clk                ),
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
        bram_w
            (
                .reset          (reset              ),
                .clk            (clk                ),
                .cke            (1'b1               )
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
        bram_r
            (
                .reset          (reset              ),
                .clk            (clk                ),
                .cke            (1'b1               )
            );


    jelly3_axi4_to_bram_dp
            #(
                .DEVICE         (DEVICE             ),
                .SIMULATION     (SIMULATION         ),
                .DEBUG          (DEBUG              )
            )
        u_axi4_to_bram_dp
            (
                .s_axi4         (axi4.s             ),
                .m_bram_w       (bram_w.m           ),
                .m_bram_r       (bram_r.m           )
            );


    logic   [BRAM_STRB_BITS-1:0]    wr_en       ;
    logic   [BRAM_ADDR_BITS-1:0]    wr_addr     ;
    logic   [BRAM_DATA_BITS-1:0]    wr_din      ;
    logic   [BRAM_ADDR_BITS-1:0]    rd_addr     ;
    logic   [BRAM_DATA_BITS-1:0]    rd_dout     ;
    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH     (BRAM_ADDR_BITS     ),
                .DATA_WIDTH     (BRAM_DATA_BITS     ),
                .WE_WIDTH       (BRAM_DATA_BITS/8   ),
                .RAM_TYPE       ("block"            ),
                .DOUT_REGS      (1                  )
            )
        u_ram_simple_dualport
            (
                .wr_clk         (bram_w.clk         ),
                .wr_en          ,
                .wr_addr        ,
                .wr_din         ,

                .rd_clk         (bram_r.clk         ),
                .rd_en          (bram_r.cke         ),
                .rd_regcke      (bram_r.cke         ),
                .rd_addr        ,
                .rd_dout        
            );

    jelly3_bram_writer
            #(
                .LATENCY        (1              ),
                .ADDR_BITS      (BRAM_ADDR_BITS ), 
                .DATA_BITS      (BRAM_DATA_BITS ) 
            )
        u_bram_writer
            (
                .bram           (bram_w.sw      ),

                .en             (               ),
                .we             (wr_en          ),
                .addr           (wr_addr        ),
                .wdata          (wr_din         )
            );

    jelly3_bram_reader
            #(
                .LATENCY        (2              ),
                .ADDR_BITS      (BRAM_ADDR_BITS ), 
                .DATA_BITS      (BRAM_DATA_BITS ) 
            )
        u_bram_reader
            (
                .bram           (bram_r.sr      ),

                .en             (               ),
                .addr           (rd_addr        ),
                .rdata          (rd_dout        )
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
                '{
                    32'h03020100,
                    32'h07ff0504,
                    32'h0b0aff08,
                    32'h0f0e0d0c
                },  // data []
                '{4'hf, 4'hf, 4'hf, 4'hf}  // strb []
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
        assert (rdatas[0] == 32'h03020100) else $error("ERROR: rdatas[0] = %h", rdatas[0]);
        assert (rdatas[1] == 32'h07ff0504) else $error("ERROR: rdatas[1] = %h", rdatas[1]);
        assert (rdatas[2] == 32'h0b0aff08) else $error("ERROR: rdatas[2] = %h", rdatas[2]);
        assert (rdatas[3] == 32'h0f0e0d0c) else $error("ERROR: rdatas[3] = %h", rdatas[3]);

        u_axi4_accessor.write(
                '0,     // id     
                4,      // addr   
                3'h2,   // size   
                2'b01,  // burst  
                '0,     // lock   
                '0,     // cache  
                '0,     // prot   
                '0,     // qos    
                '0,     // region 
                '0,     // user   
                '{
                    32'hff06ffff,
                    32'hffff09ff
                },  // data []
                '{
                    4'h4,
                    4'h2
                }  // strb []
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
        assert (rdatas[0] == 32'h03020100) else $error("ERROR: rdatas[0] = %h", rdatas[0]);
        assert (rdatas[1] == 32'h07060504) else $error("ERROR: rdatas[1] = %h", rdatas[1]);
        assert (rdatas[2] == 32'h0b0a0908) else $error("ERROR: rdatas[2] = %h", rdatas[2]);
        assert (rdatas[3] == 32'h0f0e0d0c) else $error("ERROR: rdatas[3] = %h", rdatas[3]);

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

        u_axi4_accessor.read_reg (0, 1, data);
        assert (data == 32'h07060504) else $error("ERROR: data = %h", data);

        u_axi4_accessor.write_reg(0, 8, 32'h55aa55aa, 4'hf);
        u_axi4_accessor.read_reg (0, 8, data);
        assert (data == 32'h55aa55aa) else $error("ERROR: data = %h", data);
    end

endmodule


`default_nettype wire


// end of file
