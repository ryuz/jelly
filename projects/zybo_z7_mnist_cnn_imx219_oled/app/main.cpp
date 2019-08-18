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

#include "UioMmap.h"
#include "I2cAccess.h"



#define DVITX_WIDTH                         1280
#define DVITX_HEIGHT                        720
#define DVITX_STRIDE                        8192


#define IMG_MEM_ADDR						0x30000000

#define VIN_NORM_BASE_ADDR					0x00011000
#define	VIN_NORM_REG_CONTROL      			(VIN_NORM_BASE_ADDR + 0x00*4)
#define	VIN_NORM_REG_BUSY         			(VIN_NORM_BASE_ADDR + 0x01*4)
#define	VIN_NORM_REG_INDEX        			(VIN_NORM_BASE_ADDR + 0x02*4)
#define	VIN_NORM_REG_SKIP         			(VIN_NORM_BASE_ADDR + 0x03*4)
#define	VIN_NORM_REG_FRM_TIMER_EN 			(VIN_NORM_BASE_ADDR + 0x04*4)
#define	VIN_NORM_REG_FRM_TIMEOUT  			(VIN_NORM_BASE_ADDR + 0x05*4)
#define	VIN_NORM_REG_PARAM_WIDTH  			(VIN_NORM_BASE_ADDR + 0x08*4)
#define	VIN_NORM_REG_PARAM_HEIGHT 			(VIN_NORM_BASE_ADDR + 0x09*4)
#define	VIN_NORM_REG_PARAM_FILL   			(VIN_NORM_BASE_ADDR + 0x0a*4)
#define	VIN_NORM_REG_PARAM_TIMEOUT			(VIN_NORM_BASE_ADDR + 0x0b*4)

#define VDMAW_BASE_ADDR						0x00010000
#define VDMAW_REG_ID						(VDMAW_BASE_ADDR + 0x0000)
#define VDMAW_REG_VERSION					(VDMAW_BASE_ADDR + 0x0004)
#define VDMAW_REG_CTL_CONTROL				(VDMAW_BASE_ADDR + 0x0010)
#define VDMAW_REG_CTL_STATUS				(VDMAW_BASE_ADDR + 0x0014)
#define VDMAW_REG_CTL_INDEX 				(VDMAW_BASE_ADDR + 0x001c)
#define VDMAW_REG_PARAM_ADDR				(VDMAW_BASE_ADDR + 0x0020)
#define VDMAW_REG_PARAM_STRIDE				(VDMAW_BASE_ADDR + 0x0024)
#define VDMAW_REG_PARAM_WIDTH				(VDMAW_BASE_ADDR + 0x0028)
#define VDMAW_REG_PARAM_HEIGHT				(VDMAW_BASE_ADDR + 0x002c)
#define VDMAW_REG_PARAM_SIZE				(VDMAW_BASE_ADDR + 0x0030)
#define VDMAW_REG_PARAM_AWLEN				(VDMAW_BASE_ADDR + 0x003c)
#define VDMAW_REG_MONITOR_ADDR				(VDMAW_BASE_ADDR + 0x0040)
#define VDMAW_REG_MONITOR_STRIDE			(VDMAW_BASE_ADDR + 0x0044)
#define VDMAW_REG_MONITOR_WIDTH 			(VDMAW_BASE_ADDR + 0x0048)
#define VDMAW_REG_MONITOR_HEIGHT			(VDMAW_BASE_ADDR + 0x004c)
#define VDMAW_REG_MONITOR_SIZE				(VDMAW_BASE_ADDR + 0x0050)
#define VDMAW_REG_MONITOR_AWLEN 			(VDMAW_BASE_ADDR + 0x005c)

