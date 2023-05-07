#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>

#include <iostream>
#include <fstream>
#include <vector>

#include <opencv2/opencv.hpp>

#include "jelly/JellyRegs.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/Imx219Control.h"


#define REG_DIFF_ENABLE                 0x00
#define REG_DIFF_TARGET                 0x01
#define REG_DIFF_GAIN                   0x02
#define REG_DIFF_INPUT                  0x03
#define REG_DIFF_OUTPUT                 0x04

#define REG_STMC_CORE_ID                0x00
#define REG_STMC_CTL_ENABLE             0x01
#define REG_STMC_CTL_TARGET             0x02
#define REG_STMC_CTL_PWM                0x03
#define REG_STMC_TARGET_X               0x04
#define REG_STMC_TARGET_V               0x06
#define REG_STMC_TARGET_A               0x07
#define REG_STMC_MAX_V                  0x09
#define REG_STMC_MAX_A                  0x0a
#define REG_STMC_MAX_A_NEAR             0x0f
#define REG_STMC_CUR_X                  0x10
#define REG_STMC_CUR_V                  0x12
#define REG_STMC_CUR_A                  0x13
#define REG_STMC_TIME                   0x20
#define REG_STMC_IN_X_DIFF              0x21



void capture_still_image(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_norm, std::uintptr_t bufaddr, int width, int height, int frame_num);
void write_log(jelly::MemAccessor& reg_log0, jelly::MemAccessor& reg_log1, int num0, int num1);


int main(int argc, char *argv[])
{
    double  pixel_clock = 139200000.0;
    bool    binning     = true;
    int     width       = 640;
    int     height      = 132;
    int     aoi_x       = -1;
    int     aoi_y       = -1;
    bool    flip_h      = true;
    bool    flip_v      = true;
    int     frame_rate  = 1000;
    int     exposure    = 10;
    int     a_gain      = 20;
    int     d_gain      = 10;
    int     bayer_phase = 2;
    int     view_scale  = 1;

    for ( int i = 1; i < argc; ++i ) {
        if ( strcmp(argv[i], "full") == 0 ) {
            pixel_clock = 91000000;
            binning    = false;
            width      = 3280;
            height     = 2464;
            aoi_x      = 0;
            aoi_y      = 0;
            frame_rate = 20;
            exposure   = 33;
            a_gain     = 20;
            d_gain     = 0;
            view_scale = 4;
        }
        else if ( strcmp(argv[i], "-pixel_clock") == 0 && i+1 < argc) {
            ++i;
            pixel_clock = strtof(argv[i], nullptr);
        }
        else if ( strcmp(argv[i], "-binning") == 0 && i+1 < argc) {
            ++i;
            binning = (strtol(argv[i], nullptr, 0) != 0);
        }
        else if ( strcmp(argv[i], "-width") == 0 && i+1 < argc) {
            ++i;
            width = strtol(argv[i], nullptr, 0);
        }
        else if ( strcmp(argv[i], "-height") == 0 && i+1 < argc) {
            ++i;
            height = strtol(argv[i], nullptr, 0);
        }
        else if ( strcmp(argv[i], "-aoi_x") == 0 && i+1 < argc) {
            ++i;
            aoi_x = strtol(argv[i], nullptr, 0);
        }
        else if ( strcmp(argv[i], "-aoi_y") == 0 && i+1 < argc) {
            ++i;
            aoi_y = strtol(argv[i], nullptr, 0);
        }
        else if ( strcmp(argv[i], "-frame_rate") == 0 && i+1 < argc) {
            ++i;
            frame_rate = (int)strtof(argv[i], nullptr);
        }
        else if ( strcmp(argv[i], "-exposure") == 0 && i+1 < argc) {
            ++i;
            exposure = (int)strtof(argv[i], nullptr);
        }
        else if ( strcmp(argv[i], "-a_gain") == 0 && i+1 < argc) {
            ++i;
            a_gain = (int)strtof(argv[i], nullptr);
        }
        else if ( strcmp(argv[i], "-d_gain") == 0 && i+1 < argc) {
            ++i;
            d_gain = (int)strtof(argv[i], nullptr);
        }
        else if ( strcmp(argv[i], "-bayer_phase") == 0 && i+1 < argc) {
            ++i;
            bayer_phase = strtol(argv[i], nullptr, 0);
        }
        else if ( strcmp(argv[i], "-view_scale") == 0 && i+1 < argc) {
            ++i;
            view_scale = strtol(argv[i], nullptr, 0);
        }
        else {
            std::cout << "unknown option : " << argv[i] << std::endl;
            return 1;
        }
    }
    
    width &= ~0xf;
    width  = std::max(width, 16);
    height = std::max(height, 2);


    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri : open error or mmap error" << std::endl;
        return 1;
    }
    auto reg_fmtr  = uio_acc.GetAccessor(0x00010000);
    auto reg_prmup = uio_acc.GetAccessor(0x00011000);
    auto reg_wdma  = uio_acc.GetAccessor(0x00021000);
    auto reg_rgb   = uio_acc.GetAccessor(0x00030000);
    auto reg_cmtx  = uio_acc.GetAccessor(0x00030400);
    auto reg_gauss = uio_acc.GetAccessor(0x00030800);
    auto reg_mask  = uio_acc.GetAccessor(0x00030c00);
    auto reg_sel   = uio_acc.GetAccessor(0x00033c00);
    auto reg_stmc  = uio_acc.GetAccessor(0x00041000);
    auto reg_posc  = uio_acc.GetAccessor(0x00042000);
    auto reg_log0  = uio_acc.GetAccessor(0x00070000);
    auto reg_log1  = uio_acc.GetAccessor(0x00071000);

    std::cout << "CORE IDs" << std::endl;
    std::cout << "reg_fmtr  : " << std::hex << reg_fmtr .ReadReg(0) << std::endl;
    std::cout << "reg_prmup : " << std::hex << reg_prmup.ReadReg(0) << std::endl;
    std::cout << "reg_wdma  : " << std::hex << reg_wdma .ReadReg(0) << std::endl;
    std::cout << "reg_rgb   : " << std::hex << reg_rgb  .ReadReg(0) << std::endl;
    std::cout << "reg_cmtx  : " << std::hex << reg_cmtx .ReadReg(0) << std::endl;
    std::cout << "reg_gauss : " << std::hex << reg_gauss.ReadReg(0) << std::endl;
    std::cout << "reg_mask  : " << std::hex << reg_mask .ReadReg(0) << std::endl;
    std::cout << "reg_sel   : " << std::hex << reg_sel  .ReadReg(0) << std::endl;
