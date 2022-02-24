// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// Dualport-RAM
module jelly2_ram_dualport
        #(
            parameter   int                                 ADDR_WIDTH   = 10,
            parameter   int                                 DATA_WIDTH   = 32,
            parameter   int                                 WE_WIDTH     = 1,
            parameter   int                                 WORD_WIDTH   = DATA_WIDTH/WE_WIDTH,
            parameter   int                                 MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                                       RAM_TYPE     = "block",
            parameter   bit                                 DOUT_REGS0   = 0,
            parameter   bit                                 DOUT_REGS1   = 0,
            parameter                                       MODE0        = "WRITE_FIRST",
            parameter                                       MODE1        = "WRITE_FIRST",

            parameter   bit                                 FILLMEM      = 0,
            parameter   logic   [WE_WIDTH*WORD_WIDTH-1:0]   FILLMEM_DATA = 0,
            parameter   bit                                 READMEMB     = 0,
            parameter   bit                                 READMEMH     = 0,
            parameter                                       READMEM_FIlE = ""
        )
        (
            // port0
            input   wire                                port0_clk,
            input   wire                                port0_en,
            input   wire                                port0_regcke,
            input   wire    [WE_WIDTH-1:0]              port0_we,
            input   wire    [ADDR_WIDTH-1:0]            port0_addr,
            input   wire    [WE_WIDTH*WORD_WIDTH-1:0]   port0_din,
            output  wire    [WE_WIDTH*WORD_WIDTH-1:0]   port0_dout,
            
            // port1
            input   wire                                port1_clk,
            input   wire                                port1_en,
            input   wire                                port1_regcke,
            input   wire    [WE_WIDTH-1:0]              port1_we,
            input   wire    [ADDR_WIDTH-1:0]            port1_addr,
            input   wire    [WE_WIDTH*WORD_WIDTH-1:0]   port1_din,
            output  wire    [WE_WIDTH*WORD_WIDTH-1:0]   port1_dout
        );
    
    // verilator lint_off MULTIDRIVEN
    
    // memory
    (* ram_style = RAM_TYPE *)
    reg     [WE_WIDTH*WORD_WIDTH-1:0]   mem [0:MEM_SIZE-1];
    
    // dout
    logic   [WE_WIDTH*WORD_WIDTH-1:0]   tmp_port0_dout;
    logic   [WE_WIDTH*WORD_WIDTH-1:0]   tmp_port1_dout;
    
    
    // port0
    generate
    for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : blk_wf0
        if ( MODE0 == "WRITE_FIRST" ) begin
            // write first
            always_ff @ ( posedge port0_clk ) begin
                if ( port0_en ) begin
                    if ( port0_we[i] ) begin
                        mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i];
                        tmp_port0_dout[i] <= port0_din[i];
                    end
                    else begin
                        tmp_port0_dout[i] <= mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
        else begin
            // read first
            always_ff @ ( posedge port0_clk ) begin
                if ( port0_en ) begin
                    if ( port0_we[i] ) begin
                        mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port0_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    tmp_port0_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port0_addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end
    
    // DOUT FF insert
    if ( DOUT_REGS0 ) begin
        logic   [WE_WIDTH*WORD_WIDTH-1:0]  reg_port0_dout;
        always_ff @(posedge port0_clk) begin
            if ( port0_regcke ) begin
                reg_port0_dout <= tmp_port0_dout;
            end
        end
        assign port0_dout = reg_port0_dout;
    end
    else begin
        assign port0_dout = tmp_port0_dout;
    end
    endgenerate
    
    
    // port1
    generate
    for ( genvar i = 0; i < WE_WIDTH; ++i ) begin : blk_wf1
        if ( MODE1 == "WRITE_FIRST" ) begin
            // write first
            always_ff @ ( posedge port1_clk ) begin
                if ( port1_en ) begin
                    if ( port1_we[i] ) begin
                        mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                        tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    else begin
                        tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH];
                    end
                end
            end
        end
        else begin
            // read first
            always_ff @ ( posedge port1_clk ) begin
                if ( port1_en ) begin
                    if ( port1_we[i] ) begin
                        mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH] <= port1_din[i*WORD_WIDTH +: WORD_WIDTH];
                    end
                    tmp_port1_dout[i*WORD_WIDTH +: WORD_WIDTH] <= mem[port1_addr][i*WORD_WIDTH +: WORD_WIDTH];
                end
            end
        end
    end
    
    // DOUT FF insert
    if ( DOUT_REGS1 ) begin
        logic   [WE_WIDTH*WORD_WIDTH-1:0]   reg_port1_dout;
        always_ff @(posedge port1_clk) begin
            if ( port1_regcke ) begin
                reg_port1_dout <= tmp_port1_dout;
            end
        end
        assign port1_dout = reg_port1_dout;
    end
    else begin
        assign port1_dout = tmp_port1_dout;
    end
    endgenerate
    
    // verilator lint_on MULTIDRIVEN
    
    
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


`default_nettype wire


// End of file
