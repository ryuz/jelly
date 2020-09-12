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
            parameter   ASYNC            = 1,
            parameter   UNIT_WIDTH       = 8,
            parameter   S_DATA_SIZE      = 0,   // log2 (0:1byte, 1:2byte, 2:4byte, 3:81byte...)
            parameter   M_DATA_SIZE      = 0,   // log2 (0:1byte, 1:2byte, 2:4byte, 3:81byte...)
            
            parameter   FIFO_PTR_WIDTH   = 10,
            parameter   FIFO_RAM_TYPE    = "block",
            parameter   FIFO_LOW_DEALY   = 0,
            parameter   FIFO_DOUT_REGS   = 1,
            parameter   FIFO_SLAVE_REGS  = 1,
            parameter   FIFO_MASTER_REGS = 1,
            
            parameter   S_DATA_WIDTH = (UNIT_WIDTH << S_DATA_SIZE),
            parameter   M_DATA_WIDTH = (UNIT_WIDTH << M_DATA_SIZE)
        )
        (
            input   wire                        endian,
            
            input   wire                        s_reset,
            input   wire                        s_clk,
            input   wire    [S_DATA_WIDTH-1:0]  s_data,
            input   wire                        s_valid,
            output  wire                        s_ready,
            output  wire    [FIFO_PTR_WIDTH:0]  s_free_count,
            output  wire                        s_wr_signal,
            
            
            input   wire                        m_reset,
            input   wire                        m_clk,
            output  wire    [M_DATA_WIDTH-1:0]  m_data,
            output  wire                        m_valid,
            input   wire                        m_ready,
            output  wire    [FIFO_PTR_WIDTH:0]  m_data_count,
            output  wire                        m_rd_signal
        );
    
    
    generate
    if ( M_DATA_SIZE < S_DATA_SIZE ) begin : blk_cnv_narrow
        
        wire    [S_DATA_WIDTH-1:0]      fifo_data;
        wire                            fifo_valid;
        wire                            fifo_ready;
        
        jelly_fifo_generic_fwtf
                #(
                    .ASYNC              (ASYNC),
                    .DATA_WIDTH         (S_DATA_WIDTH),
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .SLAVE_REGS         (FIFO_SLAVE_REGS),
                    .MASTER_REGS        (FIFO_MASTER_REGS)
                )
            i_fifo_generic_fwtf
                (
                    .s_reset            (s_reset),
                    .s_clk              (s_clk),
                    .s_data             (s_data),
                    .s_valid            (s_valid),
                    .s_ready            (s_ready),
                    .s_free_count       (s_free_count),
                    
                    .m_reset            (m_reset),
                    .m_clk              (m_clk),
                    .m_data             (fifo_data),
                    .m_valid            (fifo_valid),
                    .m_ready            (fifo_ready),
                    .m_data_count       (m_data_count)
                );
        
        jelly_data_width_convert
                #(
                    .UNIT_WIDTH         (UNIT_WIDTH),
                    .S_DATA_SIZE        (S_DATA_SIZE),
                    .M_DATA_SIZE        (M_DATA_SIZE)
                )
            i_data_width_convert
                (
                    .reset              (m_reset),
                    .clk                (m_clk),
                    .cke                (1'b1),
                    
                    .endian             (endian),
                    
                    .s_data             (fifo_data),
                    .s_first            (1'b0),
                    .s_last             (1'b0),
                    .s_valid            (fifo_valid),
                    .s_ready            (fifo_ready),
                    
                    .m_data             (m_data),
                    .m_first            (),
                    .m_last             (),
                    .m_valid            (m_valid),
                    .m_ready            (m_ready)
                );
        
        assign s_wr_signal = (s_valid & s_ready);
        assign m_rd_signal = (fifo_valid & fifo_ready);
    end
    else begin : blk_cnv_wide
        wire    [M_DATA_WIDTH-1:0]      wide_data;
        wire                            wide_valid;
        wire                            wide_ready;
        
        jelly_data_width_converter
                #(
                    .UNIT_WIDTH         (UNIT_WIDTH),
                    .S_DATA_SIZE        (S_DATA_SIZE),
                    .M_DATA_SIZE        (M_DATA_SIZE)
                )
            i_data_width_converter
                (
                    .reset              (s_reset),
                    .clk                (s_clk),
                    .cke                (1'b1),
                    
                    .endian             (endian),
                    
                    .s_data             (s_data),
                    .s_first            (1'b0),
                    .s_last             (1'b0),
                    .s_valid            (s_valid),
                    .s_ready            (s_ready),
                    
                    .m_data             (wide_data),
                    .m_first            (),
                    .m_last             (),
                    .m_valid            (wide_valid),
                    .m_ready            (wide_ready)
                );
        
        jelly_fifo_generic_fwtf
                #(
                    .ASYNC              (ASYNC),
                    .DATA_WIDTH         (M_DATA_WIDTH),
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .SLAVE_REGS         (FIFO_SLAVE_REGS),
                    .MASTER_REGS        (FIFO_MASTER_REGS)
                )
            i_fifo_generic_fwtf
                (
                    .s_reset            (s_reset),
                    .s_clk              (s_clk),
                    .s_data             (wide_data),
                    .s_valid            (wide_valid),
                    .s_ready            (wide_ready),
                    .s_free_count       (s_free_count),
                    
                    .m_reset            (m_reset),
                    .m_clk              (m_clk),
                    .m_data             (m_data),
                    .m_valid            (m_valid),
                    .m_ready            (m_ready),
                    .m_data_count       (m_data_count)
                );
        
        assign s_wr_signal = (wide_valid & wide_ready);
        assign m_rd_signal = (m_valid & m_ready);
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file