//  std::cout << "reg_stmc  : " << std::hex << reg_stmc .ReadReg(0) << std::endl;
//  std::cout << "reg_posc  : " << std::hex << reg_posc .ReadReg(0) << std::endl;
    std::cout << "reg_log0  : " << std::hex << reg_log0 .ReadReg(0) << std::endl;
    std::cout << "reg_log1  : " << std::hex << reg_log1 .ReadReg(0) << std::endl;
    std::cout << "" << std::endl;


    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf0 : open error or mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
//  std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
//  std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;


    // motro initialize
	reg_stmc.WriteReg(REG_STMC_MAX_A,       100);
	reg_stmc.WriteReg(REG_STMC_MAX_V,    200000);
	reg_stmc.WriteReg(REG_STMC_CTL_ENABLE,    1);

//   test
//   std::cout << "speed 1000" << std::endl;
//   reg_stmc.WriteReg(REG_STMC_TARGET_V, 100000);
//   reg_stmc.WriteReg(REG_STMC_CTL_TARGET, 2);

    // feedback 
// 	reg_stmc.WriteReg(REG_STMC_CTL_TARGET, 8 + 1);

//	reg_posc.WriteReg(REG_DIFF_ENABLE,  0x00000001);
//	reg_posc.WriteReg(REG_DIFF_TARGET,  0x40000000);
//	reg_posc.WriteReg(REG_DIFF_GAIN,    -0x1000);

    reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 0);

    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
        std::cout << "I2C open error" << std::endl;
        return 1;
    }

    // camera 設定
    imx219.SetPixelClock(pixel_clock);
    imx219.SetAoi(width, height, aoi_x, aoi_y, binning, binning);
    imx219.Start();

    // DMA start (contine)
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_ADDR, dmabuf_phys_adr);        // addr
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_STRIDE, width*4);              // stride
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_WIDTH, width);                 // width
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_HEIGHT, height);               // height
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_SIZE, width*height);           // size
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_AWLEN, 31);                    // awlen
    reg_wdma.WriteReg(REG_VIDEO_WDMA_CTL_CONTROL, 0x03);

    // normalizer start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT, 100000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH, width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT, height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL, 0x0ff);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT, 0x100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x03);

