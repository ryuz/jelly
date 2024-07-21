// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


interface jelly3_axi4_if
    #(
        parameter   int     ID_BITS        = 8                              ,
        parameter   int     ADDR_BITS      = 32                             ,
        parameter   int     DATA_BITS      = 32                             ,
        parameter   int     BYTE_BITS      = 8                              ,
        parameter   int     STRB_BITS      = DATA_BITS / BYTE_BITS          ,
        parameter   int     LEN_BITS       = 8                              ,
        parameter   int     SIZE_BITS      = 3                              ,
        parameter   int     BURST_BITS     = 2                              ,
        parameter   int     LOCK_BITS      = 1                              ,
        parameter   int     CACHE_BITS     = 4                              ,
        parameter   int     PROT_BITS      = 3                              ,
        parameter   int     QOS_BITS       = 4                              ,
        parameter   int     REGION_BITS    = 4                              ,
        parameter   int     RESP_BITS      = 2                              ,

        parameter   bit     USE_ID         = 1                              ,
        parameter   bit     USE_SIZE       = 1                              ,
        parameter   bit     USE_BURST      = 1                              ,
        parameter   bit     USE_LOCK       = 1                              ,
        parameter   bit     USE_CACHE      = 1                              ,
        parameter   bit     USE_PROT       = 1                              ,
        parameter   bit     USE_QOS        = 1                              ,
        parameter   bit     USE_REGION     = 1                              ,
        parameter   bit     USE_RESP       = 1                              ,
        parameter   bit     USE_USER       = 0                              ,

        parameter   int     USER_REQ_BITS  = 1                              ,
        parameter   int     USER_DATA_BITS = 1                              ,
        parameter   int     USER_RESP_BITS = 1                              ,
        parameter   int     AWUSER_BITS    = USER_REQ_BITS                  ,
        parameter   int     WUSER_BITS     = USER_DATA_BITS                 ,
        parameter   int     BUSER_BITS     = USER_RESP_BITS                 ,
        parameter   int     ARUSER_BITS    = USER_REQ_BITS                  ,
        parameter   int     RUSER_BITS     = USER_DATA_BITS + USER_RESP_BITS,

        parameter   int     LIMIT_AW      = 255                             ,
        parameter   int     LIMIT_W       = 255                             ,
        parameter   int     LIMIT_WC      = 1023                            ,
        parameter   int     LIMIT_AR      = 255                             ,
        parameter   int     LIMIT_R       = 255                             ,
        parameter   int     LIMIT_RC      = 1023                            ,

        parameter           SIMULATION    = "false"                         ,
        parameter           DEBUG         = "false"                         
    )
    (
        input   var logic   aresetn ,
        input   var logic   aclk    ,
        input   var logic   aclken  
    );

    // typedef
    typedef logic   [ID_BITS    -1:0]   id_t        ;
    typedef logic   [ADDR_BITS  -1:0]   addr_t      ;
    typedef logic   [LEN_BITS   -1:0]   len_t       ;
    typedef logic   [SIZE_BITS  -1:0]   size_t      ;
    typedef logic   [BURST_BITS -1:0]   burst_t     ;
    typedef logic   [LOCK_BITS  -1:0]   lock_t      ;
    typedef logic   [CACHE_BITS -1:0]   cache_t     ;
    typedef logic   [PROT_BITS  -1:0]   prot_t      ;
    typedef logic   [QOS_BITS   -1:0]   qos_t       ;
    typedef logic   [REGION_BITS-1:0]   region_t    ;
    typedef logic   [DATA_BITS  -1:0]   data_t      ;
    typedef logic   [STRB_BITS  -1:0]   strb_t      ;
    typedef logic   [RESP_BITS  -1:0]   resp_t      ;
    typedef logic   [AWUSER_BITS-1:0]   awuser_t    ;
    typedef logic   [WUSER_BITS -1:0]   wuser_t     ;
    typedef logic   [BUSER_BITS -1:0]   buser_t     ;
    typedef logic   [ARUSER_BITS-1:0]   aruser_t    ;
    typedef logic   [RUSER_BITS -1:0]   ruser_t     ;
 

    // attributes
    bit     [ADDR_BITS-1:0]         addr_base   ;
    bit     [ADDR_BITS-1:0]         addr_high   ;

    // signals  
    id_t        awid        ;
    addr_t      awaddr      ;
    len_t       awlen       ;
    size_t      awsize      ;
    burst_t     awburst     ;
    lock_t      awlock      ;
    cache_t     awcache     ;
    prot_t      awprot      ;
    qos_t       awqos       ;
    region_t    awregion    ;
    awuser_t    awuser      ;
    logic       awvalid     ;
    logic       awready     ;

    data_t      wdata       ;
    strb_t      wstrb       ;
    logic       wlast       ;
    wuser_t     wuser       ;
    logic       wvalid      ;
    logic       wready      ;

    id_t        bid         ;
    resp_t      bresp       ;
    buser_t     buser       ;
    logic       bvalid      ;
    logic       bready      ;

    id_t        arid        ;
    addr_t      araddr      ;
    len_t       arlen       ;
    size_t      arsize      ;
    burst_t     arburst     ;
    lock_t      arlock      ;
    cache_t     arcache     ;
    prot_t      arprot      ;
    qos_t       arqos       ;
    region_t    arregion    ;
    aruser_t    aruser      ;
    logic       arvalid     ;
    logic       arready     ;

    id_t        rid         ;
    data_t      rdata       ;
    resp_t      rresp       ;
    logic       rlast       ;
    ruser_t     ruser       ;
    logic       rvalid      ;
    logic       rready      ;

    modport m
        (
            input   addr_base   ,
            input   addr_high   ,

            input   aresetn     ,
            input   aclk        ,
            input   aclken      ,

            output  awid        ,
            output  awaddr      ,
            output  awlen       ,
            output  awsize      ,
            output  awburst     ,
            output  awlock      ,
            output  awcache     ,
            output  awprot      ,
            output  awqos       ,
            output  awregion    ,
            output  awuser      ,
            output  awvalid     ,
            input   awready     ,

            output  wdata       ,
            output  wstrb       ,
            output  wlast       ,
            output  wuser       ,
            output  wvalid      ,
            input   wready      ,

            input   bid         ,
            input   bresp       ,
            input   buser       ,
            input   bvalid      ,
            output  bready      ,

            output  arid        ,
            output  araddr      ,
            output  arlen       ,
            output  arsize      ,
            output  arburst     ,
            output  arlock      ,
            output  arcache     ,
            output  arprot      ,
            output  arqos       ,
            output  arregion    ,
            output  aruser      ,
            output  arvalid     ,
            input   arready     ,

            input   rid         ,
            input   rdata       ,
            input   rresp       ,
            input   rlast       ,
            input   ruser       ,
            input   rvalid      ,
            output  rready      
        );

    modport s
        (
            input   addr_base   ,
            input   addr_high   ,

            input   aresetn     ,
            input   aclk        ,
            input   aclken      ,

            input   awid        ,
            input   awaddr      ,
            input   awlen       ,
            input   awsize      ,
            input   awburst     ,
            input   awlock      ,
            input   awcache     ,
            input   awprot      ,
            input   awqos       ,
            input   awregion    ,
            input   awuser      ,
            input   awvalid     ,
            output  awready     ,

            input   wdata       ,
            input   wstrb       ,
            input   wlast       ,
            input   wuser       ,
            input   wvalid      ,
            output  wready      ,

            output  bid         ,
            output  bresp       ,
            output  buser       ,
            output  bvalid      ,
            input   bready      ,

            input   arid        ,
            input   araddr      ,
            input   arlen       ,
            input   arsize      ,
            input   arburst     ,
            input   arlock      ,
            input   arcache     ,
            input   arprot      ,
            input   arqos       ,
            input   arregion    ,
            input   aruser      ,
            input   arvalid     ,
            output  arready     ,

            output  rid         ,
            output  rdata       ,
            output  rresp       ,
            output  rlast       ,
            output  ruser       ,
            output  rvalid      ,
            input   rready      
        );

    modport mw
        (
            input   addr_base   ,
            input   addr_high   ,

            input   aresetn     ,
            input   aclk        ,

            output  awid        ,
            output  awaddr      ,
            output  awlen       ,
            output  awsize      ,
            output  awburst     ,
            output  awlock      ,
            output  awcache     ,
            output  awprot      ,
            output  awqos       ,
            output  awregion    ,
            output  awuser      ,
            output  awvalid     ,
            input   awready     ,

            output  wdata       ,
            output  wstrb       ,
            output  wlast       ,
            output  wuser       ,
            output  wvalid      ,
            input   wready      ,

            input   bid         ,
            input   bresp       ,
            input   buser       ,
            input   bvalid      ,
            output  bready      
        );
    
    modport mr
        (
            input   addr_base   ,
            input   addr_high   ,

            input   aresetn     ,
            input   aclk        ,

            output  arid        ,
            output  araddr      ,
            output  arlen       ,
            output  arsize      ,
            output  arburst     ,
            output  arlock      ,
            output  arcache     ,
            output  arprot      ,
            output  arqos       ,
            output  arregion    ,
            output  aruser      ,
            output  arvalid     ,
            input   arready     ,

            input   rid         ,
            input   rdata       ,
            input   rresp       ,
            input   rlast       ,
            input   ruser       ,
            input   rvalid      ,
            output  rready      
        );

    modport sw
        (
            input   addr_base   ,
            input   addr_high   ,

            input   aresetn     ,
            input   aclk        ,

            input   awid        ,
            input   awaddr      ,
            input   awlen       ,
            input   awsize      ,
            input   awburst     ,
            input   awlock      ,
            input   awcache     ,
            input   awprot      ,
            input   awqos       ,
            input   awregion    ,
            input   awuser      ,
            input   awvalid     ,
            output  awready     ,

            input   wdata       ,
            input   wstrb       ,
            input   wlast       ,
            input   wuser       ,
            input   wvalid      ,
            output  wready      ,

            output  bid         ,
            output  bresp       ,
            output  buser       ,
            output  bvalid      ,
            input   bready      
        );

    modport sr
        (
            input   addr_base   ,
            input   addr_high   ,

            input   aresetn     ,
            input   aclk        ,

            input   arid        ,
            input   araddr      ,
            input   arlen       ,
            input   arsize      ,
            input   arburst     ,
            input   arlock      ,
            input   arcache     ,
            input   arprot      ,
            input   arqos       ,
            input   arregion    ,
            input   aruser      ,
            input   arvalid     ,
            output  arready     ,

            output  rid         ,
            output  rdata       ,
            output  rresp       ,
            output  rlast       ,
            output  ruser       ,
            output  rvalid      ,
            input   rready      
        );




