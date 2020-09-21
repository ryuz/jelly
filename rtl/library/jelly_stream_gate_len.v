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
            parameter   USER_WIDTH    = 0,
            
            parameter   S_PERMIT_REGS = 1,
            parameter   S_REGS        = 1,
            parameter   M_REGS        = 1,
            
            // local
            parameter   USER_BITS     = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [LEN_WIDTH-1:0]     s_permit_len,
            input   wire                        s_permit_first,
            input   wire                        s_permit_last,
            input   wire    [USER_BITS-1:0]     s_permit_user,
            input   wire                        s_permit_valid,
            output  wire                        s_permit_ready,
            
            input   wire    [DATA_WIDTH-1:0]    s_data,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [DATA_WIDTH-1:0]    m_data,
            output  wire    [USER_BITS-1:0]     m_user,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    // insert FF
    wire    [LEN_WIDTH-1:0]     ff_s_permit_len;
    wire                        ff_s_permit_first;
    wire                        ff_s_permit_last;
    wire    [USER_BITS-1:0]     ff_s_permit_user;
    wire                        ff_s_permit_valid;
    wire                        ff_s_permit_ready;
    
    wire    [DATA_WIDTH-1:0]    ff_s_data;
    wire                        ff_s_valid;
    wire                        ff_s_ready;
    
    wire                        ff_m_first;
    wire                        ff_m_last;
    wire    [DATA_WIDTH-1:0]    ff_m_data;
    wire    [USER_BITS-1:0]     ff_m_user;
    wire                        ff_m_valid;
    wire                        ff_m_ready;
    
    jelly_data_ff_pack
            #(
                .DATA0_WIDTH    (LEN_WIDTH),
                .DATA1_WIDTH    (1),
                .DATA2_WIDTH    (1),
                .DATA3_WIDTH    (USER_WIDTH),
                .S_REGS         (S_PERMIT_REGS),
                .M_REGS         (0)
            )
        i_data_ff_s_permit
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data0        (s_permit_len),
                .s_data1        (s_permit_first),
                .s_data2        (s_permit_last),
                .s_data3        (s_permit_user),
                .s_valid        (s_permit_valid),
                .s_ready        (s_permit_ready),
                
                .m_data0        (ff_s_permit_len),
                .m_data1        (ff_s_permit_first),
                .m_data2        (ff_s_permit_last),
                .m_data3        (ff_s_permit_user),
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
    
    
    jelly_data_ff_pack
            #(
                .DATA0_WIDTH    (1),
                .DATA1_WIDTH    (1),
                .DATA2_WIDTH    (DATA_WIDTH),
                .DATA3_WIDTH    (USER_WIDTH),
                .S_REGS         (0),
                .M_REGS         (M_REGS)
            )
        i_data_ff_m
            (
                .reset          (reset),
                .clk            (clk),
                .cke            (cke),
                
                .s_data0        (ff_m_first),
                .s_data1        (ff_m_last),
                .s_data2        (ff_m_data),
                .s_data3        (ff_m_user),
                .s_valid        (ff_m_valid),
                .s_ready        (ff_m_ready),
                
                .m_data0        (m_first),
                .m_data1        (m_last),
                .m_data2        (m_data),
                .m_data3        (m_user),
                .m_valid        (m_valid),
                .m_ready        (m_ready)
            );
    
    
    
    // core
    reg                             reg_busy;
    reg     [LEN_WIDTH-1:0]         reg_len;
    reg                             reg_end;
    reg                             reg_first;
    reg                             reg_last;
    reg     [USER_BITS-1:0]         reg_user;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_busy  <= 1'b0;
            reg_len   <= {LEN_WIDTH{1'bx}};
            reg_end   <= 1'bx;
            reg_first <= 1'bx;
            reg_last  <= 1'bx;
            reg_user  <= {USER_BITS{1'bx}};
        end
        else if ( cke ) begin
            if ( ff_s_permit_valid & ff_s_permit_ready ) begin
                reg_busy  <= 1'b1;
                reg_len   <= ff_s_permit_len - (1'b1 - LEN_OFFSET);
                reg_end   <= (ff_s_permit_len == (1'b1 - LEN_OFFSET));
                reg_first <= ff_s_permit_first;
                reg_last  <= ff_s_permit_last;
                reg_user  <= ff_s_permit_user;
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
    assign ff_m_user   = reg_user;
    assign ff_m_valid  = ff_s_valid & reg_busy;
    
    
endmodule


`default_nettype wire


// end of file
