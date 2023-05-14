

`ifndef	__RYUZ__JELLY__REGS__H__
`define	__RYUZ__JELLY__REGS__H__


/* ---------------------------------- */
/*  ID                                */
/* ---------------------------------- */

`define CORE_ID_BUFFER_MANAGER                  32'h527A0004
`define CORE_ID_BUFFER_ALLOCATOR                32'h527A0008
`define CORE_ID_DMA_STREAM_WRITE                32'h527A0110
`define CORE_ID_DMA_STREAM_READ                 32'h527A0120
`define CORE_ID_DMA_FIFO                        32'h527A0140
`define CORE_ID_VDMA_AXI4S_TO_AXI4              32'h527A1010
`define CORE_ID_VDMA_AXI4_TO_AXI4S              32'h527A1020
`define CORE_ID_VDMA_AXI4S_TO_AXI4S             32'h527A1040
`define CORE_ID_VIDEO_VIN                       32'h527A1110
`define CORE_ID_VIDEO_VOUT                      32'h527A1140
`define CORE_ID_VSYNC_GENERATOR                 32'h527A1150
`define CORE_ID_VSYNC_ADJUST_DE                 32'h527A1152
`define CORE_ID_VIDEO_PARAMETER_UPDATE          32'h527A1F10
`define CORE_ID_VIDEO_FMTREG                    32'h527A1220
`define CORE_ID_VIDEO_OVERLAY_BRAM              32'h527A2400
`define CORE_ID_IMG_PREVIOUS_FRAME              32'h527A2010
`define CORE_ID_IMG_DEMOSAIC_ACPI               32'h527A2110
`define CORE_ID_IMG_GAMMA_CORRECTION            32'h527A2120
`define CORE_ID_IMG_COLOR_MATRIX                32'h527A2130
`define CORE_ID_IMG_RGB_TO_GRAY                 32'h527A2150
`define CORE_ID_IMG_BINARIZER                   32'h527A2210
`define CORE_ID_IMG_GAUSSIAN_3X3                32'h527A2310
`define CORE_ID_IMG_SOBEL_CORE                  32'h527A2320
`define CORE_ID_IMG_SOBEL_CANNY                 32'h527A2330
`define CORE_ID_IMG_ALPHA_BELND                 32'h527A2340
`define CORE_ID_IMG_AREA_MASK                   32'h527A2820
`define CORE_ID_IMG_MASS_CENTER                 32'h527A2820
`define CORE_ID_IMG_SELECTOR                    32'h527A2F10



/* ---------------------------------- */
/*  DMA                               */
/* ---------------------------------- */

