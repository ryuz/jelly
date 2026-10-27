// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_axi4_protocol_checker
        #(
            parameter   DEBUG = "true",
            parameter   int CHECK_QUEUE_DEPTH = 8
        )
        (
            jelly3_axi4_if.mon mon_axi4,

            output  var logic                       error,
            output  var logic [10:0]                 error_flags,
            output  var logic [3:0]                  error_code,
            output  var logic [mon_axi4.ID_BITS-1:0] error_id,
            output  var logic [mon_axi4.ADDR_BITS-1:0] error_addr,
            output  var logic [mon_axi4.LEN_BITS-1:0] error_len
        );

    localparam type id_t    = logic [mon_axi4.ID_BITS-1:0];
    localparam type addr_t  = logic [mon_axi4.ADDR_BITS-1:0];
    localparam type len_t   = logic [mon_axi4.LEN_BITS-1:0];
    localparam type size_t  = logic [mon_axi4.SIZE_BITS-1:0];
    localparam type burst_t = logic [mon_axi4.BURST_BITS-1:0];

    localparam int DATA_BYTES = mon_axi4.DATA_BITS / mon_axi4.BYTE_BITS;
    localparam int MAX_SIZE   = $clog2(DATA_BYTES);

    localparam int ERR_AW_4K       = 0;
    localparam int ERR_AR_4K       = 1;
    localparam int ERR_AW_FORMAT   = 2;
    localparam int ERR_AR_FORMAT   = 3;
    localparam int ERR_AW_STABLE   = 4;
    localparam int ERR_W_STABLE    = 5;
    localparam int ERR_B_STABLE    = 6;
    localparam int ERR_AR_STABLE   = 7;
    localparam int ERR_R_STABLE    = 8;
    localparam int ERR_WLAST       = 9;
    localparam int ERR_QUEUE_FULL  = 10;

    localparam int PTR_BITS = $clog2(CHECK_QUEUE_DEPTH) > 0 ? $clog2(CHECK_QUEUE_DEPTH) : 1;
    localparam int COUNT_BITS = $clog2(CHECK_QUEUE_DEPTH + 1) > 0 ? $clog2(CHECK_QUEUE_DEPTH + 1) : 1;
    localparam type beat_count_t = logic [mon_axi4.LEN_BITS:0];

    typedef struct packed {
        id_t   id;
        addr_t addr;
        len_t  len;
    } aw_check_t;

    aw_check_t   aw_check_fifo [CHECK_QUEUE_DEPTH];
    beat_count_t w_check_fifo  [CHECK_QUEUE_DEPTH];
    logic [PTR_BITS-1:0]  aw_check_wr_ptr;
    logic [PTR_BITS-1:0]  aw_check_rd_ptr;
    logic [PTR_BITS-1:0]  w_check_wr_ptr;
    logic [PTR_BITS-1:0]  w_check_rd_ptr;
    logic [COUNT_BITS-1:0] aw_check_count;
    logic [COUNT_BITS-1:0] w_check_count;
    beat_count_t ff_w_beats;

    function automatic logic [PTR_BITS-1:0] next_ptr(input logic [PTR_BITS-1:0] ptr);
        if ( ptr == PTR_BITS'(CHECK_QUEUE_DEPTH - 1) ) begin
            return '0;
        end
        return ptr + PTR_BITS'(1);
    endfunction

    logic w_fire;
    logic wlast_fire;
    logic check_w_burst;
    logic aw_check_overflow;
    logic w_check_overflow;
    assign w_fire = mon_axi4.aclken && mon_axi4.wvalid && mon_axi4.wready;
    assign wlast_fire = w_fire && mon_axi4.wlast;
    assign check_w_burst = (aw_check_count != 0) && (w_check_count != 0);
    assign aw_check_overflow = aw_fire && (aw_check_count == COUNT_BITS'(CHECK_QUEUE_DEPTH)) && !check_w_burst;
    assign w_check_overflow  = wlast_fire && (w_check_count == COUNT_BITS'(CHECK_QUEUE_DEPTH)) && !check_w_burst;

    logic aw_fire;
    logic ar_fire;
    assign aw_fire = mon_axi4.aclken && mon_axi4.awvalid && mon_axi4.awready;
    assign ar_fire = mon_axi4.aclken && mon_axi4.arvalid && mon_axi4.arready;

    function automatic logic burst_format_error(
                input addr_t  addr,
                input len_t   len,
                input size_t  size,
                input burst_t burst
            );
        logic [31:0] beat_bytes;
        logic [31:0] beat_count;
        begin
            beat_bytes = 32'd1 << size;
            beat_count = 32'(len) + 32'd1;
            burst_format_error = (size > size_t'(MAX_SIZE)) || (burst == burst_t'(2'b11));
            if ( burst == burst_t'(2'b00) && beat_count > 16 ) begin
                burst_format_error = 1'b1;
            end
            if ( burst == burst_t'(2'b10) ) begin
                if ( !(len == len_t'(1) || len == len_t'(3) || len == len_t'(7) || len == len_t'(15)) ) begin
                    burst_format_error = 1'b1;
                end
                if ( ({20'd0, addr[11:0]} & (beat_bytes - 32'd1)) != 0 ) begin
                    burst_format_error = 1'b1;
                end
            end
        end
    endfunction

    function automatic logic burst_crosses_4k(
                input addr_t  addr,
                input len_t   len,
                input size_t  size,
                input burst_t burst
            );
        logic [31:0] beat_bytes;
        logic [31:0] beat_count;
        logic [31:0] first_aligned_addr;
        logic [31:0] end_addr;
        begin
            burst_crosses_4k = 1'b0;
            if ( burst == burst_t'(2'b01) && size <= size_t'(MAX_SIZE) ) begin
                beat_bytes       = 32'd1 << size;
                beat_count       = 32'(len) + 32'd1;
                first_aligned_addr = {20'd0, addr[11:0]} & ~(beat_bytes - 32'd1);
                end_addr         = first_aligned_addr + (beat_count << size);
                burst_crosses_4k = end_addr > 32'd4096;
            end
        end
    endfunction

    logic [10:0] event_flags;
    always_comb begin
        event_flags = '0;
        if ( aw_fire ) begin
            event_flags[ERR_AW_FORMAT] = burst_format_error(mon_axi4.awaddr, mon_axi4.awlen,
                                                            mon_axi4.awsize, mon_axi4.awburst);
            event_flags[ERR_AW_4K]     = burst_crosses_4k(mon_axi4.awaddr, mon_axi4.awlen,
                                                         mon_axi4.awsize, mon_axi4.awburst);
        end
        if ( ar_fire ) begin
            event_flags[ERR_AR_FORMAT] = burst_format_error(mon_axi4.araddr, mon_axi4.arlen,
                                                            mon_axi4.arsize, mon_axi4.arburst);
            event_flags[ERR_AR_4K]     = burst_crosses_4k(mon_axi4.araddr, mon_axi4.arlen,
                                                         mon_axi4.arsize, mon_axi4.arburst);
        end
        event_flags[ERR_AW_STABLE] = ff_aw_stalled && (!mon_axi4.awvalid || aw_payload != ff_aw_payload);
        event_flags[ERR_W_STABLE]  = ff_w_stalled  && (!mon_axi4.wvalid  || w_payload  != ff_w_payload );
        event_flags[ERR_B_STABLE]  = ff_b_stalled  && (!mon_axi4.bvalid  || b_payload  != ff_b_payload );
        event_flags[ERR_AR_STABLE] = ff_ar_stalled && (!mon_axi4.arvalid || ar_payload != ff_ar_payload);
        event_flags[ERR_R_STABLE]  = ff_r_stalled  && (!mon_axi4.rvalid  || r_payload  != ff_r_payload );
        event_flags[ERR_WLAST]     = check_w_burst &&
                         (beat_count_t'(aw_check_fifo[aw_check_rd_ptr].len) + beat_count_t'(1) !=
                          w_check_fifo[w_check_rd_ptr]);
        event_flags[ERR_QUEUE_FULL] = aw_check_overflow || w_check_overflow;
    end

    logic [$bits({mon_axi4.awid, mon_axi4.awaddr, mon_axi4.awlen, mon_axi4.awsize, mon_axi4.awburst,
                  mon_axi4.awlock, mon_axi4.awcache, mon_axi4.awprot, mon_axi4.awqos, mon_axi4.awregion,
                  mon_axi4.awuser})-1:0] aw_payload;
    logic [$bits({mon_axi4.wdata, mon_axi4.wstrb, mon_axi4.wlast, mon_axi4.wuser})-1:0] w_payload;
    logic [$bits({mon_axi4.bid, mon_axi4.bresp, mon_axi4.buser})-1:0] b_payload;
    logic [$bits({mon_axi4.arid, mon_axi4.araddr, mon_axi4.arlen, mon_axi4.arsize, mon_axi4.arburst,
                  mon_axi4.arlock, mon_axi4.arcache, mon_axi4.arprot, mon_axi4.arqos, mon_axi4.arregion,
                  mon_axi4.aruser})-1:0] ar_payload;
    logic [$bits({mon_axi4.rid, mon_axi4.rdata, mon_axi4.rresp, mon_axi4.rlast, mon_axi4.ruser})-1:0] r_payload;

    assign aw_payload = {mon_axi4.awid, mon_axi4.awaddr, mon_axi4.awlen, mon_axi4.awsize, mon_axi4.awburst,
                         mon_axi4.awlock, mon_axi4.awcache, mon_axi4.awprot, mon_axi4.awqos, mon_axi4.awregion,
                         mon_axi4.awuser};
    assign w_payload  = {mon_axi4.wdata, mon_axi4.wstrb, mon_axi4.wlast, mon_axi4.wuser};
    assign b_payload  = {mon_axi4.bid, mon_axi4.bresp, mon_axi4.buser};
    assign ar_payload = {mon_axi4.arid, mon_axi4.araddr, mon_axi4.arlen, mon_axi4.arsize, mon_axi4.arburst,
                         mon_axi4.arlock, mon_axi4.arcache, mon_axi4.arprot, mon_axi4.arqos, mon_axi4.arregion,
                         mon_axi4.aruser};
    assign r_payload  = {mon_axi4.rid, mon_axi4.rdata, mon_axi4.rresp, mon_axi4.rlast, mon_axi4.ruser};

    logic ff_aw_stalled;
    logic ff_w_stalled;
    logic ff_b_stalled;
    logic ff_ar_stalled;
    logic ff_r_stalled;
    logic [$bits(aw_payload)-1:0] ff_aw_payload;
    logic [$bits(w_payload)-1:0]  ff_w_payload;
    logic [$bits(b_payload)-1:0]  ff_b_payload;
    logic [$bits(ar_payload)-1:0] ff_ar_payload;
    logic [$bits(r_payload)-1:0]  ff_r_payload;

    (* MARK_DEBUG=DEBUG *) logic [10:0] ff_error_flags;
    (* MARK_DEBUG=DEBUG *) logic [3:0] ff_error_code;
    (* MARK_DEBUG=DEBUG *) id_t       ff_error_id;
    (* MARK_DEBUG=DEBUG *) addr_t     ff_error_addr;
    (* MARK_DEBUG=DEBUG *) len_t      ff_error_len;

    logic [3:0] event_code;
    id_t        event_id;
    addr_t      event_addr;
    len_t       event_len;

    always_comb begin
        event_code = '0;
        event_id   = '0;
        event_addr = '0;
        event_len  = '0;
        if ( event_flags[ERR_AW_4K] || event_flags[ERR_AW_FORMAT] || event_flags[ERR_AW_STABLE] ) begin
            event_id   = mon_axi4.awid;
            event_addr = mon_axi4.awaddr;
            event_len  = mon_axi4.awlen;
            if ( event_flags[ERR_AW_4K] )      event_code = 4'(ERR_AW_4K);
            else if ( event_flags[ERR_AW_FORMAT] ) event_code = 4'(ERR_AW_FORMAT);
            else                                event_code = 4'(ERR_AW_STABLE);
        end
        else if ( event_flags[ERR_AR_4K] || event_flags[ERR_AR_FORMAT] || event_flags[ERR_AR_STABLE] ) begin
            event_id   = mon_axi4.arid;
            event_addr = mon_axi4.araddr;
            event_len  = mon_axi4.arlen;
            if ( event_flags[ERR_AR_4K] )      event_code = 4'(ERR_AR_4K);
            else if ( event_flags[ERR_AR_FORMAT] ) event_code = 4'(ERR_AR_FORMAT);
            else                                event_code = 4'(ERR_AR_STABLE);
        end
        else if ( event_flags[ERR_W_STABLE] ) begin
            event_code = 4'(ERR_W_STABLE);
        end
        else if ( event_flags[ERR_B_STABLE] ) begin
            event_code = 4'(ERR_B_STABLE);
            event_id   = mon_axi4.bid;
        end
        else if ( event_flags[ERR_R_STABLE] ) begin
            event_code = 4'(ERR_R_STABLE);
            event_id   = mon_axi4.rid;
        end
        else if ( event_flags[ERR_WLAST] ) begin
            event_code = 4'(ERR_WLAST);
            event_id   = aw_check_fifo[aw_check_rd_ptr].id;
            event_addr = aw_check_fifo[aw_check_rd_ptr].addr;
            event_len  = aw_check_fifo[aw_check_rd_ptr].len;
        end
        else if ( event_flags[ERR_QUEUE_FULL] ) begin
            event_code = 4'(ERR_QUEUE_FULL);
        end
    end

    always_ff @(posedge mon_axi4.aclk) begin
        if ( ~mon_axi4.aresetn ) begin
            aw_check_wr_ptr <= '0;
            aw_check_rd_ptr <= '0;
            w_check_wr_ptr  <= '0;
            w_check_rd_ptr  <= '0;
            aw_check_count  <= '0;
            w_check_count   <= '0;
            ff_w_beats      <= '0;
        end
        else begin
            if ( aw_fire && !aw_check_overflow ) begin
                aw_check_fifo[aw_check_wr_ptr].id   <= mon_axi4.awid;
                aw_check_fifo[aw_check_wr_ptr].addr <= mon_axi4.awaddr;
                aw_check_fifo[aw_check_wr_ptr].len  <= mon_axi4.awlen;
                aw_check_wr_ptr <= next_ptr(aw_check_wr_ptr);
            end
            if ( wlast_fire && !w_check_overflow ) begin
                w_check_fifo[w_check_wr_ptr] <= ff_w_beats + beat_count_t'(1);
                w_check_wr_ptr <= next_ptr(w_check_wr_ptr);
                ff_w_beats <= '0;
            end
            else if ( w_fire ) begin
                ff_w_beats <= ff_w_beats + beat_count_t'(1);
            end
            if ( check_w_burst ) begin
                aw_check_rd_ptr <= next_ptr(aw_check_rd_ptr);
                w_check_rd_ptr  <= next_ptr(w_check_rd_ptr);
            end

            case ({aw_fire && !aw_check_overflow, check_w_burst})
                2'b10: aw_check_count <= aw_check_count + COUNT_BITS'(1);
                2'b01: aw_check_count <= aw_check_count - COUNT_BITS'(1);
                default: begin end
            endcase
            case ({wlast_fire && !w_check_overflow, check_w_burst})
                2'b10: w_check_count <= w_check_count + COUNT_BITS'(1);
                2'b01: w_check_count <= w_check_count - COUNT_BITS'(1);
                default: begin end
            endcase
        end
    end

    always_ff @(posedge mon_axi4.aclk) begin
        if ( ~mon_axi4.aresetn ) begin
            ff_aw_stalled <= 1'b0;
            ff_w_stalled  <= 1'b0;
            ff_b_stalled  <= 1'b0;
            ff_ar_stalled <= 1'b0;
            ff_r_stalled  <= 1'b0;
            ff_aw_payload <= 'x;
            ff_w_payload  <= 'x;
            ff_b_payload  <= 'x;
            ff_ar_payload <= 'x;
            ff_r_payload  <= 'x;
            ff_error_flags <= '0;
            ff_error_code  <= '0;
            ff_error_id    <= '0;
            ff_error_addr  <= '0;
            ff_error_len   <= '0;
        end
        else begin
            ff_aw_stalled <= mon_axi4.awvalid && !(mon_axi4.awready && mon_axi4.aclken);
            ff_w_stalled  <= mon_axi4.wvalid  && !(mon_axi4.wready  && mon_axi4.aclken);
            ff_b_stalled  <= mon_axi4.bvalid  && !(mon_axi4.bready  && mon_axi4.aclken);
            ff_ar_stalled <= mon_axi4.arvalid && !(mon_axi4.arready && mon_axi4.aclken);
            ff_r_stalled  <= mon_axi4.rvalid  && !(mon_axi4.rready  && mon_axi4.aclken);
            if ( mon_axi4.awvalid && !(mon_axi4.awready && mon_axi4.aclken) ) ff_aw_payload <= aw_payload;
            if ( mon_axi4.wvalid  && !(mon_axi4.wready  && mon_axi4.aclken) ) ff_w_payload  <= w_payload;
            if ( mon_axi4.bvalid  && !(mon_axi4.bready  && mon_axi4.aclken) ) ff_b_payload  <= b_payload;
            if ( mon_axi4.arvalid && !(mon_axi4.arready && mon_axi4.aclken) ) ff_ar_payload <= ar_payload;
            if ( mon_axi4.rvalid  && !(mon_axi4.rready  && mon_axi4.aclken) ) ff_r_payload  <= r_payload;

            ff_error_flags <= ff_error_flags | event_flags;
            if ( ff_error_flags == '0 && event_flags != '0 ) begin
                ff_error_code <= event_code;
                ff_error_id   <= event_id;
                ff_error_addr <= event_addr;
                ff_error_len  <= event_len;
            end
        end
    end

    assign error       = |ff_error_flags;
    assign error_flags = ff_error_flags;
    assign error_code  = ff_error_code;
    assign error_id    = ff_error_id;
    assign error_addr  = ff_error_addr;
    assign error_len   = ff_error_len;

endmodule


`default_nettype wire


// end of file