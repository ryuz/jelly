#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include "UioMmap.h"
#include "I2cAccess.h"
//#include <opencv2/core.hpp>
//#include <opencv2/imgcodecs.hpp>
//#include <opencv2/highgui.hpp>
#include <opencv2/opencv.hpp>

#define FRAME_NUM		3
#define IMAGE_WIDTH		(3280 / 2)
#define IMAGE_HEIGHT	(2464 / 2)


/*
int i2c_test(void)
{
	int i2c = open("/dev/i2c-0", O_RDWR);
	if ( i2c < 0 ) {
		printf("I2C open error\n");
		return 1;
	}
	printf("I2C:%d\n", i2c);
	
	ioctl(i2c, I2C_SLAVE, 0x10);
	
	uint8_t	buf[16];
	int ret = 0;
	buf[0] = 0x00;
	buf[1] = 0x00;
    ret = write(i2c, buf, 2);
    printf("write:%d\n\r", ret);
	
	buf[0] = 0xff;
    ret = read(i2c, buf, 1);
    printf("read:%d\n\r", ret);
    
    printf("read:0x%02x\n\r", buf[0]);
	close(i2c);
	return 0;
}
*/



void capture_still_image(UioMmap& um_pl_peri, int width, int height, int frame_num)
{
	// DMA start (one shot)
	um_pl_peri.WriteWord32(0x00010020, 0x30000000);
	um_pl_peri.WriteWord32(0x00010024, width*2);				// stride
	um_pl_peri.WriteWord32(0x00010028, width);					// width
	um_pl_peri.WriteWord32(0x0001002c, height);					// height
	um_pl_peri.WriteWord32(0x00010030, width*height*frame_num);	// size
	um_pl_peri.WriteWord32(0x0001003c, 31);						// awlen
	um_pl_peri.WriteWord32(0x00010010, 0x07);
	
	// normalizer start
	um_pl_peri.WriteWord32(0x00011010, 1);
	um_pl_peri.WriteWord32(0x00011014, 100000000);
	um_pl_peri.WriteWord32(0x00011020, width);
	um_pl_peri.WriteWord32(0x00011024, height);
	um_pl_peri.WriteWord32(0x00011028, 0xfff);
	um_pl_peri.WriteWord32(0x0001102c, 0x10000);
	um_pl_peri.WriteWord32(0x00011000, 3);
	usleep(100000);
	
	
	// Žæ‚èž‚ÝŠ®—¹‚ð‘Ò‚Â
	usleep(10000);
	while ( um_pl_peri.ReadWord32(0x00010014) != 0 ) {
		usleep(10000);
	}
	
	// normalizer stop
	um_pl_peri.WriteWord32(0x00011000, 0);
	usleep(1000);
	while ( um_pl_peri.ReadWord32(0x00011004) != 0 ) {
		usleep(1000);
	}
}




