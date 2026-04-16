// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_arbiter
        #(
            parameter   int     NUM            = 4,
            parameter   int     FIFO_PTR_BITS  = 4,
            parameter           FIFO_RAM_TYPE  = "distributed",
            parameter   bit     FIFO_DOUT_REG  = 0
        )
        (
            jelly3_axi4_if.s    s_axi4 [NUM],
            jelly3_axi4_if.m    m_axi4
        );

    localparam  int     SEL_BITS = NUM > 1 ? $clog2(NUM) : 1;
    localparam  type    sel_t    = logic [SEL_BITS-1:0];

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


    // response destination queues
    sel_t   bsel_s_data  ;
    logic   bsel_s_valid ;
    logic   bsel_s_ready ;
    sel_t   bsel_m_data  ;
    logic   bsel_m_valid ;
    logic   bsel_m_ready ;
    jelly3_stream_fifo
            #(
                .ASYNC          (0                  ),
                .PTR_BITS       (FIFO_PTR_BITS      ),
                .DATA_BITS      ($bits(sel_t)       ),
                .data_t         (sel_t              ),
                .RAM_TYPE       (FIFO_RAM_TYPE      ),
                .DOUT_REG       (FIFO_DOUT_REG      )
            )
        u_stream_fifo_bsel
            (
                .s_reset        (~m_axi4.aresetn    ),
                .s_clk          (m_axi4.aclk        ),
                .s_cke          (m_axi4.aclken      ),
                .s_data         (bsel_s_data        ),
                .s_valid        (bsel_s_valid       ),
                .s_ready        (bsel_s_ready       ),
                .s_free_size    (                   ),

                .m_reset        (~m_axi4.aresetn    ),
                .m_clk          (m_axi4.aclk        ),
                .m_cke          (m_axi4.aclken      ),
                .m_data         (bsel_m_data        ),
                .m_valid        (bsel_m_valid       ),
                .m_ready        (bsel_m_ready       ),
                .m_data_size    (                   )
            );

    sel_t   rsel_s_data  ;
    logic   rsel_s_valid ;
    logic   rsel_s_ready ;
    sel_t   rsel_m_data  ;
    logic   rsel_m_valid ;
    logic   rsel_m_ready ;
    jelly3_stream_fifo
            #(
                .ASYNC          (0                  ),
                .PTR_BITS       (FIFO_PTR_BITS      ),
                .DATA_BITS      ($bits(sel_t)       ),
                .data_t         (sel_t              ),
                .RAM_TYPE       (FIFO_RAM_TYPE      ),
                .DOUT_REG       (FIFO_DOUT_REG      )
            )
        u_stream_fifo_rsel
            (
                .s_reset        (~m_axi4.aresetn    ),
                .s_clk          (m_axi4.aclk        ),
                .s_cke          (m_axi4.aclken      ),
                .s_data         (rsel_s_data        ),
                .s_valid        (rsel_s_valid       ),
                .s_ready        (rsel_s_ready       ),
                .s_free_size    (                   ),

                .m_reset        (~m_axi4.aresetn    ),
                .m_clk          (m_axi4.aclk        ),
                .m_cke          (m_axi4.aclken      ),
                .m_data         (rsel_m_data        ),
                .m_valid        (rsel_m_valid       ),
                .m_ready        (rsel_m_ready       ),
                .m_data_size    (                   )
            );


    // write arbiter
    logic   write_busy       ;
    sel_t   write_sel        ;
    logic   write_req_valid  ;
    sel_t   write_req_sel    ;
    logic   write_start_ack  ;

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            write_busy      <= 1'b0;
            write_sel       <= 'x;
            write_req_valid <= 1'b0;
            write_req_sel   <= 'x;
        end
        else if ( m_axi4.aclken ) begin
            if ( !write_busy && !write_req_valid ) begin
                if ( bsel_s_ready ) begin
                    for ( int i = 0; i < NUM; i++ ) begin
                        if ( s_axi4_awvalid[i] && s_axi4_wvalid[i] ) begin
                            write_req_valid <= 1'b1;
                            write_req_sel   <= sel_t'(i);
                            break;
                        end
                    end
                end
            end

            if ( write_req_valid && !(s_axi4_awvalid[write_req_sel] && s_axi4_wvalid[write_req_sel]) ) begin
                write_req_valid <= 1'b0;
            end

            if ( write_start_ack ) begin
                write_sel       <= write_req_sel;
                write_busy      <= ~s_axi4_wlast[write_req_sel];
                write_req_valid <= 1'b0;
            end
            else if ( write_busy && s_axi4_wvalid[write_sel] && m_axi4.wready && s_axi4_wlast[write_sel] ) begin
                write_busy <= 1'b0;
            end
        end
    end

    always_comb begin
        s_axi4_awready = '0;
        s_axi4_wready  = '0;

        if ( write_req_valid ) begin
            s_axi4_awready[write_req_sel] = m_axi4.awready && m_axi4.wready;
            s_axi4_wready [write_req_sel] = m_axi4.awready && m_axi4.wready;
        end

        if ( write_busy ) begin
            s_axi4_wready[write_sel] = m_axi4.wready;
        end
    end

    assign write_start_ack = write_req_valid && s_axi4_awvalid[write_req_sel] && s_axi4_wvalid[write_req_sel]
                                && m_axi4.awready && m_axi4.wready;

    assign m_axi4.awid     = s_axi4_awid    [write_req_sel]                                           ;
    assign m_axi4.awaddr   = s_axi4_awaddr  [write_req_sel]                                           ;
    assign m_axi4.awlen    = s_axi4_awlen   [write_req_sel]                                           ;
    assign m_axi4.awsize   = s_axi4_awsize  [write_req_sel]                                           ;
    assign m_axi4.awburst  = s_axi4_awburst [write_req_sel]                                           ;
    assign m_axi4.awlock   = s_axi4_awlock  [write_req_sel]                                           ;
    assign m_axi4.awcache  = s_axi4_awcache [write_req_sel]                                           ;
    assign m_axi4.awprot   = s_axi4_awprot  [write_req_sel]                                           ;
    assign m_axi4.awqos    = s_axi4_awqos   [write_req_sel]                                           ;
    assign m_axi4.awregion = s_axi4_awregion[write_req_sel]                                           ;
    assign m_axi4.awuser   = s_axi4_awuser  [write_req_sel]                                           ;
    assign m_axi4.awvalid  = write_req_valid && s_axi4_awvalid[write_req_sel] && s_axi4_wvalid[write_req_sel];

    assign m_axi4.wdata    = write_busy ? s_axi4_wdata [write_sel] : s_axi4_wdata [write_req_sel];
    assign m_axi4.wstrb    = write_busy ? s_axi4_wstrb [write_sel] : s_axi4_wstrb [write_req_sel];
    assign m_axi4.wlast    = write_busy ? s_axi4_wlast [write_sel] : s_axi4_wlast [write_req_sel];
    assign m_axi4.wuser    = write_busy ? s_axi4_wuser [write_sel] : s_axi4_wuser [write_req_sel];
    assign m_axi4.wvalid   = write_busy ? s_axi4_wvalid[write_sel] : (write_req_valid && s_axi4_awvalid[write_req_sel] && s_axi4_wvalid[write_req_sel]);

    assign bsel_s_data  = write_req_sel;
    assign bsel_s_valid = write_start_ack;


    // write response route
    logic   b_accept;
    always_comb begin
        b_accept = 1'b0;
        if ( bsel_m_valid ) begin
            if ( !s_axi4_bvalid[bsel_m_data] || s_axi4_bready[bsel_m_data] ) begin
                b_accept = m_axi4.bvalid;
            end
        end
    end

    assign m_axi4.bready = bsel_m_valid && (!s_axi4_bvalid[bsel_m_data] || s_axi4_bready[bsel_m_data]);
    assign bsel_m_ready  = b_accept;

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

            if ( b_accept ) begin
                s_axi4_bid   [bsel_m_data] <= m_axi4.bid;
                s_axi4_bresp [bsel_m_data] <= m_axi4.bresp;
                s_axi4_buser [bsel_m_data] <= m_axi4.buser;
                s_axi4_bvalid[bsel_m_data] <= 1'b1;
            end
        end
    end


    // read arbiter
    logic   read_req_valid;
    sel_t   read_req_sel;
    logic   read_start_ack;

    always_ff @(posedge m_axi4.aclk) begin
        if ( ~m_axi4.aresetn ) begin
            read_req_valid <= 1'b0;
            read_req_sel   <= 'x;
        end
        else if ( m_axi4.aclken ) begin
            if ( !read_req_valid ) begin
                if ( rsel_s_ready ) begin
                    for ( int i = 0; i < NUM; i++ ) begin
                        if ( s_axi4_arvalid[i] ) begin
                            read_req_valid <= 1'b1;
                            read_req_sel   <= sel_t'(i);
                            break;
                        end
                    end
                end
            end

            if ( read_req_valid && !s_axi4_arvalid[read_req_sel] ) begin
                read_req_valid <= 1'b0;
            end

            if ( read_start_ack ) begin
                read_req_valid <= 1'b0;
            end
        end
    end

    always_comb begin
        s_axi4_arready = '0;
        if ( read_req_valid ) begin
            s_axi4_arready[read_req_sel] = m_axi4.arready;
        end
    end

    assign read_start_ack = read_req_valid && s_axi4_arvalid[read_req_sel] && m_axi4.arready;

    assign m_axi4.arid     = s_axi4_arid    [read_req_sel];
    assign m_axi4.araddr   = s_axi4_araddr  [read_req_sel];
    assign m_axi4.arlen    = s_axi4_arlen   [read_req_sel];
    assign m_axi4.arsize   = s_axi4_arsize  [read_req_sel];
    assign m_axi4.arburst  = s_axi4_arburst [read_req_sel];
    assign m_axi4.arlock   = s_axi4_arlock  [read_req_sel];
    assign m_axi4.arcache  = s_axi4_arcache [read_req_sel];
    assign m_axi4.arprot   = s_axi4_arprot  [read_req_sel];
    assign m_axi4.arqos    = s_axi4_arqos   [read_req_sel];
    assign m_axi4.arregion = s_axi4_arregion[read_req_sel];
    assign m_axi4.aruser   = s_axi4_aruser  [read_req_sel];
    assign m_axi4.arvalid  = read_req_valid && s_axi4_arvalid[read_req_sel];

    assign rsel_s_data  = read_req_sel;
    assign rsel_s_valid = read_start_ack;


    // read response route
    logic   r_accept;
    always_comb begin
        r_accept = 1'b0;
        if ( rsel_m_valid ) begin
            if ( !s_axi4_rvalid[rsel_m_data] || s_axi4_rready[rsel_m_data] ) begin
                r_accept = m_axi4.rvalid;
            end
        end
    end

    // R destination selection follows AR issue order. This assumes no R interleave.
    assign m_axi4.rready = rsel_m_valid && (!s_axi4_rvalid[rsel_m_data] || s_axi4_rready[rsel_m_data]);
    assign rsel_m_ready  = r_accept && m_axi4.rlast;

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
                if ( s_axi4_rvalid[i] && s_axi4_rready[i] ) begin
                    s_axi4_rid   [i] <= 'x;
                    s_axi4_rdata [i] <= 'x;
                    s_axi4_rresp [i] <= 'x;
                    s_axi4_rlast [i] <= 'x;
                    s_axi4_ruser [i] <= 'x;
                    s_axi4_rvalid[i] <= 1'b0;
                end
            end

            if ( r_accept ) begin
                s_axi4_rid   [rsel_m_data] <= m_axi4.rid;
                s_axi4_rdata [rsel_m_data] <= m_axi4.rdata;
                s_axi4_rresp [rsel_m_data] <= m_axi4.rresp;
                s_axi4_rlast [rsel_m_data] <= m_axi4.rlast;
                s_axi4_ruser [rsel_m_data] <= m_axi4.ruser;
                s_axi4_rvalid[rsel_m_data] <= 1'b1;
            end
        end
    end

endmodule


`default_nettype wire


// end of file