/* buffer manager */
`define REG_BUF_MANAGER_CORE_ID                 8'h00
`define REG_BUF_MANAGER_CORE_VERSION            8'h01
`define REG_BUF_MANAGER_CORE_CONFIG             8'h03
`define REG_BUF_MANAGER_NEWEST_INDEX            8'h20
`define REG_BUF_MANAGER_WRITER_INDEX            8'h21
`define REG_BUF_MANAGER_BUFFER0_ADDR            8'h40
`define REG_BUF_MANAGER_BUFFER1_ADDR            8'h41
`define REG_BUF_MANAGER_BUFFER2_ADDR            8'h42
`define REG_BUF_MANAGER_BUFFER3_ADDR            8'h43
`define REG_BUF_MANAGER_BUFFER4_ADDR            8'h44
`define REG_BUF_MANAGER_BUFFER5_ADDR            8'h45
`define REG_BUF_MANAGER_BUFFER6_ADDR            8'h46
`define REG_BUF_MANAGER_BUFFER7_ADDR            8'h47
`define REG_BUF_MANAGER_BUFFER8_ADDR            8'h48
`define REG_BUF_MANAGER_BUFFER9_ADDR            8'h49
`define REG_BUF_MANAGER_BUFFER0_REFCNT          8'h80
`define REG_BUF_MANAGER_BUFFER1_REFCNT          8'h81
`define REG_BUF_MANAGER_BUFFER2_REFCNT          8'h82
`define REG_BUF_MANAGER_BUFFER3_REFCNT          8'h83
`define REG_BUF_MANAGER_BUFFER4_REFCNT          8'h84
`define REG_BUF_MANAGER_BUFFER5_REFCNT          8'h85
`define REG_BUF_MANAGER_BUFFER6_REFCNT          8'h86
`define REG_BUF_MANAGER_BUFFER7_REFCNT          8'h87
`define REG_BUF_MANAGER_BUFFER8_REFCNT          8'h88
`define REG_BUF_MANAGER_BUFFER9_REFCNT          8'h89
`define REG_BUF_MANAGER_BUFFER_ADDR(x)          (8'h40 + (x))
`define REG_BUF_MANAGER_BUFFER_REFCNT(x)        (8'h80 + (x))

/* buffer allocator */
`define REG_BUF_ALLOC_CORE_ID                   8'h00
`define REG_BUF_ALLOC_CORE_VERSION              8'h01
`define REG_BUF_ALLOC_CORE_CONFIG               8'h03
`define REG_BUF_ALLOC_BUFFER0_REQUEST           8'h20
`define REG_BUF_ALLOC_BUFFER0_RELEASE           8'h21
`define REG_BUF_ALLOC_BUFFER0_ADDR              8'h22
`define REG_BUF_ALLOC_BUFFER0_INDEX             8'h23
`define REG_BUF_ALLOC_BUFFER_REQUEST(x)         (8'h20 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_RELEASE(x)         (8'h21 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_ADDR(x)            (8'h22 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_INDEX(x)           (8'h23 + 4*(x))

/* DMA Stream write */
`define REG_DMA_WRITE_CORE_ID                   8'h00
`define REG_DMA_WRITE_CORE_VERSION              8'h01
`define REG_DMA_WRITE_CORE_CONFIG               8'h03
`define REG_DMA_WRITE_CTL_CONTROL               8'h04
`define REG_DMA_WRITE_CTL_STATUS                8'h05
`define REG_DMA_WRITE_CTL_INDEX                 8'h07
`define REG_DMA_WRITE_IRQ_ENABLE                8'h08
`define REG_DMA_WRITE_IRQ_STATUS                8'h09
`define REG_DMA_WRITE_IRQ_CLR                   8'h0a
`define REG_DMA_WRITE_IRQ_SET                   8'h0b
`define REG_DMA_WRITE_PARAM_AWADDR              8'h10
`define REG_DMA_WRITE_PARAM_AWOFFSET            8'h18
`define REG_DMA_WRITE_PARAM_AWLEN_MAX           8'h1c
`define REG_DMA_WRITE_PARAM_AWLEN0              8'h20
`define REG_DMA_WRITE_PARAM_AWLEN1              8'h24
`define REG_DMA_WRITE_PARAM_AWSTEP1             8'h25
`define REG_DMA_WRITE_PARAM_AWLEN2              8'h28
`define REG_DMA_WRITE_PARAM_AWSTEP2             8'h29
`define REG_DMA_WRITE_PARAM_AWLEN3              8'h2c
`define REG_DMA_WRITE_PARAM_AWSTEP3             8'h2d
`define REG_DMA_WRITE_PARAM_AWLEN4              8'h30
`define REG_DMA_WRITE_PARAM_AWSTEP4             8'h31
`define REG_DMA_WRITE_PARAM_AWLEN5              8'h34
`define REG_DMA_WRITE_PARAM_AWSTEP5             8'h35
`define REG_DMA_WRITE_PARAM_AWLEN6              8'h38
`define REG_DMA_WRITE_PARAM_AWSTEP6             8'h39
`define REG_DMA_WRITE_PARAM_AWLEN7              8'h3c
`define REG_DMA_WRITE_PARAM_AWSTEP7             8'h3d
`define REG_DMA_WRITE_PARAM_AWLEN8              8'h30
`define REG_DMA_WRITE_PARAM_AWSTEP8             8'h31
`define REG_DMA_WRITE_PARAM_AWLEN9              8'h44
`define REG_DMA_WRITE_PARAM_AWSTEP9             8'h45
`define REG_DMA_WRITE_WSKIP_EN                  8'h70
`define REG_DMA_WRITE_WDETECT_FIRST             8'h72
`define REG_DMA_WRITE_WDETECT_LAST              8'h73
`define REG_DMA_WRITE_WPADDING_EN               8'h74
`define REG_DMA_WRITE_WPADDING_DATA             8'h75
`define REG_DMA_WRITE_WPADDING_STRB             8'h76
`define REG_DMA_WRITE_SHADOW_AWADDR             8'h90
`define REG_DMA_WRITE_SHADOW_AWLEN_MAX          8'h91
`define REG_DMA_WRITE_SHADOW_AWLEN0             8'ha0
`define REG_DMA_WRITE_SHADOW_AWLEN1             8'ha4
`define REG_DMA_WRITE_SHADOW_AWSTEP1            8'ha5
`define REG_DMA_WRITE_SHADOW_AWLEN2             8'ha8
`define REG_DMA_WRITE_SHADOW_AWSTEP2            8'ha9
`define REG_DMA_WRITE_SHADOW_AWLEN3             8'hac
`define REG_DMA_WRITE_SHADOW_AWSTEP3            8'had
`define REG_DMA_WRITE_SHADOW_AWLEN4             8'hb0
`define REG_DMA_WRITE_SHADOW_AWSTEP4            8'hb1
`define REG_DMA_WRITE_SHADOW_AWLEN5             8'hb4
`define REG_DMA_WRITE_SHADOW_AWSTEP5            8'hb5
`define REG_DMA_WRITE_SHADOW_AWLEN6             8'hb8
`define REG_DMA_WRITE_SHADOW_AWSTEP6            8'hb9
`define REG_DMA_WRITE_SHADOW_AWLEN7             8'hbc
`define REG_DMA_WRITE_SHADOW_AWSTEP7            8'hbd
`define REG_DMA_WRITE_SHADOW_AWLEN8             8'hb0
`define REG_DMA_WRITE_SHADOW_AWSTEP8            8'hb1
`define REG_DMA_WRITE_SHADOW_AWLEN9             8'hc4
`define REG_DMA_WRITE_SHADOW_AWSTEP9            8'hc5

/* DMA Stream read */
`define REG_DMA_READ_CORE_ID                    8'h00
`define REG_DMA_READ_CORE_VERSION               8'h01
`define REG_DMA_READ_CORE_CONFIG                8'h03
`define REG_DMA_READ_CTL_CONTROL                8'h04
`define REG_DMA_READ_CTL_STATUS                 8'h05
`define REG_DMA_READ_CTL_INDEX                  8'h07
`define REG_DMA_READ_IRQ_ENABLE                 8'h08
`define REG_DMA_READ_IRQ_STATUS                 8'h09
`define REG_DMA_READ_IRQ_CLR                    8'h0a
`define REG_DMA_READ_IRQ_SET                    8'h0b
`define REG_DMA_READ_PARAM_ARADDR               8'h10
`define REG_DMA_READ_PARAM_AROFFSET             8'h18
`define REG_DMA_READ_PARAM_ARLEN_MAX            8'h1c
`define REG_DMA_READ_PARAM_ARLEN0               8'h20
`define REG_DMA_READ_PARAM_ARLEN1               8'h24
`define REG_DMA_READ_PARAM_ARSTEP1              8'h25
`define REG_DMA_READ_PARAM_ARLEN2               8'h28
`define REG_DMA_READ_PARAM_ARSTEP2              8'h29
`define REG_DMA_READ_PARAM_ARLEN3               8'h2c
`define REG_DMA_READ_PARAM_ARSTEP3              8'h2d
`define REG_DMA_READ_PARAM_ARLEN4               8'h30
`define REG_DMA_READ_PARAM_ARSTEP4              8'h31
`define REG_DMA_READ_PARAM_ARLEN5               8'h34
`define REG_DMA_READ_PARAM_ARSTEP5              8'h35
`define REG_DMA_READ_PARAM_ARLEN6               8'h38
`define REG_DMA_READ_PARAM_ARSTEP6              8'h39
`define REG_DMA_READ_PARAM_ARLEN7               8'h3c
`define REG_DMA_READ_PARAM_ARSTEP7              8'h3d
`define REG_DMA_READ_PARAM_ARLEN8               8'h30
`define REG_DMA_READ_PARAM_ARSTEP8              8'h31
`define REG_DMA_READ_PARAM_ARLEN9               8'h44
`define REG_DMA_READ_PARAM_ARSTEP9              8'h45
`define REG_DMA_READ_SHADOW_ARADDR              8'h90
`define REG_DMA_READ_SHADOW_ARLEN_MAX           8'h91
`define REG_DMA_READ_SHADOW_ARLEN0              8'ha0
`define REG_DMA_READ_SHADOW_ARLEN1              8'ha4
`define REG_DMA_READ_SHADOW_ARSTEP1             8'ha5
`define REG_DMA_READ_SHADOW_ARLEN2              8'ha8
`define REG_DMA_READ_SHADOW_ARSTEP2             8'ha9
`define REG_DMA_READ_SHADOW_ARLEN3              8'hac
`define REG_DMA_READ_SHADOW_ARSTEP3             8'had
`define REG_DMA_READ_SHADOW_ARLEN4              8'hb0
`define REG_DMA_READ_SHADOW_ARSTEP4             8'hb1
`define REG_DMA_READ_SHADOW_ARLEN5              8'hb4
`define REG_DMA_READ_SHADOW_ARSTEP5             8'hb5
`define REG_DMA_READ_SHADOW_ARLEN6              8'hb8
`define REG_DMA_READ_SHADOW_ARSTEP6             8'hb9
`define REG_DMA_READ_SHADOW_ARLEN7              8'hbc
`define REG_DMA_READ_SHADOW_ARSTEP7             8'hbd
`define REG_DMA_READ_SHADOW_ARLEN8              8'hb0
`define REG_DMA_READ_SHADOW_ARSTEP8             8'hb1
`define REG_DMA_READ_SHADOW_ARLEN9              8'hc4
`define REG_DMA_READ_SHADOW_ARSTEP9             8'hc5


/* DMA Video write */
`define REG_VDMA_WRITE_CORE_ID                  `REG_DMA_WRITE_CORE_ID
`define REG_VDMA_WRITE_CORE_VERSION             `REG_DMA_WRITE_CORE_VERSION
`define REG_VDMA_WRITE_CORE_CONFIG              `REG_DMA_WRITE_CORE_CONFIG
`define REG_VDMA_WRITE_CTL_CONTROL              `REG_DMA_WRITE_CTL_CONTROL
`define REG_VDMA_WRITE_CTL_STATUS               `REG_DMA_WRITE_CTL_STATUS
`define REG_VDMA_WRITE_CTL_INDEX                `REG_DMA_WRITE_CTL_INDEX
`define REG_VDMA_WRITE_IRQ_ENABLE               `REG_DMA_WRITE_IRQ_ENABLE
`define REG_VDMA_WRITE_IRQ_STATUS               `REG_DMA_WRITE_IRQ_STATUS
`define REG_VDMA_WRITE_IRQ_CLR                  `REG_DMA_WRITE_IRQ_CLR
`define REG_VDMA_WRITE_IRQ_SET                  `REG_DMA_WRITE_IRQ_SET
`define REG_VDMA_WRITE_PARAM_ADDR               `REG_DMA_WRITE_PARAM_AWADDR
`define REG_VDMA_WRITE_PARAM_OFFSET             `REG_DMA_WRITE_PARAM_AWOFFSET
`define REG_VDMA_WRITE_PARAM_AWLEN_MAX          `REG_DMA_WRITE_PARAM_AWLEN_MAX
`define REG_VDMA_WRITE_PARAM_H_SIZE             `REG_DMA_WRITE_PARAM_AWLEN0
`define REG_VDMA_WRITE_PARAM_V_SIZE             `REG_DMA_WRITE_PARAM_AWLEN1
`define REG_VDMA_WRITE_PARAM_LINE_STEP          `REG_DMA_WRITE_PARAM_AWSTEP1
`define REG_VDMA_WRITE_PARAM_F_SIZE             `REG_DMA_WRITE_PARAM_AWLEN2
`define REG_VDMA_WRITE_PARAM_FRAME_STEP         `REG_DMA_WRITE_PARAM_AWSTEP2
`define REG_VDMA_WRITE_SKIP_EN                  `REG_DMA_WRITE_WSKIP_EN
`define REG_VDMA_WRITE_DETECT_FIRST             `REG_DMA_WRITE_WDETECT_FIRST
`define REG_VDMA_WRITE_DETECT_LAST              `REG_DMA_WRITE_WDETECT_LAST
`define REG_VDMA_WRITE_PADDING_EN               `REG_DMA_WRITE_WPADDING_EN
`define REG_VDMA_WRITE_PADDING_DATA             `REG_DMA_WRITE_WPADDING_DATA
`define REG_VDMA_WRITE_PADDING_STRB             `REG_DMA_WRITE_WPADDING_STRB
`define REG_VDMA_WRITE_SHADOW_ADDR              `REG_DMA_WRITE_SHADOW_AWADDR
`define REG_VDMA_WRITE_SHADOW_AWLEN_MAX         `REG_DMA_WRITE_SHADOW_AWLEN_MAX
`define REG_VDMA_WRITE_SHADOW_H_SIZE            `REG_DMA_WRITE_SHADOW_AWLEN0
`define REG_VDMA_WRITE_SHADOW_V_SIZE            `REG_DMA_WRITE_SHADOW_AWLEN1
`define REG_VDMA_WRITE_SHADOW_LINE_STEP         `REG_DMA_WRITE_SHADOW_AWSTEP1
`define REG_VDMA_WRITE_SHADOW_F_SIZE            `REG_DMA_WRITE_SHADOW_AWLEN2
`define REG_VDMA_WRITE_SHADOW_FRAME_STEP        `REG_DMA_WRITE_SHADOW_AWSTEP2

/* DMA Video read */
`define REG_VDMA_READ_CORE_ID                   `REG_DMA_READ_CORE_ID
`define REG_VDMA_READ_CORE_VERSION              `REG_DMA_READ_CORE_VERSION
`define REG_VDMA_READ_CORE_CONFIG               `REG_DMA_READ_CORE_CONFIG
`define REG_VDMA_READ_CTL_CONTROL               `REG_DMA_READ_CTL_CONTROL
`define REG_VDMA_READ_CTL_STATUS                `REG_DMA_READ_CTL_STATUS
`define REG_VDMA_READ_CTL_INDEX                 `REG_DMA_READ_CTL_INDEX
`define REG_VDMA_READ_IRQ_ENABLE                `REG_DMA_READ_IRQ_ENABLE
`define REG_VDMA_READ_IRQ_STATUS                `REG_DMA_READ_IRQ_STATUS
`define REG_VDMA_READ_IRQ_CLR                   `REG_DMA_READ_IRQ_CLR
`define REG_VDMA_READ_IRQ_SET                   `REG_DMA_READ_IRQ_SET
`define REG_VDMA_READ_PARAM_ADDR                `REG_DMA_READ_PARAM_ARADDR
`define REG_VDMA_READ_PARAM_OFFSET              `REG_DMA_READ_PARAM_AROFFSET
`define REG_VDMA_READ_PARAM_ARLEN_MAX           `REG_DMA_READ_PARAM_ARLEN_MAX
`define REG_VDMA_READ_PARAM_H_SIZE              `REG_DMA_READ_PARAM_ARLEN0
`define REG_VDMA_READ_PARAM_V_SIZE              `REG_DMA_READ_PARAM_ARLEN1
`define REG_VDMA_READ_PARAM_LINE_STEP           `REG_DMA_READ_PARAM_ARSTEP1
`define REG_VDMA_READ_PARAM_F_SIZE              `REG_DMA_READ_PARAM_ARLEN2
`define REG_VDMA_READ_PARAM_FRAME_STEP          `REG_DMA_READ_PARAM_ARSTEP2
`define REG_VDMA_READ_SHADOW_ADDR               `REG_DMA_READ_SHADOW_ARADDR
`define REG_VDMA_READ_SHADOW_ARLEN_MAX          `REG_DMA_READ_SHADOW_ARLEN_MAX
`define REG_VDMA_READ_SHADOW_H_SIZE             `REG_DMA_READ_SHADOW_ARLEN0
`define REG_VDMA_READ_SHADOW_V_SIZE             `REG_DMA_READ_SHADOW_ARLEN1
`define REG_VDMA_READ_SHADOW_LINE_STEP          `REG_DMA_READ_SHADOW_ARSTEP1
`define REG_VDMA_READ_SHADOW_F_SIZE             `REG_DMA_READ_SHADOW_ARLEN2
`define REG_VDMA_READ_SHADOW_FRAME_STEP         `REG_DMA_READ_SHADOW_ARSTEP2



/* ---------------------------------- */
/*  Video                             */
/* ---------------------------------- */

/* FIFO with DMA */
`define REG_DAM_FIFO_CORE_ID                    8'h00
`define REG_DAM_FIFO_CORE_VERSION               8'h01
`define REG_DAM_FIFO_CTL_CONTROL                8'h04
`define REG_DAM_FIFO_CTL_STATUS                 8'h05
`define REG_DAM_FIFO_CTL_INDEX                  8'h06
`define REG_DAM_FIFO_PARAM_ADDR                 8'h08
`define REG_DAM_FIFO_PARAM_SIZE                 8'h09
`define REG_DAM_FIFO_PARAM_AWLEN                8'h10
`define REG_DAM_FIFO_PARAM_WSTRB                8'h11
`define REG_DAM_FIFO_PARAM_WTIMEOUT             8'h13
`define REG_DAM_FIFO_PARAM_ARLEN                8'h14
`define REG_DAM_FIFO_PARAM_RTIMEOUT             8'h17
`define REG_DAM_FIFO_CURRENT_ADDR               8'h28
`define REG_DAM_FIFO_CURRENT_SIZE               8'h29
`define REG_DAM_FIFO_CURRENT_AWLEN              8'h30
`define REG_DAM_FIFO_CURRENT_WSTRB              8'h31
`define REG_DAM_FIFO_CURRENT_WTIMEOUT           8'h33
`define REG_DAM_FIFO_CURRENT_ARLEN              8'h34
`define REG_DAM_FIFO_CURRENT_RTIMEOUT           8'h37

/* parameter update control */
`define REG_VIDEO_PRMUP_CORE_ID                 8'h00
`define REG_VIDEO_PRMUP_CORE_VERSION            8'h01
`define REG_VIDEO_PRMUP_CONTROL                 8'h04
`define REG_VIDEO_PRMUP_INDEX                   8'h05
`define REG_VIDEO_PRMUP_FRAME_COUNT             8'h06

/* Video Write-DMA */
`define REG_VIDEO_WDMA_CORE_ID                  8'h00
`define REG_VIDEO_WDMA_VERSION                  8'h01
`define REG_VIDEO_WDMA_CTL_CONTROL              8'h04
`define REG_VIDEO_WDMA_CTL_STATUS               8'h05
`define REG_VIDEO_WDMA_CTL_INDEX                8'h07
`define REG_VIDEO_WDMA_PARAM_ADDR               8'h08
`define REG_VIDEO_WDMA_PARAM_STRIDE             8'h09
`define REG_VIDEO_WDMA_PARAM_WIDTH              8'h0a
`define REG_VIDEO_WDMA_PARAM_HEIGHT             8'h0b
`define REG_VIDEO_WDMA_PARAM_SIZE               8'h0c
`define REG_VIDEO_WDMA_PARAM_AWLEN              8'h0f
`define REG_VIDEO_WDMA_MONITOR_ADDR             8'h10
`define REG_VIDEO_WDMA_MONITOR_STRIDE           8'h11
`define REG_VIDEO_WDMA_MONITOR_WIDTH            8'h12
`define REG_VIDEO_WDMA_MONITOR_HEIGHT           8'h13
`define REG_VIDEO_WDMA_MONITOR_SIZE             8'h14
`define REG_VIDEO_WDMA_MONITOR_AWLEN            8'h17

/* Video Read-DMA */
`define REG_VIDEO_RDMA_CORE_ID                  8'h00
`define REG_VIDEO_RDMA_CORE_VERSION             8'h01
`define REG_VIDEO_RDMA_CTL_CONTROL              8'h04
`define REG_VIDEO_RDMA_CTL_STATUS               8'h05
`define REG_VIDEO_RDMA_CTL_INDEX                8'h06
`define REG_VIDEO_RDMA_PARAM_ADDR               8'h08
`define REG_VIDEO_RDMA_PARAM_STRIDE             8'h09
`define REG_VIDEO_RDMA_PARAM_WIDTH              8'h0a
`define REG_VIDEO_RDMA_PARAM_HEIGHT             8'h0b
`define REG_VIDEO_RDMA_PARAM_SIZE               8'h0c
`define REG_VIDEO_RDMA_PARAM_ARLEN              8'h0f
`define REG_VIDEO_RDMA_MONITOR_ADDR             8'h10
`define REG_VIDEO_RDMA_MONITOR_STRIDE           8'h11
`define REG_VIDEO_RDMA_MONITOR_WIDTH            8'h12
`define REG_VIDEO_RDMA_MONITOR_HEIGHT           8'h13
`define REG_VIDEO_RDMA_MONITOR_SIZE             8'h14
`define REG_VIDEO_RDMA_MONITOR_ARLEN            8'h17

/* Video format regularizer */
`define REG_VIDEO_FMTREG_CORE_ID                8'h00
`define REG_VIDEO_FMTREG_CORE_VERSION           8'h01
`define REG_VIDEO_FMTREG_CTL_CONTROL            8'h04
`define REG_VIDEO_FMTREG_CTL_STATUS             8'h05
`define REG_VIDEO_FMTREG_CTL_INDEX              8'h07
`define REG_VIDEO_FMTREG_CTL_SKIP               8'h08
`define REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN       8'h0a
`define REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT        8'h0b
`define REG_VIDEO_FMTREG_PARAM_WIDTH            8'h10
`define REG_VIDEO_FMTREG_PARAM_HEIGHT           8'h11
`define REG_VIDEO_FMTREG_PARAM_FILL             8'h12
`define REG_VIDEO_FMTREG_PARAM_TIMEOUT          8'h13

/* Video sync generator */
`define REG_VIDEO_VSGEN_CORE_ID                 8'h00
`define REG_VIDEO_VSGEN_CORE_VERSION            8'h01
`define REG_VIDEO_VSGEN_CTL_CONTROL             8'h04
`define REG_VIDEO_VSGEN_CTL_STATUS              8'h05
`define REG_VIDEO_VSGEN_PARAM_HTOTAL            8'h08
`define REG_VIDEO_VSGEN_PARAM_HSYNC_POL         8'h0B
`define REG_VIDEO_VSGEN_PARAM_HDISP_START       8'h0C
`define REG_VIDEO_VSGEN_PARAM_HDISP_END         8'h0D
`define REG_VIDEO_VSGEN_PARAM_HSYNC_START       8'h0E
`define REG_VIDEO_VSGEN_PARAM_HSYNC_END         8'h0F
`define REG_VIDEO_VSGEN_PARAM_VTOTAL            8'h10
`define REG_VIDEO_VSGEN_PARAM_VSYNC_POL         8'h13
`define REG_VIDEO_VSGEN_PARAM_VDISP_START       8'h14
`define REG_VIDEO_VSGEN_PARAM_VDISP_END         8'h15
`define REG_VIDEO_VSGEN_PARAM_VSYNC_START       8'h16
`define REG_VIDEO_VSGEN_PARAM_VSYNC_END         8'h17

/* Video sync de adjuster */
`define REG_VIDEO_ADJDE_CORE_ID                 8'h00
`define REG_VIDEO_ADJDE_CORE_VERSION            8'h01
`define REG_VIDEO_ADJDE_CTL_CONTROL             8'h04
`define REG_VIDEO_ADJDE_CTL_STATUS              8'h05
`define REG_VIDEO_ADJDE_CTL_INDEX               8'h07
`define REG_VIDEO_ADJDE_PARAM_HSIZE             8'h08
`define REG_VIDEO_ADJDE_PARAM_VSIZE             8'h09
`define REG_VIDEO_ADJDE_PARAM_HSTART            8'h0a
`define REG_VIDEO_ADJDE_PARAM_VSTART            8'h0b
`define REG_VIDEO_ADJDE_PARAM_HPOL              8'h0c
`define REG_VIDEO_ADJDE_PARAM_VPOL              8'h0d
`define REG_VIDEO_ADJDE_CURRENT_HSIZE           8'h18
`define REG_VIDEO_ADJDE_CURRENT_VSIZE           8'h19
`define REG_VIDEO_ADJDE_CURRENT_HSTART          8'h1a
`define REG_VIDEO_ADJDE_CURRENT_VSTART          8'h1b

`define REG_VIDEO_BINARIZER_CORE_ID             8'h00
`define REG_VIDEO_BINARIZER_CORE_VERSION        8'h01
`define REG_VIDEO_BINARIZER_CTL_CONTROL         8'h04
`define REG_VIDEO_BINARIZER_CTL_STATUS          8'h05
`define REG_VIDEO_BINARIZER_CTL_INDEX           8'h07
`define REG_VIDEO_BINARIZER_PARAM_TH            8'h10
`define REG_VIDEO_BINARIZER_PARAM_INV           8'h11

`define REG_VIDEO_OVERLAY_CORE_ID               8'h00
`define REG_VIDEO_OVERLAY_CORE_VERSION          8'h01
`define REG_VIDEO_OVERLAY_CTL_CONTROL           8'h04
`define REG_VIDEO_OVERLAY_CTL_STATUS            8'h05
`define REG_VIDEO_OVERLAY_CTL_INDEX             8'h07
`define REG_VIDEO_OVERLAY_PARAM_X               8'h08
`define REG_VIDEO_OVERLAY_PARAM_Y               8'h09
`define REG_VIDEO_OVERLAY_PARAM_WIDTH           8'h0a
`define REG_VIDEO_OVERLAY_PARAM_HEIGHT          8'h0b
`define REG_VIDEO_OVERLAY_PARAM_BG_EN           8'h0e
`define REG_VIDEO_OVERLAY_PARAM_BG_DATA         8'h0f


/* ---------------------------------- */
/*  Image processing                  */
/* ---------------------------------- */

/* Demosaic */
`define REG_IMG_DEMOSAIC_CORE_ID                8'h00
`define REG_IMG_DEMOSAIC_CORE_VERSION           8'h01
`define REG_IMG_DEMOSAIC_CTL_CONTROL            8'h04
`define REG_IMG_DEMOSAIC_CTL_STATUS             8'h05
`define REG_IMG_DEMOSAIC_CTL_INDEX              8'h07
`define REG_IMG_DEMOSAIC_PARAM_PHASE            8'h08
`define REG_IMG_DEMOSAIC_CURRENT_PHASE          8'h18

/* color matrix */
`define REG_IMG_COLMAT_CORE_ID                  8'h00
`define REG_IMG_COLMAT_CORE_VERSION             8'h01
`define REG_IMG_COLMAT_CTL_CONTROL              8'h04
`define REG_IMG_COLMAT_CTL_STATUS               8'h05
`define REG_IMG_COLMAT_CTL_INDEX                8'h07
`define REG_IMG_COLMAT_PARAM_MATRIX00           8'h10
`define REG_IMG_COLMAT_PARAM_MATRIX01           8'h11
`define REG_IMG_COLMAT_PARAM_MATRIX02           8'h12
`define REG_IMG_COLMAT_PARAM_MATRIX03           8'h13
`define REG_IMG_COLMAT_PARAM_MATRIX10           8'h14
`define REG_IMG_COLMAT_PARAM_MATRIX11           8'h15
`define REG_IMG_COLMAT_PARAM_MATRIX12           8'h16
`define REG_IMG_COLMAT_PARAM_MATRIX13           8'h17
`define REG_IMG_COLMAT_PARAM_MATRIX20           8'h18
`define REG_IMG_COLMAT_PARAM_MATRIX21           8'h19
`define REG_IMG_COLMAT_PARAM_MATRIX22           8'h1a
`define REG_IMG_COLMAT_PARAM_MATRIX23           8'h1b
`define REG_IMG_COLMAT_PARAM_CLIP_MIN0          8'h20
`define REG_IMG_COLMAT_PARAM_CLIP_MAX0          8'h21
`define REG_IMG_COLMAT_PARAM_CLIP_MIN1          8'h22
`define REG_IMG_COLMAT_PARAM_CLIP_MAX1          8'h23
`define REG_IMG_COLMAT_PARAM_CLIP_MIN2          8'h24
`define REG_IMG_COLMAT_PARAM_CLIP_MAX2          8'h25
`define REG_IMG_COLMAT_CFG_COEFF0_WIDTH         8'h40
`define REG_IMG_COLMAT_CFG_COEFF1_WIDTH         8'h41
`define REG_IMG_COLMAT_CFG_COEFF2_WIDTH         8'h42
`define REG_IMG_COLMAT_CFG_COEFF3_WIDTH         8'h43
`define REG_IMG_COLMAT_CFG_COEFF0_FRAC_WIDTH    8'h44
`define REG_IMG_COLMAT_CFG_COEFF1_FRAC_WIDTH    8'h45
`define REG_IMG_COLMAT_CFG_COEFF2_FRAC_WIDTH    8'h46
`define REG_IMG_COLMAT_CFG_COEFF3_FRAC_WIDTH    8'h47
`define REG_IMG_COLMAT_CURRENT_MATRIX00         8'h90
`define REG_IMG_COLMAT_CURRENT_MATRIX01         8'h91
`define REG_IMG_COLMAT_CURRENT_MATRIX02         8'h92
`define REG_IMG_COLMAT_CURRENT_MATRIX03         8'h93
`define REG_IMG_COLMAT_CURRENT_MATRIX10         8'h94
`define REG_IMG_COLMAT_CURRENT_MATRIX11         8'h95
`define REG_IMG_COLMAT_CURRENT_MATRIX12         8'h96
`define REG_IMG_COLMAT_CURRENT_MATRIX13         8'h97
`define REG_IMG_COLMAT_CURRENT_MATRIX20         8'h98
`define REG_IMG_COLMAT_CURRENT_MATRIX21         8'h99
`define REG_IMG_COLMAT_CURRENT_MATRIX22         8'h9a
`define REG_IMG_COLMAT_CURRENT_MATRIX23         8'h9b
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN0        8'ha0
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX0        8'ha1
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN1        8'ha2
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX1        8'ha3
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN2        8'ha4
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX2        8'ha5

/* gamma  */
`define REG_IMG_GAMMA_CORE_ID                   8'h00
`define REG_IMG_GAMMA_CORE_VERSION              8'h01
`define REG_IMG_GAMMA_CTL_CONTROL               8'h04
`define REG_IMG_GAMMA_CTL_STATUS                8'h05
`define REG_IMG_GAMMA_CTL_INDEX                 8'h07
`define REG_IMG_GAMMA_PARAM_ENABLE              8'h08
`define REG_IMG_GAMMA_CURRENT_ENABLE            8'h18
`define REG_IMG_GAMMA_CFG_TBL_ADDR              8'h80
`define REG_IMG_GAMMA_CFG_TBL_SIZE              8'h81
`define REG_IMG_GAMMA_CFG_TBL_WIDTH             8'h82

/* gaussian 3x3 */
`define REG_IMG_GAUSS3X3_CORE_ID                8'h00
`define REG_IMG_GAUSS3X3_CORE_VERSION           8'h01
`define REG_IMG_GAUSS3X3_CTL_CONTROL            8'h04
`define REG_IMG_GAUSS3X3_CTL_STATUS             8'h05
`define REG_IMG_GAUSS3X3_CTL_INDEX              8'h07
`define REG_IMG_GAUSS3X3_PARAM_ENABLE           8'h08
`define REG_IMG_GAUSS3X3_CURRENT_ENABLE         8'h18

/* canny */
`define REG_IMG_CANNY_CORE_ID                   8'h00
`define REG_IMG_CANNY_CORE_VERSION              8'h01
`define REG_IMG_CANNY_CTL_CONTROL               8'h04
`define REG_IMG_CANNY_CTL_STATUS                8'h05
`define REG_IMG_CANNY_CTL_INDEX                 8'h07
`define REG_IMG_CANNY_PARAM_TH                  8'h08
`define REG_IMG_CANNY_CURRENT_TH                8'h18

/* binarizer */
`define REG_IMG_BINARIZER_CORE_ID               8'h00
`define REG_IMG_BINARIZER_CORE_VERSION          8'h01
`define REG_IMG_BINARIZER_CTL_CONTROL           8'h04
`define REG_IMG_BINARIZER_CTL_STATUS            8'h05
`define REG_IMG_BINARIZER_CTL_INDEX             8'h07
`define REG_IMG_BINARIZER_PARAM_TH              8'h08
`define REG_IMG_BINARIZER_PARAM_INV             8'h09
`define REG_IMG_BINARIZER_PARAM_VAL0            8'h0a
`define REG_IMG_BINARIZER_PARAM_VAL1            8'h0b
`define REG_IMG_BINARIZER_CURRENT_TH            8'h18
`define REG_IMG_BINARIZER_CURRENT_INV           8'h19
`define REG_IMG_BINARIZER_CURRENT_VAL0          8'h1a
`define REG_IMG_BINARIZER_CURRENT_VAL1          8'h1b

/* alpha blend */
`define REG_IMG_ALPHABLEND_CORE_ID              8'h00
`define REG_IMG_ALPHABLEND_CORE_VERSION         8'h01
`define REG_IMG_ALPHABLEND_CTL_CONTROL          8'h04
`define REG_IMG_ALPHABLEND_CTL_STATUS           8'h05
`define REG_IMG_ALPHABLEND_CTL_INDEX            8'h07
`define REG_IMG_ALPHABLEND_PARAM_ALPHA          8'h08
`define REG_IMG_ALPHABLEND_CURRENT_ALPHA        8'h18

/* area mask */
`define REG_IMG_AREAMASK_CORE_ID                8'h00
`define REG_IMG_AREAMASK_CORE_VERSION           8'h01
`define REG_IMG_AREAMASK_CTL_CONTROL            8'h04
`define REG_IMG_AREAMASK_CTL_STATUS             8'h05
`define REG_IMG_AREAMASK_CTL_INDEX              8'h07
`define REG_IMG_AREAMASK_PARAM_MASK_FLAG        8'h10
`define REG_IMG_AREAMASK_PARAM_MASK_VALUE0      8'h12
`define REG_IMG_AREAMASK_PARAM_MASK_VALUE1      8'h13
`define REG_IMG_AREAMASK_PARAM_THRESH_FLAG      8'h14
`define REG_IMG_AREAMASK_PARAM_THRESH_VALUE     8'h15
`define REG_IMG_AREAMASK_PARAM_RECT_FLAG        8'h21
`define REG_IMG_AREAMASK_PARAM_RECT_LEFT        8'h24
`define REG_IMG_AREAMASK_PARAM_RECT_RIGHT       8'h25
`define REG_IMG_AREAMASK_PARAM_RECT_TOP         8'h26
`define REG_IMG_AREAMASK_PARAM_RECT_BOTTOM      8'h27
`define REG_IMG_AREAMASK_PARAM_CIRCLE_FLAG      8'h50
`define REG_IMG_AREAMASK_PARAM_CIRCLE_X         8'h54
`define REG_IMG_AREAMASK_PARAM_CIRCLE_Y         8'h55
`define REG_IMG_AREAMASK_PARAM_CIRCLE_RADIUS2   8'h56
`define REG_IMG_AREAMASK_CURRENT_MASK_FLAG      8'h90
`define REG_IMG_AREAMASK_CURRENT_MASK_VALUE0    8'h92
`define REG_IMG_AREAMASK_CURRENT_MASK_VALUE1    8'h93
`define REG_IMG_AREAMASK_CURRENT_THRESH_FLAG    8'h94
`define REG_IMG_AREAMASK_CURRENT_THRESH_VALUE   8'h95
`define REG_IMG_AREAMASK_CURRENT_RECT_FLAG      8'ha1
`define REG_IMG_AREAMASK_CURRENT_RECT_LEFT      8'ha4
`define REG_IMG_AREAMASK_CURRENT_RECT_RIGHT     8'ha5
`define REG_IMG_AREAMASK_CURRENT_RECT_TOP       8'ha6
`define REG_IMG_AREAMASK_CURRENT_RECT_BOTTOM    8'ha7
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_FLAG    8'hd0
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_X       8'hd4
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_Y       8'hd5
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_RADIUS2 8'hd6

/* FIFO with DMA */
`define REG_IMG_PREVFRM_CORE_ID                 8'h00
`define REG_IMG_PREVFRM_CORE_VERSION            8'h01
`define REG_IMG_PREVFRM_CTL_CONTROL             8'h04
`define REG_IMG_PREVFRM_CTL_STATUS              8'h05
`define REG_IMG_PREVFRM_CTL_INDEX               8'h06
`define REG_IMG_PREVFRM_PARAM_ADDR              8'h08
`define REG_IMG_PREVFRM_PARAM_SIZE              8'h09
`define REG_IMG_PREVFRM_PARAM_AWLEN             8'h10
`define REG_IMG_PREVFRM_PARAM_WSTRB             8'h11
`define REG_IMG_PREVFRM_PARAM_WTIMEOUT          8'h13
`define REG_IMG_PREVFRM_PARAM_ARLEN             8'h14
`define REG_IMG_PREVFRM_PARAM_RTIMEOUT          8'h17
`define REG_IMG_PREVFRM_PARAM_INITDATA          8'h18
`define REG_IMG_PREVFRM_CURRENT_ADDR            8'h28
`define REG_IMG_PREVFRM_CURRENT_SIZE            8'h29
`define REG_IMG_PREVFRM_CURRENT_AWLEN           8'h30
`define REG_IMG_PREVFRM_CURRENT_WSTRB           8'h31
`define REG_IMG_PREVFRM_CURRENT_WTIMEOUT        8'h33
`define REG_IMG_PREVFRM_CURRENT_ARLEN           8'h34
`define REG_IMG_PREVFRM_CURRENT_RTIMEOUT        8'h37
`define REG_IMG_PREVFRM_CURRENT_INITDATA        8'h38

/* image selector */
`define REG_IMG_SELECTOR_CORE_ID                8'h00
`define REG_IMG_SELECTOR_CORE_VERSION           8'h01
`define REG_IMG_SELECTOR_CTL_SELECT             8'h08
`define REG_IMG_SELECTOR_CONFIG_NUM             8'h10


/* ---------------------------------- */
/*  Peripherals                       */
/* ---------------------------------- */

/* I2C */
`define REG_PERIPHERAL_I2C_STATUS               8'h00
`define REG_PERIPHERAL_I2C_CONTROL              8'h01
`define REG_PERIPHERAL_I2C_SEND                 8'h02
`define REG_PERIPHERAL_I2C_RECV                 8'h03
`define REG_PERIPHERAL_I2C_DIVIDER              8'h04

`define PERIPHERAL_I2C_CONTROL_START            8'h01
`define PERIPHERAL_I2C_CONTROL_STOP             8'h02
`define PERIPHERAL_I2C_CONTROL_ACK              8'h04
`define PERIPHERAL_I2C_CONTROL_NAK              8'h08
`define PERIPHERAL_I2C_CONTROL_RECV             8'h10




/* ---------------------------------- */
/*  Miscellaneous                     */
/* ---------------------------------- */

`define REG_LOGGER_CORE_ID                      8'h00
`define REG_LOGGER_CORE_VERSION                 8'h01
`define REG_LOGGER_CTL_CONTROL                  8'h04
`define REG_LOGGER_CTL_STATUS                   8'h05
`define REG_LOGGER_CTL_COUNT                    8'h07
`define REG_LOGGER_LIMIT_SIZE                   8'h08
`define REG_LOGGER_READ_DATA                    8'h10
`define REG_LOGGER_POL_TIMER0                   8'h18
`define REG_LOGGER_POL_TIMER1                   8'h19
`define REG_LOGGER_POL_DATA(x)                  (8'h20+(x))

`define REG_COMMUNICATION_PIPE_CORE_ID          8'h00
`define REG_COMMUNICATION_PIPE_CORE_VERSION     8'h01
`define REG_COMMUNICATION_PIPE_CORE_DATE        8'h02
`define REG_COMMUNICATION_PIPE_CORE_SERIAL      8'h03
`define REG_COMMUNICATION_PIPE_TX_DATA          8'h10
`define REG_COMMUNICATION_PIPE_TX_STATUS        8'h11
`define REG_COMMUNICATION_PIPE_TX_FREE_COUNT    8'h12
`define REG_COMMUNICATION_PIPE_TX_IRQ_STATUS    8'h14
`define REG_COMMUNICATION_PIPE_TX_IRQ_ENABLE    8'h15
`define REG_COMMUNICATION_PIPE_RX_DATA          8'h18
`define REG_COMMUNICATION_PIPE_RX_STATUS        8'h19
`define REG_COMMUNICATION_PIPE_RX_FREE_COUNT    8'h1a
`define REG_COMMUNICATION_PIPE_RX_IRQ_STATUS    8'h1c
`define REG_COMMUNICATION_PIPE_RX_IRQ_ENABLE    8'h1d

`define REG_MONITORPINCTL_CORE_ID               8'h00
`define REG_MONITORPINCTL_CORE_VERSION          8'h01
`define REG_MONITORPINCTL_IN_DATA(n)            (8'h10+(n))
`define REG_MONITORPINCTL_SELECT(n)             (8'h20+(n)*4)
`define REG_MONITORPINCTL_OVERRIDE(n)           (8'h21+(n)*4)
`define REG_MONITORPINCTL_OUT_VALUE(n)          (8'h22+(n)*4)
`define REG_MONITORPINCTL_MONITOR(n)            (8'h23+(n)*4)

`endif	/* __RYUZ__JELLY__REGS__H__ */


/* end of file */
