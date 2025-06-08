// ---------------------------------------------------------------------------
//  Jelly  -- The platform for real-time computing
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns/1ps
`default_nettype none



module jelly3_dma_video_write
        #(
            // control port(AXI4-Lite)
            parameter   bit                             AXI4L_ASYNC         = 1,
            parameter   int                             REGADR_BITS         = 8,
            
            // AXI4-Stream Video
            parameter   bit                             AXI4S_ASYNC          = 1,
            
            // AXI4 Memory
            parameter   int                             ADDR_BITS            = 49,
            parameter   int                             AXI4_AWID            = 0,
            parameter   bit     [0:0]                   AXI4_AWLOCK          = 1'b0,
            parameter   bit     [3:0]                   AXI4_AWCACHE         = 4'b0001,
            parameter   bit     [2:0]                   AXI4_AWPROT          = 3'b000,
            parameter   int                             AXI4_AWQOS           = 0,
            parameter   bit     [3:0]                   AXI4_AWREGION        = 4'b0000,
            parameter   int                             AXI4_ALIGN           = 12,  // 2^12 = 4k が境界
            
            // レジスタ構成など
            parameter   int                             INDEX_BITS           = 1,
            parameter   bit                             SIZE_OFFSET          = 1'b1,
            parameter   int                             H_SIZE_BITS          = 12,
            parameter   int                             V_SIZE_BITS          = 12,
            parameter   int                             F_SIZE_BITS          = 8,
            parameter   int                             LINE_STEP_BITS       = 16,
            parameter   int                             FRAME_STEP_BITS      = 32,
            
            // レジスタ初期値
            parameter   bit     [3:0]                   INIT_CTL_CONTROL      = 4'b0000,
            parameter   bit     [0:0]                   INIT_IRQ_ENABLE       = 1'b0,
            parameter   bit     [ADDR_BITS-1:0]         INIT_PARAM_ADDR       = 0,
            parameter   bit     [ADDR_BITS-1:0]         INIT_PARAM_OFFSET     = 0,
            parameter   bit     [7:0]                   INIT_PARAM_AWLEN_MAX  = 0,
            parameter   bit     [H_SIZE_BITS-1:0]       INIT_PARAM_H_SIZE     = 0,
            parameter   bit     [V_SIZE_BITS-1:0]       INIT_PARAM_V_SIZE     = 0,
            parameter   bit     [LINE_STEP_BITS-1:0]    INIT_PARAM_LINE_STEP  = 0,
            parameter   bit     [F_SIZE_BITS-1:0]       INIT_PARAM_F_SIZE     = 0,
            parameter   bit     [FRAME_STEP_BITS-1:0]   INIT_PARAM_FRAME_STEP = 0,
            parameter   bit                             INIT_SKIP_EN          = 1'b1,
            parameter   bit     [2:0]                   INIT_DETECT_FIRST     = 3'b010,
            parameter   bit     [2:0]                   INIT_DETECT_LAST      = 3'b001,
            parameter   bit                             INIT_PADDING_EN       = 1'b1,
            parameter                                   INIT_PADDING_DATA     = '0,
            parameter                                   INIT_PADDING_STRB     = '0,
            
            // 構成情報
            parameter                                   CORE_ID               = 32'h527a_0110,
            parameter                                   CORE_VERSION          = 32'h0000_0000,
            parameter   bit                             BYPASS_GATE           = 0,
            parameter   bit                             BYPASS_ALIGN          = 0,
            parameter   bit                             WDETECTOR_CHANGE      = 0,
            parameter   bit                             DETECTOR_ENABLE       = 1,
            parameter   bit                             ALLOW_UNALIGNED       = 1,
            parameter   int                             CAPACITY_BITS         = 32,
            parameter   int                             WFIFO_PTR_BITS        = 9,
            parameter                                   WFIFO_RAM_TYPE        = "block",
            parameter   bit                             WFIFO_LOW_DEALY       = 0,
            parameter   bit                             WFIFO_DOUT_REG        = 1,
            parameter   bit                             WFIFO_S_REG           = 0,
            parameter   bit                             WFIFO_M_REG           = 1,
            parameter   int                             AWFIFO_PTR_BITS       = 4,
            parameter                                   AWFIFO_RAM_TYPE       = "distributed",
            parameter   bit                             AWFIFO_LOW_DEALY      = 1,
            parameter   bit                             AWFIFO_DOUT_REG       = 1,
            parameter   bit                             AWFIFO_S_REG          = 1,
            parameter   bit                             AWFIFO_M_REG          = 1,
            parameter   int                             BFIFO_PTR_BITS        = 4,
            parameter                                   BFIFO_RAM_TYPE        = "distributed",
            parameter   bit                             BFIFO_LOW_DEALY       = 0,
            parameter   bit                             BFIFO_DOUT_REG        = 0,
            parameter   bit                             BFIFO_S_REG           = 0,
            parameter   bit                             BFIFO_M_REG           = 0,
            parameter   int                             SWFIFOPTR_BITS        = 4,
            parameter                                   SWFIFORAM_TYPE        = "distributed",
            parameter   bit                             SWFIFOLOW_DEALY       = 1,
            parameter   bit                             SWFIFODOUT_REG        = 0,
            parameter   bit                             SWFIFOS_REG           = 0,
            parameter   bit                             SWFIFOM_REG           = 0,
            parameter   int                             MBFIFO_PTR_BITS       = 4,
            parameter                                   MBFIFO_RAM_TYPE       = "distributed",
            parameter   bit                             MBFIFO_LOW_DEALY      = 1,
            parameter   bit                             MBFIFO_DOUT_REG       = 0,
            parameter   bit                             MBFIFO_S_REG          = 0,
            parameter   bit                             MBFIFO_M_REG          = 0,
            parameter   int                             WDATFIFO_PTR_BITS     = 4,
            parameter   bit                             WDATFIFO_DOUT_REG     = 0,
            parameter                                   WDATFIFO_RAM_TYPE     = "distributed",
            parameter   bit                             WDATFIFO_LOW_DEALY    = 1,
            parameter   bit                             WDATFIFO_S_REG        = 0,
            parameter   bit                             WDATFIFO_M_REG        = 0,
            parameter   bit                             WDAT_S_REG            = 0,
            parameter   bit                             WDAT_M_REG            = 1,
            parameter   int                             BACKFIFO_PTR_BITS     = 4,
            parameter   bit                             BACKFIFO_DOUT_REG     = 0,
            parameter                                   BACKFIFO_RAM_TYPE     = "distributed",
            parameter   bit                             BACKFIFO_LOW_DEALY    = 1,
            parameter   bit                             BACKFIFO_S_REG        = 0,
            parameter   bit                             BACKFIFO_M_REG        = 0,
            parameter   bit                             BACK_S_REG            = 0,
            parameter   bit                             BACK_M_REG            = 1,
            parameter   bit                             CONVERT_S_REG         = 0
        )
        (
            input   var logic                       endian,

            jelly3_axi4s_if.s                       s_axi4s,
            jelly3_axi4_if.mw                       m_axi4,

            jelly3_axi4l_if.s                       s_axi4l,
            output  var logic   [0:0]               out_irq,
            
            output  var logic                       buffer_request,
            output  var logic                       buffer_release,
            input   var logic    [ADDR_BITS-1:0]    buffer_addr
        );
    
    
    jelly3_dma_stream_write
            #(
                .N                      (3                      ),
                .AWADDR_BITS            (ADDR_BITS              ),
                
                .AXI4S_BYTE_BITS        (s_axi4s.BYTE_BITS      ),
                .AXI4S_DATA_BITS        (s_axi4s.DATA_BITS      ),
                .AXI4S_STRB_BITS        (s_axi4s.STRB_BITS      ),

                .AXI4L_ASYNC            (AXI4L_ASYNC            ),
                .REGADR_BITS            (REGADR_BITS            ),

                .AXI4S_ASYNC            (AXI4S_ASYNC            ),
                .AXI4S_VIDEO            (1'b1                   ),
                .AXI4S_USE_STRB         (1'b0                   ),
                .AXI4S_USE_FIRST        (1'b0                   ),
                .AXI4S_USE_LAST         (1'b1                   ),

                .AXI4_AWID              (AXI4_AWID              ),
                .AXI4_AWLOCK            (AXI4_AWLOCK            ),
                .AXI4_AWCACHE           (AXI4_AWCACHE           ),
                .AXI4_AWPROT            (AXI4_AWPROT            ),
                .AXI4_AWQOS             (AXI4_AWQOS             ),
                .AXI4_AWREGION          (AXI4_AWREGION          ),
                .AXI4_ALIGN             (AXI4_ALIGN             ),
                
                .INDEX_BITS             (INDEX_BITS             ),
                .AWLEN_OFFSET           (SIZE_OFFSET            ),
                .AWLEN0_BITS            (H_SIZE_BITS            ),
                .AWLEN1_BITS            (V_SIZE_BITS            ),
                .AWLEN2_BITS            (F_SIZE_BITS            ),
                .AWSTEP1_BITS           (LINE_STEP_BITS         ),
                .AWSTEP2_BITS           (FRAME_STEP_BITS        ),
                
                .INIT_CTL_CONTROL       (INIT_CTL_CONTROL       ),
                .INIT_IRQ_ENABLE        (INIT_IRQ_ENABLE        ),
                .INIT_PARAM_AWADDR      (INIT_PARAM_ADDR        ),
                .INIT_PARAM_AWOFFSET    (INIT_PARAM_OFFSET      ),
                .INIT_PARAM_AWLEN_MAX   (int'(INIT_PARAM_AWLEN_MAX)),
                .INIT_PARAM_AWLEN0      (INIT_PARAM_H_SIZE      ),
                .INIT_PARAM_AWLEN1      (INIT_PARAM_V_SIZE      ),
                .INIT_PARAM_AWSTEP1     (INIT_PARAM_LINE_STEP   ),
                .INIT_PARAM_AWLEN2      (INIT_PARAM_F_SIZE      ),
                .INIT_PARAM_AWSTEP2     (INIT_PARAM_FRAME_STEP  ),
                
                .INIT_WSKIP_EN          (INIT_SKIP_EN           ),
                .INIT_WDETECT_FIRST     (INIT_DETECT_FIRST      ),
                .INIT_WDETECT_LAST      (INIT_DETECT_LAST       ),
                .INIT_WPADDING_EN       (INIT_PADDING_EN        ),
                .INIT_WPADDING_DATA     (s_axi4s.DATA_BITS'(INIT_PADDING_DATA)),
                .INIT_WPADDING_STRB     (INIT_PADDING_STRB      ),
                
                .CORE_ID                (CORE_ID                ),
                .CORE_VERSION           (CORE_VERSION           ),
                .BYPASS_GATE            (BYPASS_GATE            ),
                .BYPASS_ALIGN           (BYPASS_ALIGN           ),
                .WDETECTOR_CHANGE       (WDETECTOR_CHANGE       ),
                .WDETECTOR_ENABLE       (DETECTOR_ENABLE        ),
                .ALLOW_UNALIGNED        (ALLOW_UNALIGNED        ),
                .CAPACITY_BITS          (CAPACITY_BITS          ),
                .WFIFO_PTR_BITS         (WFIFO_PTR_BITS         ),
                .WFIFO_RAM_TYPE         (WFIFO_RAM_TYPE         ),
                .WFIFO_LOW_DEALY        (WFIFO_LOW_DEALY        ),
                .WFIFO_DOUT_REG         (WFIFO_DOUT_REG         ),
                .WFIFO_S_REG            (WFIFO_S_REG            ),
                .WFIFO_M_REG            (WFIFO_M_REG            ),
                .AWFIFO_PTR_BITS        (AWFIFO_PTR_BITS        ),
                .AWFIFO_RAM_TYPE        (AWFIFO_RAM_TYPE        ),
                .AWFIFO_LOW_DEALY       (AWFIFO_LOW_DEALY       ),
                .AWFIFO_DOUT_REG        (AWFIFO_DOUT_REG        ),
                .AWFIFO_S_REG           (AWFIFO_S_REG           ),
                .AWFIFO_M_REG           (AWFIFO_M_REG           ),
                .BFIFO_PTR_BITS         (BFIFO_PTR_BITS         ),
                .BFIFO_RAM_TYPE         (BFIFO_RAM_TYPE         ),
                .BFIFO_LOW_DEALY        (BFIFO_LOW_DEALY        ),
                .BFIFO_DOUT_REG         (BFIFO_DOUT_REG         ),
                .BFIFO_S_REG            (BFIFO_S_REG            ),
                .BFIFO_M_REG            (BFIFO_M_REG            ),
                .SWFIFOPTR_BITS         (SWFIFOPTR_BITS         ),
                .SWFIFORAM_TYPE         (SWFIFORAM_TYPE         ),
                .SWFIFOLOW_DEALY        (SWFIFOLOW_DEALY        ),
                .SWFIFODOUT_REG         (SWFIFODOUT_REG         ),
                .SWFIFOS_REG            (SWFIFOS_REG            ),
                .SWFIFOM_REG            (SWFIFOM_REG            ),
                .MBFIFO_PTR_BITS        (MBFIFO_PTR_BITS        ),
                .MBFIFO_RAM_TYPE        (MBFIFO_RAM_TYPE        ),
                .MBFIFO_LOW_DEALY       (MBFIFO_LOW_DEALY       ),
                .MBFIFO_DOUT_REG        (MBFIFO_DOUT_REG        ),
                .MBFIFO_S_REG           (MBFIFO_S_REG           ),
                .MBFIFO_M_REG           (MBFIFO_M_REG           ),
                .WDATFIFO_PTR_BITS      (WDATFIFO_PTR_BITS      ),
                .WDATFIFO_DOUT_REG      (WDATFIFO_DOUT_REG      ),
                .WDATFIFO_RAM_TYPE      (WDATFIFO_RAM_TYPE      ),
                .WDATFIFO_LOW_DEALY     (WDATFIFO_LOW_DEALY     ),
                .WDATFIFO_S_REG         (WDATFIFO_S_REG         ),
                .WDATFIFO_M_REG         (WDATFIFO_M_REG         ),
                .WDAT_S_REG             (WDAT_S_REG             ),
                .WDAT_M_REG             (WDAT_M_REG             ),
                .BACKFIFO_PTR_BITS      (BACKFIFO_PTR_BITS      ),
                .BACKFIFO_DOUT_REG      (BACKFIFO_DOUT_REG      ),
                .BACKFIFO_RAM_TYPE      (BACKFIFO_RAM_TYPE      ),
                .BACKFIFO_LOW_DEALY     (BACKFIFO_LOW_DEALY     ),
                .BACKFIFO_S_REG         (BACKFIFO_S_REG         ),
                .BACKFIFO_M_REG         (BACKFIFO_M_REG         ),
                .BACK_S_REG             (BACK_S_REG             ),
                .BACK_M_REG             (BACK_M_REG             ),
                .CONVERT_S_REG          (CONVERT_S_REG          )
            )
        i_dma_stream_write
            (
                .endian             ,
                .s_axi4l            ,
                .s_axi4s            ,
                .m_axi4             ,
                .out_irq            ,
                .buffer_request     ,
                .buffer_release     ,
                .buffer_addr        
            );
    
endmodule


`default_nettype wire


// end of file
