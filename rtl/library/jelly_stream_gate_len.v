// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 許可された個数で first last を付与して stream にする
module jelly_stream_gate_len
        #(
            parameter   DATA_WIDTH    = 32,
            parameter   LEN_WIDTH     = 32,
            parameter   LEN_OFFSET    = 1'b1,
            
            parameter   S_PERMIT_REGS = 1,
            parameter   S_REGS        = 1,
            parameter   M_REGS        = 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [LEN_WIDTH-1:0]     s_permit_len,
            input   wire                        s_permit_first,
            input   wire                        s_permit_last,
            input   wire                        s_permit_valid,
            output  wire                        s_permit_ready,
            
            input   wire    [DATA_WIDTH-1:0]    s_data,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [DATA_WIDTH-1:0]    m_data,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    // insert FF
    wire    [LEN_WIDTH-1:0]     ff_s_permit_len;
    wire                        ff_s_permit_first;
    wire                        ff_s_permit_last;
    wire                        ff_s_permit_valid;
    wire                        ff_s_permit_ready;
    
    wire    [DATA_WIDTH-1:0]    ff_s_data;
    wire                        ff_s_valid;
    wire                        ff_s_ready;
    
    wire                        ff_m_first;
    wire                        ff_m_last;
    wire    [DATA_WIDTH-1:0]    ff_m_data;
    wire                        ff_m_valid;
    wire                        ff_m_ready;
    
    jelly_data_ff
            #(
                .DATA_WIDTH     (LEN_WIDTH + 2),
                .S_REGS         (S_PERMIT_REGS),
                .M_REGS         (0)
            )
        i_data_ff_s_permit
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         ({s_permit_len, s_permit_first, s_permit_last}),
                .s_valid        (s_permit_valid),
                .s_ready        (s_permit_ready),
                
                .m_data         ({ff_s_permit_len, ff_s_permit_first, ff_s_permit_last}),
                .m_valid        (ff_s_permit_valid),
                .m_ready        (ff_s_permit_ready)
            );
    
    jelly_data_ff
            #(
                .DATA_WIDTH     (DATA_WIDTH),
                .S_REGS         (S_REGS),
                .M_REGS         (0)
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
    
    
    jelly_pipeline_insert_ff
            #(
                .DATA_WIDTH     (2+DATA_WIDTH),
                .SLAVE_REGS     (0),
                .MASTER_REGS    (M_REGS)
            )
        i_data_ff_m
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         ({ff_m_first, ff_m_last, ff_m_data}),
                .s_valid        (ff_m_valid),
                .s_ready        (ff_m_ready),
                
                .m_data         ({m_first, m_last, m_data}),
                .m_valid        (m_valid),
                .m_ready        (m_ready)
            );
    
    
    
    // core
    reg                             reg_busy;
    reg     [LEN_WIDTH-1:0]         reg_len;
    reg                             reg_end;
    reg                             reg_first;
    reg                             reg_last;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_busy  <= 1'b0;
            reg_len   <= {LEN_WIDTH{1'bx}};
            reg_end   <= 1'bx;
            reg_first <= 1'bx;
            reg_last  <= 1'bx;
        end
        else if ( cke ) begin
            if ( ff_s_permit_valid & ff_s_permit_ready ) begin
                reg_busy  <= 1'b1;
                reg_len   <= ff_s_permit_len - (1'b1 - LEN_OFFSET);
                reg_end   <= (ff_s_permit_len == (1'b1 - LEN_OFFSET));
                reg_first <= ff_s_permit_first;
                reg_last  <= ff_s_permit_last;
            end
            else begin
                if ( ff_m_ready && ff_m_valid ) begin
                    reg_first <= 1'b0;
                    if ( reg_end ) begin
                        reg_busy  <= 1'b0;
                        reg_len   <= {LEN_WIDTH{1'bx}};
                        reg_end   <= 1'bx;
                        reg_first <= 1'bx;
                        reg_last  <= 1'bx;
                    end
                    else begin
                        reg_len   <= reg_len - 1'b1;
                        reg_end   <= (reg_len == 1);
                    end
                end
            end
        end
    end
    
    assign ff_s_permit_ready = !reg_busy || (ff_m_valid & ff_m_ready & reg_end);
    
    assign ff_s_ready  = ff_m_ready  & reg_busy;
    
    assign ff_m_first  = reg_first;
    assign ff_m_last   = reg_last & reg_end;
    assign ff_m_data   = ff_s_data;
    assign ff_m_valid  = ff_s_valid & reg_busy;
    
    
endmodule


`default_nettype wire


// end of file
