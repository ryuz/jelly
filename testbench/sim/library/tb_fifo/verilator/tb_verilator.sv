

`timescale 1ns / 1ps


module tb_verilator(
            input   logic   reset,
            input   logic   clk
        );
    

    /*
    parameter   int                         ADDR_WIDTH   = 6;
    parameter   int                         DATA_WIDTH   = 8;
    parameter   int                         MEM_SIZE     = (1 << ADDR_WIDTH);
    parameter   string                      RAM_TYPE     = "distributed";
    parameter   bit                         DOUT_REGS    = 0;
    
    parameter   bit                         FILLMEM      = 0;
    parameter   logic   [DATA_WIDTH-1:0]    FILLMEM_DATA = 0;
    parameter   bit                         READMEMB     = 0;
    parameter   bit                         READMEMH     = 0;
    parameter   string                      READMEM_FIlE = "";


    logic                       wr_clk;
    logic                       wr_en;
    logic   [ADDR_WIDTH-1:0]    wr_addr;
    logic   [DATA_WIDTH-1:0]    wr_din;
    
    logic                       rd_clk;
    logic                       rd_en;
    logic                       rd_regcke;
    logic   [ADDR_WIDTH-1:0]    rd_addr;
    logic   [DATA_WIDTH-1:0]    rd_dout;


    jelly2_ram_simple_dualport
            #(
                .ADDR_WIDTH         (ADDR_WIDTH   ),
                .DATA_WIDTH         (DATA_WIDTH   ),
                .MEM_SIZE           (MEM_SIZE     ),
                .RAM_TYPE           (RAM_TYPE     ),
                .DOUT_REGS          (DOUT_REGS    ),
                .FILLMEM            (FILLMEM      ),
                .FILLMEM_DATA       (FILLMEM_DATA ),
                .READMEMB           (READMEMB     ),
                .READMEMH           (READMEMH     ),
                .READMEM_FIlE       (READMEM_FIlE )
            )
        i_ram_simple_dualport
            (
                .*
            );
    */

    
    parameter   int     DATA_WIDTH = 8;
    parameter   int     PTR_WIDTH  = 4;
    parameter   bit     DOUT_REGS  = 0;
    parameter   string  RAM_TYPE   = "distributed"; //"block";
    parameter   bit     LOW_DEALY  = 1;

    logic                        wr_en = 1;
    logic    [DATA_WIDTH-1:0]    wr_data = 1;
    logic                        rd_en = 1;
    logic                        rd_regcke = 1;
    logic    [DATA_WIDTH-1:0]    rd_data;

    logic                        full;
    logic                        empty;
    logic    [PTR_WIDTH:0]       free_count;
    logic    [PTR_WIDTH:0]       data_count;

    // FIFO
    jelly2_fifo
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .PTR_WIDTH      (PTR_WIDTH),
                .DOUT_REGS      (DOUT_REGS),
                .RAM_TYPE       (RAM_TYPE),
                .LOW_DEALY      (LOW_DEALY)
            )
        i_fifo
            (
                .*
            );
    
endmodule


`default_nettype wire


// end of file
