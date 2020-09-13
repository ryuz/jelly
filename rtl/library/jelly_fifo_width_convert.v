// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_fifo_width_convert
        #(
            parameter ASYNC               = 1,
            parameter FIFO_PTR_WIDTH      = 9,
            parameter FIFO_RAM_TYPE       = "block",
            parameter FIFO_LOW_DEALY      = 0,
            parameter FIFO_DOUT_REGS      = 1,
            parameter FIFO_S_REGS         = 1,
            parameter FIFO_M_REGS         = 1,
            
            parameter NUM_GCD             = 1, // S_NUM と M_NUM の最大公約数(人力)
            parameter UNIT_WIDTH          = 32,
            parameter S_NUM               = 1,
            parameter M_NUM               = 1,
            parameter S_DATA_WIDTH        = S_NUM * UNIT_WIDTH,
            parameter M_DATA_WIDTH        = M_NUM * UNIT_WIDTH,
            parameter USER_F_WIDTH        = 0,
            parameter USER_L_WIDTH        = 0,
            parameter HAS_FIRST           = 0,
            parameter HAS_LAST            = 0,
            parameter ALLOW_UNALIGN_FIRST = 1,
            parameter ALLOW_UNALIGN_LAST  = 1,
            parameter FIRST_FORCE_LAST    = 1,  // firstで前方吐き出し時に残変換があれば強制的にlastを付与
            parameter FIRST_OVERWRITE     = 0,  // first時前方に残変換があれば吐き出さずに上書き
            parameter CONVERT_S_REGS      = 1,
            
            parameter POST_CONVERT        = (M_NUM < S_NUM),
            
            // local
            parameter UNIT_BITS           = UNIT_WIDTH   > 0 ? UNIT_WIDTH   : 1,
            parameter S_DATA_BITS         = S_DATA_WIDTH > 0 ? S_DATA_WIDTH : 1,
            parameter M_DATA_BITS         = M_DATA_WIDTH > 0 ? M_DATA_WIDTH : 1,
            parameter USER_F_BITS         = USER_F_WIDTH > 0 ? USER_F_WIDTH : 1,
            parameter USER_L_BITS         = USER_L_WIDTH > 0 ? USER_L_WIDTH : 1
        )
        (
            input   wire                        reset,
            input   wire                        clk,
            input   wire                        cke,
            
            input   wire                        endian,
            
            input   wire    [UNIT_BITS-1:0]     padding,
            
            input   wire                        s_reset,
            input   wire                        s_clk,
            input   wire                        s_first,
            input   wire                        s_last,
            input   wire    [S_DATA_BITS-1:0]   s_data,
            input   wire    [USER_F_BITS-1:0]   s_user_f,
            input   wire    [USER_L_BITS-1:0]   s_user_l,
            input   wire                        s_valid,
            output  wire                        s_ready,
            output  wire     [FIFO_PTR_WIDTH:0] s_fifo_free_count,
            output  wire                        s_fifo_wr_signal,
            
            input   wire                        m_reset,
            input   wire                        m_clk,
            output  wire                        m_first,
            output  wire                        m_last,
            output  wire    [M_DATA_BITS-1:0]   m_data,
            output  wire    [USER_F_BITS-1:0]   m_user_f,
            output  wire    [USER_L_BITS-1:0]   m_user_l,
            output  wire                        m_valid,
            input   wire                        m_ready,
            output  wire    [FIFO_PTR_WIDTH:0]  m_fifo_data_count,
            output  wire                        m_fifo_rd_signal
        );
    
    jelly_fifo_width_convert_pack
            #(
                .ASYNC                  (ASYNC),
                .FIFO_PTR_WIDTH         (FIFO_PTR_WIDTH),
                .FIFO_RAM_TYPE          (FIFO_RAM_TYPE),
                .FIFO_LOW_DEALY         (FIFO_LOW_DEALY),
                .FIFO_DOUT_REGS         (FIFO_DOUT_REGS),
                .FIFO_S_REGS            (FIFO_S_REGS),
                .FIFO_M_REGS            (FIFO_M_REGS),
                .NUM_GCD                (NUM_GCD),
                .S_NUM                  (S_NUM),
                .M_NUM                  (M_NUM),
                .UNIT0_WIDTH            (UNIT_WIDTH),
                .S_DATA0_WIDTH          (S_DATA_WIDTH),
                .M_DATA0_WIDTH          (M_DATA_WIDTH),
                .USER_F_WIDTH           (USER_F_WIDTH),
                .USER_L_WIDTH           (USER_L_WIDTH),
                .HAS_FIRST              (HAS_FIRST),
                .HAS_LAST               (HAS_LAST),
                .ALLOW_UNALIGN_FIRST    (ALLOW_UNALIGN_FIRST),
                .ALLOW_UNALIGN_LAST     (ALLOW_UNALIGN_LAST),
                .FIRST_FORCE_LAST       (FIRST_FORCE_LAST),
                .FIRST_OVERWRITE        (FIRST_OVERWRITE),
                .CONVERT_S_REGS         (CONVERT_S_REGS),
                .POST_CONVERT           (POST_CONVERT)
            )
        i_fifo_width_convert_pack
            (
                .reset                  (reset),
                .clk                    (clk),
                .cke                    (cke),
                
                .endian                 (endian),
                .padding0               (padding),
                
                .s_reset                (s_reset),
                .s_clk                  (s_clk),
                .s_first                (s_first),
                .s_last                 (s_last),
                .s_data0                (s_data),
                .s_user_f               (s_user_f),
                .s_user_l               (s_user_l),
                .s_valid                (s_valid),
                .s_ready                (s_ready),
                .s_fifo_free_count      (s_fifo_free_count),
                .s_fifo_wr_signal       (s_fifo_wr_signal),
                
                .m_reset                (m_reset),
                .m_clk                  (m_clk),
                .m_first                (m_first),
                .m_last                 (m_last),
                .m_data0                (m_data),
                .m_user_f               (m_user_f),
                .m_user_l               (m_user_l),
                .m_valid                (m_valid),
                .m_ready                (m_ready),
                .m_fifo_data_count      (m_fifo_data_count),
                .m_fifo_rd_signal       (m_fifo_rd_signal)
            );
    
endmodule


`default_nettype wire


// end of file