//      capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, frame_num);

    int     rec_frame_num = std::min(100, (int)(dmabuf_mem_size / (width * height * 4)));
    int     frame_num     = 1;

    if ( rec_frame_num <= 0 ) {
        std::cout << "udmabuf size error" << std::endl;
    }

    int gauss = 5;

    // mask
    int mask_flag        = 0;
    int mask_en          = 1;
    int mask_th_flag     = 1;
    int mask_th_val      = 88;
    int mask_rect_flag   = 0;
    int mask_rect_left   = 0;
    int mask_rect_right  = 640;
    int mask_rect_top    = 0;
    int mask_rect_bottom = 132;
    int mask_circle_flag = 1;
    int mask_circle_x    = 294; // 640/2;
    int mask_circle_y    = 66;  //132/2;
    int mask_circle_r    = 100; // 100;
    cv::namedWindow("mask");
    cv::resizeWindow("mask", 320, 480);
    cv::createTrackbar("mask_flag",   "mask", &mask_flag,           3);
    cv::createTrackbar("mask_en",     "mask", &mask_en,             3);
    cv::createTrackbar("th_flag",     "mask", &mask_th_flag,        3);
    cv::createTrackbar("th_val",      "mask", &mask_th_val,      1024);
    cv::createTrackbar("rc_flag",     "mask", &mask_rect_flag,      3);
    cv::createTrackbar("rc_left",     "mask", &mask_rect_left,    639);
    cv::createTrackbar("rc_right",    "mask", &mask_rect_right,   639);
    cv::createTrackbar("rc_top",      "mask", &mask_rect_top,     131);
    cv::createTrackbar("rc_bottom",   "mask", &mask_rect_bottom,  131);
    cv::createTrackbar("circle_flag", "mask", &mask_circle_flag,    3);    
    cv::createTrackbar("circle_x",    "mask", &mask_circle_x,     639);
    cv::createTrackbar("circle_y",    "mask", &mask_circle_y,     131);
    cv::createTrackbar("circle_r",    "mask", &mask_circle_r,     640);
    
    // feedback
    int feedback_en     = 1;
    int feedback_target = 5;
    int feedback_gain   = 100;
    cv::namedWindow("feedback");
    cv::resizeWindow("feedback", 640, 200);
    cv::createTrackbar("enable", "feedback", &feedback_en, 1);
    cv::createTrackbar("target", "feedback", &feedback_target, 0x1000);
    cv::createTrackbar("gain",   "feedback", &feedback_gain,   200);
    
    // motor
    int motor_en         = 1;
    int motor_mode       = 1;
    int motor_x          = 200;
    int motor_v          = 101;
    int motor_max_v      = 1000;
    int motor_max_a      = 10;
    cv::namedWindow("motor");
    cv::resizeWindow("motor", 320, 300);
    cv::createTrackbar("en",    "motor", &motor_en,       1);
    cv::createTrackbar("mode",  "motor", &motor_mode,     2);
    cv::createTrackbar("x",     "motor", &motor_x,       400);
    cv::createTrackbar("v",     "motor", &motor_v,       200);
    cv::createTrackbar("max_v", "motor", &motor_max_v,   100);
    cv::createTrackbar("max_a", "motor", &motor_max_a,   100);

    int     key;
    while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
        /*
        std::cout << reg_log0.ReadReg(REG_LOGGER_CTL_STATUS) << std::endl;
        std::cout << reg_log0.ReadReg(REG_LOGGER_CTL_COUNT) << std::endl;
        if ( reg_log0.ReadReg(REG_LOGGER_CTL_COUNT) > 600 ) {
            reg_log0.WriteReg(REG_LOGGER_CTL_CONTROL, 3);
            sleep(0.1);
            reg_log0.WriteReg(REG_LOGGER_CTL_CONTROL, 0);
        }
        */

        // 設定
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);

        reg_rgb.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
        reg_rgb.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);

        reg_gauss.WriteReg(REG_IMG_GAUSS3X3_PARAM_ENABLE, (1 << gauss) - 1);
        reg_gauss.WriteReg(REG_IMG_GAUSS3X3_CTL_CONTROL,  0x3);

        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_MASK_FLAG,      mask_flag | (mask_en << 2));
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_THRESH_FLAG,    mask_th_flag);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_THRESH_VALUE,   mask_th_val);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_RECT_FLAG,      mask_rect_flag);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_RECT_LEFT,      mask_rect_left);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_RECT_RIGHT,     mask_rect_right);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_RECT_TOP,       mask_rect_top);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_RECT_BOTTOM,    mask_rect_bottom);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_CIRCLE_FLAG,    mask_circle_flag);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_CIRCLE_X,       mask_circle_x);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_CIRCLE_Y,       mask_circle_y);
        reg_mask.WriteReg(REG_IMG_AREAMASK_PARAM_CIRCLE_RADIUS2, mask_circle_r*mask_circle_r);
        reg_mask.WriteReg(REG_IMG_AREAMASK_CTL_CONTROL, 0x7);

        reg_posc.WriteReg(REG_DIFF_ENABLE,  feedback_en);
        reg_posc.WriteReg(REG_DIFF_TARGET,  feedback_target * 0x100000);
        reg_posc.WriteReg(REG_DIFF_GAIN,    (feedback_gain - 100) * 0x10);

        const int motor_mode_tbl[] = {0x01, 0x02, 0x09, 0x00};
        reg_stmc.WriteReg(REG_STMC_CTL_TARGET, motor_mode_tbl[motor_mode]);
        reg_stmc.WriteReg(REG_STMC_MAX_A,       motor_max_a);
        reg_stmc.WriteReg(REG_STMC_MAX_V,       motor_max_v*0x10000);
        if ( motor_mode != 2 ) {
            reg_stmc.WriteReg(REG_STMC_TARGET_X,    (motor_x - 200) * 0x100);
            reg_stmc.WriteReg(REG_STMC_TARGET_V,    (motor_v - 100) * 1000);
        }
        reg_stmc.WriteReg(REG_STMC_CTL_ENABLE,  motor_en);

