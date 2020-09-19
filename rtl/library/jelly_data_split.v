// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_data_split
        #(
            parameter   NUM        = 16,
            parameter   DATA_WIDTH = 8,
            parameter   S_REGS     = 1,
            
            parameter   DATA_BITS  = DATA_WIDTH > 0 ? DATA_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [DATA_WIDTH-1:0]    s_data,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire    [DATA_WIDTH-1:0]    m_data,
            output  wire    [NUM-1:0]           m_valid,
            input   wire    [NUM-1:0]           m_ready
        );
    
    
    
    // -----------------------------------------
    //  insert FF
    // -----------------------------------------
    
    wire    [DATA_WIDTH-1:0]    ff_s_data;
    wire                        ff_s_valid;
    wire                        ff_s_ready;
    
    jelly_data_ff
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .S_REGS         (S_REGS),
                .M_REGS         (1)
            )
        i_data_ff_s
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         (s_data),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_data         (ff_s_data),
                .m_valid        (ff_s_valid),
                .m_ready        (ff_s_ready)
            );
    
    
    
    // -----------------------------------------
    //  split
    // -----------------------------------------
    
    reg     [DATA_BITS-1:0]         reg_data;
    reg     [NUM-1:0]               reg_valid;
    
    assign ff_s_ready = &(~m_valid | m_ready);
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_data  <= {DATA_BITS{1'bx}};
            reg_valid <= {NUM{1'bx}};
        end
        else if ( cke ) begin
            if ( ff_s_ready ) begin
                reg_data  <= ff_s_data;
                reg_valid <= {NUM{ff_s_valid}};
            end
            else begin
                reg_valid <= (reg_valid & ~m_ready);
            end
        end
    end
    
    assign m_data  = reg_data;
    assign m_valid = reg_valid;
    
    
endmodule


`default_nettype wire


// end of file
