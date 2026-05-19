
// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4_m
        #(
            parameter   int     WADDR_LOW    = 0      ,
            parameter   int     WADDR_HIGH   = 4095   ,
            parameter   int     RADDR_LOW    = 0      ,
            parameter   int     RADDR_HIGH   = 4095   ,
            parameter   int     AW_BUSY_RATE = 0      ,
            parameter   int     W_BUSY_RATE  = 0      ,
            parameter   int     B_BUSY_RATE  = 0      ,
            parameter   int     AR_BUSY_RATE = 0      ,
            parameter   int     R_BUSY_RATE  = 0      
        )
        (
            input   var logic       enable      ,
            jelly3_axi4_if.m        m_axi4
        );

    localparam int  ID_BITS     = m_axi4.ID_BITS         ;
    localparam int  ADDR_BITS   = m_axi4.ADDR_BITS       ;
    localparam int  LEN_BITS    = m_axi4.LEN_BITS        ;
    localparam int  SIZE_BITS   = m_axi4.SIZE_BITS       ;
    localparam int  BURST_BITS  = m_axi4.BURST_BITS      ;
    localparam int  LOCK_BITS   = m_axi4.LOCK_BITS       ;
    localparam int  CACHE_BITS  = m_axi4.CACHE_BITS      ;
    localparam int  PROT_BITS   = m_axi4.PROT_BITS       ;
    localparam int  QOS_BITS    = m_axi4.QOS_BITS        ;
    localparam int  REGION_BITS = m_axi4.REGION_BITS     ;
    localparam int  DATA_BITS   = m_axi4.DATA_BITS       ;
    localparam int  STRB_BITS   = m_axi4.STRB_BITS       ;
    localparam int  RESP_BITS   = m_axi4.RESP_BITS       ;
    localparam int  AWUSER_BITS = m_axi4.AWUSER_BITS     ;
    localparam int  WUSER_BITS  = m_axi4.WUSER_BITS      ;
    localparam int  BUSER_BITS  = m_axi4.BUSER_BITS      ;
    localparam int  ARUSER_BITS = m_axi4.ARUSER_BITS     ;
    localparam int  RUSER_BITS  = m_axi4.RUSER_BITS      ;

    localparam type id_t       = logic [ID_BITS-1:0]      ;
    localparam type addr_t     = logic [ADDR_BITS-1:0]    ;
    localparam type len_t      = logic [LEN_BITS-1:0]     ;
    localparam type size_t     = logic [SIZE_BITS-1:0]    ;
    localparam type burst_t    = logic [BURST_BITS-1:0]   ;
    localparam type lock_t     = logic [LOCK_BITS-1:0]    ;
    localparam type cache_t    = logic [CACHE_BITS-1:0]   ;
    localparam type prot_t     = logic [PROT_BITS-1:0]    ;
    localparam type qos_t      = logic [QOS_BITS-1:0]     ;
    localparam type region_t   = logic [REGION_BITS-1:0]  ;
    localparam type data_t     = logic [DATA_BITS-1:0]    ;
    localparam type strb_t     = logic [STRB_BITS-1:0]    ;
    localparam type resp_t     = logic [RESP_BITS-1:0]    ;
    localparam type awuser_t   = logic [AWUSER_BITS-1:0]  ;
    localparam type wuser_t    = logic [WUSER_BITS-1:0]   ;
    localparam type buser_t    = logic [BUSER_BITS-1:0]   ;
    localparam type aruser_t   = logic [ARUSER_BITS-1:0]  ;
    localparam type ruser_t    = logic [RUSER_BITS-1:0]   ;

    len_t   aw_queue [$];
    bit     w_queue [$];

    id_t    awid;
    addr_t  awaddr;
    len_t   awlen;
    size_t  awsize;
    burst_t awburst;
    lock_t  awlock;
    cache_t awcache;
    prot_t  awprot;
    qos_t   awqos;
    region_t awregion;
    awuser_t awuser;
    logic   awvalid;

    data_t  wdata;
    strb_t  wstrb;
    logic   wlast;
    wuser_t wuser;
    logic   wvalid;

    logic   bready;

    id_t    arid;
    addr_t  araddr;
    len_t   arlen;
    size_t  arsize;
    burst_t arburst;
    lock_t  arlock;
    cache_t arcache;
    prot_t  arprot;
    qos_t   arqos;
    region_t arregion;
    aruser_t aruser;
    logic   arvalid;

    logic   rready;

    function automatic bit can_issue(input int busy_rate);
        return ($urandom_range(0, 100) >= busy_rate);
    endfunction

    always_ff @(posedge m_axi4.aclk) begin
        if ( !m_axi4.aresetn ) begin
            awvalid <= 1'b0;
            wvalid  <= 1'b0;
            bready  <= 1'b0;
            arvalid <= 1'b0;
            rready  <= 1'b0;
        end
        else if ( m_axi4.aclken ) begin
            // 書き込みコマンドを一定数キューイングする
            while ( enable && aw_queue.size() <= 2 ) begin
                automatic len_t len = len_t'($urandom());
                aw_queue.push_back(len);
                for ( int i = 0; i < int'(len)+1; i++ ) begin
                    w_queue.push_back(i==int'(len));
                end
            end

            // aw
            if ( !awvalid || m_axi4.awready ) begin
                if ( can_issue(AW_BUSY_RATE) && aw_queue.size() > 0 ) begin
                    awid    <= id_t'($urandom());
                    awaddr  <= addr_t'($urandom_range(WADDR_LOW, WADDR_HIGH));
                    awlen   <= aw_queue[0];
                    awsize  <= size_t'($urandom());
                    awburst <= burst_t'($urandom());
                    awlock  <= lock_t'($urandom());
                    awcache <= cache_t'($urandom());
                    awprot  <= prot_t'($urandom());
                    awqos   <= qos_t'($urandom());
                    awregion <= region_t'($urandom());
                    awuser  <= awuser_t'($urandom());
                    awvalid <= 1'b1;
                    aw_queue.pop_front();
                end
                else begin
                    awvalid <= 1'b0;
                end
            end

            // w
            if ( !wvalid || m_axi4.wready ) begin
                if ( can_issue(W_BUSY_RATE) && w_queue.size() > 0 ) begin
                    wdata   <= data_t'($urandom());
                    wstrb   <= strb_t'($urandom());
                    wlast   <= w_queue[0];
                    wuser   <= wuser_t'($urandom());
                    wvalid  <= 1'b1;
                    w_queue.pop_front();
                end
            end

            // b
            bready <= can_issue(B_BUSY_RATE);

            // ar
            if ( !arvalid || m_axi4.arready ) begin
                if ( enable && can_issue(AR_BUSY_RATE) ) begin
                    arid     <= id_t'($urandom());
                    araddr   <= addr_t'($urandom_range(RADDR_LOW, RADDR_HIGH));
                    arlen    <= len_t'($urandom());
                    arsize   <= size_t'($urandom());
                    arburst  <= burst_t'($urandom());
                    arlock   <= lock_t'($urandom());
                    arcache  <= cache_t'($urandom());
                    arprot   <= prot_t'($urandom());
                    arqos    <= qos_t'($urandom());
                    arregion <= region_t'($urandom());
                    aruser   <= aruser_t'($urandom());
                    arvalid  <= 1'b1;
                end
                else begin
                    arvalid <= 1'b0;
                end
            end

            // r
            rready <= can_issue(R_BUSY_RATE);
        end
    end

    assign m_axi4.awid     = awvalid ? awid     : 'x;
    assign m_axi4.awaddr   = awvalid ? awaddr   : 'x;
    assign m_axi4.awlen    = awvalid ? awlen    : 'x;
    assign m_axi4.awsize   = awvalid ? awsize   : 'x;
    assign m_axi4.awburst  = awvalid ? awburst  : 'x;
    assign m_axi4.awlock   = awvalid ? awlock   : 'x;
    assign m_axi4.awcache  = awvalid ? awcache  : 'x;
    assign m_axi4.awprot   = awvalid ? awprot   : 'x;
    assign m_axi4.awqos    = awvalid ? awqos    : 'x;
    assign m_axi4.awregion = awvalid ? awregion : 'x;
    assign m_axi4.awuser   = awvalid ? awuser   : 'x;
    assign m_axi4.awvalid  = awvalid;

    assign m_axi4.wdata    = wvalid ? wdata : 'x;
    assign m_axi4.wstrb    = wvalid ? wstrb : 'x;
    assign m_axi4.wlast    = wvalid ? wlast : 'x;
    assign m_axi4.wuser    = wvalid ? wuser : 'x;
    assign m_axi4.wvalid   = wvalid;

    assign m_axi4.bready   = bready;

    assign m_axi4.arid     = arvalid ? arid     : 'x;
    assign m_axi4.araddr   = arvalid ? araddr   : 'x;
    assign m_axi4.arlen    = arvalid ? arlen    : 'x;
    assign m_axi4.arsize   = arvalid ? arsize   : 'x;
    assign m_axi4.arburst  = arvalid ? arburst  : 'x;
    assign m_axi4.arlock   = arvalid ? arlock   : 'x;
    assign m_axi4.arcache  = arvalid ? arcache  : 'x;
    assign m_axi4.arprot   = arvalid ? arprot   : 'x;
    assign m_axi4.arqos    = arvalid ? arqos    : 'x;
    assign m_axi4.arregion = arvalid ? arregion : 'x;
    assign m_axi4.aruser   = arvalid ? aruser   : 'x;
    assign m_axi4.arvalid  = arvalid;

    assign m_axi4.rready   = rready;
    
endmodule


`default_nettype wire
