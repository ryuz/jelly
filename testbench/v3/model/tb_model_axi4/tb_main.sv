`timescale 1ns / 1ps
`default_nettype none

`include "../../../../rtl/v3/model/jelly3_model_axi4_m.sv"
`include "../../../../rtl/v3/model/jelly3_model_axi4_mem_check.sv"


module tb_main
        (
            input   var logic   reset,
            input   var logic   clk
        );

    localparam  int     ID_BITS         = 4;
    localparam  int     ADDR_BITS       = 32;
    localparam  int     DATA_BITS       = 32;
    localparam  int     STRB_BITS       = DATA_BITS / 8;
    localparam  int     LEN_BITS        = 8;
    localparam  int     SIZE_BITS       = 3;
    localparam  int     DATA_BYTES      = STRB_BITS;
    localparam  int     DATA_SIZE       = $clog2(DATA_BYTES);
    localparam  int     WADDR_LOW       = 'h0000_0100;
    localparam  int     WADDR_HIGH      = 'h0000_01ff;
    localparam  int     RADDR_LOW       = 'h0000_0100;
    localparam  int     RADDR_HIGH      = 'h0000_01ff;
    localparam  int     TEST_CYCLES     = 500;
    localparam  int     WRITE_ID        = 3;
    localparam  int     READ_ID         = 5;

    localparam  type    id_t            = logic [ID_BITS-1:0]    ;
    localparam  type    addr_t          = logic [ADDR_BITS-1:0]  ;
    localparam  type    data_t          = logic [DATA_BITS-1:0]  ;
    localparam  type    len_t           = logic [LEN_BITS-1:0]   ;
    localparam  type    size_t          = logic [SIZE_BITS-1:0]  ;

    logic   aresetn;
    logic   aclk;
    logic   aclken;
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
        axi4
            (
                .aresetn    (aresetn    ),
                .aclk       (aclk       ),
                .aclken     (aclken     )
            );

    logic   enable;

    jelly3_model_axi4_m
            #(
                .WADDR_LOW          (WADDR_LOW          ),
                .WADDR_HIGH         (WADDR_HIGH         ),
                .RADDR_LOW          (RADDR_LOW          ),
                .RADDR_HIGH         (RADDR_HIGH         ),
                .AW_BUSY_RATE       (25                 ),
                .W_BUSY_RATE        (35                 ),
                .B_BUSY_RATE        (20                 ),
                .AR_BUSY_RATE       (25                 ),
                .R_BUSY_RATE        (20                 )
            )
        u_model_axi4_m
            (
                .enable              (enable              ),
                .m_axi4              (axi4.m              )
            );

    jelly3_model_axi4_s
            #(
                .MEM_ADDR_BITS       (12                  ),
                .READ_DATA_ADDR      (0                   ),
                .WRITE_LOG_FILE      ("axi4_write_log.txt"),
                .READ_LOG_FILE       ("axi4_read_log.txt" ),
                .AW_DELAY            (0                   ),
                .AR_DELAY            (0                   ),
                .AW_FIFO_PTR_BITS    (0                   ),
                .W_FIFO_PTR_BITS     (0                   ),
                .B_FIFO_PTR_BITS     (0                   ),
                .AR_FIFO_PTR_BITS    (0                   ),
                .R_FIFO_PTR_BITS     (0                   ),
                .AW_BUSY_RATE        (15                  ),
                .W_BUSY_RATE         (15                  ),
                .B_BUSY_RATE         (15                  ),
                .AR_BUSY_RATE        (0                   ),
                .R_BUSY_RATE         (0                   ),
                .AW_RAND_SEED        (400                 ),
                .W_RAND_SEED         (401                 ),
                .B_RAND_SEED         (402                 ),
                .AR_RAND_SEED        (403                 ),
                .R_RAND_SEED         (404                 )
            )
        u_model_axi4_s
            (
                .s_axi4              (axi4.s              )
            );

    jelly3_model_axi4_mem_check
            #(
                .SHOW_MATCH          (1                   ),
                .SHOW_SKIP           (1                   ),
                .CHECK_BRESP         (1                   ),
                .CHECK_RRESP         (1                   ),
                .CHECK_WLAST         (1                   ),
                .CHECK_RLAST         (1                   )
            )
        u_memory_checker
            (
                .mon_axi4            (axi4.mon            )
            );



    initial begin
        enable = 1'b0;

        wait (aresetn == 1'b1);
        repeat (20) @(posedge aclk);

        enable = 1'b1;
        repeat (TEST_CYCLES) @(posedge aclk);
        enable = 1'b0;


        u_model_axi4_s.write_memh("axi4_mem_dump.txt");

        $display("tb_model_axi4 passed");
        $finish;
    end

endmodule


`default_nettype wire


// end of file