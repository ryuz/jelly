`timescale 1ns / 1ps
`default_nettype none


// Directed tests: each case specifies the exact downstream AW/AR sequence the
// splitter must produce (address, len, burst) and checks data readback.
module tb_main
        #(parameter int DATA_BITS = 32)
        (
            input   var logic   reset,
            input   var logic   clk,
            output  var logic   done
        );

    localparam int ID_BITS    = 4;
    localparam int ADDR_BITS  = 32;
    localparam int DATA_BYTES = DATA_BITS / 8;
    localparam int MAX_SIZE   = $clog2(DATA_BYTES);
    localparam int PAGE_BEATS = 4096 / DATA_BYTES;      // full-width beats per 4KB page

    localparam type id_t    = logic [ID_BITS-1:0];
    localparam type addr_t  = logic [ADDR_BITS-1:0];
    localparam type len_t   = logic [7:0];
    localparam type burst_t = logic [1:0];
    localparam type data_t  = logic [DATA_BITS-1:0];
    localparam type strb_t  = logic [DATA_BYTES-1:0];

    localparam id_t    TEST_ID = id_t'(3);
    localparam burst_t FIXED   = 2'b00;
    localparam burst_t INCR    = 2'b01;
    localparam burst_t WRAP    = 2'b10;

    typedef struct packed {
        addr_t  addr;
        len_t   len;
        burst_t burst;
    } chunk_t;

    logic aresetn;
    assign aresetn = ~reset;

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS    ),
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        s_axi4 (
                .aresetn    (aresetn),
                .aclk       (clk),
                .aclken     (1'b1)
            );

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS    ),
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        m_axi4 (
                .aresetn    (aresetn),
                .aclk       (clk),
                .aclken     (1'b1)
            );

    jelly3_axi4_burst_splitter
            #(
                .SIMULATION ("true")
            )
        u_dut (
                .s_axi4 (s_axi4.s),
                .m_axi4 (m_axi4.m)
            );

    logic        m_error;
    logic [10:0] m_error_flags;
    logic [3:0]  m_error_code;
    id_t         m_error_id;
    addr_t       m_error_addr;
    len_t        m_error_len;

    jelly3_axi4_protocol_checker
            #(
                .CHECK_QUEUE_DEPTH (16)
            )
        u_checker_m (
                .mon_axi4    (m_axi4.mon),
                .error       (m_error),
                .error_flags (m_error_flags),
                .error_code  (m_error_code),
                .error_id    (m_error_id),
                .error_addr  (m_error_addr),
                .error_len   (m_error_len)
            );

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS  (16),
                .AW_BUSY_RATE  (0),
                .W_BUSY_RATE   (0),
                .B_BUSY_RATE   (0),
                .AR_BUSY_RATE  (0),
                .R_BUSY_RATE   (0)
            )
        u_model (
                .s_axi4 (m_axi4.s)
            );

    jelly3_axi4_accessor
        u_accessor (
                .m_axi4 (s_axi4.m)
            );


    // ---------------------------------------------
    //  downstream / upstream monitors
    // ---------------------------------------------

    chunk_t aw_log [$];
    chunk_t ar_log [$];
    int     m_wlast_count;
    int     m_rlast_count;
    int     s_rlast_count;
    int     s_r_count;
    int     s_b_count;

    always_ff @(posedge clk) begin
        if ( aresetn ) begin
            if ( m_axi4.awvalid && m_axi4.awready ) begin
                aw_log.push_back('{addr: m_axi4.awaddr, len: m_axi4.awlen, burst: m_axi4.awburst});
                assert (m_axi4.awid == TEST_ID) else $fatal(1, "awid changed: %h", m_axi4.awid);
            end
            if ( m_axi4.arvalid && m_axi4.arready ) begin
                ar_log.push_back('{addr: m_axi4.araddr, len: m_axi4.arlen, burst: m_axi4.arburst});
                assert (m_axi4.arid == TEST_ID) else $fatal(1, "arid changed: %h", m_axi4.arid);
            end
            if ( m_axi4.wvalid && m_axi4.wready && m_axi4.wlast ) m_wlast_count++;
            if ( m_axi4.rvalid && m_axi4.rready && m_axi4.rlast ) m_rlast_count++;
            if ( s_axi4.rvalid && s_axi4.rready ) begin
                s_r_count++;
                if ( s_axi4.rlast ) s_rlast_count++;
                assert (s_axi4.rid == TEST_ID) else $fatal(1, "rid mismatch: %h", s_axi4.rid);
            end
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                s_b_count++;
                assert (s_axi4.bid == TEST_ID && s_axi4.bresp == 2'b00)
                    else $fatal(1, "B mismatch bid=%h bresp=%h", s_axi4.bid, s_axi4.bresp);
            end
        end
    end


    // ---------------------------------------------
    //  test case runner
    // ---------------------------------------------

    function automatic chunk_t mk(input addr_t addr, input int len, input burst_t burst = INCR);
        return '{addr: addr, len: len_t'(len), burst: burst};
    endfunction

    // reference split for long INCR bursts (hand-written lists are used for the short cases)
    function automatic void expect_incr(ref chunk_t exp [$], input addr_t addr, input int beats, input int size);
        int a, remain, bytes, to_bnd, c;
        bytes  = 1 << size;
        a      = int'(addr);
        remain = beats;
        while ( remain > 0 ) begin
            to_bnd = (4096 - (((a / bytes) * bytes) % 4096)) / bytes;
            c      = (remain < to_bnd) ? remain : to_bnd;
            exp.push_back(mk(addr_t'(a), c - 1));
            remain -= c;
            a       = ((a / bytes) * bytes) + c * bytes;
        end
    endfunction

    // byte lanes carrying data on beat i (INCR semantics, as modelled by jelly3_model_axi4_s)
    function automatic int beat_addr(input addr_t addr, input int i, input int size);
        int bytes;
        bytes = 1 << size;
        return (i == 0) ? int'(addr) : (int'(addr) / bytes) * bytes + i * bytes;
    endfunction

    function automatic int lane_lo(input addr_t addr, input int i, input int size);
        return beat_addr(addr, i, size) % DATA_BYTES;
    endfunction

    function automatic int lane_hi(input addr_t addr, input int i, input int size);
        int bytes;
        bytes = 1 << size;
        return ((beat_addr(addr, i, size) / bytes) * bytes) % DATA_BYTES + bytes - 1;
    endfunction

    int case_num = 0;

    task automatic run_case(
                input string    name,
                input addr_t    addr,
                input int       beats,
                input int       size,
                input burst_t   burst,
                ref   chunk_t   exp [$]
            );
        data_t wr_datas [];
        data_t rd_datas [];
        strb_t wr_strbs [];
        int    lo, hi;

        case_num++;
        aw_log.delete();
        ar_log.delete();
        m_wlast_count = 0;
        m_rlast_count = 0;
        s_rlast_count = 0;
        s_r_count     = 0;
        s_b_count     = 0;

        wr_datas = new[beats];
        wr_strbs = new[beats];
        for ( int i = 0; i < beats; i++ ) begin
            lo = lane_lo(addr, i, size);
            hi = lane_hi(addr, i, size);
            wr_strbs[i] = '0;
            for ( int b = 0; b < DATA_BYTES; b++ ) begin
                wr_datas[i][b*8 +: 8] = 8'h5a ^ 8'(case_num * 16 + i) ^ 8'(b);
                wr_strbs[i][b] = (b >= lo && b <= hi);
            end
        end

        u_accessor.write(TEST_ID, addr, 3'(size), burst, '0, '0, '0, '0, '0, '0, wr_datas, wr_strbs);
        u_accessor.read (TEST_ID, addr, 8'(beats - 1), 3'(size), burst, '0, '0, '0, '0, '0, '0, rd_datas);
        repeat (2) @(posedge clk);

        // data (valid lanes only)
        assert (rd_datas.size() == beats)
            else $fatal(1, "[%0d:%s] read size mismatch: %0d", DATA_BITS, name, rd_datas.size());
        for ( int i = 0; i < beats; i++ ) begin
            for ( int b = lane_lo(addr, i, size); b <= lane_hi(addr, i, size); b++ ) begin
                assert (rd_datas[i][b*8 +: 8] == wr_datas[i][b*8 +: 8])
                    else $fatal(1, "[%0d:%s] readback mismatch beat=%0d lane=%0d expected=%h actual=%h",
                                DATA_BITS, name, i, b, wr_datas[i][b*8 +: 8], rd_datas[i][b*8 +: 8]);
            end
        end

        // downstream command sequence must match exactly
        assert (aw_log.size() == exp.size() && ar_log.size() == exp.size())
            else $fatal(1, "[%0d:%s] chunk count mismatch expected=%0d AW=%0d AR=%0d",
                        DATA_BITS, name, exp.size(), aw_log.size(), ar_log.size());
        for ( int i = 0; i < exp.size(); i++ ) begin
            assert (aw_log[i] == exp[i])
                else $fatal(1, "[%0d:%s] AW[%0d] mismatch addr=%08x len=%0d burst=%0d expected addr=%08x len=%0d burst=%0d",
                            DATA_BITS, name, i, aw_log[i].addr, aw_log[i].len, aw_log[i].burst,
                            exp[i].addr, exp[i].len, exp[i].burst);
            assert (ar_log[i] == exp[i])
                else $fatal(1, "[%0d:%s] AR[%0d] mismatch addr=%08x len=%0d burst=%0d expected addr=%08x len=%0d burst=%0d",
                            DATA_BITS, name, i, ar_log[i].addr, ar_log[i].len, ar_log[i].burst,
                            exp[i].addr, exp[i].len, exp[i].burst);
        end

        // one WLAST/RLAST per chunk downstream, exactly one RLAST and one B upstream
        assert (m_wlast_count == exp.size() && m_rlast_count == exp.size())
            else $fatal(1, "[%0d:%s] downstream last count mismatch WLAST=%0d RLAST=%0d expected=%0d",
                        DATA_BITS, name, m_wlast_count, m_rlast_count, exp.size());
        assert (s_r_count == beats && s_rlast_count == 1 && s_b_count == 1)
            else $fatal(1, "[%0d:%s] upstream response mismatch R=%0d RLAST=%0d B=%0d",
                        DATA_BITS, name, s_r_count, s_rlast_count, s_b_count);
        assert (m_error_flags == '0)
            else $fatal(1, "[%0d:%s] downstream protocol error flags=%03x code=%0d addr=%08x len=%0d",
                        DATA_BITS, name, m_error_flags, m_error_code, m_error_addr, m_error_len);

        $display("tb_axi4_burst_splitter DATA_BITS=%0d case %0d (%s) : PASS chunks=%0d",
                 DATA_BITS, case_num, name, exp.size());
    endtask


    // ---------------------------------------------
    //  test cases
    // ---------------------------------------------

    initial begin
        automatic chunk_t exp [$];
        automatic int     B = DATA_BYTES;
        automatic int     half;

        done = 1'b0;
        wait (aresetn);
        repeat (10) @(posedge clk);

        // crossing in the middle of a 16-beat burst
        exp.delete();
        exp.push_back(mk(addr_t'(4096 - 8*B), 7));
        exp.push_back(mk(addr_t'(4096),       7));
        run_case("cross_half", addr_t'(4096 - 8*B), 16, MAX_SIZE, INCR, exp);

        // ends exactly on the boundary: no split
        exp.delete();
        exp.push_back(mk(addr_t'(4096 - 16*B), 15));
        run_case("end_at_boundary", addr_t'(4096 - 16*B), 16, MAX_SIZE, INCR, exp);

        // starts exactly on the boundary: no split
        exp.delete();
        exp.push_back(mk(addr_t'(4096), 15));
        run_case("start_at_boundary", addr_t'(4096), 16, MAX_SIZE, INCR, exp);

        // single beat in the last slot of a page
        exp.delete();
        exp.push_back(mk(addr_t'(4096 - B), 0));
        run_case("single_last_beat", addr_t'(4096 - B), 1, MAX_SIZE, INCR, exp);

        // two beats straddling: 1 + 1
        exp.delete();
        exp.push_back(mk(addr_t'(4096 - B), 0));
        exp.push_back(mk(addr_t'(4096),     0));
        run_case("two_beat_straddle", addr_t'(4096 - B), 2, MAX_SIZE, INCR, exp);

        // maximum length starting on the last beat of a page (multiple crossings on wide buses)
        exp.delete();
        expect_incr(exp, addr_t'(4096 - B), 256, MAX_SIZE);
        assert (exp[0] == mk(addr_t'(4096 - B), 0) && exp[1].addr == addr_t'(4096) &&
                exp.size() == 1 + (255 + PAGE_BEATS - 1) / PAGE_BEATS)
            else $fatal(1, "reference split self-check failed");
        run_case("max_len_from_last_beat", addr_t'(4096 - B), 256, MAX_SIZE, INCR, exp);

        // maximum length from a page start (no split unless the burst is longer than a page)
        exp.delete();
        expect_incr(exp, addr_t'(32'h0000_2000), 256, MAX_SIZE);
        run_case("max_len_from_page_start", addr_t'(32'h0000_2000), 256, MAX_SIZE, INCR, exp);

        if ( B > 1 ) begin
            // unaligned start address: first chunk keeps the unaligned address, beat count unchanged
            exp.delete();
            exp.push_back(mk(addr_t'(4096 - 8*B + 1), 7));
            exp.push_back(mk(addr_t'(4096),           7));
            run_case("unaligned_cross", addr_t'(4096 - 8*B + 1), 16, MAX_SIZE, INCR, exp);

            // narrow transfer (half bus width)
            half = B / 2;
            exp.delete();
            exp.push_back(mk(addr_t'(4096 - 8*half), 7));
            exp.push_back(mk(addr_t'(4096),          7));
            run_case("narrow_cross", addr_t'(4096 - 8*half), 16, MAX_SIZE - 1, INCR, exp);

            // narrow + unaligned, boundary inside the burst
            exp.delete();
            exp.push_back(mk(addr_t'(4096 - 3*half + 1), 2));
            exp.push_back(mk(addr_t'(4096),              4));
            run_case("narrow_unaligned_cross", addr_t'(4096 - 3*half + 1), 8, MAX_SIZE - 1, INCR, exp);
        end

        // FIXED / WRAP bursts never cross 4KB and must pass through untouched
        exp.delete();
        exp.push_back(mk(addr_t'(4096 - B), 15, FIXED));
        run_case("fixed_passthrough", addr_t'(4096 - B), 16, MAX_SIZE, FIXED, exp);

        exp.delete();
        exp.push_back(mk(addr_t'(4096 - 2*B), 3, WRAP));
        run_case("wrap_passthrough", addr_t'(4096 - 2*B), 4, MAX_SIZE, WRAP, exp);

        $display("tb_axi4_burst_splitter DATA_BITS=%0d : PASS (%0d cases)", DATA_BITS, case_num);
        done = 1'b1;
    end

endmodule


`default_nettype wire


// end of file