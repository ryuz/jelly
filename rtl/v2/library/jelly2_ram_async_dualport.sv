// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none

// Dualport async RAM
module jelly2_ram_async_dualport
        #(
            parameter   int                         ADDR_WIDTH   = 8,
            parameter   int                         DATA_WIDTH   = 1,
            parameter   int                         MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                               RAM_TYPE     = "distributed",
            
            parameter   bit                         FILLMEM      = 0,
            parameter   bit     [DATA_WIDTH-1:0]    FILLMEM_DATA = 0,
            parameter   bit                         READMEMB     = 0,
            parameter   bit                         READMEMH     = 0,
            parameter                               READMEM_FIlE = ""
        )
        (
            // port0 (read/write)
            input   var logic                       port0_clk,
            input   var logic                       port0_we,
            input   var logic   [ADDR_WIDTH-1:0]    port0_addr,
            input   var logic   [DATA_WIDTH-1:0]    port0_din,
            output  var logic   [DATA_WIDTH-1:0]    port0_dout,
            
            // port1 (read only)
            input   var logic   [ADDR_WIDTH-1:0]    port1_addr,
            output  var logic   [DATA_WIDTH-1:0]    port1_dout
        );
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [DATA_WIDTH-1:0]    mem [0:MEM_SIZE-1];

    // port0 (read/write)
    always_ff @ ( posedge port0_clk ) begin
        if ( port0_we ) begin
            mem[port0_addr] <= port0_din;
        end
    end
    assign port0_dout = mem[port0_addr];
    
    // port1 (read only)
    assign port1_dout = mem[port1_addr];


    // initialize
    initial begin
        if ( FILLMEM ) begin
            for ( int i = 0; i < MEM_SIZE; i++ ) begin
                mem[i] = FILLMEM_DATA;
            end
        end
        
        if ( READMEMB ) begin
            $readmemb(READMEM_FIlE, mem);
        end
        if ( READMEMH ) begin
            $readmemh(READMEM_FIlE, mem);
        end
    end
        
endmodule


`default_nettype wire


// End of file
