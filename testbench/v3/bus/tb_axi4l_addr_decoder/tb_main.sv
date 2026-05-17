`timescale 1ns / 1ps
`default_nettype none


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    // -------------------------
    //  DUT
    // -------------------------

    localparam int NUM       = 3;
    localparam int ADDR_BITS = 32;
    localparam int DATA_BITS = 32;

    localparam type addr_t = logic [ADDR_BITS-1:0];
    localparam type data_t = logic [DATA_BITS-1:0];

    logic aresetn;
    logic aclk;
    logic aclken;
    assign aresetn = ~reset;
    assign aclk    = clk;
    assign aclken  = 1'b1;

    jelly3_axi4l_if
            #(
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        s_axi4l
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
        m_axi4l[NUM]
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    jelly3_axi4l_addr_decoder
            #(
                .NUM            (NUM            ),
                .DEC_ADDR_BITS  (ADDR_BITS      ),
                .DEC_ADDR_MASK  (64'hffff_ffff  )
            )
        u_axi4l_addr_decoder
            (
                .s_axi4l        (s_axi4l.s      ),
                .m_axi4l        (m_axi4l        )
            );


    // -------------------------
    //  Slave models
    // -------------------------

    for ( genvar i = 0; i < NUM; i++ ) begin : g_model
        jelly3_model_axi4l_s
                #(
                    .MEM_ADDR_BITS      (12                         ),
                    .READ_DATA_ADDR     (0                          ),
                    .WRITE_LOG_FILE     (""                         ),
                    .READ_LOG_FILE      (""                         ),
                    .AW_DELAY           (0                          ),
                    .AR_DELAY           (0                          ),
                    .AW_FIFO_PTR_BITS   (0                          ),
                    .W_FIFO_PTR_BITS    (0                          ),
                    .B_FIFO_PTR_BITS    (0                          ),
                    .AR_FIFO_PTR_BITS   (0                          ),
                    .R_FIFO_PTR_BITS    (0                          ),
                    .AW_BUSY_RATE       (30                         ),
                    .W_BUSY_RATE        (30                         ),
                    .B_BUSY_RATE        (30                         ),
                    .AR_BUSY_RATE       (30                         ),
                    .R_BUSY_RATE        (30                         ),
                    .AW_RAND_SEED       (101 + i*10                 ),
                    .W_RAND_SEED        (102 + i*10                 ),
                    .B_RAND_SEED        (103 + i*10                 ),
                    .AR_RAND_SEED       (104 + i*10                 ),
                    .R_RAND_SEED        (105 + i*10                 )
                )
            u_model_axi4l_s
                (
                    .s_axi4l            (m_axi4l[i].s               )
                );
    end


    // -------------------------
    //  Master accessor
    // -------------------------

    jelly3_axi4l_accessor
            #(
                .RAND_RATE_AW   (0  ),
                .RAND_RATE_W    (0  ),
                .RAND_RATE_B    (0  ),
                .RAND_RATE_AR   (0  ),
                .RAND_RATE_R    (0  )
            )
        u_axi4l_accessor
            (
                .m_axi4l        (s_axi4l.m )
            );


    // -------------------------
    //  Test sequence
    // -------------------------

    task automatic write_and_read_check(
                input int     idx,
                input int     reg_idx,
                input data_t  wdata
            );
        automatic addr_t base;
        automatic data_t rdata;
        base = addr_t'(idx * 32'h0000_1000);

        u_axi4l_accessor.write_reg(base, reg_idx, wdata, '1);
        u_axi4l_accessor.read_reg (base, reg_idx, rdata);
        assert (rdata == wdata)
            else $error("readback mismatch idx=%0d reg=%0d expected=%08x actual=%08x", idx, reg_idx, wdata, rdata);
    endtask

    initial begin
        automatic data_t rd_data;

        // decode table
        m_axi4l[0].addr_base = addr_t'(32'h0000_0000);
        m_axi4l[0].addr_high = addr_t'(32'h0000_0fff);
        m_axi4l[1].addr_base = addr_t'(32'h0000_1000);
        m_axi4l[1].addr_high = addr_t'(32'h0000_1fff);
        m_axi4l[2].addr_base = addr_t'(32'h0000_2000);
        m_axi4l[2].addr_high = addr_t'(32'h0000_2fff);

        wait (aresetn == 1'b1);
        repeat (10) @(posedge aclk);

        // each decode region
        write_and_read_check(0, 4, 32'h1111_0004);
        write_and_read_check(1, 5, 32'h2222_0005);
        write_and_read_check(2, 6, 32'h3333_0006);

        // out-of-range read must be local zero response
        u_axi4l_accessor.read_reg(addr_t'(32'h0000_8000), 0, rd_data);
        assert (rd_data == data_t'('0))
            else $error("out-of-range read data mismatch actual=%08x", rd_data);

        // out-of-range write must not affect mapped data
        u_axi4l_accessor.write_reg(addr_t'(32'h0000_8000), 0, 32'hffff_ffff, 4'hf);
        u_axi4l_accessor.read_reg(addr_t'(32'h0000_0000), 4, rd_data);
        assert (rd_data == 32'h1111_0004)
            else $error("out-of-range write side-effect detected actual=%08x", rd_data);

        $display("tb_axi4l_addr_decoder : PASS");
        #1000;
        $finish;
    end

endmodule


`default_nettype wire


// end of file