int main()
{
//	return i2c_test();
	
	UioMmap um_pl_peri("my_pl_peri", 0x00200000);
	if ( !um_pl_peri.IsMapped() ) {
		printf("map error : my_pl_peri\n");
		return 1;
	}
	
	UioMmap um_pl_mem("my_pl_ddr3", 0x10000000);
	if ( !um_pl_mem.IsMapped() ) {
		printf("map error : my_pl_ddr3\n");
		return 1;
	}
	
//	volatile uint32_t *peri_addr = (volatile uint32_t *)um_pl_peri.GetAddress();
//	printf("hello:%x\n", peri_addr[0]);
	
	
//	cv::Mat img(IMAGE_HEIGHT, IMAGE_WIDTH, CV_16U);
	
	
	int w = 640;
	int h = 132;
	
	I2cAccess	i2c;
	
	if ( !i2c.Open("/dev/i2c-0", 0x10) ) {
		printf("I2C open error\n");
		return 1;
	}
	
//	printf("0x00 : %02x\n", i2c.ReadAddr16Byte(0x00));
//	printf("0x01 : %02x\n", i2c.ReadAddr16Byte(0x01));
	
	i2c.WriteAddr16Byte(0x0103, 0x01);
	usleep(10000);
	i2c.WriteAddr16Byte(0x0103, 0x00);
	usleep(10000);
	printf("0x00 : %02x\n", i2c.ReadAddr16Byte(0x00));
	printf("0x01 : %02x\n", i2c.ReadAddr16Byte(0x01));
	printf("%02x\n", i2c.ReadAddr16Byte(0x0103));
	
	
	i2c.WriteAddr16Byte(0x0102, 0x01  );   // ???? (Reserved)
//	i2c.WriteAddr16Word();
	i2c.WriteAddr16Byte(0x0100, 0x00  );   // mode_select [4:0]  (0: SW standby, 1: Streaming)
	i2c.WriteAddr16Word(0x6620, 0x0101);   // ????
	i2c.WriteAddr16Word(0x6622, 0x0101);
	
	/*
	i2c.WriteAddr16Byte(0x30EB, 0x0C  );   // Access command sequence Seq. No. 2
	i2c.WriteAddr16Byte(0x30EB, 0x05);
	i2c.WriteAddr16Word(0x300A, 0xFFFF);
	i2c.WriteAddr16Byte(0x30EB, 0x05);
	i2c.WriteAddr16Byte(0x30EB, 0x09);
	*/
	
	i2c.WriteAddr16Byte(0x30EB, 0x05);   // Access command sequence Seq.
	i2c.WriteAddr16Byte(0x30EB, 0x0C);
	i2c.WriteAddr16Byte(0x300A, 0xFF);
	i2c.WriteAddr16Byte(0x300B, 0xFF);
	i2c.WriteAddr16Byte(0x30EB, 0x05);
	i2c.WriteAddr16Byte(0x30EB, 0x09);
	
	i2c.WriteAddr16Byte(0x0114, 0x01  );   // * CSI_LANE_MODE (03: 4Lane 01: 2Lane)
	i2c.WriteAddr16Byte(0x0128, 0x00  );   //   DPHY_CTRL (MIPI Global timing setting 0: auto mode, 1: manual mode)
	i2c.WriteAddr16Word(0x012a, 0x1800);   // * INCK frequency [MHz] 6,144MHz
	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	i2c.WriteAddr16Word(0x015A, 0x09BD);   // 0x9bd=2493     COARSE_INTEGRATION_TIME_A
	i2c.WriteAddr16Word(0x0160, 0x0372);   // 0x372= 882     FRM_LENGTH_A
	
#if 0
	i2c.WriteAddr16Word(0x0162, 0x0D78);   // 0xD78=3448     LINE_LENGTH_A (line_length_pck Units: Pixels)  
	i2c.WriteAddr16Word(0x0164, 0x0000);   //      X_ADD_STA_A  x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
	i2c.WriteAddr16Word(0x0166, 0x0CCF);   // 0xccf=3279     X_ADD_END_A
	i2c.WriteAddr16Word(0x0168, 0x0000);   //      Y_ADD_STA_A
	i2c.WriteAddr16Word(0x016A, 0x099F);   // 0x99f=2463     Y_ADD_END_A
	i2c.WriteAddr16Word(0x016C, 0x0668);   // 0x668=1640     x_output_size
	i2c.WriteAddr16Word(0x016E, 0x04D0);   // 0x4d0=1232     y_output_size
#else
	i2c.WriteAddr16Word(0x0164, 3280/2 - w);    //      X_ADD_STA_A  x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
	i2c.WriteAddr16Word(0x0166, 3280/2 + w-1);  // 0xccf=3279     X_ADD_END_A
	i2c.WriteAddr16Word(0x0168, 2464/2 - h);    //      Y_ADD_STA_A
	i2c.WriteAddr16Word(0x016A, 2464/2 + h-1);  // 0x99f=2463     Y_ADD_END_A
	i2c.WriteAddr16Word(0x016C, w);   // 0x668=1640     x_output_size
	i2c.WriteAddr16Word(0x016E, h);   // 0x4d0=1232     y_output_size
#endif
	
	
	i2c.WriteAddr16Word(0x0170, 0x0101);   //      X_ODD_INC_A  Increment for odd pixels 1, 3
//	i2c.WriteAddr16Word(0x0170, 0x0303);   // r     X_ODD_INC_A  Increment for odd pixels 1, 3
//	i2c.WriteAddr16Word(0x0174, 0x0101);   //      BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
	i2c.WriteAddr16Word(0x0174, 0x0303);   // r     BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
	i2c.WriteAddr16Word(0x018C, 0x0A0A);   //      CSI_DATA_FORMAT_A   CSI-2 data format
	i2c.WriteAddr16Byte(0x0301, 0x05  );   // * VTPXCK_DIV  Video Timing Pixel Clock Divider Value
	i2c.WriteAddr16Word(0x0303, 0x0103);   // * VTSYCK_DIV  PREPLLCK_VT_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)
	i2c.WriteAddr16Word(0x0305, 0x0300);   // * PREPLLCK_OP_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)  / PLL_VT_MPY ‹æØ‚è‚ª‚¨‚©‚µ‚¢ŽŸ‚É‘±‚­
//	i2c.WriteAddr16Byte(0x0307, 0x39  );   // * PLL_VT_MPY
//	i2c.WriteAddr16Byte(0x0307, 84  );   // r PLL_VT_MPY
	i2c.WriteAddr16Byte(0x0307, 87  );   // r PLL_VT_MPY
	i2c.WriteAddr16Byte(0x0309, 0x0A  );   // * OPPXCK_DIV
	i2c.WriteAddr16Word(0x030B, 0x0100);   // * OPSYCK_DIV PLL_OP_MPY[10:8] / ‹æØ‚è‚ª‚¨‚©‚µ‚¢ŽŸ‚É‘±‚­
	i2c.WriteAddr16Byte(0x030D, 0x72  );   // * PLL_OP_MPY[10:8]
	
	i2c.WriteAddr16Byte(0x455E, 0x00  );   //
	i2c.WriteAddr16Byte(0x471E, 0x4B  );   //
	i2c.WriteAddr16Byte(0x4767, 0x0F  );   //
	i2c.WriteAddr16Byte(0x4750, 0x14  );   //
	i2c.WriteAddr16Byte(0x4540, 0x00  );   //
	i2c.WriteAddr16Byte(0x47B4, 0x14  );   //
	i2c.WriteAddr16Byte(0x4713, 0x30  );   //
	i2c.WriteAddr16Byte(0x478B, 0x10  );   //
	i2c.WriteAddr16Byte(0x478F, 0x10  );   //
	i2c.WriteAddr16Byte(0x4793, 0x10  );   //
	i2c.WriteAddr16Byte(0x4797, 0x0E  );   //
	i2c.WriteAddr16Byte(0x479B, 0x0E  );   //

	i2c.WriteAddr16Byte(0x0172, 0x03  );   //      IMG_ORIENTATION_A
	
//	i2c.WriteAddr16Word(0x0160, 0x06E3);   //      FRM_LENGTH_A[15:8]
//	i2c.WriteAddr16Word(0x0162, 0x0D78);   //      LINE_LENGTH_A
//	i2c.WriteAddr16Word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A
//	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A

//	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
//	i2c.WriteAddr16Word(0x0160, 0x06E3);   //      FRM_LENGTH_A
//	i2c.WriteAddr16Word(0x0162, 0x0D78);   //      LINE_LENGTH_A (line_length_pck Units: Pixels)
//	i2c.WriteAddr16Word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A

	i2c.WriteAddr16Byte(0x0100, 0x01  );   //      mode_select [4:0] 0: SW standby, 1: Streaming

//	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
//	i2c.WriteAddr16Word(0x0160, 0x06E3);   // 0x06E3=3330   FRM_LENGTH_A
//	i2c.WriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   LINE_LENGTH_A
//	i2c.WriteAddr16Word(0x015A, 0x0421);   // 0x0421=1057   COARSE_INTEGRATION_TIME_A

#if 0
	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	i2c.WriteAddr16Word(0x0160, 0x0D02);   // 0x0D02=3330   FRM_LENGTH_A
	i2c.WriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   INE_LENGTH_A (line_length_pck Units: Pixels)
	i2c.WriteAddr16Word(0x015A, 0x0D02);   // 0x0D02=3330   COARSE_INTEGRATION_TIME_A
	i2c.WriteAddr16Byte(0x0157, 0xE0  );   //      ANA_GAIN_GLOBAL_A
#else
	i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
	i2c.WriteAddr16Word(0x0160, 80);       // 0x0D02=3330   FRM_LENGTH_A
	i2c.WriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   LINE_LENGTH_A (line_length_pck Units: Pixels)
	i2c.WriteAddr16Word(0x015A, 50);       // 0x0D02=3330   COARSE_INTEGRATION_TIME_A
	i2c.WriteAddr16Byte(0x0157, 0xE0  );   //      ANA_GAIN_GLOBAL_A
#endif
	
	
	
//	int width  = 640; // IMAGE_WIDTH;
//	int height = 120; // IMAGE_HEIGHT;
//	int width  = 0x48e; // 640; // IMAGE_WIDTH;
//	int height = 0xD78; // 120; // IMAGE_HEIGHT;
	int width  = w;
	int height = h; // IMAGE_HEIGHT / 2;
	
	void* mem_addr = um_pl_mem.GetAddress();
	
	{
		int		frame_num = 3;
		int		key;
		while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
			cv::Mat img(height*frame_num, width, CV_16U);
			memcpy(img.data, (void *)mem_addr, width * height * 2 * frame_num);
			cv::imshow("img", img);
//			cv::imwrite("img.png", img);
			cv::createTrackbar("width",  "img", &width,     IMAGE_WIDTH);
			cv::createTrackbar("height", "img", &height,    IMAGE_HEIGHT);
			cv::createTrackbar("frame",  "img", &frame_num, 10);
			
			width &= 0xfffffff0;
			if ( width  < 16 ) { width  = 16; }
			if ( height < 2 )  { height = 2; }
			
			capture_still_image(um_pl_peri, width, height, frame_num);
		}
	}
	
	return 0;
	
	
	// DMA stop
	um_pl_peri.WriteWord32(0x00010010, 0x00);
	usleep(100000);
