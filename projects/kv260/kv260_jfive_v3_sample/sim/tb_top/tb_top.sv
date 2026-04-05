
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    localparam RATE500 = 2.0;
    localparam RATE333 = 3.0;
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #10000000
        $finish();
    end

    logic   reset = 1'b1;
    always #(RATE500*100)  reset = 1'b0;

    logic   clk = 1'b1;
    always #(RATE500/2.0)  clk = ~clk;
    
    logic   aclk = 1'b1;
    always #(RATE333/2.0)  aclk = ~aclk;

    // -----------------------------
    //  main
    // -----------------------------

    jelly3_axi4l_if
            #(
                .ADDR_BITS          (40          ),
                .DATA_BITS          (32          )
            )
        axi4l
            (
                .aresetn            (~reset     ),
                .aclk               (aclk       ),
                .aclken             (1'b1       )
            );

    jelly3_axi4_if
            #(
                .ID_BITS            (16          ),
                .ADDR_BITS          (40          ),
                .DATA_BITS          (32          )
            )
        axi4
            (
                .aresetn            (~reset     ),
                .aclk               (aclk        ),
                .aclken             (1'b1       )
            );

    tb_main
        u_tb_main
            (
                .reset              ,
                .clk                ,
                .aclk               ,

                .s_axi4l_awaddr     (axi4l.awaddr ),
                .s_axi4l_awprot     (axi4l.awprot ),
                .s_axi4l_awvalid    (axi4l.awvalid),
                .s_axi4l_awready    (axi4l.awready),
                .s_axi4l_wdata      (axi4l.wdata  ),
                .s_axi4l_wstrb      (axi4l.wstrb  ),
                .s_axi4l_wvalid     (axi4l.wvalid ),
                .s_axi4l_wready     (axi4l.wready ),
                .s_axi4l_bresp      (axi4l.bresp  ),
                .s_axi4l_bvalid     (axi4l.bvalid ),
                .s_axi4l_bready     (axi4l.bready ),
                .s_axi4l_araddr     (axi4l.araddr ),
                .s_axi4l_arprot     (axi4l.arprot ),
                .s_axi4l_arvalid    (axi4l.arvalid),
                .s_axi4l_arready    (axi4l.arready),
                .s_axi4l_rdata      (axi4l.rdata  ),
                .s_axi4l_rresp      (axi4l.rresp  ),
                .s_axi4l_rvalid     (axi4l.rvalid ),
                .s_axi4l_rready     (axi4l.rready ),
                
                .s_axi4_awid        (axi4.awid    ),
                .s_axi4_awaddr      (axi4.awaddr  ),
                .s_axi4_awburst     (axi4.awburst ),
                .s_axi4_awcache     (axi4.awcache ),
                .s_axi4_awlen       (axi4.awlen   ),
                .s_axi4_awlock      (axi4.awlock  ),
                .s_axi4_awprot      (axi4.awprot  ),
                .s_axi4_awqos       (axi4.awqos   ),
                .s_axi4_awregion    (axi4.awregion),
                .s_axi4_awsize      (axi4.awsize  ),
                .s_axi4_awuser      (axi4.awuser  ),
                .s_axi4_awvalid     (axi4.awvalid ),
                .s_axi4_awready     (axi4.awready ),
                .s_axi4_wlast       (axi4.wlast   ),
                .s_axi4_wdata       (axi4.wdata   ),
                .s_axi4_wstrb       (axi4.wstrb   ),
                .s_axi4_wvalid      (axi4.wvalid  ),
                .s_axi4_wready      (axi4.wready  ),
                .s_axi4_bid         (axi4.bid     ),
                .s_axi4_bresp       (axi4.bresp   ),
                .s_axi4_bvalid      (axi4.bvalid  ),
                .s_axi4_bready      (axi4.bready  ),
                .s_axi4_araddr      (axi4.araddr  ),
                .s_axi4_arburst     (axi4.arburst ),
                .s_axi4_arcache     (axi4.arcache ),
                .s_axi4_arid        (axi4.arid    ),
                .s_axi4_arlen       (axi4.arlen   ),
                .s_axi4_arlock      (axi4.arlock  ),
                .s_axi4_arprot      (axi4.arprot  ),
                .s_axi4_arqos       (axi4.arqos   ),
                .s_axi4_arregion    (axi4.arregion),
                .s_axi4_arsize      (axi4.arsize  ),
                .s_axi4_aruser      (axi4.aruser  ),
                .s_axi4_arvalid     (axi4.arvalid ),
                .s_axi4_arready     (axi4.arready ),
                .s_axi4_rid         (axi4.rid     ),
                .s_axi4_rdata       (axi4.rdata   ),
                .s_axi4_rlast       (axi4.rlast   ),
                .s_axi4_rresp       (axi4.rresp   ),
                .s_axi4_rvalid      (axi4.rvalid  ),
                .s_axi4_rready      (axi4.rready  )
            );

    jelly3_axi4l_accessor
            #(
                .RAND_RATE_AW   (0      ),
                .RAND_RATE_W    (0      ),
                .RAND_RATE_B    (0      ),
                .RAND_RATE_AR   (0      ),
                .RAND_RATE_R    (0      )
            )
        u_axi4l_accessor
            (
                .m_axi4l        (axi4l  )
            );

    jelly3_axi4_accessor
            #(
                .RAND_RATE_AW   (0      ),
                .RAND_RATE_W    (0      ),
                .RAND_RATE_B    (0      ),
                .RAND_RATE_AR   (0      ),
                .RAND_RATE_R    (0      )
            )
        u_axi4_accessor
            (
                .m_axi4         (axi4   )
            );


    localparam  int MEM_SIZE = 65536 / 4;
    logic   [31:0]    mem   [0:MEM_SIZE-1];
    initial begin
        $readmemh("../../../jfive/jfive_mem.hex", mem);
    end
    
    logic   [39:0]  base_mem = 40'ha010_0000;

    logic   [31:0]  rdata;  
    initial begin
        $display("start");
        #1000;

        for ( int i = 0; i < MEM_SIZE; i++ ) begin
            if ( mem[i] != 0 ) begin
                u_axi4_accessor.write_reg(base_mem, i, mem[i], 4'hf, 16'h12);
            end
        end

        u_axi4_accessor.read_reg(base_mem, 0, rdata);
        u_axi4_accessor.read_reg(base_mem, 1, rdata);
        u_axi4_accessor.read_reg(base_mem, 2, rdata);
        u_axi4_accessor.read_reg(base_mem, 3, rdata);

        #100;
        // リセット解除
        $display("reset release");
        u_axi4l_accessor.write_reg(0, 4, 1, 4'hf);
    end


endmodule


`default_nettype wire


// end of file
