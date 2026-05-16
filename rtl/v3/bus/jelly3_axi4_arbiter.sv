// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// 固定優先度 で s_axi4 の添え字の小さい方が優先度高
// s_axi4 の どのポートからのアクセスを m_axi4 の id の下位 bit に付与する
// m_axi4 側の id 幅を十分なサイズ確保するのはユーザーの責任とする(s_axi4 側の id の上位ビットがゼロ固定とするなども含む)


module jelly3_axi4_arbiter
        #(
            parameter   int     NUM = 4
        )
        (
            jelly3_axi4_if.s    s_axi4 [NUM],
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

    localparam  int     SEL_BITS = $clog2(NUM);
    localparam  int     SEL_IDX_BITS = NUM > 1 ? $clog2(NUM) : 1;
    typedef logic [SEL_IDX_BITS-1:0] sel_idx_t;

    localparam  id_t    SEL_MASK = id_t'((1 << SEL_BITS) - 1);


    // assign for packed array
    id_t      [NUM-1:0] s_axi4_awid      ;
    addr_t    [NUM-1:0] s_axi4_awaddr    ;
    len_t     [NUM-1:0] s_axi4_awlen     ;
    size_t    [NUM-1:0] s_axi4_awsize    ;
    burst_t   [NUM-1:0] s_axi4_awburst   ;
    lock_t    [NUM-1:0] s_axi4_awlock    ;
    cache_t   [NUM-1:0] s_axi4_awcache   ;
    prot_t    [NUM-1:0] s_axi4_awprot    ;
    qos_t     [NUM-1:0] s_axi4_awqos     ;
    region_t  [NUM-1:0] s_axi4_awregion  ;
    awuser_t  [NUM-1:0] s_axi4_awuser    ;
    logic     [NUM-1:0] s_axi4_awvalid   ;
    logic     [NUM-1:0] s_axi4_awready   ;
    data_t    [NUM-1:0] s_axi4_wdata     ;
    strb_t    [NUM-1:0] s_axi4_wstrb     ;
    logic     [NUM-1:0] s_axi4_wlast     ;
    wuser_t   [NUM-1:0] s_axi4_wuser     ;
    logic     [NUM-1:0] s_axi4_wvalid    ;
    logic     [NUM-1:0] s_axi4_wready    ;
    id_t      [NUM-1:0] s_axi4_bid       ;
    resp_t    [NUM-1:0] s_axi4_bresp     ;
    buser_t   [NUM-1:0] s_axi4_buser     ;
    logic     [NUM-1:0] s_axi4_bvalid    ;
    logic     [NUM-1:0] s_axi4_bready    ;
    id_t      [NUM-1:0] s_axi4_arid      ;
    addr_t    [NUM-1:0] s_axi4_araddr    ;
    len_t     [NUM-1:0] s_axi4_arlen     ;
    size_t    [NUM-1:0] s_axi4_arsize    ;
    burst_t   [NUM-1:0] s_axi4_arburst   ;
    lock_t    [NUM-1:0] s_axi4_arlock    ;
    cache_t   [NUM-1:0] s_axi4_arcache   ;
    prot_t    [NUM-1:0] s_axi4_arprot    ;
    qos_t     [NUM-1:0] s_axi4_arqos     ;
    region_t  [NUM-1:0] s_axi4_arregion  ;
    aruser_t  [NUM-1:0] s_axi4_aruser    ;
    logic     [NUM-1:0] s_axi4_arvalid   ;
    logic     [NUM-1:0] s_axi4_arready   ;
    id_t      [NUM-1:0] s_axi4_rid       ;
    data_t    [NUM-1:0] s_axi4_rdata     ;
    resp_t    [NUM-1:0] s_axi4_rresp     ;
    logic     [NUM-1:0] s_axi4_rlast     ;
    ruser_t   [NUM-1:0] s_axi4_ruser     ;
    logic     [NUM-1:0] s_axi4_rvalid    ;
    logic     [NUM-1:0] s_axi4_rready    ;
    for ( genvar i = 0; i < NUM; i++ ) begin : s_assign
        assign s_axi4_awid    [i] = s_axi4[i].awid   ;
        assign s_axi4_awaddr  [i] = s_axi4[i].awaddr ;
        assign s_axi4_awlen   [i] = s_axi4[i].awlen  ;
        assign s_axi4_awsize  [i] = s_axi4[i].awsize ;
        assign s_axi4_awburst [i] = s_axi4[i].awburst;
        assign s_axi4_awlock  [i] = s_axi4[i].awlock ;
        assign s_axi4_awcache [i] = s_axi4[i].awcache;
        assign s_axi4_awprot  [i] = s_axi4[i].awprot ;
        assign s_axi4_awqos   [i] = s_axi4[i].awqos  ;
        assign s_axi4_awregion[i] = s_axi4[i].awregion;
        assign s_axi4_awuser  [i] = s_axi4[i].awuser ;
        assign s_axi4_awvalid [i] = s_axi4[i].awvalid;
        assign s_axi4_wdata   [i] = s_axi4[i].wdata  ;
        assign s_axi4_wstrb   [i] = s_axi4[i].wstrb  ;
        assign s_axi4_wlast   [i] = s_axi4[i].wlast  ;
        assign s_axi4_wuser   [i] = s_axi4[i].wuser  ;
        assign s_axi4_wvalid  [i] = s_axi4[i].wvalid ;
        assign s_axi4_bready  [i] = s_axi4[i].bready ;
        assign s_axi4_arid    [i] = s_axi4[i].arid   ;
        assign s_axi4_araddr  [i] = s_axi4[i].araddr ;
        assign s_axi4_arlen   [i] = s_axi4[i].arlen  ;
        assign s_axi4_arsize  [i] = s_axi4[i].arsize ;
        assign s_axi4_arburst [i] = s_axi4[i].arburst;
        assign s_axi4_arlock  [i] = s_axi4[i].arlock ;
        assign s_axi4_arcache [i] = s_axi4[i].arcache;
        assign s_axi4_arprot  [i] = s_axi4[i].arprot ;
        assign s_axi4_arqos   [i] = s_axi4[i].arqos  ;
        assign s_axi4_arregion[i] = s_axi4[i].arregion;
        assign s_axi4_aruser  [i] = s_axi4[i].aruser ;
        assign s_axi4_arvalid [i] = s_axi4[i].arvalid;
        assign s_axi4_rready  [i] = s_axi4[i].rready ;

        assign s_axi4[i].awready = s_axi4_awready[i];
        assign s_axi4[i].wready  = s_axi4_wready [i];
        assign s_axi4[i].bid     = s_axi4_bid    [i];
        assign s_axi4[i].bresp   = s_axi4_bresp  [i];
        assign s_axi4[i].buser   = s_axi4_buser  [i];
        assign s_axi4[i].bvalid  = s_axi4_bvalid [i];
        assign s_axi4[i].arready = s_axi4_arready[i];
        assign s_axi4[i].rid     = s_axi4_rid    [i];
        assign s_axi4[i].rdata   = s_axi4_rdata  [i];
        assign s_axi4[i].rresp   = s_axi4_rresp  [i];
        assign s_axi4[i].rlast   = s_axi4_rlast  [i];
        assign s_axi4[i].ruser   = s_axi4_ruser  [i];
        assign s_axi4[i].rvalid  = s_axi4_rvalid [i];
    end


    // write arbiter
    logic   write_busy       ;
    sel_idx_t write_sel      ;
    logic   write_sel_valid  ;
    sel_idx_t write_sel_req  ;
    logic   write_start      ;

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            write_busy      <= 1'b0;
            write_sel       <= 'x;
            write_sel_valid <= 1'b0;
            write_sel_req   <= 'x;
        end
        else if ( m_axi4.aclken ) begin
            if ( !write_busy && !write_sel_valid ) begin
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( s_axi4_awvalid[i] && s_axi4_wvalid[i] ) begin
                        write_sel_valid <= 1'b1;
                        write_sel_req   <= sel_idx_t'(i);
                        break;
                    end
                end
            end

            if ( write_sel_valid && !(s_axi4_awvalid[write_sel_req] && s_axi4_wvalid[write_sel_req]) ) begin
                write_sel_valid <= 1'b0;
            end

            if ( write_start ) begin
                write_sel       <= write_sel_req;
                write_busy      <= ~s_axi4_wlast[write_sel_req];
                write_sel_valid <= 1'b0;
            end
            else if ( write_busy && s_axi4_wvalid[write_sel] && m_axi4.wready && s_axi4_wlast[write_sel] ) begin
                write_busy <= 1'b0;
            end
        end
    end

    always_comb begin
        s_axi4_awready = '0;
        s_axi4_wready  = '0;

        if ( write_sel_valid ) begin
            s_axi4_awready[write_sel_req] = m_axi4.awready && m_axi4.wready;
            s_axi4_wready [write_sel_req] = m_axi4.awready && m_axi4.wready;
        end

        if ( write_busy ) begin
            s_axi4_wready[write_sel] = m_axi4.wready;
        end
    end

    assign write_start = write_sel_valid && s_axi4_awvalid[write_sel_req] && s_axi4_wvalid[write_sel_req]
                            && m_axi4.awready && m_axi4.wready;

    assign m_axi4.awid     = (s_axi4_awid[write_sel_req] << SEL_BITS) | id_t'(write_sel_req);
    assign m_axi4.awaddr   = s_axi4_awaddr  [write_sel_req]                                           ;
    assign m_axi4.awlen    = s_axi4_awlen   [write_sel_req]                                           ;
    assign m_axi4.awsize   = s_axi4_awsize  [write_sel_req]                                           ;
    assign m_axi4.awburst  = s_axi4_awburst [write_sel_req]                                           ;
    assign m_axi4.awlock   = s_axi4_awlock  [write_sel_req]                                           ;
    assign m_axi4.awcache  = s_axi4_awcache [write_sel_req]                                           ;
    assign m_axi4.awprot   = s_axi4_awprot  [write_sel_req]                                           ;
    assign m_axi4.awqos    = s_axi4_awqos   [write_sel_req]                                           ;
    assign m_axi4.awregion = s_axi4_awregion[write_sel_req]                                           ;
    assign m_axi4.awuser   = s_axi4_awuser  [write_sel_req]                                           ;
    assign m_axi4.awvalid  = write_sel_valid && s_axi4_awvalid[write_sel_req] && s_axi4_wvalid[write_sel_req];

    assign m_axi4.wdata    = write_busy ? s_axi4_wdata [write_sel] : s_axi4_wdata [write_sel_req];
    assign m_axi4.wstrb    = write_busy ? s_axi4_wstrb [write_sel] : s_axi4_wstrb [write_sel_req];
    assign m_axi4.wlast    = write_busy ? s_axi4_wlast [write_sel] : s_axi4_wlast [write_sel_req];
    assign m_axi4.wuser    = write_busy ? s_axi4_wuser [write_sel] : s_axi4_wuser [write_sel_req];
    assign m_axi4.wvalid   = write_busy ? s_axi4_wvalid[write_sel] : (write_sel_valid && s_axi4_awvalid[write_sel_req] && s_axi4_wvalid[write_sel_req]);
    
    // write response route
    sel_idx_t b_sel;
    assign b_sel = m_axi4.bvalid ? sel_idx_t'(m_axi4.bid & SEL_MASK) : sel_idx_t'(0);

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            s_axi4_bid    <= 'x;
            s_axi4_bresp  <= 'x;
            s_axi4_buser  <= 'x;
            s_axi4_bvalid <= '0;
        end
        else if ( m_axi4.aclken ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4_bvalid[i] && s_axi4_bready[i] ) begin
                    s_axi4_bid   [i] <= 'x;
                    s_axi4_bresp [i] <= 'x;
                    s_axi4_buser [i] <= 'x;
                    s_axi4_bvalid[i] <= 1'b0;
                end
            end

            if ( m_axi4.bvalid && (!s_axi4_bvalid[b_sel] || s_axi4_bready[b_sel]) ) begin
                s_axi4_bid   [b_sel] <= m_axi4.bid;
                s_axi4_bresp [b_sel] <= m_axi4.bresp;
                s_axi4_buser [b_sel] <= m_axi4.buser;
                s_axi4_bvalid[b_sel] <= 1'b1;
            end
        end
    end

    assign m_axi4.bready = !s_axi4_bvalid[b_sel] || s_axi4_bready[b_sel];



    // read arbiter
    logic   read_sel_valid;
    sel_idx_t read_sel_req;
    logic   read_start;

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            read_sel_valid <= 1'b0;
            read_sel_req   <= 'x;
        end
        else if ( m_axi4.aclken ) begin
            if ( !read_sel_valid ) begin
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( s_axi4_arvalid[i] ) begin
                        read_sel_valid <= 1'b1;
                        read_sel_req   <= sel_idx_t'(i);
                        break;
                    end
                end
            end

            if ( read_sel_valid && !s_axi4_arvalid[read_sel_req] ) begin
                read_sel_valid <= 1'b0;
            end

            if ( read_start ) begin
                read_sel_valid <= 1'b0;
            end
        end
    end

    always_comb begin
        s_axi4_arready = '0;
        if ( read_sel_valid ) begin
            s_axi4_arready[read_sel_req] = m_axi4.arready;
        end
    end

    assign read_start = read_sel_valid && s_axi4_arvalid[read_sel_req] && m_axi4.arready;

    assign m_axi4.arid     = (s_axi4_arid[read_sel_req] << SEL_BITS) | id_t'(read_sel_req);
    assign m_axi4.araddr   = s_axi4_araddr  [read_sel_req];
    assign m_axi4.arlen    = s_axi4_arlen   [read_sel_req];
    assign m_axi4.arsize   = s_axi4_arsize  [read_sel_req];
    assign m_axi4.arburst  = s_axi4_arburst [read_sel_req];
    assign m_axi4.arlock   = s_axi4_arlock  [read_sel_req];
    assign m_axi4.arcache  = s_axi4_arcache [read_sel_req];
    assign m_axi4.arprot   = s_axi4_arprot  [read_sel_req];
    assign m_axi4.arqos    = s_axi4_arqos   [read_sel_req];
    assign m_axi4.arregion = s_axi4_arregion[read_sel_req];
    assign m_axi4.aruser   = s_axi4_aruser  [read_sel_req];
    assign m_axi4.arvalid  = read_sel_valid && s_axi4_arvalid[read_sel_req];

    // read response route
    sel_idx_t r_sel;
    assign r_sel = m_axi4.rvalid ? sel_idx_t'(m_axi4.rid & SEL_MASK) : sel_idx_t'(0);

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            s_axi4_rid    <= 'x;
            s_axi4_rdata  <= 'x;
            s_axi4_rresp  <= 'x;
            s_axi4_rlast  <= 'x;
            s_axi4_ruser  <= 'x;
            s_axi4_rvalid <= '0;
        end
        else if ( m_axi4.aclken ) begin
            for ( int i = 0; i < NUM; i++ ) begin
                if ( s_axi4_rvalid[i] && s_axi4_rready[i] && s_axi4_rlast[i] ) begin
                    s_axi4_rid   [i] <= 'x;
                    s_axi4_rdata [i] <= 'x;
                    s_axi4_rresp [i] <= 'x;
                    s_axi4_rlast [i] <= 'x;
                    s_axi4_ruser [i] <= 'x;
                    s_axi4_rvalid[i] <= 1'b0;
                end
            end

            if ( m_axi4.rvalid && (!s_axi4_rvalid[r_sel] || s_axi4_rready[r_sel]) ) begin
                s_axi4_rid   [r_sel] <= m_axi4.rid;
                s_axi4_rdata [r_sel] <= m_axi4.rdata;
                s_axi4_rresp [r_sel] <= m_axi4.rresp;
                s_axi4_rlast [r_sel] <= m_axi4.rlast;
                s_axi4_ruser [r_sel] <= m_axi4.ruser;
                s_axi4_rvalid[r_sel] <= 1'b1;
            end
        end
    end

    assign m_axi4.rready = !s_axi4_rvalid[r_sel] || s_axi4_rready[r_sel];


endmodule


`default_nettype wire


// end of file
