`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/bus/jelly3_axi4_ff.sv"


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam  int     ID_BITS      = 4;
    localparam  int     ADDR_BITS    = 32;
    localparam  int     DATA_BITS    = 32;
    localparam  int     LEN_BITS     = 8;
    localparam  int     AWUSER_BITS  = 3;
    localparam  int     WUSER_BITS   = 4;
    localparam  int     BUSER_BITS   = 2;
    localparam  int     ARUSER_BITS = 3;
    localparam  int     RUSER_BITS   = 5;
    localparam  int     TXN_COUNT    = 64;
    localparam  int     MAX_CYCLES   = 2000;

    localparam  type    id_t      = logic [ID_BITS-1:0];
    localparam  type    addr_t    = logic [ADDR_BITS-1:0];
    localparam  type    len_t     = logic [LEN_BITS-1:0];
    localparam  type    data_t    = logic [DATA_BITS-1:0];
    localparam  type    strb_t    = logic [DATA_BITS/8-1:0];
    localparam  type    awuser_t  = logic [AWUSER_BITS-1:0];
    localparam  type    wuser_t   = logic [WUSER_BITS-1:0];
    localparam  type    buser_t   = logic [BUSER_BITS-1:0];
    localparam  type    aruser_t  = logic [ARUSER_BITS-1:0];
    localparam  type    ruser_t   = logic [RUSER_BITS-1:0];

    typedef struct packed {
        id_t                id;
        addr_t              addr;
        len_t               len;
        logic [2:0]         size;
        logic [1:0]         burst;
        logic               lock;
        logic [3:0]         cache;
        logic [2:0]         prot;
        logic [3:0]         qos;
        logic [3:0]         region;
        awuser_t            user;
    } aw_t;

    typedef struct packed {
        data_t              data;
        strb_t              strb;
        logic               last;
        wuser_t             user;
    } w_t;

    typedef struct packed {
        id_t                id;
        logic [1:0]         resp;
        buser_t             user;
    } b_t;

    typedef struct packed {
        id_t                id;
        addr_t              addr;
        len_t               len;
        logic [2:0]         size;
        logic [1:0]         burst;
        logic               lock;
        logic [3:0]         cache;
        logic [2:0]         prot;
        logic [3:0]         qos;
        logic [3:0]         region;
        aruser_t            user;
    } ar_t;

    typedef struct packed {
        id_t                id;
        data_t              data;
        logic [1:0]         resp;
        logic               last;
        ruser_t             user;
    } r_t;

    logic   aresetn;
    logic   aclken;
    assign aresetn = ~reset;
    assign aclken  = 1'b1;

    jelly3_axi4_if
            #(
                .ID_BITS        (ID_BITS        ),
                .ADDR_BITS      (ADDR_BITS      ),
                .DATA_BITS      (DATA_BITS      ),
                .LEN_BITS       (LEN_BITS       ),
                .USE_USER       (1'b1           ),
                .AWUSER_BITS    (AWUSER_BITS    ),
                .WUSER_BITS     (WUSER_BITS     ),
                .BUSER_BITS     (BUSER_BITS     ),
                .ARUSER_BITS    (ARUSER_BITS    ),
                .RUSER_BITS     (RUSER_BITS     ),
                .SIMULATION     ("true"         )
            )
        s_axi4
            (
                .aresetn        (aresetn        ),
                .aclk           (clk            ),
                .aclken         (aclken         )
            );

    jelly3_axi4_if
            #(
                .ID_BITS        (ID_BITS        ),
                .ADDR_BITS      (ADDR_BITS      ),
                .DATA_BITS      (DATA_BITS      ),
                .LEN_BITS       (LEN_BITS       ),
                .USE_USER       (1'b1           ),
                .AWUSER_BITS    (AWUSER_BITS    ),
                .WUSER_BITS     (WUSER_BITS     ),
                .BUSER_BITS     (BUSER_BITS     ),
                .ARUSER_BITS    (ARUSER_BITS    ),
                .RUSER_BITS     (RUSER_BITS     ),
                .SIMULATION     ("true"         )
            )
        m_axi4
            (
                .aresetn        (aresetn        ),
                .aclk           (clk            ),
                .aclken         (aclken         )
            );

    jelly3_axi4_ff
            #(
                .S_REG          (1'b1           ),
                .M_REG          (1'b1           )
            )
        u_dut
            (
                .s_axi4         (s_axi4         ),
                .m_axi4         (m_axi4         )
            );

    int unsigned cycle_count;
    int unsigned aw_src_count, aw_dst_count;
    int unsigned w_src_count,  w_dst_count;
    int unsigned b_src_count,  b_dst_count;
    int unsigned ar_src_count, ar_dst_count;
    int unsigned r_src_count,  r_dst_count;

    aw_t    observed_aw;
    w_t     observed_w;
    b_t     observed_b;
    ar_t    observed_ar;
    r_t     observed_r;

    function automatic aw_t make_aw(input int unsigned index);
        aw_t value;
        begin
            value.id     = id_t'(index + 1);
            value.addr   = addr_t'(32'h1000 + index * 32'h20);
            value.len    = len_t'(index ^ 8'ha5);
            value.size   = 3'(index + 1);
            value.burst  = 2'(index);
            value.lock   = 1'(index >> 1);
            value.cache  = 4'(index + 3);
            value.prot   = 3'(index ^ 3'b101);
            value.qos    = 4'(index + 5);
            value.region = 4'(index ^ 4'ha);
            value.user   = awuser_t'(index ^ 3'h5);
            make_aw = value;
        end
    endfunction

    function automatic w_t make_w(input int unsigned index);
        w_t value;
        begin
            value.data = data_t'(32'h9000_0000 ^ index);
            value.strb = strb_t'(index ^ 4'hb);
            value.last = (index % 5) == 4;
            value.user = wuser_t'(index ^ 4'h9);
            make_w = value;
        end
    endfunction

    function automatic b_t make_b(input int unsigned index);
        b_t value;
        begin
            value.id   = id_t'(index + 7);
            value.resp = 2'(index % 3);
            value.user = buser_t'(index ^ 2'h2);
            make_b = value;
        end
    endfunction

    function automatic ar_t make_ar(input int unsigned index);
        ar_t value;
        begin
            value.id     = id_t'(index + 9);
            value.addr   = addr_t'(32'h8000 + index * 32'h40);
            value.len    = len_t'(index ^ 8'h5a);
            value.size   = 3'(index + 2);
            value.burst  = 2'(index + 1);
            value.lock   = 1'(index >> 2);
            value.cache  = 4'(index + 6);
            value.prot   = 3'(index ^ 3'b011);
            value.qos    = 4'(index + 8);
            value.region = 4'(index ^ 4'h3);
            value.user   = aruser_t'(index ^ 3'h6);
            make_ar = value;
        end
    endfunction

    function automatic r_t make_r(input int unsigned index);
        r_t value;
        begin
            value.id   = id_t'(index + 11);
            value.data = data_t'(32'h5000_0000 + index);
            value.resp = 2'(index % 3);
            value.last = (index % 7) == 6;
            value.user = ruser_t'(index ^ 5'h15);
            make_r = value;
        end
    endfunction

    always_comb begin
        s_axi4.awid     = make_aw(aw_src_count).id;
        s_axi4.awaddr   = make_aw(aw_src_count).addr;
        s_axi4.awlen    = make_aw(aw_src_count).len;
        s_axi4.awsize   = make_aw(aw_src_count).size;
        s_axi4.awburst  = make_aw(aw_src_count).burst;
        s_axi4.awlock   = make_aw(aw_src_count).lock;
        s_axi4.awcache  = make_aw(aw_src_count).cache;
        s_axi4.awprot   = make_aw(aw_src_count).prot;
        s_axi4.awqos    = make_aw(aw_src_count).qos;
        s_axi4.awregion = make_aw(aw_src_count).region;
        s_axi4.awuser   = make_aw(aw_src_count).user;
        s_axi4.awvalid  = (aw_src_count < TXN_COUNT);

        s_axi4.wdata    = make_w(w_src_count).data;
        s_axi4.wstrb    = make_w(w_src_count).strb;
        s_axi4.wlast    = make_w(w_src_count).last;
        s_axi4.wuser    = make_w(w_src_count).user;
        s_axi4.wvalid   = (w_src_count < TXN_COUNT);

        s_axi4.bready   = (cycle_count % 5) >= 2;

        s_axi4.arid     = make_ar(ar_src_count).id;
        s_axi4.araddr   = make_ar(ar_src_count).addr;
        s_axi4.arlen    = make_ar(ar_src_count).len;
        s_axi4.arsize   = make_ar(ar_src_count).size;
        s_axi4.arburst  = make_ar(ar_src_count).burst;
        s_axi4.arlock   = make_ar(ar_src_count).lock;
        s_axi4.arcache  = make_ar(ar_src_count).cache;
        s_axi4.arprot   = make_ar(ar_src_count).prot;
        s_axi4.arqos    = make_ar(ar_src_count).qos;
        s_axi4.arregion = make_ar(ar_src_count).region;
        s_axi4.aruser   = make_ar(ar_src_count).user;
        s_axi4.arvalid  = (ar_src_count < TXN_COUNT);

        s_axi4.rready   = (cycle_count % 7) >= 3;

        m_axi4.awready  = (cycle_count % 7) >= 3;
        m_axi4.wready   = (cycle_count % 11) >= 4;

        m_axi4.bid      = make_b(b_src_count).id;
        m_axi4.bresp    = make_b(b_src_count).resp;
        m_axi4.buser    = make_b(b_src_count).user;
        m_axi4.bvalid   = (b_src_count < TXN_COUNT);

        m_axi4.arready  = (cycle_count % 13) >= 5;

        m_axi4.rid      = make_r(r_src_count).id;
        m_axi4.rdata    = make_r(r_src_count).data;
        m_axi4.rresp    = make_r(r_src_count).resp;
        m_axi4.rlast    = make_r(r_src_count).last;
        m_axi4.ruser    = make_r(r_src_count).user;
        m_axi4.rvalid   = (r_src_count < TXN_COUNT);
    end

    always @(posedge clk) begin
        if ( reset ) begin
            cycle_count <= 0;
            aw_src_count <= 0;
            aw_dst_count <= 0;
            w_src_count  <= 0;
            w_dst_count  <= 0;
            b_src_count  <= 0;
            b_dst_count  <= 0;
            ar_src_count <= 0;
            ar_dst_count <= 0;
            r_src_count  <= 0;
            r_dst_count  <= 0;
        end
        else begin
            cycle_count <= cycle_count + 1;

            if ( s_axi4.awvalid && s_axi4.awready ) begin
                aw_src_count <= aw_src_count + 1;
            end
            if ( m_axi4.awvalid && m_axi4.awready ) begin
                if ( aw_dst_count >= TXN_COUNT ) begin
                    $fatal(1, "AW: unexpected extra transfer");
                end
                observed_aw = {
                    m_axi4.awid, m_axi4.awaddr, m_axi4.awlen, m_axi4.awsize,
                    m_axi4.awburst, m_axi4.awlock, m_axi4.awcache,
                    m_axi4.awprot, m_axi4.awqos, m_axi4.awregion, m_axi4.awuser
                };
                if ( observed_aw !== make_aw(aw_dst_count) ) begin
                    $fatal(1, "AW: payload mismatch at transaction %0d", aw_dst_count);
                end
                aw_dst_count <= aw_dst_count + 1;
            end

            if ( s_axi4.wvalid && s_axi4.wready ) begin
                w_src_count <= w_src_count + 1;
            end
            if ( m_axi4.wvalid && m_axi4.wready ) begin
                if ( w_dst_count >= TXN_COUNT ) begin
                    $fatal(1, "W: unexpected extra transfer");
                end
                observed_w = {m_axi4.wdata, m_axi4.wstrb, m_axi4.wlast, m_axi4.wuser};
                if ( observed_w !== make_w(w_dst_count) ) begin
                    $fatal(1, "W: payload mismatch at transaction %0d", w_dst_count);
                end
                w_dst_count <= w_dst_count + 1;
            end

            if ( m_axi4.bvalid && m_axi4.bready ) begin
                b_src_count <= b_src_count + 1;
            end
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                if ( b_dst_count >= TXN_COUNT ) begin
                    $fatal(1, "B: unexpected extra transfer");
                end
                observed_b = {s_axi4.bid, s_axi4.bresp, s_axi4.buser};
                if ( observed_b !== make_b(b_dst_count) ) begin
                    $fatal(1, "B: payload mismatch at transaction %0d", b_dst_count);
                end
                b_dst_count <= b_dst_count + 1;
            end

            if ( s_axi4.arvalid && s_axi4.arready ) begin
                ar_src_count <= ar_src_count + 1;
            end
            if ( m_axi4.arvalid && m_axi4.arready ) begin
                if ( ar_dst_count >= TXN_COUNT ) begin
                    $fatal(1, "AR: unexpected extra transfer");
                end
                observed_ar = {
                    m_axi4.arid, m_axi4.araddr, m_axi4.arlen, m_axi4.arsize,
                    m_axi4.arburst, m_axi4.arlock, m_axi4.arcache,
                    m_axi4.arprot, m_axi4.arqos, m_axi4.arregion, m_axi4.aruser
                };
                if ( observed_ar !== make_ar(ar_dst_count) ) begin
                    $fatal(1, "AR: payload mismatch at transaction %0d", ar_dst_count);
                end
                ar_dst_count <= ar_dst_count + 1;
            end

            if ( m_axi4.rvalid && m_axi4.rready ) begin
                r_src_count <= r_src_count + 1;
            end
            if ( s_axi4.rvalid && s_axi4.rready ) begin
                if ( r_dst_count >= TXN_COUNT ) begin
                    $fatal(1, "R: unexpected extra transfer");
                end
                observed_r = {s_axi4.rid, s_axi4.rdata, s_axi4.rresp, s_axi4.rlast, s_axi4.ruser};
                if ( observed_r !== make_r(r_dst_count) ) begin
                    $fatal(1, "R: payload mismatch at transaction %0d", r_dst_count);
                end
                r_dst_count <= r_dst_count + 1;
            end

            if ( aw_src_count == TXN_COUNT && aw_dst_count == TXN_COUNT
                    && w_src_count == TXN_COUNT && w_dst_count == TXN_COUNT
                    && b_src_count == TXN_COUNT && b_dst_count == TXN_COUNT
                    && ar_src_count == TXN_COUNT && ar_dst_count == TXN_COUNT
                    && r_src_count == TXN_COUNT && r_dst_count == TXN_COUNT ) begin
                $display("PASS: jelly3_axi4_ff transferred %0d transactions on all channels", TXN_COUNT);
                $finish;
            end

            if ( cycle_count >= MAX_CYCLES ) begin
                $fatal(1, "Timeout: AXI4 FF test did not complete");
            end
        end
    end

endmodule


`default_nettype wire