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
    localparam int ID_BITS   = 4;
    localparam int ADDR_BITS = 32;
    localparam int DATA_BITS = 32;

    localparam type id_t   = logic [ID_BITS-1:0];
    localparam type addr_t = logic [ADDR_BITS-1:0];
    localparam type data_t = logic [DATA_BITS-1:0];

    logic aresetn;
    logic aclk;
    logic aclken;
    assign aresetn = ~reset;
    assign aclk    = clk;
    assign aclken  = 1'b1;

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

    jelly3_axi4_if
            #(
                .ID_BITS    (ID_BITS    ),
                .ADDR_BITS  (ADDR_BITS  ),
                .DATA_BITS  (DATA_BITS  ),
                .SIMULATION ("true"     )
            )
        m_axi4[NUM]
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    jelly3_axi4_addr_decoder
            #(
                .NUM            (NUM            ),
                .DEC_ADDR_BITS  (ADDR_BITS      ),
                .DEC_ADDR_MASK  (64'hffff       )
            )
        u_axi4_addr_decoder
            (
                .s_axi4         (s_axi4.s       ),
                .m_axi4         (m_axi4         )
            );

    assign m_axi4[0].addr_base = addr_t'(32'h0000_0000);
    assign m_axi4[0].addr_high = addr_t'(32'h0000_0fff);
    assign m_axi4[1].addr_base = addr_t'(32'h0000_1000);
    assign m_axi4[1].addr_high = addr_t'(32'h0000_1fff);
    assign m_axi4[2].addr_base = addr_t'(32'h0000_2000);
    assign m_axi4[2].addr_high = addr_t'(32'h0000_2fff);

    // -------------------------
    //  Master model
    // -------------------------

    logic   enable;
    jelly3_model_axi4_m
            #(
                .WADDR_LOW      (32'h0000   ),
                .WADDR_HIGH     (32'h3fff   ),
                .RADDR_LOW      (32'h0000   ),
                .RADDR_HIGH     (32'h3fff   ),
                .AW_BUSY_RATE   (80         ),
                .W_BUSY_RATE    (50         ),
                .B_BUSY_RATE    (20         ),
                .AR_BUSY_RATE   (80         ),
                .R_BUSY_RATE    (20         )
            )
        u_model_axi4_m
            (
                .enable         (enable     ),
                .m_axi4         (s_axi4     )
            );

    int  fp_s_aw;
    int  fp_s_w;
    int  fp_s_b;
    int  fp_s_ar;
    int  fp_s_r;
    int  fp_m0_aw;
    int  fp_m0_ar;
    int  fp_m1_aw;
    int  fp_m1_ar;
    int  fp_m2_aw;
    int  fp_m2_ar;
    initial begin
        fp_s_aw  = $fopen("s_aw_log.txt", "w");
        fp_s_w   = $fopen("s_w_log.txt", "w");
        fp_s_b   = $fopen("s_b_log.txt", "w");
        fp_s_ar  = $fopen("s_ar_log.txt", "w");
        fp_s_r   = $fopen("s_r_log.txt", "w");
        fp_m0_aw = $fopen("m0_aw_log.txt", "w");
        fp_m0_ar = $fopen("m0_ar_log.txt", "w");
        fp_m1_aw = $fopen("m1_aw_log.txt", "w");
        fp_m1_ar = $fopen("m1_ar_log.txt", "w");
        fp_m2_aw = $fopen("m2_aw_log.txt", "w");
        fp_m2_ar = $fopen("m2_ar_log.txt", "w");
    end

    always_ff @( posedge clk ) begin
        if ( s_axi4.aresetn ) begin
            // slave
            if ( s_axi4.awvalid && s_axi4.awready ) begin
                $fwrite(fp_s_aw, "%0t: aw: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, s_axi4.awid, s_axi4.awaddr, s_axi4.awlen, s_axi4.awsize, s_axi4.awburst);
            end
            if ( s_axi4.wvalid && s_axi4.wready ) begin
                $fwrite(fp_s_w, "%0t: w: data=%08h strb=%0h last=%b\n",
                        $time, s_axi4.wdata, s_axi4.wstrb, s_axi4.wlast);
            end
            if ( s_axi4.bvalid && s_axi4.bready ) begin
                $fwrite(fp_s_b, "%0t: b: id=%0h resp=%0h\n",
                        $time, s_axi4.bid, s_axi4.bresp);
            end
            if ( s_axi4.arvalid && s_axi4.arready ) begin
                $fwrite(fp_s_ar, "%0t: ar: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, s_axi4.arid, s_axi4.araddr, s_axi4.arlen, s_axi4.arsize, s_axi4.arburst);
            end
            if ( s_axi4.rvalid && s_axi4.rready ) begin
                $fwrite(fp_s_r, "%0t: r: id=%0h data=%08h resp=%0h last=%b\n",
                        $time, s_axi4.rid, s_axi4.rdata, s_axi4.rresp, s_axi4.rlast);
            end

            // master0
            if ( m_axi4[0].awvalid && m_axi4[0].awready ) begin
                $fwrite(fp_m0_aw, "%0t: aw: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, m_axi4[0].awid, m_axi4[0].awaddr, m_axi4[0].awlen, m_axi4[0].awsize, m_axi4[0].awburst);
                if ( m_axi4[0].awaddr < m_axi4[0].addr_base || m_axi4[0].awaddr > m_axi4[0].addr_high ) begin
                    $display("Error: master0 awaddr out of range: %04h", m_axi4[0].awaddr);
                end
            end
            if ( m_axi4[0].arvalid && m_axi4[0].arready ) begin
                $fwrite(fp_m0_ar, "%0t: ar: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, m_axi4[0].arid, m_axi4[0].araddr, m_axi4[0].arlen, m_axi4[0].arsize, m_axi4[0].arburst);
                if ( m_axi4[0].araddr < m_axi4[0].addr_base || m_axi4[0].araddr > m_axi4[0].addr_high ) begin
                    $display("Error: master0 araddr out of range: %04h", m_axi4[0].araddr);
                end
            end

            // master1
            if ( m_axi4[1].awvalid && m_axi4[1].awready ) begin
                $fwrite(fp_m1_aw, "%0t: aw: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, m_axi4[1].awid, m_axi4[1].awaddr, m_axi4[1].awlen, m_axi4[1].awsize, m_axi4[1].awburst);
                if ( m_axi4[1].awaddr < m_axi4[1].addr_base || m_axi4[1].awaddr > m_axi4[1].addr_high ) begin
                    $display("Error: master1 awaddr out of range: %04h", m_axi4[1].awaddr);
                end
            end
            if ( m_axi4[1].arvalid && m_axi4[1].arready ) begin
                $fwrite(fp_m1_ar, "%0t: ar: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, m_axi4[1].arid, m_axi4[1].araddr, m_axi4[1].arlen, m_axi4[1].arsize, m_axi4[1].arburst);
                if ( m_axi4[1].araddr < m_axi4[1].addr_base || m_axi4[1].araddr > m_axi4[1].addr_high ) begin
                    $display("Error: master1 araddr out of range: %04h", m_axi4[1].araddr);
                end
            end

            // master2
            if ( m_axi4[2].awvalid && m_axi4[2].awready ) begin
                $fwrite(fp_m2_aw, "%0t: aw: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, m_axi4[2].awid, m_axi4[2].awaddr, m_axi4[2].awlen, m_axi4[2].awsize, m_axi4[2].awburst);
                if ( m_axi4[2].awaddr < m_axi4[2].addr_base || m_axi4[2].awaddr > m_axi4[2].addr_high ) begin
                    $display("Error: master2 awaddr out of range: %04h", m_axi4[2].awaddr);
                end
            end
            if ( m_axi4[2].arvalid && m_axi4[2].arready ) begin
                $fwrite(fp_m2_ar, "%0t: ar: id=%0h addr=%04h len=%0h size=%0h burst=%0h\n",
                        $time, m_axi4[2].arid, m_axi4[2].araddr, m_axi4[2].arlen, m_axi4[2].arsize, m_axi4[2].arburst);
                if ( m_axi4[2].araddr < m_axi4[2].addr_base || m_axi4[2].araddr > m_axi4[2].addr_high ) begin
                    $display("Error: master2 araddr out of range: %04h", m_axi4[2].araddr);
                end
            end
        end
    end

    initial begin
        enable = 1;
        #1000000;
//      #325;
        enable = 0;
        #10000;
        $finish();
    end

    // -------------------------
    //  Slave models
    // -------------------------

    for ( genvar i = 0; i < NUM; i++ ) begin : g_model
        jelly3_model_axi4_s
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
            u_model_axi4_s
                (
                    .s_axi4             (m_axi4[i].s                )
                );
    end


endmodule


`default_nettype wire


// end of file
