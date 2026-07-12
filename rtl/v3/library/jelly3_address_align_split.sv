// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2026 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


// アライン跨ぎ分割(2回以上跨ぐのは対象外なので事前に上限制御すること)
module jelly3_address_align_split
        #(
            parameter   bit     BYPASS        = 0                       ,
            parameter   int     USER_BITS     = 1                       ,
            parameter   type    user_t        = logic [USER_BITS-1:0]   ,
            parameter   int     ADDR_BITS     = 32                      ,
            parameter   type    addr_t        = logic [ADDR_BITS-1:0]   ,
            parameter   int     UNIT_SIZE     = 3                       ,   // log2 (0:1byte, 1:2byte, 2:4byte, 3:8byte, ...)
            parameter   int     LEN_BITS      = 8                       ,
            parameter   type    len_t         = logic [LEN_BITS-1:0]    ,
            parameter   bit     LEN_OFFSET    = 1'b1                    ,
            parameter   int     ALIGN         = 12                      ,   // 2^n
            parameter   bit     S_REG         = 1                       
        )
        (
            input   var logic       reset   ,
            input   var logic       clk     ,
            input   var logic       cke     ,
            
            input   var logic       s_first ,
            input   var logic       s_last  ,
            input   var addr_t      s_addr  ,
            input   var len_t       s_len   ,
            input   var user_t      s_user  ,
            input   var logic       s_valid ,
            output  var logic       s_ready ,
            
            output  var logic       m_first ,
            output  var logic       m_last  ,
            output  var addr_t      m_addr  ,
            output  var len_t       m_len   ,
            output  var user_t      m_user  ,
            output  var logic       m_valid ,
            input   var logic       m_ready 
        );
    
    localparam  UNIT_ALIGN = ALIGN - UNIT_SIZE;
    
    
    generate
    if ( BYPASS ) begin : blk_bypass
        assign  m_first = s_first;
        assign  m_last  = s_last;
        assign  m_addr  = s_addr;
        assign  m_len   = s_len;
        assign  m_user  = s_user;
        assign  m_valid = s_valid;
        assign  s_ready = m_ready;
    end
    else begin : blk_split
        
        // ---------------------------------
        //  Insert FF
        // ---------------------------------
        
        typedef struct packed {
            logic       first;
            logic       last;
            addr_t      addr;
            len_t       len;
            user_t      user;
        } cmd_t;
        
        logic       ff_s_first;
        logic       ff_s_last;
        addr_t      ff_s_addr;
        len_t       ff_s_len;
        user_t      ff_s_user;
        logic       ff_s_valid;
        logic       ff_s_ready;
        
        jelly3_stream_ff
                #(
                    .data_t     (cmd_t  ),
                    .S_REG      (S_REG  ),
                    .M_REG      (0      )
                )
            u_stream_ff_s
                (
                    .reset      (reset  ),
                    .clk        (clk    ),
                    .cke        (cke    ),
                    .s_data     ('{
                                    s_first,
                                    s_last,
                                    s_addr,
                                    s_len,
                                    s_user
                                }),
                    .s_valid    (s_valid),
                    .s_ready    (s_ready),
                    .m_data     ('{
                                    ff_s_first,
                                    ff_s_last,
                                    ff_s_addr,
                                    ff_s_len,
                                    ff_s_user
                                }),
                    .m_valid    (ff_s_valid),
                    .m_ready    (ff_s_ready)
                );
        
        
        // ---------------------------------
        //  Core
        // ---------------------------------
        
        logic   [UNIT_ALIGN:0]      align_addr;
        logic   [UNIT_ALIGN:0]      unit_addr;
        logic   [UNIT_ALIGN:0]      end_addr;
        logic                       align_over;
        
        assign align_addr = (1 << UNIT_ALIGN);
        assign unit_addr  = (UNIT_ALIGN+1)'(ff_s_addr[ALIGN-1:UNIT_SIZE]);
        assign end_addr   = (UNIT_ALIGN+1)'(({1'b0, unit_addr}) + (UNIT_ALIGN+1)'(ff_s_len) + (UNIT_ALIGN+1)'(LEN_OFFSET) - (UNIT_ALIGN+1)'(1));
        assign align_over = ff_s_valid && end_addr[UNIT_ALIGN];
        
        logic                       reg_split;
        logic                       reg_first;
        logic                       reg_last;
        logic                       reg_lflag;
        user_t                      reg_user;
        addr_t                      reg_addr;
        len_t                       reg_len;
        len_t                       reg_len_base;
        logic                       reg_valid;
        
        always_ff @(posedge clk) begin
            if ( reset ) begin
                reg_split    <= 1'b0;
                reg_first    <= 1'bx;
                reg_last     <= 1'bx;
                reg_lflag    <= 1'bx;
                reg_user     <= {USER_BITS{1'bx}};
                reg_addr     <= {ADDR_BITS{1'bx}};
                reg_len      <= {LEN_BITS{1'bx}};
                reg_len_base <= {LEN_BITS{1'bx}};
                reg_valid    <= 1'b0;
            end
            else if ( cke && (!m_valid || m_ready) ) begin
                reg_valid <= 1'b0;
                if ( !reg_split ) begin
                    reg_first    <= ff_s_first;
                    reg_last     <= ff_s_last;
                    reg_lflag    <= ff_s_last;
                    reg_user     <= ff_s_user;
                    reg_addr     <= ff_s_addr;
                    reg_len      <= ff_s_len;
                    reg_len_base <= ff_s_len;
                    reg_valid    <= ff_s_valid;
                    if ( align_over ) begin
                        reg_split <= 1'b1;
                        reg_last  <= 1'b0;
                        reg_len   <= len_t'(align_addr) - len_t'(unit_addr) - len_t'(LEN_OFFSET);
                    end
                end
                else begin
                    reg_first <= 1'b0;
                    reg_last  <= reg_lflag;
                    reg_split <= 1'b0;
                    reg_addr  <= reg_addr + ((addr_t'(reg_len) + addr_t'(1'b1)) << UNIT_SIZE);
                    reg_len   <= reg_len_base - reg_len - len_t'(LEN_OFFSET);
                    reg_valid <= 1'b1;
                end
            end
        end
        
        assign m_first = reg_first;
        assign m_last  = reg_last;
        assign m_user  = reg_user;
        assign m_addr  = reg_addr;
        assign m_len   = reg_len;
        assign m_valid = reg_valid;
        
        assign ff_s_ready = (!m_valid || m_ready) && ~reg_split;
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
