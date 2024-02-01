// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   int     AXI4L_ADDR_BITS = 40,
            parameter   int     AXI4L_DATA_BITS = 32,
            parameter   int     AXI4L_STRB_BITS = AXI4L_DATA_BITS/8,
            parameter   int     AXI4L_PROT_BITS = 3,
            parameter   int     AXI4L_RESP_BITS = 2
        )
        (
            input   var logic                           aresetn         ,
            input   var logic                           aclk            ,
            input   var logic   [AXI4L_ADDR_BITS-1:0]   s_axi4l_awaddr  ,
            input   var logic   [AXI4L_PROT_BITS-1:0]   s_axi4l_awprot  ,
            input   var logic                           s_axi4l_awvalid ,
            output  var logic                           s_axi4l_awready ,
            input   var logic   [AXI4L_DATA_BITS-1:0]   s_axi4l_wdata   ,
            input   var logic   [AXI4L_STRB_BITS-1:0]   s_axi4l_wstrb   ,
            input   var logic                           s_axi4l_wvalid  ,
            output  var logic                           s_axi4l_wready  ,
            output  var logic   [AXI4L_RESP_BITS-1:0]   s_axi4l_bresp   ,
            output  var logic                           s_axi4l_bvalid  ,
            input   var logic                           s_axi4l_bready  ,
            input   var logic   [AXI4L_ADDR_BITS-1:0]   s_axi4l_araddr  ,
            input   var logic   [AXI4L_PROT_BITS-1:0]   s_axi4l_arprot  ,
            input   var logic                           s_axi4l_arvalid ,
            output  var logic                           s_axi4l_arready ,
            output  var logic   [AXI4L_DATA_BITS-1:0]   s_axi4l_rdata   ,
            output  var logic   [AXI4L_RESP_BITS-1:0]   s_axi4l_rresp   ,
            output  var logic                           s_axi4l_rvalid  ,
            input   var logic                           s_axi4l_rready  
        );
    
    int     sym_cycle = 0;
    always_ff @(posedge aclk) begin
        sym_cycle <= sym_cycle + 1;
    end

    
    // -----------------------------------------
    //  top
    // -----------------------------------------
    
    kv260_register
        i_top
            (
                .pmod           (),
                .fan_en         ()
            );


    always_comb force i_top.i_design_1.m_axi4l_aresetn = aresetn;
    always_comb force i_top.i_design_1.m_axi4l_aclk    = aclk   ;
    always_comb force i_top.i_design_1.m_axi4l_awaddr  = s_axi4l_awaddr ;
    always_comb force i_top.i_design_1.m_axi4l_awprot  = s_axi4l_awprot ;
    always_comb force i_top.i_design_1.m_axi4l_awvalid = s_axi4l_awvalid;
    always_comb force i_top.i_design_1.m_axi4l_wstrb   = s_axi4l_wstrb  ;
    always_comb force i_top.i_design_1.m_axi4l_wdata   = s_axi4l_wdata  ;
    always_comb force i_top.i_design_1.m_axi4l_wvalid  = s_axi4l_wvalid ;
    always_comb force i_top.i_design_1.m_axi4l_bready  = s_axi4l_bready ;
    always_comb force i_top.i_design_1.m_axi4l_araddr  = s_axi4l_araddr ;
    always_comb force i_top.i_design_1.m_axi4l_arprot  = s_axi4l_arprot ;
    always_comb force i_top.i_design_1.m_axi4l_arvalid = s_axi4l_arvalid;
    always_comb force i_top.i_design_1.m_axi4l_rready  = s_axi4l_rready ;

    assign s_axi4l_awready = i_top.i_design_1.m_axi4l_awready ;
    assign s_axi4l_wready  = i_top.i_design_1.m_axi4l_wready  ;
    assign s_axi4l_bresp   = i_top.i_design_1.m_axi4l_bresp   ;
    assign s_axi4l_bvalid  = i_top.i_design_1.m_axi4l_bvalid  ;
    assign s_axi4l_arready = i_top.i_design_1.m_axi4l_arready ;
    assign s_axi4l_rdata   = i_top.i_design_1.m_axi4l_rdata   ;
    assign s_axi4l_rresp   = i_top.i_design_1.m_axi4l_rresp   ;
    assign s_axi4l_rvalid  = i_top.i_design_1.m_axi4l_rvalid  ;
    

endmodule


`default_nettype wire


// end of file
