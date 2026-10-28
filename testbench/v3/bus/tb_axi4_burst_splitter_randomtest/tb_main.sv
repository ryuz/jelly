`timescale 1ns / 1ps
`default_nettype none


// Random stress test for jelly3_axi4_burst_splitter.
//  - AW/W ordering: random skew, AW-first, W-first (WVALID asserted before AWVALID)
//  - multiple outstanding commands on both write and read paths, reads overlap writes
//  - multiple 4KB crossings per burst (wide bus), unaligned start, narrow transfers
//  - random stalls on every channel, optional ACLKEN gating, small-FIFO backpressure
module tb_main
        #(
            parameter int DATA_BITS           = 32  ,
            parameter int NUM_TESTS           = 512 ,
            parameter int FIFO_PTR_BITS       = 5   ,   // DUT FIFO depth
            parameter int BUSY_RATE           = 30  ,   // % stall on every channel
            parameter int CKE_BUSY_RATE       = 0   ,   // % cycles with aclken low
            parameter int MAX_OUTSTANDING     = 8   ,   // commands in flight (per direction)
            parameter int MODEL_FIFO_PTR_BITS = 0       // downstream slave AW/W/AR queue depth
        )
        (
            input   var logic   clk,
            input   var logic   reset
        );

    localparam int ID_BITS      = 4;
    localparam int ADDR_BITS    = 32;
    localparam int DATA_BYTES   = DATA_BITS / 8;
    localparam int MAX_SIZE     = $clog2(DATA_BYTES);
    localparam int MAX_BEATS    = 256;
    localparam int NUM_REGIONS  = 16;
    localparam int REGION_BYTES = (2 * MAX_BEATS * DATA_BYTES > 8192) ? 2 * MAX_BEATS * DATA_BYTES : 8192;
    localparam int MEM_BYTES    = NUM_REGIONS * REGION_BYTES;
    localparam int MEM_ADDR_BITS = $clog2(MEM_BYTES / DATA_BYTES);
    localparam int CHECK_QUEUE_DEPTH = 64;

    localparam type id_t   = logic [ID_BITS-1:0];
    localparam type addr_t = logic [ADDR_BITS-1:0];
    localparam type len_t  = logic [7:0];
    localparam type size_t = logic [2:0];
    localparam type data_t = logic [DATA_BITS-1:0];
    localparam type strb_t = logic [DATA_BYTES-1:0];

    localparam id_t TEST_ID = id_t'(5);

    localparam int MODE_RANDOM   = 0;
    localparam int MODE_AW_FIRST = 1;
    localparam int MODE_W_FIRST  = 2;

    logic aresetn;
    assign aresetn = ~reset;

    logic aclken = 1'b1;
    always_ff @(posedge clk) begin
        aclken <= (CKE_BUSY_RATE == 0) || ($urandom_range(99) >= CKE_BUSY_RATE);
    end

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS),
                .ADDR_BITS  (ADDR_BITS),
                .DATA_BITS  (DATA_BITS),
                .SIMULATION ("true")
            )
        s_axi4 (
                .aresetn    (aresetn),
                .aclk       (clk),
                .aclken     (aclken)
            );

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS),
                .ADDR_BITS  (ADDR_BITS),
                .DATA_BITS  (DATA_BITS),
                .SIMULATION ("true")
            )
        m_axi4 (
                .aresetn    (aresetn),
                .aclk       (clk),
                .aclken     (aclken)
            );

    jelly3_axi4_burst_splitter
            #(
                .FIFO_PTR_BITS  (FIFO_PTR_BITS),
                .SIMULATION     ("true")
            )
        u_dut (
                .s_axi4 (s_axi4.s),
                .m_axi4 (m_axi4.m)
            );

    logic       s_error;
    logic [10:0] s_error_flags;
    logic [3:0] s_error_code;
    id_t        s_error_id;
    addr_t      s_error_addr;
    logic [7:0] s_error_len;

    jelly3_axi4_protocol_checker
            #(
                .CHECK_QUEUE_DEPTH (CHECK_QUEUE_DEPTH)
            )
        u_checker_s (
                .mon_axi4    (s_axi4.mon),
                .error       (s_error),
                .error_flags (s_error_flags),
                .error_code  (s_error_code),
                .error_id    (s_error_id),
                .error_addr  (s_error_addr),
                .error_len   (s_error_len)
            );

    logic       m_error;
    logic [10:0] m_error_flags;
    logic [3:0] m_error_code;
    id_t        m_error_id;
    addr_t      m_error_addr;
    logic [7:0] m_error_len;

    jelly3_axi4_protocol_checker
            #(
                .CHECK_QUEUE_DEPTH (CHECK_QUEUE_DEPTH)
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
                .MEM_ADDR_BITS      (MEM_ADDR_BITS),
                .AW_FIFO_PTR_BITS   (MODEL_FIFO_PTR_BITS),
                .W_FIFO_PTR_BITS    (MODEL_FIFO_PTR_BITS),
                .B_FIFO_PTR_BITS    (MODEL_FIFO_PTR_BITS),
                .AR_FIFO_PTR_BITS   (MODEL_FIFO_PTR_BITS),
                .R_FIFO_PTR_BITS    (MODEL_FIFO_PTR_BITS),
                .AW_BUSY_RATE       (BUSY_RATE),
                .W_BUSY_RATE        (BUSY_RATE),
                .B_BUSY_RATE        (BUSY_RATE),
                .AR_BUSY_RATE       (BUSY_RATE),
                .R_BUSY_RATE        (BUSY_RATE)
            )
        u_model (
                .s_axi4 (m_axi4.s)
            );


    // ---------------------------------------------
    //  command table (generated at time 0)
    // ---------------------------------------------

    addr_t  cmd_addr   [NUM_TESTS];
    int     cmd_beats  [NUM_TESTS];
    int     cmd_size   [NUM_TESTS];
    int     cmd_mode   [NUM_TESTS];
    int     cmd_chunks [NUM_TESTS];

    int     total_chunks;
    int     cov_crossing, cov_multi, cov_single, cov_unaligned, cov_narrow;
    int     cov_mode [3];

    // reference: number of AXI4-legal bursts the command must be split into
    function automatic int calc_chunks(input addr_t addr, input int beats, input int size);
        int a, remain, bytes, to_bnd, c, n;
        bytes  = 1 << size;
        a      = (int'(addr) / bytes) * bytes;
        remain = beats;
        n      = 0;
        while ( remain > 0 ) begin
            to_bnd = (4096 - (a % 4096)) / bytes;
            c      = (remain < to_bnd) ? remain : to_bnd;
            remain -= c;
            a      += c * bytes;
            n++;
        end
        return n;
    endfunction

    initial begin
        automatic int beats, size, bytes, span, kind, base, off, k_beats, max_k;
        total_chunks  = 0;
        cov_crossing  = 0; cov_multi = 0; cov_single = 0; cov_unaligned = 0; cov_narrow = 0;
        cov_mode[0] = 0; cov_mode[1] = 0; cov_mode[2] = 0;
        for ( int k = 0; k < NUM_TESTS; k++ ) begin
            beats = $urandom_range(MAX_BEATS, 1);
            size  = ($urandom_range(99) < 70) ? MAX_SIZE : $urandom_range(MAX_SIZE, 0);
            bytes = 1 << size;
            kind  = k % 4;
            base  = (k % NUM_REGIONS) * REGION_BYTES;
            case ( kind )
                0, 1: begin     // crosses the first boundary
                    if ( beats < 2 ) beats = 2;
                    max_k   = (beats - 1 < 4096 / bytes) ? beats - 1 : 4096 / bytes;
                    k_beats = $urandom_range(max_k, 1);
                    off     = 4096 - k_beats * bytes;
                end
                2: begin        // ends exactly on the boundary
                    span = beats * bytes;
                    off  = (span <= 4096) ? 4096 - span : 0;
                end
                default: begin  // inside one page when it fits
                    span = beats * bytes;
                    off  = (span <= 4096) ? $urandom_range((4096 - span) / bytes, 0) * bytes : 0;
                end
            endcase
            if ( bytes > 1 && $urandom_range(99) < 25 ) begin
                off += $urandom_range(bytes - 1, 1);
                cov_unaligned++;
            end
            cmd_addr[k]   = addr_t'(base + off);
            cmd_beats[k]  = beats;
            cmd_size[k]   = size;
            cmd_mode[k]   = $urandom_range(2);
            cmd_chunks[k] = calc_chunks(cmd_addr[k], beats, size);
            total_chunks += cmd_chunks[k];
            if ( cmd_chunks[k] > 1 ) cov_crossing++; else cov_single++;
            if ( cmd_chunks[k] > 2 ) cov_multi++;
            if ( size < MAX_SIZE )   cov_narrow++;
            cov_mode[cmd_mode[k]]++;
        end
    end

    // byte address and valid lane range of beat i
    function automatic int beat_byte_addr(input int k, input int i);
        int bytes;
        bytes = 1 << cmd_size[k];
        return (i == 0) ? int'(cmd_addr[k]) : (int'(cmd_addr[k]) / bytes) * bytes + i * bytes;
    endfunction

    function automatic int lane_lo(input int k, input int i);
        return beat_byte_addr(k, i) % DATA_BYTES;
    endfunction

    function automatic int lane_hi(input int k, input int i);
        int bytes;
        bytes = 1 << cmd_size[k];
        return ((beat_byte_addr(k, i) / bytes) * bytes) % DATA_BYTES + bytes - 1;
    endfunction

    function automatic int word_base(input int k, input int i);
        return (beat_byte_addr(k, i) / DATA_BYTES) * DATA_BYTES;
    endfunction


    // ---------------------------------------------
    //  reference memory (scoreboard)
    // ---------------------------------------------

    bit [7:0]   ref_mem [0:MEM_BYTES-1];
    initial begin
        for ( int i = 0; i < MEM_BYTES; i++ ) ref_mem[i] = '0;
    end


    // ---------------------------------------------
    //  upstream master drivers
    // ---------------------------------------------

    logic   aw_valid = 1'b0;
    addr_t  aw_addr;
    len_t   aw_len;
    size_t  aw_size;
    logic   w_valid = 1'b0;
    data_t  w_data;
    strb_t  w_strb;
    logic   w_last;
    logic   ar_valid = 1'b0;
    addr_t  ar_addr;
    len_t   ar_len;
    size_t  ar_size;
    logic   b_ready = 1'b1;
    logic   r_ready = 1'b1;

    always_ff @(posedge clk) begin
        if ( aclken ) begin
            b_ready <= (BUSY_RATE == 0) || ($urandom_range(99) >= BUSY_RATE);
            r_ready <= (BUSY_RATE == 0) || ($urandom_range(99) >= BUSY_RATE);
        end
    end

    assign s_axi4.awid     = TEST_ID;
    assign s_axi4.awaddr   = aw_addr;
    assign s_axi4.awlen    = aw_len;
    assign s_axi4.awsize   = aw_size;
    assign s_axi4.awburst  = 2'b01;
    assign s_axi4.awlock   = '0;
    assign s_axi4.awcache  = '0;
    assign s_axi4.awprot   = '0;
    assign s_axi4.awqos    = '0;
    assign s_axi4.awregion = '0;
    assign s_axi4.awuser   = '0;
    assign s_axi4.awvalid  = aw_valid;
    assign s_axi4.wdata    = w_data;
    assign s_axi4.wstrb    = w_strb;
    assign s_axi4.wlast    = w_last;
    assign s_axi4.wuser    = '0;
    assign s_axi4.wvalid   = w_valid;
    assign s_axi4.bready   = b_ready;
    assign s_axi4.arid     = TEST_ID;
    assign s_axi4.araddr   = ar_addr;
    assign s_axi4.arlen    = ar_len;
    assign s_axi4.arsize   = ar_size;
    assign s_axi4.arburst  = 2'b01;
    assign s_axi4.arlock   = '0;
    assign s_axi4.arcache  = '0;
    assign s_axi4.arprot   = '0;
    assign s_axi4.arqos    = '0;
    assign s_axi4.arregion = '0;
    assign s_axi4.aruser   = '0;
    assign s_axi4.arvalid  = ar_valid;
    assign s_axi4.rready   = r_ready;

    // handshake flags registered at the clock edge (drivers update at posedge + #1)
    logic issue_aw, issue_w, issue_ar;
    logic cke_q;    // aclken that was effective at the last edge
    always_ff @(posedge clk) begin
        cke_q    <= aclken;
        issue_aw <= aclken && s_axi4.awvalid && s_axi4.awready;
        issue_w  <= aclken && s_axi4.wvalid  && s_axi4.wready;
        issue_ar <= aclken && s_axi4.arvalid && s_axi4.arready;
    end

    bit     aw_done      [NUM_TESTS];   // AW accepted
    bit     w_presented  [NUM_TESTS];   // first WVALID asserted
    int     aw_issued    = 0;
    int     ar_issued    = 0;
    int     b_count      = 0;
    int     r_done_count = 0;
    int     errors       = 0;
    int     cov_w_led    = 0;   // WVALID was already asserted when AW was accepted
    int     cov_aw_led   = 0;
    int     max_out_w    = 0;   // observed outstanding depth
    int     max_out_r    = 0;

    // advance to just after an enabled clock edge; signals are never changed across a gated edge
    task automatic tick();
        do begin @(posedge clk); #1; end while ( !cke_q );
    endtask

    // write command k must not start until the read of the previous user of its region is done
    task automatic wait_region_free(input int k);
        while ( k >= NUM_REGIONS && r_done_count <= k - NUM_REGIONS ) tick();
    endtask

    task automatic drive_aw();
        for ( int k = 0; k < NUM_TESTS; k++ ) begin
            while ( k - b_count >= MAX_OUTSTANDING ) tick();
            wait_region_free(k);
            if ( cmd_mode[k] == MODE_W_FIRST ) begin
                while ( !w_presented[k] ) tick();
                repeat ($urandom_range(8, 1)) tick();
            end
            else begin
                repeat ($urandom_range(3, 0)) tick();
            end
            aw_addr  = cmd_addr[k];
            aw_len   = len_t'(cmd_beats[k] - 1);
            aw_size  = size_t'(cmd_size[k]);
            aw_valid = 1'b1;
            do tick(); while ( !issue_aw );
            aw_valid   = 1'b0;
            aw_done[k] = 1'b1;
            if ( w_presented[k] ) cov_w_led++; else cov_aw_led++;
        end
    endtask

    task automatic drive_w();
        int lo, hi, wb;
        for ( int k = 0; k < NUM_TESTS; k++ ) begin
            wait_region_free(k);
            if ( cmd_mode[k] == MODE_AW_FIRST ) begin
                while ( !aw_done[k] ) tick();
                repeat ($urandom_range(8, 0)) tick();
            end
            else begin
                repeat ($urandom_range(2, 0)) tick();
            end
            for ( int i = 0; i < cmd_beats[k]; i++ ) begin
                if ( i > 0 && BUSY_RATE > 0 && $urandom_range(99) < BUSY_RATE ) repeat ($urandom_range(3, 1)) tick();
                lo = lane_lo(k, i);
                hi = lane_hi(k, i);
                wb = word_base(k, i);
                for ( int l = 0; l < DATA_BYTES; l++ ) begin
                    w_data[l*8 +: 8] = 8'($urandom);
                    w_strb[l] = (l >= lo && l <= hi) && ($urandom_range(99) < 90);
                    if ( w_strb[l] ) ref_mem[wb + l] = w_data[l*8 +: 8];
                end
                w_last  = (i == cmd_beats[k] - 1);
                w_valid = 1'b1;
                w_presented[k] = 1'b1;
                do tick(); while ( !issue_w );
                w_valid = 1'b0;
            end
        end
    endtask

    task automatic drive_ar();
        for ( int k = 0; k < NUM_TESTS; k++ ) begin
            while ( b_count <= k ) tick();
            while ( k - r_done_count >= MAX_OUTSTANDING ) tick();
            repeat ($urandom_range(3, 0)) tick();
            ar_addr  = cmd_addr[k];
            ar_len   = len_t'(cmd_beats[k] - 1);
            ar_size  = size_t'(cmd_size[k]);
            ar_valid = 1'b1;
            do tick(); while ( !issue_ar );
            ar_valid = 1'b0;
            ar_issued++;
        end
    endtask


    // ---------------------------------------------
    //  monitors
    // ---------------------------------------------

    int s_aw_count = 0;
    int s_ar_count = 0;
    int m_aw_count = 0;
    int m_ar_count = 0;
    int m_b_count  = 0;
    int m_rlast_count = 0;
    int r_cmd  = 0;
    int r_beat = 0;

    always_ff @(posedge clk) begin
        if ( aresetn && aclken ) begin
            if ( s_axi4.awvalid && s_axi4.awready ) begin s_aw_count++; aw_issued++; end
            if ( s_axi4.arvalid && s_axi4.arready ) s_ar_count++;
            if ( m_axi4.awvalid && m_axi4.awready ) m_aw_count++;
            if ( m_axi4.arvalid && m_axi4.arready ) m_ar_count++;
            if ( m_axi4.bvalid  && m_axi4.bready  ) m_b_count++;
            if ( m_axi4.rvalid  && m_axi4.rready && m_axi4.rlast ) m_rlast_count++;
            if ( aw_issued - b_count      > max_out_w ) max_out_w = aw_issued - b_count;
            if ( ar_issued - r_done_count > max_out_r ) max_out_r = ar_issued - r_done_count;

            // write response: exactly one per upstream command, in order
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                if ( b_count >= aw_issued ) begin
                    $error("unexpected B: b_count=%0d aw_issued=%0d", b_count, aw_issued); errors++;
                end
                if ( s_axi4.bid !== TEST_ID ) begin
                    $error("bid mismatch: %0d", s_axi4.bid); errors++;
                end
                if ( s_axi4.bresp !== 2'b00 ) begin
                    $error("bresp=%0d for cmd %0d", s_axi4.bresp, b_count); errors++;
                end
                b_count++;
            end

            // read data: compare valid lanes against scoreboard, RLAST only on the final beat
            if ( s_axi4.rvalid && s_axi4.rready ) begin
                if ( r_cmd >= ar_issued ) begin
                    $error("unexpected R: r_cmd=%0d ar_issued=%0d", r_cmd, ar_issued); errors++;
                end
                else begin
                    if ( s_axi4.rid !== TEST_ID ) begin
                        $error("rid mismatch: %0d", s_axi4.rid); errors++;
                    end
                    if ( s_axi4.rresp !== 2'b00 ) begin
                        $error("rresp=%0d cmd=%0d beat=%0d", s_axi4.rresp, r_cmd, r_beat); errors++;
                    end
                    for ( int l = lane_lo(r_cmd, r_beat); l <= lane_hi(r_cmd, r_beat); l++ ) begin
                        if ( s_axi4.rdata[l*8 +: 8] !== ref_mem[word_base(r_cmd, r_beat) + l] ) begin
                            $error("rdata mismatch cmd=%0d beat=%0d lane=%0d addr=%08x exp=%02x act=%02x",
                                   r_cmd, r_beat, l, word_base(r_cmd, r_beat) + l,
                                   ref_mem[word_base(r_cmd, r_beat) + l], s_axi4.rdata[l*8 +: 8]);
                            errors++;
                        end
                    end
                    if ( s_axi4.rlast !== (r_beat == cmd_beats[r_cmd] - 1) ) begin
                        $error("rlast mismatch cmd=%0d beat=%0d/%0d rlast=%b",
                               r_cmd, r_beat, cmd_beats[r_cmd], s_axi4.rlast);
                        errors++;
                    end
                    if ( r_beat == cmd_beats[r_cmd] - 1 ) begin
                        r_cmd++;
                        r_beat = 0;
                        r_done_count++;
                    end
                    else begin
                        r_beat++;
                    end
                end
            end
        end
    end


    // ---------------------------------------------
    //  main
    // ---------------------------------------------

    initial begin
        wait (aresetn);
        repeat (10) tick();

        fork
            drive_aw();
            drive_w();
            drive_ar();
            begin
                automatic int last_shown = 0;
                while ( r_done_count < NUM_TESTS ) begin
                    tick();
                    if ( r_done_count >= last_shown + 64 ) begin
                        last_shown = r_done_count;
                        $display("[%0t] progress: %0d/%0d commands verified", $time, r_done_count, NUM_TESTS);
                    end
                end
            end
        join

        repeat (50) tick();

        $display("config: DATA_BITS=%0d NUM_TESTS=%0d FIFO_PTR_BITS=%0d BUSY_RATE=%0d CKE_BUSY_RATE=%0d MAX_OUTSTANDING=%0d MODEL_FIFO_PTR_BITS=%0d",
                 DATA_BITS, NUM_TESTS, FIFO_PTR_BITS, BUSY_RATE, CKE_BUSY_RATE, MAX_OUTSTANDING, MODEL_FIFO_PTR_BITS);
        $display("coverage: crossing=%0d (multi=%0d) single=%0d unaligned=%0d narrow=%0d mode[random/aw_first/w_first]=%0d/%0d/%0d",
                 cov_crossing, cov_multi, cov_single, cov_unaligned, cov_narrow, cov_mode[0], cov_mode[1], cov_mode[2]);
        $display("observed: aw_led=%0d w_led=%0d max_outstanding_w=%0d max_outstanding_r=%0d",
                 cov_aw_led, cov_w_led, max_out_w, max_out_r);
        $display("counts: s_aw=%0d s_ar=%0d s_b=%0d m_aw=%0d m_ar=%0d m_b=%0d m_rlast=%0d expected_chunks=%0d",
                 s_aw_count, s_ar_count, b_count, m_aw_count, m_ar_count, m_b_count, m_rlast_count, total_chunks);
        $display("checkers: upstream flags=%03x (bit0/1 = expected 4KB crossings) downstream flags=%03x",
                 s_error_flags, m_error_flags);

        assert (errors == 0)
            else $fatal(1, "%0d data/response errors", errors);
        assert (b_count == NUM_TESTS && s_aw_count == NUM_TESTS && s_ar_count == NUM_TESTS)
            else $fatal(1, "upstream count mismatch");
        assert (m_aw_count == total_chunks && m_ar_count == total_chunks &&
                m_b_count == total_chunks && m_rlast_count == total_chunks)
            else $fatal(1, "downstream segment count mismatch");
        assert (m_error_flags == '0)
            else $fatal(1, "downstream checker observed protocol errors flags=%03x code=%0d addr=%08x len=%0d",
                        m_error_flags, m_error_code, m_error_addr, m_error_len);
        assert ((s_error_flags & ~11'h003) == '0)
            else $fatal(1, "upstream checker observed unexpected errors flags=%03x code=%0d", s_error_flags, s_error_code);
        assert (s_error_flags[0] && s_error_flags[1])
            else $fatal(1, "upstream checker did not observe 4KB crossings flags=%03x", s_error_flags);
        assert (cov_crossing > 0 && cov_single > 0 && cov_mode[0] > 0 && cov_mode[1] > 0 && cov_mode[2] > 0)
            else $fatal(1, "coverage hole");
        assert (cov_aw_led > 0 && cov_w_led > 0 && max_out_w > 1 && max_out_r > 1)
            else $fatal(1, "coverage hole: AW/W ordering or outstanding depth");
        assert (MAX_SIZE == 0 || (cov_unaligned > 0 && cov_narrow > 0))
            else $fatal(1, "coverage hole: unaligned/narrow");
        assert (MAX_BEATS * DATA_BYTES <= 4096 || cov_multi > 0)
            else $fatal(1, "coverage hole: multi-crossing");

        $display("tb_axi4_burst_splitter_randomtest : PASS");
        $finish;
    end

endmodule


`default_nettype wire


// end of file