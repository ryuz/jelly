
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
            input   var logic               s_axi4l_rready      
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


endmodule


`default_nettype wire


// end of file
