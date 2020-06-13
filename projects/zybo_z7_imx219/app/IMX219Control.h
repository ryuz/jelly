
#ifndef __JELLY__IMX219_CONTORL__H__
#define __JELLY__IMX219_CONTORL__H__

//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <opencv2/opencv.hpp>

#include <linux/i2c-dev.h>
#include "I2cAccess.h"


#define IMX219_MODEL_ID_0                  0x0000
#define IMX219_MODEL_ID_1                  0x0001
#define IMX219_FABRICATION_TOP             0x0002
#define IMX219_LOT_ID_TOP_0                0x0004
#define IMX219_LOT_ID_TOP_1                0x0005
#define IMX219_LOT_ID_TOP_2                0x0006
#define IMX219_WAFER_NUM_TOP               0x0007
#define IMX219_CHIP_NUMBER_0               0x000D
#define IMX219_CHIP_NUMBER_1               0x000E
#define IMX219_PROCESS_VERSION             0x000F
#define IMX219_ROM_ID                      0x0011
#define IMX219_FRM_CNT                     0x0018
#define IMX219_PX_ORDER                    0x0019
#define IMX219_DT_PEDESTAL_0               0x001A
#define IMX219_DT_PEDESTAL_1               0x001B
#define IMX219_FRM_FMT_TYPE                0x0040
#define IMX219_FRM_FMT_SUBTYPE             0x0041
#define IMX219_FRM_FMT_DESC0_0             0x0042
#define IMX219_FRM_FMT_DESC0_1             0x0043
#define IMX219_FRM_FMT_DESC1_0             0x0044
#define IMX219_FRM_FMT_DESC1_1             0x0045
#define IMX219_FRM_FMT_DESC2_0             0x0046
#define IMX219_FRM_FMT_DESC2_1             0x0047
#define IMX219_MODE_SEL                    0x0100
#define IMX219_SW_RESET                    0x0103
#define IMX219_CORRUPTED FRAME STATUS      0x0104
#define IMX219_MASK_CORRUPTED_FRAMES       0x0105
#define IMX219_FAST STANDBY ENABLE         0x0106
#define IMX219_CSI_CH_ID                   0x0110
#define IMX219_CSI_SIG_MODE                0x0111
#define IMX219_CSI_LANE_MODE               0x0114
#define IMX219_TEMPERATURE_EN_VAL          0x0140
#define IMX219_READOUT_V_CNT_0             0x0142
#define IMX219_READOUT_V_CNT_1             0x0143
#define IMX219_FRAME_BANK_ENABLE           0x0150
#define IMX219_FRAME_BANK_FRM_CNT          0x0151
#define IMX219_FRAME_BANK_FAST_TRACKING    0x0152
#define IMX219_FRAME_DURATION_A            0x0154
#define IMX219_COMP_ENABLE_A               0x0155
#define IMX219_ANA_GAIN_GLOBAL_A           0x0157
#define IMX219_DIG_GAIN_GLOBAL_A_0         0x0158
#define IMX219_DIG_GAIN_GLOBAL_A_1         0x0159
#define IMX219_COARSE_INTEGRATION_TIME_A_0 0x015A
#define IMX219_COARSE_INTEGRATION_TIME_A_1 0x015B
#define IMX219_SENSOR_MODE_A               0x015D
#define IMX219_FRM_LENGTH_A_0              0x0160
#define IMX219_FRM_LENGTH_A_1              0x0161
#define IMX219_LINE_LENGTH_A_0             0x0162
#define IMX219_LINE_LENGTH_A_1             0x0163
#define IMX219_X_ADD_STA_A_0               0x0164
#define IMX219_X_ADD_STA_A_1               0x0165
#define IMX219_X_ADD_END_A_0               0x0166
#define IMX219_X_ADD_END_A_1               0x0167
#define IMX219_Y_ADD_STA_A_0               0x0168
#define IMX219_Y_ADD_STA_A_1               0x0169
#define IMX219_Y_ADD_END_A_0               0x016A
#define IMX219_Y_ADD_END_A_1               0x016B
#define IMX219_X_OUTPUT_SIZE_0             0x016C
#define IMX219_X_OUTPUT_SIZE_1             0x016D
#define IMX219_Y_OUTPUT_SIZE_0             0x016E
#define IMX219_Y_OUTPUT_SIZE_1             0x016F
#define IMX219_X_ODD_INC_A                 0x0170
#define IMX219_Y_ODD_INC_A                 0x0171
#define IMX219_IMG_ORIENTATION_A           0x0172
#define IMX219_BINNING_MODE_H_A            0x0174
#define IMX219_BINNING_MODE_V_A            0x0175
#define IMX219_BINNING_CAL_MODE_H_A        0x0176
#define IMX219_BINNING_ CAL_MODE_V_A       0x0177
#define IMX219_RESERVE_0                   0x0188
#define IMX219_ANA_GAIN_GLOBAL_SHORT_A     0x0189
#define IMX219_COARSE_INTEG_TIME_SHORT_0_A 0x018A
#define IMX219_COARSE_INTEG_TIME_SHORT_1_A 0x018B
#define IMX219_CSI_DATA_FORMAT_0_A         0x018C
#define IMX219_CSI_DATA_FORMAT_1_A         0x018D
#define IMX219_LSC_ENABLE_A                0x0190
#define IMX219_LSC_COLOR_MODE_A            0x0191
#define IMX219_LSC_SELECT_TABLE_A          0x0192
#define IMX219_LSC_TUNING_ENABLE_A         0x0193
#define IMX219_LSC_WHITE_BALANCE_RG_0_A    0x0194
#define IMX219_LSC_WHITE_BALANCE_RG_1_A    0x0195
#define IMX219_RESERVE_1                   0x0196
#define IMX219_RESERVE_2                   0x0197
#define IMX219_LSC_TUNING_COEF_R_A         0x0198
#define IMX219_LSC_TUNING_COEF_GR_A        0x0199
#define IMX219_LSC_TUNING_COEF_GB_A        0x019A
#define IMX219_LSC_TUNING_COEF_B_A         0x019B
#define IMX219_LSC_TUNING_R_0_A            0x019C
#define IMX219_LSC_TUNING_R_1_A            0x019D
#define IMX219_LSC_TUNING_GR_0_A           0x019E
#define IMX219_LSC_TUNING_GR_1_A           0x019F
#define IMX219_LSC_TUNING_GB_0_A           0x01A0
#define IMX219_LSC_TUNING_GB_1_A           0x01A1
#define IMX219_LSC_TUNING_B_0_A            0x01A2
#define IMX219_LSC_TUNING_B_1_A            0x01A3
#define IMX219_LSC_KNOT_POINT_FORMAT_A     0x01A4
#define IMX219_VTPXCK_DIV                  0x0301
#define IMX219_VTSYCK_DIV                  0x0303
#define IMX219_PREPLLCK_VT_DIV             0x0304
#define IMX219_PREPLLCK_OP_DIV             0x0305
#define IMX219_PLL_VT_MPY_0                0x0306
#define IMX219_PLL_VT_MPY_1                0x0307
#define IMX219_OPPXCK_DIV                  0x0309
#define IMX219_OPSYCK_DIV                  0x030B
#define IMX219_PLL_OP_MPY_0                0x030C
#define IMX219_PLL_OP_MPY_1                0x030D
#define IMX219_RESERVE_3                   0x030E
#define IMX219_RESERVE_4                   0x0318
#define IMX219_RESERVE_5                   0x0319
#define IMX219_RESERVE_6                   0x031A
#define IMX219_RESERVE_7                   0x031B
#define IMX219_RESERVE_8                   0x031C
#define IMX219_RESERVE_9                   0x031D
#define IMX219_RESERVE_10                  0x031E
#define IMX219_RESERVE_11                  0x031F
#define IMX219_FLASH_STATUS                0x0321



