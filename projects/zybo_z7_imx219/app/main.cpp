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
	reg_norm.WriteReg(REG_NORM_PARAM_FILL, 0x0ff);
	reg_norm.WriteReg(REG_NORM_PARAM_TIMEOUT, 0x100000);
	reg_norm.WriteReg(REG_NORM_CONTROL, 0x03);
	usleep(100000);
	
	// 取り込み完了を待つ
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
	auto dmabuf_ptr      = udmabuf_acc.GetPtr();
	auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    std::cout << "udmabuf0 phys addr : " << std::hex << dmabuf_ptr << std::endl;
    std::cout << "udmabuf0 size      : " << std::hex << dmabuf_phys_adr << std::endl;


	int width  = 3280; // 3280 / 4;
	int height = 2464; // 2464;

//			width &= 0xfffffff0;
//			if ( width  < 16 ) { width  = 16; }
//			if ( height < 2 )  { height = 2; }

	IMX219ControlI2c imx219;
	if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
		printf("I2C open error\n");
		return 1;
	}

#if 1
	width  = 640;
	height = 132;
	imx219.SetPixelClock(139200000);
	imx219.SetGain(30.0);
	imx219.SetDigitalGain(30.0);
	imx219.SetAoi(width, height, -1, -1, true, true);
//	imx219.Setup();
#else
	width  = 3280;
	height = 2464;
	imx219.SetPixelClock(91000000);
	imx219.SetGain(10.0);
	imx219.SetDigitalGain(0.0);
	imx219.SetAoi(width, height, 8, 8, false, false);
//	imx219.Setup();
#endif
	imx219.SetFlip(true, true);

	imx219.Start();

	int fps      = 1000;
	int exposure = 1;
	int a_gain   = 20;
	int d_gain   = 24;
	{
		int		frame_num = 1;
		int		key;
		while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
			capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, frame_num);
			cv::Mat img(height*frame_num, width, CV_8UC4);
			memcpy(img.data, dmabuf_ptr, width * height * 4 * frame_num);
			cv::imshow("img", img);
			cv::createTrackbar("fps",      "img", &fps, 1000);
			cv::createTrackbar("exposure", "img", &exposure, 100);
			cv::createTrackbar("a_gain",   "img", &a_gain, 20);
			cv::createTrackbar("d_gain",   "img", &d_gain, 24);

			imx219.SetFrameRate(fps);
			imx219.SetExposureTime(exposure / 1000.0);
			imx219.SetGain(a_gain);
			imx219.SetDigitalGain(d_gain);

			if ( key == 'p' ) {
				std::cout << "pixel clock   : " << imx219.GetPixelClock()   << " [Hz]"  << std::endl;
				std::cout << "frame rate    : " << imx219.GetFrameRate()    << " [fps]" << std::endl;
				std::cout << "exposure time : " << imx219.GetExposureTime() << " [s]"   << std::endl;
				std::cout << "analog  gain  : " << imx219.GetGain()         << " [db]"  << std::endl;
				std::cout << "digital gain  : " << imx219.GetDigitalGain()  << " [db]"  << std::endl;
			}

			if ( key == 'd' ) {
				cv::Mat imgRgb;
				cv::cvtColor(img, imgRgb, CV_BGRA2BGR);
				cv::imwrite("img.png", imgRgb);
			}

			if ( key == 'r' ) {
				printf("record\n");
				capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, 1);
				char* p = (char*)dmabuf_ptr;
				for ( int i = 0; i< 1; i++ ) {
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



