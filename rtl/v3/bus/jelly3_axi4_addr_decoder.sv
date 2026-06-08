// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_addr_decoder
        #(
            parameter   int             NUM           = 4,
            parameter   int             DEC_ADDR_BITS = 0,
            parameter   bit     [63:0]  DEC_ADDR_MASK = '1
        )
        (
            jelly3_axi4_if.s    s_axi4,
            jelly3_axi4_if.m    m_axi4 [NUM]
        );

    localparam int DEC_MASK_BITS = DEC_ADDR_BITS > 0 ? DEC_ADDR_BITS : s_axi4.ADDR_BITS;
    typedef logic [DEC_MASK_BITS-1:0] mask_t;
    function [DEC_MASK_BITS-1:0] dec_addr_mask(input [s_axi4.ADDR_BITS-1:0] addr);
        return DEC_MASK_BITS'(addr) & DEC_MASK_BITS'(DEC_ADDR_MASK);
    endfunction

    localparam type id_t     = logic [s_axi4.ID_BITS    -1:0];
    localparam type addr_t   = logic [s_axi4.ADDR_BITS  -1:0];
    localparam type len_t    = logic [s_axi4.LEN_BITS   -1:0];
    localparam type size_t   = logic [s_axi4.SIZE_BITS  -1:0];
    localparam type burst_t  = logic [s_axi4.BURST_BITS -1:0];
    localparam type lock_t   = logic [s_axi4.LOCK_BITS  -1:0];
    localparam type cache_t  = logic [s_axi4.CACHE_BITS -1:0];
    localparam type prot_t   = logic [s_axi4.PROT_BITS  -1:0];
    localparam type qos_t    = logic [s_axi4.QOS_BITS   -1:0];
    localparam type region_t = logic [s_axi4.REGION_BITS-1:0];
    localparam type data_t   = logic [s_axi4.DATA_BITS  -1:0];
    localparam type strb_t   = logic [s_axi4.STRB_BITS  -1:0];
    localparam type resp_t   = logic [s_axi4.RESP_BITS  -1:0];
    localparam type awuser_t = logic [s_axi4.AWUSER_BITS-1:0];
    localparam type wuser_t  = logic [s_axi4.WUSER_BITS -1:0];
    localparam type buser_t  = logic [s_axi4.BUSER_BITS -1:0];
    localparam type aruser_t = logic [s_axi4.ARUSER_BITS-1:0];
    localparam type ruser_t  = logic [s_axi4.RUSER_BITS -1:0];

    addr_t addr_base [NUM];
    addr_t addr_high [NUM];
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign addr_base[i] = m_axi4[i].addr_base;
        assign addr_high[i] = m_axi4[i].addr_high;
    end

    // address decode
    logic [NUM:0]   awaddr_match;
    always_comb begin
        awaddr_match      = '0;
        awaddr_match[NUM] = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( dec_addr_mask(s_axi4.awaddr) >= dec_addr_mask(addr_base[i])
              && dec_addr_mask(s_axi4.awaddr) <= dec_addr_mask(addr_high[i]) ) begin
                awaddr_match[i]   = 1'b1;
                awaddr_match[NUM] = 1'b0;
                break;
            end
        end
    end

    logic [NUM:0]   araddr_match;
    always_comb begin
        araddr_match      = '0;
        araddr_match[NUM] = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( dec_addr_mask(s_axi4.araddr) >= dec_addr_mask(addr_base[i])
              && dec_addr_mask(s_axi4.araddr) <= dec_addr_mask(addr_high[i]) ) begin
                araddr_match[i]   = 1'b1;
                araddr_match[NUM] = 1'b0;
                break;
            end
        end
    end

    // write channel
    logic   [NUM:0]     m_awready;
    logic   [NUM:0]     m_wready ;
    id_t    [NUM:0]     m_bid    ;
    resp_t  [NUM:0]     m_bresp  ;
    buser_t [NUM:0]     m_buser  ;
    logic   [NUM:0]     m_bvalid ;
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_awready[i] = m_axi4[i].awready ;
        assign m_wready [i] = m_axi4[i].wready  ;
        assign m_bid    [i] = m_axi4[i].bid     ;
        assign m_bresp  [i] = m_axi4[i].bresp   ;
        assign m_buser  [i] = m_axi4[i].buser   ;
        assign m_bvalid [i] = m_axi4[i].bvalid  ;
    end


    logic               write_busy  ;
    logic   [NUM:0]     w_maskbit  ;

    id_t                m_awid      ;
    addr_t              m_awaddr    ;
    len_t               m_awlen     ;
    size_t              m_awsize    ;
    burst_t             m_awburst   ;
    lock_t              m_awlock    ;
    cache_t             m_awcache   ;
    prot_t              m_awprot    ;
    qos_t               m_awqos     ;
    region_t            m_awregion  ;
    awuser_t            m_awuser    ;
    logic   [NUM:0]     m_awvalid   ;
    data_t              m_wdata     ;
    strb_t              m_wstrb     ;
    logic               m_wlast     ;
    wuser_t             m_wuser     ;
    logic   [NUM:0]     m_wvalid    ;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            write_busy   <= 1'b0    ;
            w_maskbit    <= '0      ;
            m_awvalid    <= '0      ;
            m_wvalid     <= '0      ;

            s_axi4.bid    <= 'x     ;
            s_axi4.bresp  <= 'x     ;
            s_axi4.buser  <= 'x     ;
            s_axi4.bvalid <= 1'b0   ;
        end
        else begin
            // finish
            for ( int i = 0; i < NUM+1; i++ ) begin
                if ( m_awready[i] ) begin
                    m_awvalid[i] <= 1'b0;
                end
                if ( m_wready[i] ) begin
                    m_wvalid[i]  <= 1'b0;
                end
                if ( s_axi4.wlast && s_axi4.wvalid && s_axi4.wready ) begin
                    w_maskbit <= '0   ;
                end
            end
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                write_busy    <= 1'b0   ;
                s_axi4.bid    <= 'x     ;
                s_axi4.bresp  <= 'x     ;
                s_axi4.buser  <= 'x     ;
                s_axi4.bvalid <= 1'b0   ;
            end

            // write data
            if ( s_axi4.wready ) begin
                m_wdata <= s_axi4.wdata ;
                m_wstrb <= s_axi4.wstrb ;
                m_wlast <= s_axi4.wlast ;
                m_wuser <= s_axi4.wuser ;
                for ( int i = 0; i < NUM+1; i++ ) begin
                    if ( s_axi4.wready && w_maskbit[i] ) begin
                        m_wvalid[i]  <= s_axi4.wvalid;
                    end
                end
            end

            // start
            if ( s_axi4.awvalid && s_axi4.awready && s_axi4.wvalid && s_axi4.wready ) begin
                write_busy <= 1'b1;
                m_awid     <= s_axi4.awid    ;
                m_awaddr   <= s_axi4.awaddr  ;
                m_awlen    <= s_axi4.awlen   ;
                m_awsize   <= s_axi4.awsize  ;
                m_awburst  <= s_axi4.awburst ;
                m_awlock   <= s_axi4.awlock  ;
                m_awcache  <= s_axi4.awcache ;
                m_awprot   <= s_axi4.awprot  ;
                m_awqos    <= s_axi4.awqos   ;
                m_awregion <= s_axi4.awregion;
                m_awuser   <= s_axi4.awuser  ;
                m_wdata    <= s_axi4.wdata   ;
                m_wstrb    <= s_axi4.wstrb   ;
                m_wlast    <= s_axi4.wlast   ;
                m_wuser    <= s_axi4.wuser   ;
                for ( int i = 0; i < NUM+1; i++ ) begin
                    if ( awaddr_match[i] ) begin
                        w_maskbit[i] <= !s_axi4.wlast;
                        m_awvalid[i] <= 1'b1;
                        m_wvalid [i] <= 1'b1;
                    end
                end
            end

            // response
            for ( int i = 0; i < NUM+1; i++ ) begin
                if ( m_bvalid[i] ) begin
                    s_axi4.bid    <= m_bid  [i];
                    s_axi4.bresp  <= m_bresp[i];
                    s_axi4.buser  <= m_buser[i];
                    s_axi4.bvalid <= 1'b1;
                end
            end
        end
    end

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4[i].awid     = m_awvalid[i] ? m_awid     : 'x;
        assign m_axi4[i].awaddr   = m_awvalid[i] ? m_awaddr   : 'x;
        assign m_axi4[i].awlen    = m_awvalid[i] ? m_awlen    : 'x;
        assign m_axi4[i].awsize   = m_awvalid[i] ? m_awsize   : 'x;
        assign m_axi4[i].awburst  = m_awvalid[i] ? m_awburst  : 'x;
        assign m_axi4[i].awlock   = m_awvalid[i] ? m_awlock   : 'x;
        assign m_axi4[i].awcache  = m_awvalid[i] ? m_awcache  : 'x;
        assign m_axi4[i].awprot   = m_awvalid[i] ? m_awprot   : 'x;
        assign m_axi4[i].awqos    = m_awvalid[i] ? m_awqos    : 'x;
        assign m_axi4[i].awregion = m_awvalid[i] ? m_awregion : 'x;
        assign m_axi4[i].awuser   = m_awvalid[i] ? m_awuser   : 'x;
        assign m_axi4[i].awvalid  = m_awvalid[i];
        assign m_axi4[i].wdata    = m_wvalid[i]  ? m_wdata    : 'x;
        assign m_axi4[i].wstrb    = m_wvalid[i]  ? m_wstrb    : 'x;
        assign m_axi4[i].wlast    = m_wvalid[i]  ? m_wlast    : 'x;
        assign m_axi4[i].wuser    = m_wvalid[i]  ? m_wuser    : 'x;
        assign m_axi4[i].wvalid   = m_wvalid[i];
        assign m_axi4[i].bready   = 1'b1;   // 前のコマンドが終わらないと次を要求しないので常に受け取れる
    end

    assign s_axi4.awready = (s_axi4.wvalid  && (!write_busy || (s_axi4.bvalid && s_axi4.bready)));
    assign s_axi4.wready  = (s_axi4.awvalid && (!write_busy || (s_axi4.bvalid && s_axi4.bready))) || |(w_maskbit & (~m_wvalid | m_wready));



    // read channel
    logic       m_arready   [NUM+1];
    id_t        m_rid       [NUM+1];
    data_t      m_rdata     [NUM+1];
    resp_t      m_rresp     [NUM+1];
    logic       m_rlast     [NUM+1];
    ruser_t     m_ruser     [NUM+1];
    logic       m_rvalid    [NUM+1];
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_arready[i] = m_axi4[i].arready;
        assign m_rid    [i] = m_axi4[i].rid;
        assign m_rdata  [i] = m_axi4[i].rdata;
        assign m_rresp  [i] = m_axi4[i].rresp;
        assign m_rlast  [i] = m_axi4[i].rlast;
        assign m_ruser  [i] = m_axi4[i].ruser;
        assign m_rvalid [i] = m_axi4[i].rvalid;
    end

    logic               read_busy   ;
    id_t                m_arid      ;
    addr_t              m_araddr    ;
    len_t               m_arlen     ;
    size_t              m_arsize    ;
    burst_t             m_arburst   ;
    lock_t              m_arlock    ;
    cache_t             m_arcache   ;
    prot_t              m_arprot    ;
    qos_t               m_arqos     ;
    region_t            m_arregion  ;
    aruser_t            m_aruser    ;
    logic   [NUM:0]     m_arvalid   ;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            read_busy  <= 1'b0;

            m_arid     <= 'x;
            m_araddr   <= 'x;
            m_arlen    <= 'x;
            m_arsize   <= 'x;
            m_arburst  <= 'x;
            m_arlock   <= 'x;
            m_arcache  <= 'x;
            m_arprot   <= 'x;
            m_arqos    <= 'x;
            m_arregion <= 'x;
            m_aruser   <= 'x;
            for ( int i = 0; i < NUM+1; i++ ) begin
                m_arvalid[i] <= 1'b0;
            end

            s_axi4.rid    <= 'x;
            s_axi4.rdata  <= 'x;
            s_axi4.rresp  <= 'x;
            s_axi4.rlast  <= 'x;
            s_axi4.ruser  <= 'x;
            s_axi4.rvalid <= 1'b0;
        end
        else begin
            // finish
            for ( int i = 0; i < NUM+1; i++ ) begin
                if ( m_arready[i] ) begin
                    m_arvalid[i] <= 1'b0;
                end
            end
            if ( s_axi4.rready ) begin
                s_axi4.rvalid <= 1'b0;
            end
            if ( s_axi4.rlast && s_axi4.rvalid && s_axi4.rready ) begin
                read_busy     <= 1'b0;
                s_axi4.rid    <= 'x;
                s_axi4.rdata  <= 'x;
                s_axi4.rresp  <= 'x;
                s_axi4.rlast  <= 'x;
                s_axi4.ruser  <= 'x;
                s_axi4.rvalid <= 1'b0;
            end

            // start
            if ( s_axi4.arvalid && s_axi4.arready ) begin
                read_busy  <= 1'b1;
                m_arid     <= s_axi4.arid       ;
                m_araddr   <= s_axi4.araddr     ;
                m_arlen    <= s_axi4.arlen      ;
                m_arsize   <= s_axi4.arsize     ;
                m_arburst  <= s_axi4.arburst    ;
                m_arlock   <= s_axi4.arlock     ;
                m_arcache  <= s_axi4.arcache    ;
                m_arprot   <= s_axi4.arprot     ;
                m_arqos    <= s_axi4.arqos      ;
                m_arregion <= s_axi4.arregion   ;
                m_aruser   <= s_axi4.aruser     ;
                for ( int i = 0; i < NUM+1; i++ ) begin
                    if ( araddr_match[i] ) begin
                        m_arvalid[i] <= 1'b1;
                    end
                end
            end

            // response
            for ( int i = 0; i < NUM+1; i++ ) begin
                if ( m_rvalid[i] && (!s_axi4.rvalid || s_axi4.rready) ) begin
                    s_axi4.rid    <= m_rid  [i];
                    s_axi4.rdata  <= m_rdata[i];
                    s_axi4.rresp  <= m_rresp[i];
                    s_axi4.rlast  <= m_rlast[i];
                    s_axi4.ruser  <= m_ruser[i];
                    s_axi4.rvalid <= 1'b1;
                end
            end
        end
    end

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4[i].arid     = m_arvalid[i] ? m_arid     : 'x;
        assign m_axi4[i].araddr   = m_arvalid[i] ? m_araddr   : 'x;
        assign m_axi4[i].arlen    = m_arvalid[i] ? m_arlen    : 'x;
        assign m_axi4[i].arsize   = m_arvalid[i] ? m_arsize   : 'x;
        assign m_axi4[i].arburst  = m_arvalid[i] ? m_arburst  : 'x;
        assign m_axi4[i].arlock   = m_arvalid[i] ? m_arlock   : 'x;
        assign m_axi4[i].arcache  = m_arvalid[i] ? m_arcache  : 'x;
        assign m_axi4[i].arprot   = m_arvalid[i] ? m_arprot   : 'x;
        assign m_axi4[i].arqos    = m_arvalid[i] ? m_arqos    : 'x;
        assign m_axi4[i].arregion = m_arvalid[i] ? m_arregion : 'x;
        assign m_axi4[i].aruser   = m_arvalid[i] ? m_aruser   : 'x;
        assign m_axi4[i].arvalid  = m_arvalid[i];
        assign m_axi4[i].rready   = !s_axi4.rvalid || s_axi4.rready;
    end

    assign s_axi4.arready = !read_busy || (s_axi4.rlast && s_axi4.rvalid && s_axi4.rready);


    // other address
    jelly3_axi4_if
            #(
                .ID_BITS            (s_axi4.ID_BITS         ),
                .ADDR_BITS          (s_axi4.ADDR_BITS       ),
                .DATA_BITS          (s_axi4.DATA_BITS       ),
                .BYTE_BITS          (s_axi4.BYTE_BITS       ),
                .STRB_BITS          (s_axi4.STRB_BITS       ),
                .LEN_BITS           (s_axi4.LEN_BITS        ),
                .SIZE_BITS          (s_axi4.SIZE_BITS       ),
                .BURST_BITS         (s_axi4.BURST_BITS      ),
                .LOCK_BITS          (s_axi4.LOCK_BITS       ),
                .CACHE_BITS         (s_axi4.CACHE_BITS      ),
                .PROT_BITS          (s_axi4.PROT_BITS       ),
                .QOS_BITS           (s_axi4.QOS_BITS        ),
                .REGION_BITS        (s_axi4.REGION_BITS     ),
                .RESP_BITS          (s_axi4.RESP_BITS       ),
                .USE_ID             (s_axi4.USE_ID          ),
                .USE_SIZE           (s_axi4.USE_SIZE        ),
                .USE_BURST          (s_axi4.USE_BURST       ),
                .USE_LOCK           (s_axi4.USE_LOCK        ),
                .USE_CACHE          (s_axi4.USE_CACHE       ),
                .USE_PROT           (s_axi4.USE_PROT        ),
                .USE_QOS            (s_axi4.USE_QOS         ),
                .USE_REGION         (s_axi4.USE_REGION      ),
                .USE_RESP           (s_axi4.USE_RESP        ),
                .USE_USER           (s_axi4.USE_USER        ),
                .USER_REQ_BITS      (s_axi4.USER_REQ_BITS   ),
                .USER_DATA_BITS     (s_axi4.USER_DATA_BITS  ),
                .USER_RESP_BITS     (s_axi4.USER_RESP_BITS  ),
                .AWUSER_BITS        (s_axi4.AWUSER_BITS     ),
                .WUSER_BITS         (s_axi4.WUSER_BITS      ),
                .BUSER_BITS         (s_axi4.BUSER_BITS      ),
                .ARUSER_BITS        (s_axi4.ARUSER_BITS     ),
                .RUSER_BITS         (s_axi4.RUSER_BITS      ),
                .LIMIT_AW           (s_axi4.LIMIT_AW        ),
                .LIMIT_W            (s_axi4.LIMIT_W         ),
                .LIMIT_WC           (s_axi4.LIMIT_WC        ),
                .LIMIT_AR           (s_axi4.LIMIT_AR        ),
                .LIMIT_R            (s_axi4.LIMIT_R         ),
                .LIMIT_RC           (s_axi4.LIMIT_RC        ),
                .ALLOW_WDATA_X      (s_axi4.ALLOW_WDATA_X   ),
                .ALLOW_RDATA_X      (s_axi4.ALLOW_RDATA_X   )
            )
        ax4_other
            (
                .aresetn            (s_axi4.aresetn         ),
                .aclk               (s_axi4.aclk            ),
                .aclken             (s_axi4.aclken          )
            );

    assign ax4_other.awid     = m_awid          ;
    assign ax4_other.awaddr   = m_awaddr        ;
    assign ax4_other.awlen    = m_awlen         ;
    assign ax4_other.awsize   = m_awsize        ;
    assign ax4_other.awburst  = m_awburst       ;
    assign ax4_other.awlock   = m_awlock        ;
    assign ax4_other.awcache  = m_awcache       ;
    assign ax4_other.awprot   = m_awprot        ;
    assign ax4_other.awqos    = m_awqos         ;
    assign ax4_other.awregion = m_awregion      ;
    assign ax4_other.awuser   = m_awuser        ;
    assign ax4_other.awvalid  = m_awvalid [NUM] ;
    assign ax4_other.wdata    = m_wdata         ;
    assign ax4_other.wstrb    = m_wstrb         ;
    assign ax4_other.wlast    = m_wlast         ;
    assign ax4_other.wuser    = m_wuser         ;
    assign ax4_other.wvalid   = m_wvalid  [NUM] ;
    assign ax4_other.bready   = 1'b1            ;
    assign ax4_other.arid     = m_arid          ;
    assign ax4_other.araddr   = m_araddr        ;
    assign ax4_other.arlen    = m_arlen         ;
    assign ax4_other.arsize   = m_arsize        ;
    assign ax4_other.arburst  = m_arburst       ;
    assign ax4_other.arlock   = m_arlock        ;
    assign ax4_other.arcache  = m_arcache       ;
    assign ax4_other.arprot   = m_arprot        ;
    assign ax4_other.arqos    = m_arqos         ;
    assign ax4_other.arregion = m_arregion      ;
    assign ax4_other.aruser   = m_aruser        ;
    assign ax4_other.arvalid  = m_arvalid [NUM] ;
    assign ax4_other.rready   = !s_axi4.rvalid || s_axi4.rready;

    assign m_awready[NUM] = ax4_other.awready  ;
    assign m_wready [NUM] = ax4_other.wready   ;
    assign m_bid    [NUM] = ax4_other.bid      ;
    assign m_bresp  [NUM] = ax4_other.bresp    ;
    assign m_buser  [NUM] = ax4_other.buser    ;
    assign m_bvalid [NUM] = ax4_other.bvalid   ;
    assign m_arready[NUM] = ax4_other.arready  ;
    assign m_rid    [NUM] = ax4_other.rid      ;
    assign m_rdata  [NUM] = ax4_other.rdata    ;
    assign m_rresp  [NUM] = ax4_other.rresp    ;
    assign m_rlast  [NUM] = ax4_other.rlast    ;
    assign m_ruser  [NUM] = ax4_other.ruser    ;
    assign m_rvalid [NUM] = ax4_other.rvalid   ;

    jelly3_axi4_terminator
            #(
                .READ_VALUE ('0             )
            )
        u_axi4_terminator
            (
                .s_axi4     (ax4_other.s    )
            );


`ifdef __SIMULATION__
    initial begin
        if ( s_axi4.ADDR_BITS != m_axi4[0].ADDR_BITS ) begin
            $display("ERROR: ADDR_BITS mismatch");
            $finish;
        end
        if ( s_axi4.DATA_BITS != m_axi4[0].DATA_BITS ) begin
            $display("ERROR: DATA_BITS mismatch");
            $finish;
        end
    end
`endif


endmodule


`default_nettype wire


// end of file
