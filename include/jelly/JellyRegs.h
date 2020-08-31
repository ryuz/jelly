
#ifndef	__RYUZ__JELLY__REGS__H__
#define	__RYUZ__JELLY__REGS__H__


/* ---------------------------------- */
/*  Video                             */
/* ---------------------------------- */

#define CORE_ID_VIDEO_PRMUP                     0x527a1f10
#define CORE_ID_VIDEO_WDMA                      0x527a1020
#define CORE_ID_VIDEO_RDMA                      0x527a1040
#define CORE_ID_VIDEO_FMTREG                    0x527a1220


/* FIFO with DMA */
#define REG_DAM_FIFO_CORE_ID                    0x00
#define REG_DAM_FIFO_CORE_VERSION               0x01
#define REG_DAM_FIFO_CTL_CONTROL                0x04
#define REG_DAM_FIFO_CTL_STATUS                 0x05
#define REG_DAM_FIFO_CTL_INDEX                  0x06
#define REG_DAM_FIFO_PARAM_ADDR                 0x08
#define REG_DAM_FIFO_PARAM_SIZE                 0x09
#define REG_DAM_FIFO_PARAM_AWLEN                0x10
#define REG_DAM_FIFO_PARAM_WSTRB                0x11
#define REG_DAM_FIFO_PARAM_WTIMEOUT             0x13
#define REG_DAM_FIFO_PARAM_ARLEN                0x14
#define REG_DAM_FIFO_PARAM_RTIMEOUT             0x17
#define REG_DAM_FIFO_CURRENT_ADDR               0x28
#define REG_DAM_FIFO_CURRENT_SIZE               0x29
#define REG_DAM_FIFO_CURRENT_AWLEN              0x30
#define REG_DAM_FIFO_CURRENT_WSTRB              0x31
#define REG_DAM_FIFO_CURRENT_WTIMEOUT           0x33
#define REG_DAM_FIFO_CURRENT_ARLEN              0x34
#define REG_DAM_FIFO_CURRENT_RTIMEOUT           0x37

/* parameter update control */
#define REG_VIDEO_PRMUP_CORE_ID                 0x00
#define REG_VIDEO_PRMUP_CORE_VERSION            0x01
#define REG_VIDEO_PRMUP_CONTROL                 0x04
#define REG_VIDEO_PRMUP_INDEX                   0x05
#define REG_VIDEO_PRMUP_FRAME_COUNT             0x06

/* Video Write-DMA */
#define REG_VIDEO_WDMA_CORE_ID                  0x00
#define REG_VIDEO_WDMA_VERSION                  0x01
#define REG_VIDEO_WDMA_CTL_CONTROL              0x04
#define REG_VIDEO_WDMA_CTL_STATUS               0x05
#define REG_VIDEO_WDMA_CTL_INDEX                0x07
#define REG_VIDEO_WDMA_PARAM_ADDR               0x08
#define REG_VIDEO_WDMA_PARAM_STRIDE             0x09
#define REG_VIDEO_WDMA_PARAM_WIDTH              0x0a
#define REG_VIDEO_WDMA_PARAM_HEIGHT             0x0b
#define REG_VIDEO_WDMA_PARAM_SIZE               0x0c
#define REG_VIDEO_WDMA_PARAM_AWLEN              0x0f
#define REG_VIDEO_WDMA_MONITOR_ADDR             0x10
#define REG_VIDEO_WDMA_MONITOR_STRIDE           0x11
#define REG_VIDEO_WDMA_MONITOR_WIDTH            0x12
#define REG_VIDEO_WDMA_MONITOR_HEIGHT           0x13
#define REG_VIDEO_WDMA_MONITOR_SIZE             0x14
#define REG_VIDEO_WDMA_MONITOR_AWLEN            0x17