#define VDMAR_BASE_ADDR 					0x00020000
#define VDMAR_REG_ID						(VDMAR_BASE_ADDR + 0x0000)
#define VDMAR_REG_VERSION					(VDMAR_BASE_ADDR + 0x0004)
#define VDMAR_REG_CTL_CONTROL				(VDMAR_BASE_ADDR + 0x0010)
#define VDMAR_REG_CTL_STATUS				(VDMAR_BASE_ADDR + 0x0014)
#define VDMAR_REG_CTL_INDEX 				(VDMAR_BASE_ADDR + 0x001c)
#define VDMAR_REG_PARAM_ADDR				(VDMAR_BASE_ADDR + 0x0020)
#define VDMAR_REG_PARAM_STRIDE				(VDMAR_BASE_ADDR + 0x0024)
#define VDMAR_REG_PARAM_WIDTH				(VDMAR_BASE_ADDR + 0x0028)
#define VDMAR_REG_PARAM_HEIGHT				(VDMAR_BASE_ADDR + 0x002c)
#define VDMAR_REG_PARAM_SIZE				(VDMAR_BASE_ADDR + 0x0030)
#define VDMAR_REG_PARAM_ARLEN				(VDMAR_BASE_ADDR + 0x003c)
#define VDMAR_REG_MONITOR_ADDR				(VDMAR_BASE_ADDR + 0x0040)
#define VDMAR_REG_MONITOR_STRIDE			(VDMAR_BASE_ADDR + 0x0044)
#define VDMAR_REG_MONITOR_WIDTH 			(VDMAR_BASE_ADDR + 0x0048)
#define VDMAR_REG_MONITOR_HEIGHT			(VDMAR_BASE_ADDR + 0x004c)
#define VDMAR_REG_MONITOR_SIZE				(VDMAR_BASE_ADDR + 0x0050)
#define VDMAR_REG_MONITOR_ARLEN 			(VDMAR_BASE_ADDR + 0x005c)

#define	VOUT_VSGEN_BASE_ADDR				0x00021000
#define	VOUT_VSGEN_REG_ID                	(VOUT_VSGEN_BASE_ADDR + 0x0000)
#define	VOUT_VSGEN_REG_VERSION           	(VOUT_VSGEN_BASE_ADDR + 0x0004)
#define	VOUT_VSGEN_REG_CTL_CONTROL       	(VOUT_VSGEN_BASE_ADDR + 0x0010)
#define	VOUT_VSGEN_REG_CTL_STATUS        	(VOUT_VSGEN_BASE_ADDR + 0x0014)
#define	VOUT_VSGEN_REG_PARAM_HTOTAL      	(VOUT_VSGEN_BASE_ADDR + 0x0020)
#define	VOUT_VSGEN_REG_PARAM_HSYNC_POL   	(VOUT_VSGEN_BASE_ADDR + 0x002c)
#define	VOUT_VSGEN_REG_PARAM_HDISP_START 	(VOUT_VSGEN_BASE_ADDR + 0x0030)
#define	VOUT_VSGEN_REG_PARAM_HDISP_END   	(VOUT_VSGEN_BASE_ADDR + 0x0034)
#define	VOUT_VSGEN_REG_PARAM_HSYNC_START 	(VOUT_VSGEN_BASE_ADDR + 0x0038)
#define	VOUT_VSGEN_REG_PARAM_HSYNC_END   	(VOUT_VSGEN_BASE_ADDR + 0x003c)
#define	VOUT_VSGEN_REG_PARAM_VTOTAL      	(VOUT_VSGEN_BASE_ADDR + 0x0040)
#define	VOUT_VSGEN_REG_PARAM_VSYNC_POL   	(VOUT_VSGEN_BASE_ADDR + 0x004c)
#define	VOUT_VSGEN_REG_PARAM_VDISP_START 	(VOUT_VSGEN_BASE_ADDR + 0x0050)
#define	VOUT_VSGEN_REG_PARAM_VDISP_END   	(VOUT_VSGEN_BASE_ADDR + 0x0054)
#define	VOUT_VSGEN_REG_PARAM_VSYNC_START 	(VOUT_VSGEN_BASE_ADDR + 0x0058)
#define	VOUT_VSGEN_REG_PARAM_VSYNC_END   	(VOUT_VSGEN_BASE_ADDR + 0x005c)




void oled_init(UioMmap* p);
int  oled_main();

void camera_setup(I2cAccess& i2c, int w, int h);                                                                 // カメラ初期化
void capture_still_image(UioMmap& um_pl_peri, int offset, int width, int height, int stride, int frame_num);    // DDR3-SDRAM経由で画像をキャプチャ
void start_viewer_dma   (UioMmap& um_pl_peri, int offset, int width, int height, int stride, int frame_num);
void write_back_image(void* mem_addr);

