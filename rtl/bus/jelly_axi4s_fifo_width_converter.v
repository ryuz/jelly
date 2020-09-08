// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_axi4s_fifo_width_converter
        #(
            parameter   ASYNC            = 1,
            parameter   UNIT_WIDTH       = 8,
            parameter   BYTE_WIDTH       = 8,
            parameter   S_DATA_WIDTH     = 8,
            parameter   M_DATA_WIDTH     = 32,
            parameter   USER_UNIT        = 1,
            parameter   S_USER_WIDTH     = 0,
            
            parameter   WITH_FIRST       = 1,
            parameter   WITH_LAST        = 1,
            parameter   WITH_STRB        = 1,
            parameter   WITH_KEEP        = 1,
            
            parameter   FIRST_FORCE_LAST = 1,  // firstで前方吐き出し時に残変換があれば強制的にlastを付与
            parameter   FIRST_OVERWRITE  = 0,  // first時前方に残変換があれば吐き出さずに上書き
            
            parameter   S_REGS           = 1,
            
            parameter   FIFO_PTR_WIDTH   = 9,
            parameter   FIFO_RAM_TYPE    = "block",
            parameter   FIFO_LOW_DEALY   = 0,
            parameter   FIFO_DOUT_REGS   = 1,
            parameter   FIFO_SLAVE_REGS  = 1,
            parameter   FIFO_MASTER_REGS = 1,
            
            // local
            parameter   STRB_UNIT        = UNIT_WIDTH / BYTE_WIDTH,
            parameter   KEEP_UNIT        = UNIT_WIDTH / BYTE_WIDTH,
            parameter   S_USER_BITS      = S_USER_WIDTH > 0 ? S_USER_WIDTH : 1,
            parameter   S_STRB_WIDTH     = S_DATA_WIDTH / BYTE_WIDTH,
            parameter   S_KEEP_WIDTH     = S_DATA_WIDTH / BYTE_WIDTH,
            parameter   M_USER_WIDTH     = S_USER_WIDTH * M_DATA_WIDTH / S_DATA_WIDTH,
            parameter   M_USER_BITS      = M_USER_WIDTH > 0 ? M_USER_WIDTH : 1,
            parameter   M_STRB_WIDTH     = M_DATA_WIDTH / BYTE_WIDTH,
            parameter   M_KEEP_WIDTH     = M_DATA_WIDTH / BYTE_WIDTH
        )
        (
            input   wire                        endian,
            
            input   wire                        s_aresetn,
            input   wire                        s_aclk,
            input   wire    [S_USER_BITS-1:0]   s_axi4s_tuser,
            input   wire                        s_axi4s_tfirst,
            input   wire                        s_axi4s_tlast,
            input   wire    [S_STRB_WIDTH-1:0]  s_axi4s_tkeep,
            input   wire    [S_STRB_WIDTH-1:0]  s_axi4s_tstrb,
            input   wire    [S_DATA_WIDTH-1:0]  s_axi4s_tdata,
            input   wire                        s_axi4s_tvalid,
            output  wire                        s_axi4s_tready,
            output  wire    [FIFO_PTR_WIDTH:0]  s_fifo_free_count,
            output  wire                        s_fifo_wr_signal,
            
            
            input   wire                        m_aresetn,
            input   wire                        m_aclk,
            output  wire    [S_USER_BITS-1:0]   m_axi4s_tuser,
            output  wire                        m_axi4s_tfirst,
            output  wire                        m_axi4s_tlast,
            output  wire    [S_STRB_WIDTH-1:0]  m_axi4s_tkeep,
            output  wire    [S_STRB_WIDTH-1:0]  m_axi4s_tstrb,
            output  wire    [M_DATA_WIDTH-1:0]  m_axi4s_tdata,
            output  wire                        m_axi4s_tvalid,
            input   wire                        m_axi4s_tready,
            output  wire    [FIFO_PTR_WIDTH:0]  m_fifo_data_count,
            output  wire                        m_fifo_rd_signal
        );
    
    localparam PACK_FIRST_WIDTH  = WITH_FIRST ?            1 : 0;
    localparam PACK_LAST_WIDTH   = WITH_LAST  ?            1 : 0;
    localparam PACK_S_STRB_WIDTH = WITH_STRB  ? S_STRB_WIDTH : 0;
    localparam PACK_S_KEEP_WIDTH = WITH_KEEP  ? S_KEEP_WIDTH : 0;
    localparam PACK_M_STRB_WIDTH = WITH_STRB  ? M_STRB_WIDTH : 0;
    localparam PACK_M_KEEP_WIDTH = WITH_STRB  ? M_KEEP_WIDTH : 0;
    
    localparam S_PACK_WIDTH = S_USER_WIDTH + PACK_FIRST_WIDTH + PACK_LAST_WIDTH + PACK_S_STRB_WIDTH + PACK_S_KEEP_WIDTH + S_DATA_WIDTH;
    localparam M_PACK_WIDTH = M_USER_WIDTH + PACK_FIRST_WIDTH + PACK_LAST_WIDTH + PACK_M_STRB_WIDTH + PACK_M_KEEP_WIDTH + M_DATA_WIDTH;
    
    
    generate
    if ( M_DATA_WIDTH < S_DATA_WIDTH ) begin : blk_cnv_narrow
        
        // pack -> FIFO -> unpack
        wire    [S_PACK_WIDTH-1:0]      s_axi4s_tpack;
        
        wire    [S_PACK_WIDTH-1:0]      fifo_tpack;
        wire    [S_USER_BITS-1:0]       fifo_tuser;
        wire                            fifo_tfirst;
        wire                            fifo_tlast;
        wire    [S_STRB_WIDTH-1:0]      fifo_tkeep;
        wire    [S_STRB_WIDTH-1:0]      fifo_tstrb;
        wire    [S_DATA_WIDTH-1:0]      fifo_tdata;
        wire                            fifo_tvalid;
        wire                            fifo_tready;
        
        jelly_func_pack
                #(
                    .N                  (1),
                    .W0                 (S_USER_WIDTH),
                    .W1                 (PACK_FIRST_WIDTH),
                    .W2                 (PACK_LAST_WIDTH),
                    .W3                 (PACK_S_STRB_WIDTH),
                    .W4                 (PACK_S_KEEP_WIDTH),
                    .W5                 (S_DATA_WIDTH)
                )
            i_func_pack
                (
                    .in0                (s_axi4s_tuser),
                    .in1                (s_axi4s_tfirst),
                    .in2                (s_axi4s_tlast),
                    .in3                (s_axi4s_tkeep),
                    .in4                (s_axi4s_tstrb),
                    .in5                (s_axi4s_tdata),
                    .out                (s_axi4s_tpack)
                );
        
        jelly_fifo_generic_fwtf
                #(
                    .ASYNC              (ASYNC),
                    .DATA_WIDTH         (S_PACK_WIDTH),
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .SLAVE_REGS         (FIFO_SLAVE_REGS),
                    .MASTER_REGS        (FIFO_MASTER_REGS)
                )
            i_fifo_generic_fwtf
                (
                    .s_reset            (~s_aresetn),
                    .s_clk              (s_aclk),
                    .s_data             (s_axi4s_tpack),
                    .s_valid            (s_axi4s_tvalid),
                    .s_ready            (s_axi4s_tready),
                    .s_free_count       (s_fifo_free_count),
                    
                    .m_reset            (~m_aresetn),
                    .m_clk              (m_aclk),
                    .m_data             (fifo_tpack),
                    .m_valid            (fifo_tvalid),
                    .m_ready            (fifo_tready),
                    .m_data_count       (m_fifo_data_count)
                );
        
        jelly_func_unpack
                #(
                    .N                  (1),
                    .W0                 (S_USER_WIDTH),
                    .W1                 (PACK_FIRST_WIDTH),
                    .W2                 (PACK_LAST_WIDTH),
                    .W3                 (PACK_S_STRB_WIDTH),
                    .W4                 (PACK_S_KEEP_WIDTH),
                    .W5                 (S_DATA_WIDTH)
                )
            i_func_unpack
                (
                    .in                 (fifo_tpack),
                    .out0               (fifo_tuser),
                    .out1               (fifo_tfirst),
                    .out2               (fifo_tlast),
                    .out3               (fifo_tkeep),
                    .out4               (fifo_tstrb),
                    .out5               (fifo_tdata)
                );
        
        
        // width convert
        jelly_axi4s_width_converter
                #(
                    .UNIT_WIDTH         (UNIT_WIDTH),
                    .BYTE_WIDTH         (BYTE_WIDTH),
                    .S_DATA_WIDTH       (S_DATA_WIDTH),
                    .M_DATA_WIDTH       (M_DATA_WIDTH),
                    .USER_UNIT          (USER_UNIT),
                    .S_USER_WIDTH       (S_USER_WIDTH),
                    .WITH_FIRST         (WITH_FIRST),
                    .WITH_LAST          (WITH_LAST),
                    .WITH_STRB          (WITH_STRB),
                    .WITH_KEEP          (WITH_KEEP),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_axi4s_width_converter
                (
                    .aresetn            (m_aresetn),
                    .aclk               (m_aclk),
                    .cke                (1'b1),
                    .endian             (endian),
                    
                    .s_axi4s_tuser      (fifo_tuser),
                    .s_axi4s_tdata      (fifo_tdata),
                    .s_axi4s_tstrb      (fifo_tstrb),
                    .s_axi4s_tkeep      (fifo_tkeep),
                    .s_axi4s_tfirst     (fifo_tfirst),
                    .s_axi4s_tlast      (fifo_tlast),
                    .s_axi4s_tvalid     (fifo_tvalid),
                    .s_axi4s_tready     (fifo_tready),
                    
                    .m_axi4s_tuser      (m_axi4s_tuser),
                    .m_axi4s_tdata      (m_axi4s_tdata),
                    .m_axi4s_tstrb      (m_axi4s_tstrb),
                    .m_axi4s_tkeep      (m_axi4s_tkeep),
                    .m_axi4s_tfirst     (m_axi4s_tfirst),
                    .m_axi4s_tlast      (m_axi4s_tlast),
                    .m_axi4s_tvalid     (m_axi4s_tvalid),
                    .m_axi4s_tready     (m_axi4s_tready)
                );
        
        assign s_fifo_wr_signal = (s_axi4s_tvalid & s_axi4s_tready);
        assign m_fifo_rd_signal = (fifo_tvalid & fifo_tready);
    end
    else begin : blk_cnv_wide
        
        // width convert
        wire    [S_USER_BITS-1:0]       wide_tuser;
        wire                            wide_tfirst;
        wire                            wide_tlast;
        wire    [S_STRB_WIDTH-1:0]      wide_tkeep;
        wire    [S_STRB_WIDTH-1:0]      wide_tstrb;
        wire    [M_DATA_WIDTH-1:0]      wide_tdata;
        wire                            wide_tvalid;
        wire                            wide_tready;
        
        jelly_axi4s_width_converter
                #(
                    .UNIT_WIDTH         (UNIT_WIDTH),
                    .BYTE_WIDTH         (BYTE_WIDTH),
                    .S_DATA_WIDTH       (S_DATA_WIDTH),
                    .M_DATA_WIDTH       (M_DATA_WIDTH),
                    .USER_UNIT          (USER_UNIT),
                    .S_USER_WIDTH       (S_USER_WIDTH),
                    .WITH_FIRST         (WITH_FIRST),
                    .WITH_LAST          (WITH_LAST),
                    .WITH_STRB          (WITH_STRB),
                    .WITH_KEEP          (WITH_KEEP),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_axi4s_width_converter
                (
                    .aresetn            (s_aresetn),
                    .aclk               (s_aclk),
                    .cke                (1'b1),
                    .endian             (endian),
                    
                    .s_axi4s_tuser      (s_axi4s_tuser),
                    .s_axi4s_tdata      (s_axi4s_tdata),
                    .s_axi4s_tstrb      (s_axi4s_tstrb),
                    .s_axi4s_tkeep      (s_axi4s_tkeep),
                    .s_axi4s_tfirst     (s_axi4s_tfirst),
                    .s_axi4s_tlast      (s_axi4s_tlast),
                    .s_axi4s_tvalid     (s_axi4s_tvalid),
                    .s_axi4s_tready     (s_axi4s_tready),
                    
                    .m_axi4s_tuser      (wide_tuser),
                    .m_axi4s_tdata      (wide_tdata),
                    .m_axi4s_tstrb      (wide_tstrb),
                    .m_axi4s_tkeep      (wide_tkeep),
                    .m_axi4s_tfirst     (wide_tfirst),
                    .m_axi4s_tlast      (wide_tlast),
                    .m_axi4s_tvalid     (wide_tvalid),
                    .m_axi4s_tready     (wide_tready)
                );
        
        
        // pack -> FIFO -> unpack
        wire    [M_PACK_WIDTH-1:0]      wide_tpack;
        wire    [M_PACK_WIDTH-1:0]      m_axi4s_tpack;
        
        jelly_func_pack
                #(
                    .N                  (1),
                    .W0                 (M_USER_WIDTH),
                    .W1                 (PACK_FIRST_WIDTH),
                    .W2                 (PACK_LAST_WIDTH),
                    .W3                 (PACK_M_STRB_WIDTH),
                    .W4                 (PACK_M_KEEP_WIDTH),
                    .W5                 (M_DATA_WIDTH)
                )
            i_func_pack
                (
                    .in0                (wide_tuser),
                    .in1                (wide_tfirst),
                    .in2                (wide_tlast),
                    .in3                (wide_tkeep),
                    .in4                (wide_tstrb),
                    .in5                (wide_tdata),
                    .out                (wide_tpack)
                );
        
        jelly_fifo_generic_fwtf
                #(
                    .ASYNC              (ASYNC),
                    .DATA_WIDTH         (M_PACK_WIDTH),
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .SLAVE_REGS         (FIFO_SLAVE_REGS),
                    .MASTER_REGS        (FIFO_MASTER_REGS)
                )
            i_fifo_generic_fwtf
                (
                    .s_reset            (~s_aresetn),
                    .s_clk              (s_aclk),
                    .s_data             (wide_tpack),
                    .s_valid            (wide_tvalid),
                    .s_ready            (wide_tready),
                    .s_free_count       (s_fifo_free_count),
                    
                    .m_reset            (~m_aresetn),
                    .m_clk              (m_aclk),
                    .m_data             (m_axi4s_tpack),
                    .m_valid            (m_axi4s_tvalid),
                    .m_ready            (m_axi4s_tready),
                    .m_data_count       (m_fifo_data_count)
                );
        
        jelly_func_unpack
                #(
                    .N                  (1),
                    .W0                 (M_USER_WIDTH),
                    .W1                 (PACK_FIRST_WIDTH),
                    .W2                 (PACK_LAST_WIDTH),
                    .W3                 (PACK_M_STRB_WIDTH),
                    .W4                 (PACK_M_KEEP_WIDTH),
                    .W5                 (M_DATA_WIDTH)
                )
            i_func_unpack
                (
                    .in                 (m_axi4s_tpack),
                    .out0               (m_axi4s_tuser),
                    .out1               (m_axi4s_tfirst),
                    .out2               (m_axi4s_tlast),
                    .out3               (m_axi4s_tkeep),
                    .out4               (m_axi4s_tstrb),
                    .out5               (m_axi4s_tdata)
                );
        
        assign s_fifo_wr_signal = (wide_tvalid & wide_tready);
        assign m_fifo_rd_signal = (m_axi4s_tvalid & m_axi4s_tready);
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file

