/*
 * imx219_control.cc
 *
 *  Created on: 2019/07/28
 *      Author: ryuji2
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_cache.h"

#include "xparameters.h"
#include "sleep.h"
#include "xiicps.h"



// I2C parameters
#define IIC_SCLK_RATE       400000  // clock 400KHz
#define IIC_DEVICE_ID       XPAR_XIICPS_0_DEVICE_ID

//#define MPU9250_ADDRESS		0x68    // 7bit address
//#define AK8963_ADDRESS		0x0C	// Address of magnetometer

XIicPs Iic;

int i2c_write(XIicPs *Iic, u8* buff, u32 len, u16 i2c_adder)
{
    int Status;

    while(XIicPs_BusIsBusy(Iic)){
        /* NOP */
    }

    Status = XIicPs_MasterSendPolled(Iic, buff, len, i2c_adder);

    if(Status != XST_SUCCESS){
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}


int i2c_read(XIicPs *Iic, u8* buff, u32 len, u16 i2c_adder)
{
    int Status;

    // Wait until bus is idle to start another transfer.
    while(XIicPs_BusIsBusy(Iic)){
        /* NOP */
    }

    Status = XIicPs_MasterRecvPolled(Iic, buff, len, i2c_adder);

    if (Status == XST_SUCCESS)
        return XST_SUCCESS;
    else
        return -1;
}


int imx219_read(u16 addr, u8* buf, u32 len)
{
 	u8		buf_w[2];
 	buf_w[0] = ((addr >> 8) & 0xff);
 	buf_w[1] = ((addr >> 0) & 0xff);
 	i2c_write(&Iic, buf_w, 2, 0x10);
 	return i2c_read(&Iic, buf, len, 0x10);
}

int imx219_write(u16 addr, u8* buf, u32 len)
{
 	u8		buf_w[2+16];
 	int		i;
 	buf_w[0] = ((addr >> 8) & 0xff);
 	buf_w[1] = ((addr >> 0) & 0xff);
 	for ( i = 0; i < len; i++ ) {
 		buf_w[2+i] = buf[i];
 	}
 	return i2c_write(&Iic, buf_w, 2+len, 0x10);
}


int imx219_write_byte(u16 addr, u8 data)
{
 	u8		buf_w[1];
 	buf_w[0] = data;
 	return imx219_write(addr, buf_w, 1);
}

int imx219_write_word(u16 addr, u16 data)
{
 	u8		buf_w[2];
 	buf_w[0] = ((data >> 8) & 0xff);
 	buf_w[1] = ((data >> 0) & 0xff);
 	return imx219_write(addr, buf_w, 2);
}



int imx219_init(int width, int height)
{
    int Status;
     XIicPs_Config *Config;  /**< configuration information for the device */

     Config = XIicPs_LookupConfig(IIC_DEVICE_ID);
     if(Config == NULL){
         printf("Error: XIicPs_LookupConfig()\n");
         return XST_FAILURE;
     }

     Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);
     if(Status != XST_SUCCESS){
         printf("Error: XIicPs_CfgInitialize()\n");
         return XST_FAILURE;
     }

     Status = XIicPs_SelfTest(&Iic);
     if(Status != XST_SUCCESS){
         printf("Error: XIicPs_SelfTest()\n");
         return XST_FAILURE;
     }

     XIicPs_SetSClk(&Iic, IIC_SCLK_RATE);
     printf("I2C configuration done.\n");

#if 0
	u8    buf_r[16];
	imx219_read(0x0000, buf_r, 2);
	printf("ID:%02x %02x\n\r", buf_r[0], buf_r[1]);
	imx219_read(0x0002, buf_r, 1);
	printf("0x02:%02x\n\r", buf_r[0]);
	imx219_read(0x0003, buf_r, 1);
	printf("0x02:%02x\n\r", buf_r[0]);
#endif


#define ORG_SETTING		0

	imx219_write_byte(0x0102, 0x01  );   // ???? (Reserved)
	//	imx219_write_word();
	imx219_write_byte(0x0100, 0x00  );   // mode_select [4:0]  (0: SW standby, 1: Streaming)
	imx219_write_word(0x6620, 0x0101);   // ????
	imx219_write_word(0x6622, 0x0101);

	imx219_write_byte(0x30EB, 0x0C  );   // Access command sequence Seq. No. 2
	imx219_write_byte(0x30EB, 0x05);
	imx219_write_word(0x300A, 0xFFFF);
	imx219_write_byte(0x30EB, 0x05);
	imx219_write_byte(0x30EB, 0x09);

	imx219_write_byte(0x0114, 0x01  );   // CSI_LANE_MODE (03: 4Lane 01: 2Lane)
	imx219_write_byte(0x0128, 0x00  );   // DPHY_CTRL (MIPI Global timing setting 0: auto mode, 1: manual mode)
	imx219_write_word(0x012a, 0x1800);   // INCK frequency [MHz] 6,144MHz
	imx219_write_byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	imx219_write_word(0x015A, 0x09BD);   //      COARSE_INTEGRATION_TIME_A
	imx219_write_word(0x0160, 0x0372);   //      FRM_LENGTH_A

#if ORG_SETTING
	imx219_write_word(0x0162, 0x0D78);   //      LINE_LENGTH_A (line_length_pck Units: Pixels)
	imx219_write_word(0x0164, 0x0000);   //      X_ADD_STA_A  x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
	imx219_write_word(0x0166, 0x0CCF);   //      X_ADD_END_A
	imx219_write_word(0x0168, 0x0000);   //      Y_ADD_STA_A
	imx219_write_word(0x016A, 0x099F);   //      Y_ADD_END_A
	imx219_write_word(0x016C, 0x0668);   //      x_output_size
	imx219_write_word(0x016E, 0x04D0);   //      y_output_size