// メイン関数
int main(int argc, char *argv[])
{
    bool gui  = false;
    bool stop = false;
    if ( argc >= 2 && strcmp(argv[1], "gui") == 0 ) {
        gui = true;
    }
    if ( argc >= 2 && strcmp(argv[1], "stop") == 0 ) {
        stop = true;
    }
    
    
    // UIOオープン
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
    
    
    // 一旦すべてのDMA等を止める
    um_pl_peri.WriteWord32(VDMAR_REG_CTL_CONTROL, 0x0);
    um_pl_peri.WriteWord32(VDMAW_REG_CTL_CONTROL, 0x0);
    while ( um_pl_peri.ReadWord32(VDMAR_REG_CTL_STATUS) != 0 ) {
        usleep(1000);
    }
    while ( um_pl_peri.ReadWord32(VDMAW_REG_CTL_STATUS) != 0 ) {
        usleep(1000);
    }
    
    // normalizer stop
    um_pl_peri.WriteWord32(0x00011000, 0);
    usleep(1000);
    while ( um_pl_peri.ReadWord32(0x00011004) != 0 ) {
        usleep(1000);
    }
    
    // 止めるだけならここで終了
    if ( stop ) {
        printf("stop\n");
        return 0;
    }
    
    
    // OLED初期化
    oled_init(&um_pl_peri);
    oled_main();
    
    
    // カメラサイズ
    int width  = 640;
    int height = 132;
    
    // DVIへの表示位置
    int dvi_x  = (DVITX_WIDTH  - width ) / 2;
    int dvi_y  = (DVITX_HEIGHT - height) / 2;
    
    int stride = DVITX_STRIDE;
    int offset = DVITX_STRIDE * dvi_y + dvi_x * 4;
    void* mem_addr = um_pl_mem.GetAddress();
    
    
    // カメラ初期化
    I2cAccess   i2c;
    if ( !i2c.Open("/dev/i2c-0", 0x10) ) {
        printf("I2C open error\n");
        return 1;
    }
    
    i2c.WriteAddr16Byte(0x0103, 0x01);
    usleep(10000);
    i2c.WriteAddr16Byte(0x0103, 0x00);
    usleep(10000);
    printf("0x00 : %02x\n", i2c.ReadAddr16Byte(0x00));
    printf("0x01 : %02x\n", i2c.ReadAddr16Byte(0x01));
    printf("%02x\n", i2c.ReadAddr16Byte(0x0103));
    
    camera_setup(i2c, width, height);
    
    
    
    // demosaic param_phase
    um_pl_peri.WriteWord32(0x00012000, 0);
    
    // color map
    um_pl_peri.WriteWord32(0x00019040, 0x0000000);  // 黒
    um_pl_peri.WriteWord32(0x00019044, 0x0000080);  // 茶
    um_pl_peri.WriteWord32(0x00019048, 0x00000ff);  // 赤
    um_pl_peri.WriteWord32(0x0001904c, 0x04cb7ff);  // 橙
    um_pl_peri.WriteWord32(0x00019050, 0x000ffff);  // 黄
    um_pl_peri.WriteWord32(0x00019054, 0x0008000);  // 緑
    um_pl_peri.WriteWord32(0x00019058, 0x0ff0000);  // 青
    um_pl_peri.WriteWord32(0x0001905c, 0x0800080);  // 紫
    um_pl_peri.WriteWord32(0x00019060, 0x0808080);  // 灰
    um_pl_peri.WriteWord32(0x00019064, 0x0ffffff);  // 白
    
    
    // UI
    int view_sel   = 0;     // 表示ソースの選択
    int bin_th     = 127;   // 2値化閾値
    int dnn0_en    = 1;     // DNN0の表示有効化
    int dnn1_en    = 1;     // DNN1の表示有効化
    int dnn0_th    = 127;   // classifierの閾値
    int dnn0_lpf   = 0;     // classifierのLPF強度
    int dnn1_th    = 127;   // detectorの閾値
    int dnn1_lpf   = 0;     // detectorのLPF強度
    
    
    // パラメータ設定
    um_pl_peri.WriteWord32(0x00019000, dnn0_en + (dnn1_en << 1));
    um_pl_peri.WriteWord32(0x00019004, view_sel);
    um_pl_peri.WriteWord32(0x00019008, dnn0_th);
    um_pl_peri.WriteWord32(0x0001900c, dnn1_th);
    um_pl_peri.WriteWord32(0x00015000, dnn0_lpf);
    um_pl_peri.WriteWord32(0x00015040, dnn1_lpf);
    
    // 背景画像展開
    write_back_image(mem_addr);
    
    
    // DVI-TX start DMA read
    um_pl_peri.WriteWord32(VDMAR_REG_PARAM_ADDR,   0x30000000);
    um_pl_peri.WriteWord32(VDMAR_REG_PARAM_STRIDE, DVITX_STRIDE);
    um_pl_peri.WriteWord32(VDMAR_REG_PARAM_WIDTH,  DVITX_WIDTH);
    um_pl_peri.WriteWord32(VDMAR_REG_PARAM_HEIGHT, DVITX_HEIGHT);
    um_pl_peri.WriteWord32(VDMAR_REG_PARAM_SIZE,   DVITX_WIDTH*DVITX_HEIGHT);
    um_pl_peri.WriteWord32(VDMAR_REG_PARAM_ARLEN,  31);
    um_pl_peri.WriteWord32(VDMAR_REG_CTL_CONTROL,  0x3);
    
    um_pl_peri.WriteWord32(VOUT_VSGEN_REG_CTL_CONTROL, 1);
    
    
    
    int     frame_num = 1;
    int     key = -1;
    do {
        // 画像取り込み
        capture_still_image(um_pl_peri, offset, width, height, stride, frame_num);
        cv::Mat img(height*frame_num, width, CV_8UC4);
        {
            char* p = (char*)mem_addr;
            p += offset;
            for ( int i = 0; i < height * frame_num; ++i ) {
                memcpy(&img.data[width*4*i], p, width*4);
                p += stride;
            }
        }
        
        // GUI表示
        if ( gui ) {
            cv::imshow("img", img);
            
    //      cv::createTrackbar("width",   "img", &width,      IMAGE_WIDTH);
    //      cv::createTrackbar("height",  "img", &height,     IMAGE_HEIGHT);
    //      cv::createTrackbar("frame",   "img", &frame_num,  10);
            
            cv::createTrackbar("view_sel", "img", &view_sel,  15);
            cv::createTrackbar("bin_th",   "img", &bin_th,   255);
            cv::createTrackbar("dnn0_en",  "img", &dnn0_en,    1);
            cv::createTrackbar("dnn1_en",  "img", &dnn1_en,    1);
            cv::createTrackbar("dnn0_th",  "img", &dnn0_th,  255);
            cv::createTrackbar("dnn0_lpf", "img", &dnn0_lpf, 255);
            cv::createTrackbar("dnn1_th",  "img", &dnn1_th,  255);
            cv::createTrackbar("dnn1_lpf", "img", &dnn1_lpf, 255);
        }
        
        
        width &= 0xfffffff0;
        if ( width  < 16 ) { width  = 16; }
        if ( height < 2 )  { height = 2; }
        
        
        if ( bin_th == 0 ) {
            // PWMモード(テーブルサイズ=15)
            um_pl_peri.WriteWord32(0x00018100 + 4*0,  0x10);
            um_pl_peri.WriteWord32(0x00018100 + 4*1,  0xf0);
            um_pl_peri.WriteWord32(0x00018100 + 4*2,  0x70);
            um_pl_peri.WriteWord32(0x00018100 + 4*3,  0x90);
            um_pl_peri.WriteWord32(0x00018100 + 4*4,  0x30);
            um_pl_peri.WriteWord32(0x00018100 + 4*5,  0xd0);
            um_pl_peri.WriteWord32(0x00018100 + 4*6,  0x50);
            um_pl_peri.WriteWord32(0x00018100 + 4*7,  0xb0);
            um_pl_peri.WriteWord32(0x00018100 + 4*8,  0x20);
            um_pl_peri.WriteWord32(0x00018100 + 4*9,  0xe0);
            um_pl_peri.WriteWord32(0x00018100 + 4*10, 0x60);
            um_pl_peri.WriteWord32(0x00018100 + 4*11, 0xa0);
            um_pl_peri.WriteWord32(0x00018100 + 4*12, 0x40);
            um_pl_peri.WriteWord32(0x00018100 + 4*13, 0xc0);
            um_pl_peri.WriteWord32(0x00018100 + 4*14, 0x80);
            um_pl_peri.WriteWord32(0x00018010, 14);      // MNIST_MOD_REG_PARAM_END
        }
        else {
            // 単純2値化(テーブルサイズ=1)
            um_pl_peri.WriteWord32(0x00018100, bin_th);
            um_pl_peri.WriteWord32(0x00018010, 0);       // MNIST_MOD_REG_PARAM_END
        }
        
        // パラメータ設定
        um_pl_peri.WriteWord32(0x00019000, dnn0_en + (dnn1_en << 1));
        um_pl_peri.WriteWord32(0x00019004, view_sel);
        um_pl_peri.WriteWord32(0x00019008, dnn0_th);
        um_pl_peri.WriteWord32(0x0001900c, dnn1_th);
        um_pl_peri.WriteWord32(0x00015000, dnn0_lpf);
        um_pl_peri.WriteWord32(0x00015040, dnn1_lpf);
        
        // 録画
        if ( key == 'r' ) {
            printf("record\n");
            capture_still_image(um_pl_peri, 0, width, height, width*4, 100);
            char* p = (char*)mem_addr;
            for ( int i = 0; i< 100; i++ ) {
                char fname[64];
                sprintf(fname, "rec_%04d.png", i);
                cv::Mat imgRec(height, width, CV_8UC4);
                memcpy(imgRec.data, p, width * height * 4); p += width * height * 4;
                cv::Mat imgRgb;
                cv::cvtColor(imgRec, imgRgb, CV_BGRA2BGR);
                cv::imwrite(fname, imgRgb);
            }
            
            
            // 背景画像展開
            write_back_image(mem_addr);
        }
    } while ( gui && ((key = (cv::waitKey(10) & 0xff)) != 0x1b) );
    
    
    // DVI用にDMAを動きっぱなしにする
    start_viewer_dma(um_pl_peri, offset, width, height, stride, frame_num);
    
    return 0;
}



