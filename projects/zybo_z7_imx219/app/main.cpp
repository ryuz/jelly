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
#include <opencv2/opencv.hpp>

// #include "UioMmap.h"

#include "jelly/UioAccess.h"
#include "jelly/UdmabufAccess.h"
#include "I2cAccess.h"
#include "IMX219Control.h"

using namespace jelly;


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

// Video Write-DMA
#define REG_WDMA_ID            		0x00
#define REG_WDMA_VERSION       		0x01
#define REG_WDMA_CTL_CONTROL   		0x04
#define REG_WDMA_CTL_STATUS    		0x05
#define REG_WDMA_CTL_INDEX     		0x07
#define REG_WDMA_PARAM_ADDR    		0x08
#define REG_WDMA_PARAM_STRIDE  		0x09
#define REG_WDMA_PARAM_WIDTH   		0x0a
#define REG_WDMA_PARAM_HEIGHT  		0x0b
#define REG_WDMA_PARAM_SIZE    		0x0c
#define REG_WDMA_PARAM_AWLEN   		0x0f
#define REG_WDMA_MONITOR_ADDR  		0x10
#define REG_WDMA_MONITOR_STRIDE		0x11
#define REG_WDMA_MONITOR_WIDTH 		0x12
#define REG_WDMA_MONITOR_HEIGHT		0x13
#define REG_WDMA_MONITOR_SIZE  		0x14
#define REG_WDMA_MONITOR_AWLEN 		0x17

// Video Normalizer
#define REG_NORM_CONTROL            0x00
#define REG_NORM_BUSY               0x01
#define REG_NORM_INDEX              0x02
#define REG_NORM_SKIP               0x03
#define REG_NORM_FRM_TIMER_EN       0x04
#define REG_NORM_FRM_TIMEOUT        0x05
#define REG_NORM_PARAM_WIDTH        0x08
#define REG_NORM_PARAM_HEIGHT       0x09
#define REG_NORM_PARAM_FILL         0x0a
#define REG_NORM_PARAM_TIMEOUT      0x0b


void capture_still_image(MemAccess& reg_wdma, MemAccess& reg_norm, std::uintptr_t bufaddr, int width, int height, int frame_num)
{
	// DMA start (one shot)
	reg_wdma.WriteReg(REG_WDMA_PARAM_ADDR, bufaddr); // 0x30000000);
	reg_wdma.WriteReg(REG_WDMA_PARAM_STRIDE, width*4);				// stride
	reg_wdma.WriteReg(REG_WDMA_PARAM_WIDTH, width);					// width
	reg_wdma.WriteReg(REG_WDMA_PARAM_HEIGHT, height);				// height
	reg_wdma.WriteReg(REG_WDMA_PARAM_SIZE, width*height*frame_num);	// size
	reg_wdma.WriteReg(REG_WDMA_PARAM_AWLEN, 31);					// awlen
	reg_wdma.WriteReg(REG_WDMA_CTL_CONTROL, 0x07);
	
	// normalizer start
	reg_norm.WriteReg(REG_NORM_FRM_TIMER_EN, 1);
	reg_norm.WriteReg(REG_NORM_FRM_TIMEOUT, 100000000);
	reg_norm.WriteReg(REG_NORM_PARAM_WIDTH, width);
	reg_norm.WriteReg(REG_NORM_PARAM_HEIGHT, height);
	reg_norm.WriteReg(REG_NORM_PARAM_FILL, 0xfff);
	reg_norm.WriteReg(REG_NORM_PARAM_TIMEOUT, 0x10000);
	reg_norm.WriteReg(REG_NORM_CONTROL, 0x03);
	usleep(100000);
	
	// Žæ‚èž‚ÝŠ®—¹‚ð‘Ò‚Â
	usleep(10000);
	while ( reg_wdma.ReadReg(REG_WDMA_CTL_STATUS) != 0 ) {
		usleep(10000);
	}
	
	// normalizer stop
	reg_norm.WriteReg(REG_NORM_CONTROL, 0x00);
	usleep(1000);
	while ( reg_wdma.ReadReg(REG_NORM_BUSY) != 0 ) {
		usleep(1000);
	}
}


