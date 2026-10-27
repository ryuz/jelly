`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(parameter int DATA_BITS = 32)
        (
            input   var logic   reset,
            input   var logic   clk,
            output  var logic   done
        );

    localparam int ID_BITS   = 4;
    localparam int ADDR_BITS = 32;
    localparam int DATA_BYTES = DATA_BITS / 8;
    localparam int TEST_BEATS = 16;
    localparam int BEATS_TO_BOUNDARY = TEST_BEATS / 2;
    localparam int SIZE = $clog2(DATA_BYTES);
    localparam addr_t START_ADDR = addr_t'(4096 - BEATS_TO_BOUNDARY * DATA_BYTES);

    localparam type id_t   = logic [ID_BITS-1:0];
    localparam type addr_t = logic [ADDR_BITS-1:0];
    localparam type len_t  = logic [7:0];
    localparam type data_t = logic [DATA_BITS-1:0];
    localparam type strb_t = logic [DATA_BITS/8-1:0];

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

    jelly3_axi4_burst_splitter u_dut (
        .s_axi4 (s_axi4.s),
        .m_axi4 (m_axi4.m)
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

    addr_t aw_addr_log [4];
    len_t  aw_len_log  [4];
    addr_t ar_addr_log [4];
    len_t  ar_len_log  [4];
    int    aw_count;
    int    wlast_count;
    int    ar_count;
    int    rlast_count;

    always_ff @(posedge clk) begin
        if ( ~aresetn ) begin
            aw_count    <= 0;
            wlast_count <= 0;
            ar_count    <= 0;
            rlast_count <= 0;
        end
        else begin
            if ( m_axi4.awvalid && m_axi4.awready ) begin
                if ( aw_count < 4 ) begin
                    aw_addr_log[aw_count] <= m_axi4.awaddr;
                    aw_len_log [aw_count] <= len_t'(m_axi4.awlen);
                end
                aw_count <= aw_count + 1;
            end
            if ( m_axi4.wvalid && m_axi4.wready && m_axi4.wlast ) begin
                wlast_count <= wlast_count + 1;
            end
            if ( m_axi4.arvalid && m_axi4.arready ) begin
                if ( ar_count < 4 ) begin
                    ar_addr_log[ar_count] <= m_axi4.araddr;
                    ar_len_log [ar_count] <= len_t'(m_axi4.arlen);
                end
                ar_count <= ar_count + 1;
            end
            if ( m_axi4.rvalid && m_axi4.rready && m_axi4.rlast ) begin
                rlast_count <= rlast_count + 1;
            end
        end
    end

    initial begin
        automatic data_t wr_datas[];
        automatic data_t rd_datas[];
        automatic strb_t wr_strbs[];

        done = 1'b0;
        wait (aresetn);
        repeat (10) @(posedge clk);

        wr_datas = new[TEST_BEATS];
        wr_strbs = new[TEST_BEATS];
        for ( int i = 0; i < TEST_BEATS; i++ ) begin
            wr_datas[i] = '0;
            wr_strbs[i] = '1;
            for ( int b = 0; b < DATA_BYTES; b++ ) begin
                wr_datas[i][b*8 +: 8] = 8'h5a ^ 8'(i) ^ 8'(b);
            end
        end

        u_accessor.write(
                id_t'(3),
                START_ADDR,
                3'(SIZE),
                2'b01,
                '0, '0, '0, '0, '0, '0,
                wr_datas,
                wr_strbs
            );

        u_accessor.read(
                id_t'(3),
                START_ADDR,
                8'(TEST_BEATS - 1),
                3'(SIZE),
                2'b01,
                '0, '0, '0, '0, '0, '0,
                rd_datas
            );

        assert (rd_datas.size() == TEST_BEATS)
            else $fatal(1, "read size mismatch: %0d", rd_datas.size());
        for ( int i = 0; i < TEST_BEATS; i++ ) begin
            assert (rd_datas[i] == wr_datas[i])
                else $fatal(1, "readback mismatch width=%0d beat=%0d expected=%h actual=%h",
                            DATA_BITS,
                            i, wr_datas[i], rd_datas[i]);
        end

        repeat (2) @(posedge clk);
        assert (aw_count == 2 && wlast_count == 2)
            else $fatal(1, "write split mismatch width=%0d AW=%0d WLAST=%0d", DATA_BITS, aw_count, wlast_count);
        assert (aw_addr_log[0] == START_ADDR && aw_len_log[0] == len_t'(BEATS_TO_BOUNDARY - 1))
            else $fatal(1, "first AW mismatch width=%0d addr=%08x len=%0d", DATA_BITS, aw_addr_log[0], aw_len_log[0]);
        assert (aw_addr_log[1] == addr_t'(32'h0000_1000) && aw_len_log[1] == len_t'(BEATS_TO_BOUNDARY - 1))
            else $fatal(1, "second AW mismatch width=%0d addr=%08x len=%0d", DATA_BITS, aw_addr_log[1], aw_len_log[1]);

        assert (ar_count == 2 && rlast_count == 2)
            else $fatal(1, "read split mismatch width=%0d AR=%0d RLAST=%0d", DATA_BITS, ar_count, rlast_count);
        assert (ar_addr_log[0] == START_ADDR && ar_len_log[0] == len_t'(BEATS_TO_BOUNDARY - 1))
            else $fatal(1, "first AR mismatch width=%0d addr=%08x len=%0d", DATA_BITS, ar_addr_log[0], ar_len_log[0]);
        assert (ar_addr_log[1] == addr_t'(32'h0000_1000) && ar_len_log[1] == len_t'(BEATS_TO_BOUNDARY - 1))
            else $fatal(1, "second AR mismatch width=%0d addr=%08x len=%0d", DATA_BITS, ar_addr_log[1], ar_len_log[1]);

        $display("tb_axi4_burst_splitter DATA_BITS=%0d : PASS", DATA_BITS);
        done = 1'b1;
    end

endmodule


`default_nettype wire


// end of file