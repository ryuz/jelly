
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    localparam RATE = 2.0;
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
    #100000
        $finish();
    end

    logic   reset = 1'b1;
    always #(RATE*100)  reset = 1'b0;

    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    

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
                .aclk               (clk        ),
                .aclken             (1'b1       )
            );

    tb_main
        u_tb_main
            (
                .reset              ,
                .clk                ,

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
                .s_axi4l_rready     (axi4l.rready )
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

    logic   [31:0]    mem   [0:1023];
    
    logic   [39:0]  base_mem = 40'ha010_0000;

    initial begin
        $display("start");
        #1000;

        $readmemh("../../mem.hex", mem);
        for (int i=0; i < 400; i++) begin
            u_axi4l_accessor.write_reg(base_mem, i, mem[i], 4'hf);
        end

        #100;
        // リセット解除
        u_axi4l_accessor.write_reg(0, 4, 1, 4'hf);
    end


endmodule


`default_nettype wire


// end of file
