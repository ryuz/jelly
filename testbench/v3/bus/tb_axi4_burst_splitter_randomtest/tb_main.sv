`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   clk,
            input   var logic   reset
        );

    localparam int ID_BITS   = 4;
    localparam int ADDR_BITS = 32;
    localparam int DATA_BITS = 32;
    localparam int NUM_TESTS = 1024;
    localparam int MAX_BEATS = 64;

    localparam type id_t   = logic [ID_BITS-1:0];
    localparam type addr_t = logic [ADDR_BITS-1:0];
    localparam type data_t = logic [DATA_BITS-1:0];
    localparam type strb_t = logic [DATA_BITS/8-1:0];

    logic aresetn;
    assign aresetn = ~reset;

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
                .aclken     (1'b1)
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
                .aclken     (1'b1)
            );

    jelly3_axi4_burst_splitter u_dut (
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
                .CHECK_QUEUE_DEPTH (4)
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
                .CHECK_QUEUE_DEPTH (4)
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
                .AW_BUSY_RATE   (20),
                .W_BUSY_RATE    (20),
                .B_BUSY_RATE    (20),
                .AR_BUSY_RATE   (20),
                .R_BUSY_RATE    (20)
            )
        u_model (
                .s_axi4 (m_axi4.s)
            );

    jelly3_axi4_accessor
        u_accessor (
                .m_axi4 (s_axi4.m)
            );

    logic [31:0] wave_s_awaddr;
    logic [7:0]  wave_s_awlen;
    logic        wave_s_awvalid;
    logic        wave_s_awready;
    logic [31:0] wave_m_awaddr;
    logic [7:0]  wave_m_awlen;
    logic        wave_m_awvalid;
    logic        wave_m_awready;
    logic [31:0] wave_s_araddr;
    logic [7:0]  wave_s_arlen;
    logic        wave_s_arvalid;
    logic        wave_s_arready;
    logic [31:0] wave_m_araddr;
    logic [7:0]  wave_m_arlen;
    logic        wave_m_arvalid;
    logic        wave_m_arready;
    logic        wave_s_wlast;
    logic        wave_m_wlast;
    logic        wave_s_rlast;
    logic        wave_m_rlast;

    assign wave_s_awaddr  = s_axi4.awaddr;
    assign wave_s_awlen   = s_axi4.awlen;
    assign wave_s_awvalid = s_axi4.awvalid;
    assign wave_s_awready = s_axi4.awready;
    assign wave_m_awaddr  = m_axi4.awaddr;
    assign wave_m_awlen   = m_axi4.awlen;
    assign wave_m_awvalid = m_axi4.awvalid;
    assign wave_m_awready = m_axi4.awready;
    assign wave_s_araddr  = s_axi4.araddr;
    assign wave_s_arlen   = s_axi4.arlen;
    assign wave_s_arvalid = s_axi4.arvalid;
    assign wave_s_arready = s_axi4.arready;
    assign wave_m_araddr  = m_axi4.araddr;
    assign wave_m_arlen   = m_axi4.arlen;
    assign wave_m_arvalid = m_axi4.arvalid;
    assign wave_m_arready = m_axi4.arready;
    assign wave_s_wlast   = s_axi4.wlast;
    assign wave_m_wlast   = m_axi4.wlast;
    assign wave_s_rlast   = s_axi4.rlast;
    assign wave_m_rlast   = m_axi4.rlast;

    int s_aw_count;
    int m_aw_count;
    int s_ar_count;
    int m_ar_count;

    always_ff @(posedge clk) begin
        if ( reset ) begin
            s_aw_count <= 0;
            m_aw_count <= 0;
            s_ar_count <= 0;
            m_ar_count <= 0;
        end
        else begin
            if ( s_axi4.awvalid && s_axi4.awready ) s_aw_count <= s_aw_count + 1;
            if ( m_axi4.awvalid && m_axi4.awready ) m_aw_count <= m_aw_count + 1;
            if ( s_axi4.arvalid && s_axi4.arready ) s_ar_count <= s_ar_count + 1;
            if ( m_axi4.arvalid && m_axi4.arready ) m_ar_count <= m_ar_count + 1;
        end
    end

    initial begin
        automatic int    beats;
        automatic int    beats_to_boundary;
        automatic int    page_index;
        automatic int    start_offset_words;
        automatic int    test_kind;
        automatic int    crossing_tests;
        automatic int    boundary_end_tests;
        automatic int    in_page_tests;
        automatic addr_t addr;
        automatic data_t wr_datas[];
        automatic data_t rd_datas[];
        automatic strb_t wr_strbs[];

        wait (aresetn);
        repeat (10) @(posedge clk);

        crossing_tests = 0;
        boundary_end_tests = 0;
        in_page_tests = 0;
        for ( int test_idx = 0; test_idx < NUM_TESTS; test_idx++ ) begin
            page_index = $urandom_range(62, 0);
            beats = $urandom_range(MAX_BEATS, 1);
            test_kind = test_idx % 4;
            case ( test_kind )
                0, 1: begin
                    if ( beats < 2 ) begin
                        beats = 2;
                    end
                    beats_to_boundary = $urandom_range(beats - 1, 1);
                    addr = addr_t'(page_index * 4096 + 4096 - beats_to_boundary * 4);
                    crossing_tests++;
                end
                2: begin
                    beats_to_boundary = beats;
                    addr = addr_t'(page_index * 4096 + 4096 - beats_to_boundary * 4);
                    boundary_end_tests++;
                end
                default: begin
                    start_offset_words = $urandom_range(1024 - beats, 0);
                    addr = addr_t'(page_index * 4096 + start_offset_words * 4);
                    in_page_tests++;
                end
            endcase

            wr_datas = new[beats];
            wr_strbs = new[beats];
            for ( int i = 0; i < beats; i++ ) begin
                wr_datas[i] = $urandom;
                wr_strbs[i] = '1;
            end

            u_accessor.write(
                    id_t'(1),
                    addr,
                    3'h2,
                    2'b01,
                    '0, '0, '0, '0, '0, '0,
                    wr_datas,
                    wr_strbs
                );

            u_accessor.read(
                    id_t'(1),
                    addr,
                    8'(beats - 1),
                    3'h2,
                    2'b01,
                    '0, '0, '0, '0, '0, '0,
                    rd_datas
                );

            assert (rd_datas.size() == beats)
                else $fatal(1, "test=%0d read size mismatch expected=%0d actual=%0d",
                            test_idx, beats, rd_datas.size());
            for ( int i = 0; i < beats; i++ ) begin
                assert (rd_datas[i] == wr_datas[i])
                    else $fatal(1, "test=%0d beat=%0d addr=%08x expected=%08x actual=%08x",
                                test_idx, i, addr, wr_datas[i], rd_datas[i]);
            end
        end

        repeat (10) @(posedge clk);
        assert (s_error_flags[0] && s_error_flags[1])
            else $fatal(1, "input checker did not observe crossings flags=%03x", s_error_flags);
        assert (crossing_tests == NUM_TESTS / 2 &&
                boundary_end_tests == NUM_TESTS / 4 &&
                in_page_tests == NUM_TESTS / 4)
            else $fatal(1, "coverage count mismatch crossing=%0d boundary_end=%0d in_page=%0d",
                        crossing_tests, boundary_end_tests, in_page_tests);
        assert (s_aw_count == NUM_TESTS && s_ar_count == NUM_TESTS &&
                m_aw_count == NUM_TESTS + crossing_tests &&
                m_ar_count == NUM_TESTS + crossing_tests)
            else $fatal(1, "segment count mismatch s_aw=%0d m_aw=%0d s_ar=%0d m_ar=%0d",
                        s_aw_count, m_aw_count, s_ar_count, m_ar_count);
        assert (m_error_flags == '0)
            else $fatal(1, "output checker observed protocol errors flags=%03x code=%0d addr=%08x len=%0d",
                        m_error_flags, m_error_code, m_error_addr, m_error_len);

        $warning("upstream checker observed expected AXI4 4KB crossings: flags=%03x first_id=%0d first_addr=%08x first_len=%0d",
                 s_error_flags, s_error_id, s_error_addr, s_error_len);
        $display("downstream checker clean: flags=%03x", m_error_flags);
        $display("segment counts: upstream AW/AR=%0d/%0d downstream AW/AR=%0d/%0d",
                 s_aw_count, s_ar_count, m_aw_count, m_ar_count);
        $display("tb_axi4_burst_splitter_randomtest : PASS tests=%0d crossing=%0d boundary_end=%0d in_page=%0d input_flags=%03x output_flags=%03x",
                 NUM_TESTS, crossing_tests, boundary_end_tests, in_page_tests, s_error_flags, m_error_flags);
        $finish;
    end

endmodule


`default_nettype wire


// end of file