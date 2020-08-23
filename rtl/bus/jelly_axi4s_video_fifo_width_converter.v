// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_axi4s_video_fifo_width_converter
        #(
            parameter   ASYNC            = 1,
            parameter   UNIT_WIDTH       = 8,
            parameter   S_TDATA_SIZE     = 0,   // log2 (0:1byte, 1:2byte, 2:4byte, 3:81byte...)
            parameter   M_TDATA_SIZE     = 0,   // log2 (0:1byte, 1:2byte, 2:4byte, 3:81byte...)
            
            parameter   FIFO_PTR_WIDTH   = 10,
            parameter   FIFO_RAM_TYPE    = "block",
            parameter   FIFO_LOW_DEALY   = 0,
            parameter   FIFO_DOUT_REGS   = 1,
            parameter   FIFO_SLAVE_REGS  = 1,
            parameter   FIFO_MASTER_REGS = 1,
            
            parameter   S_TDATA_WIDTH = (UNIT_WIDTH << S_TDATA_SIZE),
            parameter   M_TDATA_WIDTH = (UNIT_WIDTH << M_TDATA_SIZE)
        )
        (
            input   wire                        endian,
            
            input   wire                        s_axi4s_aresetn,
            input   wire                        s_axi4s_aclk,
            input   wire    [0:0]               s_axi4s_tuser,
            input   wire                        s_axi4s_tlast,
            input   wire    [S_TDATA_WIDTH-1:0] s_axi4s_tdata,
            input   wire                        s_axi4s_tvalid,
            output  wire                        s_axi4s_tready,
            output  wire    [FIFO_PTR_WIDTH:0]  s_fifo_free_count,
            output  wire                        s_fifo_wr_signal,
            
            
            input   wire                        m_axi4s_aresetn,
            input   wire                        m_axi4s_aclk,
            output  wire    [0:0]               m_axi4s_tuser,
            output  wire                        m_axi4s_tlast,
            output  wire    [M_TDATA_WIDTH-1:0] m_axi4s_tdata,
            output  wire                        m_axi4s_tvalid,
            input   wire                        m_axi4s_tready,
            output  wire    [FIFO_PTR_WIDTH:0]  m_fifo_data_count,
            output  wire                        s_fifo_rd_signal
        );
    
    
    generate
    if ( S_TDATA_SIZE >= M_TDATA_SIZE ) begin : blk_cnv_wide
        
        wire    [0:0]                   axi4s_fifo_tuser;
        wire                            axi4s_fifo_tlast;
        wire    [S_TDATA_WIDTH-1:0]     axi4s_fifo_tdata;
        wire                            axi4s_fifo_tvalid;
        wire                            axi4s_fifo_tready;
        
        jelly_axi4s_video_fifo
                #(
                    .TUSER_WIDTH        (1),
                    .TDATA_WIDTH        (S_TDATA_WIDTH),
                    
                    .ASYNC              (ASYNC),
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .SLAVE_REGS         (FIFO_SLAVE_REGS),
                    .MASTER_REGS        (FIFO_MASTER_REGS)
                )
            i_axi4s_video_fifo
                (
                    .s_axi4s_aresetn    (s_axi4s_aresetn),
                    .s_axi4s_aclk       (s_axi4s_aclk),
                    .s_axi4s_tuser      (s_axi4s_tuser),
                    .s_axi4s_tlast      (s_axi4s_tlast),
                    .s_axi4s_tdata      (s_axi4s_tdata),
                    .s_axi4s_tvalid     (s_axi4s_tvalid),
                    .s_axi4s_tready     (s_axi4s_tready),
                    .s_fifo_free_count  (s_fifo_free_count),
                    
                    .m_axi4s_aresetn    (m_axi4s_aresetn),
                    .m_axi4s_aclk       (m_axi4s_aclk),
                    .m_axi4s_tuser      (axi4s_fifo_tuser),
                    .m_axi4s_tlast      (axi4s_fifo_tlast),
                    .m_axi4s_tdata      (axi4s_fifo_tdata),
                    .m_axi4s_tvalid     (axi4s_fifo_tvalid),
                    .m_axi4s_tready     (axi4s_fifo_tready),
                    .m_fifo_data_count  (m_fifo_data_count)
                );
        
        jelly_axi4s_video_width_converter
                #(
                    .UNIT_WIDTH         (UNIT_WIDTH),
                    .S_TDATA_SIZE       (S_TDATA_SIZE),
                    .M_TDATA_SIZE       (M_TDATA_SIZE)
                )
            i_data_width_converter
                (
                    .aresetn            (m_axi4s_aresetn),
                    .aclk               (m_axi4s_aclk),
                    .aclken             (1'b1),
                    
                    .endian             (endian),
                    
                    .s_axi4s_tuser      (axi4s_fifo_tuser),
                    .s_axi4s_tlast      (axi4s_fifo_tlast),
                    .s_axi4s_tdata      (axi4s_fifo_tdata),
                    .s_axi4s_tvalid     (axi4s_fifo_tvalid),
                    .s_axi4s_tready     (axi4s_fifo_tready),
                    
                    .m_axi4s_tuser      (m_axi4s_tuser),
                    .m_axi4s_tlast      (m_axi4s_tlast),
                    .m_axi4s_tdata      (m_axi4s_tdata),
                    .m_axi4s_tvalid     (m_axi4s_tvalid),
                    .m_axi4s_tready     (m_axi4s_tready)
                );
        
        assign s_fifo_wr_signal = (s_axi4s_tvalid & s_axi4s_tready);
        assign m_fifo_rd_signal = (axi4s_fifo_tvalid & axi4s_fifo_tready);
    end
    else begin : blk_cnv_narrow
        wire    [0:0]                   axi4s_wide_tuser;
        wire                            axi4s_wide_tlast;
        wire    [M_TDATA_WIDTH-1:0]     axi4s_wide_tdata;
        wire                            axi4s_wide_tvalid;
        wire                            axi4s_wide_tready;
        
        jelly_axi4s_video_width_converter
                #(
                    .UNIT_WIDTH         (UNIT_WIDTH),
                    .S_TDATA_SIZE       (S_TDATA_SIZE),
                    .M_TDATA_SIZE       (M_TDATA_SIZE)
                )
            i_data_width_converter
                (
                    .aresetn            (s_axi4s_aresetn),
                    .aclk               (s_axi4s_aclk),
                    .aclken             (1'b1),
                    
                    .endian             (endian),
                    
                    .s_axi4s_tuser      (s_axi4s_tuser),
                    .s_axi4s_tlast      (s_axi4s_tlast),
                    .s_axi4s_tdata      (s_axi4s_tdata),
                    .s_axi4s_tvalid     (s_axi4s_tvalid),
                    .s_axi4s_tready     (s_axi4s_tready),
                    
                    .m_axi4s_tuser      (axi4s_wide_tuser),
                    .m_axi4s_tlast      (axi4s_wide_tlast),
                    .m_axi4s_tdata      (axi4s_wide_tdata),
                    .m_axi4s_tvalid     (axi4s_wide_tvalid),
                    .m_axi4s_tready     (axi4s_wide_tready)
                );
        
        jelly_axi4s_video_fifo
                #(
                    .TUSER_WIDTH        (1),
                    .TDATA_WIDTH        (M_TDATA_WIDTH),
                    
                    .ASYNC              (ASYNC),
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .SLAVE_REGS         (FIFO_SLAVE_REGS),
                    .MASTER_REGS        (FIFO_MASTER_REGS)
                )
            i_axi4s_video_fifo
                (
                    .s_axi4s_aresetn    (s_axi4s_aresetn),
                    .s_axi4s_aclk       (s_axi4s_aclk),
                    .s_axi4s_tuser      (axi4s_wide_tuser),
                    .s_axi4s_tlast      (axi4s_wide_tlast),
                    .s_axi4s_tdata      (axi4s_wide_tdata),
                    .s_axi4s_tvalid     (axi4s_wide_tvalid),
                    .s_axi4s_tready     (axi4s_wide_tready),
                    .s_fifo_free_count  (s_fifo_free_count),
                    
                    .m_axi4s_aresetn    (m_axi4s_aresetn),
                    .m_axi4s_aclk       (m_axi4s_aclk),
                    .m_axi4s_tuser      (m_axi4s_tuser),
                    .m_axi4s_tlast      (m_axi4s_tlast),
                    .m_axi4s_tdata      (m_axi4s_tdata),
                    .m_axi4s_tvalid     (m_axi4s_tvalid),
                    .m_axi4s_tready     (m_axi4s_tready),
                    .m_fifo_data_count  (m_fifo_data_count)
                );
        
        assign s_fifo_wr_signal = (axi4s_wide_tvalid & axi4s_wide_tready);
        assign m_fifo_rd_signal = (m_axi4s_tvalid & m_axi4s_tready);
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file