/* Video Read-DMA */
#define REG_VIDEO_RDMA_CORE_ID                  0x00
#define REG_VIDEO_RDMA_CORE_VERSION             0x01
#define REG_VIDEO_RDMA_CTL_CONTROL              0x04
#define REG_VIDEO_RDMA_CTL_STATUS               0x05
#define REG_VIDEO_RDMA_CTL_INDEX                0x06
#define REG_VIDEO_RDMA_PARAM_ADDR               0x08
#define REG_VIDEO_RDMA_PARAM_STRIDE             0x09
#define REG_VIDEO_RDMA_PARAM_WIDTH              0x0a
#define REG_VIDEO_RDMA_PARAM_HEIGHT             0x0b
#define REG_VIDEO_RDMA_PARAM_SIZE               0x0c
#define REG_VIDEO_RDMA_PARAM_ARLEN              0x0f
#define REG_VIDEO_RDMA_MONITOR_ADDR             0x10
#define REG_VIDEO_RDMA_MONITOR_STRIDE           0x11
#define REG_VIDEO_RDMA_MONITOR_WIDTH            0x12
#define REG_VIDEO_RDMA_MONITOR_HEIGHT           0x13
#define REG_VIDEO_RDMA_MONITOR_SIZE             0x14
#define REG_VIDEO_RDMA_MONITOR_ARLEN            0x17

/* Video format regularizer */
#define REG_VIDEO_FMTREG_CORE_ID                0x00
#define REG_VIDEO_FMTREG_CORE_VERSION           0x01
#define REG_VIDEO_FMTREG_CTL_CONTROL            0x04
#define REG_VIDEO_FMTREG_CTL_STATUS             0x05
#define REG_VIDEO_FMTREG_CTL_INDEX              0x07
#define REG_VIDEO_FMTREG_CTL_SKIP               0x08
#define REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN       0x0a
#define REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT        0x0b
#define REG_VIDEO_FMTREG_PARAM_WIDTH            0x10
#define REG_VIDEO_FMTREG_PARAM_HEIGHT           0x11
#define REG_VIDEO_FMTREG_PARAM_FILL             0x12
#define REG_VIDEO_FMTREG_PARAM_TIMEOUT          0x13

// Video sync generator
#define REG_VIDEO_VSGEN_CORE_ID                 0x00
#define REG_VIDEO_VSGEN_CORE_VERSION            0x01
#define REG_VIDEO_VSGEN_CTL_CONTROL             0x04
#define REG_VIDEO_VSGEN_CTL_STATUS              0x05
#define REG_VIDEO_VSGEN_PARAM_HTOTAL            0x08
#define REG_VIDEO_VSGEN_PARAM_HSYNC_POL         0x0B
#define REG_VIDEO_VSGEN_PARAM_HDISP_START       0x0C
#define REG_VIDEO_VSGEN_PARAM_HDISP_END         0x0D
#define REG_VIDEO_VSGEN_PARAM_HSYNC_START       0x0E
#define REG_VIDEO_VSGEN_PARAM_HSYNC_END         0x0F
#define REG_VIDEO_VSGEN_PARAM_VTOTAL            0x10
#define REG_VIDEO_VSGEN_PARAM_VSYNC_POL         0x13
#define REG_VIDEO_VSGEN_PARAM_VDISP_START       0x14
#define REG_VIDEO_VSGEN_PARAM_VDISP_END         0x15
#define REG_VIDEO_VSGEN_PARAM_VSYNC_START       0x16
#define REG_VIDEO_VSGEN_PARAM_VSYNC_END         0x17


/* ---------------------------------- */
/*  Image processing                  */
/* ---------------------------------- */

/* Demosaic */
#define REG_IMG_DEMOSAIC_CORE_ID                0x00
#define REG_IMG_DEMOSAIC_CORE_VERSION           0x01
#define REG_IMG_DEMOSAIC_CTL_CONTROL            0x04
#define REG_IMG_DEMOSAIC_CTL_STATUS             0x05
#define REG_IMG_DEMOSAIC_CTL_INDEX              0x07
#define REG_IMG_DEMOSAIC_PARAM_PHASE            0x08
#define REG_IMG_DEMOSAIC_CURRENT_PHASE          0x18