void write_back_image(void* mem_addr)
{
    unsigned char* p = (unsigned char*)mem_addr;
    
    // 背景画像展開
    cv::Mat img = cv::imread("back.png");
    if ( !img.empty() ) {
        cv::cvtColor(img, img, CV_RGB2RGBA);
        for ( int i = 0; i < DVITX_HEIGHT; ++i ) {
            memcpy(&p[i*DVITX_STRIDE], &img.data[img.cols*4*i], img.cols*4);
        }
    }
}



// DDR3-SDRAM経由で画像をキャプチャ
void capture_still_image(UioMmap& um_pl_peri, int offset, int width, int height, int stride, int frame_num)
{
    // DMA start (one shot)
    um_pl_peri.WriteWord32(0x00010020, 0x30000000 + offset);
    um_pl_peri.WriteWord32(0x00010024, stride);                 // stride
    um_pl_peri.WriteWord32(0x00010028, width);                  // width
    um_pl_peri.WriteWord32(0x0001002c, height);                 // height
    um_pl_peri.WriteWord32(0x00010030, width*height*frame_num); // size
    um_pl_peri.WriteWord32(0x0001003c, 31);                     // awlen
    um_pl_peri.WriteWord32(0x00010010, 0x07);   // one-shot
    
    // normalizer start
    um_pl_peri.WriteWord32(0x00011010, 1);
    um_pl_peri.WriteWord32(0x00011014, 100000000);
    um_pl_peri.WriteWord32(0x00011020, width);
    um_pl_peri.WriteWord32(0x00011024, height);
    um_pl_peri.WriteWord32(0x00011028, 0xfff);
    um_pl_peri.WriteWord32(0x0001102c, 0x10000);
    um_pl_peri.WriteWord32(0x00011000, 3);
//  usleep(100000);
    
    // wait for DMA end
    usleep(1000);
    while ( um_pl_peri.ReadWord32(0x00010014) != 0 ) {
        usleep(10000);
    }
}