// awaddr
property prop_awaddr_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awaddr ); endproperty
property prop_awaddr_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awaddr ); endproperty
ASSERT_AWADDR_VALID  : assert property(prop_awaddr_valid );
ASSERT_AWADDR_STABLE : assert property(prop_awaddr_stable );

// araddr
property prop_araddr_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(araddr ); endproperty
property prop_araddr_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(araddr ); endproperty
property prop_araddr_clken ; @(posedge aclk) disable iff ( ~aresetn ) (!aclken            ) |=> $stable(araddr ); endproperty
ASSERT_ARADDR_VALID  : assert property(prop_araddr_valid );
ASSERT_ARADDR_STABLE : assert property(prop_araddr_stable );
ASSERT_ARADDR_CLKEN  : assert property(prop_araddr_clken );


// awlen
property prop_awlen_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awlen ); endproperty
property prop_awlen_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awlen ); endproperty
ASSERT_AWLEN_VALID  : assert property(prop_awlen_valid );
ASSERT_AWLEN_STABLE : assert property(prop_awlen_stable );

// arlen
property prop_arlen_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arlen ); endproperty
property prop_arlen_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arlen ); endproperty
ASSERT_ARLEN_VALID  : assert property(prop_arlen_valid );
ASSERT_ARLEN_STABLE : assert property(prop_arlen_stable );


