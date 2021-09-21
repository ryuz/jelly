// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// FIFO
module jelly2_fifo_shifter
        #(
            parameter   int     DATA_WIDTH = 8,
            parameter   int     PTR_WIDTH  = 6,
            parameter   int     FIFO_SIZE  = (1 << PTR_WIDTH),
            parameter   bit     DOUT_REGS  = 0
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        wr_en,
            input   wire    [DATA_WIDTH-1:0]    wr_data,
            
            input   wire                        rd_en,
            input   wire                        rd_regcke,
            output  wire    [DATA_WIDTH-1:0]    rd_data,
            
            output  wire                        full,
            output  wire                        empty,
            output  wire    [PTR_WIDTH:0]       free_count,
            output  wire    [PTR_WIDTH:0]       data_count
        );
    
    wire                        write_en = (wr_en & ~full);
    wire                        read_en  = (rd_en & ~empty);
    
    // shifter
    logic   [PTR_WIDTH-1:0]     shifter_sel;
    logic   [DATA_WIDTH-1:0]    shifter_data;
    jelly2_data_shift_register_lut
            #(
                .SEL_WIDTH      (PTR_WIDTH),
                .NUM            (FIFO_SIZE),
                .DATA_WIDTH     (DATA_WIDTH)
            )
        i_data_shift_register_lut
            (
                .clk            (clk),
                .cke            (cke & write_en),
                
                .in_data        (wr_data),
                
                .sel            (shifter_sel),
                .out_data       (shifter_data)
            );
    
    
    // control
    logic   [DATA_WIDTH-1:0]    reg_dout;
    logic   [PTR_WIDTH-1:0]     reg_ptr;
    logic                       reg_empty;
    logic                       reg_full;
    
    wire    [PTR_WIDTH:0]       next_ptr = {1'b0, reg_ptr} + PTR_WIDTH'(write_en) - PTR_WIDTH'(read_en);
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_dout  <= {DATA_WIDTH{1'bx}};
            reg_ptr   <= {PTR_WIDTH{1'bx}};
            reg_empty <= 1'b1;
            reg_full  <= 1'b0;
        end
        else if ( cke ) begin
            if ( read_en ) begin
                reg_dout <= shifter_data;
            end
            
            if ( reg_empty ) begin
                reg_full  <= 1'b0;
                reg_empty <= ~wr_en;
                reg_ptr   <= {PTR_WIDTH{1'b0}};
            end
            else begin
                reg_ptr   <= next_ptr[PTR_WIDTH] ? {PTR_WIDTH{1'b0}} : next_ptr[PTR_WIDTH-1:0];
                reg_empty <= next_ptr[PTR_WIDTH];
                reg_full  <= (next_ptr == (PTR_WIDTH+1)'(FIFO_SIZE-1));
            end
        end
    end
    
    assign shifter_sel = reg_ptr;
    
    
    assign empty      = reg_empty;
    assign full       = reg_full;
    
    assign free_count = {1'b0, ~reg_ptr} + (PTR_WIDTH+1)'(reg_empty);
    assign data_count = {1'b0, reg_ptr} + (PTR_WIDTH+1)'(!reg_empty);
    
    
    generate
    if ( DOUT_REGS ) begin : blk_dout_reg
        reg     [DATA_WIDTH-1:0]    reg_rd_data;
        always_ff @(posedge clk) begin
            if ( cke ) begin
                if ( rd_regcke ) begin
                    reg_rd_data <= reg_dout;
                end
            end
        end
        assign rd_data = reg_rd_data;
    end
    else begin
        assign rd_data = reg_dout;
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file
