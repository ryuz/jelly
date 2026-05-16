`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/model/jelly3_model_axi4l_m.sv"
`include "../../../../rtl/v3/model/jelly3_model_axi4l_mem_check.sv"


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam int ADDR_BITS      = 32;
    localparam int DATA_BITS      = 32;
    localparam int TEST_CYCLES    = 10000;
    localparam longint unsigned ADDR_LOW  = 64'd0;
    localparam longint unsigned ADDR_HIGH = 64'd16383;

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
        axi4l
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    logic   enable;
    logic   busy;
    logic   write_busy;
    logic   read_busy;

    jelly3_model_axi4l_m
            #(
                .WRITE_ADDR_LOW   (ADDR_LOW            ),
                .WRITE_ADDR_HIGH  (ADDR_HIGH           ),
                .READ_ADDR_LOW    (ADDR_LOW            ),
                .READ_ADDR_HIGH   (ADDR_HIGH           ),
                .WRITE_ISSUE_RATE (60                  ),
                .READ_ISSUE_RATE  (60                  ),
                .WRITE_RAND_SEED  (100                ),
                .READ_RAND_SEED   (200                )
            )
        u_model_axi4l_m
            (
                .enable         (enable        ),
                .busy           (busy          ),
                .write_busy     (write_busy    ),
                .read_busy      (read_busy     ),
                .m_axi4l        (axi4l.m       )
            );

    jelly3_model_axi4l_s
            #(
                .MEM_ADDR_BITS  (12             ),
                .READ_DATA_ADDR (0              ),
                .WRITE_LOG_FILE (""             ),
                .READ_LOG_FILE  (""             ),
                .AW_BUSY_RATE   (20             ),
                .W_BUSY_RATE    (20             ),
                .B_BUSY_RATE    (20             ),
                .AR_BUSY_RATE   (20             ),
                .R_BUSY_RATE    (20             ),
                .AW_RAND_SEED   (300            ),
                .W_RAND_SEED    (301            ),
                .B_RAND_SEED    (302            ),
                .AR_RAND_SEED   (303            ),
                .R_RAND_SEED    (304            )
            )
        u_model_axi4l_s
            (
                .s_axi4l        (axi4l.s       )
            );

    jelly3_model_axi4l_mem_check
            #(
                .MEM_ADDR_BITS  (12             ),
                .ADDR_BASE      (0              ),
                .SHOW_MATCH     (0              ),
                .SHOW_SKIP      (0              ),
                .CHECK_BRESP    (1              ),
                .CHECK_RRESP    (1              )
            )
        u_memory_checker
            (
                .mon_axi4l      (axi4l.mon      )
            );

    int cycle_count;
    int write_aw_count;
    int write_w_count;
    int write_b_count;
    int read_ar_count;
    int read_r_count;

    always_ff @(posedge aclk) begin
        if ( !aresetn ) begin
            cycle_count    <= 0;
            write_aw_count <= 0;
            write_w_count  <= 0;
            write_b_count  <= 0;
            read_ar_count  <= 0;
            read_r_count   <= 0;
        end
        else if ( aclken ) begin
            cycle_count <= cycle_count + 1;
            if ( axi4l.awvalid && axi4l.awready ) begin
                write_aw_count <= write_aw_count + 1;
            end
            if ( axi4l.wvalid && axi4l.wready ) begin
                write_w_count <= write_w_count + 1;
            end
            if ( axi4l.bvalid && axi4l.bready ) begin
                write_b_count <= write_b_count + 1;
            end
            if ( axi4l.arvalid && axi4l.arready ) begin
                read_ar_count <= read_ar_count + 1;
            end
            if ( axi4l.rvalid && axi4l.rready ) begin
                read_r_count <= read_r_count + 1;
            end
        end
    end

    initial begin
        enable = 1'b0;

        wait ( aresetn == 1'b1 );
        repeat (20) @(posedge aclk);

        enable = 1'b1;
        repeat (TEST_CYCLES) @(posedge aclk);
        enable = 1'b0;

        wait ( !busy && !write_busy && !read_busy );
        repeat (20) @(posedge aclk);

        $display("---- tb_model_axi4l summary ----");
        $display("cycles        : %0d", cycle_count);
        $display("write aw/w/b  : %0d / %0d / %0d", write_aw_count, write_w_count, write_b_count);
        $display("read ar/r     : %0d / %0d", read_ar_count, read_r_count);

        assert (write_aw_count >= 20)
            else $fatal(1, "insufficient write transactions count=%0d", write_aw_count);
        assert (read_ar_count >= 20)
            else $fatal(1, "insufficient read transactions count=%0d", read_ar_count);
        assert (write_aw_count == write_w_count)
            else $fatal(1, "write aw/w mismatch aw=%0d w=%0d", write_aw_count, write_w_count);
        assert (write_aw_count == write_b_count)
            else $fatal(1, "write aw/b mismatch aw=%0d b=%0d", write_aw_count, write_b_count);
        assert (read_ar_count == read_r_count)
            else $fatal(1, "read ar/r mismatch ar=%0d r=%0d", read_ar_count, read_r_count);

        $display("tb_model_axi4l passed");
        $finish;
    end

endmodule


`default_nettype wire


// end of file
