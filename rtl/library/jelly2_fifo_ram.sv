// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// FIFO
module jelly2_fifo_ram
        #(
            parameter   int     DATA_WIDTH = 8,
            parameter   int     PTR_WIDTH  = 10,
            parameter   bit     DOUT_REGS  = 0,
            parameter   string  RAM_TYPE   = "block",
            parameter   bit     LOW_DEALY  = 0
        )
        (
            input   logic                       reset,
            input   logic                       clk,
            
            input   logic                       wr_en,
            input   logic   [DATA_WIDTH-1:0]    wr_data,
            
            input   logic                       rd_en,
            input   logic                       rd_regcke,
            output  logic   [DATA_WIDTH-1:0]    rd_data,
            
            output  logic                        full,
            output  logic                        empty,
            output  logic    [PTR_WIDTH:0]       free_count,
            output  logic    [PTR_WIDTH:0]       data_count
        );
    
    
    // ---------------------------------
    //  RAM
    // ---------------------------------
    
    wire                        ram_wr_en;
    wire    [PTR_WIDTH-1:0]     ram_wr_addr;
    wire    [DATA_WIDTH-1:0]    ram_wr_data;
    
    wire                        ram_rd_en;
    wire    [PTR_WIDTH-1:0]     ram_rd_addr;
    wire    [DATA_WIDTH-1:0]    ram_rd_data;
    
    // ram
    jelly2_ram_simple_dualport
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .ADDR_WIDTH     (PTR_WIDTH),
                .DOUT_REGS      (DOUT_REGS),
                .RAM_TYPE       (RAM_TYPE)
            )
        i_ram_simple_dualport
            (
                .wr_clk         (clk),
                .wr_en          (ram_wr_en),
                .wr_addr        (ram_wr_addr),
                .wr_din         (ram_wr_data),
                
                .rd_clk         (clk),
                .rd_en          (ram_rd_en),
                .rd_regcke      (rd_regcke),
                .rd_addr        (ram_rd_addr),
                .rd_dout        (ram_rd_data)
            );
    
    
    // ---------------------------------
    //  FIFO pointer
    // ---------------------------------
    
    // write
    logic   [PTR_WIDTH:0]       wptr;
    logic   [PTR_WIDTH:0]       rptr;
    
    logic   [PTR_WIDTH:0]       next_rptr;
    logic   [PTR_WIDTH:0]       next_wptr;
    logic                       next_empty;
    logic                       next_full;
    logic   [PTR_WIDTH:0]       next_data_count;
    logic   [PTR_WIDTH:0]       next_free_count;
    always_comb begin
        next_wptr       = wptr;
        next_rptr       = rptr;
        next_empty      = empty;
        next_full       = full;
        next_data_count = data_count;
        next_free_count = free_count;
        
        if ( ram_wr_en ) begin
            next_wptr = wptr + 1'b1;
        end
        if ( ram_rd_en ) begin
            next_rptr = rptr + 1'b1;
        end
        
        if ( LOW_DEALY ) begin
            next_empty      = (next_wptr == next_rptr);
            next_full       = (next_wptr[PTR_WIDTH] != next_rptr[PTR_WIDTH]) && (next_wptr[PTR_WIDTH-1:0] == next_rptr[PTR_WIDTH-1:0]);
            next_data_count = (next_wptr - next_rptr);
            next_free_count = ((next_rptr - next_wptr) + (1 << PTR_WIDTH));
        end
        else begin
            next_empty      = (wptr == next_rptr);
            next_full       = (next_wptr[PTR_WIDTH] != rptr[PTR_WIDTH]) && (next_wptr[PTR_WIDTH-1:0] == rptr[PTR_WIDTH-1:0]);
            next_data_count = (wptr - next_rptr);
            next_free_count = ((rptr - next_wptr) + (1 << PTR_WIDTH));
        end
    end
    
    always_ff @( posedge clk ) begin
        if ( reset ) begin
            wptr       <= '0;
            rptr       <= '0;
            full       <= 1'b1;
            empty      <= 1'b1;
            free_count <= '0;
            data_count <= '0;
        end
        else begin
            wptr       <= next_wptr;
            rptr       <= next_rptr;
            full       <= next_full;
            empty      <= next_empty;
            free_count <= next_free_count;
            data_count <= next_data_count;
        end
    end
    
    assign ram_wr_en   = wr_en & ~full;
    assign ram_wr_addr = wptr[PTR_WIDTH-1:0];
    assign ram_wr_data = wr_data;
    
    assign ram_rd_en   = rd_en & ~empty;
    assign ram_rd_addr = rptr[PTR_WIDTH-1:0];
    assign rd_data     = ram_rd_data;
    
endmodule


`default_nettype wire


// end of file