//	while ( um_pl_peri.ReadWord32(0x00010014) != 0 ) {
//		um_pl_peri.WriteWord32(0x00011000, 1);
//		usleep(100000);
//	}
//	um_pl_peri.WriteWord32(0x00011000, 0);
//	usleep(100000);
	
	
	// normalizer
	um_pl_peri.WriteWord32(0x00011010, 1);
	um_pl_peri.WriteWord32(0x00011014, 100000000);
	um_pl_peri.WriteWord32(0x00011020, width);
	um_pl_peri.WriteWord32(0x00011024, height);
	um_pl_peri.WriteWord32(0x00011028, 0xfff);
	um_pl_peri.WriteWord32(0x0001102c, 0x10000);
	um_pl_peri.WriteWord32(0x00011000, 3);
	usleep(1000000);
	
	printf("normalizer\n");
	printf("0x00011000:%08x\n", um_pl_peri.ReadWord32(0x00011000));
	printf("0x00011004:%08x\n", um_pl_peri.ReadWord32(0x00011004));
	printf("0x00011008:%08x\n", um_pl_peri.ReadWord32(0x00011008));
	printf("0x0001100c:%08x\n", um_pl_peri.ReadWord32(0x0001100c));
	printf("0x00011010:%08x\n", um_pl_peri.ReadWord32(0x00011010));
	printf("0x00011014:%08x\n", um_pl_peri.ReadWord32(0x00011014));
	printf("0x00011020:%08x\n", um_pl_peri.ReadWord32(0x00011020));	// width);
	printf("0x00011024:%08x\n", um_pl_peri.ReadWord32(0x00011024));	// height);
	printf("0x00011028:%08x\n", um_pl_peri.ReadWord32(0x00011028));	// 0x400);
	printf("0x0001102c:%08x\n", um_pl_peri.ReadWord32(0x0001102c));	// 0xfff);
	
	int		enable = 1;
	
	int		key;
	while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
		cv::Mat img(height, width, CV_16U);
		memcpy(img.data, (void *)mem_addr, width * height * 2);
		cv::imshow("img", img);
		cv::createTrackbar("en", "img", &enable, 1);
		
		um_pl_peri.WriteWord32(0x00010020, 0x30000000);
		um_pl_peri.WriteWord32(0x00010024, width*2);		// stride
		um_pl_peri.WriteWord32(0x00010028, width);			// width
		um_pl_peri.WriteWord32(0x0001002c, height);			// height
		um_pl_peri.WriteWord32(0x00010030, width*height);	// size
		um_pl_peri.WriteWord32(0x0001003c, 31);				// awlen
		um_pl_peri.WriteWord32(0x00010010, 0x07);
		
		// Žæ‚èž‚ÝŠ®—¹‚ð‘Ò‚Â
		usleep(10000);
		while ( um_pl_peri.ReadWord32(0x00010014) != 0 ) {
			usleep(10000);
			printf(".");
		}
		printf("\n");
	}
	
	
	um_pl_peri.WriteWord32(0x00010010, 0x00);
	usleep(100000);
	
	return 0;
}



