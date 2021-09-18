// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps


// Simple Dualport-RAM
module jelly2_ram_simple_dualport
        #(
            parameter   int                         ADDR_WIDTH   = 6,
            parameter   int                         DATA_WIDTH   = 8,
            parameter   int                         MEM_SIZE     = (1 << ADDR_WIDTH),
            parameter                               RAM_TYPE     = "distributed",
            parameter   bit                         DOUT_REGS    = 0,
            
            parameter   bit                         FILLMEM      = 0,
            parameter   bit     [DATA_WIDTH-1:0]    FILLMEM_DATA = 0,
            parameter   bit                         READMEMB     = 0,
            parameter   bit                         READMEMH     = 0,
            parameter   string                      READMEM_FIlE = ""
        )
        (
            // write port
            input       logic                       wr_clk,
            input       logic                       wr_en,
            input       logic   [ADDR_WIDTH-1:0]    wr_addr,
            input       logic   [DATA_WIDTH-1:0]    wr_din,
            
            // read port
            input       logic                       rd_clk,
            input       logic                       rd_en,
            input       logic                       rd_regcke,
            input       logic   [ADDR_WIDTH-1:0]    rd_addr,
            output      logic   [DATA_WIDTH-1:0]    rd_dout
        );
    
    parameter string RAM_STYLE = "distributed";
    
    // memory
    (* ram_style = RAM_STYLE *)
    logic   [DATA_WIDTH-1:0]    mem [0:MEM_SIZE-1];
    
    integer iMEM_SIZE = MEM_SIZE;
    
    // write port
    always_ff @ ( posedge wr_clk ) begin
        if ( wr_en ) begin
            mem[wr_addr] <= wr_din;
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
        always @(posedge rd_clk) begin
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
