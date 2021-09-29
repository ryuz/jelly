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
            parameter   int                         ADDR_WIDTH   = 8,
            parameter   int                         DATA_WIDTH   = 8,
            parameter   int                         MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                               RAM_TYPE     = "block",
            parameter   bit                         DOUT_REGS0   = 0,
            parameter   bit                         DOUT_REGS1   = 0,
            parameter                               MODE0        = "WRITE_FIRST",
            parameter                               MODE1        = "WRITE_FIRST",

            parameter   bit                         FILLMEM      = 0,
            parameter   logic   [DATA_WIDTH-1:0]    FILLMEM_DATA = 0,
            parameter   bit                         READMEMB     = 0,
            parameter   bit                         READMEMH     = 0,
            parameter                               READMEM_FIlE = ""
        )
        (
            // port0
            input   wire                        port0_clk,
            input   wire                        port0_en,
            input   wire                        port0_regcke,
            input   wire                        port0_we,
            input   wire    [ADDR_WIDTH-1:0]    port0_addr,
            input   wire    [DATA_WIDTH-1:0]    port0_din,
            output  wire    [DATA_WIDTH-1:0]    port0_dout,
            
            // port1
            input   wire                        port1_clk,
            input   wire                        port1_en,
            input   wire                        port1_regcke,
            input   wire                        port1_we,
            input   wire    [ADDR_WIDTH-1:0]    port1_addr,
            input   wire    [DATA_WIDTH-1:0]    port1_din,
            output  wire    [DATA_WIDTH-1:0]    port1_dout
        );
    
    // verilator lint_off MULTIDRIVEN

    // memory
    (* ram_style = RAM_TYPE *)
    reg     [DATA_WIDTH-1:0]    mem [0:MEM_SIZE-1];
    
    // dout
    reg     [DATA_WIDTH-1:0]    tmp_port0_dout;
    reg     [DATA_WIDTH-1:0]    tmp_port1_dout;
    
    // port0
    generate
    if ( 128'(MODE0) == 128'("WRITE_FIRST") ) begin
        // write first
        always_ff @ ( posedge port0_clk ) begin
            if ( port0_en ) begin
                if ( port0_we ) begin
                    mem[port0_addr] <= port0_din;
                end
                
                if ( port0_we ) begin
                    tmp_port0_dout <= port0_din;
                end
                else begin
                    tmp_port0_dout <= mem[port0_addr];
                end
            end
        end
    end
    else begin
        // read first
        always_ff @ ( posedge port0_clk ) begin
            if ( port0_en ) begin
                if ( port0_we ) begin
                    mem[port0_addr] <= port0_din;
                end
                tmp_port0_dout <= mem[port0_addr];
            end
        end
    end
    
    // DOUT FF insert
    if ( DOUT_REGS0 ) begin
        reg     [DATA_WIDTH-1:0]    reg_port0_dout;
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
    if ( 128'(MODE1) == 128'("WRITE_FIRST") ) begin
        // write first
        always_ff @ ( posedge port1_clk ) begin
            if ( port1_en ) begin
                if ( port1_we ) begin
                    mem[port1_addr] <= port1_din;
                end
                
                if ( port1_we ) begin
                    tmp_port1_dout <= port1_din;
                end
                else begin
                    tmp_port1_dout <= mem[port1_addr];
                end
            end
        end
    end
    else begin
        // read first
        always_ff @ ( posedge port1_clk ) begin
            if ( port1_en ) begin
                if ( port1_we ) begin
                    mem[port1_addr] <= port1_din;
                end
                tmp_port1_dout <= mem[port1_addr];
            end
        end
    end
    
    // DOUT FF insert
    if ( DOUT_REGS1 ) begin
        reg     [DATA_WIDTH-1:0]    reg_port1_dout;
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