// wdata
property prop_wdata_valid ; @(posedge aclk) disable iff ( ~aresetn ) wvalid |-> !$isunknown(wdata ); endproperty
property prop_wdata_stable; @(posedge aclk) disable iff ( ~aresetn ) (wvalid && !wready) |=> $stable(wdata ); endproperty
//ASSERT_WDATA_VALID  : assert property(prop_wdata_valid );
ASSERT_WDATA_STABLE : assert property(prop_wdata_stable );

// wstrb
property prop_wstrb_valid ; @(posedge aclk) disable iff ( ~aresetn ) wvalid |-> !$isunknown(wstrb ); endproperty
property prop_wstrb_stable; @(posedge aclk) disable iff ( ~aresetn ) (wvalid && !wready) |=> $stable(wstrb ); endproperty
ASSERT_WSTRB_VALID  : assert property(prop_wstrb_valid );
ASSERT_WSTRB_STABLE : assert property(prop_wstrb_stable );

// wlast
property prop_wlast_valid ; @(posedge aclk) disable iff ( ~aresetn ) wvalid |-> !$isunknown(wlast ); endproperty
property prop_wlast_stable; @(posedge aclk) disable iff ( ~aresetn ) (wvalid && !wready) |=> $stable(wlast ); endproperty
ASSERT_WLAST_VALID  : assert property(prop_wlast_valid );
ASSERT_WLAST_STABLE : assert property(prop_wlast_stable );

