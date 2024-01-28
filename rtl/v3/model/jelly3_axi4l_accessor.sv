// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4l_accessor
    #(
        parameter   int     RAND_RATE_AW = 0,
        parameter   int     RAND_RATE_W  = 0,
        parameter   int     RAND_RATE_B  = 0,
        parameter   int     RAND_RATE_AR = 0,
        parameter   int     RAND_RATE_R  = 0
    )
    (
        jelly3_axi4l_if.m   m_axi4l
    );

    localparam EPSILON = 0.01;

    logic   busy_aw;
    logic   busy_w ;
    logic   busy_b ;
    logic   busy_ar;
    logic   busy_r ;
    always_ff @(posedge m_axi4l.aclk) begin
        if ( !m_axi4l.awvalid || m_axi4l.awready )  busy_aw <= $urandom_range(100) < RAND_RATE_AW;
        if ( !m_axi4l.wvalid  || m_axi4l.wready  )  busy_w  <= $urandom_range(100) < RAND_RATE_W;
        busy_b  <= $urandom_range(100) < RAND_RATE_B;
        if ( !m_axi4l.arvalid || m_axi4l.arready )  busy_ar <= $urandom_range(100) < RAND_RATE_AR;
        busy_r  <= $urandom_range(100) < RAND_RATE_R;
    end


    // signals
    logic   [m_axi4l.ADDR_BITS-1:0]     awaddr;
    logic   [m_axi4l.PROT_BITS-1:0]     awprot;
    logic                               awvalid = 1'b0;
    logic                               awready;
    logic   [m_axi4l.STRB_BITS-1:0]     wstrb;
    logic   [m_axi4l.DATA_BITS-1:0]     wdata;
    logic                               wvalid = 1'b0;
    logic                               wready;
    logic   [m_axi4l.RESP_BITS-1:0]     bresp;
    logic                               bvalid;
    logic                               bready = 1'b0;
    logic   [m_axi4l.ADDR_BITS-1:0]     araddr;
    logic   [m_axi4l.PROT_BITS-1:0]     arprot;
    logic                               arvalid = 1'b0;
    logic                               arready;
    logic   [m_axi4l.DATA_BITS-1:0]     rdata;
    logic   [m_axi4l.RESP_BITS-1:0]     rresp;
    logic                               rvalid;
    logic                               rready = 1'b0;

    assign m_axi4l.awaddr  = awvalid ? awaddr : 'x  ;
    assign m_axi4l.awprot  = awvalid ? awprot : 'x  ;
    assign m_axi4l.awvalid = awvalid && busy_aw;
    assign m_axi4l.wstrb   = wvalid  ? wstrb  : 'x  ;
    assign m_axi4l.wdata   = wvalid  ? wdata  : 'x  ;
    assign m_axi4l.wvalid  = wvalid  && busy_w ;
    assign m_axi4l.bready  = !busy_b;
    assign m_axi4l.araddr  = arvalid ? araddr : 'x  ;
    assign m_axi4l.arprot  = arvalid ? arprot : 'x  ;
    assign m_axi4l.arvalid = arvalid && busy_ar;
    assign m_axi4l.rready  = !busy_r;

    // fetch
    logic                               awready;
    logic                               wready;
    logic   [m_axi4l.RESP_BITS-1:0]     bresp;
    logic                               bvalid;
    logic                               arready;
    logic   [m_axi4l.DATA_BITS-1:0]     rdata;
    logic   [m_axi4l.RESP_BITS-1:0]     rresp;
    logic                               rvalid;

    logic                               issue_aw;
    logic                               issue_w;
    logic                               issue_b;
    logic                               issue_ar;
    logic                               issue_r;
    always_ff @(posedge m_axi4l.aclk) begin
        awready <= m_axi4l.awready;
        wready  <= m_axi4l.wready ;
        bresp   <= m_axi4l.bresp  ;
        bvalid  <= m_axi4l.bvalid ;
        arready <= m_axi4l.arready;
        rdata   <= m_axi4l.rdata  ;
        rresp   <= m_axi4l.rresp  ;
        rvalid  <= m_axi4l.rvalid ;

        issue_aw <= m_axi4l.awvalid & m_axi4l.awready   ;
        issue_w  <= m_axi4l.wvalid  & m_axi4l.wready    ;
        issue_b  <= m_axi4l.bvalid  & m_axi4l.bready    ;
        issue_ar <= m_axi4l.arvalid & m_axi4l.arready   ;
        issue_r  <= m_axi4l.rvalid  & m_axi4l.rready    ;
    end

    task write(
                input   logic   [ADDR_BITS-1:0]     addr,
                input   logic   [DATA_BITS-1:0]     data,
                input   logic   [STRB_BITS-1:0]     strb
            );
        $display("[axi4l write] addr:%x <= data:%x strb:%x", addr, data, strb);
        @(posedge aclk); #EPSILON;
        awaddr  = addr;
        awprot  = '0;
        awvalid = 1'b1;
        wstrb   = strb;
        wdata   = data;
        wvalid  = 1'b1;

        @(posedge aclk); #EPSILON;
        while ( awvalid || wvalid ) begin
            if ( issue_aw ) begin
                awaddr  = 'x;
                awprot  = 'x;
                awvalid = 1'b0;
            end
            if ( issue_w ) begin
                wstrb   = 'x;
                wdata   = 'x;
                wvalid  = 1'b0;
            end
            @(posedge aclk); #EPSILON;
        end

        while ( !issue_b ) begin
            @(posedge aclk); #EPSILON;
        end
    endtask

    task read(
                input   logic   [ADDR_BITS-1:0]     addr,
                output  logic   [DATA_BITS-1:0]     data
            );
        @(posedge aclk); #EPSILON;
        araddr  = addr;
        arprot  = '0;
        arvalid = 1'b1;
        @(posedge aclk); #EPSILON;
        while ( !issue_aw ) begin
            @(posedge aclk); #EPSILON;
        end

        araddr  = 'x;
        arprot  = 'x;
        arvalid = 1'b0;
        @(posedge aclk); #EPSILON;
        while ( !issue_r ) begin
            @(posedge aclk); #EPSILON;
        end
        data = rdata;
        $display("[axi4l read] addr:%x => data:%x", addr, data);
    endtask

endmodule


`default_nettype wire


// end of file