void start_viewer_dma(UioMmap& um_pl_peri, int offset, int width, int height, int stride, int frame_num)
{
    while ( um_pl_peri.ReadWord32(0x00010014) != 0 ) {
        usleep(10000);
    }
    
    // DMA start (one shot)
    um_pl_peri.WriteWord32(VDMAW_REG_PARAM_ADDR, 0x30000000 + offset);
    um_pl_peri.WriteWord32(VDMAW_REG_PARAM_STRIDE, stride);                 // stride
    um_pl_peri.WriteWord32(VDMAW_REG_PARAM_WIDTH, width);                  // width
    um_pl_peri.WriteWord32(VDMAW_REG_PARAM_HEIGHT, height);                 // height
    um_pl_peri.WriteWord32(VDMAW_REG_PARAM_SIZE, width*height*frame_num); // size
    um_pl_peri.WriteWord32(VDMAW_REG_PARAM_AWLEN, 3);                      // awlen
    um_pl_peri.WriteWord32(VDMAW_REG_CTL_CONTROL, 0x03);
    
    // normalizer start
    um_pl_peri.WriteWord32(0x00011010, 1);
    um_pl_peri.WriteWord32(0x00011014, 100000000);
    um_pl_peri.WriteWord32(0x00011020, width);
    um_pl_peri.WriteWord32(0x00011024, height);
    um_pl_peri.WriteWord32(0x00011028, 0xfff);
    um_pl_peri.WriteWord32(0x0001102c, 0x10000);
    um_pl_peri.WriteWord32(0x00011000, 3);
}



