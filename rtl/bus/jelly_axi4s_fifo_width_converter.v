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
            parameter   FIFO_PTR_WIDTH   = 9,
            parameter   FIFO_RAM_TYPE    = "block",
            parameter   FIFO_LOW_DEALY   = 0,
            parameter   FIFO_DOUT_REGS   = 1,
            parameter   FIFO_S_REGS      = 1,
            parameter   FIFO_M_REGS      = 1,
            
            parameter   HAS_STRB         = 1,
            parameter   HAS_KEEP         = 1,
            parameter   HAS_FIRST        = 1,
            parameter   HAS_LAST         = 1,
            
            parameter   BYTE_WIDTH       = 8,
            parameter   S_TDATA_WIDTH    = 8,
            parameter   M_TDATA_WIDTH    = 32,
            parameter   DATA_WIDTH_GCD   = BYTE_WIDTH,
            
            parameter   S_TSTRB_WIDTH    = HAS_STRB ? (S_TDATA_WIDTH / BYTE_WIDTH) : 0,
            parameter   S_TKEEP_WIDTH    = HAS_KEEP ? (S_TDATA_WIDTH / BYTE_WIDTH) : 0,
            parameter   S_TUSER_WIDTH    = 0,
            
            parameter   M_TSTRB_WIDTH    = HAS_STRB ? (M_TDATA_WIDTH / BYTE_WIDTH) : 0,
            parameter   M_TKEEP_WIDTH    = HAS_KEEP ? (M_TDATA_WIDTH / BYTE_WIDTH) : 0,
            parameter   M_TUSER_WIDTH    = S_TUSER_WIDTH * M_TDATA_WIDTH / S_TDATA_WIDTH,
            
            parameter   FIRST_FORCE_LAST = 1,
            parameter   FIRST_OVERWRITE  = 0,
            
            parameter   S_REGS           = 1,
            
            // local
            parameter   S_TDATA_BITS     = S_TDATA_WIDTH > 0 ? S_TDATA_WIDTH : 1,
            parameter   S_TSTRB_BITS     = S_TSTRB_WIDTH > 0 ? S_TSTRB_WIDTH : 1,
            parameter   S_TKEEP_BITS     = S_TKEEP_WIDTH > 0 ? S_TKEEP_WIDTH : 1,
            parameter   S_TUSER_BITS     = S_TUSER_WIDTH > 0 ? S_TUSER_WIDTH : 1,
            parameter   M_TDATA_BITS     = M_TDATA_WIDTH > 0 ? M_TDATA_WIDTH : 1,
            parameter   M_TSTRB_BITS     = M_TSTRB_WIDTH > 0 ? M_TSTRB_WIDTH : 1,
            parameter   M_TKEEP_BITS     = M_TKEEP_WIDTH > 0 ? M_TKEEP_WIDTH : 1,
            parameter   M_TUSER_BITS     = M_TUSER_WIDTH > 0 ? M_TUSER_WIDTH : 1
        )
        (
            input   wire                        endian,
            
            input   wire                        s_aresetn,
            input   wire                        s_aclk,
            input   wire    [S_TDATA_BITS-1:0]  s_axi4s_tdata,
            input   wire    [S_TSTRB_BITS-1:0]  s_axi4s_tstrb,
            input   wire    [S_TKEEP_BITS-1:0]  s_axi4s_tkeep,
            input   wire                        s_axi4s_tfirst,
            input   wire                        s_axi4s_tlast,
            input   wire    [S_TUSER_BITS-1:0]  s_axi4s_tuser,
            input   wire                        s_axi4s_tvalid,
            output  wire                        s_axi4s_tready,
            output  wire    [FIFO_PTR_WIDTH:0]  s_fifo_free_count,
            output  wire                        s_fifo_wr_signal,
            
            
            input   wire                        m_aresetn,
            input   wire                        m_aclk,
            output  wire    [M_TDATA_BITS-1:0]  m_axi4s_tdata,
            output  wire    [M_TSTRB_BITS-1:0]  m_axi4s_tstrb,
            output  wire    [M_TKEEP_BITS-1:0]  m_axi4s_tkeep,
            output  wire                        m_axi4s_tfirst,
            output  wire                        m_axi4s_tlast,
            output  wire    [M_TUSER_BITS-1:0]  m_axi4s_tuser,
            output  wire                        m_axi4s_tvalid,
            input   wire                        m_axi4s_tready,
            output  wire    [FIFO_PTR_WIDTH:0]  m_fifo_data_count,
            output  wire                        m_fifo_rd_signal
        );
    
    generate
    if ( M_TDATA_WIDTH < S_TDATA_WIDTH ) begin : blk_cnv_narrow
        
        // FIFO
        wire    [S_TUSER_BITS-1:0]      fifo_tuser;
        wire                            fifo_tfirst;
        wire                            fifo_tlast;
        wire    [S_TSTRB_BITS-1:0]      fifo_tkeep;
        wire    [S_TSTRB_BITS-1:0]      fifo_tstrb;
        wire    [S_TDATA_BITS-1:0]      fifo_tdata;
        wire                            fifo_tvalid;
        wire                            fifo_tready;
        jelly_axi4s_fifo
                #(
                    .ASYNC              (ASYNC),
                    .HAS_FIRST          (HAS_FIRST),
                    .HAS_LAST           (HAS_LAST),
                    .HAS_STRB           (HAS_STRB),
                    .HAS_KEEP           (HAS_KEEP),
                    
                    .BYTE_WIDTH         (BYTE_WIDTH),
                    .TUSER_WIDTH        (S_TUSER_WIDTH),
                    .TDATA_WIDTH        (S_TDATA_WIDTH),
                    .TSTRB_WIDTH        (S_TSTRB_WIDTH),
                    .TKEEP_WIDTH        (S_TKEEP_WIDTH),
                    
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .S_REGS             (FIFO_S_REGS),
                    .M_REGS             (FIFO_M_REGS)
                )
            i_axi4s_fifo
                (
                    .s_aresetn          (s_aresetn),
                    .s_aclk             (s_aclk),
                    .s_axi4s_tfirst     (s_axi4s_tfirst),
                    .s_axi4s_tlast      (s_axi4s_tlast),
                    .s_axi4s_tuser      (s_axi4s_tuser),
                    .s_axi4s_tstrb      (s_axi4s_tstrb),
                    .s_axi4s_tkeep      (s_axi4s_tkeep),
                    .s_axi4s_tdata      (s_axi4s_tdata),
                    .s_axi4s_tvalid     (s_axi4s_tvalid),
                    .s_axi4s_tready     (s_axi4s_tready),
                    .s_free_count       (s_fifo_free_count),
                    
                    .m_aresetn          (m_aresetn),
                    .m_aclk             (m_aclk),
                    .m_axi4s_tuser      (fifo_tuser),
                    .m_axi4s_tfirst     (fifo_tfirst),
                    .m_axi4s_tlast      (fifo_tlast),
                    .m_axi4s_tstrb      (fifo_tstrb),
                    .m_axi4s_tkeep      (fifo_tkeep),
                    .m_axi4s_tdata      (fifo_tdata),
                    .m_axi4s_tvalid     (fifo_tvalid),
                    .m_axi4s_tready     (fifo_tready),
                    .m_data_count       (m_fifo_data_count)
                );
        
        // width convert
        jelly_axi4s_width_converter
                #(
                    .HAS_STRB           (HAS_STRB),
                    .HAS_KEEP           (HAS_KEEP),
                    .HAS_FIRST          (HAS_FIRST),
                    .HAS_LAST           (HAS_LAST),
                    .BYTE_WIDTH         (BYTE_WIDTH),
                    .S_TDATA_WIDTH      (S_TDATA_WIDTH),
                    .M_TDATA_WIDTH      (M_TDATA_WIDTH),
                    .DATA_WIDTH_GCD     (DATA_WIDTH_GCD),
                    .S_TSTRB_WIDTH      (S_TSTRB_WIDTH),
                    .S_TKEEP_WIDTH      (S_TKEEP_WIDTH),
                    .S_TUSER_WIDTH      (S_TUSER_WIDTH),
                    .M_TSTRB_WIDTH      (M_TSTRB_WIDTH),
                    .M_TKEEP_WIDTH      (M_TKEEP_WIDTH),
                    .M_TUSER_WIDTH      (M_TUSER_WIDTH),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_axi4s_width_converter
                (
                    .aresetn            (m_aresetn),
                    .aclk               (m_aclk),
                    .aclken             (1'b1),
                    .endian             (endian),
                    
                    .s_axi4s_tdata      (fifo_tdata),
                    .s_axi4s_tstrb      (fifo_tstrb),
                    .s_axi4s_tkeep      (fifo_tkeep),
                    .s_axi4s_tfirst     (fifo_tfirst),
                    .s_axi4s_tlast      (fifo_tlast),
                    .s_axi4s_tuser      (fifo_tuser),
                    .s_axi4s_tvalid     (fifo_tvalid),
                    .s_axi4s_tready     (fifo_tready),
                    
                    .m_axi4s_tdata      (m_axi4s_tdata),
                    .m_axi4s_tstrb      (m_axi4s_tstrb),
                    .m_axi4s_tkeep      (m_axi4s_tkeep),
                    .m_axi4s_tfirst     (m_axi4s_tfirst),
                    .m_axi4s_tlast      (m_axi4s_tlast),
                    .m_axi4s_tuser      (m_axi4s_tuser),
                    .m_axi4s_tvalid     (m_axi4s_tvalid),
                    .m_axi4s_tready     (m_axi4s_tready)
                );
        
        assign s_fifo_wr_signal = (s_axi4s_tvalid & s_axi4s_tready);
        assign m_fifo_rd_signal = (fifo_tvalid & fifo_tready);
    end
    else begin : blk_cnv_wide
        
        // width convert
        wire    [M_TDATA_WIDTH-1:0]     wide_tdata;
        wire    [M_TSTRB_WIDTH-1:0]     wide_tstrb;
        wire    [M_TKEEP_BITS-1:0]      wide_tkeep;
        wire                            wide_tfirst;
        wire                            wide_tlast;
        wire    [M_TUSER_BITS-1:0]      wide_tuser;
        wire                            wide_tvalid;
        wire                            wide_tready;
        
        jelly_axi4s_width_converter
                #(
                    .HAS_STRB           (HAS_STRB),
                    .HAS_KEEP           (HAS_KEEP),
                    .HAS_FIRST          (HAS_FIRST),
                    .HAS_LAST           (HAS_LAST),
                    .BYTE_WIDTH         (BYTE_WIDTH),
                    .S_TDATA_WIDTH      (S_TDATA_WIDTH),
                    .M_TDATA_WIDTH      (M_TDATA_WIDTH),
                    .DATA_WIDTH_GCD     (DATA_WIDTH_GCD),
                    .S_TSTRB_WIDTH      (S_TSTRB_WIDTH),
                    .S_TKEEP_WIDTH      (S_TKEEP_WIDTH),
                    .S_TUSER_WIDTH      (S_TUSER_WIDTH),
                    .M_TSTRB_WIDTH      (M_TSTRB_WIDTH),
                    .M_TKEEP_WIDTH      (M_TKEEP_WIDTH),
                    .M_TUSER_WIDTH      (M_TUSER_WIDTH),
                    .FIRST_FORCE_LAST   (FIRST_FORCE_LAST),
                    .FIRST_OVERWRITE    (FIRST_OVERWRITE),
                    .S_REGS             (S_REGS)
                )
            i_axi4s_width_converter
                (
                    .aresetn            (s_aresetn),
                    .aclk               (s_aclk),
                    .aclken             (1'b1),
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
        
        // FIFO
        jelly_axi4s_fifo
                #(
                    .ASYNC              (ASYNC),
                    .HAS_FIRST          (HAS_FIRST),
                    .HAS_LAST           (HAS_LAST),
                    .HAS_STRB           (HAS_STRB),
                    .HAS_KEEP           (HAS_KEEP),
                    
                    .BYTE_WIDTH         (BYTE_WIDTH),
                    .TUSER_WIDTH        (M_TUSER_WIDTH),
                    .TDATA_WIDTH        (M_TDATA_WIDTH),
                    .TSTRB_WIDTH        (M_TSTRB_WIDTH),
                    .TKEEP_WIDTH        (M_TKEEP_WIDTH),
                    
                    .PTR_WIDTH          (FIFO_PTR_WIDTH),
                    .RAM_TYPE           (FIFO_RAM_TYPE),
                    .LOW_DEALY          (FIFO_LOW_DEALY),
                    .DOUT_REGS          (FIFO_DOUT_REGS),
                    .S_REGS             (FIFO_S_REGS),
                    .M_REGS             (FIFO_M_REGS)
                )
            i_axi4s_fifo
                (
                    .s_aresetn          (s_aresetn),
                    .s_aclk             (s_aclk),
                    .s_axi4s_tfirst     (wide_tfirst),
                    .s_axi4s_tlast      (wide_tlast),
                    .s_axi4s_tuser      (wide_tuser),
                    .s_axi4s_tstrb      (wide_tstrb),
                    .s_axi4s_tkeep      (wide_tkeep),
                    .s_axi4s_tdata      (wide_tdata),
                    .s_axi4s_tvalid     (wide_tvalid),
                    .s_axi4s_tready     (wide_tready),
                    .s_free_count       (s_fifo_free_count),
                    
                    .m_aresetn          (m_aresetn),
                    .m_aclk             (m_aclk),
                    .m_axi4s_tuser      (m_axi4s_tuser),
                    .m_axi4s_tfirst     (m_axi4s_tfirst),
                    .m_axi4s_tlast      (m_axi4s_tlast),
                    .m_axi4s_tstrb      (m_axi4s_tstrb),
                    .m_axi4s_tkeep      (m_axi4s_tkeep),
                    .m_axi4s_tdata      (m_axi4s_tdata),
                    .m_axi4s_tvalid     (m_axi4s_tvalid),
                    .m_axi4s_tready     (m_axi4s_tready),
                    .m_data_count       (m_fifo_data_count)
                );
         
        assign s_fifo_wr_signal = (wide_tvalid & wide_tready);
        assign m_fifo_rd_signal = (m_axi4s_tvalid & m_axi4s_tready);
    end
    endgenerate
    
    
endmodule


`default_nettype wire


// end of file