#else
	imx219_write_word(0x0164, 3280/2 - width);    //      X_ADD_STA_A  x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
	imx219_write_word(0x0166, 3280/2 + width-1);  // 0xccf=3279     X_ADD_END_A
	imx219_write_word(0x0168, 2464/2 - height);    //      Y_ADD_STA_A
	imx219_write_word(0x016A, 2464/2 + height-1);  // 0x99f=2463     Y_ADD_END_A
	imx219_write_word(0x016C, width);    // 0x668=1640     x_output_size
	imx219_write_word(0x016E, height);   // 0x4d0=1232     y_output_size
#endif

#if ORG_SETTING
	imx219_write_word(0x0170, 0x0101);   //      X_ODD_INC_A  Increment for odd pixels 1, 3
	imx219_write_word(0x0174, 0x0101);   //      BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
#else
	imx219_write_word(0x0174, 0x0303);   // r     BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
#endif

	imx219_write_word(0x018C, 0x0A0A);   //      CSI_DATA_FORMAT_A   CSI-2 data format
	imx219_write_byte(0x0301, 0x05  );   //      VTPXCK_DIV  Video Timing Pixel Clock Divider Value
	imx219_write_word(0x0303, 0x0103);   //      VTSYCK_DIV  PREPLLCK_VT_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)
	imx219_write_word(0x0305, 0x0300);   //      PREPLLCK_OP_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)  / PLL_VT_MPY ãÊêÿÇËÇ™Ç®Ç©ÇµÇ¢éüÇ…ë±Ç≠
#if ORG_SETTING
	imx219_write_byte(0x0307, 0x39  );   //      PLL_VT_MPY
#else
	imx219_write_byte(0x0307, 87  );   // r PLL_VT_MPY
#endif

	imx219_write_byte(0x0309, 0x0A  );   //      OPPXCK_DIV
	imx219_write_word(0x030B, 0x0100);   //      OPSYCK_DIV PLL_OP_MPY[10:8] / ãÊêÿÇËÇ™Ç®Ç©ÇµÇ¢éüÇ…ë±Ç≠
	imx219_write_byte(0x030D, 0x72  );   //      PLL_OP_MPY[10:8]
	imx219_write_byte(0x455E, 0x00  );   //
	imx219_write_byte(0x471E, 0x4B  );   //
	imx219_write_byte(0x4767, 0x0F  );   //
	imx219_write_byte(0x4750, 0x14  );   //
	imx219_write_byte(0x4540, 0x00  );   //
	imx219_write_byte(0x47B4, 0x14  );   //
	imx219_write_byte(0x4713, 0x30  );   //
	imx219_write_byte(0x478B, 0x10  );   //
	imx219_write_byte(0x478F, 0x10  );   //
	imx219_write_byte(0x4793, 0x10  );   //
	imx219_write_byte(0x4797, 0x0E  );   //
	imx219_write_byte(0x479B, 0x0E  );   //


#if ORG_SETTING
	imx219_write_byte(0x0172, 0x03  );   //      IMG_ORIENTATION_A
	imx219_write_word(0x0160, 0x06E3);   //      FRM_LENGTH_A[15:8]
	imx219_write_word(0x0162, 0x0D78);   //      LINE_LENGTH_A
	imx219_write_word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A
	imx219_write_byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A

	imx219_write_byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	imx219_write_word(0x0160, 0x06E3);   //      FRM_LENGTH_A
	imx219_write_word(0x0162, 0x0D78);   //      LINE_LENGTH_A (line_length_pck Units: Pixels)
	imx219_write_word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A

	imx219_write_byte(0x0100, 0x01  );   //      mode_select [4:0] 0: SW standby, 1: Streaming

	imx219_write_byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	imx219_write_word(0x0160, 0x06E3);   //      FRM_LENGTH_A
	imx219_write_word(0x0162, 0x0D78);   //      LINE_LENGTH_A
	imx219_write_word(0x015A, 0x0421);   //      COARSE_INTEGRATION_TIME_A

	imx219_write_byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A

	imx219_write_word(0x0160, 0x0D02);   //      FRM_LENGTH_A
	imx219_write_word(0x0162, 0x0D78);   //      INE_LENGTH_A (line_length_pck Units: Pixels)
	imx219_write_word(0x015A, 0x0D02);   //      COARSE_INTEGRATION_TIME_A
	imx219_write_byte(0x0157, 0xE0  );   //      ANA_GAIN_GLOBAL_A
#else
	imx219_write_byte(0x0172, 0x00  );   //      IMG_ORIENTATION_A
	imx219_write_byte(0x0100, 0x01  );   //      mode_select [4:0] 0: SW standby, 1: Streaming
	imx219_write_byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	imx219_write_word(0x0160, 80);       // 0x0D02=3330   FRM_LENGTH_A
	imx219_write_word(0x0162, 0x0D78);   // 0x0D78=3448   LINE_LENGTH_A (line_length_pck Units: Pixels)
	imx219_write_word(0x015A, 50);       // 0x0D02=3330   COARSE_INTEGRATION_TIME_A
	imx219_write_byte(0x0157, 0xE0  );   //      ANA_GAIN_GLOBAL_A
//	imx219_write_byte(0x0157, 0xFF  );   //      ANA_GAIN_GLOBAL_A
	imx219_write_word(0x0158, 0x0FFF);   //      ANA_GAIN_GLOBAL_A
#endif

	return 0;
}
