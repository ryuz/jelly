

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
`define REG_BUF_MANAGER_CORE_ID                 'h00
`define REG_BUF_MANAGER_CORE_VERSION            'h01
`define REG_BUF_MANAGER_CORE_CONFIG             'h03
`define REG_BUF_MANAGER_NEWEST_INDEX            'h20
`define REG_BUF_MANAGER_WRITER_INDEX            'h21
`define REG_BUF_MANAGER_BUFFER0_ADDR            'h40
`define REG_BUF_MANAGER_BUFFER1_ADDR            'h41
`define REG_BUF_MANAGER_BUFFER2_ADDR            'h42
`define REG_BUF_MANAGER_BUFFER3_ADDR            'h43
`define REG_BUF_MANAGER_BUFFER4_ADDR            'h44
`define REG_BUF_MANAGER_BUFFER5_ADDR            'h45
`define REG_BUF_MANAGER_BUFFER6_ADDR            'h46
`define REG_BUF_MANAGER_BUFFER7_ADDR            'h47
`define REG_BUF_MANAGER_BUFFER8_ADDR            'h48
`define REG_BUF_MANAGER_BUFFER9_ADDR            'h49
`define REG_BUF_MANAGER_BUFFER0_REFCNT          'h80
`define REG_BUF_MANAGER_BUFFER1_REFCNT          'h81
`define REG_BUF_MANAGER_BUFFER2_REFCNT          'h82
`define REG_BUF_MANAGER_BUFFER3_REFCNT          'h83
`define REG_BUF_MANAGER_BUFFER4_REFCNT          'h84
`define REG_BUF_MANAGER_BUFFER5_REFCNT          'h85
`define REG_BUF_MANAGER_BUFFER6_REFCNT          'h86
`define REG_BUF_MANAGER_BUFFER7_REFCNT          'h87
`define REG_BUF_MANAGER_BUFFER8_REFCNT          'h88
`define REG_BUF_MANAGER_BUFFER9_REFCNT          'h89
`define REG_BUF_MANAGER_BUFFER_ADDR(x)          ('h40 + (x))
`define REG_BUF_MANAGER_BUFFER_REFCNT(x)        ('h80 + (x))

/* buffer allocator */
`define REG_BUF_ALLOC_CORE_ID                   'h00
`define REG_BUF_ALLOC_CORE_VERSION              'h01
`define REG_BUF_ALLOC_CORE_CONFIG               'h03
`define REG_BUF_ALLOC_BUFFER0_REQUEST           'h20
`define REG_BUF_ALLOC_BUFFER0_RELEASE           'h21
`define REG_BUF_ALLOC_BUFFER0_ADDR              'h22
`define REG_BUF_ALLOC_BUFFER0_INDEX             'h23
`define REG_BUF_ALLOC_BUFFER_REQUEST(x)         ('h20 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_RELEASE(x)         ('h21 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_ADDR(x)            ('h22 + 4*(x))
`define REG_BUF_ALLOC_BUFFER_INDEX(x)           ('h23 + 4*(x))

/* DMA Stream write */
`define REG_DMA_WRITE_CORE_ID                   'h00
`define REG_DMA_WRITE_CORE_VERSION              'h01
`define REG_DMA_WRITE_CORE_CONFIG               'h03
`define REG_DMA_WRITE_CTL_CONTROL               'h04
`define REG_DMA_WRITE_CTL_STATUS                'h05
`define REG_DMA_WRITE_CTL_INDEX                 'h07
`define REG_DMA_WRITE_IRQ_ENABLE                'h08
`define REG_DMA_WRITE_IRQ_STATUS                'h09
`define REG_DMA_WRITE_IRQ_CLR                   'h0a
`define REG_DMA_WRITE_IRQ_SET                   'h0b
`define REG_DMA_WRITE_PARAM_AWADDR              'h10
`define REG_DMA_WRITE_PARAM_AWOFFSET            'h18
`define REG_DMA_WRITE_PARAM_AWLEN_MAX           'h1c
`define REG_DMA_WRITE_PARAM_AWLEN0              'h20
`define REG_DMA_WRITE_PARAM_AWLEN1              'h24
`define REG_DMA_WRITE_PARAM_AWSTEP1             'h25
`define REG_DMA_WRITE_PARAM_AWLEN2              'h28
`define REG_DMA_WRITE_PARAM_AWSTEP2             'h29
`define REG_DMA_WRITE_PARAM_AWLEN3              'h2c
`define REG_DMA_WRITE_PARAM_AWSTEP3             'h2d
`define REG_DMA_WRITE_PARAM_AWLEN4              'h30
`define REG_DMA_WRITE_PARAM_AWSTEP4             'h31
`define REG_DMA_WRITE_PARAM_AWLEN5              'h34
`define REG_DMA_WRITE_PARAM_AWSTEP5             'h35
`define REG_DMA_WRITE_PARAM_AWLEN6              'h38
`define REG_DMA_WRITE_PARAM_AWSTEP6             'h39
`define REG_DMA_WRITE_PARAM_AWLEN7              'h3c
`define REG_DMA_WRITE_PARAM_AWSTEP7             'h3d
`define REG_DMA_WRITE_PARAM_AWLEN8              'h30
`define REG_DMA_WRITE_PARAM_AWSTEP8             'h31
`define REG_DMA_WRITE_PARAM_AWLEN9              'h44
`define REG_DMA_WRITE_PARAM_AWSTEP9             'h45
`define REG_DMA_WRITE_WSKIP_EN                  'h70
`define REG_DMA_WRITE_WDETECT_FIRST             'h72
`define REG_DMA_WRITE_WDETECT_LAST              'h73
`define REG_DMA_WRITE_WPADDING_EN               'h74
`define REG_DMA_WRITE_WPADDING_DATA             'h75
`define REG_DMA_WRITE_WPADDING_STRB             'h76
`define REG_DMA_WRITE_SHADOW_AWADDR             'h90
`define REG_DMA_WRITE_SHADOW_AWLEN_MAX          'h91
`define REG_DMA_WRITE_SHADOW_AWLEN0             'ha0
`define REG_DMA_WRITE_SHADOW_AWLEN1             'ha4
`define REG_DMA_WRITE_SHADOW_AWSTEP1            'ha5
`define REG_DMA_WRITE_SHADOW_AWLEN2             'ha8
`define REG_DMA_WRITE_SHADOW_AWSTEP2            'ha9
`define REG_DMA_WRITE_SHADOW_AWLEN3             'hac
`define REG_DMA_WRITE_SHADOW_AWSTEP3            'had
`define REG_DMA_WRITE_SHADOW_AWLEN4             'hb0
`define REG_DMA_WRITE_SHADOW_AWSTEP4            'hb1
`define REG_DMA_WRITE_SHADOW_AWLEN5             'hb4
`define REG_DMA_WRITE_SHADOW_AWSTEP5            'hb5
`define REG_DMA_WRITE_SHADOW_AWLEN6             'hb8
`define REG_DMA_WRITE_SHADOW_AWSTEP6            'hb9
`define REG_DMA_WRITE_SHADOW_AWLEN7             'hbc
`define REG_DMA_WRITE_SHADOW_AWSTEP7            'hbd
`define REG_DMA_WRITE_SHADOW_AWLEN8             'hb0
`define REG_DMA_WRITE_SHADOW_AWSTEP8            'hb1
`define REG_DMA_WRITE_SHADOW_AWLEN9             'hc4
`define REG_DMA_WRITE_SHADOW_AWSTEP9            'hc5

/* DMA Stream read */
`define REG_DMA_READ_CORE_ID                    'h00
`define REG_DMA_READ_CORE_VERSION               'h01
`define REG_DMA_READ_CORE_CONFIG                'h03
`define REG_DMA_READ_CTL_CONTROL                'h04
`define REG_DMA_READ_CTL_STATUS                 'h05
`define REG_DMA_READ_CTL_INDEX                  'h07
`define REG_DMA_READ_IRQ_ENABLE                 'h08
`define REG_DMA_READ_IRQ_STATUS                 'h09
`define REG_DMA_READ_IRQ_CLR                    'h0a
`define REG_DMA_READ_IRQ_SET                    'h0b
`define REG_DMA_READ_PARAM_ARADDR               'h10
`define REG_DMA_READ_PARAM_AROFFSET             'h18
`define REG_DMA_READ_PARAM_ARLEN_MAX            'h1c
`define REG_DMA_READ_PARAM_ARLEN0               'h20
`define REG_DMA_READ_PARAM_ARLEN1               'h24
`define REG_DMA_READ_PARAM_ARSTEP1              'h25
`define REG_DMA_READ_PARAM_ARLEN2               'h28
`define REG_DMA_READ_PARAM_ARSTEP2              'h29
`define REG_DMA_READ_PARAM_ARLEN3               'h2c
`define REG_DMA_READ_PARAM_ARSTEP3              'h2d
`define REG_DMA_READ_PARAM_ARLEN4               'h30
`define REG_DMA_READ_PARAM_ARSTEP4              'h31
`define REG_DMA_READ_PARAM_ARLEN5               'h34
`define REG_DMA_READ_PARAM_ARSTEP5              'h35
`define REG_DMA_READ_PARAM_ARLEN6               'h38
`define REG_DMA_READ_PARAM_ARSTEP6              'h39
`define REG_DMA_READ_PARAM_ARLEN7               'h3c
`define REG_DMA_READ_PARAM_ARSTEP7              'h3d
`define REG_DMA_READ_PARAM_ARLEN8               'h30
`define REG_DMA_READ_PARAM_ARSTEP8              'h31
`define REG_DMA_READ_PARAM_ARLEN9               'h44
`define REG_DMA_READ_PARAM_ARSTEP9              'h45
`define REG_DMA_READ_SHADOW_ARADDR              'h90
`define REG_DMA_READ_SHADOW_ARLEN_MAX           'h91
`define REG_DMA_READ_SHADOW_ARLEN0              'ha0
`define REG_DMA_READ_SHADOW_ARLEN1              'ha4
`define REG_DMA_READ_SHADOW_ARSTEP1             'ha5
`define REG_DMA_READ_SHADOW_ARLEN2              'ha8
`define REG_DMA_READ_SHADOW_ARSTEP2             'ha9
`define REG_DMA_READ_SHADOW_ARLEN3              'hac
`define REG_DMA_READ_SHADOW_ARSTEP3             'had
`define REG_DMA_READ_SHADOW_ARLEN4              'hb0
`define REG_DMA_READ_SHADOW_ARSTEP4             'hb1
`define REG_DMA_READ_SHADOW_ARLEN5              'hb4
`define REG_DMA_READ_SHADOW_ARSTEP5             'hb5
`define REG_DMA_READ_SHADOW_ARLEN6              'hb8
`define REG_DMA_READ_SHADOW_ARSTEP6             'hb9
`define REG_DMA_READ_SHADOW_ARLEN7              'hbc
`define REG_DMA_READ_SHADOW_ARSTEP7             'hbd
`define REG_DMA_READ_SHADOW_ARLEN8              'hb0
`define REG_DMA_READ_SHADOW_ARSTEP8             'hb1
`define REG_DMA_READ_SHADOW_ARLEN9              'hc4
`define REG_DMA_READ_SHADOW_ARSTEP9             'hc5


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
`define REG_DAM_FIFO_CORE_ID                    'h00
`define REG_DAM_FIFO_CORE_VERSION               'h01
`define REG_DAM_FIFO_CTL_CONTROL                'h04
`define REG_DAM_FIFO_CTL_STATUS                 'h05
`define REG_DAM_FIFO_CTL_INDEX                  'h06
`define REG_DAM_FIFO_PARAM_ADDR                 'h08
`define REG_DAM_FIFO_PARAM_SIZE                 'h09
`define REG_DAM_FIFO_PARAM_AWLEN                'h10
`define REG_DAM_FIFO_PARAM_WSTRB                'h11
`define REG_DAM_FIFO_PARAM_WTIMEOUT             'h13
`define REG_DAM_FIFO_PARAM_ARLEN                'h14
`define REG_DAM_FIFO_PARAM_RTIMEOUT             'h17
`define REG_DAM_FIFO_CURRENT_ADDR               'h28
`define REG_DAM_FIFO_CURRENT_SIZE               'h29
`define REG_DAM_FIFO_CURRENT_AWLEN              'h30
`define REG_DAM_FIFO_CURRENT_WSTRB              'h31
`define REG_DAM_FIFO_CURRENT_WTIMEOUT           'h33
`define REG_DAM_FIFO_CURRENT_ARLEN              'h34
`define REG_DAM_FIFO_CURRENT_RTIMEOUT           'h37

/* parameter update control */
`define REG_VIDEO_PRMUP_CORE_ID                 'h00
`define REG_VIDEO_PRMUP_CORE_VERSION            'h01
`define REG_VIDEO_PRMUP_CONTROL                 'h04
`define REG_VIDEO_PRMUP_INDEX                   'h05
`define REG_VIDEO_PRMUP_FRAME_COUNT             'h06

/* Video Write-DMA */
`define REG_VIDEO_WDMA_CORE_ID                  'h00
`define REG_VIDEO_WDMA_VERSION                  'h01
`define REG_VIDEO_WDMA_CTL_CONTROL              'h04
`define REG_VIDEO_WDMA_CTL_STATUS               'h05
`define REG_VIDEO_WDMA_CTL_INDEX                'h07
`define REG_VIDEO_WDMA_PARAM_ADDR               'h08
`define REG_VIDEO_WDMA_PARAM_STRIDE             'h09
`define REG_VIDEO_WDMA_PARAM_WIDTH              'h0a
`define REG_VIDEO_WDMA_PARAM_HEIGHT             'h0b
`define REG_VIDEO_WDMA_PARAM_SIZE               'h0c
`define REG_VIDEO_WDMA_PARAM_AWLEN              'h0f
`define REG_VIDEO_WDMA_MONITOR_ADDR             'h10
`define REG_VIDEO_WDMA_MONITOR_STRIDE           'h11
`define REG_VIDEO_WDMA_MONITOR_WIDTH            'h12
`define REG_VIDEO_WDMA_MONITOR_HEIGHT           'h13
`define REG_VIDEO_WDMA_MONITOR_SIZE             'h14
`define REG_VIDEO_WDMA_MONITOR_AWLEN            'h17

/* Video Read-DMA */
`define REG_VIDEO_RDMA_CORE_ID                  'h00
`define REG_VIDEO_RDMA_CORE_VERSION             'h01
`define REG_VIDEO_RDMA_CTL_CONTROL              'h04
`define REG_VIDEO_RDMA_CTL_STATUS               'h05
`define REG_VIDEO_RDMA_CTL_INDEX                'h06
`define REG_VIDEO_RDMA_PARAM_ADDR               'h08
`define REG_VIDEO_RDMA_PARAM_STRIDE             'h09
`define REG_VIDEO_RDMA_PARAM_WIDTH              'h0a
`define REG_VIDEO_RDMA_PARAM_HEIGHT             'h0b
`define REG_VIDEO_RDMA_PARAM_SIZE               'h0c
`define REG_VIDEO_RDMA_PARAM_ARLEN              'h0f
`define REG_VIDEO_RDMA_MONITOR_ADDR             'h10
`define REG_VIDEO_RDMA_MONITOR_STRIDE           'h11
`define REG_VIDEO_RDMA_MONITOR_WIDTH            'h12
`define REG_VIDEO_RDMA_MONITOR_HEIGHT           'h13
`define REG_VIDEO_RDMA_MONITOR_SIZE             'h14
`define REG_VIDEO_RDMA_MONITOR_ARLEN            'h17

/* Video format regularizer */
`define REG_VIDEO_FMTREG_CORE_ID                'h00
`define REG_VIDEO_FMTREG_CORE_VERSION           'h01
`define REG_VIDEO_FMTREG_CTL_CONTROL            'h04
`define REG_VIDEO_FMTREG_CTL_STATUS             'h05
`define REG_VIDEO_FMTREG_CTL_INDEX              'h07
`define REG_VIDEO_FMTREG_CTL_SKIP               'h08
`define REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN       'h0a
`define REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT        'h0b
`define REG_VIDEO_FMTREG_PARAM_WIDTH            'h10
`define REG_VIDEO_FMTREG_PARAM_HEIGHT           'h11
`define REG_VIDEO_FMTREG_PARAM_FILL             'h12
`define REG_VIDEO_FMTREG_PARAM_TIMEOUT          'h13

/* Video sync generator */
`define REG_VIDEO_VSGEN_CORE_ID                 'h00
`define REG_VIDEO_VSGEN_CORE_VERSION            'h01
`define REG_VIDEO_VSGEN_CTL_CONTROL             'h04
`define REG_VIDEO_VSGEN_CTL_STATUS              'h05
`define REG_VIDEO_VSGEN_PARAM_HTOTAL            'h08
`define REG_VIDEO_VSGEN_PARAM_HSYNC_POL         'h0B
`define REG_VIDEO_VSGEN_PARAM_HDISP_START       'h0C
`define REG_VIDEO_VSGEN_PARAM_HDISP_END         'h0D
`define REG_VIDEO_VSGEN_PARAM_HSYNC_START       'h0E
`define REG_VIDEO_VSGEN_PARAM_HSYNC_END         'h0F
`define REG_VIDEO_VSGEN_PARAM_VTOTAL            'h10
`define REG_VIDEO_VSGEN_PARAM_VSYNC_POL         'h13
`define REG_VIDEO_VSGEN_PARAM_VDISP_START       'h14
`define REG_VIDEO_VSGEN_PARAM_VDISP_END         'h15
`define REG_VIDEO_VSGEN_PARAM_VSYNC_START       'h16
`define REG_VIDEO_VSGEN_PARAM_VSYNC_END         'h17

/* Video sync de adjuster */
`define REG_VIDEO_ADJDE_CORE_ID                 'h00
`define REG_VIDEO_ADJDE_CORE_VERSION            'h01
`define REG_VIDEO_ADJDE_CTL_CONTROL             'h04
`define REG_VIDEO_ADJDE_CTL_STATUS              'h05
`define REG_VIDEO_ADJDE_CTL_INDEX               'h07
`define REG_VIDEO_ADJDE_PARAM_HSIZE             'h08
`define REG_VIDEO_ADJDE_PARAM_VSIZE             'h09
`define REG_VIDEO_ADJDE_PARAM_HSTART            'h0a
`define REG_VIDEO_ADJDE_PARAM_VSTART            'h0b
`define REG_VIDEO_ADJDE_PARAM_HPOL              'h0c
`define REG_VIDEO_ADJDE_PARAM_VPOL              'h0d
`define REG_VIDEO_ADJDE_CURRENT_HSIZE           'h18
`define REG_VIDEO_ADJDE_CURRENT_VSIZE           'h19
`define REG_VIDEO_ADJDE_CURRENT_HSTART          'h1a
`define REG_VIDEO_ADJDE_CURRENT_VSTART          'h1b

`define REG_VIDEO_BINARIZER_CORE_ID             'h00
`define REG_VIDEO_BINARIZER_CORE_VERSION        'h01
`define REG_VIDEO_BINARIZER_CTL_CONTROL         'h04
`define REG_VIDEO_BINARIZER_CTL_STATUS          'h05
`define REG_VIDEO_BINARIZER_CTL_INDEX           'h07
`define REG_VIDEO_BINARIZER_PARAM_TH            'h10
`define REG_VIDEO_BINARIZER_PARAM_INV           'h11

`define REG_VIDEO_OVERLAY_CORE_ID               'h00
`define REG_VIDEO_OVERLAY_CORE_VERSION          'h01
`define REG_VIDEO_OVERLAY_CTL_CONTROL           'h04
`define REG_VIDEO_OVERLAY_CTL_STATUS            'h05
`define REG_VIDEO_OVERLAY_CTL_INDEX             'h07
`define REG_VIDEO_OVERLAY_PARAM_X               'h08
`define REG_VIDEO_OVERLAY_PARAM_Y               'h09
`define REG_VIDEO_OVERLAY_PARAM_WIDTH           'h0a
`define REG_VIDEO_OVERLAY_PARAM_HEIGHT          'h0b
`define REG_VIDEO_OVERLAY_PARAM_BG_EN           'h0e
`define REG_VIDEO_OVERLAY_PARAM_BG_DATA         'h0f


/* ---------------------------------- */
/*  Image processing                  */
/* ---------------------------------- */

/* Black Level Correction */
`define REG_IMG_BAYER_BLC_CORE_ID               'h00
`define REG_IMG_BAYER_BLC_CORE_VERSION          'h01
`define REG_IMG_BAYER_BLC_CTL_CONTROL           'h04
`define REG_IMG_BAYER_BLC_CTL_STATUS            'h05
`define REG_IMG_BAYER_BLC_CTL_INDEX             'h07
`define REG_IMG_BAYER_BLC_PARAM_PHASE           'h08
`define REG_IMG_BAYER_BLC_PARAM_OFFSET0         'h10
`define REG_IMG_BAYER_BLC_PARAM_OFFSET1         'h11
`define REG_IMG_BAYER_BLC_PARAM_OFFSET2         'h12
`define REG_IMG_BAYER_BLC_PARAM_OFFSET3         'h13

/* White Balance */
`define REG_IMG_BAYER_WB_CORE_ID                'h00
`define REG_IMG_BAYER_WB_CORE_VERSION           'h01
`define REG_IMG_BAYER_WB_CTL_CONTROL            'h04
`define REG_IMG_BAYER_WB_CTL_STATUS             'h05
`define REG_IMG_BAYER_WB_CTL_INDEX              'h07
`define REG_IMG_BAYER_WB_PARAM_PHASE            'h08
`define REG_IMG_BAYER_WB_PARAM_OFFSET0          'h10
`define REG_IMG_BAYER_WB_PARAM_OFFSET1          'h11
`define REG_IMG_BAYER_WB_PARAM_OFFSET2          'h12
`define REG_IMG_BAYER_WB_PARAM_OFFSET3          'h13
`define REG_IMG_BAYER_WB_PARAM_COEFF0           'h14
`define REG_IMG_BAYER_WB_PARAM_COEFF1           'h15
`define REG_IMG_BAYER_WB_PARAM_COEFF2           'h16
`define REG_IMG_BAYER_WB_PARAM_COEFF3           'h17

/* Demosaic */
`define REG_IMG_DEMOSAIC_CORE_ID                'h00
`define REG_IMG_DEMOSAIC_CORE_VERSION           'h01
`define REG_IMG_DEMOSAIC_CTL_CONTROL            'h04
`define REG_IMG_DEMOSAIC_CTL_STATUS             'h05
`define REG_IMG_DEMOSAIC_CTL_INDEX              'h07
`define REG_IMG_DEMOSAIC_PARAM_PHASE            'h08
`define REG_IMG_DEMOSAIC_CURRENT_PHASE          'h18

/* color matrix */
`define REG_IMG_COLMAT_CORE_ID                  'h00
`define REG_IMG_COLMAT_CORE_VERSION             'h01
`define REG_IMG_COLMAT_CTL_CONTROL              'h04
`define REG_IMG_COLMAT_CTL_STATUS               'h05
`define REG_IMG_COLMAT_CTL_INDEX                'h07
`define REG_IMG_COLMAT_PARAM_MATRIX00           'h10
`define REG_IMG_COLMAT_PARAM_MATRIX01           'h11
`define REG_IMG_COLMAT_PARAM_MATRIX02           'h12
`define REG_IMG_COLMAT_PARAM_MATRIX03           'h13
`define REG_IMG_COLMAT_PARAM_MATRIX10           'h14
`define REG_IMG_COLMAT_PARAM_MATRIX11           'h15
`define REG_IMG_COLMAT_PARAM_MATRIX12           'h16
`define REG_IMG_COLMAT_PARAM_MATRIX13           'h17
`define REG_IMG_COLMAT_PARAM_MATRIX20           'h18
`define REG_IMG_COLMAT_PARAM_MATRIX21           'h19
`define REG_IMG_COLMAT_PARAM_MATRIX22           'h1a
`define REG_IMG_COLMAT_PARAM_MATRIX23           'h1b
`define REG_IMG_COLMAT_PARAM_CLIP_MIN0          'h20
`define REG_IMG_COLMAT_PARAM_CLIP_MAX0          'h21
`define REG_IMG_COLMAT_PARAM_CLIP_MIN1          'h22
`define REG_IMG_COLMAT_PARAM_CLIP_MAX1          'h23
`define REG_IMG_COLMAT_PARAM_CLIP_MIN2          'h24
`define REG_IMG_COLMAT_PARAM_CLIP_MAX2          'h25
`define REG_IMG_COLMAT_CFG_COEFF0_WIDTH         'h40
`define REG_IMG_COLMAT_CFG_COEFF1_WIDTH         'h41
`define REG_IMG_COLMAT_CFG_COEFF2_WIDTH         'h42
`define REG_IMG_COLMAT_CFG_COEFF3_WIDTH         'h43
`define REG_IMG_COLMAT_CFG_COEFF0_FRAC_WIDTH    'h44
`define REG_IMG_COLMAT_CFG_COEFF1_FRAC_WIDTH    'h45
`define REG_IMG_COLMAT_CFG_COEFF2_FRAC_WIDTH    'h46
`define REG_IMG_COLMAT_CFG_COEFF3_FRAC_WIDTH    'h47
`define REG_IMG_COLMAT_CURRENT_MATRIX00         'h90
`define REG_IMG_COLMAT_CURRENT_MATRIX01         'h91
`define REG_IMG_COLMAT_CURRENT_MATRIX02         'h92
`define REG_IMG_COLMAT_CURRENT_MATRIX03         'h93
`define REG_IMG_COLMAT_CURRENT_MATRIX10         'h94
`define REG_IMG_COLMAT_CURRENT_MATRIX11         'h95
`define REG_IMG_COLMAT_CURRENT_MATRIX12         'h96
`define REG_IMG_COLMAT_CURRENT_MATRIX13         'h97
`define REG_IMG_COLMAT_CURRENT_MATRIX20         'h98
`define REG_IMG_COLMAT_CURRENT_MATRIX21         'h99
`define REG_IMG_COLMAT_CURRENT_MATRIX22         'h9a
`define REG_IMG_COLMAT_CURRENT_MATRIX23         'h9b
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN0        'ha0
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX0        'ha1
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN1        'ha2
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX1        'ha3
`define REG_IMG_COLMAT_CURRENT_CLIP_MIN2        'ha4
`define REG_IMG_COLMAT_CURRENT_CLIP_MAX2        'ha5

/* gamma  */
`define REG_IMG_GAMMA_CORE_ID                   'h00
`define REG_IMG_GAMMA_CORE_VERSION              'h01
`define REG_IMG_GAMMA_CTL_CONTROL               'h04
`define REG_IMG_GAMMA_CTL_STATUS                'h05
`define REG_IMG_GAMMA_CTL_INDEX                 'h07
`define REG_IMG_GAMMA_PARAM_ENABLE              'h08
`define REG_IMG_GAMMA_CURRENT_ENABLE            'h18
`define REG_IMG_GAMMA_CFG_TBL_ADDR              'h80
`define REG_IMG_GAMMA_CFG_TBL_SIZE              'h81
`define REG_IMG_GAMMA_CFG_TBL_WIDTH             'h82

/* gaussian 3x3 */
`define REG_IMG_GAUSS3X3_CORE_ID                'h00
`define REG_IMG_GAUSS3X3_CORE_VERSION           'h01
`define REG_IMG_GAUSS3X3_CTL_CONTROL            'h04
`define REG_IMG_GAUSS3X3_CTL_STATUS             'h05
`define REG_IMG_GAUSS3X3_CTL_INDEX              'h07
`define REG_IMG_GAUSS3X3_PARAM_ENABLE           'h08
`define REG_IMG_GAUSS3X3_CURRENT_ENABLE         'h18

/* canny */
`define REG_IMG_CANNY_CORE_ID                   'h00
`define REG_IMG_CANNY_CORE_VERSION              'h01
`define REG_IMG_CANNY_CTL_CONTROL               'h04
`define REG_IMG_CANNY_CTL_STATUS                'h05
`define REG_IMG_CANNY_CTL_INDEX                 'h07
`define REG_IMG_CANNY_PARAM_TH                  'h08
`define REG_IMG_CANNY_CURRENT_TH                'h18

/* binarizer */
`define REG_IMG_BINARIZER_CORE_ID               'h00
`define REG_IMG_BINARIZER_CORE_VERSION          'h01
`define REG_IMG_BINARIZER_CTL_CONTROL           'h04
`define REG_IMG_BINARIZER_CTL_STATUS            'h05
`define REG_IMG_BINARIZER_CTL_INDEX             'h07
`define REG_IMG_BINARIZER_PARAM_TH              'h08
`define REG_IMG_BINARIZER_PARAM_INV             'h09
`define REG_IMG_BINARIZER_PARAM_VAL0            'h0a
`define REG_IMG_BINARIZER_PARAM_VAL1            'h0b
`define REG_IMG_BINARIZER_CURRENT_TH            'h18
`define REG_IMG_BINARIZER_CURRENT_INV           'h19
`define REG_IMG_BINARIZER_CURRENT_VAL0          'h1a
`define REG_IMG_BINARIZER_CURRENT_VAL1          'h1b

/* alpha blend */
`define REG_IMG_ALPHABLEND_CORE_ID              'h00
`define REG_IMG_ALPHABLEND_CORE_VERSION         'h01
`define REG_IMG_ALPHABLEND_CTL_CONTROL          'h04
`define REG_IMG_ALPHABLEND_CTL_STATUS           'h05
`define REG_IMG_ALPHABLEND_CTL_INDEX            'h07
`define REG_IMG_ALPHABLEND_PARAM_ALPHA          'h08
`define REG_IMG_ALPHABLEND_CURRENT_ALPHA        'h18

/* area mask */
`define REG_IMG_AREAMASK_CORE_ID                'h00
`define REG_IMG_AREAMASK_CORE_VERSION           'h01
`define REG_IMG_AREAMASK_CTL_CONTROL            'h04
`define REG_IMG_AREAMASK_CTL_STATUS             'h05
`define REG_IMG_AREAMASK_CTL_INDEX              'h07
`define REG_IMG_AREAMASK_PARAM_MASK_FLAG        'h10
`define REG_IMG_AREAMASK_PARAM_MASK_VALUE0      'h12
`define REG_IMG_AREAMASK_PARAM_MASK_VALUE1      'h13
`define REG_IMG_AREAMASK_PARAM_THRESH_FLAG      'h14
`define REG_IMG_AREAMASK_PARAM_THRESH_VALUE     'h15
`define REG_IMG_AREAMASK_PARAM_RECT_FLAG        'h21
`define REG_IMG_AREAMASK_PARAM_RECT_LEFT        'h24
`define REG_IMG_AREAMASK_PARAM_RECT_RIGHT       'h25
`define REG_IMG_AREAMASK_PARAM_RECT_TOP         'h26
`define REG_IMG_AREAMASK_PARAM_RECT_BOTTOM      'h27
`define REG_IMG_AREAMASK_PARAM_CIRCLE_FLAG      'h50
`define REG_IMG_AREAMASK_PARAM_CIRCLE_X         'h54
`define REG_IMG_AREAMASK_PARAM_CIRCLE_Y         'h55
`define REG_IMG_AREAMASK_PARAM_CIRCLE_RADIUS2   'h56
`define REG_IMG_AREAMASK_CURRENT_MASK_FLAG      'h90
`define REG_IMG_AREAMASK_CURRENT_MASK_VALUE0    'h92
`define REG_IMG_AREAMASK_CURRENT_MASK_VALUE1    'h93
`define REG_IMG_AREAMASK_CURRENT_THRESH_FLAG    'h94
`define REG_IMG_AREAMASK_CURRENT_THRESH_VALUE   'h95
`define REG_IMG_AREAMASK_CURRENT_RECT_FLAG      'ha1
`define REG_IMG_AREAMASK_CURRENT_RECT_LEFT      'ha4
`define REG_IMG_AREAMASK_CURRENT_RECT_RIGHT     'ha5
`define REG_IMG_AREAMASK_CURRENT_RECT_TOP       'ha6
`define REG_IMG_AREAMASK_CURRENT_RECT_BOTTOM    'ha7
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_FLAG    'hd0
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_X       'hd4
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_Y       'hd5
`define REG_IMG_AREAMASK_CURRENT_CIRCLE_RADIUS2 'hd6

/* FIFO with DMA */
`define REG_IMG_PREVFRM_CORE_ID                 'h00
`define REG_IMG_PREVFRM_CORE_VERSION            'h01
`define REG_IMG_PREVFRM_CTL_CONTROL             'h04
`define REG_IMG_PREVFRM_CTL_STATUS              'h05
`define REG_IMG_PREVFRM_CTL_INDEX               'h06
`define REG_IMG_PREVFRM_PARAM_ADDR              'h08
`define REG_IMG_PREVFRM_PARAM_SIZE              'h09
`define REG_IMG_PREVFRM_PARAM_AWLEN             'h10
`define REG_IMG_PREVFRM_PARAM_WSTRB             'h11
`define REG_IMG_PREVFRM_PARAM_WTIMEOUT          'h13
`define REG_IMG_PREVFRM_PARAM_ARLEN             'h14
`define REG_IMG_PREVFRM_PARAM_RTIMEOUT          'h17
`define REG_IMG_PREVFRM_PARAM_INITDATA          'h18
`define REG_IMG_PREVFRM_CURRENT_ADDR            'h28
`define REG_IMG_PREVFRM_CURRENT_SIZE            'h29
`define REG_IMG_PREVFRM_CURRENT_AWLEN           'h30
`define REG_IMG_PREVFRM_CURRENT_WSTRB           'h31
`define REG_IMG_PREVFRM_CURRENT_WTIMEOUT        'h33
`define REG_IMG_PREVFRM_CURRENT_ARLEN           'h34
`define REG_IMG_PREVFRM_CURRENT_RTIMEOUT        'h37
`define REG_IMG_PREVFRM_CURRENT_INITDATA        'h38

/* LK acc */
`define REG_IMG_LK_ACC_CORE_ID                  'h00
`define REG_IMG_LK_ACC_CORE_VERSION             'h01
`define REG_IMG_LK_ACC_CTL_CONTROL              'h04
`define REG_IMG_LK_ACC_CTL_STATUS               'h05
`define REG_IMG_LK_ACC_CTL_INDEX                'h07
`define REG_IMG_LK_ACC_IRQ_ENABLE               'h08
`define REG_IMG_LK_ACC_IRQ_STATUS               'h09
`define REG_IMG_LK_ACC_IRQ_CLR                  'h0a
`define REG_IMG_LK_ACC_IRQ_SET                  'h0b
`define REG_IMG_LK_ACC_PARAM_X                  'h10
`define REG_IMG_LK_ACC_PARAM_Y                  'h11
`define REG_IMG_LK_ACC_PARAM_WIDTH              'h12
`define REG_IMG_LK_ACC_PARAM_HEIGHT             'h13
`define REG_IMG_LK_ACC_ACC_VALID                'h40
`define REG_IMG_LK_ACC_ACC_READY                'h41
`define REG_IMG_LK_ACC_ACC_GXX0                 'h42
`define REG_IMG_LK_ACC_ACC_GXX1                 'h43
`define REG_IMG_LK_ACC_ACC_GYY0                 'h44
`define REG_IMG_LK_ACC_ACC_GYY1                 'h45
`define REG_IMG_LK_ACC_ACC_GXY0                 'h46
`define REG_IMG_LK_ACC_ACC_GXY1                 'h47
`define REG_IMG_LK_ACC_ACC_EX0                  'h48
`define REG_IMG_LK_ACC_ACC_EX1                  'h49
`define REG_IMG_LK_ACC_ACC_EY0                  'h4a
`define REG_IMG_LK_ACC_ACC_EY1                  'h4b
`define REG_IMG_LK_ACC_OUT_VALID                'h60
`define REG_IMG_LK_ACC_OUT_READY                'h61
`define REG_IMG_LK_ACC_OUT_DX0                  'h64
`define REG_IMG_LK_ACC_OUT_DX1                  'h65
`define REG_IMG_LK_ACC_OUT_DY0                  'h66
`define REG_IMG_LK_ACC_OUT_DY1                  'h67

/* image selector */
`define REG_IMG_SELECTOR_CORE_ID                'h00
`define REG_IMG_SELECTOR_CORE_VERSION           'h01
`define REG_IMG_SELECTOR_CTL_SELECT             'h08
`define REG_IMG_SELECTOR_CONFIG_NUM             'h10


/* ---------------------------------- */
/*  Peripherals                       */
/* ---------------------------------- */

/* I2C */
`define REG_PERIPHERAL_I2C_STATUS               'h00
`define REG_PERIPHERAL_I2C_CONTROL              'h01
`define REG_PERIPHERAL_I2C_SEND                 'h02
`define REG_PERIPHERAL_I2C_RECV                 'h03
`define REG_PERIPHERAL_I2C_DIVIDER              'h04

`define PERIPHERAL_I2C_CONTROL_START            'h01
`define PERIPHERAL_I2C_CONTROL_STOP             'h02
`define PERIPHERAL_I2C_CONTROL_ACK              'h04
`define PERIPHERAL_I2C_CONTROL_NAK              'h08
`define PERIPHERAL_I2C_CONTROL_RECV             'h10




/* ---------------------------------- */
/*  Miscellaneous                     */
/* ---------------------------------- */

`define REG_LOGGER_CORE_ID                      'h00
`define REG_LOGGER_CORE_VERSION                 'h01
`define REG_LOGGER_CTL_CONTROL                  'h04
`define REG_LOGGER_CTL_STATUS                   'h05
`define REG_LOGGER_CTL_COUNT                    'h07
`define REG_LOGGER_LIMIT_SIZE                   'h08
`define REG_LOGGER_READ_DATA                    'h10
`define REG_LOGGER_POL_TIMER0                   'h18
`define REG_LOGGER_POL_TIMER1                   'h19
`define REG_LOGGER_POL_DATA(x)                  ('h20+(x))

`define REG_COMMUNICATION_PIPE_CORE_ID          'h00
`define REG_COMMUNICATION_PIPE_CORE_VERSION     'h01
`define REG_COMMUNICATION_PIPE_CORE_DATE        'h02
`define REG_COMMUNICATION_PIPE_CORE_SERIAL      'h03
`define REG_COMMUNICATION_PIPE_TX_DATA          'h10
`define REG_COMMUNICATION_PIPE_TX_STATUS        'h11
`define REG_COMMUNICATION_PIPE_TX_FREE_COUNT    'h12
`define REG_COMMUNICATION_PIPE_TX_IRQ_STATUS    'h14
`define REG_COMMUNICATION_PIPE_TX_IRQ_ENABLE    'h15
`define REG_COMMUNICATION_PIPE_RX_DATA          'h18
`define REG_COMMUNICATION_PIPE_RX_STATUS        'h19
`define REG_COMMUNICATION_PIPE_RX_FREE_COUNT    'h1a
`define REG_COMMUNICATION_PIPE_RX_IRQ_STATUS    'h1c
`define REG_COMMUNICATION_PIPE_RX_IRQ_ENABLE    'h1d

`define REG_MONITORPINCTL_CORE_ID               'h00
`define REG_MONITORPINCTL_CORE_VERSION          'h01
`define REG_MONITORPINCTL_IN_DATA(n)            ('h10+(n))
`define REG_MONITORPINCTL_SELECT(n)             ('h20+(n)*4)
`define REG_MONITORPINCTL_OVERRIDE(n)           ('h21+(n)*4)
`define REG_MONITORPINCTL_OUT_VALUE(n)          ('h22+(n)*4)
`define REG_MONITORPINCTL_MONITOR(n)            ('h23+(n)*4)

`endif	/* __RYUZ__JELLY__REGS__H__ */


/* end of file */