// カメラ初期化
void camera_setup(I2cAccess& i2c, int w, int h)
{
    /*
    i2c.WriteAddr16Byte(0x0102, 0x01  );   // ???? (Reserved)
//  i2c.WriteAddr16Word();
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
    
//  i2c.WriteAddr16Word(0x0170, 0x0303);   // r     X_ODD_INC_A  Increment for odd pixels 1, 3
//  i2c.WriteAddr16Word(0x0174, 0x0101);   //      BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
    i2c.WriteAddr16Word(0x0174, 0x0303);   // r     BINNING_MODE_H_A  0: no-binning, 1: x2-binning, 2: x4-binning, 3: x2-analog (special) binning
    i2c.WriteAddr16Word(0x018C, 0x0A0A);   //      CSI_DATA_FORMAT_A   CSI-2 data format
    i2c.WriteAddr16Byte(0x0301, 0x05  );   // * VTPXCK_DIV  Video Timing Pixel Clock Divider Value
    i2c.WriteAddr16Word(0x0303, 0x0103);   // * VTSYCK_DIV  PREPLLCK_VT_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)
    i2c.WriteAddr16Word(0x0305, 0x0300);   // * PREPLLCK_OP_DIV(3: EXCK_FREQ 24 MHz to 27 MHz)  / PLL_VT_MPY 区切りがおかしい次に続く
//  i2c.WriteAddr16Byte(0x0307, 0x39  );   // * PLL_VT_MPY
//  i2c.WriteAddr16Byte(0x0307, 84  );      // r PLL_VT_MPY
    i2c.WriteAddr16Byte(0x0307, 87  );      // r PLL_VT_MPY
    i2c.WriteAddr16Byte(0x0309, 0x0A  );   // * OPPXCK_DIV
    i2c.WriteAddr16Word(0x030B, 0x0100);   // * OPSYCK_DIV PLL_OP_MPY[10:8] / 区切りがおかしい次に続く
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

    i2c.WriteAddr16Byte(0x0172, 0x00  );   //      IMG_ORIENTATION_A
    
//  i2c.WriteAddr16Word(0x0160, 0x06E3);   //      FRM_LENGTH_A[15:8]
//  i2c.WriteAddr16Word(0x0162, 0x0D78);   //      LINE_LENGTH_A
//  i2c.WriteAddr16Word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A
//  i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A

//  i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
//  i2c.WriteAddr16Word(0x0160, 0x06E3);   //      FRM_LENGTH_A
//  i2c.WriteAddr16Word(0x0162, 0x0D78);   //      LINE_LENGTH_A (line_length_pck Units: Pixels)
//  i2c.WriteAddr16Word(0x015A, 0x0422);   //      COARSE_INTEGRATION_TIME_A

    i2c.WriteAddr16Byte(0x0100, 0x01  );   //      mode_select [4:0] 0: SW standby, 1: Streaming

//  i2c.WriteAddr16Byte(0x0157, 0x00  );   //      ANA_GAIN_GLOBAL_A
//  i2c.WriteAddr16Word(0x0160, 0x06E3);   // 0x06E3=3330   FRM_LENGTH_A
//  i2c.WriteAddr16Word(0x0162, 0x0D78);   // 0x0D78=3448   LINE_LENGTH_A
//  i2c.WriteAddr16Word(0x015A, 0x0421);   // 0x0421=1057   COARSE_INTEGRATION_TIME_A

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
//  i2c.WriteAddr16Byte(0x0157, 0xFF  );   //      ANA_GAIN_GLOBAL_A
    i2c.WriteAddr16Word(0x0158, 0x0FFF);   //      ANA_GAIN_GLOBAL_A
#endif
}


// end of file