/* color matrix */
#define REG_IMG_COLMAT_CORE_ID                  0x00
#define REG_IMG_COLMAT_CORE_VERSION             0x01
#define REG_IMG_COLMAT_CTL_CONTROL              0x04
#define REG_IMG_COLMAT_CTL_STATUS               0x05
#define REG_IMG_COLMAT_CTL_INDEX                0x07
#define REG_IMG_COLMAT_PARAM_MATRIX00           0x10
#define REG_IMG_COLMAT_PARAM_MATRIX01           0x11
#define REG_IMG_COLMAT_PARAM_MATRIX02           0x12
#define REG_IMG_COLMAT_PARAM_MATRIX03           0x13
#define REG_IMG_COLMAT_PARAM_MATRIX10           0x14
#define REG_IMG_COLMAT_PARAM_MATRIX11           0x15
#define REG_IMG_COLMAT_PARAM_MATRIX12           0x16
#define REG_IMG_COLMAT_PARAM_MATRIX13           0x17
#define REG_IMG_COLMAT_PARAM_MATRIX20           0x18
#define REG_IMG_COLMAT_PARAM_MATRIX21           0x19
#define REG_IMG_COLMAT_PARAM_MATRIX22           0x1a
#define REG_IMG_COLMAT_PARAM_MATRIX23           0x1b
#define REG_IMG_COLMAT_PARAM_CLIP_MIN0          0x20
#define REG_IMG_COLMAT_PARAM_CLIP_MAX0          0x21
#define REG_IMG_COLMAT_PARAM_CLIP_MIN1          0x22
#define REG_IMG_COLMAT_PARAM_CLIP_MAX1          0x23
#define REG_IMG_COLMAT_PARAM_CLIP_MIN2          0x24
#define REG_IMG_COLMAT_PARAM_CLIP_MAX2          0x25
#define REG_IMG_COLMAT_CFG_COEFF0_WIDTH         0x40
#define REG_IMG_COLMAT_CFG_COEFF1_WIDTH         0x41
#define REG_IMG_COLMAT_CFG_COEFF2_WIDTH         0x42
#define REG_IMG_COLMAT_CFG_COEFF3_WIDTH         0x43
#define REG_IMG_COLMAT_CFG_COEFF0_FRAC_WIDTH    0x44
#define REG_IMG_COLMAT_CFG_COEFF1_FRAC_WIDTH    0x45
#define REG_IMG_COLMAT_CFG_COEFF2_FRAC_WIDTH    0x46
#define REG_IMG_COLMAT_CFG_COEFF3_FRAC_WIDTH    0x47
#define REG_IMG_COLMAT_CURRENT_MATRIX00         0x90
#define REG_IMG_COLMAT_CURRENT_MATRIX01         0x91
#define REG_IMG_COLMAT_CURRENT_MATRIX02         0x92
#define REG_IMG_COLMAT_CURRENT_MATRIX03         0x93
#define REG_IMG_COLMAT_CURRENT_MATRIX10         0x94
#define REG_IMG_COLMAT_CURRENT_MATRIX11         0x95
#define REG_IMG_COLMAT_CURRENT_MATRIX12         0x96
#define REG_IMG_COLMAT_CURRENT_MATRIX13         0x97
#define REG_IMG_COLMAT_CURRENT_MATRIX20         0x98
#define REG_IMG_COLMAT_CURRENT_MATRIX21         0x99
#define REG_IMG_COLMAT_CURRENT_MATRIX22         0x9a
#define REG_IMG_COLMAT_CURRENT_MATRIX23         0x9b
#define REG_IMG_COLMAT_CURRENT_CLIP_MIN0        0xa0
#define REG_IMG_COLMAT_CURRENT_CLIP_MAX0        0xa1
#define REG_IMG_COLMAT_CURRENT_CLIP_MIN1        0xa2
#define REG_IMG_COLMAT_CURRENT_CLIP_MAX1        0xa3
#define REG_IMG_COLMAT_CURRENT_CLIP_MIN2        0xa4
#define REG_IMG_COLMAT_CURRENT_CLIP_MAX2        0xa5

