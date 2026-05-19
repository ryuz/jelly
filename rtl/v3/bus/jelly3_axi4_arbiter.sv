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

    // 何も転送してないか、前の転送が終わるときに aw と w の両方揃ってる一番小さい添え字を選択する
    // wlast が来るまでは同じ添え字を選択し続ける為に wbusy と wsel を使う

    logic       wbusy   ;
    sel_idx_t   wsel    ;

    logic aw_ready  ;
    logic w_ready   ;
    assign aw_ready = !m_axi4.awvalid || m_axi4.awready;
    assign w_ready  = !wbusy && (!m_axi4.wvalid || m_axi4.wready);

    always_comb begin
        s_axi4_awready = '0;
        s_axi4_wready  = '0;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( aw_ready && w_ready && s_axi4_awvalid[i] && s_axi4_wvalid[i] ) begin
                s_axi4_awready[i] = 1'b1;
                s_axi4_wready [i] = 1'b1;
                break;
            end
        end
        if ( wbusy ) begin
            s_axi4_wready[wsel] = !m_axi4.wvalid || m_axi4.wready;
        end
    end

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            m_axi4.awid     <= 'x;
            m_axi4.awaddr   <= 'x;
            m_axi4.awlen    <= 'x;
            m_axi4.awsize   <= 'x;
            m_axi4.awburst  <= 'x;
            m_axi4.awlock   <= 'x;
            m_axi4.awcache  <= 'x;
            m_axi4.awprot   <= 'x;
            m_axi4.awqos    <= 'x;
            m_axi4.awregion <= 'x;
            m_axi4.awuser   <= 'x;
            m_axi4.awvalid  <= 1'b0;
            m_axi4.wdata    <= 'x;
            m_axi4.wstrb    <= 'x;
            m_axi4.wlast    <= 'x;
            m_axi4.wuser    <= 'x;
            m_axi4.wvalid   <= 1'b0;
            wbusy <= 1'b0;
            wsel  <= 'x;
        end
        else if ( m_axi4.aclken ) begin
            if ( m_axi4.awready ) begin
                m_axi4.awvalid  <= 1'b0;
            end
            if ( m_axi4.wready ) begin
                m_axi4.wvalid  <= 1'b0;
            end

            if ( aw_ready && w_ready ) begin
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( s_axi4_awvalid[i] && s_axi4_wvalid[i] ) begin
                        wbusy <= 1'b1;
                        wsel  <= sel_idx_t'(i);
                        m_axi4.awid     <= (s_axi4_awid[i] << SEL_BITS) | id_t'(i);
                        m_axi4.awaddr   <= s_axi4_awaddr  [i];
                        m_axi4.awlen    <= s_axi4_awlen   [i];
                        m_axi4.awsize   <= s_axi4_awsize  [i];
                        m_axi4.awburst  <= s_axi4_awburst [i];
                        m_axi4.awlock   <= s_axi4_awlock  [i];
                        m_axi4.awcache  <= s_axi4_awcache [i];
                        m_axi4.awprot   <= s_axi4_awprot  [i];
                        m_axi4.awqos    <= s_axi4_awqos   [i];
                        m_axi4.awregion <= s_axi4_awregion[i];
                        m_axi4.awuser   <= s_axi4_awuser  [i];
                        m_axi4.awvalid  <= 1'b1;
                        m_axi4.wdata    <= s_axi4_wdata  [i];
                        m_axi4.wstrb    <= s_axi4_wstrb  [i];
                        m_axi4.wlast    <= s_axi4_wlast  [i];
                        m_axi4.wuser    <= s_axi4_wuser  [i];
                        m_axi4.wvalid   <= 1'b1;
                        break;
                    end
                end
            end

            if ( wbusy ) begin
                if ( !m_axi4.wvalid || m_axi4.wready ) begin
                    m_axi4.wdata  <= s_axi4_wdata  [wsel];
                    m_axi4.wstrb  <= s_axi4_wstrb  [wsel];
                    m_axi4.wlast  <= s_axi4_wlast  [wsel];
                    m_axi4.wuser  <= s_axi4_wuser  [wsel];
                    m_axi4.wvalid <= s_axi4_wvalid [wsel];
                    if ( s_axi4_wvalid[wsel] && s_axi4_wlast[wsel] ) begin
                        wbusy <= 1'b0;
                    end
                end
            end
        end
    end

    sel_idx_t   bsel    ;
    assign bsel = sel_idx_t'(m_axi4.bid & SEL_MASK);

    assign m_axi4.bready = s_axi4_bready[bsel];
    always_comb begin
        for ( int i = 0; i < NUM; i++ ) begin
            s_axi4_bresp [i] = m_axi4.bresp;
            s_axi4_buser [i] = m_axi4.buser;
            s_axi4_bvalid[i] = m_axi4.bvalid && (bsel == sel_idx_t'(i));
        end
    end



    // read arbiter
    // read はシンプルに添え字の小さい方から順に処理する
    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            m_axi4.arid     <= 'x;
            m_axi4.araddr   <= 'x;
            m_axi4.arlen    <= 'x;
            m_axi4.arsize   <= 'x;
            m_axi4.arburst  <= 'x;
            m_axi4.arlock   <= 'x;
            m_axi4.arcache  <= 'x;
            m_axi4.arprot   <= 'x;
            m_axi4.arqos    <= 'x;
            m_axi4.arregion <= 'x;
            m_axi4.aruser   <= 'x;
            m_axi4.arvalid  <= 1'b0;
        end
        else if ( m_axi4.aclken ) begin
            if ( m_axi4.arready ) begin
                m_axi4.arvalid  <= 1'b0;
            end

            if ( !m_axi4.arvalid || m_axi4.arready ) begin
                for ( int i = 0; i < NUM; i++ ) begin
                    if ( s_axi4_arvalid[i] ) begin
                        m_axi4.arid     <= (s_axi4_arid[i] << SEL_BITS) | id_t'(i);
                        m_axi4.araddr   <= s_axi4_araddr  [i];
                        m_axi4.arlen    <= s_axi4_arlen   [i];
                        m_axi4.arsize   <= s_axi4_arsize  [i];
                        m_axi4.arburst  <= s_axi4_arburst [i];
                        m_axi4.arlock   <= s_axi4_arlock  [i];
                        m_axi4.arcache  <= s_axi4_arcache [i];
                        m_axi4.arprot   <= s_axi4_arprot  [i];
                        m_axi4.arqos    <= s_axi4_arqos   [i];
                        m_axi4.arregion <= s_axi4_arregion[i];
                        m_axi4.aruser   <= s_axi4_aruser  [i];
                        m_axi4.arvalid  <= 1'b1;
                        break;
                    end
                end
            end
        end
    end

    sel_idx_t   rsel    ;
    assign rsel = sel_idx_t'(m_axi4.rid & SEL_MASK);

    assign m_axi4.rready = s_axi4_rready[bsel];
    always_comb begin
        for ( int i = 0; i < NUM; i++ ) begin
            s_axi4_rresp [i] = m_axi4.rresp;
            s_axi4_rlast [i] = m_axi4.rlast;
            s_axi4_rdata [i] = m_axi4.rdata;
            s_axi4_ruser [i] = m_axi4.ruser;
            s_axi4_rvalid[i] = m_axi4.rvalid && (bsel == sel_idx_t'(i));
        end
    end




endmodule


`default_nettype wire


// end of file