class IMX219ControlI2c
{
protected:
	I2cAccess	m_i2c;

	bool		m_binning_x = true;
	bool		m_binning_y = true;
	int			m_aoi_x  = 3280/2 - 640;
	int			m_aoi_y  = 2464/2 - 132;
	int			m_width  = 640;
	int			m_height = 132;

	float		m_framerate = 1000;
	float		m_exposure  = 1;
	float		m_gain = 1;

public:
	IMX219ControlI2c() {}
	~IMX219ControlI2c() {}

	bool Open(const char* fname, unsigned char dev)
	{
		return m_i2c.Open(fname, dev);
	}

	void Close(const char* fname, unsigned char dev)
	{
		return m_i2c.Close();
	}

	bool IsOpend(void)
	{
		return m_i2c.IsOpend();
	}
	
	bool Setup(void)
	{
		if ( !IsOpend() ) {
			return false;
		}

		// ソフトリセット
		I2cWriteAddr16Byte(IMX219_SW_RESET, 0x01);
		usleep(100);
//		I2cWriteAddr16Byte(0x0103, 0x00);
//		usleep(10000);

		I2cWriteAddr16Byte(0x0102, 0x01);   // ???? (Reserved)
		I2cWriteAddr16Byte(0x0100, 0x00);   // mode_select [4:0]  (0: SW standby, 1: Streaming)
		I2cWriteAddr16Word(0x6620, 0x0101);   // ????
		I2cWriteAddr16Word(0x6622, 0x0101);
	
		I2cWriteAddr16Byte(0x30EB, 0x05);   // Access command sequence Seq.
		I2cWriteAddr16Byte(0x30EB, 0x0C);
		I2cWriteAddr16Byte(0x300A, 0xFF);
		I2cWriteAddr16Byte(0x300B, 0xFF);
		I2cWriteAddr16Byte(0x30EB, 0x05);
		I2cWriteAddr16Byte(0x30EB, 0x09);

		I2cWriteAddr16Byte(0x0114, 0x01  );   // * CSI_LANE_MODE (03: 4Lane 01: 2Lane)
		I2cWriteAddr16Byte(0x0128, 0x00  );   //   DPHY_CTRL (MIPI Global timing setting 0: auto mode, 1: manual mode)
		I2cWriteAddr16Word(0x012a, 0x1800);   // * INCK frequency [MHz] 6,144MHz
		I2cWriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
		I2cWriteAddr16Word(0x015A, 0x09BD);   // 0x9bd=2493     COARSE_INTEGRATION_TIME_A
		I2cWriteAddr16Word(0x0160, 0x0372);   // 0x372= 882     FRM_LENGTH_A

		int	w = 640;
		int	h = 132;
#if 0
		I2cWriteAddr16Word(0x0162, 0x0D78);   // 0xD78=3448     LINE_LENGTH_A (line_length_pck Units: Pixels)  
		I2cWriteAddr16Word(0x0164, 0x0000);   //      X_ADD_STA_A  x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
		I2cWriteAddr16Word(0x0166, 0x0CCF);   // 0xccf=3279     X_ADD_END_A
		I2cWriteAddr16Word(0x0168, 0x0000);   //      Y_ADD_STA_A
		I2cWriteAddr16Word(0x016A, 0x099F);   // 0x99f=2463     Y_ADD_END_A
		I2cWriteAddr16Word(0x016C, 0x0668);   // 0x668=1640     x_output_size
		I2cWriteAddr16Word(0x016E, 0x04D0);   // 0x4d0=1232     y_output_size
#else
		I2cWriteAddr16Word(0x0164, 3280/2 - w);    //      X_ADD_STA_A  x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
		I2cWriteAddr16Word(0x0166, 3280/2 + w-1);  // 0xccf=3279     X_ADD_END_A
		I2cWriteAddr16Word(0x0168, 2464/2 - h);    //      Y_ADD_STA_A
		I2cWriteAddr16Word(0x016A, 2464/2 + h-1);  // 0x99f=2463     Y_ADD_END_A
		I2cWriteAddr16Word(0x016C, w);   // 0x668=1640     x_output_size
		I2cWriteAddr16Word(0x016E, h);   // 0x4d0=1232     y_output_size
#endif
	
	
		I2cWriteAddr16Word(0x0170, 0x0101);   //      X_ODD_INC_A  Increment for odd pixels 1, 3
	//	I2cWriteAddr16Word(0x0170, 0x0303);   // r     X_ODD_INC_A  Increment for odd pixels 1, 3
	//	I2cWriteAddr16Word(0x0174, 0x0101);   //      BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
		I2cWriteAddr16Word(0x0174, 0x0303);   // r     BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
		I2cWriteAddr16Word(0x018C, 0x0A0A);   //      CSI_DATA_FORMAT_A   CSI-2 data format
		I2cWriteAddr16Byte(0x0301, 0x05  );   // * VTPXCK_DIV  Video Timing Pixel Clock Divider Value
		I2cWriteAddr16Word(0x0303, 0x0103);   // * VTSYCK_DIV  PREPLLCK_VT_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)
		I2cWriteAddr16Word(0x0305, 0x0300);   // * PREPLLCK_OP_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)  / PLL_VT_MPY 区切りがおかしい次に続く
	//	I2cWriteAddr16Byte(0x0307, 0x39  );   // * PLL_VT_MPY
	//	I2cWriteAddr16Byte(0x0307, 84  );   // r PLL_VT_MPY
		I2cWriteAddr16Byte(0x0307, 87  );   // r PLL_VT_MPY
		I2cWriteAddr16Byte(0x0309, 0x0A  );   // * OPPXCK_DIV
		I2cWriteAddr16Word(0x030B, 0x0100);   // * OPSYCK_DIV PLL_OP_MPY[10:8] / 区切りがおかしい次に続く
		I2cWriteAddr16Byte(0x030D, 0x72  );   // * PLL_OP_MPY[10:8]
		
		I2cWriteAddr16Byte(0x455E, 0x00  );   //
		I2cWriteAddr16Byte(0x471E, 0x4B  );   //
		I2cWriteAddr16Byte(0x4767, 0x0F  );   //
		I2cWriteAddr16Byte(0x4750, 0x14  );   //
		I2cWriteAddr16Byte(0x4540, 0x00  );   //
		I2cWriteAddr16Byte(0x47B4, 0x14  );   //
		I2cWriteAddr16Byte(0x4713, 0x30  );   //
		I2cWriteAddr16Byte(0x478B, 0x10  );   //
		I2cWriteAddr16Byte(0x478F, 0x10  );   //
		I2cWriteAddr16Byte(0x4793, 0x10  );   //
		I2cWriteAddr16Byte(0x4797, 0x0E  );   //
		I2cWriteAddr16Byte(0x479B, 0x0E  );   //

		I2cWriteAddr16Byte(0x0172, 0x03  );   //      IMG_ORIENTATION_A
		
	//	i2c.WriteAddr16Word(0x0160, 0x06E3);   //      FRM_LENGTH_A[15:8]
	//	i2c.WriteAddr16Word(0x0162, 0x0D78);   //      LINE_LENGTH_A
	//	i2c.WriteAddr16Word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A
	//	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A

	//	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	//	i2c.WriteAddr16Word(0x0160, 0x06E3);   //      FRM_LENGTH_A
	//	i2c.WriteAddr16Word(0x0162, 0x0D78);   //      LINE_LENGTH_A (line_length_pck Units: Pixels)
	//	i2c.WriteAddr16Word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A

		I2cWriteAddr16Byte(0x0100, 0x01  );   //      mode_select [4:0] 0: SW standby, 1: Streaming

	//	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	//	i2c.WriteAddr16Word(0x0160, 0x06E3);   // 0x06E3=3330   FRM_LENGTH_A
	//	i2c.WriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   LINE_LENGTH_A
	//	i2c.WriteAddr16Word(0x015A, 0x0421);   // 0x0421=1057   COARSE_INTEGRATION_TIME_A

	#if 0
		I2cWriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
		I2cWriteAddr16Word(0x0160, 0x0D02);   // 0x0D02=3330   FRM_LENGTH_A
		I2cWriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   INE_LENGTH_A (line_length_pck Units: Pixels)
		I2cWriteAddr16Word(0x015A, 0x0D02);   // 0x0D02=3330   COARSE_INTEGRATION_TIME_A
		I2cWriteAddr16Byte(0x0157, 0xE0  );   //      ANA_GAIN_GLOBAL_A
	#else
		I2cWriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
		I2cWriteAddr16Word(0x0160, 80);       // 0x0D02=3330   FRM_LENGTH_A
		I2cWriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   LINE_LENGTH_A (line_length_pck Units: Pixels)
		I2cWriteAddr16Word(0x015A, 50);       // 0x0D02=3330   COARSE_INTEGRATION_TIME_A
		I2cWriteAddr16Byte(0x0157, 0xE0  );   //      ANA_GAIN_GLOBAL_A
	//	I2cWriteAddr16Byte(0x0157, 0xFF  );   //      ANA_GAIN_GLOBAL_A
		I2cWriteAddr16Word(0x0158, 0x0FFF);   //      ANA_GAIN_GLOBAL_A
	#endif

		return true;
	}



protected:
	int I2cWriteAddr16(unsigned short addr, const void* data, int len)
	{
		unsigned char buf[2+len];
		
		buf[0] = ((addr >> 8) & 0xff);
		buf[1] = ((addr >> 0) & 0xff);
		memcpy(&buf[2], data, len);
		m_i2c.Write(buf, 2+len);
		
		return len;
	}
	
	int I2cReadAddr16(unsigned short addr, void* buf, int len)
	{
		unsigned char addr_buf[2];
		
		addr_buf[0] = ((addr >> 8) & 0xff);
		addr_buf[1] = ((addr >> 0) & 0xff);
		m_i2c.Write(addr_buf, 2);
		m_i2c.Read(buf, len);
		
		return len;
	}
	
	int I2cWriteAddr16Byte(unsigned short addr, unsigned char data)
	{
		return I2cWriteAddr16(addr, &data, 1);
	}
	
	int I2cWriteAddr16Word(unsigned short addr, unsigned short data)
	{
		unsigned char buf[2];
	 	buf[0] = ((data >> 8) & 0xff);
	 	buf[1] = ((data >> 0) & 0xff);
		return I2cWriteAddr16(addr, buf, 2);
	}
	
	unsigned char I2cReadAddr16Byte(unsigned short addr)
	{
		unsigned char buf[1];
		I2cReadAddr16(addr, buf, 1);
		return buf[0];
	}
};


#endif	// __JELLY__IMX219_CONTORL__H__

// end of file
