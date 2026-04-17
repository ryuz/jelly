`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    // -------------------------
    //  DUT parameters
    // -------------------------

    localparam int  ID_BITS   = 4;
    localparam int  ADDR_BITS = 32;
    localparam int  DATA_BITS = 32;

    localparam type id_t   = logic [ID_BITS  -1:0];
    localparam type addr_t = logic [ADDR_BITS-1:0];
    localparam type data_t = logic [DATA_BITS-1:0];

    logic aresetn;
    logic aclk;
    logic aclken;
    assign aresetn = ~reset;
    assign aclk    = clk;
    assign aclken  = 1'b1;


    // -------------------------
    //  Interfaces
    // -------------------------

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS    ),
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        s_axi4
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        m_axi4l
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );


    // -------------------------
    //  DUT
    // -------------------------

    jelly3_axi4_to_axi4l
            #(
                .DEVICE         ("RTL"      ),
                .SIMULATION     ("false"    ),
                .DEBUG          ("false"    )
            )
        u_dut
            (
                .s_axi4     (s_axi4.s   ),
                .m_axi4l    (m_axi4l.m  )
            );


    // -------------------------
    //  AXI4-Lite slave model
    // -------------------------

    jelly3_model_axi4l_s
            #(
                .MEM_ADDR_BITS      (12                 ),
                .READ_DATA_ADDR     (0                  ),
                .WRITE_LOG_FILE     (""                 ),
                .READ_LOG_FILE      (""                 ),
                .AW_DELAY           (0                  ),
                .AR_DELAY           (0                  ),
                .AW_FIFO_PTR_BITS   (0                  ),
                .W_FIFO_PTR_BITS    (0                  ),
                .B_FIFO_PTR_BITS    (0                  ),
                .AR_FIFO_PTR_BITS   (0                  ),
                .R_FIFO_PTR_BITS    (0                  ),
                .AW_BUSY_RATE       (30                 ),
                .W_BUSY_RATE        (30                 ),
                .B_BUSY_RATE        (30                 ),
                .AR_BUSY_RATE       (30                 ),
                .R_BUSY_RATE        (30                 ),
                .AW_RAND_SEED       (101                ),
                .W_RAND_SEED        (102                ),
                .B_RAND_SEED        (103                ),
                .AR_RAND_SEED       (104                ),
                .R_RAND_SEED        (105                )
            )
        u_model_axi4l_s
            (
                .s_axi4l    (m_axi4l.s  )
            );


    // -------------------------
    //  AXI4 master accessor
    // -------------------------

    jelly3_axi4_accessor
            #(
                .RAND_RATE_AW   (0  ),
                .RAND_RATE_W    (0  ),
                .RAND_RATE_B    (0  ),
                .RAND_RATE_AR   (0  ),
                .RAND_RATE_R    (0  )
            )
        u_axi4_accessor
            (
                .m_axi4     (s_axi4.m   )
            );


    // -------------------------
    //  Test sequence
    // -------------------------

    // Helper: write a single beat and read back, check rdata == wdata
    task automatic single_write_read(
                input addr_t addr,
                input data_t wdata,
                input id_t   id
            );
        automatic data_t rdatas [];

        u_axi4_accessor.write(
                id,         // id
                addr,       // addr
                3'h2,       // size (4 byte)
                2'b01,      // burst INCR
                '0,         // lock
                '0,         // cache
                '0,         // prot
                '0,         // qos
                '0,         // region
                '0,         // user
                {wdata},    // data[]
                {4'hf}      // strb[]
            );

        u_axi4_accessor.read(
                id,         // id
                addr,       // addr
                8'd0,       // len (1 beat)
                3'h2,       // size
                2'b01,      // burst INCR
                '0,         // lock
                '0,         // cache
                '0,         // prot
                '0,         // qos
                '0,         // region
                '0,         // user
                rdatas
            );

        assert (rdatas.size() == 1)
            else $error("single read size mismatch addr=%08x", addr);
        assert (rdatas[0] == wdata)
            else $error("single read mismatch addr=%08x expected=%08x actual=%08x", addr, wdata, rdatas[0]);

        $display("[axi4->axi4l single] addr:%08x wr:%08x rd:%08x %s",
                 addr, wdata, rdatas[0], (rdatas[0] == wdata) ? "OK" : "FAIL");
    endtask


    // Helper: burst write len+1 beats starting at addr, then burst read back
    task automatic burst_write_read(
                input addr_t  addr,
                input int     len,        // AXI len field (beats-1)
                input data_t  base_data,
                input id_t    id
            );
        automatic data_t wr_datas [];
        automatic data_t rd_datas [];
        automatic int    beats = len + 1;

        automatic logic [3:0] wr_strbs [];
        wr_datas = new[beats];
        wr_strbs = new[beats];
        for (int i = 0; i < beats; i++) begin
            wr_datas[i] = base_data + data_t'(i);
            wr_strbs[i] = 4'hf;
        end

        u_axi4_accessor.write(
                id,         // id
                addr,       // addr
                3'h2,       // size
                2'b01,      // burst INCR
                '0, '0, '0, '0, '0, '0,
                wr_datas,
                wr_strbs
            );

        u_axi4_accessor.read(
                id,         // id
                addr,       // addr
                8'(len),    // len
                3'h2,       // size
                2'b01,      // burst INCR
                '0, '0, '0, '0, '0, '0,
                rd_datas
            );

        assert (rd_datas.size() == beats)
            else $error("burst read size mismatch addr=%08x expected=%0d actual=%0d",
                         addr, beats, rd_datas.size());
        for (int i = 0; i < beats; i++) begin
            assert (rd_datas[i] == wr_datas[i])
                else $error("burst read mismatch addr=%08x beat=%0d expected=%08x actual=%08x",
                             addr, i, wr_datas[i], rd_datas[i]);
        end

        $display("[axi4->axi4l burst len=%0d] addr:%08x base:%08x %s",
                 len, addr, base_data,
                 (rd_datas == wr_datas) ? "OK" : "FAIL");
    endtask


    // Helper: partial-strobe write, then read back to verify masked bytes
    task automatic partial_strobe_check(
                input addr_t  addr,
                input data_t  init_data,
                input data_t  patch_data,
                input logic [3:0] strb,
                input id_t    id
            );
        automatic data_t exp;
        automatic data_t rd_datas [];

        // build expected: bytes selected by strb take patch_data, rest keep init_data
        exp = '0;
        for (int b = 0; b < 4; b++) begin
            if (strb[b]) exp[b*8 +: 8] = patch_data[b*8 +: 8];
            else         exp[b*8 +: 8] = init_data [b*8 +: 8];
        end

        // write init_data first
        u_axi4_accessor.write(
                id, addr, 3'h2, 2'b01, '0, '0, '0, '0, '0, '0,
                {init_data}, {4'hf}
            );
        // partial-strobe update
        u_axi4_accessor.write(
                id, addr, 3'h2, 2'b01, '0, '0, '0, '0, '0, '0,
                {patch_data}, {strb}
            );
        // read back
        u_axi4_accessor.read(
                id, addr, 8'd0, 3'h2, 2'b01, '0, '0, '0, '0, '0, '0,
                rd_datas
            );

        assert (rd_datas.size() == 1 && rd_datas[0] == exp)
            else $error("strobe check mismatch addr=%08x expected=%08x actual=%08x", addr, exp, rd_datas[0]);

        $display("[axi4->axi4l strobe=%04b] addr:%08x expected:%08x actual:%08x %s",
                 strb, addr, exp, rd_datas[0], (rd_datas[0] == exp) ? "OK" : "FAIL");
    endtask


    initial begin
        wait (aresetn == 1'b1);
        repeat (10) @(posedge aclk);

        // --- single-beat write + read back ---
        single_write_read(addr_t'(32'h0000_0010), 32'hA5A5_0001, id_t'(1));
        single_write_read(addr_t'(32'h0000_0100), 32'hB6B6_0002, id_t'(2));
        single_write_read(addr_t'(32'h0000_1000), 32'hC7C7_0003, id_t'(3));

        // --- burst write/read (len=3, 4 beats) ---
        burst_write_read(addr_t'(32'h0000_0000), 3, 32'hDEAD_0000, id_t'(4));

        // --- burst write/read (len=7, 8 beats) ---
        burst_write_read(addr_t'(32'h0000_0040), 7, 32'hBEEF_0000, id_t'(5));

        // --- partial strobe write ---
        partial_strobe_check(
                addr_t'(32'h0000_0200),
                32'hFF00_FF00,   // init
                32'h1234_5678,   // patch
                4'b0101,         // strb: bytes 0 and 2 updated
                id_t'(6)
            );

        repeat (20) @(posedge aclk);

        $display("tb_axi4_to_axi4l : PASS");
        $finish;
    end

endmodule


`default_nettype wire


// end of file
