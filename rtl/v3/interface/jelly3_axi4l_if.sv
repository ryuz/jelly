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


/*
// valid 時に信号が有効であること
property prop_valid_addr (logic [ADDR_BITS-1:0] addr, logic valid);
@(posedge aclk) valid |-> !$isunknown(addr);
endproperty
property prop_valid_prot (logic [PROT_BITS-1:0] prot, logic valid);
@(posedge aclk) valid |-> !$isunknown(prot);
endproperty
property prop_valid_data (logic [DATA_BITS-1:0] data, logic valid);
@(posedge aclk) valid |-> !$isunknown(data);
endproperty
property prop_valid_strb (logic [STRB_BITS-1:0] strb, logic valid);
@(posedge aclk) valid |-> !$isunknown(strb);
endproperty
property prop_valid_resp (logic [RESP_BITS-1:0] resp, logic valid);
@(posedge aclk) valid |-> !$isunknown(resp);
endproperty

ASSERT_VALID_AWADDR : assert property(prop_valid_addr(awaddr,  awvalid));
ASSERT_VALID_AWPROT : assert property(prop_valid_prot(awprot,  awvalid));
ASSERT_VALID_WDATA  : assert property(prop_valid_data(wdata,   wvalid ));
ASSERT_VALID_WSTRB  : assert property(prop_valid_strb(wstrb,   wvalid ));
ASSERT_VALID_BRESP  : assert property(prop_valid_resp(bresp,   bvalid ));
ASSERT_VALID_ARADDR : assert property(prop_valid_addr(araddr,  arvalid));
ASSERT_VALID_ARPROT : assert property(prop_valid_prot(arprot,  arvalid));
ASSERT_VALID_RDATA  : assert property(prop_valid_data(rdata,   rvalid ));
ASSERT_VALID_RRESP  : assert property(prop_valid_resp(rresp,   rvalid ));


// valid が 1 の時に ready が 0 なら次のサイクルでもvalidは維持
property prop_stable_valid(logic valid, logic ready);
@(posedge aclk) (valid && !ready) |=> valid;
endproperty
ASSERT_STABLE_AWVALID : assert property(prop_stable_valid(awvalid, awready));
ASSERT_STABLE_WVALID  : assert property(prop_stable_valid(wvalid,  wready ));
ASSERT_STABLE_BVALID  : assert property(prop_stable_valid(bvalid,  bready ));
ASSERT_STABLE_ARVALID : assert property(prop_stable_valid(arvalid, arready));
ASSERT_STABLE_RVALID  : assert property(prop_stable_valid(rvalid,  rready ));

// valid が 1 の時に ready が 0 なら次のサイクルで信号は変化しない
property prop_stable_addr(logic [ADDR_BITS-1:0] addr, logic valid, logic ready);
@(posedge aclk) (valid && !ready) |=> $stable(addr);
endproperty
property prop_stable_prot(logic [PROT_BITS-1:0] prot, logic valid, logic ready);
@(posedge aclk) (valid && !ready) |=> $stable(prot);
endproperty
property prop_stable_data(logic [DATA_BITS-1:0] data, logic valid, logic ready);
@(posedge aclk) (valid && !ready) |=> $stable(data);
endproperty
property prop_stable_strb(logic [STRB_BITS-1:0] strb, logic valid, logic ready);
@(posedge aclk) (valid && !ready) |=> $stable(strb);
endproperty
property prop_stable_resp(logic [RESP_BITS-1:0] resp, logic valid, logic ready);
@(posedge aclk) (valid && !ready) |=> $stable(resp);
endproperty
ASSERT_STABLE_AWADDR  : assert property(prop_stable_addr(awaddr, awvalid, awready));
ASSERT_STABLE_AWPROT  : assert property(prop_stable_prot(awprot, awvalid, awready));
ASSERT_STABLE_WDATA   : assert property(prop_stable_data(wdata,  wvalid,  wready ));
ASSERT_STABLE_WSTRB   : assert property(prop_stable_strb(wstrb,  wvalid,  wready ));
ASSERT_STABLE_BRESP   : assert property(prop_stable_resp(bresp,  bvalid,  bready ));
ASSERT_STABLE_ARADDR  : assert property(prop_stable_addr(araddr, arvalid, arready));
ASSERT_STABLE_ARPROT  : assert property(prop_stable_prot(arprot, arvalid, arready));
ASSERT_STABLE_RDATA   : assert property(prop_stable_data(rdata,  rvalid,  rready ));
ASSERT_STABLE_RRESP   : assert property(prop_stable_resp(rresp,  rvalid,  rready ));
*/


