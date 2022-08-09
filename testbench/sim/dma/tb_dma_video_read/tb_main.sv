// ---------------------------------------------------------------------------
//
//                                 Copyright (C) 2015-2020 by Ryuz 
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module tb_main
        #(
            parameter   int     WB_ADR_WIDTH          = 8,
            parameter   int     WB_DAT_WIDTH          = 32,
            parameter   int     WB_SEL_WIDTH          = (WB_DAT_WIDTH / 8)
        )
        (
            input   wire                        s_wb_rst_i,
            input   wire                        s_wb_clk_i,
            input   wire    [WB_ADR_WIDTH-1:0]  s_wb_adr_i,
            input   wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_i,
            output  wire    [WB_DAT_WIDTH-1:0]  s_wb_dat_o,
            input   wire                        s_wb_we_i,
            input   wire    [WB_SEL_WIDTH-1:0]  s_wb_sel_i,
            input   wire                        s_wb_stb_i,
            output  wire                        s_wb_ack_o,

            input   wire                        mem_aresetn,
            input   wire                        mem_aclk,
            input   wire                        video_aresetn,
            input   wire                        video_aclk
        );
    
    
    // -----------------------------------------
    //  top
    // -----------------------------------------

    localparam  BYTE_WIDTH            = 8;
    localparam  WB_ASYNC              = 1;
    localparam  AXI4S_ASYNC           = 1;
    localparam  AXI4S_DATA_WIDTH      = 32;
    localparam  AXI4S_USER_WIDTH      = 1;
    localparam  AXI4_ID_WIDTH         = 6;
    localparam  AXI4_ADDR_WIDTH       = 32;
    localparam  AXI4_DATA_SIZE        = 2;    // 0:8bit; 1:16bit; 2:32bit ...
    localparam  AXI4_DATA_WIDTH       = (BYTE_WIDTH << AXI4_DATA_SIZE);
    localparam  AXI4_LEN_WIDTH        = 8;
    localparam  AXI4_QOS_WIDTH        = 4;
    localparam  AXI4_ARID             = {AXI4_ID_WIDTH{1'b0}};
    localparam  AXI4_ARSIZE           = AXI4_DATA_SIZE;
    localparam  AXI4_ARBURST          = 2'b01;
    localparam  AXI4_ARLOCK           = 1'b0;
    localparam  AXI4_ARCACHE          = 4'b0001;
    localparam  AXI4_ARPROT           = 3'b000;
    localparam  AXI4_ARQOS            = 0;
    localparam  AXI4_ARREGION         = 4'b0000;
    localparam  AXI4_ALIGN            = 12;  // 2^12 = 4k が境界
    localparam  INDEX_WIDTH           = 1;
    localparam  SIZE_OFFSET           = 1'b1;
    localparam  H_SIZE_WIDTH          = 12;
    localparam  V_SIZE_WIDTH          = 12;
    localparam  F_SIZE_WIDTH          = 8;
    localparam  LINE_STEP_WIDTH       = AXI4_ADDR_WIDTH;
    localparam  FRAME_STEP_WIDTH      = AXI4_ADDR_WIDTH;
    localparam  INIT_CTL_CONTROL      = 4'b0000;
    localparam  INIT_IRQ_ENABLE       = 1'b0;
    localparam  INIT_PARAM_ADDR       = 0;
    localparam  INIT_PARAM_OFFSET     = 0;
    localparam  INIT_PARAM_AWLEN_MAX  = 0;
    localparam  INIT_PARAM_H_SIZE     = 0;
    localparam  INIT_PARAM_V_SIZE     = 0;
    localparam  INIT_PARAM_LINE_STEP  = 0;
    localparam  INIT_PARAM_F_SIZE     = 0;
    localparam  INIT_PARAM_FRAME_STEP = 0;
    localparam  CORE_ID               = 32'h527a_0120;
    localparam  CORE_VERSION          = 32'h0000_0000;
    localparam  BYPASS_GATE           = 0;
    localparam  BYPASS_ALIGN          = 0;
    localparam  ALLOW_UNALIGNED       = 1;
    localparam  CAPACITY_WIDTH        = 32;
    localparam  RFIFO_PTR_WIDTH       = 9;
    localparam  RFIFO_RAM_TYPE        = "block";
    localparam  RFIFO_LOW_DEALY       = 0;
    localparam  RFIFO_DOUT_REGS       = 1;
    localparam  RFIFO_S_REGS          = 0;
    localparam  RFIFO_M_REGS          = 1;
    localparam  ARFIFO_PTR_WIDTH      = 4;
    localparam  ARFIFO_RAM_TYPE       = "distributed";
    localparam  ARFIFO_LOW_DEALY      = 1;
    localparam  ARFIFO_DOUT_REGS      = 1;
    localparam  ARFIFO_S_REGS         = 1;
    localparam  ARFIFO_M_REGS         = 1;
    localparam  SRFIFO_PTR_WIDTH      = 4;
    localparam  SRFIFO_RAM_TYPE       = "distributed";
    localparam  SRFIFO_LOW_DEALY      = 0;
    localparam  SRFIFO_DOUT_REGS      = 0;
    localparam  SRFIFO_S_REGS         = 0;
    localparam  SRFIFO_M_REGS         = 0;
    localparam  MRFIFO_PTR_WIDTH      = 4;
    localparam  MRFIFO_RAM_TYPE       = "distributed";
    localparam  MRFIFO_LOW_DEALY      = 1;
    localparam  MRFIFO_DOUT_REGS      = 0;
    localparam  MRFIFO_S_REGS         = 0;
    localparam  MRFIFO_M_REGS         = 0;
    localparam  RACKFIFO_PTR_WIDTH    = 4;
    localparam  RACKFIFO_DOUT_REGS    = 0;
    localparam  RACKFIFO_RAM_TYPE     = "distributed";
    localparam  RACKFIFO_LOW_DEALY    = 1;
    localparam  RACKFIFO_S_REGS       = 0;
    localparam  RACKFIFO_M_REGS       = 0;
    localparam  RACK_S_REGS           = 0;
    localparam  RACK_M_REGS           = 1;
    localparam  CACKFIFO_PTR_WIDTH    = 4;
    localparam  CACKFIFO_DOUT_REGS    = 0;
    localparam  CACKFIFO_RAM_TYPE     = "distributed";
    localparam  CACKFIFO_LOW_DEALY    = 1;
    localparam  CACKFIFO_S_REGS       = 0;
    localparam  CACKFIFO_M_REGS       = 0;
    localparam  CACK_S_REGS           = 0;
    localparam  CACK_M_REGS           = 1;
    localparam  CONVERT_S_REGS        = 0;

    logic                           endian;
    
    logic   [0:0]                   out_irq;
    
    logic                           buffer_request;
    logic                           buffer_release;
    logic   [AXI4_ADDR_WIDTH-1:0]   buffer_addr = '0;
    
    logic                           m_axi4s_aresetn;
    logic                           m_axi4s_aclk;
    logic   [AXI4S_USER_WIDTH-1:0]  m_axi4s_tuser;
    logic                           m_axi4s_tlast;
    logic   [AXI4S_DATA_WIDTH-1:0]  m_axi4s_tdata;
    logic                           m_axi4s_tvalid;
    logic                           m_axi4s_tready;
    
    logic                           m_aresetn;
    logic                           m_aclk;
    logic   [AXI4_ID_WIDTH-1:0]     m_axi4_arid;
    logic   [AXI4_ADDR_WIDTH-1:0]   m_axi4_araddr;
    logic   [AXI4_LEN_WIDTH-1:0]    m_axi4_arlen;
    logic   [2:0]                   m_axi4_arsize;
    logic   [1:0]                   m_axi4_arburst;
    logic   [0:0]                   m_axi4_arlock;
    logic   [3:0]                   m_axi4_arcache;
    logic   [2:0]                   m_axi4_arprot;
    logic   [AXI4_QOS_WIDTH-1:0]    m_axi4_arqos;
    logic   [3:0]                   m_axi4_arregion;
    logic                           m_axi4_arvalid;
    logic                           m_axi4_arready;
    logic   [AXI4_ID_WIDTH-1:0]     m_axi4_rid;
    logic   [AXI4_DATA_WIDTH-1:0]   m_axi4_rdata;
    logic   [1:0]                   m_axi4_rresp;
    logic                           m_axi4_rlast;
    logic                           m_axi4_rvalid;
    logic                           m_axi4_rready;
    
    always_comb m_axi4s_aresetn = video_aresetn;
    always_comb m_axi4s_aclk    = video_aclk;
    always_comb m_aresetn       = mem_aresetn;
    always_comb m_aclk          = mem_aclk;

    jelly_dma_video_read
            #(
                .BYTE_WIDTH             (BYTE_WIDTH             ),
                .WB_ASYNC               (WB_ASYNC               ),
                .WB_ADR_WIDTH           (WB_ADR_WIDTH           ),
                .WB_DAT_WIDTH           (WB_DAT_WIDTH           ),
                .WB_SEL_WIDTH           (WB_SEL_WIDTH           ),
                .AXI4S_ASYNC            (AXI4S_ASYNC            ),
                .AXI4S_DATA_WIDTH       (AXI4S_DATA_WIDTH       ),
                .AXI4S_USER_WIDTH       (AXI4S_USER_WIDTH       ),
                .AXI4_ID_WIDTH          (AXI4_ID_WIDTH          ),
                .AXI4_ADDR_WIDTH        (AXI4_ADDR_WIDTH        ),
                .AXI4_DATA_SIZE         (AXI4_DATA_SIZE         ),
                .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH        ),
                .AXI4_LEN_WIDTH         (AXI4_LEN_WIDTH         ),
                .AXI4_QOS_WIDTH         (AXI4_QOS_WIDTH         ),
                .AXI4_ARID              (AXI4_ARID              ),
                .AXI4_ARSIZE            (AXI4_ARSIZE            ),
                .AXI4_ARBURST           (AXI4_ARBURST           ),
                .AXI4_ARLOCK            (AXI4_ARLOCK            ),
                .AXI4_ARCACHE           (AXI4_ARCACHE           ),
                .AXI4_ARPROT            (AXI4_ARPROT            ),
                .AXI4_ARQOS             (AXI4_ARQOS             ),
                .AXI4_ARREGION          (AXI4_ARREGION          ),
                .AXI4_ALIGN             (AXI4_ALIGN             ),
                .INDEX_WIDTH            (INDEX_WIDTH            ),
                .SIZE_OFFSET            (SIZE_OFFSET            ),
                .H_SIZE_WIDTH           (H_SIZE_WIDTH           ),
                .V_SIZE_WIDTH           (V_SIZE_WIDTH           ),
                .F_SIZE_WIDTH           (F_SIZE_WIDTH           ),
                .LINE_STEP_WIDTH        (LINE_STEP_WIDTH        ),
                .FRAME_STEP_WIDTH       (FRAME_STEP_WIDTH       ),
                .INIT_CTL_CONTROL       (INIT_CTL_CONTROL       ),
                .INIT_IRQ_ENABLE        (INIT_IRQ_ENABLE        ),
                .INIT_PARAM_ADDR        (INIT_PARAM_ADDR        ),
                .INIT_PARAM_OFFSET      (INIT_PARAM_OFFSET      ),
                .INIT_PARAM_AWLEN_MAX   (INIT_PARAM_AWLEN_MAX   ),
                .INIT_PARAM_H_SIZE      (INIT_PARAM_H_SIZE      ),
                .INIT_PARAM_V_SIZE      (INIT_PARAM_V_SIZE      ),
                .INIT_PARAM_LINE_STEP   (INIT_PARAM_LINE_STEP   ),
                .INIT_PARAM_F_SIZE      (INIT_PARAM_F_SIZE      ),
                .INIT_PARAM_FRAME_STEP  (INIT_PARAM_FRAME_STEP  ),
                .CORE_ID                (CORE_ID                ),
                .CORE_VERSION           (CORE_VERSION           ),
                .BYPASS_GATE            (BYPASS_GATE            ),
                .BYPASS_ALIGN           (BYPASS_ALIGN           ),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED        ),
                .CAPACITY_WIDTH         (CAPACITY_WIDTH         ),
                .RFIFO_PTR_WIDTH        (RFIFO_PTR_WIDTH        ),
                .RFIFO_RAM_TYPE         (RFIFO_RAM_TYPE         ),
                .RFIFO_LOW_DEALY        (RFIFO_LOW_DEALY        ),
                .RFIFO_DOUT_REGS        (RFIFO_DOUT_REGS        ),
                .RFIFO_S_REGS           (RFIFO_S_REGS           ),
                .RFIFO_M_REGS           (RFIFO_M_REGS           ),
                .ARFIFO_PTR_WIDTH       (ARFIFO_PTR_WIDTH       ),
                .ARFIFO_RAM_TYPE        (ARFIFO_RAM_TYPE        ),
                .ARFIFO_LOW_DEALY       (ARFIFO_LOW_DEALY       ),
                .ARFIFO_DOUT_REGS       (ARFIFO_DOUT_REGS       ),
                .ARFIFO_S_REGS          (ARFIFO_S_REGS          ),
                .ARFIFO_M_REGS          (ARFIFO_M_REGS          ),
                .SRFIFO_PTR_WIDTH       (SRFIFO_PTR_WIDTH       ),
                .SRFIFO_RAM_TYPE        (SRFIFO_RAM_TYPE        ),
                .SRFIFO_LOW_DEALY       (SRFIFO_LOW_DEALY       ),
                .SRFIFO_DOUT_REGS       (SRFIFO_DOUT_REGS       ),
                .SRFIFO_S_REGS          (SRFIFO_S_REGS          ),
                .SRFIFO_M_REGS          (SRFIFO_M_REGS          ),
                .MRFIFO_PTR_WIDTH       (MRFIFO_PTR_WIDTH       ),
                .MRFIFO_RAM_TYPE        (MRFIFO_RAM_TYPE        ),
                .MRFIFO_LOW_DEALY       (MRFIFO_LOW_DEALY       ),
                .MRFIFO_DOUT_REGS       (MRFIFO_DOUT_REGS       ),
                .MRFIFO_S_REGS          (MRFIFO_S_REGS          ),
                .MRFIFO_M_REGS          (MRFIFO_M_REGS          ),
                .RACKFIFO_PTR_WIDTH     (RACKFIFO_PTR_WIDTH     ),
                .RACKFIFO_DOUT_REGS     (RACKFIFO_DOUT_REGS     ),
                .RACKFIFO_RAM_TYPE      (RACKFIFO_RAM_TYPE      ),
                .RACKFIFO_LOW_DEALY     (RACKFIFO_LOW_DEALY     ),
                .RACKFIFO_S_REGS        (RACKFIFO_S_REGS        ),
                .RACKFIFO_M_REGS        (RACKFIFO_M_REGS        ),
                .RACK_S_REGS            (RACK_S_REGS            ),
                .RACK_M_REGS            (RACK_M_REGS            ),
                .CACKFIFO_PTR_WIDTH     (CACKFIFO_PTR_WIDTH     ),
                .CACKFIFO_DOUT_REGS     (CACKFIFO_DOUT_REGS     ),
                .CACKFIFO_RAM_TYPE      (CACKFIFO_RAM_TYPE      ),
                .CACKFIFO_LOW_DEALY     (CACKFIFO_LOW_DEALY     ),
                .CACKFIFO_S_REGS        (CACKFIFO_S_REGS        ),
                .CACKFIFO_M_REGS        (CACKFIFO_M_REGS        ),
                .CACK_S_REGS            (CACK_S_REGS            ),
                .CACK_M_REGS            (CACK_M_REGS            ),
                .CONVERT_S_REGS         (CONVERT_S_REGS         )
            )
        i_dma_video_read
            (
                .endian,

                .s_wb_rst_i,
                .s_wb_clk_i,
                .s_wb_adr_i,
                .s_wb_dat_i,
                .s_wb_dat_o,
                .s_wb_we_i,
                .s_wb_sel_i,
                .s_wb_stb_i,
                .s_wb_ack_o,
                .out_irq,

                .buffer_request,
                .buffer_release,
                .buffer_addr,
                
                .m_axi4s_aresetn,
                .m_axi4s_aclk,
                .m_axi4s_tuser,
                .m_axi4s_tlast,
                .m_axi4s_tdata,
                .m_axi4s_tvalid,
                .m_axi4s_tready,
                
                .m_aresetn,
                .m_aclk,
                .m_axi4_arid,
                .m_axi4_araddr,
                .m_axi4_arlen,
                .m_axi4_arsize,
                .m_axi4_arburst,
                .m_axi4_arlock,
                .m_axi4_arcache,
                .m_axi4_arprot,
                .m_axi4_arqos,
                .m_axi4_arregion,
                .m_axi4_arvalid,
                .m_axi4_arready,
                .m_axi4_rid,
                .m_axi4_rdata,
                .m_axi4_rresp,
                .m_axi4_rlast,
                .m_axi4_rvalid,
                .m_axi4_rready
            );
    
    

    // -----------------------------------------
    //  video output
    // -----------------------------------------

    localparam RAND_BUSY = 1;

    jelly2_axi4s_slave_model
            #(
                .COMPONENTS         (1),
                .DATA_WIDTH         (AXI4S_DATA_WIDTH),
                .INIT_FRAME_NUM     (0),
                .FORMAT             ("P2"),
                .FILE_NAME          ("img_"),
                .FILE_EXT           (".pgm"),
                .SEQUENTIAL_FILE    (1),
                .ENDIAN             (0),
                .BUSY_RATE          (RAND_BUSY ? 30 : 0),
                .RANDOM_SEED        (732)
            )
        i_axi4s_slave_model
            (
                .aresetn            (video_aresetn),
                .aclk               (video_aclk),
                .aclken             (1'b1),

                .param_width        (640),
                .param_height       (480),
                .frame_num          (),
                
                .s_axi4s_tuser      (m_axi4s_tuser),
                .s_axi4s_tlast      (m_axi4s_tlast),
                .s_axi4s_tdata      (m_axi4s_tdata),
                .s_axi4s_tvalid     (m_axi4s_tvalid),
                .s_axi4s_tready     (m_axi4s_tready)
            );


    // -----------------------------------------
    //  memory
    // -----------------------------------------

    jelly_axi4_slave_model
            #(
                .AXI_ID_WIDTH           (AXI4_ID_WIDTH),
                .AXI_ADDR_WIDTH         (AXI4_ADDR_WIDTH),
                .AXI_QOS_WIDTH          (AXI4_QOS_WIDTH),
                .AXI_LEN_WIDTH          (AXI4_LEN_WIDTH),
                .AXI_DATA_SIZE          (AXI4_DATA_SIZE),
                .AXI_DATA_WIDTH         (AXI4_DATA_WIDTH),
                .AXI_STRB_WIDTH         (AXI4_DATA_WIDTH/8),
                .MEM_WIDTH              (24),
                
                .READ_DATA_ADDR         (0),
                
                .WRITE_LOG_FILE         ("axi4_write.txt"),
                .READ_LOG_FILE          ("axi4_read.txt"),
                
                .AW_DELAY               (RAND_BUSY ? 64 : 0),
                .AR_DELAY               (RAND_BUSY ? 64 : 0),
                
                .AW_FIFO_PTR_WIDTH      (RAND_BUSY ? 4 : 0),
                .W_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .B_FIFO_PTR_WIDTH       (RAND_BUSY ? 4 : 0),
                .AR_FIFO_PTR_WIDTH      (0),
                .R_FIFO_PTR_WIDTH       (0),
                
                .AW_BUSY_RATE           (RAND_BUSY ? 80 : 0),
                .W_BUSY_RATE            (RAND_BUSY ? 20 : 0),
                .B_BUSY_RATE            (RAND_BUSY ? 20 : 0),
                .AR_BUSY_RATE           (RAND_BUSY ? 80 : 0),
                .R_BUSY_RATE            (RAND_BUSY ? 20 : 0)
            )
        i_axi4_slave_model
            (
                .aresetn                (mem_aresetn),
                .aclk                   (mem_aclk),
                
                .s_axi4_awid            (),
                .s_axi4_awaddr          (),
                .s_axi4_awlen           (),
                .s_axi4_awsize          (),
                .s_axi4_awburst         (),
                .s_axi4_awlock          (),
                .s_axi4_awcache         (),
                .s_axi4_awprot          (),
                .s_axi4_awqos           (),
                .s_axi4_awvalid         ('0),
                .s_axi4_awready         (),
                .s_axi4_wdata           (),
                .s_axi4_wstrb           (),
                .s_axi4_wlast           (),
                .s_axi4_wvalid          ('0),
                .s_axi4_wready          (),
                .s_axi4_bid             (),
                .s_axi4_bresp           (),
                .s_axi4_bvalid          (),
                .s_axi4_bready          ('0),
                
                .s_axi4_arid            (m_axi4_arid),
                .s_axi4_araddr          (m_axi4_araddr),
                .s_axi4_arlen           (m_axi4_arlen),
                .s_axi4_arsize          (m_axi4_arsize),
                .s_axi4_arburst         (m_axi4_arburst),
                .s_axi4_arlock          (m_axi4_arlock),
                .s_axi4_arcache         (m_axi4_arcache),
                .s_axi4_arprot          (m_axi4_arprot),
                .s_axi4_arqos           (m_axi4_arqos),
                .s_axi4_arvalid         (m_axi4_arvalid),
                .s_axi4_arready         (m_axi4_arready),
                .s_axi4_rid             (m_axi4_rid),
                .s_axi4_rdata           (m_axi4_rdata),
                .s_axi4_rresp           (m_axi4_rresp),
                .s_axi4_rlast           (m_axi4_rlast),
                .s_axi4_rvalid          (m_axi4_rvalid),
                .s_axi4_rready          (m_axi4_rready)
            );
    
endmodule


`default_nettype wire


// end of file
