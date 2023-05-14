// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2022 by Ryuz
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly2_texture_writer_core
        #(
            parameter   int                             COMPONENT_NUM        = 3,
            parameter   int                             COMPONENT_DATA_WIDTH = 8,

            parameter   int                             S_AXI4S_DATA_WIDTH   = COMPONENT_NUM * COMPONENT_DATA_WIDTH,

            parameter   int                             M_AXI4_ID_WIDTH      = 6,
            parameter   int                             M_AXI4_ADDR_WIDTH    = 32,
            parameter   int                             M_AXI4_DATA_SIZE     = 3,   // 0:8bit, 1:16bit, 2:32bit, 3:64bit, ... ...
            parameter   int                             M_AXI4_DATA_WIDTH    = (8 << M_AXI4_DATA_SIZE),
            parameter   int                             M_AXI4_STRB_WIDTH    = (1 << M_AXI4_DATA_SIZE),
            parameter   int                             M_AXI4_LEN_WIDTH     = 8,
            parameter   int                             M_AXI4_QOS_WIDTH     = 4,
            parameter   bit     [M_AXI4_ID_WIDTH-1:0]   M_AXI4_AWID          = {M_AXI4_ID_WIDTH{1'b0}},
            parameter   bit     [2:0]                   M_AXI4_AWSIZE        = 3'(M_AXI4_DATA_SIZE),
            parameter   bit     [1:0]                   M_AXI4_AWBURST       = 2'b01,
            parameter   bit     [0:0]                   M_AXI4_AWLOCK        = 1'b0,
            parameter   bit     [3:0]                   M_AXI4_AWCACHE       = 4'b0001,
            parameter   bit     [2:0]                   M_AXI4_AWPROT        = 3'b000,
            parameter   bit     [M_AXI4_QOS_WIDTH-1:0]  M_AXI4_AWQOS         = 0,
            parameter   bit     [3:0]                   M_AXI4_AWREGION      = 4'b0000,
            parameter   bit                             M_AXI4_AW_REGS       = 1,
            parameter   bit                             M_AXI4_W_REGS        = 1,
            parameter   int                             M_AXI4_COUNT_WIDTH   = 8,
            
            parameter   int                             BLK_X_SIZE           = 3,       // 2^n (0:1, 1:2, 2:4, 3:8, ... )
            parameter   int                             BLK_Y_SIZE           = 3,       // 2^n (0:1, 1:2, 2:4, 3:8, ... )
            parameter   int                             STEP_Y_SIZE          = 1,       // 2^n (0:1, 1:2, 2:4, 3:8, ... )
            
            parameter   int                             X_WIDTH              = 10,
            parameter   int                             Y_WIDTH              = 10,
                                    
            parameter   int                             STRIDE_C_WIDTH       = BLK_X_SIZE + BLK_Y_SIZE,
            parameter   int                             STRIDE_X_WIDTH       = BLK_X_SIZE + BLK_Y_SIZE + $clog2(COMPONENT_NUM),
            parameter   int                             STRIDE_Y_WIDTH       = X_WIDTH + BLK_Y_SIZE,
                                    
            parameter   int                             BUF_ADDR_WIDTH       = 1 + X_WIDTH + STEP_Y_SIZE,
            parameter                                   BUF_RAM_TYPE         = "block"
        )
        (
            input   wire                                reset,
            input   wire                                clk,
            
            input   wire                                endian,
            
            input   wire                                enable,
            output  wire                                busy,
            
            input   wire    [M_AXI4_ADDR_WIDTH-1:0]     param_addr,
            input   wire    [M_AXI4_LEN_WIDTH-1:0]      param_awlen,
            input   wire    [X_WIDTH-1:0]               param_width,
            input   wire    [Y_WIDTH-1:0]               param_height,
            input   wire    [STRIDE_C_WIDTH-1:0]        param_stride_c,
            input   wire    [STRIDE_X_WIDTH-1:0]        param_stride_x,
            input   wire    [STRIDE_Y_WIDTH-1:0]        param_stride_y,
            
            input   wire    [0:0]                       s_axi4s_tuser,
            input   wire                                s_axi4s_tlast,
            input   wire    [S_AXI4S_DATA_WIDTH-1:0]    s_axi4s_tdata,
            input   wire                                s_axi4s_tvalid,
            output  wire                                s_axi4s_tready,
            
            output  wire    [M_AXI4_ID_WIDTH-1:0]       m_axi4_awid,
            output  wire    [M_AXI4_ADDR_WIDTH-1:0]     m_axi4_awaddr,
            output  wire    [M_AXI4_LEN_WIDTH-1:0]      m_axi4_awlen,
            output  wire    [2:0]                       m_axi4_awsize,
            output  wire    [1:0]                       m_axi4_awburst,
            output  wire    [0:0]                       m_axi4_awlock,
            output  wire    [3:0]                       m_axi4_awcache,
            output  wire    [2:0]                       m_axi4_awprot,
            output  wire    [M_AXI4_QOS_WIDTH-1:0]      m_axi4_awqos,
            output  wire    [3:0]                       m_axi4_awregion,
            output  wire                                m_axi4_awvalid,
            input   wire                                m_axi4_awready,
            output  wire    [M_AXI4_DATA_WIDTH-1:0]     m_axi4_wdata,
            output  wire    [M_AXI4_STRB_WIDTH-1:0]     m_axi4_wstrb,
            output  wire                                m_axi4_wlast,
            output  wire                                m_axi4_wvalid,
            input   wire                                m_axi4_wready,
            input   wire    [M_AXI4_ID_WIDTH-1:0]       m_axi4_bid,
            input   wire    [1:0]                       m_axi4_bresp,
            input   wire                                m_axi4_bvalid,
            output  wire                                m_axi4_bready
        );
    
    
    // ---------------------------------
    //  common
    // ---------------------------------
        
    localparam  int     COMPONENT_SIZE      = $clog2((COMPONENT_DATA_WIDTH+7)/8);
    localparam  int     COMPONENT_SEL_WIDTH = $clog2(COMPONENT_NUM);
    localparam  int     BLK_NUM             = (1 << (M_AXI4_DATA_SIZE - COMPONENT_SIZE));
    
    
    // ---------------------------------
    //  line to blk
    // ---------------------------------
    
    logic                                                               blk_busy;

    logic   [COMPONENT_SEL_WIDTH-1:0]                                   blk_component;
    logic   [M_AXI4_ADDR_WIDTH-1:0]                                     blk_addr;
    logic   [BLK_NUM-1:0][COMPONENT_NUM-1:0][COMPONENT_DATA_WIDTH-1:0]  blk_data;
    logic                                                               blk_last;
    logic                                                               blk_valid;
    logic                                                               blk_ready;
    
    jelly2_texture_writer_line_to_blk
            #(
                .COMPONENT_NUM          (COMPONENT_NUM),
                .COMPONENT_SEL_WIDTH    (COMPONENT_SEL_WIDTH),
                .BLK_X_SIZE             (BLK_X_SIZE),
                .BLK_Y_SIZE             (BLK_Y_SIZE),
                .STEP_Y_SIZE            (STEP_Y_SIZE),
                
                .X_WIDTH                (X_WIDTH),
                .Y_WIDTH                (Y_WIDTH),
                .STRIDE_C_WIDTH         (STRIDE_C_WIDTH - COMPONENT_SIZE),
                .STRIDE_X_WIDTH         (STRIDE_X_WIDTH - COMPONENT_SIZE),
                .STRIDE_Y_WIDTH         (STRIDE_Y_WIDTH - COMPONENT_SIZE),
                
                .ADDR_WIDTH             (M_AXI4_ADDR_WIDTH),
                .S_DATA_WIDTH           (S_AXI4S_DATA_WIDTH),
                .M_DATA_SIZE            (M_AXI4_DATA_SIZE - COMPONENT_SIZE),
                
                .BUF_ADDR_WIDTH         (BUF_ADDR_WIDTH),
                .BUF_RAM_TYPE           (BUF_RAM_TYPE)
            )
        i_texture_writer_line_to_blk
            (
                .reset                  (reset),
                .clk                    (clk),
                
                .endian                 (endian),
                
                .enable                 (enable),
                .busy                   (blk_busy),
                
                .param_width            (param_width),
                .param_height           (param_height),
                .param_stride_c         (param_stride_c >> COMPONENT_SIZE),
                .param_stride_x         (param_stride_x >> COMPONENT_SIZE),
                .param_stride_y         (param_stride_y >> COMPONENT_SIZE),
                
                .s_first                (s_axi4s_tuser[0]),
                .s_data                 (s_axi4s_tdata),
                .s_valid                (s_axi4s_tvalid),
                .s_ready                (s_axi4s_tready),
                
                .m_component            (blk_component),
                .m_addr                 (blk_addr),
                .m_data                 (blk_data),
                .m_last                 (blk_last),
                .m_valid                (blk_valid),
                .m_ready                (blk_ready)
            );
    
    
    
    // ---------------------------------
    //  AXI4 Write
    // ---------------------------------
        
    logic   [M_AXI4_ADDR_WIDTH-1:0]                 reg_dma_addr;
    logic   [BLK_NUM-1:0][COMPONENT_DATA_WIDTH-1:0] reg_dma_data;
    logic                                           reg_dma_valid;
    logic                                           dma_ready;
    
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_dma_addr  <= {M_AXI4_ADDR_WIDTH{1'bx}};
            reg_dma_data  <= {M_AXI4_DATA_WIDTH{1'bx}};
            reg_dma_valid <= 1'b0;
        end
        else if ( blk_ready ) begin
            reg_dma_addr  <= param_addr + (blk_addr << COMPONENT_SIZE);
            for ( int i = 0; i < BLK_NUM; ++i ) begin
                reg_dma_data[i] <= blk_data[i][blk_component];
            end
            reg_dma_valid <= blk_valid;
        end
    end
    
    assign blk_ready = (!reg_dma_valid || dma_ready);
    
    jelly_texture_writer_axi4
            #(
                .M_AXI4_ID_WIDTH        (M_AXI4_ID_WIDTH),
                .M_AXI4_ADDR_WIDTH      (M_AXI4_ADDR_WIDTH),
                .M_AXI4_DATA_SIZE       (M_AXI4_DATA_SIZE),
                .M_AXI4_DATA_WIDTH      (M_AXI4_DATA_WIDTH),
                .M_AXI4_STRB_WIDTH      (M_AXI4_STRB_WIDTH),
                .M_AXI4_LEN_WIDTH       (M_AXI4_LEN_WIDTH),
                .M_AXI4_QOS_WIDTH       (M_AXI4_QOS_WIDTH),
                .M_AXI4_AWID            (M_AXI4_AWID),
                .M_AXI4_AWSIZE          (M_AXI4_AWSIZE),
                .M_AXI4_AWBURST         (M_AXI4_AWBURST),
                .M_AXI4_AWLOCK          (M_AXI4_AWLOCK),
                .M_AXI4_AWCACHE         (M_AXI4_AWCACHE),
                .M_AXI4_AWPROT          (M_AXI4_AWPROT),
                .M_AXI4_AWQOS           (M_AXI4_AWQOS),
                .M_AXI4_AWREGION        (M_AXI4_AWREGION),
                .M_REGS                 (1),
                .S_REGS                 (1)
            )
        i_texture_writer_axi4
            (
                .reset                  (reset),
                .clk                    (clk),
                
                .param_awlen            (param_awlen),
                
                .s_addr                 (reg_dma_addr),
                .s_data                 (reg_dma_data),
                .s_valid                (reg_dma_valid),
                .s_ready                (dma_ready),
                
                .m_axi4_awid            (m_axi4_awid),
                .m_axi4_awaddr          (m_axi4_awaddr),
                .m_axi4_awlen           (m_axi4_awlen),
                .m_axi4_awsize          (m_axi4_awsize),
                .m_axi4_awburst         (m_axi4_awburst),
                .m_axi4_awlock          (m_axi4_awlock),
                .m_axi4_awcache         (m_axi4_awcache),
                .m_axi4_awprot          (m_axi4_awprot),
                .m_axi4_awqos           (m_axi4_awqos),
                .m_axi4_awregion        (m_axi4_awregion),
                .m_axi4_awvalid         (m_axi4_awvalid),
                .m_axi4_awready         (m_axi4_awready),
                .m_axi4_wdata           (m_axi4_wdata),
                .m_axi4_wstrb           (m_axi4_wstrb),
                .m_axi4_wlast           (m_axi4_wlast),
                .m_axi4_wvalid          (m_axi4_wvalid),
                .m_axi4_wready          (m_axi4_wready),
                .m_axi4_bid             (m_axi4_bid),
                .m_axi4_bresp           (m_axi4_bresp),
                .m_axi4_bvalid          (m_axi4_bvalid),
                .m_axi4_bready          (m_axi4_bready)
            );
    
    
    // ---------------------------------
    //  detect write complete
    // ---------------------------------
    
    logic   [M_AXI4_COUNT_WIDTH-1:0]    reg_axi4_awcount;
    logic                               reg_axi4_awbusy;
    always_ff @(posedge clk) begin
        if ( reset ) begin
            reg_axi4_awcount <= {M_AXI4_COUNT_WIDTH{1'b0}};
            reg_axi4_awbusy  <= 1'b0;
        end
        else begin
            reg_axi4_awcount <= reg_axi4_awcount + M_AXI4_COUNT_WIDTH'(m_axi4_awvalid && m_axi4_awready) - M_AXI4_COUNT_WIDTH'(m_axi4_bvalid && m_axi4_bready);
            reg_axi4_awbusy  <= ((reg_axi4_awcount > 0 ) || m_axi4_awvalid);
        end
    end
    
    assign busy = (reg_axi4_awbusy || blk_busy);
    
endmodule


`default_nettype wire


// end of file
