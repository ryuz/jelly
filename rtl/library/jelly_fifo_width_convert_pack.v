// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_fifo_width_convert_pack
        #(
            parameter ASYNC               = 1,
            parameter FIFO_PTR_WIDTH      = 9,
            parameter FIFO_RAM_TYPE       = "block",
            parameter FIFO_LOW_DEALY      = 0,
            parameter FIFO_DOUT_REGS      = 1,
            parameter FIFO_S_REGS         = 1,
            parameter FIFO_M_REGS         = 1,
            
            parameter NUM_GCD             = 1, // S_NUM と M_NUM の最大公約数(人力)
            parameter S_NUM               = 1,
            parameter M_NUM               = 1,
            parameter UNIT0_WIDTH         = 32,
            parameter UNIT1_WIDTH         = 0,
            parameter UNIT2_WIDTH         = 0,
            parameter UNIT3_WIDTH         = 0,
            parameter UNIT4_WIDTH         = 0,
            parameter UNIT5_WIDTH         = 0,
            parameter S_DATA0_WIDTH       = S_NUM * UNIT0_WIDTH,
            parameter S_DATA1_WIDTH       = S_NUM * UNIT1_WIDTH,
            parameter S_DATA2_WIDTH       = S_NUM * UNIT2_WIDTH,
            parameter S_DATA3_WIDTH       = S_NUM * UNIT3_WIDTH,
            parameter S_DATA4_WIDTH       = S_NUM * UNIT4_WIDTH,
            parameter S_DATA5_WIDTH       = S_NUM * UNIT5_WIDTH,
            parameter M_DATA0_WIDTH       = M_NUM * UNIT0_WIDTH,
            parameter M_DATA1_WIDTH       = M_NUM * UNIT1_WIDTH,
            parameter M_DATA2_WIDTH       = M_NUM * UNIT2_WIDTH,
            parameter M_DATA3_WIDTH       = M_NUM * UNIT3_WIDTH,
            parameter M_DATA4_WIDTH       = M_NUM * UNIT4_WIDTH,
            parameter M_DATA5_WIDTH       = M_NUM * UNIT5_WIDTH,
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
            parameter UNIT0_BITS          = UNIT0_WIDTH   > 0 ? UNIT0_WIDTH   : 1,
            parameter UNIT1_BITS          = UNIT1_WIDTH   > 0 ? UNIT1_WIDTH   : 1,
            parameter UNIT2_BITS          = UNIT2_WIDTH   > 0 ? UNIT2_WIDTH   : 1,
            parameter UNIT3_BITS          = UNIT3_WIDTH   > 0 ? UNIT3_WIDTH   : 1,
            parameter UNIT4_BITS          = UNIT4_WIDTH   > 0 ? UNIT4_WIDTH   : 1,
            parameter UNIT5_BITS          = UNIT5_WIDTH   > 0 ? UNIT5_WIDTH   : 1,
            parameter S_DATA0_BITS        = S_DATA0_WIDTH > 0 ? S_DATA0_WIDTH : 1,
            parameter S_DATA1_BITS        = S_DATA1_WIDTH > 0 ? S_DATA1_WIDTH : 1,
            parameter S_DATA2_BITS        = S_DATA2_WIDTH > 0 ? S_DATA2_WIDTH : 1,
            parameter S_DATA3_BITS        = S_DATA3_WIDTH > 0 ? S_DATA3_WIDTH : 1,
            parameter S_DATA4_BITS        = S_DATA4_WIDTH > 0 ? S_DATA4_WIDTH : 1,
            parameter S_DATA5_BITS        = S_DATA5_WIDTH > 0 ? S_DATA5_WIDTH : 1,
            parameter M_DATA0_BITS        = M_DATA0_WIDTH > 0 ? M_DATA0_WIDTH : 1,
            parameter M_DATA1_BITS        = M_DATA1_WIDTH > 0 ? M_DATA1_WIDTH : 1,
            parameter M_DATA2_BITS        = M_DATA2_WIDTH > 0 ? M_DATA2_WIDTH : 1,
            parameter M_DATA3_BITS        = M_DATA3_WIDTH > 0 ? M_DATA3_WIDTH : 1,
            parameter M_DATA4_BITS        = M_DATA4_WIDTH > 0 ? M_DATA4_WIDTH : 1,
            parameter M_DATA5_BITS        = M_DATA5_WIDTH > 0 ? M_DATA5_WIDTH : 1,
            parameter USER_F_BITS         = USER_F_WIDTH  > 0 ? USER_F_WIDTH  : 1,
            parameter USER_L_BITS         = USER_L_WIDTH  > 0 ? USER_L_WIDTH  : 1
        )
        (
            input   wire                        endian,
            
            input   wire    [UNIT0_BITS-1:0]    padding0,
            input   wire    [UNIT1_BITS-1:0]    padding1,
            input   wire    [UNIT2_BITS-1:0]    padding2,
            input   wire    [UNIT3_BITS-1:0]    padding3,
            input   wire    [UNIT4_BITS-1:0]    padding4,
            input   wire    [UNIT5_BITS-1:0]    padding5,
            
            input   wire                        s_reset,
            input   wire                        s_clk,
            input   wire                        s_first,
            input   wire                        s_last,
            input   wire    [S_DATA0_BITS-1:0]  s_data0,
            input   wire    [S_DATA1_BITS-1:0]  s_data1,
            input   wire    [S_DATA2_BITS-1:0]  s_data2,
            input   wire    [S_DATA3_BITS-1:0]  s_data3,
            input   wire    [S_DATA4_BITS-1:0]  s_data4,
            input   wire    [S_DATA5_BITS-1:0]  s_data5,
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
            output  wire    [M_DATA0_BITS-1:0]  m_data0,
            output  wire    [M_DATA1_BITS-1:0]  m_data1,
            output  wire    [M_DATA2_BITS-1:0]  m_data2,
            output  wire    [M_DATA3_BITS-1:0]  m_data3,
            output  wire    [M_DATA4_BITS-1:0]  m_data4,
            output  wire    [M_DATA5_BITS-1:0]  m_data5,
            output  wire    [USER_F_BITS-1:0]   m_user_f,
            output  wire    [USER_L_BITS-1:0]   m_user_l,
            output  wire                        m_valid,
            input   wire                        m_ready,
            output  wire    [FIFO_PTR_WIDTH:0]  m_fifo_data_count,
            output  wire                        m_fifo_rd_signal
        );
    
    
    generate
    if ( POST_CONVERT ) begin : post_convert
        // FIFO
        wire                        fifo_first;
        wire                        fifo_last;
        wire    [S_DATA0_BITS-1:0]  fifo_data0;
        wire    [S_DATA1_BITS-1:0]  fifo_data1;
        wire    [S_DATA2_BITS-1:0]  fifo_data2;
        wire    [S_DATA3_BITS-1:0]  fifo_data3;
        wire    [S_DATA4_BITS-1:0]  fifo_data4;
        wire    [S_DATA5_BITS-1:0]  fifo_data5;
        wire    [USER_F_BITS-1:0]   fifo_user_f;
        wire    [USER_L_BITS-1:0]   fifo_user_l;
        wire                        fifo_valid;
        wire                        fifo_ready;
        jelly_fifo_pack
                #(
                    .ASYNC                  (ASYNC),
                    .DATA0_WIDTH            (S_DATA0_WIDTH),
                    .DATA1_WIDTH            (S_DATA1_WIDTH),
                    .DATA2_WIDTH            (S_DATA2_WIDTH),
                    .DATA3_WIDTH            (S_DATA3_WIDTH),
                    .DATA4_WIDTH            (S_DATA4_WIDTH),
                    .DATA5_WIDTH            (S_DATA5_WIDTH),
                    .DATA6_WIDTH            (USER_F_WIDTH),
                    .DATA7_WIDTH            (USER_L_WIDTH),
                    .DATA8_WIDTH            (HAS_FIRST ? 1 : 0),
                    .DATA9_WIDTH            (HAS_LAST  ? 1 : 0),
                    .PTR_WIDTH              (FIFO_PTR_WIDTH),
                    .DOUT_REGS              (FIFO_DOUT_REGS),
                    .RAM_TYPE               (FIFO_RAM_TYPE),
                    .LOW_DEALY              (FIFO_LOW_DEALY),
                    .S_REGS                 (FIFO_S_REGS),
                    .M_REGS                 (FIFO_M_REGS)
                )
            i_fifo_pack
                (
                    .s_reset                (s_reset),
                    .s_clk                  (s_clk),
                    .s_data0                (s_data0),
                    .s_data1                (s_data1),
                    .s_data2                (s_data2),
                    .s_data3                (s_data3),
                    .s_data4                (s_data4),
                    .s_data5                (s_data5),
                    .s_data6                (s_user_f),
                    .s_data7                (s_user_l),
                    .s_data8                (s_first),
                    .s_data9                (s_last),
                    .s_valid                (s_valid),
                    .s_ready                (s_ready),
                    .s_free_count           (s_fifo_free_count),
                    
                    .m_reset                (m_reset),
                    .m_clk                  (m_clk),
                    .m_data0                (fifo_data0),
                    .m_data1                (fifo_data1),
                    .m_data2                (fifo_data2),
                    .m_data3                (fifo_data3),
                    .m_data4                (fifo_data4),
                    .m_data5                (fifo_data5),
                    .m_data6                (fifo_user_f),
                    .m_data7                (fifo_user_l),
                    .m_data8                (fifo_first),
                    .m_data9                (fifo_last),
                    .m_valid                (fifo_valid),
                    .m_ready                (fifo_ready),
                    .m_data_count           (m_fifo_data_count)
                );
        
        // convert
        jelly_data_width_convert_pack
                #(
                    .NUM_GCD                (NUM_GCD),
                    .S_NUM                  (S_NUM),
                    .M_NUM                  (M_NUM),
                    .UNIT0_WIDTH            (UNIT0_WIDTH),
                    .UNIT1_WIDTH            (UNIT1_WIDTH),
                    .UNIT2_WIDTH            (UNIT2_WIDTH),
                    .UNIT3_WIDTH            (UNIT3_WIDTH),
                    .UNIT4_WIDTH            (UNIT4_WIDTH),
                    .UNIT5_WIDTH            (UNIT5_WIDTH),
                    .S_DATA0_WIDTH          (S_DATA0_WIDTH),
                    .S_DATA1_WIDTH          (S_DATA1_WIDTH),
                    .S_DATA2_WIDTH          (S_DATA2_WIDTH),
                    .S_DATA3_WIDTH          (S_DATA3_WIDTH),
                    .S_DATA4_WIDTH          (S_DATA4_WIDTH),
                    .S_DATA5_WIDTH          (S_DATA5_WIDTH),
                    .M_DATA0_WIDTH          (M_DATA0_WIDTH),
                    .M_DATA1_WIDTH          (M_DATA1_WIDTH),
                    .M_DATA2_WIDTH          (M_DATA2_WIDTH),
                    .M_DATA3_WIDTH          (M_DATA3_WIDTH),
                    .M_DATA4_WIDTH          (M_DATA4_WIDTH),
                    .M_DATA5_WIDTH          (M_DATA5_WIDTH),
                    .USER_F_WIDTH           (USER_F_WIDTH),
                    .USER_L_WIDTH           (USER_L_WIDTH),
                    .ALLOW_UNALIGN_FIRST    (ALLOW_UNALIGN_FIRST),
                    .ALLOW_UNALIGN_LAST     (ALLOW_UNALIGN_LAST),
                    .FIRST_FORCE_LAST       (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE        (FIRST_OVERWRITE),
                    .S_REGS                 (CONVERT_S_REGS)
                )
            i_data_width_convert_pack
                (
                    .reset                  (m_reset),
                    .clk                    (m_clk),
                    .cke                    (1'b1),
                    
                    .endian                 (endian),
                    
                    .padding0               (padding0),
                    .padding1               (padding1),
                    .padding2               (padding2),
                    .padding3               (padding3),
                    .padding4               (padding4),
                    .padding5               (padding5),
                    
                    .s_first                (HAS_FIRST ? fifo_first : 1'b0),
                    .s_last                 (HAS_LAST  ? fifo_last  : 1'b0),
                    .s_data0                (fifo_data0),
                    .s_data1                (fifo_data1),
                    .s_data2                (fifo_data2),
                    .s_data3                (fifo_data3),
                    .s_data4                (fifo_data4),
                    .s_data5                (fifo_data5),
                    .s_user_f               (fifo_user_f),
                    .s_user_l               (fifo_user_l),
                    .s_valid                (fifo_valid),
                    .s_ready                (fifo_ready),
                    
                    .m_first                (m_first),
                    .m_last                 (m_last),
                    .m_data0                (m_data0),
                    .m_data1                (m_data1),
                    .m_data2                (m_data2),
                    .m_data3                (m_data3),
                    .m_data4                (m_data4),
                    .m_data5                (m_data5),
                    .m_user_f               (m_user_f),
                    .m_user_l               (m_user_l),
                    .m_valid                (m_valid),
                    .m_ready                (m_ready)
                );
        
        assign s_fifo_wr_signal = (s_valid   & s_ready);
        assign m_fifo_rd_signal = (fifo_valid & fifo_ready);
    end
    else begin : pre_convert
        // convert
        wire                        conv_first;
        wire                        conv_last;
        wire    [M_DATA0_BITS-1:0]  conv_data0;
        wire    [M_DATA1_BITS-1:0]  conv_data1;
        wire    [M_DATA2_BITS-1:0]  conv_data2;
        wire    [M_DATA3_BITS-1:0]  conv_data3;
        wire    [M_DATA4_BITS-1:0]  conv_data4;
        wire    [M_DATA5_BITS-1:0]  conv_data5;
        wire    [USER_F_BITS-1:0]   conv_user_f;
        wire    [USER_L_BITS-1:0]   conv_user_l;
        wire                        conv_valid;
        wire                        conv_ready;
        jelly_data_width_convert_pack
                #(
                    .NUM_GCD                (NUM_GCD),
                    .S_NUM                  (S_NUM),
                    .M_NUM                  (M_NUM),
                    .UNIT0_WIDTH            (UNIT0_WIDTH),
                    .UNIT1_WIDTH            (UNIT1_WIDTH),
                    .UNIT2_WIDTH            (UNIT2_WIDTH),
                    .UNIT3_WIDTH            (UNIT3_WIDTH),
                    .UNIT4_WIDTH            (UNIT4_WIDTH),
                    .UNIT5_WIDTH            (UNIT5_WIDTH),
                    .S_DATA0_WIDTH          (S_DATA0_WIDTH),
                    .S_DATA1_WIDTH          (S_DATA1_WIDTH),
                    .S_DATA2_WIDTH          (S_DATA2_WIDTH),
                    .S_DATA3_WIDTH          (S_DATA3_WIDTH),
                    .S_DATA4_WIDTH          (S_DATA4_WIDTH),
                    .S_DATA5_WIDTH          (S_DATA5_WIDTH),
                    .M_DATA0_WIDTH          (M_DATA0_WIDTH),
                    .M_DATA1_WIDTH          (M_DATA1_WIDTH),
                    .M_DATA2_WIDTH          (M_DATA2_WIDTH),
                    .M_DATA3_WIDTH          (M_DATA3_WIDTH),
                    .M_DATA4_WIDTH          (M_DATA4_WIDTH),
                    .M_DATA5_WIDTH          (M_DATA5_WIDTH),
                    .USER_F_WIDTH           (USER_F_WIDTH),
                    .USER_L_WIDTH           (USER_L_WIDTH),
                    .ALLOW_UNALIGN_FIRST    (ALLOW_UNALIGN_FIRST),
                    .ALLOW_UNALIGN_LAST     (ALLOW_UNALIGN_LAST),
                    .FIRST_FORCE_LAST       (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE        (FIRST_OVERWRITE),
                    .S_REGS                 (CONVERT_S_REGS)
                )
            i_data_width_convert_pack
                (
                    .reset                  (s_reset),
                    .clk                    (s_clk),
                    .cke                    (1'b1),
                    
                    .endian                 (endian),
                    
                    .padding0               (padding0),
                    .padding1               (padding1),
                    .padding2               (padding2),
                    .padding3               (padding3),
                    .padding4               (padding4),
                    .padding5               (padding5),
                    
                    .s_first                (HAS_FIRST ? s_first : 1'b0),
                    .s_last                 (HAS_LAST  ? s_last  : 1'b0),
                    .s_data0                (s_data0),
                    .s_data1                (s_data1),
                    .s_data2                (s_data2),
                    .s_data3                (s_data3),
                    .s_data4                (s_data4),
                    .s_data5                (s_data5),
                    .s_user_f               (s_user_f),
                    .s_user_l               (s_user_l),
                    .s_valid                (s_valid),
                    .s_ready                (s_ready),
                    
                    .m_first                (conv_first),
                    .m_last                 (conv_last),
                    .m_data0                (conv_data0),
                    .m_data1                (conv_data1),
                    .m_data2                (conv_data2),
                    .m_data3                (conv_data3),
                    .m_data4                (conv_data4),
                    .m_data5                (conv_data5),
                    .m_user_f               (conv_user_f),
                    .m_user_l               (conv_user_l),
                    .m_valid                (conv_valid),
                    .m_ready                (conv_ready)
                );
        
        // FIFO
        jelly_fifo_pack
                #(
                    .ASYNC                  (ASYNC),
                    .DATA0_WIDTH            (M_DATA0_WIDTH),
                    .DATA1_WIDTH            (M_DATA1_WIDTH),
                    .DATA2_WIDTH            (M_DATA2_WIDTH),
                    .DATA3_WIDTH            (M_DATA3_WIDTH),
                    .DATA4_WIDTH            (M_DATA4_WIDTH),
                    .DATA5_WIDTH            (M_DATA5_WIDTH),
                    .DATA6_WIDTH            (USER_F_WIDTH),
                    .DATA7_WIDTH            (USER_L_WIDTH),
                    .DATA8_WIDTH            (HAS_FIRST ? 1 : 0),
                    .DATA9_WIDTH            (HAS_LAST  ? 1 : 0),
                    .PTR_WIDTH              (FIFO_PTR_WIDTH),
                    .DOUT_REGS              (FIFO_DOUT_REGS),
                    .RAM_TYPE               (FIFO_RAM_TYPE),
                    .LOW_DEALY              (FIFO_LOW_DEALY),
                    .S_REGS                 (FIFO_S_REGS),
                    .M_REGS                 (FIFO_M_REGS)
                )
            i_fifo_pack
                (
                    .s_reset                (s_reset),
                    .s_clk                  (s_clk),
                    .s_data0                (conv_data0),
                    .s_data1                (conv_data1),
                    .s_data2                (conv_data2),
                    .s_data3                (conv_data3),
                    .s_data4                (conv_data4),
                    .s_data5                (conv_data5),
                    .s_data6                (conv_user_f),
                    .s_data7                (conv_user_l),
                    .s_data8                (conv_first),
                    .s_data9                (conv_last),
                    .s_valid                (conv_valid),
                    .s_ready                (conv_ready),
                    .s_free_count           (s_fifo_free_count),
                    
                    .m_reset                (m_reset),
                    .m_clk                  (m_clk),
                    .m_data0                (m_data0),
                    .m_data1                (m_data1),
                    .m_data2                (m_data2),
                    .m_data3                (m_data3),
                    .m_data4                (m_data4),
                    .m_data5                (m_data5),
                    .m_data6                (m_user_f),
                    .m_data7                (m_user_l),
                    .m_data8                (m_first),
                    .m_data9                (m_last),
                    .m_valid                (m_valid),
                    .m_ready                (m_ready),
                    .m_data_count           (m_fifo_data_count)
                );
        
        assign s_fifo_wr_signal = (conv_valid & conv_ready);
        assign m_fifo_rd_signal = (m_valid    & m_ready);
    end
    endgenerate
    
endmodule


`default_nettype wire


// end of file
