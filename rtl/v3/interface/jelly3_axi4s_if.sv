// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


interface jelly3_axi4s_if
    #(
        parameter   bit     USE_STRB  = 0,
        parameter   bit     USE_KEEP  = 0,
        parameter   bit     USE_LAST  = 1,
        parameter   bit     USE_ID    = 0,
        parameter   bit     USE_DEST  = 0,
        parameter   bit     USE_USER  = 0,

        parameter   int     DATA_BITS = 32,
        parameter   int     BYTE_BITS = 8,
        parameter   int     STRB_BITS = DATA_BITS / BYTE_BITS,
        parameter   int     KEEP_BITS = DATA_BITS / BYTE_BITS,
        parameter   int     ID_BITS   = 8,
        parameter   int     DEST_BITS = 4,
        parameter   int     USER_BITS = 1
    )
    (
        input   var logic   aresetn,
        input   var logic   aclk
    );

    // signals
    logic   [DATA_BITS-1:0]     tdata;
    logic   [STRB_BITS-1:0]     tstrb;
    logic   [STRB_BITS-1:0]     tkeep;
    logic                       tlast;
    logic   [ID_BITS-1:0]       tid;
    logic   [DEST_BITS-1:0]     tdest;
    logic   [USER_BITS-1:0]     tuser;
    logic                       tvalid;
    logic                       tready;

    modport m
        (
            input   aresetn,
            input   aclk,
            input   aclken,
    
            output  tdata,
            output  tstrb,
            output  tkeep,
            output  tlast,
            output  tid,
            output  tdest,
            output  tuser,
            output  tvalid,
            input   tready
        );

    modport s
        (
            input   aresetn,
            input   aclk,
    
            input   tdata,
            input   tstrb,
            input   tkeep,
            input   tlast,
            input   tid,
            input   tdest,
            input   tuser,
            input   tvalid,
            output  tready
        );


// valid 時に信号が有効であること
property prop_tdata_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tdata ); endproperty
property prop_tdata_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tdata); endproperty
ASSERT_TDATA_VALID  : assert property(prop_tdata_valid );
ASSERT_TDATA_STABLE : assert property(prop_tdata_stable );

if ( USE_STRB ) begin
    property prop_tstrb_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tstrb ); endproperty
    property prop_tstrb_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tstrb); endproperty
    ASSERT_TSTRB_VALID  : assert property(prop_tstrb_valid );
    ASSERT_TSTRB_STABLE : assert property(prop_tstrb_stable );
end

if ( USE_KEEP ) begin
    property prop_tkeep_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tkeep ); endproperty
    property prop_tkeep_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tkeep); endproperty
    ASSERT_TKEEP_VALID  : assert property(prop_tkeep_valid );
    ASSERT_TKEEP_STABLE : assert property(prop_tkeep_stable );
end

if ( USE_LAST ) begin
    property prop_tlast_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tlast ); endproperty
    property prop_tlast_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tlast); endproperty
    ASSERT_TLAST_VALID  : assert property(prop_tlast_valid );
    ASSERT_TLAST_STABLE : assert property(prop_tlast_stable );
end

if ( USE_ID ) begin
    property prop_tid_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tid ); endproperty
    property prop_tid_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tid); endproperty
    ASSERT_TID_VALID  : assert property(prop_tid_valid );
    ASSERT_TID_STABLE : assert property(prop_tid_stable );
end

if ( USE_DEST ) begin
    property prop_tdest_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tdest ); endproperty
    property prop_tdest_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tdest); endproperty
    ASSERT_TDEST_VALID  : assert property(prop_tdest_valid );
    ASSERT_TDEST_STABLE : assert property(prop_tdest_stable );
end

if ( USE_USER ) begin
    property prop_tuser_valid ; @(posedge aclk) disable iff ( ~aresetn ) tvalid |-> !$isunknown(tuser ); endproperty
    property prop_tuser_stable; @(posedge aclk) disable iff ( ~aresetn ) (tvalid && !tready) |=> $stable(tuser); endproperty
    ASSERT_TUSER_VALID  : assert property(prop_tuser_valid );
    ASSERT_TUSER_STABLE : assert property(prop_tuser_stable );
end

endinterface


`default_nettype wire


// end of file