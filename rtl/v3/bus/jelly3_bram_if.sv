// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


interface jelly3_bram_if
    #(
        parameter   int     ID_BITS   = 8                       ,
        parameter   int     ADDR_BITS = 10                      ,
        parameter   int     DATA_BITS = 32                      ,
        parameter   int     BYTE_BITS = 8                       ,
        parameter   int     STRB_BITS = DATA_BITS / BYTE_BITS   
    )
    (
        input   var logic   reset   ,
        input   var logic   clk     ,
        input   var logic   cke     
    );

    typedef logic   [ID_BITS-1:0]       id_t    ;
    typedef logic   [ADDR_BITS-1:0]     addr_t  ;
    typedef logic   [DATA_BITS-1:0]     data_t  ;
    typedef logic   [STRB_BITS-1:0]     strb_t  ;

    // command
    id_t        cid         ;
    addr_t      caddr       ;
    logic       clast       ;
    strb_t      cstrb       ;
    data_t      cdata       ;
    logic       clast       ;
    logic       cvalid      ;
    logic       cready      ;

    // response
    id_t        rid         ;
    logic       rlast       ;
    data_t      rdata       ;
    logic       rvalid      ;
    logic       rready      ;
    
    modport m
        (
            input   reset       ,
            input   clk         ,
    
            output  cid         ,
            output  caddr       ,
            output  clast       ,
            output  cstrb       ,
            output  cdata       ,
            output  cvalid      ,
            input   cready      ,
        
            input   rid         ,
            input   rlast       ,
            input   rdata       ,
            input   rvalid      ,
            output  rready      
        );

    modport s
        (
            input   reset       ,
            input   clk         ,
    
            input   cid         ,
            input   caddr       ,
            input   clast       ,
            input   cstrb       ,
            input   cdata       ,
            input   cvalid      ,
            output  cready      ,
        
            output  rid         ,
            output  rlast       ,
            output  rvalid      ,
            input   rready      
        );


// caddr
property prop_caddr_valid  ; @(posedge clk) disable iff ( reset ) cvalid |-> !$isunknown(caddr); endproperty
property prop_caddr_stable ; @(posedge clk) disable iff ( reset ) (cvalid && !cready) |=> $stable(caddr); endproperty
ASSERT_CADDR_VALID  : assert property(prop_caddr_valid );
ASSERT_CADDR_STABLE : assert property(prop_caddr_stable);

// cstrb
property prop_cstrb_valid  ; @(posedge clk) disable iff ( reset ) cvalid |-> !$isunknown(cstrb); endproperty
property prop_cstrb_stable ; @(posedge clk) disable iff ( reset ) (cvalid && !cready) |=> $stable(cstrb); endproperty
ASSERT_CSTRB_VALID  : assert property(prop_cstrb_valid );
ASSERT_CSTRB_STABLE : assert property(prop_cstrb_stable);

// cvalid
property prop_cvalid_stable ; @(posedge clk) disable iff ( reset ) (cvalid && !cready) |=> $stable(cvalid ); endproperty
ASSERT_CVALID_STABLE : assert property(prop_cvalid_stable);


// rdata
property prop_rdata_valid  ; @(posedge clk) disable iff ( reset ) rvalid |-> !$isunknown(rdata ); endproperty
property prop_rdata_stable ; @(posedge clk) disable iff ( reset ) (rvalid && !rready) |=> $stable(rdata ); endproperty
ASSERT_RDATA_VALID  : assert property(prop_rdata_valid );
ASSERT_RDATA_STABLE : assert property(prop_rdata_stable );

// rvalid
property prop_rvalid_stable ; @(posedge clk) disable iff ( reset ) (rvalid && !rready) |=> $stable(rvalid ); endproperty
ASSERT_RVALID_STABLE : assert property(prop_rvalid_stable );


endinterface


`default_nettype wire


// end of file
