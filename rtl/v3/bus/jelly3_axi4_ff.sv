// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_ff
        #(
            parameter   bit     S_REG       = 1         ,
            parameter   bit     M_REG       = 1         ,
            parameter           SIMULATION  = "false"   
        )
        (
            jelly3_axi4_if.s    s_axi4,
            jelly3_axi4_if.m    m_axi4
        );

    localparam  type    id_t     = logic [m_axi4.ID_BITS    -1:0];
    localparam  type    addr_t   = logic [m_axi4.ADDR_BITS  -1:0];
    localparam  type    len_t    = logic [m_axi4.LEN_BITS   -1:0];
    localparam  type    size_t   = logic [m_axi4.SIZE_BITS  -1:0];
    localparam  type    burst_t  = logic [m_axi4.BURST_BITS -1:0];
    localparam  type    lock_t   = logic [m_axi4.LOCK_BITS  -1:0];
    localparam  type    cache_t  = logic [m_axi4.CACHE_BITS -1:0];
    localparam  type    prot_t   = logic [m_axi4.PROT_BITS  -1:0];
    localparam  type    qos_t    = logic [m_axi4.QOS_BITS   -1:0];
    localparam  type    region_t = logic [m_axi4.REGION_BITS-1:0];
    localparam  type    data_t   = logic [m_axi4.DATA_BITS  -1:0];
    localparam  type    strb_t   = logic [m_axi4.STRB_BITS  -1:0];
    localparam  type    resp_t   = logic [m_axi4.RESP_BITS  -1:0];
    localparam  type    awuser_t = logic [m_axi4.AWUSER_BITS-1:0];
    localparam  type    wuser_t  = logic [m_axi4.WUSER_BITS -1:0];
    localparam  type    buser_t  = logic [m_axi4.BUSER_BITS -1:0];
    localparam  type    aruser_t = logic [m_axi4.ARUSER_BITS-1:0];
    localparam  type    ruser_t  = logic [m_axi4.RUSER_BITS -1:0];

    typedef struct packed {
        id_t        id      ;
        addr_t      addr    ;
        len_t       len     ;
        size_t      size    ;
        burst_t     burst   ;
        lock_t      lock    ;
        cache_t     cache   ;
        prot_t      prot    ;
        qos_t       qos     ;
        region_t    region  ;
        awuser_t    user    ;
    } aw_t;

    typedef struct packed {
        data_t      data    ;
        strb_t      strb    ;
        logic       last    ;
        wuser_t     user    ;
    } w_t;

    typedef struct packed {
        id_t        id      ;
        resp_t      resp    ;
        buser_t     user    ;
    } b_t;

    typedef struct packed {
        id_t        id      ;
        addr_t      addr    ;
        len_t       len     ;
        size_t      size    ;
        burst_t     burst   ;
        lock_t      lock    ;
        cache_t     cache   ;
        prot_t      prot    ;
        qos_t       qos     ;
        region_t    region  ;
        aruser_t    user    ;
    } ar_t;

    typedef struct packed {
        id_t        id      ;
        data_t      data    ;
        resp_t      resp    ;
        logic       last    ;
        ruser_t     user    ;
    } r_t;


    // write address channel (AW)
    aw_t    aw_s_data;
    aw_t    aw_m_data;

    assign aw_s_data.id     = s_axi4.awid     ;
    assign aw_s_data.addr   = s_axi4.awaddr   ;
    assign aw_s_data.len    = s_axi4.awlen    ;
    assign aw_s_data.size   = s_axi4.awsize   ;
    assign aw_s_data.burst  = s_axi4.awburst  ;
    assign aw_s_data.lock   = s_axi4.awlock   ;
    assign aw_s_data.cache  = s_axi4.awcache  ;
    assign aw_s_data.prot   = s_axi4.awprot   ;
    assign aw_s_data.qos    = s_axi4.awqos    ;
    assign aw_s_data.region = s_axi4.awregion ;
    assign aw_s_data.user   = s_axi4.awuser   ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(aw_t) ),
                .data_t         (aw_t        ),
                .S_REG          (S_REG       ),
                .M_REG          (M_REG       )
            )
        u_stream_ff_aw
            (
                .reset          (~s_axi4.aresetn),
                .clk            (s_axi4.aclk    ),
                .cke            (s_axi4.aclken  ),
                .s_data         (aw_s_data      ),
                .s_valid        (s_axi4.awvalid ),
                .s_ready        (s_axi4.awready ),
                .m_data         (aw_m_data      ),
                .m_valid        (m_axi4.awvalid ),
                .m_ready        (m_axi4.awready )
            );

    assign m_axi4.awid     = aw_m_data.id     ;
    assign m_axi4.awaddr   = aw_m_data.addr   ;
    assign m_axi4.awlen    = aw_m_data.len    ;
    assign m_axi4.awsize   = aw_m_data.size   ;
    assign m_axi4.awburst  = aw_m_data.burst  ;
    assign m_axi4.awlock   = aw_m_data.lock   ;
    assign m_axi4.awcache  = aw_m_data.cache  ;
    assign m_axi4.awprot   = aw_m_data.prot   ;
    assign m_axi4.awqos    = aw_m_data.qos    ;
    assign m_axi4.awregion = aw_m_data.region ;
    assign m_axi4.awuser   = aw_m_data.user   ;


    // write data channel (W)
    w_t     w_s_data;
    w_t     w_m_data;

    assign w_s_data.data = s_axi4.wdata ;
    assign w_s_data.strb = s_axi4.wstrb ;
    assign w_s_data.last = s_axi4.wlast ;
    assign w_s_data.user = s_axi4.wuser ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(w_t)  ),
                .data_t         (w_t         ),
                .S_REG          (S_REG       ),
                .M_REG          (M_REG       )
            )
        u_stream_ff_w
            (
                .reset          (~s_axi4.aresetn),
                .clk            (s_axi4.aclk    ),
                .cke            (s_axi4.aclken  ),
                .s_data         (w_s_data       ),
                .s_valid        (s_axi4.wvalid  ),
                .s_ready        (s_axi4.wready  ),
                .m_data         (w_m_data       ),
                .m_valid        (m_axi4.wvalid  ),
                .m_ready        (m_axi4.wready  )
            );

    assign m_axi4.wdata = w_m_data.data ;
    assign m_axi4.wstrb = w_m_data.strb ;
    assign m_axi4.wlast = w_m_data.last ;
    assign m_axi4.wuser = w_m_data.user ;


    // write response channel (B)
    b_t     b_s_data;
    b_t     b_m_data;

    assign b_s_data.id   = m_axi4.bid   ;
    assign b_s_data.resp = m_axi4.bresp ;
    assign b_s_data.user = m_axi4.buser ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(b_t)  ),
                .data_t         (b_t         ),
                .S_REG          (S_REG       ),
                .M_REG          (M_REG       )
            )
        u_stream_ff_b
            (
                .reset          (~s_axi4.aresetn),
                .clk            (s_axi4.aclk    ),
                .cke            (s_axi4.aclken  ),
                .s_data         (b_s_data       ),
                .s_valid        (m_axi4.bvalid  ),
                .s_ready        (m_axi4.bready  ),
                .m_data         (b_m_data       ),
                .m_valid        (s_axi4.bvalid  ),
                .m_ready        (s_axi4.bready  )
            );

    assign s_axi4.bid   = b_m_data.id   ;
    assign s_axi4.bresp = b_m_data.resp ;
    assign s_axi4.buser = b_m_data.user ;


    // read address channel (AR)
    ar_t    ar_s_data;
    ar_t    ar_m_data;

    assign ar_s_data.id     = s_axi4.arid     ;
    assign ar_s_data.addr   = s_axi4.araddr   ;
    assign ar_s_data.len    = s_axi4.arlen    ;
    assign ar_s_data.size   = s_axi4.arsize   ;
    assign ar_s_data.burst  = s_axi4.arburst  ;
    assign ar_s_data.lock   = s_axi4.arlock   ;
    assign ar_s_data.cache  = s_axi4.arcache  ;
    assign ar_s_data.prot   = s_axi4.arprot   ;
    assign ar_s_data.qos    = s_axi4.arqos    ;
    assign ar_s_data.region = s_axi4.arregion ;
    assign ar_s_data.user   = s_axi4.aruser   ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(ar_t) ),
                .data_t         (ar_t        ),
                .S_REG          (S_REG       ),
                .M_REG          (M_REG       )
            )
        u_stream_ff_ar
            (
                .reset          (~s_axi4.aresetn),
                .clk            (s_axi4.aclk    ),
                .cke            (s_axi4.aclken  ),
                .s_data         (ar_s_data      ),
                .s_valid        (s_axi4.arvalid ),
                .s_ready        (s_axi4.arready ),
                .m_data         (ar_m_data      ),
                .m_valid        (m_axi4.arvalid ),
                .m_ready        (m_axi4.arready )
            );

    assign m_axi4.arid     = ar_m_data.id     ;
    assign m_axi4.araddr   = ar_m_data.addr   ;
    assign m_axi4.arlen    = ar_m_data.len    ;
    assign m_axi4.arsize   = ar_m_data.size   ;
    assign m_axi4.arburst  = ar_m_data.burst  ;
    assign m_axi4.arlock   = ar_m_data.lock   ;
    assign m_axi4.arcache  = ar_m_data.cache  ;
    assign m_axi4.arprot   = ar_m_data.prot   ;
    assign m_axi4.arqos    = ar_m_data.qos    ;
    assign m_axi4.arregion = ar_m_data.region ;
    assign m_axi4.aruser   = ar_m_data.user   ;


    // read data channel (R)
    r_t     r_s_data;
    r_t     r_m_data;

    assign r_s_data.id   = m_axi4.rid   ;
    assign r_s_data.data = m_axi4.rdata ;
    assign r_s_data.resp = m_axi4.rresp ;
    assign r_s_data.last = m_axi4.rlast ;
    assign r_s_data.user = m_axi4.ruser ;

    jelly3_stream_ff
            #(
                .DATA_BITS      ($bits(r_t)  ),
                .data_t         (r_t         ),
                .S_REG          (S_REG       ),
                .M_REG          (M_REG       )
            )
        u_stream_ff_r
            (
                .reset          (~s_axi4.aresetn),
                .clk            (s_axi4.aclk    ),
                .cke            (s_axi4.aclken  ),
                .s_data         (r_s_data       ),
                .s_valid        (m_axi4.rvalid  ),
                .s_ready        (m_axi4.rready  ),
                .m_data         (r_m_data       ),
                .m_valid        (s_axi4.rvalid  ),
                .m_ready        (s_axi4.rready  )
            );

    assign s_axi4.rid   = r_m_data.id   ;
    assign s_axi4.rdata = r_m_data.data ;
    assign s_axi4.rresp = r_m_data.resp ;
    assign s_axi4.rlast = r_m_data.last ;
    assign s_axi4.ruser = r_m_data.user ;


    if ( SIMULATION == "true" ) begin
        always_comb begin
            sva_resetn : assert (s_axi4.aresetn === m_axi4.aresetn);
            sva_clk    : assert (s_axi4.aclk    === m_axi4.aclk   );
            sva_cke    : assert (s_axi4.aclken  === m_axi4.aclken );
        end
    end

endmodule


`default_nettype wire


// end of file
