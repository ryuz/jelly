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
        parameter   int                         RESP_BITS = 2,
        parameter   int                         ISSUE_LIMIT_AW = 1,
        parameter   int                         ISSUE_LIMIT_W  = 1,
        parameter   int                         ISSUE_LIMIT_AR = 1
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


// valid 時に信号が有効であること
property prop_valid(signal, valid);
@(posedge aclk) valid |-> !$isunknown(signal);
endproperty

ASSERT_VALID_AWADDR : assert property(prop_valid(awaddr,  awvalid));
ASSERT_VALID_AWPROT : assert property(prop_valid(awprot,  awvalid));
ASSERT_VALID_WDATA  : assert property(prop_valid(wdata,   wvalid ));
ASSERT_VALID_WSTRB  : assert property(prop_valid(wstrb,   wvalid ));
ASSERT_VALID_BRESP  : assert property(prop_valid(bresp,   bvalid ));
ASSERT_VALID_ARADDR : assert property(prop_valid(araddr,  arvalid));
ASSERT_VALID_ARPROT : assert property(prop_valid(arprot,  arvalid));
ASSERT_VALID_RDATA  : assert property(prop_valid(rdata,   rvalid ));
ASSERT_VALID_RRESP  : assert property(prop_valid(rresp,   rvalid ));


// valid が 1 の時に ready が 0 なら次のサイクルで信号は変化しない
property prop_stable(signal, valid, ready);
@(posedge aclk) (valid && !ready) |=> $stable(signal);
endproperty

ASSERT_STABLE_AWADDR  : assert property(prop_stable(awaddr,  awvalid, awready));
ASSERT_STABLE_AWPROT  : assert property(prop_stable(awprot,  awvalid, awready));
ASSERT_STABLE_AWVALID : assert property(prop_stable(awvalid, awvalid, awready));
ASSERT_STABLE_WDATA   : assert property(prop_stable(wdata,   wvalid,  wready ));
ASSERT_STABLE_WSTRB   : assert property(prop_stable(wstrb,   wvalid,  wready ));
ASSERT_STABLE_WVALID  : assert property(prop_stable(wvalid,  wvalid,  wready ));
ASSERT_STABLE_BRESP   : assert property(prop_stable(bresp,   bvalid,  bready ));
ASSERT_STABLE_BVALID  : assert property(prop_stable(bvalid,  bvalid,  bready ));
ASSERT_STABLE_ARADDR  : assert property(prop_stable(araddr,  arvalid, arready));
ASSERT_STABLE_ARPROT  : assert property(prop_stable(arprot,  arvalid, arready));
ASSERT_STABLE_ARVALID : assert property(prop_stable(arvalid, arvalid, arready));
ASSERT_STABLE_RDATA   : assert property(prop_stable(rdata,   rvalid,  rready ));
ASSERT_STABLE_RRESP   : assert property(prop_stable(rresp,   rvalid,  rready ));
ASSERT_STABLE_RVALID  : assert property(prop_stable(rvalid,  rvalid,  rready ));


// コマンド発行数と応答数が乖離しないこと
`ifdef __SIMULATION__
    int         issue_aw;
    int         issue_w;
    int         issue_ar;
    always_ff @(posedge aclk) begin
        if ( ~aresetn ) begin
            issue_aw     <= 0;
            issue_w      <= 0;
            issue_ar     <= 0;
        end
        else begin
            if ( awvalid && awready ) begin issue_aw <= issue_aw + 1; end
            if ( wvalid  && wready  ) begin issue_w  <= issue_w  + 1; end
            if ( bvalid  && bready  ) begin issue_aw <= issue_aw - 1; issue_w <= issue_w - 1; end
            if ( arvalid && arready ) begin issue_ar <= issue_ar + 1; end
            if ( rvalid  && rready  ) begin issue_ar <= issue_ar - 1; end

            assert ( issue_aw >= 0 && issue_w >=0 ) else begin
                $error("ERROR: %m: illegal bvalid issue");
            end
            assert ( issue_aw <= ISSUE_LIMIT_AW ) else begin
                $error("ERROR: %m: aw  channel overflow");
            end
            assert ( issue_w <= ISSUE_LIMIT_W ) else begin
                $error("ERROR: %m: w channel overflow");
            end
            assert ( issue_ar <= ISSUE_LIMIT_AR ) else begin
                $error("ERROR: %m: ar channel overflow");
            end
        end
    end
`endif


endinterface


`default_nettype wire


// end of file