/* gamma  */
#define REG_IMG_GAMMA_CORE_ID                   0x00
#define REG_IMG_GAMMA_CORE_VERSION              0x01
#define REG_IMG_GAMMA_CTL_CONTROL               0x04
#define REG_IMG_GAMMA_CTL_STATUS                0x05
#define REG_IMG_GAMMA_CTL_INDEX                 0x07
#define REG_IMG_GAMMA_PARAM_ENABLE              0x08
#define REG_IMG_GAMMA_CURRENT_ENABLE            0x18
#define REG_IMG_GAMMA_CFG_TBL_ADDR              0x80
#define REG_IMG_GAMMA_CFG_TBL_SIZE              0x81
#define REG_IMG_GAMMA_CFG_TBL_WIDTH             0x82

/* gaussian 3x3 */
#define REG_IMG_GAUSS3X3_CORE_ID                0x00
#define REG_IMG_GAUSS3X3_CORE_VERSION           0x01
#define REG_IMG_GAUSS3X3_CTL_CONTROL            0x04
#define REG_IMG_GAUSS3X3_CTL_STATUS             0x05
#define REG_IMG_GAUSS3X3_CTL_INDEX              0x07
#define REG_IMG_GAUSS3X3_PARAM_ENABLE           0x08
#define REG_IMG_GAUSS3X3_CURRENT_ENABLE         0x18

/* canny */
#define REG_IMG_CANNY_CORE_ID                   0x00
#define REG_IMG_CANNY_CORE_VERSION              0x01
#define REG_IMG_CANNY_CTL_CONTROL               0x04
#define REG_IMG_CANNY_CTL_STATUS                0x05
#define REG_IMG_CANNY_CTL_INDEX                 0x07
#define REG_IMG_CANNY_PARAM_TH                  0x08
#define REG_IMG_CANNY_CURRENT_TH                0x18

/* binarizer */
#define REG_IMG_BINARIZER_CORE_ID               0x00
#define REG_IMG_BINARIZER_CORE_VERSION          0x01
#define REG_IMG_BINARIZER_CTL_CONTROL           0x04
#define REG_IMG_BINARIZER_CTL_STATUS            0x05
#define REG_IMG_BINARIZER_CTL_INDEX             0x07
#define REG_IMG_BINARIZER_PARAM_TH              0x08
#define REG_IMG_BINARIZER_PARAM_INV             0x09
#define REG_IMG_BINARIZER_PARAM_VAL0            0x0a
#define REG_IMG_BINARIZER_PARAM_VAL1            0x0b
#define REG_IMG_BINARIZER_CURRENT_TH            0x18
#define REG_IMG_BINARIZER_CURRENT_INV           0x19
#define REG_IMG_BINARIZER_CURRENT_VAL0          0x1a
#define REG_IMG_BINARIZER_CURRENT_VAL1          0x1b

