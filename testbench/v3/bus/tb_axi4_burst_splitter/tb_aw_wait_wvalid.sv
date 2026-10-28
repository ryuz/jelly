`timescale 1ns / 1ps
`default_nettype none


module tb_aw_wait_wvalid
        #(
            parameter bit WAIT_WVALID = 1'b1,
            parameter bit WAIT_WLAST = 1'b0,
            parameter bit W_EARLY = WAIT_WLAST,
            parameter int CHUNK_BEATS = 3,
            parameter int B_DELAY = 0
        );

    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic aresetn = 1'b0;
    initial begin
        repeat (10) @(negedge clk);
        aresetn = 1'b1;
    end

    jelly3_axi4_if #(.ID_BITS(4), .ADDR_BITS(32), .DATA_BITS(32))
        s_axi4 (.aresetn(aresetn), .aclk(clk), .aclken(1'b1));
    jelly3_axi4_if #(.ID_BITS(4), .ADDR_BITS(32), .DATA_BITS(32))
        m_axi4 (.aresetn(aresetn), .aclk(clk), .aclken(1'b1));

    jelly3_axi4_burst_splitter u_dut (
        .s_axi4 (s_axi4.s),
        .m_axi4 (m_axi4.m)
    );

    jelly3_axi4_accessor #(.RAND_RATE_B(80))
        u_accessor (.m_axi4(s_axi4.m));

    logic aw_active;
    logic w_seen;
    logic w_complete;
    logic bvalid;
    logic [3:0] bid;
    logic [1:0] bresp;
    logic buser;
    logic b_pending;
    int b_delay_remaining;
    logic [1:0] first_resp;
    logic [1:0] last_resp;
    wire [1:0] expected_resp = first_resp > last_resp ? first_resp : last_resp;
    int aw_count;
    int w_count;
    int b_count;
    int s_b_count;
    int b_stall_count;
    logic s_b_stalled;
    logic [6:0] held_b;

    assign m_axi4.awready = !aw_active && !bvalid && !b_pending &&
                            (WAIT_WLAST ? w_complete : (!WAIT_WVALID || w_seen));
    assign m_axi4.wready  = !w_complete && !bvalid && !b_pending && (W_EARLY || aw_active);
    assign m_axi4.bid     = bid;
    assign m_axi4.bresp   = bresp;
    assign m_axi4.buser   = buser;
    assign m_axi4.bvalid  = bvalid;
    assign m_axi4.arready = 1'b0;
    assign m_axi4.rid     = '0;
    assign m_axi4.rdata   = '0;
    assign m_axi4.rresp   = '0;
    assign m_axi4.rlast   = 1'b0;
    assign m_axi4.ruser   = '0;
    assign m_axi4.rvalid  = 1'b0;

    always_ff @(posedge clk) begin
        if ( !aresetn ) begin
            aw_active <= 1'b0;
            w_seen    <= 1'b0;
            w_complete <= 1'b0;
            bvalid    <= 1'b0;
            bid       <= '0;
            bresp     <= '0;
            buser     <= 1'b0;
            b_pending <= 1'b0;
            b_delay_remaining <= 0;
            aw_count  <= 0;
            w_count   <= 0;
            b_count   <= 0;
            s_b_count <= 0;
            b_stall_count <= 0;
            s_b_stalled <= 1'b0;
            held_b <= '0;
        end
        else begin
            if ( m_axi4.wvalid ) begin
                w_seen <= 1'b1;
            end
            if ( m_axi4.awvalid && m_axi4.awready ) begin
                assert (m_axi4.awid == 4'h3 && int'(m_axi4.awlen) == CHUNK_BEATS - 1 &&
                    m_axi4.awaddr == ((aw_count % 2 == 0) ? 32'(4096 - CHUNK_BEATS * 4) : 32'h0000_1000))
                    else $fatal(1, "unexpected split AW count=%0d", aw_count);
                aw_active <= 1'b1;
                bid <= m_axi4.awid;
                aw_count <= aw_count + 1;
            end
            if ( m_axi4.wvalid && m_axi4.wready ) begin
                assert (m_axi4.wdata == (32'h1234_5678 + 32'(w_count % (2 * CHUNK_BEATS))) &&
                        m_axi4.wstrb == 4'hf && m_axi4.wlast == (w_count % CHUNK_BEATS == CHUNK_BEATS - 1))
                    else $fatal(1, "write payload mismatch");
                w_count <= w_count + 1;
                if ( m_axi4.wlast ) begin
                    w_complete <= 1'b1;
                end
            end
            if ( (aw_active || (m_axi4.awvalid && m_axi4.awready)) &&
                 (w_complete || (m_axi4.wvalid && m_axi4.wready && m_axi4.wlast)) ) begin
                aw_active <= 1'b0;
                w_complete <= 1'b0;
                w_seen <= 1'b0;
                bresp <= (b_count % 2 == 0) ? first_resp : last_resp;
                buser <= (b_count % 2 == 1);
                bvalid <= (B_DELAY == 0);
                b_pending <= (B_DELAY != 0);
                b_delay_remaining <= B_DELAY;
            end
            if ( b_pending ) begin
                if ( b_delay_remaining <= 1 ) begin
                    bvalid <= 1'b1;
                    b_pending <= 1'b0;
                end
                else begin
                    b_delay_remaining <= b_delay_remaining - 1;
                end
            end
            if ( m_axi4.bvalid && m_axi4.bready ) begin
                bvalid <= 1'b0;
                b_count <= b_count + 1;
            end
            if ( s_b_stalled ) begin
                assert (s_axi4.bvalid && {s_axi4.bid, s_axi4.bresp, s_axi4.buser} == held_b)
                    else $fatal(1, "upstream B response changed while stalled");
            end
            s_b_stalled <= s_axi4.bvalid && !s_axi4.bready;
            held_b <= {s_axi4.bid, s_axi4.bresp, s_axi4.buser};
            if ( s_axi4.bvalid && !s_axi4.bready ) begin
                b_stall_count <= b_stall_count + 1;
            end
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                assert (s_axi4.bid == 4'h3 && s_axi4.bresp == expected_resp && s_axi4.buser == 1'b1)
                    else $fatal(1, "upstream B mismatch BID=%h BRESP=%h expected=%h BUSER=%h",
                                s_axi4.bid, s_axi4.bresp, expected_resp, s_axi4.buser);
                s_b_count <= s_b_count + 1;
            end
        end
    end

    initial begin
        automatic logic [31:0] wr_datas[];
        automatic logic [3:0] wr_strbs[];

        wait (aresetn);
        wr_datas = new[2 * CHUNK_BEATS];
        wr_strbs = new[2 * CHUNK_BEATS];
        for ( int beat_idx = 0; beat_idx < 2 * CHUNK_BEATS; beat_idx++ ) begin
            wr_datas[beat_idx] = 32'h1234_5678 + 32'(beat_idx);
            wr_strbs[beat_idx] = '1;
        end
        for ( int first_code = 0; first_code < 3; first_code++ ) begin
            for ( int last_code = 0; last_code < 3; last_code++ ) begin
                first_resp = first_code == 0 ? 2'b00 : 2'(first_code + 1);
                last_resp = last_code == 0 ? 2'b00 : 2'(last_code + 1);
                u_accessor.write(4'h3, 32'(4096 - CHUNK_BEATS * 4), 3'd2, 2'b01,
                                 '0, '0, '0, '0, '0, '0, wr_datas, wr_strbs);
            end
        end
        repeat (10) @(negedge clk);
        assert (aw_count == 18 && w_count == 18 * CHUNK_BEATS &&
            b_count == 18 && s_b_count == 9 && b_stall_count > 0)
            else $fatal(1, "response count mismatch AW=%0d B=%0d source_B=%0d stalls=%0d",
                        aw_count, b_count, s_b_count, b_stall_count);
        $display("tb_aw_wait_wvalid : PASS WAIT_WVALID=%0d WAIT_WLAST=%0d W_EARLY=%0d CHUNK_BEATS=%0d B_DELAY=%0d response_pairs=9 B_stalls=%0d",
             WAIT_WVALID, WAIT_WLAST, W_EARLY, CHUNK_BEATS, B_DELAY, b_stall_count);
        $finish;
    end

    initial begin
        wait (aresetn);
        repeat (10000) @(negedge clk);
        $fatal(1, "AW/W deadlock: source WVALID=%b downstream AWVALID=%b AWREADY=%b WVALID=%b WREADY=%b BVALID=%b AW=%0d B=%0d",
               s_axi4.wvalid, m_axi4.awvalid, m_axi4.awready,
               m_axi4.wvalid, m_axi4.wready, m_axi4.bvalid, aw_count, b_count);
    end

endmodule


`default_nettype wire


// end of file