// rdata
property prop_rdata_valid ; @(posedge aclk) disable iff ( ~aresetn ) rvalid |-> !$isunknown(rdata ); endproperty
property prop_rdata_stable; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rdata ); endproperty
//ASSERT_RDATA_VALID  : assert property(prop_rdata_valid );
ASSERT_RDATA_STABLE : assert property(prop_rdata_stable );

// rlast
property prop_rlast_valid ; @(posedge aclk) disable iff ( ~aresetn ) rvalid |-> !$isunknown(rlast ); endproperty
property prop_rlast_stable; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rlast ); endproperty
ASSERT_RLAST_VALID  : assert property(prop_rlast_valid );
ASSERT_RLAST_STABLE : assert property(prop_rlast_stable );



if ( USE_ID ) begin
    // awid
    property prop_awid_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awid ); endproperty
    property prop_awid_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awid ); endproperty
    ASSERT_AWID_VALID  : assert property(prop_awid_valid );
    ASSERT_AWID_STABLE : assert property(prop_awid_stable );

    // bid
    property prop_bid_valid ; @(posedge aclk) disable iff ( ~aresetn ) bvalid |-> !$isunknown(bid ); endproperty
    property prop_bid_stable; @(posedge aclk) disable iff ( ~aresetn ) (bvalid && !bready) |=> $stable(bid ); endproperty
    ASSERT_BID_VALID  : assert property(prop_bid_valid );
    ASSERT_BID_STABLE : assert property(prop_bid_stable );

    // arid
    property prop_arid_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arid ); endproperty
    property prop_arid_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arid ); endproperty
    ASSERT_ARID_VALID  : assert property(prop_arid_valid );
    ASSERT_ARID_STABLE : assert property(prop_arid_stable );

    // rid
    property prop_rid_valid ; @(posedge aclk) disable iff ( ~aresetn ) rvalid |-> !$isunknown(rid ); endproperty
    property prop_rid_stable; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rid ); endproperty
    ASSERT_RID_VALID  : assert property(prop_rid_valid );
    ASSERT_RID_STABLE : assert property(prop_rid_stable );
end
        
