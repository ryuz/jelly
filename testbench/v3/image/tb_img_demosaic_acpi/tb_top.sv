
`timescale 1ns / 1ps
`default_nettype none


module tb_top();
    
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        
        #1000000;
            $finish;
    end
    
    localparam RATE = 1000.0/200.0;

    logic   clk = 1'b1;
    always #(RATE/2.0)  clk = ~clk;
    
    logic   reset = 1'b1;
    initial #(RATE*100) reset = 1'b0;


    parameter   int     AXI4L_ADDR_BITS  = 32   ;
    parameter   int     AXI4L_DATA_BITS  = 32   ;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (AXI4L_ADDR_BITS),
                .DATA_BITS  (AXI4L_DATA_BITS)
            )
        axi4l
            (
                .aresetn    (~reset ),
                .aclk       (clk    ),
                .aclken     (1'b1   )
            );

    tb_main
        u_tb_main
            (
                .reset              ,
                .clk                ,

                .s_axi4l_aresetn    (axi4l.aresetn),
                .s_axi4l_aclk       (axi4l.aclk   ),
                .s_axi4l_awaddr     (axi4l.awaddr ),
                .s_axi4l_awprot     (axi4l.awprot ),
                .s_axi4l_awvalid    (axi4l.awvalid),
                .s_axi4l_awready    (axi4l.awready),
                .s_axi4l_wstrb      (axi4l.wstrb  ),
                .s_axi4l_wdata      (axi4l.wdata  ),
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
        u_axi4l_accessor
            (
                .m_axi4l    (axi4l.m)
            );


endmodule


`default_nettype wire


// end of file
