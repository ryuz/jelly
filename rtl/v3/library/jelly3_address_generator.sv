// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// アドレスを生成する
module jelly3_address_generator
        #(
            parameter   int     ADDR_BITS   = 32,
            parameter   type    addr_t      = logic [ADDR_BITS-1:0],
            parameter   int     ADDR_UNIT   = 1,
            parameter   int     SIZE_BITS   = 32,
            parameter   type    size_t      = logic [SIZE_BITS-1:0],
            parameter   int     LEN_BITS    = 8,
            parameter   type    len_t       = logic [LEN_BITS-1:0],
            parameter   bit     SIZE_OFFSET = 1'b0,
            parameter   bit     LEN_OFFSET  = 1'b1,
            parameter   bit     S_REG       = 1'b1
        )
        (
            input   var logic                   reset,
            input   var logic                   clk,
            input   var logic                   cke,
            
            input   var addr_t                  s_addr,
            input   var size_t                  s_size,
            input   var len_t                   s_max_len,
            input   var logic                   s_valid,
            output  var logic                   s_ready,
            
            output  var addr_t                  m_addr,
            output  var len_t                   m_len,
            output  var logic                   m_last,
            output  var logic                   m_valid,
            input   var logic                   m_ready
        );
    
    
    //  insert FF
    typedef struct packed {
        addr_t  addr;
        size_t  size;
        len_t   max_len;
    } cmd_t;
    
    addr_t                      ff_s_addr;
    size_t                      ff_s_size;
    len_t                       ff_s_max_len;
    logic                       ff_s_valid;
    logic                       ff_s_ready;
    
    jelly3_stream_ff
            #(
                .data_t     (cmd_t),
                .S_REG      (S_REG),
                .M_REG      (0)
            )
        u_stream_ff
            (
                .reset              (reset),
                .clk                (clk),
                .cke                (cke),
                
                .s_data             ('{
                                        s_addr,
                                        s_size,
                                        s_max_len
                                    }),
                .s_valid            (s_valid),
                .s_ready            (s_ready),
                
                .m_data             ('{
                                        ff_s_addr,
                                        ff_s_size,
                                        ff_s_max_len
                                    }),
                .m_valid            (ff_s_valid),
                .m_ready            (ff_s_ready)
            );
    
    
    
    // stage0
    addr_t                      st0_addr_base;
    len_t                       st0_max_len;
    size_t                      st0_addr;
    size_t                      st0_size;
    logic                       st0_valid;
    logic                       st0_ready;
    
    logic                       st0_last;
    assign st0_last = size_t'({1'b0, st0_size}) + size_t'(SIZE_OFFSET) <= size_t'({1'b0, st0_max_len}) + size_t'(LEN_OFFSET);
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st0_addr_base <= {ADDR_BITS{1'bx}};
            st0_max_len   <= {LEN_BITS{1'bx}};
            st0_addr      <= {SIZE_BITS{1'bx}};
            st0_size      <= {SIZE_BITS{1'bx}};
            st0_valid     <= 1'b0;
        end
        else if ( cke ) begin
            if ( !st0_valid || st0_ready ) begin
                if ( !st0_valid ) begin
                    st0_addr_base <= ff_s_addr;
                    st0_size      <= ff_s_size;
                    st0_max_len   <= ff_s_max_len;
                    st0_addr      <= {SIZE_BITS{1'b0}};
                    st0_valid     <= ff_s_valid;
                end
                else begin
                    st0_addr      <= st0_addr + (size_t'(st0_max_len) + size_t'(LEN_OFFSET)) * size_t'(ADDR_UNIT);
                    st0_size      <= st0_size - size_t'(st0_max_len) - size_t'(LEN_OFFSET);
                    st0_valid     <= !st0_last;
                end
            end
        end
    end
    
    assign ff_s_ready = (!st0_valid || st0_ready) && !st0_valid;
    
    
    // stage1
    addr_t                      st1_addr;
    len_t                       st1_len;
    logic                       st1_last;
    logic                       st1_valid;
    logic                       st1_ready;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            st1_addr   <= {ADDR_BITS{1'bx}};
            st1_len    <= {LEN_BITS{1'bx}};
            st1_last   <= 1'bx;
            st1_valid  <= 1'b0;
        end
        else if ( cke ) begin
            if ( st1_ready ) begin
                st1_addr   <= {ADDR_BITS{1'bx}};
                st1_len    <= {LEN_BITS{1'bx}};
                st1_last   <= 1'bx;
                st1_valid  <= 1'b0;
            end
            if ( st0_valid && st0_ready ) begin
                st1_addr  <= st0_addr_base + addr_t'(st0_addr);
                st1_len   <= st0_last ? len_t'(st0_size + size_t'(SIZE_OFFSET) - size_t'(LEN_OFFSET)) : st0_max_len;
                st1_last  <= st0_last;
                st1_valid <= 1'b1;
            end
        end
    end
    
    assign st0_ready = (!st1_valid || st1_ready);
    
    
    
    // master
    assign m_addr    = st1_addr;
    assign m_len     = st1_len;
    assign m_last    = st1_last;
    assign m_valid   = st1_valid;
    
    assign st1_ready = m_ready;
    
    
endmodule


`default_nettype wire


// end of file