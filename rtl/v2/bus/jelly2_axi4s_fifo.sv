// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly2_axi4s_fifo
        #(
            parameter   bit     ASYNC       = 1,
            parameter   bit     HAS_FIRST   = 0,
            parameter   bit     HAS_LAST    = 1,
            parameter   bit     HAS_STRB    = 0,
            parameter   bit     HAS_KEEP    = 0,
            
            parameter   int     BYTE_WIDTH  = 8,
            parameter   int     TDATA_WIDTH = 64,
            parameter   int     TSTRB_WIDTH = HAS_STRB ? (TDATA_WIDTH / BYTE_WIDTH) : 0,
            parameter   int     TKEEP_WIDTH = HAS_KEEP ? (TDATA_WIDTH / BYTE_WIDTH) : 0,
            parameter   int     TUSER_WIDTH = 0,
            
            parameter   int     PTR_WIDTH   = 9,
            parameter           RAM_TYPE    = "block",
            parameter   bit     LOW_DEALY   = 0,
            parameter   bit     DOUT_REGS   = 1,
            parameter   bit     S_REGS      = 1,
            parameter   bit     M_REGS      = 1,
            
            // local
            localparam  int     TDATA_BITS  = TDATA_WIDTH > 0 ? TDATA_WIDTH : 1,
            localparam  int     TSTRB_BITS  = TSTRB_WIDTH > 0 ? TSTRB_WIDTH : 1,
            localparam  int     TKEEP_BITS  = TKEEP_WIDTH > 0 ? TKEEP_WIDTH : 1,
            localparam  int     TUSER_BITS  = TUSER_WIDTH > 0 ? TUSER_WIDTH : 1
        )
        (
            input   wire                        s_aresetn,
            input   wire                        s_aclk,
            input   wire    [TDATA_WIDTH-1:0]   s_axi4s_tdata,
            input   wire    [TSTRB_BITS-1:0]    s_axi4s_tstrb,
            input   wire    [TKEEP_BITS-1:0]    s_axi4s_tkeep,
            input   wire                        s_axi4s_tfirst,
            input   wire                        s_axi4s_tlast,
            input   wire    [TUSER_BITS-1:0]    s_axi4s_tuser,
            input   wire                        s_axi4s_tvalid,
            output  wire                        s_axi4s_tready,
            output  wire    [PTR_WIDTH:0]       s_free_count,
            
            input   wire                        m_aresetn,
            input   wire                        m_aclk,
            output  wire    [TDATA_WIDTH-1:0]   m_axi4s_tdata,
            output  wire    [TSTRB_BITS-1:0]    m_axi4s_tstrb,
            output  wire    [TKEEP_BITS-1:0]    m_axi4s_tkeep,
            output  wire                        m_axi4s_tfirst,
            output  wire                        m_axi4s_tlast,
            output  wire    [TUSER_BITS-1:0]    m_axi4s_tuser,
            output  wire                        m_axi4s_tvalid,
            input   wire                        m_axi4s_tready,
            output  wire    [PTR_WIDTH:0]       m_data_count
        );
    
    // verilator lint_off PINMISSING
    jelly2_fifo_pack
            #(
                .ASYNC          (ASYNC),
                .DATA0_WIDTH    (TDATA_WIDTH),
                .DATA1_WIDTH    (TSTRB_WIDTH),
                .DATA2_WIDTH    (TKEEP_WIDTH),
                .DATA3_WIDTH    (HAS_FIRST ? 1 : 0),
                .DATA4_WIDTH    (HAS_LAST  ? 1 : 0),
                .DATA5_WIDTH    (TUSER_WIDTH),
                .PTR_WIDTH      (PTR_WIDTH),
                .DOUT_REGS      (DOUT_REGS),
                .RAM_TYPE       (RAM_TYPE),
                .LOW_DEALY      (LOW_DEALY),
                .S_REGS         (S_REGS),
                .M_REGS         (M_REGS)
            )
        i_fifo_pack
            (
                .s_reset        (~s_aresetn),
                .s_clk          (s_aclk),
                .s_cke          (1'b1),
                .s_data0        (s_axi4s_tdata),
                .s_data1        (s_axi4s_tstrb),
                .s_data2        (s_axi4s_tkeep),
                .s_data3        (s_axi4s_tfirst),
                .s_data4        (s_axi4s_tlast),
                .s_data5        (s_axi4s_tuser),
                .s_valid        (s_axi4s_tvalid),
                .s_ready        (s_axi4s_tready),
                .s_free_count   (s_free_count),
                
                .m_reset        (~m_aresetn),
                .m_clk          (m_aclk),
                .m_cke          (1'b1),
                .m_data0        (m_axi4s_tdata),
                .m_data1        (m_axi4s_tstrb),
                .m_data2        (m_axi4s_tkeep),
                .m_data3        (m_axi4s_tfirst),
                .m_data4        (m_axi4s_tlast),
                .m_data5        (m_axi4s_tuser),
                .m_valid        (m_axi4s_tvalid),
                .m_ready        (m_axi4s_tready),
                .m_data_count   (m_data_count)
            );
    // verilator lint_on PINMISSING
    
    
endmodule


`default_nettype wire


// end of file

