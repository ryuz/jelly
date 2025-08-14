
`timescale 1ns / 1ps
`default_nettype none

module jfive_tcm
        #(
            parameter   int                                 ADDR_WIDTH   = 14,
            parameter   int                                 DATA_WIDTH   = 32,
            parameter   int                                 WE_WIDTH     = 4,
            parameter   int                                 WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                       RAM_TYPE     = "block",
            parameter   bit                                 DOUT_REGS0   = 0,
            parameter   bit                                 DOUT_REGS1   = 0,
            parameter                                       MODE0        = "NORMAL",
            parameter                                       MODE1        = "NORMAL",

            parameter   bit                                 FILLMEM      = 0,
            parameter   logic   [WE_WIDTH*WORD_WIDTH-1:0]   FILLMEM_DATA = 0,
            parameter   bit                                 READMEMB     = 0,
            parameter   bit                                 READMEMH     = 1,
            parameter                                       READMEM_FIlE = "../mem.hex"
        )
        (
            // port0
            input   var logic                               port0_clk,
            input   var logic                               port0_en,
            input   var logic                               port0_regcke,
            input   var logic   [WE_WIDTH-1:0]              port0_we,
            input   var logic   [ADDR_WIDTH-1:0]            port0_addr,
            input   var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port0_din,
            output  var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port0_dout,
            
            // port1
            input   var logic                               port1_clk,
            input   var logic                               port1_en,
            input   var logic                               port1_regcke,
            input   var logic   [WE_WIDTH-1:0]              port1_we,
            input   var logic   [ADDR_WIDTH-1:0]            port1_addr,
            input   var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port1_din,
            output  var logic   [WE_WIDTH*WORD_WIDTH-1:0]   port1_dout
        );


    jelly2_ram_dualport
            #(
                .ADDR_WIDTH     (ADDR_WIDTH     ),
                .DATA_WIDTH     (DATA_WIDTH     ),
                .WE_WIDTH       (WE_WIDTH       ),
                .WORD_WIDTH     (WORD_WIDTH     ),
                .MEM_SIZE       (MEM_SIZE       ),
                .RAM_TYPE       (RAM_TYPE       ),
                .DOUT_REGS0     (DOUT_REGS0     ),
                .DOUT_REGS1     (DOUT_REGS1     ),
                .MODE0          (MODE0          ),
                .MODE1          (MODE1          ),
                .FILLMEM        (FILLMEM        ),
                .FILLMEM_DATA   (FILLMEM_DATA   ),
                .READMEMB       (READMEMB       ),
                .READMEMH       (READMEMH       ),
                .READMEM_FIlE   (READMEM_FIlE   )
            )
        u_ram_dualport
            (
                .port0_clk      ,
                .port0_en       ,
                .port0_regcke   ,
                .port0_we       ,
                .port0_addr     ,
                .port0_din      ,
                .port0_dout     ,
                
                .port1_clk      ,
                .port1_en       ,
                .port1_regcke   ,
                .port1_we       ,
                .port1_addr     ,
                .port1_din      ,
                .port1_dout     
            );

endmodule


`default_nettype wire


// end of file
