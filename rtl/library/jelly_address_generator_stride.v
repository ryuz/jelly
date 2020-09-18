// ---------------------------------------------------------------------------
//  Jelly  -- The FPGA processing system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// stride幅でのアドレスを生成する
module jelly_address_generator_stride
        #(
            parameter   ADDR_WIDTH   = 32,
            parameter   STRIDE_WIDTH = ADDR_WIDTH,
            parameter   LEN_WIDTH    = 32,
            parameter   COUNT_WIDTH  = 32,
            parameter   USER_WIDTH   = 0,
            parameter   COUNT_OFFSET = 1'b1,
            
            // loacal
            parameter   USER_BITS    = USER_WIDTH > 0 ? USER_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire    [ADDR_WIDTH-1:0]    s_addr,
            input   wire    [STRIDE_WIDTH-1:0]  s_stride,
            input   wire    [LEN_WIDTH-1:0]     s_len,
            input   wire    [COUNT_WIDTH-1:0]   s_count,
            input   wire    [USER_BITS-1:0]     s_user,
            input   wire                        s_valid,
            output  wire                        s_ready,
            
            output  wire    [ADDR_WIDTH-1:0]    m_addr,
            output  wire    [LEN_WIDTH-1:0]     m_len,
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [USER_BITS-1:0]     m_user,
            output  wire                        m_valid,
            input   wire                        m_ready
        );
    
    
    reg     [ADDR_WIDTH-1:0]        reg_addr;
    reg     [STRIDE_WIDTH-1:0]      reg_stride;
    reg     [LEN_WIDTH-1:0]         reg_len;
    reg     [COUNT_WIDTH-1:0]       reg_count;
    reg     [USER_BITS-1:0]         reg_user;
    reg                             reg_first;
    reg                             reg_last;
    reg                             reg_valid;
    
    always @(posedge clk) begin
        if ( reset ) begin
            reg_addr      <= {ADDR_WIDTH{1'bx}};
            reg_stride    <= {STRIDE_WIDTH{1'bx}};
            reg_len       <= {LEN_WIDTH{1'bx}};
            reg_count     <= {COUNT_WIDTH{1'bx}};
            reg_user      <= {USER_BITS{1'bx}};
            reg_first     <= 1'bx;
            reg_last      <= 1'bx;
            reg_valid     <= 1'b0;
        end
        else if ( cke ) begin
            if ( !reg_valid ) begin
                reg_addr   <= s_addr;
                reg_stride <= s_stride;
                reg_len    <= s_len;
                reg_user   <= s_user;
                reg_first  <= 1'b1;
                reg_last   <= (s_count == (1'b1 - COUNT_OFFSET));
                reg_count  <= s_count + (COUNT_OFFSET - 1'b1);
                reg_valid  <= (s_count >= (1'b1 - COUNT_OFFSET));
            end
            else if ( m_ready ) begin
                if ( reg_last ) begin
                    reg_addr      <= {ADDR_WIDTH{1'bx}};
                    reg_stride    <= {STRIDE_WIDTH{1'bx}};
                    reg_len       <= {LEN_WIDTH{1'bx}};
                    reg_count     <= {COUNT_WIDTH{1'bx}};
                    reg_user      <= {USER_BITS{1'bx}};
                    reg_first     <= 1'bx;
                    reg_last      <= 1'bx;
                    reg_valid     <= 1'b0;
                end
                else begin
                    reg_addr  <= reg_addr  + reg_stride;
                    reg_count <= reg_count - 1'b1;
                    reg_first <= 1'b0;
                    reg_last  <= (reg_count == 1);
                end
            end
        end
    end
    
    assign s_ready  = ~reg_valid;
    
    assign m_addr   = reg_addr;
    assign m_len    = reg_len;
    assign m_first  = reg_first;
    assign m_last   = reg_last;
    assign m_user   = reg_user;
    assign m_valid  = reg_valid;
    
endmodule


`default_nettype wire


// end of file
