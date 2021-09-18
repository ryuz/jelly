// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps


// FIFO
module jelly2_fifo
        #(
            parameter   int                         DATA_WIDTH = 8,
            parameter   int                         PTR_WIDTH  = 10,
            parameter   bit                         DOUT_REGS  = 0,
            parameter                               RAM_TYPE   = "block",
            parameter   bit                         LOW_DEALY  = 0
        )
        (
            input       logic                       reset,
            input       logic                       clk,

            input       logic                       wr_en,
            input       logic   [DATA_WIDTH-1:0]    wr_data,

            input       logic                       rd_en,
            input       logic                       rd_regcke,
            output      logic   [DATA_WIDTH-1:0]    rd_data,

            output      logic                       full,
            output      logic                       empty,
            output      logic   [PTR_WIDTH:0]       free_count,
            output      logic   [PTR_WIDTH:0]       data_count
        );
    
    
    generate
    if ( LOW_DEALY && (string'(RAM_TYPE) == "distributed") && PTR_WIDTH < 8 ) begin : blk_shifter
        jelly2_fifo_shifter
                #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .PTR_WIDTH      (PTR_WIDTH),
                    .DOUT_REGS      (DOUT_REGS)
                )
            i_fifo_shifter
                (
                    .reset          (reset),
                    .clk            (clk),
                    
                    .wr_en          (wr_en),
                    .wr_data        (wr_data),
                    
                    .rd_en          (rd_en),
                    .rd_regcke      (rd_regcke),
                    .rd_data        (rd_data),
                    
                    .full           (full),
                    .empty          (empty),
                    .free_count     (free_count),
                    .data_count     (data_count)
                );
    end
    else begin : blk_ram
        jelly2_fifo_ram
                #(
                    .DATA_WIDTH     (DATA_WIDTH),
                    .PTR_WIDTH      (PTR_WIDTH),
                    .DOUT_REGS      (DOUT_REGS),
                    .RAM_TYPE       (RAM_TYPE),
                    .LOW_DEALY      (LOW_DEALY)
                )
            i_fifo_ram
                (
                    .reset          (reset),
                    .clk            (clk),
                    
                    .wr_en          (wr_en),
                    .wr_data        (wr_data),
                    
                    .rd_en          (rd_en),
                    .rd_regcke      (rd_regcke),
                    .rd_data        (rd_data),
                    
                    .full           (full),
                    .empty          (empty),
                    .free_count     (free_count),
                    .data_count     (data_count)
                );
    end
    endgenerate
        
endmodule


// end of file
