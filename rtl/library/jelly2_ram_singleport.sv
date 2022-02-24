// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// Singleport-RAM
module jelly2_ram_singleport
        #(
            parameter   int                                 ADDR_WIDTH   = 10,
            parameter   int                                 DATA_WIDTH   = 32,
            parameter   int                                 WE_WIDTH     = 1,
            parameter   int                                 WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                       RAM_TYPE     = "block",
            parameter   bit                                 DOUT_REGS    = 0,
            parameter                                       MODE         = "WRITE_FIRST",
            
            parameter   bit                                 FILLMEM      = 0,
            parameter   logic   [WE_WIDTH*WORD_WIDTH-1:0]   FILLMEM_DATA = 0,
            parameter   bit                                 READMEMB     = 0,
            parameter   bit                                 READMEMH     = 0,
            parameter                                       READMEM_FILE = ""
        )
        (
            input   wire                                clk,
            input   wire                                en,
            input   wire                                regcke,
            input   wire    [WE_WIDTH-1:0]              we,
            input   wire    [ADDR_WIDTH-1:0]            addr,
            input   wire    [WE_WIDTH*WORD_WIDTH-1:0]   din,
            output  wire    [WE_WIDTH*WORD_WIDTH-1:0]   dout
        );
    
    // memory
    (* ram_style = RAM_TYPE *)
    logic   [WE_WIDTH*WORD_WIDTH-1:0]    mem [0:MEM_SIZE-1];
    
    logic   [WE_WIDTH*WORD_WIDTH-1:0]    tmp_dout;
    
    generate
    for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : loop_lane
        if ( MODE == "WRITE_FIRST" ) begin : blk_write_first
            // write first
            always_ff @ ( posedge clk ) begin
                if ( en ) begin
                    if ( we[i] ) begin
                        mem[addr][i*WORD_WIDTH +: WORD_WIDTH] <= din[i*WORD_WIDTH +: WORD_WIDTH];
                        tmp_dout[i*WORD_WIDTH +: WORD_WIDTH] <= din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    else begin
                        tmp_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
        else begin : blk_read_first
            // read first
            always_ff @( posedge clk ) begin
                if ( en ) begin
                    if ( we[i] ) begin
                        mem[addr][i*WORD_WIDTH +: WORD_WIDTH] <= din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    tmp_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end
    endgenerate
    
    
    // DOUT FF insert
    if ( DOUT_REGS ) begin : blk_dout_regs
        logic   [WE_WIDTH*WORD_WIDTH-1:0]    reg_dout;
        always_ff @(posedge clk) begin
            if ( regcke ) begin
                reg_dout <= tmp_dout;
            end
        end
        assign dout = reg_dout;
    end
    else begin: blk_dout
        assign dout = tmp_dout;
    end
    
    
    // initialize
    initial begin
        if ( FILLMEM ) begin
            for ( int i = 0; i < MEM_SIZE; i = i + 1 ) begin
                mem[i] = FILLMEM_DATA;
            end
        end
        
        if ( READMEMB ) begin
            $display("readmemb:%s", READMEM_FILE);
            $readmemb(READMEM_FILE, mem);
        end
        
        if ( READMEMH ) begin
            $display("readmemh:%s", READMEM_FILE);
            $readmemh(READMEM_FILE, mem);
        end
    end
    
endmodule


`default_nettype wire


// end of file
