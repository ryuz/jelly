
`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic           s_axi4l_aresetn ,
            input   var logic           s_axi4l_aclk    ,
            input   var logic   [39:0]  s_axi4l_awaddr  ,
            input   var logic   [2:0]   s_axi4l_awprot  ,
            input   var logic           s_axi4l_awvalid ,
            output  var logic           s_axi4l_awready ,
            input   var logic   [127:0] s_axi4l_wdata   ,
            input   var logic   [15:0]  s_axi4l_wstrb   ,
            input   var logic           s_axi4l_wvalid  ,
            output  var logic           s_axi4l_wready  ,
            output  var logic   [1:0]   s_axi4l_bresp   ,
            output  var logic           s_axi4l_bvalid  ,
            input   var logic           s_axi4l_bready  ,
            input   var logic   [39:0]  s_axi4l_araddr  ,
            input   var logic   [2:0]   s_axi4l_arprot  ,
            input   var logic           s_axi4l_arvalid ,
            output  var logic           s_axi4l_arready ,
            output  var logic   [127:0] s_axi4l_rdata   ,
            output  var logic   [1:0]   s_axi4l_rresp   ,
            output  var logic           s_axi4l_rvalid  ,
            input   var logic           s_axi4l_rready  
        );
    

    // ---------------------------------
    //  DUT
    // ---------------------------------

    logic   [0:0]   led     ;
    kv260_blinking_led_ps
        u_top
            (
                .led        (led    )
            );
    
    // force の仕様の異なる verilator の為に always_comb を用いる
    always_comb force u_top.u_design1.aresetn  = s_axi4l_aresetn ;
    always_comb force u_top.u_design1.aclk     = s_axi4l_aclk    ;
    always_comb force u_top.u_design1.awaddr   = s_axi4l_awaddr  ;
    always_comb force u_top.u_design1.awprot   = s_axi4l_awprot  ;
    always_comb force u_top.u_design1.awvalid  = s_axi4l_awvalid ;
    always_comb force u_top.u_design1.wdata    = s_axi4l_wdata   ;
    always_comb force u_top.u_design1.wstrb    = s_axi4l_wstrb   ;
    always_comb force u_top.u_design1.wvalid   = s_axi4l_wvalid  ;
    always_comb force u_top.u_design1.bready   = s_axi4l_bready  ;
    always_comb force u_top.u_design1.araddr   = s_axi4l_araddr  ;
    always_comb force u_top.u_design1.arprot   = s_axi4l_arprot  ;
    always_comb force u_top.u_design1.arvalid  = s_axi4l_arvalid ;
    always_comb force u_top.u_design1.rready   = s_axi4l_rready  ;

    assign s_axi4l_awready = u_top.u_design1.awready;
    assign s_axi4l_wready  = u_top.u_design1.wready ;
    assign s_axi4l_bresp   = u_top.u_design1.bresp  ;
    assign s_axi4l_bvalid  = u_top.u_design1.bvalid ;
    assign s_axi4l_arready = u_top.u_design1.arready;
    assign s_axi4l_rdata   = u_top.u_design1.rdata  ;
    assign s_axi4l_rresp   = u_top.u_design1.rresp  ;
    assign s_axi4l_rvalid  = u_top.u_design1.rvalid ;


endmodule


`default_nettype wire