int main()
{
	// mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccess uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }
	auto reg_wdma = uio_acc.GetMemAccess(0x00010000);
	auto reg_norm = uio_acc.GetMemAccess(0x00011000);
	
   	// mmap udmabuf
    std::cout << "\nudmabuf0 open" << std::endl;
    UdmabufAccess udmabuf_acc("udmabuf0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf0 mmap error" << std::endl;
        return 1;
    }
    std::cout << "udmabuf0 phys addr : " << std::hex << udmabuf_acc.GetPhysAddr() << std::endl;
    std::cout << "udmabuf0 size      : " << std::hex << udmabuf_acc.GetSize()     << std::endl;


	
	int w = 640;
	int h = 132;
	
	IMX219ControlI2c imx219;
	if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
		printf("I2C open error\n");
		return 1;
	}
	imx219.Setup();

#if 0
	I2cAccess	i2c;
	if ( !i2c.Open("/dev/i2c-0", 0x10) ) {
		printf("I2C open error\n");
		return 1;
	}

	i2c.WriteAddr16Byte(0x0103, 0x01);
	usleep(10000);
	i2c.WriteAddr16Byte(0x0103, 0x00);
	usleep(10000);

	printf("%02x\n", i2c.ReadAddr16Byte(0x0162));
	printf("%02x\n", i2c.ReadAddr16Byte(0x0163));
	i2c.WriteAddr16Word(0x0162, 0x0D76);
	printf("%02x\n", i2c.ReadAddr16Byte(0x0162));
	printf("%02x\n", i2c.ReadAddr16Byte(0x0163));
	i2c.WriteAddr16Byte(0x0103, 0x01);
	usleep(10000);
	printf("%02x\n", i2c.ReadAddr16Byte(0x0162));
	printf("%02x\n", i2c.ReadAddr16Byte(0x0163));
	return 0;

/*
	FILE* fp = fopen("reg_log.txt", "w");
	for ( int i = 0; i < 0x4000; ++i ) {
		if ( i % 16 == 0 ) { fprintf(fp, "%04x : ", i); }
		fprintf(fp, "%02x ", i2c.ReadAddr16Byte(i));
		if ( i % 16 == 15 ) { fprintf(fp, "\n"); }
	}
	fclose(fp);
*/

//	i2c.WriteAddr16Byte(0x0103, 1);
//	printf("SW_RESET:%02x\n", i2c.ReadAddr16Byte(0x0103));
	
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
//	i2c.WriteAddr16Byte(0x0157, 0xFF  );   //      ANA_GAIN_GLOBAL_A
	i2c.WriteAddr16Word(0x0158, 0x0FFF);   //      ANA_GAIN_GLOBAL_A
#endif
	
#endif	
	
//	int width  = 640; // IMAGE_WIDTH;
//	int height = 120; // IMAGE_HEIGHT;
//	int width  = 0x48e; // 640; // IMAGE_WIDTH;
//	int height = 0xD78; // 120; // IMAGE_HEIGHT;
	int width  = w;
	int height = h; // IMAGE_HEIGHT / 2;
	
//	void* mem_addr = um_pl_mem.GetAddress();
	auto dmabuf_ptr      = udmabuf_acc.GetPtr();
	auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();

	{
		int		frame_num = 1;
		int		key;
		while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
			cv::Mat img(height*frame_num, width, CV_8UC4);
			memcpy(img.data, dmabuf_ptr, width * height * 4 * frame_num);
			cv::imshow("img", img);
			cv::imwrite("img.png", img);
			cv::createTrackbar("width",  "img", &width,     IMAGE_WIDTH);
			cv::createTrackbar("height", "img", &height,    IMAGE_HEIGHT);
			cv::createTrackbar("frame",  "img", &frame_num, 10);
			
			width &= 0xfffffff0;
			if ( width  < 16 ) { width  = 16; }
			if ( height < 2 )  { height = 2; }
			
			capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, frame_num);
			
			if ( key == 'r' ) {
				printf("record\n");
				capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, 100);
				char* p = (char*)dmabuf_ptr;
				for ( int i = 0; i< 100; i++ ) {
					char fname[64];
					sprintf(fname, "rec_%04d.png", i);
					cv::Mat imgRec(height, width, CV_8UC4);
					memcpy(imgRec.data, p, width * height * 4);	p += width * height * 4;
					cv::Mat imgRgb;
					cv::cvtColor(imgRec, imgRgb, CV_BGRA2BGR);
					cv::imwrite(fname, imgRgb);
				}
			}
		}
	}
	
	return 0;
}