#if 0
	    printf("%f %10d %10d %10d\n",
                    (int)reg_posc.ReadReg(REG_DIFF_INPUT) * (180.0 / (double)0x8000UL),
                    (int)reg_posc.ReadReg(REG_DIFF_OUTPUT),
                    (int)reg_stmc.ReadReg(REG_STMC_IN_X_DIFF),
                    (int)reg_stmc.ReadReg(REG_STMC_TARGET_X));
#endif

        // キャプチャ
//      capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, frame_num);
        cv::Mat img(height*frame_num, width, CV_8UC4);
        udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4 * frame_num);
        
        // 表示
        cv::Mat view_img;
        cv::resize(img, view_img, cv::Size(), 1.0/view_scale, 1.0/view_scale);

        cv::imshow("img", view_img);
        cv::createTrackbar("scale",    "img", &view_scale, 4);
        cv::createTrackbar("fps",      "img", &frame_rate, 1000);
        cv::createTrackbar("exposure", "img", &exposure, 1000);
        cv::createTrackbar("a_gain",   "img", &a_gain, 20);
        cv::createTrackbar("d_gain",   "img", &d_gain, 24);
        cv::createTrackbar("bayer" ,   "img", &bayer_phase, 3);
        cv::createTrackbar("gauss" ,   "img", &gauss, 4);

        // ユーザー操作
        switch ( key ) {
        case 'p':
            std::cout << "pixel clock   : " << imx219.GetPixelClock()   << " [Hz]"  << std::endl;
            std::cout << "frame rate    : " << imx219.GetFrameRate()    << " [fps]" << std::endl;
            std::cout << "exposure time : " << imx219.GetExposureTime() << " [s]"   << std::endl;
            std::cout << "analog  gain  : " << imx219.GetGain()         << " [db]"  << std::endl;
            std::cout << "digital gain  : " << imx219.GetDigitalGain()  << " [db]"  << std::endl;
            std::cout << "AOI width     : " << imx219.GetAoiWidth()  << std::endl;
            std::cout << "AOI height    : " << imx219.GetAoiHeight() << std::endl;
            std::cout << "AOI x         : " << imx219.GetAoiX() << std::endl;
            std::cout << "AOI y         : " << imx219.GetAoiY() << std::endl;
            std::cout << "flip h        : " << imx219.GetFlipH() << std::endl;
            std::cout << "flip v        : " << imx219.GetFlipV() << std::endl;
            break;
        
        case '0':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 0); break;
        case '1':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 1); break;
        case '2':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 2); break;
        case '3':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 3); break;
        case '4':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 4); break;
        case '5':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 5); break;
        case '6':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 6); break;
        case '7':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 7); break;
        case '8':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 8); break;
        case '9':   reg_sel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, 9); break;

        // flip
        case 'h':  flip_h = !flip_h;  break;
        case 'v':  flip_v = !flip_v;  break;
        
        case 'l':
            std::cout << "start logging" << std::endl;
            write_log(reg_log0, reg_log1, 3000, 500000);
            std::cout << "end logging" << std::endl;
            break;

        // aoi position
        case 'w':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() - 4);    break;
        case 'z':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() + 4);    break;
        case 'a':  imx219.SetAoiPosition(imx219.GetAoiX() - 4, imx219.GetAoiY());    break;
        case 's':  imx219.SetAoiPosition(imx219.GetAoiX() + 4, imx219.GetAoiY());    break;

        case 'd':   // image dump
            {
                cv::Mat imgRgb;
                cv::cvtColor(img, imgRgb, CV_BGRA2BGR);
                cv::imwrite("img_dump.png", imgRgb);
            }
            break;

        case 'r': // image record
            std::cout << "record" << std::endl;
            capture_still_image(reg_wdma, reg_fmtr, dmabuf_phys_adr, width, height, rec_frame_num);
            int offset = 0;
            for ( int i = 0; i < rec_frame_num; i++ ) {
                char fname[64];
                sprintf(fname, "rec_%04d.png", i);
                cv::Mat imgRec(height, width, CV_8UC4);
                udmabuf_acc.MemCopyTo(imgRec.data, offset, width * height * 4);
                offset += width * height * 4;
                cv::Mat imgRgb;
                cv::cvtColor(imgRec, imgRgb, CV_BGRA2BGR);
                cv::imwrite(fname, imgRgb);
            }
            break;
        }
    }

    // close
    imx219.Stop();
    imx219.Close();
    
    return 0;
}




