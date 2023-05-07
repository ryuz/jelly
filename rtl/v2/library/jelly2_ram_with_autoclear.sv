// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// RAM with auto clear
module jelly2_ram_with_autoclear
        #(
            parameter   int                                 ADDR_WIDTH      = 12,
            parameter   int                                 DATA_WIDTH      = 8,
            parameter   int                                 WE_WIDTH        = 1,
            parameter   int                                 WORD_WIDTH      = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE        = (1 << ADDR_WIDTH),
            parameter                                       RAM_TYPE        = "block",
            parameter   bit                                 DOUT_REGS0      = 0,
            parameter   bit                                 DOUT_REGS1      = 0,
            parameter                                       MODE0           = "NO_CHANGE",
            parameter                                       MODE1           = "NO_CHANGE",
            parameter   bit                                 FILLMEM         = 0,
            parameter   logic   [WE_WIDTH*WORD_WIDTH-1:0]   FILLMEM_DATA    = 0,
            parameter   bit                                 READMEMB        = 0,
            parameter   bit                                 READMEMH        = 0,
            parameter                                       READMEM_FIlE    = "",
            parameter   int                                 RAM_ADDR_WIDTH  = RAM_TYPE == "ultra" ? (ADDR_WIDTH > 12 ? 12 : ADDR_WIDTH)
                                                                                                  : (ADDR_WIDTH > 10 ? 10 : ADDR_WIDTH),
            parameter   int                                 RAM_MEM_SIZE    = (1 << RAM_ADDR_WIDTH),
            parameter   int                                 RAM_BANK_WIDTH  = ADDR_WIDTH - RAM_ADDR_WIDTH,
            parameter   int                                 RAM_BANK_NUM    = (MEM_SIZE + RAM_MEM_SIZE - 1) / RAM_MEM_SIZE
        )
        (
            input   wire    [1:0]                           reset,
            input   wire    [1:0]                           clk,

            input   wire    [1:0][WE_WIDTH*WORD_WIDTH-1:0]  clear_din,
            input   wire    [1:0]                           clear_start,
            output  wire    [1:0]                           clear_busy,

            input   wire    [1:0]                           en,
            input   wire    [1:0]                           regcke,
            input   wire    [1:0][WE_WIDTH-1:0]             we,
            input   wire    [1:0][ADDR_WIDTH-1:0]           addr,
            input   wire    [1:0][WE_WIDTH*WORD_WIDTH-1:0]  din,
            output  wire    [1:0][WE_WIDTH*WORD_WIDTH-1:0]  dout
        );
    
    // RAM
    logic    [1:0][RAM_BANK_NUM-1:0]                        ram_en;
    logic    [1:0][RAM_BANK_NUM-1:0]                        ram_regcke;
    logic    [1:0][RAM_BANK_NUM-1:0]                        ram_we;
    logic    [1:0][RAM_BANK_NUM-1:0][RAM_ADDR_WIDTH-1:0]    ram_addr;
    logic    [1:0][RAM_BANK_NUM-1:0][DATA_WIDTH-1:0]        ram_din;
    logic    [1:0][RAM_BANK_NUM-1:0][DATA_WIDTH-1:0]        ram_dout;

    generate
    for ( genvar i = 0; i < RAM_BANK_NUM; ++i ) begin : loop_ram
        jelly2_ram_dualport
                #(
                    .ADDR_WIDTH     (RAM_ADDR_WIDTH),
                    .DATA_WIDTH     (DATA_WIDTH),
                    .WE_WIDTH       (WE_WIDTH),
                    .WORD_WIDTH     (WORD_WIDTH),
                    .MEM_SIZE       (RAM_MEM_SIZE),
                    .RAM_TYPE       (RAM_TYPE),
                    .DOUT_REGS0     (DOUT_REGS0),
                    .DOUT_REGS1     (DOUT_REGS1),
                    .MODE0          (MODE0),
                    .MODE1          (MODE1),
                    .FILLMEM        (FILLMEM),
                    .FILLMEM_DATA   (FILLMEM_DATA),
                    .READMEMB       (READMEMB),
                    .READMEMH       (READMEMH),
                    .READMEM_FIlE   (READMEM_FIlE)
                )
            i_ram_dualport
                (
                    .port0_clk      (clk[0]),
                    .port0_en       (ram_en    [0][i]),
                    .port0_regcke   (ram_regcke[0][i]),
                    .port0_we       (ram_we    [0][i]),
                    .port0_addr     (ram_addr  [0][i]),
                    .port0_din      (ram_din   [0][i]),
                    .port0_dout     (ram_dout  [0][i]),

                    .port1_clk      (clk[1]),
                    .port1_en       (ram_en    [1][i]),
                    .port1_regcke   (ram_regcke[1][i]),
                    .port1_we       (ram_we    [1][i]),
                    .port1_addr     (ram_addr  [1][i]),
                    .port1_din      (ram_din   [1][i]),
                    .port1_dout     (ram_dout  [1][i])
                );
    end
    endgenerate

    generate
    for ( genvar i = 0; i < 2; ++i ) begin : loop_control
        jelly2_autoclear_for_ram
                #(
                    .BANK_NUM       (RAM_BANK_NUM),
                    .BANK_WIDTH     (RAM_BANK_WIDTH),
                    .ADDR_WIDTH     (RAM_ADDR_WIDTH),
                    .DATA_WIDTH     (DATA_WIDTH),
                    .MEM_SIZE       (RAM_MEM_SIZE),
                    .DOUT_REGS      (i==0 ? DOUT_REGS0 : DOUT_REGS1)
                )
            i_autoclear_for_ram
                (
                    .reset          (reset      [i]),
                    .clk            (clk        [i]),

                    .clear_din      (clear_din  [i]),
                    .clear_start    (clear_start[i]),
                    .clear_busy     (clear_busy [i]),

                    .en             (en         [i]),
                    .regcke         (regcke     [i]),
                    .we             (we         [i]),
                    .addr           (addr       [i]),
                    .din            (din        [i]),
                    .dout           (dout       [i]),

                    .ram_en         (ram_en     [i]),
                    .ram_regcke     (ram_regcke [i]),
                    .ram_we         (ram_we     [i]),
                    .ram_addr       (ram_addr   [i]),
                    .ram_din        (ram_din    [i]),
                    .ram_dout       (ram_dout   [i])
                );
    end
    endgenerate
    

endmodule


`default_nettype wire


// End of file