// valid 時に信号が有効であること
property prop_valid_awaddr ; @(posedge aclk) awvalid |-> !$isunknown(awaddr ); endproperty
property prop_valid_awprot ; @(posedge aclk) awvalid |-> !$isunknown(awprot ); endproperty
property prop_valid_wdata  ; @(posedge aclk) wvalid  |-> !$isunknown(wdata  ); endproperty
property prop_valid_wstrb  ; @(posedge aclk) wvalid  |-> !$isunknown(wstrb  ); endproperty
property prop_valid_bresp  ; @(posedge aclk) bvalid  |-> !$isunknown(bresp  ); endproperty
property prop_valid_araddr ; @(posedge aclk) arvalid |-> !$isunknown(araddr ); endproperty
property prop_valid_arprot ; @(posedge aclk) arvalid |-> !$isunknown(arprot ); endproperty
property prop_valid_rdata  ; @(posedge aclk) rvalid  |-> !$isunknown(rdata  ); endproperty
property prop_valid_rresp  ; @(posedge aclk) rvalid  |-> !$isunknown(rresp  ); endproperty
ASSERT_VALID_AWADDR  : assert property(prop_valid_awaddr );
ASSERT_VALID_AWPROT  : assert property(prop_valid_awprot );
ASSERT_VALID_WDATA   : assert property(prop_valid_wdata  );
ASSERT_VALID_WSTRB   : assert property(prop_valid_wstrb  );
ASSERT_VALID_BRESP   : assert property(prop_valid_bresp  );
ASSERT_VALID_ARADDR  : assert property(prop_valid_araddr );
ASSERT_VALID_ARPROT  : assert property(prop_valid_arprot );
ASSERT_VALID_RDATA   : assert property(prop_valid_rdata  );
ASSERT_VALID_RRESP   : assert property(prop_valid_rresp  );

// valid が 1 の時に ready が 0 なら次のサイクルで信号は変化しない
property prop_stable_awaddr ; @(posedge aclk) (awvalid && !awready) |=> $stable(awaddr ); endproperty
property prop_stable_awprot ; @(posedge aclk) (awvalid && !awready) |=> $stable(awprot ); endproperty
property prop_stable_awvalid; @(posedge aclk) (awvalid && !awready) |=> $stable(awvalid); endproperty
property prop_stable_wdata  ; @(posedge aclk) (wvalid  && !wready ) |=> $stable(wdata  ); endproperty
property prop_stable_wstrb  ; @(posedge aclk) (wvalid  && !wready ) |=> $stable(wstrb  ); endproperty
property prop_stable_wvalid ; @(posedge aclk) (wvalid  && !wready ) |=> $stable(wvalid ); endproperty
property prop_stable_bresp  ; @(posedge aclk) (bvalid  && !bready ) |=> $stable(bresp  ); endproperty
property prop_stable_bvalid ; @(posedge aclk) (bvalid  && !bready ) |=> $stable(bvalid ); endproperty
property prop_stable_araddr ; @(posedge aclk) (arvalid && !arready) |=> $stable(araddr ); endproperty
property prop_stable_arprot ; @(posedge aclk) (arvalid && !arready) |=> $stable(arprot ); endproperty
property prop_stable_arvalid; @(posedge aclk) (arvalid && !arready) |=> $stable(arvalid); endproperty
property prop_stable_rdata  ; @(posedge aclk) (rvalid  && !rready ) |=> $stable(rdata  ); endproperty
property prop_stable_rresp  ; @(posedge aclk) (rvalid  && !rready ) |=> $stable(rresp  ); endproperty
property prop_stable_rvalid ; @(posedge aclk) (rvalid  && !rready ) |=> $stable(rvalid ); endproperty
ASSERT_STABLE_AWADDR  : assert property(prop_stable_awaddr );
ASSERT_STABLE_AWPROT  : assert property(prop_stable_awprot );
ASSERT_STABLE_AWVALID : assert property(prop_stable_awvalid);
ASSERT_STABLE_WDATA   : assert property(prop_stable_wdata  );
ASSERT_STABLE_WSTRB   : assert property(prop_stable_wstrb  );
ASSERT_STABLE_WVALID  : assert property(prop_stable_wvalid );
ASSERT_STABLE_BRESP   : assert property(prop_stable_bresp  );
ASSERT_STABLE_BVALID  : assert property(prop_stable_bvalid );
ASSERT_STABLE_ARADDR  : assert property(prop_stable_araddr );
ASSERT_STABLE_ARPROT  : assert property(prop_stable_arprot );
ASSERT_STABLE_ARVALID : assert property(prop_stable_arvalid);
ASSERT_STABLE_RDATA   : assert property(prop_stable_rdata  );
ASSERT_STABLE_RRESP   : assert property(prop_stable_rresp  );
ASSERT_STABLE_RVALID  : assert property(prop_stable_rvalid );



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