if ( USE_SIZE ) begin
    // awsize
    property prop_awsize_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awsize ); endproperty
    property prop_awsize_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awsize ); endproperty
    ASSERT_AWSIZE_VALID  : assert property(prop_awsize_valid );
    ASSERT_AWSIZE_STABLE : assert property(prop_awsize_stable );

    // arsize
    property prop_arsize_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arsize ); endproperty
    property prop_arsize_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arsize ); endproperty
    ASSERT_ARSIZE_VALID  : assert property(prop_arsize_valid );
    ASSERT_ARSIZE_STABLE : assert property(prop_arsize_stable );
end

if ( USE_BURST ) begin
    // awburst
    property prop_awburst_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awburst ); endproperty
    property prop_awburst_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awburst ); endproperty
    ASSERT_AWBURST_VALID  : assert property(prop_awburst_valid );
    ASSERT_AWBURST_STABLE : assert property(prop_awburst_stable );

    // arburst
    property prop_arburst_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arburst ); endproperty
    property prop_arburst_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arburst ); endproperty
    ASSERT_ARBURST_VALID  : assert property(prop_arburst_valid );
    ASSERT_ARBURST_STABLE : assert property(prop_arburst_stable );
end

if ( USE_LOCK ) begin
    // awlock
    property prop_awlock_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awlock ); endproperty
    property prop_awlock_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awlock ); endproperty
    ASSERT_AWLOCK_VALID  : assert property(prop_awlock_valid );
    ASSERT_AWLOCK_STABLE : assert property(prop_awlock_stable );

    // arlock
    property prop_arlock_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arlock ); endproperty
    property prop_arlock_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arlock ); endproperty
    ASSERT_ARLOCK_VALID  : assert property(prop_arlock_valid );
    ASSERT_ARLOCK_STABLE : assert property(prop_arlock_stable );
end 

if ( USE_CACHE ) begin
    // awcache
    property prop_awcache_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awcache ); endproperty
    property prop_awcache_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awcache ); endproperty
    ASSERT_AWCACHE_VALID  : assert property(prop_awcache_valid );
    ASSERT_AWCACHE_STABLE : assert property(prop_awcache_stable );

    // arcache
    property prop_arcache_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arcache ); endproperty
    property prop_arcache_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arcache ); endproperty
    ASSERT_ARCACHE_VALID  : assert property(prop_arcache_valid );
    ASSERT_ARCACHE_STABLE : assert property(prop_arcache_stable );
end

if ( USE_PROT ) begin
    // awprot
    property prop_awprot_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awprot ); endproperty
    property prop_awprot_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awprot ); endproperty
    ASSERT_AWPROT_VALID  : assert property(prop_awprot_valid );
    ASSERT_AWPROT_STABLE : assert property(prop_awprot_stable );

    // arprot
    property prop_arprot_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arprot ); endproperty
    property prop_arprot_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arprot ); endproperty
    ASSERT_ARPROT_VALID  : assert property(prop_arprot_valid );
    ASSERT_ARPROT_STABLE : assert property(prop_arprot_stable );
end 

if ( USE_QOS ) begin
    // awqos
    property prop_awqos_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awqos ); endproperty
    property prop_awqos_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awqos ); endproperty
    ASSERT_AWQOS_VALID  : assert property(prop_awqos_valid );
    ASSERT_AWQOS_STABLE : assert property(prop_awqos_stable );

    // arqos
    property prop_arqos_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arqos ); endproperty
    property prop_arqos_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arqos ); endproperty
    ASSERT_ARQOS_VALID  : assert property(prop_arqos_valid );
    ASSERT_ARQOS_STABLE : assert property(prop_arqos_stable );
end 

if ( USE_REGION ) begin
    // awregion
    property prop_awregion_valid ; @(posedge aclk) disable iff ( ~aresetn ) awvalid |-> !$isunknown(awregion ); endproperty
    property prop_awregion_stable; @(posedge aclk) disable iff ( ~aresetn ) (awvalid && !awready) |=> $stable(awregion ); endproperty
    ASSERT_AWREGION_VALID  : assert property(prop_awregion_valid );
    ASSERT_AWREGION_STABLE : assert property(prop_awregion_stable );

    // arregion
    property prop_arregion_valid ; @(posedge aclk) disable iff ( ~aresetn ) arvalid |-> !$isunknown(arregion ); endproperty
    property prop_arregion_stable; @(posedge aclk) disable iff ( ~aresetn ) (arvalid && !arready) |=> $stable(arregion ); endproperty
    ASSERT_ARREGION_VALID  : assert property(prop_arregion_valid );
    ASSERT_ARREGION_STABLE : assert property(prop_arregion_stable );
