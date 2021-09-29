

`timescale          1ns / 1ps
`default_nettype    none

module tb_verilator(
            input   wire    reset0,
            input   wire    clk0,
            input   wire    reset1,
            input   wire    clk1
        );

    parameter   int                         ADDR_WIDTH      = 11;
    parameter   int                         DATA_WIDTH      = 8;
    parameter   int                         MEM_SIZE        = (1 << ADDR_WIDTH);
    parameter                               RAM_TYPE        = "block";
    parameter   int                         DOUT_REGS0      = 0;
    parameter   int                         DOUT_REGS1      = 0;
    parameter                               MODE0           = "WRITE_FIRST";
    parameter                               MODE1           = "WRITE_FIRST";
    parameter   bit                         FILLMEM         = 0;
    parameter   logic   [DATA_WIDTH-1:0]    FILLMEM_DATA    = 0;
    parameter   bit                         READMEMB        = 0;
    parameter   bit                         READMEMH        = 0;
    parameter                               READMEM_FIlE    = "";
    parameter   int                         UNIT_ADDR_WIDTH = ADDR_WIDTH > 9 ? 9 : ADDR_WIDTH;

    logic   [1:0]                   reset;
    logic   [1:0]                   clk;
    logic   [1:0]                   en;
    logic   [1:0]                   regcke;
    logic   [1:0]                   we;
    logic   [1:0][ADDR_WIDTH-1:0]   addr;
    logic   [1:0][DATA_WIDTH-1:0]   din;
    logic   [1:0][DATA_WIDTH-1:0]   dout;
    logic   [1:0][DATA_WIDTH-1:0]   clear_din;
    logic   [1:0]                   clear_start;
    logic   [1:0]                   clear_busy;

    jelly2_ram_with_autoclear
            #(
                .ADDR_WIDTH         (ADDR_WIDTH     ),
                .DATA_WIDTH         (DATA_WIDTH     ),
                .MEM_SIZE           (MEM_SIZE       ),
                .RAM_TYPE           (RAM_TYPE       ),
                .DOUT_REGS0         (DOUT_REGS0     ),
                .DOUT_REGS1         (DOUT_REGS1     ),
                .MODE0              (MODE0          ),
                .MODE1              (MODE1          ),
                .FILLMEM            (FILLMEM        ),
                .FILLMEM_DATA       (FILLMEM_DATA   ),
                .READMEMB           (READMEMB       ),
                .READMEMH           (READMEMH       ),
                .READMEM_FIlE       (READMEM_FIlE   ),
                .UNIT_ADDR_WIDTH    (UNIT_ADDR_WIDTH)
            )
        i_ram_with_autoclear
            (
                .*
            );

endmodule


`default_nettype    wire


// end of file
