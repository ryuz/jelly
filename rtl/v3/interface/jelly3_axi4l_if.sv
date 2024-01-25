


`timescale 1ns / 1ps
`default_nettype none


interface jelly3_axi4l_if
    #(
        parameter   int     ADDR_WIDTH = 32,
        parameter   int     DATA_WIDTH = 32,
        parameter   int     STRB_WIDTH = DATA_WIDTH / 8,
        parameter   int     PROT_WIDTH = 3,
        parameter   int     RESP_WIDTH = 2
    )
    (
        input   var logic   aresetn,
        input   var logic   aclk
    );

    logic   [ADDR_WIDTH-1:0]    awaddr;
    logic   [PROT_WIDTH-1:0]    awprot;
    logic                       awvalid;
    logic                       awready;

    logic   [STRB_WIDTH-1:0]    wstrb;
    logic   [DATA_WIDTH-1:0]    wdata;
    logic                       wvalid;
    logic                       wready;

    logic   [RESP_WIDTH-1:0]    bresp;
    logic                       bvalid;
    logic                       bready;
   
    logic   [ADDR_WIDTH-1:0]    araddr;
    logic   [PROT_WIDTH-1:0]    arprot;
    logic                       arvalid;
    logic                       arready;

    logic   [DATA_WIDTH-1:0]    rdata;
    logic   [RESP_WIDTH-1:0]    rresp;
    logic                       rvalid;
    logic                       rready;

    modport m
        (
            input   aresetn,
            input   aclk,
    
            output  awaddr,
            output  awprot,
            output  awvalid,
            input   awready,
        
            output  wstrb,
            output  wdata,
            output  wvalid,
            input   wready,
        
            input   bresp,
            input   bvalid,
            output  bready,
        
            output  araddr,
            output  arprot,
            output  arvalid,
            input   arready,
        
            input   rdata,
            input   rresp,
            input   rvalid,
            output  rready
        );

    modport s
        (
            input   aresetn,
            input   aclk,
    
            input   awaddr,
            input   awprot,
            input   awvalid,
            output  awready,
        
            input   wstrb,
            input   wdata,
            input   wvalid,
            output  wready,
        
            output  bresp,
            output  bvalid,
            input   bready,
            
            output  araddr,
            output  arprot,
            output  arvalid,
            input   arready,
        
            input   rdata,
            input   rresp,
            input   rvalid,
            output  rready
        );

endinterface


`default_nettype wire


// end of file
