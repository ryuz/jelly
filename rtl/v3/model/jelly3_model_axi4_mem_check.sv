// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly3_model_axi4_mem_check
        #(
            parameter   bit     SHOW_MATCH      = 0,
            parameter   bit     SHOW_SKIP       = 0,
            parameter   bit     CHECK_BID       = 1,
            parameter   bit     CHECK_BRESP     = 1,
            parameter   bit     CHECK_RID       = 1,
            parameter   bit     CHECK_RRESP     = 1,
            parameter   bit     CHECK_WLAST     = 1,
            parameter   bit     CHECK_RLAST     = 1
        )
        (
            jelly3_axi4_if.mon  mon_axi4
        );

    localparam  int     AXI_ID_BITS     = mon_axi4.ID_BITS;
    localparam  int     AXI_ADDR_BITS   = mon_axi4.ADDR_BITS;
    localparam  int     AXI_LEN_BITS    = mon_axi4.LEN_BITS;
    localparam  int     AXI_SIZE_BITS   = mon_axi4.SIZE_BITS;
    localparam  int     AXI_BURST_BITS  = mon_axi4.BURST_BITS;
    localparam  int     AXI_DATA_BITS   = mon_axi4.DATA_BITS;
    localparam  int     AXI_STRB_BITS   = mon_axi4.STRB_BITS;
    localparam  int     AXI_RESP_BITS   = mon_axi4.RESP_BITS;
    localparam  int     AXI_DATA_BYTES  = AXI_STRB_BITS;
    localparam  int     AXI_ADDR_LSB    = AXI_STRB_BITS > 1 ? $clog2(AXI_STRB_BITS) : 0;

    localparam  int     AW_QUEUE_LIMIT  = mon_axi4.LIMIT_AW > 0 ? mon_axi4.LIMIT_AW : 1;
    localparam  int     W_QUEUE_LIMIT   = mon_axi4.LIMIT_WC > 0 ? mon_axi4.LIMIT_WC : 1;
    localparam  int     R_QUEUE_LIMIT   = mon_axi4.LIMIT_RC > 0 ? mon_axi4.LIMIT_RC : 1;

    localparam  type    id_t            = logic [AXI_ID_BITS-1:0];
    localparam  type    addr_t          = logic [AXI_ADDR_BITS-1:0];
    localparam  type    len_t           = logic [AXI_LEN_BITS-1:0];
    localparam  type    size_t          = logic [AXI_SIZE_BITS-1:0];
    localparam  type    burst_t         = logic [AXI_BURST_BITS-1:0];
    localparam  type    data_t          = logic [AXI_DATA_BITS-1:0];
    localparam  type    strb_t          = logic [AXI_STRB_BITS-1:0];
    localparam  type    resp_t          = logic [AXI_RESP_BITS-1:0];
    localparam  type    key_t           = longint unsigned;

    localparam  burst_t BURST_INCR      = burst_t'(2'b01);
    localparam  resp_t  RESP_OKAY       = resp_t'(2'b00);
    localparam  size_t  FULL_SIZE       = size_t'(AXI_ADDR_LSB);

    id_t            aw_id_queue[$];
    addr_t          aw_addr_queue[$];
    len_t           aw_len_queue[$];
    size_t          aw_size_queue[$];
    burst_t         aw_burst_queue[$];

    id_t            wr_bid_expect_queue[$];

    addr_t          rd_addr_queue[$];
    id_t            rd_id_queue[$];
    data_t          rd_expect_queue[$];
    logic           rd_track_queue[$];
    logic           rd_last_queue[$];

    bit     [AXI_STRB_BITS-1:0]    mem_valid            [key_t];
    data_t                          mem_data             [key_t];
    logic   wr_active;
    id_t    wr_id;
    addr_t  wr_addr;
    len_t   wr_len;
    size_t  wr_size;
    burst_t wr_burst;


    function automatic key_t addr_key
            (
                input   addr_t  addr
            );
    begin
        addr_key = key_t'(addr);
    end
    endfunction

    function automatic addr_t align_addr
            (
                input   addr_t  addr
            );
        if ( AXI_ADDR_LSB > 0 ) begin
            align_addr = addr_t'({addr[AXI_ADDR_BITS-1:AXI_ADDR_LSB], {AXI_ADDR_LSB{1'b0}}});
        end
        else begin
            align_addr = addr;
        end
    endfunction

    function automatic bit has_full_valid
            (
                input   addr_t  addr
            );
        key_t key;
    begin
        key = addr_key(addr);
        has_full_valid = mem_valid.exists(key) && (mem_valid[key] == {AXI_STRB_BITS{1'b1}});
    end
    endfunction


    wire    issue_aw = mon_axi4.awvalid && mon_axi4.awready;
    wire    issue_w  = mon_axi4.wvalid  && mon_axi4.wready;
    wire    issue_b  = mon_axi4.bvalid  && mon_axi4.bready;
    wire    issue_ar = mon_axi4.arvalid && mon_axi4.arready;
    wire    issue_r  = mon_axi4.rvalid  && mon_axi4.rready;


    always @(posedge mon_axi4.aclk) begin
        addr_t      addr;
        id_t        id;
        data_t      wr_data;
        strb_t      wr_strb;
        logic       wr_track;
        logic       rd_track;
        data_t      rd_expect;
        logic       beat_last;
        logic       burst_ok;
        logic       expected_last;
        int         beat_count;
        key_t       key;

        if ( !mon_axi4.aresetn ) begin
            aw_id_queue.delete();
            aw_addr_queue.delete();
            aw_len_queue.delete();
            aw_size_queue.delete();
            aw_burst_queue.delete();

            wr_bid_expect_queue.delete();
            rd_addr_queue.delete();
            rd_id_queue.delete();
            rd_expect_queue.delete();
            rd_track_queue.delete();
            rd_last_queue.delete();

            mem_valid.delete();
            mem_data.delete();

            wr_active = 1'b0;
            wr_id     = '0;
            wr_addr   = '0;
            wr_len    = '0;
            wr_size   = '0;
            wr_burst  = '0;
        end
        else if ( mon_axi4.aclken ) begin
            if ( issue_aw ) begin
                assert (aw_id_queue.size() < AW_QUEUE_LIMIT)
                    else $error("ERROR: %m: aw queue overflow size=%0d", aw_id_queue.size());

                aw_id_queue.push_back(mon_axi4.awid);
                aw_addr_queue.push_back(align_addr(mon_axi4.awaddr));
                aw_len_queue.push_back(mon_axi4.awlen);
                aw_size_queue.push_back(mon_axi4.awsize);
                aw_burst_queue.push_back(mon_axi4.awburst);
                wr_bid_expect_queue.push_back(mon_axi4.awid);
            end

            if ( issue_w ) begin
                if ( !wr_active ) begin
                    assert (aw_id_queue.size() > 0)
                        else $error("ERROR: %m: write data without pending aw");
                    if ( aw_id_queue.size() > 0 ) begin
                        wr_id    = aw_id_queue.pop_front();
                        wr_addr  = aw_addr_queue.pop_front();
                        wr_len   = aw_len_queue.pop_front();
                        wr_size  = aw_size_queue.pop_front();
                        wr_burst = aw_burst_queue.pop_front();
                        wr_active = 1'b1;
                    end
                end

                if ( wr_active ) begin
                    expected_last = (wr_len == 0);
                    if ( CHECK_WLAST ) begin
                        assert (mon_axi4.wlast == expected_last)
                            else $error("ERROR: %m: wlast mismatch addr=%h len=%0d wlast=%0d", wr_addr, wr_len, mon_axi4.wlast);
                    end

                    wr_track = (wr_size == FULL_SIZE) && (wr_burst == BURST_INCR);

                    if ( wr_track ) begin
                        key = addr_key(wr_addr);
                        if ( !mem_valid.exists(key) ) begin
                            mem_valid[key] = '0;
                            mem_data[key]  = '0;
                        end
                        for ( int i = 0; i < AXI_STRB_BITS; ++i ) begin
                            if ( mon_axi4.wstrb[i] ) begin
                                mem_data[key][i*8 +: 8] = mon_axi4.wdata[i*8 +: 8];
                                mem_valid[key][i]        = 1'b1;
                            end
                        end
                    end

                    // AR~R の間に同アドレスへの書き込みが確定したので in-flight read の比較を無効化
                    if ( wr_track ) begin
                        for ( int i = 0; i < rd_addr_queue.size(); ++i ) begin
                            if ( rd_addr_queue[i] == wr_addr ) begin
                                rd_track_queue[i] = 1'b0;
                            end
                        end
                    end

                    if ( expected_last ) begin
                        wr_active = 1'b0;
                    end
                    else begin
                        wr_addr = wr_addr + addr_t'(1 << wr_size);
                        wr_len  = wr_len - len_t'(1);
                    end
                end
            end

            if ( issue_ar ) begin
                addr_t  burst_addr;
                bit     burst_track;

                burst_addr  = align_addr(mon_axi4.araddr);
                burst_track = (mon_axi4.arsize == FULL_SIZE) && (mon_axi4.arburst == BURST_INCR);
                beat_count  = int'(mon_axi4.arlen) + 1;

                for ( int beat = 0; beat < beat_count; ++beat ) begin
                    // AR 時点の有効データをスナップショット
                    // burst_track かつ当該アドレスが書き込み済みの場合のみ比較対象とする
                    rd_track = burst_track && has_full_valid(burst_addr);
                    key      = addr_key(burst_addr);

                    rd_addr_queue.push_back(burst_addr);
                    rd_id_queue.push_back(mon_axi4.arid);
                    rd_expect_queue.push_back(rd_track ? mem_data[key] : '0);
                    rd_track_queue.push_back(rd_track);
                    rd_last_queue.push_back(beat == (beat_count - 1));

                    if ( SHOW_SKIP && !rd_track ) begin
                        $display("[%m(%t)] read issue skip-check addr=%h", $time, burst_addr);
                    end
                    else if ( SHOW_SKIP ) begin
                        $display("[%m(%t)] read issue check addr=%h data=%h", $time, burst_addr, mem_data[key]);
                    end

                    burst_addr = burst_addr + addr_t'(1 << mon_axi4.arsize);
                end

                assert (rd_addr_queue.size() <= R_QUEUE_LIMIT)
                    else $error("ERROR: %m: read queue overflow size=%0d", rd_addr_queue.size());
            end

            if ( issue_b ) begin
                assert (wr_bid_expect_queue.size() > 0)
                    else $error("ERROR: %m: b response without pending write burst");

                id = wr_bid_expect_queue.size() > 0 ? wr_bid_expect_queue.pop_front() : '0;
                if ( CHECK_BID ) begin
                    assert (mon_axi4.bid == id)
                        else $error("ERROR: %m: bid mismatch expected=%0d actual=%0d", id, mon_axi4.bid);
                end

                burst_ok = (!CHECK_BRESP || mon_axi4.bresp == RESP_OKAY);
                if ( !burst_ok ) begin
                    $error("ERROR: %m: bresp error id=%0d resp=%0d", mon_axi4.bid, mon_axi4.bresp);
                end
            end

            if ( issue_r ) begin
                assert (rd_addr_queue.size() > 0)
                    else $error("ERROR: %m: r response without pending read beat");

                if ( rd_addr_queue.size() > 0 ) begin
                    addr      = rd_addr_queue.pop_front();
                    id        = rd_id_queue.pop_front();
                    rd_expect = rd_expect_queue.pop_front();
                    rd_track  = rd_track_queue.pop_front();
                    beat_last = rd_last_queue.pop_front();

                    if ( CHECK_RID ) begin
                        assert (mon_axi4.rid == id)
                            else $error("ERROR: %m: rid mismatch expected=%0d actual=%0d", id, mon_axi4.rid);
                    end

                    if ( CHECK_RLAST ) begin
                        assert (mon_axi4.rlast == beat_last)
                            else $error("ERROR: %m: rlast mismatch addr=%h expected=%0d actual=%0d", addr, beat_last, mon_axi4.rlast);
                    end

                    if ( rd_track ) begin
                        // AR 時点でスナップショットした期待値と比較
                        if ( CHECK_RRESP && mon_axi4.rresp != RESP_OKAY ) begin
                            $error("ERROR: %m: rresp error addr=%h resp=%0d", addr, mon_axi4.rresp);
                        end
                        else if ( mon_axi4.rdata !== rd_expect ) begin
                            $error("ERROR: %m: read data mismatch addr=%h expected=%h actual=%h", addr, rd_expect, mon_axi4.rdata);
                        end
                        else if ( SHOW_MATCH ) begin
                            $display("[%m(%t)] read match addr=%h data=%h", $time, addr, mon_axi4.rdata);
                        end
                    end
                    else if ( SHOW_SKIP ) begin
                        $display("[%m(%t)] read skip-check addr=%h", $time, addr);
                    end
                end
            end
        end
    end

endmodule


`default_nettype wire


// end of file
