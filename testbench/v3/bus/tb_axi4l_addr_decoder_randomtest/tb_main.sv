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

    // decode table
    assign m_axi4l[0].addr_base = addr_t'(32'h0000_0000);
    assign m_axi4l[0].addr_high = addr_t'(32'h0000_0fff);
    assign m_axi4l[1].addr_base = addr_t'(32'h0000_1000);
    assign m_axi4l[1].addr_high = addr_t'(32'h0000_1fff);
    assign m_axi4l[2].addr_base = addr_t'(32'h0000_2000);
    assign m_axi4l[2].addr_high = addr_t'(32'h0000_2fff);

    // -------------------------
    //  Master model
    // -------------------------

    logic enable;
    jelly3_model_axi4l_m
            #(
                .WRITE_ADDR_LOW     (32'h0000_0000  ),
                .WRITE_ADDR_HIGH    (32'h0000_3fff  ),
                .READ_ADDR_LOW      (32'h0000_0000  ),
                .READ_ADDR_HIGH     (32'h0000_3fff  ),
                .WRITE_ISSUE_RATE   (50             ),
                .READ_ISSUE_RATE    (50             ),
                .WRITE_RAND_SEED    (0              ),
                .READ_RAND_SEED     (1              )
            )
        u_model_axi4l_m
            (
                .busy               (               ),
                .enable             (enable         ),
                .write_busy         (               ),
                .read_busy          (               ),
                .m_axi4l            (s_axi4l.m      )
            );

    initial begin
        enable = 1;
        #100000;
        enable = 0;
        #1000;
        $finish();
    end

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



endmodule


`default_nettype wire


// end of file