// 静止画キャプチャ
void capture_still_image(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_fmtr, std::uintptr_t bufaddr, int width, int height, int frame_num)
{
    // DMA start (one shot)
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_ADDR, bufaddr); // 0x30000000);
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_STRIDE, width*4);              // stride
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_WIDTH, width);                 // width
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_HEIGHT, height);               // height
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_SIZE, width*height*frame_num); // size
    reg_wdma.WriteReg(REG_VIDEO_WDMA_PARAM_AWLEN, 31);                    // awlen
    reg_wdma.WriteReg(REG_VIDEO_WDMA_CTL_CONTROL, 0x07);
    
    // normalizer start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT, 100000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH, width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT, height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL, 0x0ff);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT, 0x100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x03);
    usleep(100000);
    
    // 取り込み完了を待つ
    usleep(10000);
    while ( reg_wdma.ReadReg(REG_VIDEO_WDMA_CTL_STATUS) != 0 ) {
        usleep(10000);
    }
    
    // normalizer stop
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
    usleep(1000);
    while ( reg_wdma.ReadReg(REG_VIDEO_FMTREG_CTL_STATUS) != 0 ) {
        usleep(1000);
    }
}


struct logger_image
{
    std::uint64_t   time;
    std::uint32_t   angle;
};

struct logger_motor
{
    std::uint64_t   time;
    std::int64_t    cur_x;
    std::int32_t    cur_v;
    std::int32_t    cur_a;
    std::int64_t    target_x;
    std::int32_t    target_v;
    std::int32_t    target_a;
};

