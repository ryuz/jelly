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
    logic [NUM-1:0] awaddr_match;
    logic           awaddr_other;
    always_comb begin
        awaddr_match = '0;
        awaddr_other = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( dec_addr_mask(s_axi4.awaddr) >= dec_addr_mask(addr_base[i])
              && dec_addr_mask(s_axi4.awaddr) <= dec_addr_mask(addr_high[i]) ) begin
                awaddr_match[i] = 1'b1;
                awaddr_other    = 1'b0;
            end
        end
    end

    logic [NUM-1:0] araddr_match;
    logic           araddr_other;
    always_comb begin
        araddr_match = '0;
        araddr_other = 1'b1;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( dec_addr_mask(s_axi4.araddr) >= dec_addr_mask(addr_base[i])
              && dec_addr_mask(s_axi4.araddr) <= dec_addr_mask(addr_high[i]) ) begin
                araddr_match[i] = 1'b1;
                araddr_other    = 1'b0;
            end
        end
    end

    // write channel
    logic [NUM-1:0] m_awready;
    logic [NUM-1:0] m_wready;
    id_t            m_bid    [NUM];
    resp_t          m_bresp  [NUM];
    buser_t         m_buser  [NUM];
    logic [NUM-1:0] m_bvalid;
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_awready[i] = m_axi4[i].awready;
        assign m_wready [i] = m_axi4[i].wready;
        assign m_bid    [i] = m_axi4[i].bid;
        assign m_bresp  [i] = m_axi4[i].bresp;
        assign m_buser  [i] = m_axi4[i].buser;
        assign m_bvalid [i] = m_axi4[i].bvalid;
    end

    logic           write_busy;
    logic [NUM-1:0] write_sel;
    logic           write_other;

    id_t            write_other_bid;
    logic           write_other_bvalid;

    logic [NUM-1:0] m_awvalid;
    logic [NUM-1:0] m_wvalid;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            write_busy        <= 1'b0;
            write_sel         <= '0;
            write_other       <= 1'b0;
            write_other_bid   <= '0;
            write_other_bvalid<= 1'b0;
        end
        else begin
            if ( !write_busy && s_axi4.awvalid && s_axi4.awready ) begin
                write_busy      <= 1'b1;
                write_sel       <= awaddr_match;
                write_other     <= awaddr_other;
                write_other_bid <= s_axi4.awid;
            end

            if ( write_busy && write_other && s_axi4.wvalid && s_axi4.wready && s_axi4.wlast ) begin
                write_other_bvalid <= 1'b1;
            end

            if ( write_other_bvalid && s_axi4.bready ) begin
                write_other_bvalid <= 1'b0;
                write_busy         <= 1'b0;
            end

            for ( int i = 0; i < NUM; i++ ) begin
                if ( write_busy && !write_other && write_sel[i] && m_bvalid[i] && s_axi4.bready ) begin
                    write_busy <= 1'b0;
                end
            end
        end
    end

    logic           s_bvalid_sel;
    id_t            s_bid_sel;
    resp_t          s_bresp_sel;
    buser_t         s_buser_sel;
    always_comb begin
        s_bvalid_sel = 1'b0;
        s_bid_sel    = 'x;
        s_bresp_sel  = 'x;
        s_buser_sel  = 'x;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( write_sel[i] && m_bvalid[i] ) begin
                s_bvalid_sel = 1'b1;
                s_bid_sel    = m_bid[i];
                s_bresp_sel  = m_bresp[i];
                s_buser_sel  = m_buser[i];
            end
        end
    end

    assign s_axi4.awready = !write_busy && (awaddr_other || |(awaddr_match & m_awready));
    assign s_axi4.wready  = write_busy && (write_other || |(write_sel & m_wready));

    assign s_axi4.bid     = write_other_bvalid ? write_other_bid : s_bid_sel;
    assign s_axi4.bresp   = write_other_bvalid ? resp_t'('0)     : s_bresp_sel;
    assign s_axi4.buser   = write_other_bvalid ? buser_t'('0)    : s_buser_sel;
    assign s_axi4.bvalid  = write_other_bvalid || s_bvalid_sel;

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4[i].awid     = m_awvalid[i] ? s_axi4.awid     : 'x;
        assign m_axi4[i].awaddr   = m_awvalid[i] ? s_axi4.awaddr   : 'x;
        assign m_axi4[i].awlen    = m_awvalid[i] ? s_axi4.awlen    : 'x;
        assign m_axi4[i].awsize   = m_awvalid[i] ? s_axi4.awsize   : 'x;
        assign m_axi4[i].awburst  = m_awvalid[i] ? s_axi4.awburst  : 'x;
        assign m_axi4[i].awlock   = m_awvalid[i] ? s_axi4.awlock   : 'x;
        assign m_axi4[i].awcache  = m_awvalid[i] ? s_axi4.awcache  : 'x;
        assign m_axi4[i].awprot   = m_awvalid[i] ? s_axi4.awprot   : 'x;
        assign m_axi4[i].awqos    = m_awvalid[i] ? s_axi4.awqos    : 'x;
        assign m_axi4[i].awregion = m_awvalid[i] ? s_axi4.awregion : 'x;
        assign m_axi4[i].awuser   = m_awvalid[i] ? s_axi4.awuser   : 'x;
        assign m_axi4[i].awvalid  = m_awvalid[i];

        assign m_axi4[i].wdata    = m_wvalid[i]  ? s_axi4.wdata    : 'x;
        assign m_axi4[i].wstrb    = m_wvalid[i]  ? s_axi4.wstrb    : 'x;
        assign m_axi4[i].wlast    = m_wvalid[i]  ? s_axi4.wlast    : 'x;
        assign m_axi4[i].wuser    = m_wvalid[i]  ? s_axi4.wuser    : 'x;
        assign m_axi4[i].wvalid   = m_wvalid[i];

        assign m_axi4[i].bready   = write_busy && !write_other && write_sel[i] ? s_axi4.bready : 1'b0;
    end

    assign m_awvalid = (!write_busy && s_axi4.awvalid && !awaddr_other) ? awaddr_match : '0;
    assign m_wvalid  = ( write_busy && s_axi4.wvalid && !write_other) ? write_sel : '0;


    // read channel
    logic [NUM-1:0] m_arready;
    id_t            m_rid    [NUM];
    data_t          m_rdata  [NUM];
    resp_t          m_rresp  [NUM];
    logic [NUM-1:0] m_rlast;
    ruser_t         m_ruser  [NUM];
    logic [NUM-1:0] m_rvalid;
    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_arready[i] = m_axi4[i].arready;
        assign m_rid   [i]  = m_axi4[i].rid;
        assign m_rdata [i]  = m_axi4[i].rdata;
        assign m_rresp [i]  = m_axi4[i].rresp;
        assign m_rlast [i]  = m_axi4[i].rlast;
        assign m_ruser [i]  = m_axi4[i].ruser;
        assign m_rvalid[i]  = m_axi4[i].rvalid;
    end

    logic           read_busy;
    logic [NUM-1:0] read_sel;
    logic           read_other;

    id_t            read_other_rid;
    len_t           read_other_len;
    len_t           read_other_count;
    logic           read_other_rvalid;

    logic [NUM-1:0] m_arvalid;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            read_busy         <= 1'b0;
            read_sel          <= '0;
            read_other        <= 1'b0;
            read_other_rid    <= '0;
            read_other_len    <= '0;
            read_other_count  <= '0;
            read_other_rvalid <= 1'b0;
        end
        else begin
            if ( !read_busy && s_axi4.arvalid && s_axi4.arready ) begin
                read_busy      <= 1'b1;
                read_sel       <= araddr_match;
                read_other     <= araddr_other;
                read_other_rid <= s_axi4.arid;
                if ( araddr_other ) begin
                    read_other_len    <= s_axi4.arlen;
                    read_other_count  <= '0;
                    read_other_rvalid <= 1'b1;
                end
            end

            if ( read_other_rvalid && s_axi4.rready ) begin
                if ( read_other_count >= read_other_len ) begin
                    read_other_rvalid <= 1'b0;
                    read_busy         <= 1'b0;
                end
                else begin
                    read_other_count <= read_other_count + len_t'(1);
                end
            end

            for ( int i = 0; i < NUM; i++ ) begin
                if ( read_busy && !read_other && read_sel[i] && m_rvalid[i] && s_axi4.rready && m_rlast[i] ) begin
                    read_busy <= 1'b0;
                end
            end
        end
    end

    logic           s_rvalid_sel;
    id_t            s_rid_sel;
    data_t          s_rdata_sel;
    resp_t          s_rresp_sel;
    logic           s_rlast_sel;
    ruser_t         s_ruser_sel;
    always_comb begin
        s_rvalid_sel = 1'b0;
        s_rid_sel    = 'x;
        s_rdata_sel  = 'x;
        s_rresp_sel  = 'x;
        s_rlast_sel  = 'x;
        s_ruser_sel  = 'x;
        for ( int i = 0; i < NUM; i++ ) begin
            if ( read_sel[i] && m_rvalid[i] ) begin
                s_rvalid_sel = 1'b1;
                s_rid_sel    = m_rid[i];
                s_rdata_sel  = m_rdata[i];
                s_rresp_sel  = m_rresp[i];
                s_rlast_sel  = m_rlast[i];
                s_ruser_sel  = m_ruser[i];
            end
        end
    end

    assign s_axi4.arready = !read_busy && (araddr_other || |(araddr_match & m_arready));

    assign s_axi4.rid     = read_other_rvalid ? read_other_rid : s_rid_sel;
    assign s_axi4.rdata   = read_other_rvalid ? data_t'('0)    : s_rdata_sel;
    assign s_axi4.rresp   = read_other_rvalid ? resp_t'('0)    : s_rresp_sel;
    assign s_axi4.rlast   = read_other_rvalid ? (read_other_count >= read_other_len) : s_rlast_sel;
    assign s_axi4.ruser   = read_other_rvalid ? ruser_t'('0)   : s_ruser_sel;
    assign s_axi4.rvalid  = read_other_rvalid || s_rvalid_sel;

    for ( genvar i = 0; i < NUM; i++ ) begin
        assign m_axi4[i].arid     = m_arvalid[i] ? s_axi4.arid     : 'x;
        assign m_axi4[i].araddr   = m_arvalid[i] ? s_axi4.araddr   : 'x;
        assign m_axi4[i].arlen    = m_arvalid[i] ? s_axi4.arlen    : 'x;
        assign m_axi4[i].arsize   = m_arvalid[i] ? s_axi4.arsize   : 'x;
        assign m_axi4[i].arburst  = m_arvalid[i] ? s_axi4.arburst  : 'x;
        assign m_axi4[i].arlock   = m_arvalid[i] ? s_axi4.arlock   : 'x;
        assign m_axi4[i].arcache  = m_arvalid[i] ? s_axi4.arcache  : 'x;
        assign m_axi4[i].arprot   = m_arvalid[i] ? s_axi4.arprot   : 'x;
        assign m_axi4[i].arqos    = m_arvalid[i] ? s_axi4.arqos    : 'x;
        assign m_axi4[i].arregion = m_arvalid[i] ? s_axi4.arregion : 'x;
        assign m_axi4[i].aruser   = m_arvalid[i] ? s_axi4.aruser   : 'x;
        assign m_axi4[i].arvalid  = m_arvalid[i];

        assign m_axi4[i].rready   = read_busy && !read_other && read_sel[i] ? s_axi4.rready : 1'b0;
    end

    assign m_arvalid = (!read_busy && s_axi4.arvalid && !araddr_other) ? araddr_match : '0;


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