/* area mask */
#define REG_IMG_AREAMASK_CORE_ID                0x00
#define REG_IMG_AREAMASK_CORE_VERSION           0x01
#define REG_IMG_AREAMASK_CTL_CONTROL            0x04
#define REG_IMG_AREAMASK_CTL_STATUS             0x05
#define REG_IMG_AREAMASK_CTL_INDEX              0x07
#define REG_IMG_AREAMASK_PARAM_MASK_FLAG        0x10
#define REG_IMG_AREAMASK_PARAM_MASK_VALUE0      0x12
#define REG_IMG_AREAMASK_PARAM_MASK_VALUE1      0x13
#define REG_IMG_AREAMASK_PARAM_THRESH_FLAG      0x14
#define REG_IMG_AREAMASK_PARAM_THRESH_VALUE     0x15
#define REG_IMG_AREAMASK_PARAM_RECT_FLAG        0x21
#define REG_IMG_AREAMASK_PARAM_RECT_LEFT        0x24
#define REG_IMG_AREAMASK_PARAM_RECT_RIGHT       0x25
#define REG_IMG_AREAMASK_PARAM_RECT_TOP         0x26
#define REG_IMG_AREAMASK_PARAM_RECT_BOTTOM      0x27
#define REG_IMG_AREAMASK_PARAM_CIRCLE_FLAG      0x50
#define REG_IMG_AREAMASK_PARAM_CIRCLE_X         0x54
#define REG_IMG_AREAMASK_PARAM_CIRCLE_Y         0x55
#define REG_IMG_AREAMASK_PARAM_CIRCLE_RADIUS2   0x56
#define REG_IMG_AREAMASK_CURRENT_MASK_FLAG      0x90
#define REG_IMG_AREAMASK_CURRENT_MASK_VALUE0    0x92
#define REG_IMG_AREAMASK_CURRENT_MASK_VALUE1    0x93
#define REG_IMG_AREAMASK_CURRENT_THRESH_FLAG    0x94
#define REG_IMG_AREAMASK_CURRENT_THRESH_VALUE   0x95
#define REG_IMG_AREAMASK_CURRENT_RECT_FLAG      0xa1
#define REG_IMG_AREAMASK_CURRENT_RECT_LEFT      0xa4
#define REG_IMG_AREAMASK_CURRENT_RECT_RIGHT     0xa5
#define REG_IMG_AREAMASK_CURRENT_RECT_TOP       0xa6
#define REG_IMG_AREAMASK_CURRENT_RECT_BOTTOM    0xa7
#define REG_IMG_AREAMASK_CURRENT_CIRCLE_FLAG    0xd0
#define REG_IMG_AREAMASK_CURRENT_CIRCLE_X       0xd4
#define REG_IMG_AREAMASK_CURRENT_CIRCLE_Y       0xd5
#define REG_IMG_AREAMASK_CURRENT_CIRCLE_RADIUS2 0xd6

/* FIFO with DMA */
#define REG_IMG_PREVFRM_CORE_ID                 0x00
#define REG_IMG_PREVFRM_CORE_VERSION            0x01
#define REG_IMG_PREVFRM_CTL_CONTROL             0x04
#define REG_IMG_PREVFRM_CTL_STATUS              0x05
#define REG_IMG_PREVFRM_CTL_INDEX               0x06
#define REG_IMG_PREVFRM_PARAM_ADDR              0x08
#define REG_IMG_PREVFRM_PARAM_SIZE              0x09
#define REG_IMG_PREVFRM_PARAM_AWLEN             0x10
#define REG_IMG_PREVFRM_PARAM_WSTRB             0x11
#define REG_IMG_PREVFRM_PARAM_WTIMEOUT          0x13
#define REG_IMG_PREVFRM_PARAM_ARLEN             0x14
#define REG_IMG_PREVFRM_PARAM_RTIMEOUT          0x17
#define REG_IMG_PREVFRM_PARAM_INITDATA          0x18
#define REG_IMG_PREVFRM_CURRENT_ADDR            0x28
#define REG_IMG_PREVFRM_CURRENT_SIZE            0x29
#define REG_IMG_PREVFRM_CURRENT_AWLEN           0x30
#define REG_IMG_PREVFRM_CURRENT_WSTRB           0x31
#define REG_IMG_PREVFRM_CURRENT_WTIMEOUT        0x33
#define REG_IMG_PREVFRM_CURRENT_ARLEN           0x34
#define REG_IMG_PREVFRM_CURRENT_RTIMEOUT        0x37
#define REG_IMG_PREVFRM_CURRENT_INITDATA        0x38

/* image selector */
#define REG_IMG_SELECTOR_CORE_ID                0x00
#define REG_IMG_SELECTOR_CORE_VERSION           0x01
#define REG_IMG_SELECTOR_CTL_SELECT             0x08
#define REG_IMG_SELECTOR_CONFIG_NUM             0x10


#endif	/* __RYUZ__JELLY__REGS__H__ */


// end of file