end 

if ( USE_RESP ) begin
    // bresp
    property prop_bresp_valid ; @(posedge aclk) disable iff ( ~aresetn ) bvalid |-> !$isunknown(bresp ); endproperty
    property prop_bresp_stable; @(posedge aclk) disable iff ( ~aresetn ) (bvalid && !bready) |=> $stable(bresp ); endproperty
    ASSERT_BRESP_VALID  : assert property(prop_bresp_valid );
    ASSERT_BRESP_STABLE : assert property(prop_bresp_stable );

    // rresp
    property prop_rresp_valid ; @(posedge aclk) disable iff ( ~aresetn ) rvalid |-> !$isunknown(rresp ); endproperty
    property prop_rresp_stable; @(posedge aclk) disable iff ( ~aresetn ) (rvalid && !rready) |=> $stable(rresp ); endproperty
    ASSERT_RRESP_VALID  : assert property(prop_rresp_valid );
    ASSERT_RRESP_STABLE : assert property(prop_rresp_stable );
end


// コマンド発行数と応答数が乖離しないこと
`ifdef __SIMULATION__
    int         issue_aw;
    int         issue_w;
    int         issue_wlast;
    int         issue_b;
    int         issue_ar;
    int         issue_r;
    int         issue_rlast;
    int         issue_awlen;
    int         issue_arlen;
    assign issue_aw    = awvalid && awready         ? 1 : 0;
    assign issue_w     = wvalid  && wready          ? 1 : 0;
    assign issue_wlast = wvalid  && wready && wlast ? 1 : 0;
    assign issue_b     = bvalid  && bready          ? 1 : 0;
    assign issue_ar    = arvalid && arready         ? 1 : 0;
    assign issue_r     = rvalid  && rready          ? 1 : 0;
    assign issue_rlast = rvalid  && rready && rlast ? 1 : 0;
    assign issue_awlen = issue_aw != 0 ? int'(awlen) + 1 : 0;
    assign issue_arlen = issue_ar != 0 ? int'(arlen) + 1 : 0;

    int         count_aw;
    int         count_w;
    int         count_wc;
    int         count_ar;
    int         count_r;
    int         count_rc;

    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            count_aw     <= 0;
            count_w      <= 0;
            count_wc     <= 0;
            count_ar     <= 0;
            count_r      <= 0;
        end
        else begin
            count_aw <= count_aw + issue_aw    - issue_b        ;
            count_w  <= count_w  + issue_wlast - issue_b        ;
            count_wc <= count_wc + issue_w     - issue_awlen    ;
            count_ar <= count_ar + issue_ar    - issue_rlast    ;
            count_rc <= count_rc + issue_arlen - issue_r        ;

            assert ( count_aw >= 0 ) else begin
                $error("ERROR: %m: illegal bvalid issue (aw)");
            end
            assert ( count_w >= 0 ) else begin
                $error("ERROR: %m: illegal bvalid issue (w)");
            end
            assert ( count_wc >= -LIMIT_WC && count_wc <= LIMIT_WC ) else begin
                $error("ERROR: %m: wvalid overflow");
            end
            assert ( count_ar >= 0 ) else begin
                $error("ERROR: %m: illegal rvalid issue (ar)");
            end
            assert ( count_rc >= 0 ) else begin
                $error("ERROR: %m: illegal rvalid issue (arlen)");
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
            assert ( count_rc <= LIMIT_RC ) else begin
                $error("ERROR: %m: r channel overflow");
            end
        end
    end
`endif


endinterface


`default_nettype wire


// end of file
