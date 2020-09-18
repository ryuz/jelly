// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// 境界を合わせて許可された個数だけデータを通す
module jelly_data_gate_sync
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
            
            input   wire                        skip,           // 非busy時に読み飛ばす
            input   wire                        detect_first,
            input   wire                        detect_last,
            input   wire                        padding_en,
            input   wire    [DATA_WIDTH-1:0]    padding_data,
            input   wire                        padding_skip,   // パディング中に読み飛ばす
            
            input   wire    [LEN_WIDTH-1:0]     s_permit_len,
            input   wire                        s_permit_valid,
            output  wire                        s_permit_ready,
            
            input   wire                        s_first,
            input   wire                        s_last,
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
    wire                        ff_s_permit_valid;
    wire                        ff_s_permit_ready;
    
    wire                        ff_s_first;
    wire                        ff_s_last;
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
                .DATA_WIDTH     (LEN_WIDTH),
                .S_REGS         (S_PERMIT_REGS),
                .M_REGS         (0)
            )
        i_data_ff_s_permit
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         (s_permit_len),
                .s_valid        (s_permit_valid),
                .s_ready        (s_permit_ready),
                
                .m_data         (ff_s_permit_len),
                .m_valid        (ff_s_permit_valid),
                .m_ready        (ff_s_permit_ready)
            );
    
    jelly_data_ff
            #(
                .DATA_WIDTH     (2+DATA_WIDTH),
                .S_REGS         (S_REGS),
                .M_REGS         (0)
            )
        i_data_ff_s
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data         ({s_first, s_last, s_data}),
                .s_valid        (s_valid),
                .s_ready        (s_ready),
                
                .m_data         ({ff_s_first, ff_s_last, ff_s_data}),
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
    reg                     reg_busy;
    reg     [LEN_WIDTH-1:0] reg_len;
    reg                     reg_start;
    reg                     reg_end;
    reg                     reg_padding;
    reg                     reg_first;
    
    wire                    sig_first   = (detect_first & ff_s_valid & ff_s_first)
                                       || (detect_last  & ff_s_valid & reg_first)
                                       || (!detect_first && !detect_last && ff_s_valid);
    
    wire                    sig_padding = padding_en && (reg_padding || (sig_first && !reg_start));
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_first   <= 1'b1;
            
            reg_busy    <= 1'b0;
            reg_len     <= {LEN_WIDTH{1'bx}};
            reg_start   <= 1'b0;
            reg_end     <= 1'b0;
            reg_padding <= 1'b0;
        end
        else if ( cke ) begin
            // ストリーム先頭検出
            if ( ff_s_valid && ff_s_ready ) begin
                reg_first <= ff_s_last;
            end
            
            // 動作制御
            if ( ff_s_permit_valid & ff_s_permit_ready ) begin
                reg_busy  <= 1'b1;
                reg_len   <= ff_s_permit_len - (1'b1 - LEN_OFFSET);
                reg_start <= 1'b1;
                reg_end   <= (ff_s_permit_len == (1'b1 - LEN_OFFSET));
            end
            else begin
                if ( ff_m_ready && ff_m_valid ) begin
                    if ( reg_end ) begin
                        reg_busy    <= 1'b0;
                        reg_len     <= {LEN_WIDTH{1'bx}};
                        reg_start   <= 1'b0;
                        reg_end     <= 1'b0;
                        reg_padding <= 1'b0;
                    end
                    else begin
                        reg_len     <= reg_len - 1'b1;
                        reg_start   <= 1'b0;
                        reg_end     <= (reg_len == 1);
                        reg_padding <= sig_padding;
                    end
                end
            end
        end
    end
    
    assign ff_s_permit_ready = !reg_busy || (ff_m_valid & ff_m_ready & reg_end);
    
    assign ff_s_ready        = (reg_busy && (reg_start || (ff_m_ready && !sig_padding) || (padding_skip && sig_padding))) || (!reg_busy && skip);
    
    assign ff_m_first        = reg_start;
    assign ff_m_last         = reg_end;
    assign ff_m_data         = sig_padding ? padding_data : ff_s_data;
    assign ff_m_valid        = reg_busy && ((ff_s_valid & (!reg_start || sig_first)) || sig_padding);
    
    
endmodule


`default_nettype wire


// end of file
