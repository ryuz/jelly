


`timescale 1ns / 1ps
`default_nettype none


interface jelly3_axi4l_if
    #(
        parameter   int                         ADDR_BITS = 32,
        parameter   int                         DATA_BITS = 32,
        parameter   int                         BYTE_BITS = 8,
        parameter   int                         STRB_BITS = DATA_BITS / BYTE_BITS,
        parameter   int                         PROT_BITS = 3,
        parameter   int                         RESP_BITS = 2
    )
    (
        input   var logic   aresetn,
        input   var logic   aclk
    );

    // attributes
    bit     [ADDR_BITS-1:0]     addr_base;
    bit     [ADDR_BITS-1:0]     addr_high;

    // signals
    logic   [ADDR_BITS-1:0]     awaddr;
    logic   [PROT_BITS-1:0]     awprot;
    logic                       awvalid;
    logic                       awready;

    logic   [STRB_BITS-1:0]     wstrb;
    logic   [DATA_BITS-1:0]     wdata;
    logic                       wvalid;
    logic                       wready;

    logic   [RESP_BITS-1:0]     bresp;
    logic                       bvalid;
    logic                       bready;
   
    logic   [ADDR_BITS-1:0]     araddr;
    logic   [PROT_BITS-1:0]     arprot;
    logic                       arvalid;
    logic                       arready;

    logic   [DATA_BITS-1:0]     rdata;
    logic   [RESP_BITS-1:0]     rresp;
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
            
            input   araddr,
            input   arprot,
            input   arvalid,
            output  arready,
        
            output  rdata,
            output  rresp,
            output  rvalid,
            input   rready
        );

endinterface


`default_nettype wire


// end of file
