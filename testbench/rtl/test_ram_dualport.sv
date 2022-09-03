// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Dualport-RAM
module test_ram_dualport
        #(
            parameter   int                                 ADDR_WIDTH   = 14,
            parameter   int                                 DATA_WIDTH   = 8,
            parameter   int                                 WE_WIDTH     = 1,
            parameter   int                                 WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                       RAM_TYPE     = "ultra", // "block",
            parameter   bit                                 DOUT_REGS0   = 0,
            parameter   bit                                 DOUT_REGS1   = 0,
            parameter                                       MODE0        = "NO_CHANGE",
            parameter                                       MODE1        = "NO_CHANGE",

            parameter   bit                                 FILLMEM      = 0,
            parameter   logic   [WE_WIDTH*WORD_WIDTH-1:0]   FILLMEM_DATA = 0,
            parameter   bit                                 READMEMB     = 0,
            parameter   bit                                 READMEMH     = 0,
            parameter                                       READMEM_FIlE = ""
        )
        (
            input   wire                                clk,

            // port0
            input   wire                                port0_en,
            input   wire                                port0_regcke,
            input   wire    [WE_WIDTH-1:0]              port0_we,
            input   wire    [ADDR_WIDTH-1:0]            port0_addr,
            input   wire    [WE_WIDTH*WORD_WIDTH-1:0]   port0_din,
            output  wire    [WE_WIDTH*WORD_WIDTH-1:0]   port0_dout,
            
            // port1
            input   wire                                port1_en,
            input   wire                                port1_regcke,
            input   wire    [WE_WIDTH-1:0]              port1_we,
            input   wire    [ADDR_WIDTH-1:0]            port1_addr,
            input   wire    [WE_WIDTH*WORD_WIDTH-1:0]   port1_din,
            output  wire    [WE_WIDTH*WORD_WIDTH-1:0]   port1_dout
        );
    
 
    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (ADDR_WIDTH  ),
                .DATA_WIDTH     (DATA_WIDTH  ),
                .WE_WIDTH       (WE_WIDTH    ),
                .WORD_WIDTH     (WORD_WIDTH  ),
                .MEM_SIZE       (MEM_SIZE    ),
                .RAM_TYPE       (RAM_TYPE    ),
                .DOUT_REGS0     (DOUT_REGS0  ),
                .DOUT_REGS1     (DOUT_REGS1  ),
                .MODE0          (MODE0       ),
                .MODE1          (MODE1       ),

                .FILLMEM        (FILLMEM     ),
                .FILLMEM_DATA   (FILLMEM_DATA),
                .READMEMB       (READMEMB    ),
                .READMEMH       (READMEMH    ),
                .READMEM_FIlE   (READMEM_FIlE)
            )
        i_ram_dualport
            (
                .port0_clk      (clk),
                .port0_en,
                .port0_regcke,
                .port0_we,
                .port0_addr,
                .port0_din,
                .port0_dout,
                
                .port1_clk      (clk),
                .port1_en,
                .port1_regcke,
                .port1_we,
                .port1_addr,
                .port1_din,
                .port1_dout
            );
    
endmodule


`default_nettype wire


// End of file