void write_log(jelly::MemAccessor& reg_log0, jelly::MemAccessor& reg_log1, int num0, int num1)
{
    std::vector<logger_image>   vec_img;
    std::vector<logger_motor>   vec_mot;
    vec_img.reserve(num0);
    vec_mot.reserve(num1);

    std::cout << reg_log0.ReadReg(REG_LOGGER_CTL_STATUS) << std::endl;
    std::cout << reg_log0.ReadReg(REG_LOGGER_CTL_COUNT) << std::endl;

    // 一旦クリア
    reg_log0.WriteReg(REG_LOGGER_CTL_CONTROL, 3);
    reg_log1.WriteReg(REG_LOGGER_CTL_CONTROL, 3);
    sleep(1);
    reg_log0.WriteReg(REG_LOGGER_CTL_CONTROL, 0);
    reg_log1.WriteReg(REG_LOGGER_CTL_CONTROL, 0);

//    std::cout << reg_log0.ReadReg(REG_LOGGER_CTL_STATUS) << std::endl;
//    std::cout << reg_log0.ReadReg(REG_LOGGER_CTL_COUNT) << std::endl;

    int max_img = 0;
    int max_mot = 0;

    // ロギング
    std::cout << "start" << std::endl;
    while ( (int)vec_img.size() < num0 && (int)vec_mot.size() < num1 ) {
        max_img = std::max(max_img, (int)reg_log0.ReadReg(REG_LOGGER_CTL_COUNT));
        max_mot = std::max(max_mot, (int)reg_log1.ReadReg(REG_LOGGER_CTL_COUNT));

        if ( reg_log0.ReadReg(REG_LOGGER_CTL_STATUS) ) {
            logger_image li;
            li.time  = ((std::uint64_t)reg_log0.ReadReg(REG_LOGGER_POL_TIMER0) << 0)
                     + ((std::uint64_t)reg_log0.ReadReg(REG_LOGGER_POL_TIMER1) << 32);
            li.angle = (std::uint32_t)reg_log0.ReadReg(REG_LOGGER_POL_DATA(0));
            reg_log0.WriteReg(REG_LOGGER_CTL_CONTROL, 1);
            vec_img.push_back(li);
        }

        if ( reg_log1.ReadReg(REG_LOGGER_CTL_STATUS) ) {
            logger_motor lm;
            lm.time     = ((std::uint64_t)reg_log1.ReadReg(REG_LOGGER_POL_TIMER0) << 0)
                        + ((std::uint64_t)reg_log1.ReadReg(REG_LOGGER_POL_TIMER1) << 32);
            lm.cur_x    = ((std::uint64_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(0)) << 0)
                        + ((std::uint64_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(1)) << 32);
            lm.cur_v    = ((std::uint32_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(2)) << 0);
            lm.cur_a    = ((std::uint32_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(3)) << 0);
            lm.target_x = ((std::uint64_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(4)) << 0)
                        + ((std::uint64_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(5)) << 32);
            lm.target_v = ((std::uint32_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(6)) << 0);
            lm.target_a = ((std::uint32_t)reg_log1.ReadReg(REG_LOGGER_POL_DATA(7)) << 0);
            reg_log1.WriteReg(REG_LOGGER_CTL_CONTROL, 1);
            vec_mot.push_back(lm);
        }
    }
    std::cout << "end" << std::endl;
    std::cout << "max_img : " << max_img << std::endl;
    std::cout << "max_mot : " << max_mot << std::endl;

    {
        std::ofstream ofs("log0.csv");
        for ( auto li : vec_img ) {
            ofs << li.time << ", "
                << li.angle << "\n";
        }
    }

    {
        std::ofstream ofs("log1.csv");
        for ( auto lm : vec_mot ) {
            ofs << lm.time << ", "
                << lm.cur_x << ", "
                << lm.cur_v << ", "
                << lm.cur_a << ", "
                << lm.target_x << ", "
                << lm.target_v << ", "
                << lm.target_a << "\n";
        }
    }
}



// end of file