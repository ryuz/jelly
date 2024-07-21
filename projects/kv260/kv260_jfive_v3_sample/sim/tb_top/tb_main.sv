
`timescale 1ns / 1ps
`default_nettype none


module tb_main
    import jelly3_jfive32_pkg::*;
        #(
            parameter   DEVICE            = "ULTRASCALE_PLUS"   ,
            parameter   SIMULATION        = "false"             ,
            parameter   DEBUG             = "false"             
        )
        (
            input   var logic               reset               ,
            input   var logic               clk                 ,
            input   var logic               aclk                ,

            input   var logic   [39:0]      s_axi4l_awaddr      ,
            input   var logic   [2:0]       s_axi4l_awprot      ,
            input   var logic               s_axi4l_awvalid     ,
            output  var logic               s_axi4l_awready     ,
            input   var logic   [31:0]      s_axi4l_wdata       ,
            input   var logic   [3:0]       s_axi4l_wstrb       ,
            input   var logic               s_axi4l_wvalid      ,
            output  var logic               s_axi4l_wready      ,
            output  var logic   [1:0]       s_axi4l_bresp       ,
            output  var logic               s_axi4l_bvalid      ,
            input   var logic               s_axi4l_bready      ,
            input   var logic   [39:0]      s_axi4l_araddr      ,
            input   var logic   [2:0]       s_axi4l_arprot      ,
            input   var logic               s_axi4l_arvalid     ,
            output  var logic               s_axi4l_arready     ,
            output  var logic   [31:0]      s_axi4l_rdata       ,
            output  var logic   [1:0]       s_axi4l_rresp       ,
            output  var logic               s_axi4l_rvalid      ,
            input   var logic               s_axi4l_rready      ,

            input   var logic   [15:0]      s_axi4_awid         ,
            input   var logic   [39:0]      s_axi4_awaddr       ,
            input   var logic   [1:0]       s_axi4_awburst      ,
            input   var logic   [3:0]       s_axi4_awcache      ,
            input   var logic   [7:0]       s_axi4_awlen        ,
            input   var logic   [0:0]       s_axi4_awlock       ,
            input   var logic   [2:0]       s_axi4_awprot       ,
            input   var logic   [3:0]       s_axi4_awqos        ,
            input   var logic   [3:0]       s_axi4_awregion     ,
            input   var logic   [2:0]       s_axi4_awsize       ,
            input   var logic   [15:0]      s_axi4_awuser       ,
            input   var logic   [0:0]       s_axi4_awvalid      ,
            output  var logic   [0:0]       s_axi4_awready      ,
            input   var logic   [0:0]       s_axi4_wlast        ,
            input   var logic   [31:0]      s_axi4_wdata        ,
            input   var logic   [3:0]       s_axi4_wstrb        ,
            input   var logic   [0:0]       s_axi4_wvalid       ,
            output  var logic   [0:0]       s_axi4_wready       ,
            output  var logic   [15:0]      s_axi4_bid          ,
            output  var logic   [1:0]       s_axi4_bresp        ,
            output  var logic   [0:0]       s_axi4_bvalid       ,
            input   var logic   [0:0]       s_axi4_bready       ,
            input   var logic   [39:0]      s_axi4_araddr       ,
            input   var logic   [1:0]       s_axi4_arburst      ,
            input   var logic   [3:0]       s_axi4_arcache      ,
            input   var logic   [15:0]      s_axi4_arid         ,
            input   var logic   [7:0]       s_axi4_arlen        ,
            input   var logic   [0:0]       s_axi4_arlock       ,
            input   var logic   [2:0]       s_axi4_arprot       ,
            input   var logic   [3:0]       s_axi4_arqos        ,
            input   var logic   [3:0]       s_axi4_arregion     ,
            input   var logic   [2:0]       s_axi4_arsize       ,
            input   var logic   [15:0]      s_axi4_aruser       ,
            input   var logic   [0:0]       s_axi4_arvalid      ,
            output  var logic   [0:0]       s_axi4_arready      ,
            output  var logic   [15:0]      s_axi4_rid          ,
            output  var logic   [31:0]      s_axi4_rdata        ,
            output  var logic   [0:0]       s_axi4_rlast        ,
            output  var logic   [1:0]       s_axi4_rresp        ,
            output  var logic   [0:0]       s_axi4_rvalid       ,
            input   var logic   [0:0]       s_axi4_rready       
        );

    logic           fan_en  ;
    logic   [7:0]   pmod    ;
    
    kv260_jfive_v3_sample
            #(
                .DEVICE         (DEVICE     ),
                .SIMULATION     (SIMULATION ),
                .DEBUG          (DEBUG      )
            )
        u_top
            (
                .fan_en         ,
                .pmod           
            );
    
    always_comb force u_top.u_design_1.reset = reset;
    always_comb force u_top.u_design_1.clk   = clk;
    always_comb force u_top.u_design_1.aclk  = aclk;

    always_comb force u_top.u_design_1.axi4l_awaddr  =  s_axi4l_awaddr  ;
    always_comb force u_top.u_design_1.axi4l_awprot  =  s_axi4l_awprot  ;
    always_comb force u_top.u_design_1.axi4l_awvalid =  s_axi4l_awvalid ;
    always_comb force u_top.u_design_1.axi4l_wdata   =  s_axi4l_wdata   ;
    always_comb force u_top.u_design_1.axi4l_wstrb   =  s_axi4l_wstrb   ;
    always_comb force u_top.u_design_1.axi4l_wvalid  =  s_axi4l_wvalid  ;
    always_comb force u_top.u_design_1.axi4l_bready  =  s_axi4l_bready  ;
    always_comb force u_top.u_design_1.axi4l_araddr  =  s_axi4l_araddr  ;
    always_comb force u_top.u_design_1.axi4l_arprot  =  s_axi4l_arprot  ;
    always_comb force u_top.u_design_1.axi4l_arvalid =  s_axi4l_arvalid ;
    always_comb force u_top.u_design_1.axi4l_rready  =  s_axi4l_rready  ;

    assign s_axi4l_awready =  u_top.u_design_1.axi4l_awready;
    assign s_axi4l_wready  =  u_top.u_design_1.axi4l_wready ;
    assign s_axi4l_bresp   =  u_top.u_design_1.axi4l_bresp  ;
    assign s_axi4l_bvalid  =  u_top.u_design_1.axi4l_bvalid ;
    assign s_axi4l_arready =  u_top.u_design_1.axi4l_arready;
    assign s_axi4l_rdata   =  u_top.u_design_1.axi4l_rdata  ;
    assign s_axi4l_rresp   =  u_top.u_design_1.axi4l_rresp  ;
    assign s_axi4l_rvalid  =  u_top.u_design_1.axi4l_rvalid ;


    always_comb force u_top.u_design_1.axi4_awid     = s_axi4_awid     ;
    always_comb force u_top.u_design_1.axi4_awaddr   = s_axi4_awaddr   ;
    always_comb force u_top.u_design_1.axi4_awburst  = s_axi4_awburst  ;
    always_comb force u_top.u_design_1.axi4_awcache  = s_axi4_awcache  ;
    always_comb force u_top.u_design_1.axi4_awlen    = s_axi4_awlen    ;
    always_comb force u_top.u_design_1.axi4_awlock   = s_axi4_awlock   ;
    always_comb force u_top.u_design_1.axi4_awprot   = s_axi4_awprot   ;
    always_comb force u_top.u_design_1.axi4_awqos    = s_axi4_awqos    ;
    always_comb force u_top.u_design_1.axi4_awregion = s_axi4_awregion ;
    always_comb force u_top.u_design_1.axi4_awsize   = s_axi4_awsize   ;
    always_comb force u_top.u_design_1.axi4_awuser   = s_axi4_awuser   ;
    always_comb force u_top.u_design_1.axi4_awvalid  = s_axi4_awvalid  ;
    always_comb force u_top.u_design_1.axi4_wlast    = s_axi4_wlast    ;
    always_comb force u_top.u_design_1.axi4_wdata    = s_axi4_wdata    ;
    always_comb force u_top.u_design_1.axi4_wstrb    = s_axi4_wstrb    ;
    always_comb force u_top.u_design_1.axi4_wvalid   = s_axi4_wvalid   ;
    always_comb force u_top.u_design_1.axi4_bready   = s_axi4_bready   ;
    always_comb force u_top.u_design_1.axi4_araddr   = s_axi4_araddr   ;
    always_comb force u_top.u_design_1.axi4_arburst  = s_axi4_arburst  ;
    always_comb force u_top.u_design_1.axi4_arcache  = s_axi4_arcache  ;
    always_comb force u_top.u_design_1.axi4_arid     = s_axi4_arid     ;
    always_comb force u_top.u_design_1.axi4_arlen    = s_axi4_arlen    ;
    always_comb force u_top.u_design_1.axi4_arlock   = s_axi4_arlock   ;
    always_comb force u_top.u_design_1.axi4_arprot   = s_axi4_arprot   ;
    always_comb force u_top.u_design_1.axi4_arqos    = s_axi4_arqos    ;
    always_comb force u_top.u_design_1.axi4_arregion = s_axi4_arregion ;
    always_comb force u_top.u_design_1.axi4_arsize   = s_axi4_arsize   ;
    always_comb force u_top.u_design_1.axi4_aruser   = s_axi4_aruser   ;
    always_comb force u_top.u_design_1.axi4_arvalid  = s_axi4_arvalid  ;
    always_comb force u_top.u_design_1.axi4_rready   = s_axi4_rready   ;

    assign s_axi4_awready    = u_top.u_design_1.axi4_awready;
    assign s_axi4_wready     = u_top.u_design_1.axi4_wready ;
    assign s_axi4_bid        = u_top.u_design_1.axi4_bid    ;
    assign s_axi4_bresp      = u_top.u_design_1.axi4_bresp  ;
    assign s_axi4_bvalid     = u_top.u_design_1.axi4_bvalid ;
    assign s_axi4_arready    = u_top.u_design_1.axi4_arready;
    assign s_axi4_rid        = u_top.u_design_1.axi4_rid    ;
    assign s_axi4_rdata      = u_top.u_design_1.axi4_rdata  ;
    assign s_axi4_rlast      = u_top.u_design_1.axi4_rlast  ;
    assign s_axi4_rresp      = u_top.u_design_1.axi4_rresp  ;
    assign s_axi4_rvalid     = u_top.u_design_1.axi4_rvalid ;

endmodule


`default_nettype wire


// end of file
