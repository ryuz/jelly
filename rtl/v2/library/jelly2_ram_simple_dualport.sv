// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// Simple Dualport-RAM
module jelly2_ram_simple_dualport
        #(
            parameter   int                         ADDR_WIDTH   = 6,
            parameter   int                         DATA_WIDTH   = 8,
            parameter   int                         WE_WIDTH     = 1,
            parameter   int                         WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                         MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                               RAM_TYPE     = "distributed",
            parameter   bit                         DOUT_REGS    = 0,
            
            parameter   bit                         FILLMEM      = 0,
            parameter   bit     [DATA_WIDTH-1:0]    FILLMEM_DATA = 0,
            parameter   bit                         READMEMB     = 0,
            parameter   bit                         READMEMH     = 0,
            parameter                               READMEM_FIlE = ""
        )
        (
            // write port
            input   var logic                       wr_clk,
            input   var logic   [WE_WIDTH-1:0]      wr_en,
            input   var logic   [ADDR_WIDTH-1:0]    wr_addr,
            input   var logic   [DATA_WIDTH-1:0]    wr_din,
            
            // read port
            input   var logic                       rd_clk,
            input   var logic                       rd_en,
            input   var logic                       rd_regcke,
            input   var logic   [ADDR_WIDTH-1:0]    rd_addr,
            output  var logic   [DATA_WIDTH-1:0]    rd_dout
        );
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [DATA_WIDTH-1:0]    mem [0:MEM_SIZE-1];
    
    integer iMEM_SIZE = MEM_SIZE;
    
    // write port
    for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_we0
        always_ff @ ( posedge wr_clk ) begin
            if ( wr_en[i] ) begin
                mem[wr_addr][i*WORD_WIDTH +: WORD_WIDTH] <= wr_din[i*WORD_WIDTH +: WORD_WIDTH];
            end
        end
    end
    
    
    // read port
    logic   [DATA_WIDTH-1:0]    tmp_dout;
    always_ff @(posedge rd_clk ) begin
        if ( rd_en ) begin
            tmp_dout <= mem[rd_addr];
        end
    end
    
    
    // DOUT FF insert
    generate
    if ( DOUT_REGS ) begin : blk_reg
        logic   [DATA_WIDTH-1:0]    reg_dout;
        always_ff @(posedge rd_clk) begin
            if ( rd_regcke ) begin
                reg_dout <= tmp_dout;
            end
        end
        assign rd_dout = reg_dout;
    end
    else begin : blk_no_reg
        assign rd_dout = tmp_dout;
    end
    endgenerate
    
    // initialize
    initial begin
        if ( FILLMEM ) begin
            for ( int i = 0; i < MEM_SIZE; i = i + 1 ) begin
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


// End of file
