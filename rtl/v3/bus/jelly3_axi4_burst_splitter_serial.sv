// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_burst_splitter_serial
        (
            jelly3_axi4_if.s    s_axi4,
            jelly3_axi4_if.m    m_axi4
        );

    localparam type id_t         = logic [s_axi4.ID_BITS-1:0];
    localparam type addr_t       = logic [s_axi4.ADDR_BITS-1:0];
    localparam type addr_ext_t   = logic [s_axi4.ADDR_BITS:0];
    localparam type len_t        = logic [s_axi4.LEN_BITS-1:0];
    localparam type beat_count_t = logic [s_axi4.LEN_BITS:0];
    localparam type size_t       = logic [s_axi4.SIZE_BITS-1:0];
    localparam type burst_t      = logic [s_axi4.BURST_BITS-1:0];
    localparam type lock_t       = logic [s_axi4.LOCK_BITS-1:0];
    localparam type cache_t      = logic [s_axi4.CACHE_BITS-1:0];
    localparam type prot_t       = logic [s_axi4.PROT_BITS-1:0];
    localparam type qos_t        = logic [s_axi4.QOS_BITS-1:0];
    localparam type region_t     = logic [s_axi4.REGION_BITS-1:0];
    localparam type resp_t       = logic [s_axi4.RESP_BITS-1:0];
    localparam type awuser_t     = logic [s_axi4.AWUSER_BITS-1:0];
    localparam type buser_t      = logic [s_axi4.BUSER_BITS-1:0];
    localparam type aruser_t     = logic [s_axi4.ARUSER_BITS-1:0];

    typedef struct packed {
        id_t        id;
        size_t      size;
        burst_t     burst;
        lock_t      lock;
        cache_t     cache;
        prot_t      prot;
        qos_t       qos;
        region_t    region;
        awuser_t    user;
    } aw_t;

    typedef struct packed {
        id_t        id;
        size_t      size;
        burst_t     burst;
        lock_t      lock;
        cache_t     cache;
        prot_t      prot;
        qos_t       qos;
        region_t    region;
        aruser_t    user;
    } ar_t;

    function automatic beat_count_t calc_chunk_beats(
                input logic [11:0] addr_low,
                input beat_count_t beats,
                input size_t       size,
                input burst_t      burst
            );
        logic [12:0] beat_bytes;
        logic [12:0] bytes_to_boundary;
        logic [12:0] unaligned_offset;
        logic [12:0] boundary_beats;
        begin
            calc_chunk_beats = beats;
            if ( burst == burst_t'(2'b01) ) begin
                beat_bytes        = 13'd1 << size;
                bytes_to_boundary = 13'd4096 - {1'b0, addr_low};
                unaligned_offset  = {1'b0, addr_low} & (beat_bytes - 13'd1);
                boundary_beats    = (bytes_to_boundary + unaligned_offset) >> size;
                if ( boundary_beats == 0 ) begin
                    boundary_beats = 13'd1;
                end
                if ( 13'(beats) > boundary_beats ) begin
                    calc_chunk_beats = beat_count_t'(boundary_beats);
                end
            end
        end
    endfunction

    function automatic addr_t increment_addr(
                input addr_t       addr,
                input beat_count_t beats,
                input size_t       size
            );
        addr_ext_t aligned_addr;
        addr_ext_t byte_increment;
        begin
            aligned_addr   = (addr_ext_t'(addr) >> size) << size;
            byte_increment = addr_ext_t'(beats) << size;
            increment_addr = addr_t'(aligned_addr + byte_increment);
        end
    endfunction


    // Write path: only one source burst and one downstream segment are active.
    typedef enum logic [1:0] {WR_IDLE, WR_XFER, WR_B, WR_RESP} wr_state_t;
    wr_state_t  wr_state;
    logic       wr_aw_done;
    logic       wr_w_done;
    aw_t        wr_aw;
    addr_t      wr_addr;
    beat_count_t wr_beats_remaining;
    beat_count_t wr_chunk_beats;
    beat_count_t wr_chunk_remaining;
    resp_t      wr_resp_accum;
    resp_t      wr_resp;
    buser_t     wr_buser;

    addr_t       wr_addr_after_chunk;
    beat_count_t wr_beats_after_chunk;
    beat_count_t wr_next_chunk_beats;

    always_comb begin
        wr_addr_after_chunk  = increment_addr(wr_addr, wr_chunk_beats, wr_aw.size);
        wr_beats_after_chunk = wr_beats_remaining - wr_chunk_beats;
        wr_next_chunk_beats  = calc_chunk_beats(wr_addr_after_chunk[11:0],
                                                wr_beats_after_chunk,
                                                wr_aw.size,
                                                wr_aw.burst);
    end

    assign s_axi4.awready = (wr_state == WR_IDLE) && s_axi4.aclken;
    assign m_axi4.awid     = wr_aw.id;
    assign m_axi4.awaddr   = wr_addr;
    assign m_axi4.awlen    = len_t'(wr_chunk_beats - beat_count_t'(1));
    assign m_axi4.awsize   = wr_aw.size;
    assign m_axi4.awburst  = wr_aw.burst;
    assign m_axi4.awlock   = wr_aw.lock;
    assign m_axi4.awcache  = wr_aw.cache;
    assign m_axi4.awprot   = wr_aw.prot;
    assign m_axi4.awqos    = wr_aw.qos;
    assign m_axi4.awregion = wr_aw.region;
    assign m_axi4.awuser   = wr_aw.user;
    assign m_axi4.awvalid  = (wr_state == WR_XFER) && !wr_aw_done && s_axi4.aclken;

    assign s_axi4.wready   = (wr_state == WR_XFER) && !wr_w_done && m_axi4.wready && s_axi4.aclken;
    assign m_axi4.wdata    = s_axi4.wdata;
    assign m_axi4.wstrb    = s_axi4.wstrb;
    assign m_axi4.wlast    = (wr_chunk_remaining == beat_count_t'(1));
    assign m_axi4.wuser    = s_axi4.wuser;
    assign m_axi4.wvalid   = (wr_state == WR_XFER) && !wr_w_done && s_axi4.wvalid && s_axi4.aclken;

    assign m_axi4.bready   = (wr_state == WR_B) && s_axi4.aclken;
    assign s_axi4.bid      = wr_aw.id;
    assign s_axi4.bresp    = wr_resp;
    assign s_axi4.buser    = wr_buser;
    assign s_axi4.bvalid   = (wr_state == WR_RESP) && s_axi4.aclken;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            wr_state           <= WR_IDLE;
            wr_aw_done         <= 1'b0;
            wr_w_done          <= 1'b0;
            wr_aw              <= 'x;
            wr_addr            <= 'x;
            wr_beats_remaining <= 'x;
            wr_chunk_beats     <= 'x;
            wr_chunk_remaining <= 'x;
            wr_resp_accum      <= '0;
            wr_resp            <= 'x;
            wr_buser           <= 'x;
        end
        else if ( s_axi4.aclken ) begin
            case ( wr_state )
                WR_IDLE: begin
                    if ( s_axi4.awvalid && s_axi4.awready ) begin
                        wr_aw.id     <= s_axi4.awid;
                        wr_aw.size   <= s_axi4.awsize;
                        wr_aw.burst  <= s_axi4.awburst;
                        wr_aw.lock   <= s_axi4.awlock;
                        wr_aw.cache  <= s_axi4.awcache;
                        wr_aw.prot   <= s_axi4.awprot;
                        wr_aw.qos    <= s_axi4.awqos;
                        wr_aw.region <= s_axi4.awregion;
                        wr_aw.user   <= s_axi4.awuser;
                        wr_addr      <= s_axi4.awaddr;
                        wr_beats_remaining <= beat_count_t'(s_axi4.awlen) + beat_count_t'(1);
                        wr_chunk_beats <= calc_chunk_beats(
                                                s_axi4.awaddr[11:0],
                                                beat_count_t'(s_axi4.awlen) + beat_count_t'(1),
                                                s_axi4.awsize,
                                                s_axi4.awburst);
                        wr_chunk_remaining <= calc_chunk_beats(
                                                s_axi4.awaddr[11:0],
                                                beat_count_t'(s_axi4.awlen) + beat_count_t'(1),
                                                s_axi4.awsize,
                                                s_axi4.awburst);
                        wr_resp_accum <= '0;
                        wr_aw_done <= 1'b0;
                        wr_w_done <= 1'b0;
                        wr_state <= WR_XFER;
                    end
                end

                WR_XFER: begin
                    if ( m_axi4.awvalid && m_axi4.awready ) begin
                        wr_aw_done <= 1'b1;
                    end
                    if ( s_axi4.wvalid && s_axi4.wready ) begin
                        if ( wr_chunk_remaining == beat_count_t'(1) ) begin
                            wr_w_done <= 1'b1;
                        end
                        else begin
                            wr_chunk_remaining <= wr_chunk_remaining - beat_count_t'(1);
                        end
                    end
                    if ( (wr_aw_done || (m_axi4.awvalid && m_axi4.awready)) &&
                         (wr_w_done || (s_axi4.wvalid && s_axi4.wready &&
                                        wr_chunk_remaining == beat_count_t'(1))) ) begin
                        wr_state <= WR_B;
                    end
                end

                WR_B: begin
                    if ( m_axi4.bvalid && m_axi4.bready ) begin
                        if ( wr_beats_after_chunk == 0 ) begin
                            wr_resp  <= (m_axi4.bresp > wr_resp_accum) ? m_axi4.bresp : wr_resp_accum;
                            wr_buser <= m_axi4.buser;
                            wr_state <= WR_RESP;
                        end
                        else begin
                            wr_addr            <= wr_addr_after_chunk;
                            wr_beats_remaining <= wr_beats_after_chunk;
                            wr_chunk_beats     <= wr_next_chunk_beats;
                            wr_chunk_remaining <= wr_next_chunk_beats;
                            wr_resp_accum <= (m_axi4.bresp > wr_resp_accum) ? m_axi4.bresp : wr_resp_accum;
                            wr_aw_done <= 1'b0;
                            wr_w_done <= 1'b0;
                            wr_state <= WR_XFER;
                        end
                    end
                end

                WR_RESP: begin
                    if ( s_axi4.bvalid && s_axi4.bready ) begin
                        wr_state <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end


    // Read path: reconstruct one RLAST for the original source burst.
    typedef enum logic [1:0] {RD_IDLE, RD_AR, RD_DATA} rd_state_t;
    rd_state_t  rd_state;
    ar_t        rd_ar;
    addr_t      rd_addr;
    beat_count_t rd_beats_remaining;
    beat_count_t rd_chunk_beats;
    beat_count_t rd_chunk_remaining;

    addr_t       rd_addr_after_chunk;
    beat_count_t rd_beats_after_chunk;
    beat_count_t rd_next_chunk_beats;

    always_comb begin
        rd_addr_after_chunk  = increment_addr(rd_addr, rd_chunk_beats, rd_ar.size);
        rd_beats_after_chunk = rd_beats_remaining - beat_count_t'(1);
        rd_next_chunk_beats  = calc_chunk_beats(rd_addr_after_chunk[11:0],
                                                rd_beats_after_chunk,
                                                rd_ar.size,
                                                rd_ar.burst);
    end

    assign s_axi4.arready = (rd_state == RD_IDLE) && s_axi4.aclken;
    assign m_axi4.arid     = rd_ar.id;
    assign m_axi4.araddr   = rd_addr;
    assign m_axi4.arlen    = len_t'(rd_chunk_beats - beat_count_t'(1));
    assign m_axi4.arsize   = rd_ar.size;
    assign m_axi4.arburst  = rd_ar.burst;
    assign m_axi4.arlock   = rd_ar.lock;
    assign m_axi4.arcache  = rd_ar.cache;
    assign m_axi4.arprot   = rd_ar.prot;
    assign m_axi4.arqos    = rd_ar.qos;
    assign m_axi4.arregion = rd_ar.region;
    assign m_axi4.aruser   = rd_ar.user;
    assign m_axi4.arvalid  = (rd_state == RD_AR) && s_axi4.aclken;

    assign m_axi4.rready   = (rd_state == RD_DATA) && s_axi4.rready && s_axi4.aclken;
    assign s_axi4.rid      = m_axi4.rid;
    assign s_axi4.rdata    = m_axi4.rdata;
    assign s_axi4.rresp    = m_axi4.rresp;
    assign s_axi4.rlast    = (rd_beats_remaining == beat_count_t'(1));
    assign s_axi4.ruser    = m_axi4.ruser;
    assign s_axi4.rvalid   = (rd_state == RD_DATA) && m_axi4.rvalid && s_axi4.aclken;

    always_ff @(posedge s_axi4.aclk) begin
        if ( ~s_axi4.aresetn ) begin
            rd_state           <= RD_IDLE;
            rd_ar              <= 'x;
            rd_addr            <= 'x;
            rd_beats_remaining <= 'x;
            rd_chunk_beats     <= 'x;
            rd_chunk_remaining <= 'x;
        end
        else if ( s_axi4.aclken ) begin
            case ( rd_state )
                RD_IDLE: begin
                    if ( s_axi4.arvalid && s_axi4.arready ) begin
                        rd_ar.id     <= s_axi4.arid;
                        rd_ar.size   <= s_axi4.arsize;
                        rd_ar.burst  <= s_axi4.arburst;
                        rd_ar.lock   <= s_axi4.arlock;
                        rd_ar.cache  <= s_axi4.arcache;
                        rd_ar.prot   <= s_axi4.arprot;
                        rd_ar.qos    <= s_axi4.arqos;
                        rd_ar.region <= s_axi4.arregion;
                        rd_ar.user   <= s_axi4.aruser;
                        rd_addr      <= s_axi4.araddr;
                        rd_beats_remaining <= beat_count_t'(s_axi4.arlen) + beat_count_t'(1);
                        rd_chunk_beats <= calc_chunk_beats(
                                                s_axi4.araddr[11:0],
                                                beat_count_t'(s_axi4.arlen) + beat_count_t'(1),
                                                s_axi4.arsize,
                                                s_axi4.arburst);
                        rd_chunk_remaining <= calc_chunk_beats(
                                                s_axi4.araddr[11:0],
                                                beat_count_t'(s_axi4.arlen) + beat_count_t'(1),
                                                s_axi4.arsize,
                                                s_axi4.arburst);
                        rd_state <= RD_AR;
                    end
                end

                RD_AR: begin
                    if ( m_axi4.arvalid && m_axi4.arready ) begin
                        rd_state <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    if ( s_axi4.rvalid && s_axi4.rready ) begin
                        rd_beats_remaining <= rd_beats_after_chunk;
                        if ( rd_chunk_remaining == beat_count_t'(1) ) begin
                            if ( rd_beats_remaining == beat_count_t'(1) ) begin
                                rd_state <= RD_IDLE;
                            end
                            else begin
                                rd_addr            <= rd_addr_after_chunk;
                                rd_chunk_beats     <= rd_next_chunk_beats;
                                rd_chunk_remaining <= rd_next_chunk_beats;
                                rd_state <= RD_AR;
                            end
                        end
                        else begin
                            rd_chunk_remaining <= rd_chunk_remaining - beat_count_t'(1);
                        end
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

endmodule


`default_nettype wire


// end of file