// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
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
        parameter   int                         RESP_BITS = 2,
        parameter   int                         LIMIT_AW  = 1,
        parameter   int                         LIMIT_W   = 1,
        parameter   int                         LIMIT_AR  = 1
    )
    (
        input   var logic   aresetn,
        input   var logic   aclk
    );

    typedef logic   [ADDR_BITS-1:0]     addr_t;
    typedef logic   [DATA_BITS-1:0]     data_t;
    typedef logic   [STRB_BITS-1:0]     strb_t;
    typedef logic   [PROT_BITS-1:0]     prot_t;
    typedef logic   [RESP_BITS-1:0]     resp_t;


    // attributes
    addr_t      addr_base;
    addr_t      addr_high;

    // signals
    addr_t      awaddr;
    prot_t      awprot;
    logic       awvalid;
    logic       awready;

    data_t      wdata;
    strb_t      wstrb;
    logic       wvalid;
    logic       wready;

    resp_t      bresp;
    logic       bvalid;
    logic       bready;
   
    addr_t      araddr;
    prot_t      arprot;
    logic       arvalid;
    logic       arready;

    data_t      rdata;
    resp_t      rresp;
    logic       rvalid;
    logic       rready;
    
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



// awaddr
property prop_awaddr_valid  ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awaddr); endproperty
property prop_awaddr_stable ; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awaddr); endproperty
ASSERT_AWADDR_VALID  : assert property(prop_awaddr_valid);
ASSERT_AWADDR_STABLE : assert property(prop_awaddr_stable);

// awprot
property prop_awprot_valid  ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awprot ); endproperty
property prop_awprot_stable ; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awprot); endproperty
ASSERT_AWPROT_VALID  : assert property(prop_awprot_valid);
ASSERT_AWPROT_STABLE : assert property(prop_awprot_stable);

// awvalid
property prop_awvalid_stable ; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awvalid ); endproperty
ASSERT_AWVALID_STABLE : assert property(prop_awvalid_stable);


// wdata
property prop_wdata_valid  ; @(posedge aclk) disable iff ( ~aresetn ) wvalid |-> !$isunknown(wdata ); endproperty
property prop_wdata_stable ; @(posedge aclk) disable iff ( ~aresetn ) (wvalid && !wready) |=> $stable(wdata ); endproperty
ASSERT_WDATA_VALID  : assert property(prop_wdata_valid );
ASSERT_WDATA_STABLE : assert property(prop_wdata_stable );

// wstrb
property prop_wstrb_valid  ; @(posedge aclk) disable iff ( ~aresetn ) wvalid |-> !$isunknown(wstrb ); endproperty
property prop_wstrb_stable ; @(posedge aclk) disable iff ( ~aresetn ) (wvalid && !wready) |=> $stable(wstrb ); endproperty
ASSERT_WSTRB_VALID  : assert property(prop_wstrb_valid );
ASSERT_WSTRB_STABLE : assert property(prop_wstrb_stable );

// wvalid
property prop_wvalid_stable ; @(posedge aclk) disable iff ( ~aresetn ) (wvalid && !wready) |=> $stable(wvalid ); endproperty
ASSERT_WVALID_STABLE : assert property(prop_wvalid_stable );


// bresp
property prop_bresp_valid  ; @(posedge aclk) disable iff ( ~aresetn ) bvalid |-> !$isunknown(bresp ); endproperty
property prop_bresp_stable ; @(posedge aclk) disable iff ( ~aresetn ) (bvalid && !bready) |=> $stable(bresp ); endproperty
ASSERT_BRESP_VALID  : assert property(prop_bresp_valid );
ASSERT_BRESP_STABLE : assert property(prop_bresp_stable );

// bvalid
property prop_bvalid_stable ; @(posedge aclk) disable iff ( ~aresetn ) (bvalid && !bready) |=> $stable(bvalid ); endproperty
ASSERT_BVALID_STABLE : assert property(prop_bvalid_stable );


// araddr
property prop_araddr_valid  ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(araddr ); endproperty
property prop_araddr_stable ; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(araddr ); endproperty
ASSERT_ARADDR_VALID  : assert property(prop_araddr_valid );
ASSERT_ARADDR_STABLE : assert property(prop_araddr_stable );

// arprot
property prop_arprot_valid  ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arprot ); endproperty
property prop_arprot_stable ; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arprot ); endproperty
ASSERT_ARPROT_VALID  : assert property(prop_arprot_valid );
ASSERT_ARPROT_STABLE : assert property(prop_arprot_stable );

// arvalid
property prop_arvalid_stable ; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arvalid ); endproperty
ASSERT_ARVALID_STABLE : assert property(prop_arvalid_stable );


// rdata
property prop_rdata_valid  ; @(posedge aclk) disable iff ( ~aresetn ) rvalid |-> !$isunknown(rdata ); endproperty
property prop_rdata_stable ; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rdata ); endproperty
ASSERT_RDATA_VALID  : assert property(prop_rdata_valid );
ASSERT_RDATA_STABLE : assert property(prop_rdata_stable );

// rresp
property prop_rresp_valid  ; @(posedge aclk) disable iff ( ~aresetn ) rvalid |-> !$isunknown(rresp ); endproperty
property prop_rresp_stable ; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rresp ); endproperty
ASSERT_RRESP_VALID  : assert property(prop_rresp_valid );
ASSERT_RRESP_STABLE : assert property(prop_rresp_stable );

// rvalid
property prop_rvalid_stable ; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rvalid ); endproperty
ASSERT_RVALID_STABLE : assert property(prop_rvalid_stable );



// コマンド発行数と応答数が乖離しないこと
`ifdef __SIMULATION__
    int         issue_aw;
    int         issue_w;
    int         issue_b;
    int         issue_ar;
    int         issue_r;
    assign issue_aw    = awvalid && awready ? 1 : 0;
    assign issue_w     = wvalid  && wready  ? 1 : 0;
    assign issue_b     = bvalid  && bready  ? 1 : 0;
    assign issue_ar    = arvalid && arready ? 1 : 0;
    assign issue_r     = rvalid  && rready  ? 1 : 0;
    
    int         count_aw;
    int         count_w;
    int         count_ar;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            count_aw <= 0;
            count_w  <= 0;
            count_ar <= 0;
        end
        else begin
            count_aw <= count_aw + issue_aw - issue_b;
            count_w  <= count_w  + issue_w  - issue_b;
            count_ar <= count_ar + issue_ar - issue_r;

            assert ( count_aw >= 0 && count_w >=0 ) else begin
                $error("ERROR: %m: illegal bvalid issue");
            end
            assert ( count_aw <= LIMIT_AW ) else begin
                $error("ERROR: %m: aw  channel overflow");
            end
            assert ( count_w <= LIMIT_W ) else begin
                $error("ERROR: %m: w channel overflow");
            end
            assert ( count_ar <= LIMIT_AR ) else begin
                $error("ERROR: %m: ar channel overflow");
            end
        end
    end
`endif


endinterface


`default_nettype wire


// end of file
