

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
`define CORE_ID_VIDEO_NORMALIZER                32'h527A1220
`define CORE_ID_VIDEO_PARAMETER_UPDATE          32'h527A1F10
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
`define REG_BUF_MANAGER_CORE_ID                 32'h00
`define REG_BUF_MANAGER_CORE_VERSION            32'h01
`define REG_BUF_MANAGER_CORE_CONFIG             32'h03
`define REG_BUF_MANAGER_NEWEST_INDEX            32'h20
`define REG_BUF_MANAGER_WRITER_INDEX            32'h21
`define REG_BUF_MANAGER_BUFFER0_ADDR            32'h40
`define REG_BUF_MANAGER_BUFFER1_ADDR            32'h41
`define REG_BUF_MANAGER_BUFFER2_ADDR            32'h42
`define REG_BUF_MANAGER_BUFFER3_ADDR            32'h43
`define REG_BUF_MANAGER_BUFFER4_ADDR            32'h44
`define REG_BUF_MANAGER_BUFFER5_ADDR            32'h45
`define REG_BUF_MANAGER_BUFFER6_ADDR            32'h46
`define REG_BUF_MANAGER_BUFFER7_ADDR            32'h47
`define REG_BUF_MANAGER_BUFFER8_ADDR            32'h48
`define REG_BUF_MANAGER_BUFFER9_ADDR            32'h49
`define REG_BUF_MANAGER_BUFFER0_REFCNT          32'h80
`define REG_BUF_MANAGER_BUFFER1_REFCNT          32'h81
`define REG_BUF_MANAGER_BUFFER2_REFCNT          32'h82
`define REG_BUF_MANAGER_BUFFER3_REFCNT          32'h83
`define REG_BUF_MANAGER_BUFFER4_REFCNT          32'h84
`define REG_BUF_MANAGER_BUFFER5_REFCNT          32'h85
`define REG_BUF_MANAGER_BUFFER6_REFCNT          32'h86
`define REG_BUF_MANAGER_BUFFER7_REFCNT          32'h87
`define REG_BUF_MANAGER_BUFFER8_REFCNT          32'h88
`define REG_BUF_MANAGER_BUFFER9_REFCNT          32'h89
`define REG_BUF_MANAGER_BUFFER_ADDR(x)          (32'h40 + (x))
`define REG_BUF_MANAGER_BUFFER_REFCNT(x)        (32'h80 + (x))

/* buffer allocator */
`define REG_BUF_ALLOC_CORE_ID                   32'h00
`define REG_BUF_ALLOC_CORE_VERSION              32'h01
`define REG_BUF_ALLOC_CORE_CONFIG               32'h03
`define REG_BUF_ALLOC_BUFFER0_REQUEST           32'h20
`define REG_BUF_ALLOC_BUFFER0_RELEASE           32'h21
`define REG_BUF_ALLOC_BUFFER0_ADDR              32'h22
`define REG_BUF_ALLOC_BUFFER0_INDEX             32'h23
`define REG_BUF_ALLOC_BUFFER_REQUEST(x)         (32'h20 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_RELEASE(x)         (32'h21 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_ADDR(x)            (32'h22 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_INDEX(x)           (32'h23 + 4*(x))

/* DMA Stream write */
`define REG_DMA_WRITE_CORE_ID                   32'h00
`define REG_DMA_WRITE_CORE_VERSION              32'h01
`define REG_DMA_WRITE_CORE_CONFIG               32'h03
`define REG_DMA_WRITE_CTL_CONTROL               32'h04
`define REG_DMA_WRITE_CTL_STATUS                32'h05
`define REG_DMA_WRITE_CTL_INDEX                 32'h07
`define REG_DMA_WRITE_IRQ_ENABLE                32'h08
`define REG_DMA_WRITE_IRQ_STATUS                32'h09
`define REG_DMA_WRITE_IRQ_CLR                   32'h0a
`define REG_DMA_WRITE_IRQ_SET                   32'h0b
`define REG_DMA_WRITE_PARAM_AWADDR              32'h10
`define REG_DMA_WRITE_PARAM_AWOFFSET            32'h18
`define REG_DMA_WRITE_PARAM_AWLEN_MAX           32'h1c
`define REG_DMA_WRITE_PARAM_AWLEN0              32'h20
`define REG_DMA_WRITE_PARAM_AWLEN1              32'h24
`define REG_DMA_WRITE_PARAM_AWSTEP1             32'h25
`define REG_DMA_WRITE_PARAM_AWLEN2              32'h28
`define REG_DMA_WRITE_PARAM_AWSTEP2             32'h29
`define REG_DMA_WRITE_PARAM_AWLEN3              32'h2c
`define REG_DMA_WRITE_PARAM_AWSTEP3             32'h2d
`define REG_DMA_WRITE_PARAM_AWLEN4              32'h30
`define REG_DMA_WRITE_PARAM_AWSTEP4             32'h31
`define REG_DMA_WRITE_PARAM_AWLEN5              32'h34
`define REG_DMA_WRITE_PARAM_AWSTEP5             32'h35
`define REG_DMA_WRITE_PARAM_AWLEN6              32'h38
`define REG_DMA_WRITE_PARAM_AWSTEP6             32'h39
`define REG_DMA_WRITE_PARAM_AWLEN7              32'h3c
`define REG_DMA_WRITE_PARAM_AWSTEP7             32'h3d
`define REG_DMA_WRITE_PARAM_AWLEN8              32'h30
`define REG_DMA_WRITE_PARAM_AWSTEP8             32'h31
`define REG_DMA_WRITE_PARAM_AWLEN9              32'h44
`define REG_DMA_WRITE_PARAM_AWSTEP9             32'h45
`define REG_DMA_WRITE_WSKIP_EN                  32'h70
`define REG_DMA_WRITE_WDETECT_FIRST             32'h72
`define REG_DMA_WRITE_WDETECT_LAST              32'h73
`define REG_DMA_WRITE_WPADDING_EN               32'h74
`define REG_DMA_WRITE_WPADDING_DATA             32'h75
`define REG_DMA_WRITE_WPADDING_STRB             32'h76
`define REG_DMA_WRITE_SHADOW_AWADDR             32'h90
`define REG_DMA_WRITE_SHADOW_AWLEN_MAX          32'h91
`define REG_DMA_WRITE_SHADOW_AWLEN0             32'ha0
`define REG_DMA_WRITE_SHADOW_AWLEN1             32'ha4
`define REG_DMA_WRITE_SHADOW_AWSTEP1            32'ha5
`define REG_DMA_WRITE_SHADOW_AWLEN2             32'ha8
`define REG_DMA_WRITE_SHADOW_AWSTEP2            32'ha9
`define REG_DMA_WRITE_SHADOW_AWLEN3             32'hac
`define REG_DMA_WRITE_SHADOW_AWSTEP3            32'had
`define REG_DMA_WRITE_SHADOW_AWLEN4             32'hb0
`define REG_DMA_WRITE_SHADOW_AWSTEP4            32'hb1
`define REG_DMA_WRITE_SHADOW_AWLEN5             32'hb4
`define REG_DMA_WRITE_SHADOW_AWSTEP5            32'hb5
`define REG_DMA_WRITE_SHADOW_AWLEN6             32'hb8
`define REG_DMA_WRITE_SHADOW_AWSTEP6            32'hb9
`define REG_DMA_WRITE_SHADOW_AWLEN7             32'hbc
`define REG_DMA_WRITE_SHADOW_AWSTEP7            32'hbd
`define REG_DMA_WRITE_SHADOW_AWLEN8             32'hb0
`define REG_DMA_WRITE_SHADOW_AWSTEP8            32'hb1
`define REG_DMA_WRITE_SHADOW_AWLEN9             32'hc4
`define REG_DMA_WRITE_SHADOW_AWSTEP9            32'hc5

/* DMA Stream read */
`define REG_DMA_READ_CORE_ID                    32'h00
`define REG_DMA_READ_CORE_VERSION               32'h01
`define REG_DMA_READ_CORE_CONFIG                32'h03
`define REG_DMA_READ_CTL_CONTROL                32'h04
`define REG_DMA_READ_CTL_STATUS                 32'h05
`define REG_DMA_READ_CTL_INDEX                  32'h07
`define REG_DMA_READ_IRQ_ENABLE                 32'h08
`define REG_DMA_READ_IRQ_STATUS                 32'h09
`define REG_DMA_READ_IRQ_CLR                    32'h0a
`define REG_DMA_READ_IRQ_SET                    32'h0b
`define REG_DMA_READ_PARAM_ARADDR               32'h10
`define REG_DMA_READ_PARAM_AROFFSET             32'h18
`define REG_DMA_READ_PARAM_ARLEN_MAX            32'h1c
`define REG_DMA_READ_PARAM_ARLEN0               32'h20
`define REG_DMA_READ_PARAM_ARLEN1               32'h24
`define REG_DMA_READ_PARAM_ARSTEP1              32'h25
`define REG_DMA_READ_PARAM_ARLEN2               32'h28
`define REG_DMA_READ_PARAM_ARSTEP2              32'h29
`define REG_DMA_READ_PARAM_ARLEN3               32'h2c
`define REG_DMA_READ_PARAM_ARSTEP3              32'h2d
`define REG_DMA_READ_PARAM_ARLEN4               32'h30
`define REG_DMA_READ_PARAM_ARSTEP4              32'h31
`define REG_DMA_READ_PARAM_ARLEN5               32'h34
`define REG_DMA_READ_PARAM_ARSTEP5              32'h35
`define REG_DMA_READ_PARAM_ARLEN6               32'h38
`define REG_DMA_READ_PARAM_ARSTEP6              32'h39
`define REG_DMA_READ_PARAM_ARLEN7               32'h3c
`define REG_DMA_READ_PARAM_ARSTEP7              32'h3d
`define REG_DMA_READ_PARAM_ARLEN8               32'h30
`define REG_DMA_READ_PARAM_ARSTEP8              32'h31
`define REG_DMA_READ_PARAM_ARLEN9               32'h44
`define REG_DMA_READ_PARAM_ARSTEP9              32'h45
`define REG_DMA_READ_SHADOW_ARADDR              32'h90
`define REG_DMA_READ_SHADOW_ARLEN_MAX           32'h91
`define REG_DMA_READ_SHADOW_ARLEN0              32'ha0
`define REG_DMA_READ_SHADOW_ARLEN1              32'ha4
`define REG_DMA_READ_SHADOW_ARSTEP1             32'ha5
`define REG_DMA_READ_SHADOW_ARLEN2              32'ha8
`define REG_DMA_READ_SHADOW_ARSTEP2             32'ha9
`define REG_DMA_READ_SHADOW_ARLEN3              32'hac
`define REG_DMA_READ_SHADOW_ARSTEP3             32'had
`define REG_DMA_READ_SHADOW_ARLEN4              32'hb0
`define REG_DMA_READ_SHADOW_ARSTEP4             32'hb1
`define REG_DMA_READ_SHADOW_ARLEN5              32'hb4
`define REG_DMA_READ_SHADOW_ARSTEP5             32'hb5
`define REG_DMA_READ_SHADOW_ARLEN6              32'hb8
`define REG_DMA_READ_SHADOW_ARSTEP6             32'hb9
`define REG_DMA_READ_SHADOW_ARLEN7              32'hbc
`define REG_DMA_READ_SHADOW_ARSTEP7             32'hbd
`define REG_DMA_READ_SHADOW_ARLEN8              32'hb0
`define REG_DMA_READ_SHADOW_ARSTEP8             32'hb1
`define REG_DMA_READ_SHADOW_ARLEN9              32'hc4
`define REG_DMA_READ_SHADOW_ARSTEP9             32'hc5


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

`define CORE_ID_VIDEO_PRMUP                     32'h527a1f10
`define CORE_ID_VIDEO_WDMA                      32'h527a1020
`define CORE_ID_VIDEO_RDMA                      32'h527a1040
`define CORE_ID_VIDEO_FMTREG                    32'h527a1220


/* FIFO with DMA */
`define REG_DAM_FIFO_CORE_ID                    32'h00
`define REG_DAM_FIFO_CORE_VERSION               32'h01
`define REG_DAM_FIFO_CTL_CONTROL                32'h04
`define REG_DAM_FIFO_CTL_STATUS                 32'h05
`define REG_DAM_FIFO_CTL_INDEX                  32'h06
`define REG_DAM_FIFO_PARAM_ADDR                 32'h08
`define REG_DAM_FIFO_PARAM_SIZE                 32'h09
`define REG_DAM_FIFO_PARAM_AWLEN                32'h10
`define REG_DAM_FIFO_PARAM_WSTRB                32'h11
`define REG_DAM_FIFO_PARAM_WTIMEOUT             32'h13
`define REG_DAM_FIFO_PARAM_ARLEN                32'h14
`define REG_DAM_FIFO_PARAM_RTIMEOUT             32'h17
`define REG_DAM_FIFO_CURRENT_ADDR               32'h28
`define REG_DAM_FIFO_CURRENT_SIZE               32'h29
`define REG_DAM_FIFO_CURRENT_AWLEN              32'h30
`define REG_DAM_FIFO_CURRENT_WSTRB              32'h31
`define REG_DAM_FIFO_CURRENT_WTIMEOUT           32'h33
`define REG_DAM_FIFO_CURRENT_ARLEN              32'h34
`define REG_DAM_FIFO_CURRENT_RTIMEOUT           32'h37

/* parameter update control */
`define REG_VIDEO_PRMUP_CORE_ID                 32'h00
`define REG_VIDEO_PRMUP_CORE_VERSION            32'h01
`define REG_VIDEO_PRMUP_CONTROL                 32'h04
`define REG_VIDEO_PRMUP_INDEX                   32'h05
`define REG_VIDEO_PRMUP_FRAME_COUNT             32'h06

/* Video Write-DMA */
`define REG_VIDEO_WDMA_CORE_ID                  32'h00
`define REG_VIDEO_WDMA_VERSION                  32'h01
`define REG_VIDEO_WDMA_CTL_CONTROL              32'h04
`define REG_VIDEO_WDMA_CTL_STATUS               32'h05
`define REG_VIDEO_WDMA_CTL_INDEX                32'h07
`define REG_VIDEO_WDMA_PARAM_ADDR               32'h08
`define REG_VIDEO_WDMA_PARAM_STRIDE             32'h09
`define REG_VIDEO_WDMA_PARAM_WIDTH              32'h0a
`define REG_VIDEO_WDMA_PARAM_HEIGHT             32'h0b
`define REG_VIDEO_WDMA_PARAM_SIZE               32'h0c
`define REG_VIDEO_WDMA_PARAM_AWLEN              32'h0f
`define REG_VIDEO_WDMA_MONITOR_ADDR             32'h10
`define REG_VIDEO_WDMA_MONITOR_STRIDE           32'h11
`define REG_VIDEO_WDMA_MONITOR_WIDTH            32'h12
`define REG_VIDEO_WDMA_MONITOR_HEIGHT           32'h13
`define REG_VIDEO_WDMA_MONITOR_SIZE             32'h14
`define REG_VIDEO_WDMA_MONITOR_AWLEN            32'h17

/* Video Read-DMA */
`define REG_VIDEO_RDMA_CORE_ID                  32'h00
`define REG_VIDEO_RDMA_CORE_VERSION             32'h01
`define REG_VIDEO_RDMA_CTL_CONTROL              32'h04
`define REG_VIDEO_RDMA_CTL_STATUS               32'h05
`define REG_VIDEO_RDMA_CTL_INDEX                32'h06
`define REG_VIDEO_RDMA_PARAM_ADDR               32'h08
`define REG_VIDEO_RDMA_PARAM_STRIDE             32'h09
`define REG_VIDEO_RDMA_PARAM_WIDTH              32'h0a
`define REG_VIDEO_RDMA_PARAM_HEIGHT             32'h0b
`define REG_VIDEO_RDMA_PARAM_SIZE               32'h0c
`define REG_VIDEO_RDMA_PARAM_ARLEN              32'h0f
`define REG_VIDEO_RDMA_MONITOR_ADDR             32'h10
`define REG_VIDEO_RDMA_MONITOR_STRIDE           32'h11
`define REG_VIDEO_RDMA_MONITOR_WIDTH            32'h12
`define REG_VIDEO_RDMA_MONITOR_HEIGHT           32'h13
`define REG_VIDEO_RDMA_MONITOR_SIZE             32'h14
`define REG_VIDEO_RDMA_MONITOR_ARLEN            32'h17

/* Video format regularizer */
`define REG_VIDEO_FMTREG_CORE_ID                32'h00
`define REG_VIDEO_FMTREG_CORE_VERSION           32'h01
`define REG_VIDEO_FMTREG_CTL_CONTROL            32'h04
`define REG_VIDEO_FMTREG_CTL_STATUS             32'h05
`define REG_VIDEO_FMTREG_CTL_INDEX              32'h07
`define REG_VIDEO_FMTREG_CTL_SKIP               32'h08
`define REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN       32'h0a
`define REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT        32'h0b
`define REG_VIDEO_FMTREG_PARAM_WIDTH            32'h10
`define REG_VIDEO_FMTREG_PARAM_HEIGHT           32'h11
`define REG_VIDEO_FMTREG_PARAM_FILL             32'h12
`define REG_VIDEO_FMTREG_PARAM_TIMEOUT          32'h13

// Video sync generator
`define REG_VIDEO_VSGEN_CORE_ID                 32'h00
`define REG_VIDEO_VSGEN_CORE_VERSION            32'h01
`define REG_VIDEO_VSGEN_CTL_CONTROL             32'h04
`define REG_VIDEO_VSGEN_CTL_STATUS              32'h05
`define REG_VIDEO_VSGEN_PARAM_HTOTAL            32'h08
`define REG_VIDEO_VSGEN_PARAM_HSYNC_POL         32'h0B
`define REG_VIDEO_VSGEN_PARAM_HDISP_START       32'h0C
`define REG_VIDEO_VSGEN_PARAM_HDISP_END         32'h0D
`define REG_VIDEO_VSGEN_PARAM_HSYNC_START       32'h0E
`define REG_VIDEO_VSGEN_PARAM_HSYNC_END         32'h0F
`define REG_VIDEO_VSGEN_PARAM_VTOTAL            32'h10
`define REG_VIDEO_VSGEN_PARAM_VSYNC_POL         32'h13
`define REG_VIDEO_VSGEN_PARAM_VDISP_START       32'h14
`define REG_VIDEO_VSGEN_PARAM_VDISP_END         32'h15
`define REG_VIDEO_VSGEN_PARAM_VSYNC_START       32'h16
`define REG_VIDEO_VSGEN_PARAM_VSYNC_END         32'h17

// Video sync de adjuster
`define REG_VIDEO_ADJDE_CORE_ID                 32'h00
`define REG_VIDEO_ADJDE_CORE_VERSION            32'h01
`define REG_VIDEO_ADJDE_CTL_CONTROL             32'h04
`define REG_VIDEO_ADJDE_CTL_STATUS              32'h05
`define REG_VIDEO_ADJDE_CTL_INDEX               32'h07
`define REG_VIDEO_ADJDE_PARAM_HSIZE             32'h08
`define REG_VIDEO_ADJDE_PARAM_VSIZE             32'h09
`define REG_VIDEO_ADJDE_PARAM_HSTART            32'h0a
`define REG_VIDEO_ADJDE_PARAM_VSTART            32'h0b
`define REG_VIDEO_ADJDE_PARAM_HPOL              32'h0c
`define REG_VIDEO_ADJDE_PARAM_VPOL              32'h0d
`define REG_VIDEO_ADJDE_CURRENT_HSIZE           32'h18
`define REG_VIDEO_ADJDE_CURRENT_VSIZE           32'h19
`define REG_VIDEO_ADJDE_CURRENT_HSTART          32'h1a
`define REG_VIDEO_ADJDE_CURRENT_VSTART          32'h1b


/* ---------------------------------- */
/*  Image processing                  */
/* ---------------------------------- */

/* Demosaic */
`define REG_IMG_DEMOSAIC_CORE_ID                32'h00
`define REG_IMG_DEMOSAIC_CORE_VERSION           32'h01
`define REG_IMG_DEMOSAIC_CTL_CONTROL            32'h04
`define REG_IMG_DEMOSAIC_CTL_STATUS             32'h05
`define REG_IMG_DEMOSAIC_CTL_INDEX              32'h07
`define REG_IMG_DEMOSAIC_PARAM_PHASE            32'h08
`define REG_IMG_DEMOSAIC_CURRENT_PHASE          32'h18

/* color matrix */
`define REG_IMG_COLMAT_CORE_ID                  32'h00
`define REG_IMG_COLMAT_CORE_VERSION             32'h01
`define REG_IMG_COLMAT_CTL_CONTROL              32'h04
`define REG_IMG_COLMAT_CTL_STATUS               32'h05
`define REG_IMG_COLMAT_CTL_INDEX                32'h07
`define REG_IMG_COLMAT_PARAM_MATRIX00           32'h10
`define REG_IMG_COLMAT_PARAM_MATRIX01           32'h11
`define REG_IMG_COLMAT_PARAM_MATRIX02           32'h12
`define REG_IMG_COLMAT_PARAM_MATRIX03           32'h13
`define REG_IMG_COLMAT_PARAM_MATRIX10           32'h14
`define REG_IMG_COLMAT_PARAM_MATRIX11           32'h15
`define REG_IMG_COLMAT_PARAM_MATRIX12           32'h16
`define REG_IMG_COLMAT_PARAM_MATRIX13           32'h17
`define REG_IMG_COLMAT_PARAM_MATRIX20           32'h18
`define REG_IMG_COLMAT_PARAM_MATRIX21           32'h19
`define REG_IMG_COLMAT_PARAM_MATRIX22           32'h1a
`define REG_IMG_COLMAT_PARAM_MATRIX23           32'h1b
`define REG_IMG_COLMAT_PARAM_CLIP_MIN0          32'h20
`define REG_IMG_COLMAT_PARAM_CLIP_MAX0          32'h21
`define REG_IMG_COLMAT_PARAM_CLIP_MIN1          32'h22
`define REG_IMG_COLMAT_PARAM_CLIP_MAX1          32'h23
`define REG_IMG_COLMAT_PARAM_CLIP_MIN2          32'h24
`define REG_IMG_COLMAT_PARAM_CLIP_MAX2          32'h25
`define REG_IMG_COLMAT_CFG_COEFF0_WIDTH         32'h40
`define REG_IMG_COLMAT_CFG_COEFF1_WIDTH         32'h41
`define REG_IMG_COLMAT_CFG_COEFF2_WIDTH         32'h42
`define REG_IMG_COLMAT_CFG_COEFF3_WIDTH         32'h43
`define REG_IMG_COLMAT_CFG_COEFF0_FRAC_WIDTH    32'h44
`define REG_IMG_COLMAT_CFG_COEFF1_FRAC_WIDTH    32'h45
`define REG_IMG_COLMAT_CFG_COEFF2_FRAC_WIDTH    32'h46
`define REG_IMG_COLMAT_CFG_COEFF3_FRAC_WIDTH    32'h47
`define REG_IMG_COLMAT_CURRENT_MATRIX00         32'h90
`define REG_IMG_COLMAT_CURRENT_MATRIX01         32'h91
`define REG_IMG_COLMAT_CURRENT_MATRIX02         32'h92
`define REG_IMG_COLMAT_CURRENT_MATRIX03         32'h93
`define REG_IMG_COLMAT_CURRENT_MATRIX10         32'h94
`define REG_IMG_COLMAT_CURRENT_MATRIX11         32'h95
`define REG_IMG_COLMAT_CURRENT_MATRIX12         32'h96
`define REG_IMG_COLMAT_CURRENT_MATRIX13         32'h97
`define REG_IMG_COLMAT_CURRENT_MATRIX20         32'h98
`define REG_IMG_COLMAT_CURRENT_MATRIX21         32'h99
`define REG_IMG_COLMAT_CURRENT_MATRIX22         32'h9a
`define REG_IMG_COLMAT_CURRENT_MATRIX23         32'h9b
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN0        32'ha0
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX0        32'ha1
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN1        32'ha2
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX1        32'ha3
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN2        32'ha4
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX2        32'ha5

/* gamma  */
`define REG_IMG_GAMMA_CORE_ID                   32'h00
`define REG_IMG_GAMMA_CORE_VERSION              32'h01
`define REG_IMG_GAMMA_CTL_CONTROL               32'h04
`define REG_IMG_GAMMA_CTL_STATUS                32'h05
`define REG_IMG_GAMMA_CTL_INDEX                 32'h07
`define REG_IMG_GAMMA_PARAM_ENABLE              32'h08
`define REG_IMG_GAMMA_CURRENT_ENABLE            32'h18
`define REG_IMG_GAMMA_CFG_TBL_ADDR              32'h80
`define REG_IMG_GAMMA_CFG_TBL_SIZE              32'h81
`define REG_IMG_GAMMA_CFG_TBL_WIDTH             32'h82

/* gaussian 3x3 */
`define REG_IMG_GAUSS3X3_CORE_ID                32'h00
`define REG_IMG_GAUSS3X3_CORE_VERSION           32'h01
`define REG_IMG_GAUSS3X3_CTL_CONTROL            32'h04
`define REG_IMG_GAUSS3X3_CTL_STATUS             32'h05
`define REG_IMG_GAUSS3X3_CTL_INDEX              32'h07
`define REG_IMG_GAUSS3X3_PARAM_ENABLE           32'h08
`define REG_IMG_GAUSS3X3_CURRENT_ENABLE         32'h18

/* canny */
`define REG_IMG_CANNY_CORE_ID                   32'h00
`define REG_IMG_CANNY_CORE_VERSION              32'h01
`define REG_IMG_CANNY_CTL_CONTROL               32'h04
`define REG_IMG_CANNY_CTL_STATUS                32'h05
`define REG_IMG_CANNY_CTL_INDEX                 32'h07
`define REG_IMG_CANNY_PARAM_TH                  32'h08
`define REG_IMG_CANNY_CURRENT_TH                32'h18

/* binarizer */
`define REG_IMG_BINARIZER_CORE_ID               32'h00
`define REG_IMG_BINARIZER_CORE_VERSION          32'h01
`define REG_IMG_BINARIZER_CTL_CONTROL           32'h04
`define REG_IMG_BINARIZER_CTL_STATUS            32'h05
`define REG_IMG_BINARIZER_CTL_INDEX             32'h07
`define REG_IMG_BINARIZER_PARAM_TH              32'h08
`define REG_IMG_BINARIZER_PARAM_INV             32'h09
`define REG_IMG_BINARIZER_PARAM_VAL0            32'h0a
`define REG_IMG_BINARIZER_PARAM_VAL1            32'h0b
`define REG_IMG_BINARIZER_CURRENT_TH            32'h18
`define REG_IMG_BINARIZER_CURRENT_INV           32'h19
`define REG_IMG_BINARIZER_CURRENT_VAL0          32'h1a
`define REG_IMG_BINARIZER_CURRENT_VAL1          32'h1b

/* alpha blend */
`define REG_IMG_ALPHABLEND_CORE_ID              32'h00
`define REG_IMG_ALPHABLEND_CORE_VERSION         32'h01
`define REG_IMG_ALPHABLEND_CTL_CONTROL          32'h04
`define REG_IMG_ALPHABLEND_CTL_STATUS           32'h05
`define REG_IMG_ALPHABLEND_CTL_INDEX            32'h07
`define REG_IMG_ALPHABLEND_PARAM_ALPHA          32'h08
`define REG_IMG_ALPHABLEND_CURRENT_ALPHA        32'h18

/* area mask */
`define REG_IMG_AREAMASK_CORE_ID                32'h00
`define REG_IMG_AREAMASK_CORE_VERSION           32'h01
`define REG_IMG_AREAMASK_CTL_CONTROL            32'h04
`define REG_IMG_AREAMASK_CTL_STATUS             32'h05
`define REG_IMG_AREAMASK_CTL_INDEX              32'h07
`define REG_IMG_AREAMASK_PARAM_MASK_FLAG        32'h10
`define REG_IMG_AREAMASK_PARAM_MASK_VALUE0      32'h12
`define REG_IMG_AREAMASK_PARAM_MASK_VALUE1      32'h13
`define REG_IMG_AREAMASK_PARAM_THRESH_FLAG      32'h14
`define REG_IMG_AREAMASK_PARAM_THRESH_VALUE     32'h15
`define REG_IMG_AREAMASK_PARAM_RECT_FLAG        32'h21
`define REG_IMG_AREAMASK_PARAM_RECT_LEFT        32'h24
`define REG_IMG_AREAMASK_PARAM_RECT_RIGHT       32'h25
`define REG_IMG_AREAMASK_PARAM_RECT_TOP         32'h26
`define REG_IMG_AREAMASK_PARAM_RECT_BOTTOM      32'h27
`define REG_IMG_AREAMASK_PARAM_CIRCLE_FLAG      32'h50
`define REG_IMG_AREAMASK_PARAM_CIRCLE_X         32'h54
`define REG_IMG_AREAMASK_PARAM_CIRCLE_Y         32'h55
`define REG_IMG_AREAMASK_PARAM_CIRCLE_RADIUS2   32'h56
`define REG_IMG_AREAMASK_CURRENT_MASK_FLAG      32'h90
`define REG_IMG_AREAMASK_CURRENT_MASK_VALUE0    32'h92
`define REG_IMG_AREAMASK_CURRENT_MASK_VALUE1    32'h93
`define REG_IMG_AREAMASK_CURRENT_THRESH_FLAG    32'h94
`define REG_IMG_AREAMASK_CURRENT_THRESH_VALUE   32'h95
`define REG_IMG_AREAMASK_CURRENT_RECT_FLAG      32'ha1
`define REG_IMG_AREAMASK_CURRENT_RECT_LEFT      32'ha4
`define REG_IMG_AREAMASK_CURRENT_RECT_RIGHT     32'ha5
`define REG_IMG_AREAMASK_CURRENT_RECT_TOP       32'ha6
`define REG_IMG_AREAMASK_CURRENT_RECT_BOTTOM    32'ha7
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_FLAG    32'hd0
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_X       32'hd4
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_Y       32'hd5
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_RADIUS2 32'hd6

/* FIFO with DMA */
`define REG_IMG_PREVFRM_CORE_ID                 32'h00
`define REG_IMG_PREVFRM_CORE_VERSION            32'h01
`define REG_IMG_PREVFRM_CTL_CONTROL             32'h04
`define REG_IMG_PREVFRM_CTL_STATUS              32'h05
`define REG_IMG_PREVFRM_CTL_INDEX               32'h06
`define REG_IMG_PREVFRM_PARAM_ADDR              32'h08
`define REG_IMG_PREVFRM_PARAM_SIZE              32'h09
`define REG_IMG_PREVFRM_PARAM_AWLEN             32'h10
`define REG_IMG_PREVFRM_PARAM_WSTRB             32'h11
`define REG_IMG_PREVFRM_PARAM_WTIMEOUT          32'h13
`define REG_IMG_PREVFRM_PARAM_ARLEN             32'h14
`define REG_IMG_PREVFRM_PARAM_RTIMEOUT          32'h17
`define REG_IMG_PREVFRM_PARAM_INITDATA          32'h18
`define REG_IMG_PREVFRM_CURRENT_ADDR            32'h28
`define REG_IMG_PREVFRM_CURRENT_SIZE            32'h29
`define REG_IMG_PREVFRM_CURRENT_AWLEN           32'h30
`define REG_IMG_PREVFRM_CURRENT_WSTRB           32'h31
`define REG_IMG_PREVFRM_CURRENT_WTIMEOUT        32'h33
`define REG_IMG_PREVFRM_CURRENT_ARLEN           32'h34
`define REG_IMG_PREVFRM_CURRENT_RTIMEOUT        32'h37
`define REG_IMG_PREVFRM_CURRENT_INITDATA        32'h38

/* image selector */
`define REG_IMG_SELECTOR_CORE_ID                32'h00
`define REG_IMG_SELECTOR_CORE_VERSION           32'h01
`define REG_IMG_SELECTOR_CTL_SELECT             32'h08
`define REG_IMG_SELECTOR_CONFIG_NUM             32'h10


// end of file
