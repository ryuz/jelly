



`timescale 1ns / 1ps
`default_nettype none

module kv260_register
            (
                output  var logic   [7:0]   pmod,
                output  var logic           fan_en
            );
    

    logic   [0:0]       axi4l_aresetn;
    logic               axi4l_aclk;

    logic   [39:0]      axi4l_awaddr;
    logic   [2:0]       axi4l_awprot;
    logic               axi4l_awvalid;
    logic               axi4l_awready;

    logic   [31:0]      axi4l_wdata;
    logic   [3:0]       axi4l_wstrb;
    logic               axi4l_wvalid;
    logic               axi4l_wready;

    logic   [1:0]       axi4l_bresp;
    logic               axi4l_bvalid;
    logic               axi4l_bready;

    logic   [39:0]      axi4l_araddr;
    logic   [2:0]       axi4l_arprot;
    logic               axi4l_arvalid;
    logic               axi4l_arready;

    logic   [31:0]      axi4l_rdata;
    logic   [1:0]       axi4l_rresp;
    logic               axi4l_rvalid;
    logic               axi4l_rready;

    design_1
        i_design_1
            (
                .m_axi4l_aresetn    (axi4l_aresetn  ),
                .m_axi4l_aclk       (axi4l_aclk     ),
                .m_axi4l_awaddr     (axi4l_awaddr   ),
                .m_axi4l_awprot     (axi4l_awprot   ),
                .m_axi4l_awvalid    (axi4l_awvalid  ),
                .m_axi4l_awready    (axi4l_awready  ),
                .m_axi4l_wdata      (axi4l_wdata    ),
                .m_axi4l_wstrb      (axi4l_wstrb    ),
                .m_axi4l_wvalid     (axi4l_wvalid   ),
                .m_axi4l_wready     (axi4l_wready   ),
                .m_axi4l_bresp      (axi4l_bresp    ),
                .m_axi4l_bvalid     (axi4l_bvalid   ),
                .m_axi4l_bready     (axi4l_bready   ),
                .m_axi4l_araddr     (axi4l_araddr   ),
                .m_axi4l_arprot     (axi4l_arprot   ),
                .m_axi4l_arvalid    (axi4l_arvalid  ),
                .m_axi4l_arready    (axi4l_arready  ),
                .m_axi4l_rdata      (axi4l_rdata    ),
                .m_axi4l_rresp      (axi4l_rresp    ),
                .m_axi4l_rvalid     (axi4l_rvalid   ),
                .m_axi4l_rready     (axi4l_rready   ),

                .fan_en             (fan_en         )
            );


    jelly3_axi4l_if
            #(
                .ADDR_BITS     (40),
                .DATA_BITS     (32)
            )
        i_axi4l_if
            (
                .aresetn        (axi4l_aresetn),
                .aclk           (axi4l_aclk)
            );


    assign i_axi4l_if.awaddr    = axi4l_awaddr      ;
    assign i_axi4l_if.awprot    = axi4l_awprot      ;
    assign i_axi4l_if.awvalid   = axi4l_awvalid     ;
    assign axi4l_awready        = i_axi4l_if.awready;

    assign i_axi4l_if.wdata     = axi4l_wdata       ;
    assign i_axi4l_if.wstrb     = axi4l_wstrb       ;
    assign i_axi4l_if.wvalid    = axi4l_wvalid      ;
    assign axi4l_wready         = i_axi4l_if.wready ;
    
    assign axi4l_bresp          = i_axi4l_if.bresp  ;
    assign axi4l_bvalid         = i_axi4l_if.bvalid ;
    assign i_axi4l_if.bready    = axi4l_bready      ;
    
    assign i_axi4l_if.araddr    = axi4l_araddr      ;
    assign i_axi4l_if.arprot    = axi4l_arprot      ;
    assign i_axi4l_if.arvalid   = axi4l_arvalid     ;
    assign axi4l_arready        = i_axi4l_if.arready;

    assign axi4l_rdata          = i_axi4l_if.rdata  ;
    assign axi4l_rresp          = i_axi4l_if.rresp  ;
    assign axi4l_rvalid         = i_axi4l_if.rvalid ;
    assign i_axi4l_if.rready    = axi4l_rready      ;

    logic   [3:0][31:0]  value;
            
    jelly3_axi4l_register
            #(
                .NUM        (4),
                .WIDTH      (32)
            )
        u_axi4l_register
            (
                .s_axi4l    (i_axi4l_if),
                .value      (value)
            );

    assign pmod[7:0] = value[0][7:0];

endmodule


`default_nettype wire


// end of file

