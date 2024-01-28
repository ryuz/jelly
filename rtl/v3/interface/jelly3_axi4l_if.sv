// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


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
    logic                       awvalid = 1'b0;
    logic                       awready;

    logic   [STRB_BITS-1:0]     wstrb;
    logic   [DATA_BITS-1:0]     wdata;
    logic                       wvalid = 1'b0;
    logic                       wready;

    logic   [RESP_BITS-1:0]     bresp;
    logic                       bvalid;
    logic                       bready = 1'b0;
   
    logic   [ADDR_BITS-1:0]     araddr;
    logic   [PROT_BITS-1:0]     arprot;
    logic                       arvalid = 1'b0;
    logic                       arready;

    logic   [DATA_BITS-1:0]     rdata;
    logic   [RESP_BITS-1:0]     rresp;
    logic                       rvalid;
    logic                       rready = 1'b0;

    modport m
        (
            input   addr_base,
            input   addr_high,
        
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
            input   addr_base,
            input   addr_high,

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

    
    task write(
                input   logic   [ADDR_BITS-1:0]     addr,
                input   logic   [DATA_BITS-1:0]     data,
                input   logic   [STRB_BITS-1:0]     strb
            );
        logic fetch_awready;
        logic fetch_wready;
        $display("[axi4l write] addr:%x <= data:%x strb:%x", addr, data, strb);
        @(posedge aclk);
        #0.01;
        awaddr  = addr;
        awprot  = '0;
        awvalid = 1'b1;
        wstrb   = strb;
        wdata   = data;
        wvalid  = 1'b1;
        bready  = 1'b0;

        @(posedge aclk);
        while ( awvalid || wvalid ) begin
            fetch_awready = awready;
            fetch_wready  = wready;   
            #0.01;
            if ( fetch_awready ) begin
                awaddr  = 'x;
                awprot  = 'x;
                awvalid = 1'b0;
            end
            if ( fetch_wready ) begin
                wstrb   = 'x;
                wdata   = 'x;
                wvalid  = 1'b0;
            end
            @(posedge aclk);
        end

        #0.01;
        bready = 1'b1;
        @(posedge aclk);
        while ( !bvalid ) begin
            @(posedge aclk);
        end
        #0.01;
        bready = 1'b0;
    endtask

    task read(
                input   logic   [ADDR_BITS-1:0]     addr,
                output  logic   [DATA_BITS-1:0]     data
            );
        @(posedge aclk);
        #0.01;
        araddr  = addr;
        arprot  = '0;
        arvalid = 1'b1;
        rready  = 1'b0;
        @(posedge aclk);
        while ( !arready ) begin
            @(posedge aclk);
        end

        #0.01;
        araddr  = 'x;
        arprot  = 'x;
        arvalid = 1'b0;
        rready  = 1'b1;
        @(posedge aclk);
        while ( !rvalid ) begin
            @(posedge aclk);
        end
        data = rdata;
        $display("[axi4l read] addr:%x => data:%x", addr, data);
        #0.01;
        rready = 1'b0;
    endtask

endinterface


`default_nettype wire


// end of file
