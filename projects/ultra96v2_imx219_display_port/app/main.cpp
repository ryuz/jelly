// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include <opencv2/opencv.hpp>

#include "jelly/JellyRegs.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/GpioAccessor.h"
#include "jelly/Imx219Control.h"
#include "jelly/VideoDmaControl.h"


#define DP_MAIN_STREAM_HTOTAL               0x00000180
#define DP_MAIN_STREAM_VTOTAL               0x00000184
#define DP_MAIN_STREAM_POLARITY             0x00000188
#define DP_MAIN_STREAM_HSWIDTH              0x0000018C
#define DP_MAIN_STREAM_VSWIDTH              0x00000190
#define DP_MAIN_STREAM_HRES                 0x00000194
#define DP_MAIN_STREAM_VRES                 0x00000198
#define DP_MAIN_STREAM_HSTART               0x0000019C
#define DP_MAIN_STREAM_VSTART               0x000001A0

#define V_BLEND_SET_GLOBAL_ALPHA_REG        0x0000A00C
#define AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT    0x0000B070
#define AV_BUF_AUD_VID_CLK_SOURCE           0x0000B120



int main(int argc, char *argv[])
{
    double  pixel_clock = 91000000.0;
    bool    binning     = true;
    int     width       = 1280;
    int     height      = 720;
    int     aoi_x       = -1;
    int     aoi_y       = -1;
    bool    flip_h      = false;
    bool    flip_v      = false;
    int     frame_rate  = 1000;
    int     exposure    = 10;
    int     a_gain      = 20;
    int     d_gain      = 10;
    int     bayer_phase = 1;
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
        else if ( strcmp(argv[i], "1000fps") == 0 ) {
            pixel_clock = 139200000.0;
            binning     = true;
            width       = 640;
            height      = 132;
            aoi_x       = -1;
            aoi_y       = -1;
            flip_h      = false;
            flip_v      = false;
            frame_rate  = 1000;
            exposure    = 10;
            a_gain      = 20;
            d_gain      = 10;
            bayer_phase = 1;
            view_scale  = 1;
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



    std::cout << "--- Display Port ---" << std::endl;

    // mmap udmabuf
    std::cout << "\nudmabuf4 open" << std::endl;
    jelly::UdmabufAccessor udmabuf_acc("udmabuf4");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf4 mmap error" << std::endl;
        return 1;
    }
    auto dmabuf_addr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_size = udmabuf_acc.GetSize();

    std::cout << "udmabuf4 phys addr : 0x" << std::hex << dmabuf_addr << std::endl;
    std::cout << "udmabuf4 size      : 0x" << std::hex << dmabuf_size << std::endl;

    auto img = cv::imread("test.jpg");
    cv::Mat imgView;
    cv::resize(img, imgView, cv::Size(1920, 1080));
//  udmabuf_acc.MemCopyFrom(0, imgView.data, 1920*1080*3);
    udmabuf_acc.WriteImage2d<3>(imgView.data, 0, 1920, 1080);
    

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto reg_fmtr    = uio_acc.GetAccessor(0x00100000);  // ビデオサイズ正規化
    auto reg_demos   = uio_acc.GetAccessor(0x00200000);  // デモザイク
    auto reg_colmat  = uio_acc.GetAccessor(0x00210000);  // カラーマトリックス
    auto reg_gamma   = uio_acc.GetAccessor(0x00220000);  // ガンマ補正
    auto reg_gauss   = uio_acc.GetAccessor(0x00240000);  // ガウシアンフィルタ
    auto reg_canny   = uio_acc.GetAccessor(0x00250000);  // Cannyフィルタ
    auto reg_imgdma  = uio_acc.GetAccessor(0x00260000);  // FIFO dma
    auto reg_bindiff = uio_acc.GetAccessor(0x00270000);  // 前画像との差分バイナライズ
    auto reg_sel     = uio_acc.GetAccessor(0x002f0000);  // 出力切り替え
    auto reg_bufmng  = uio_acc.GetAccessor(0x00300000);  // Buffer manager
    auto reg_bufalc  = uio_acc.GetAccessor(0x00310000);  // Buffer allocator
    auto reg_vdmaw_  = uio_acc.GetAccessor(0x00320000);  // Write-DMA
    auto reg_vdmar_  = uio_acc.GetAccessor(0x00340000);  // Read-DMA
    auto reg_vsgen   = uio_acc.GetAccessor(0x00360000);  // Video out sync generator

#if 1
    // ID確認
    std::cout << "CORE ID" << std::endl;
    std::cout << "fmtr    : " << std::hex << reg_fmtr.ReadReg(0) << std::endl;
    std::cout << "demos   : " << std::hex << reg_demos.ReadReg(0) << std::endl;
    std::cout << "colmat  : " << std::hex << reg_colmat.ReadReg(0) << std::endl;
    std::cout << "gamma   : " << std::hex << reg_gamma.ReadReg(0) << std::endl;
    std::cout << "gauss   : " << std::hex << reg_gauss.ReadReg(0) << std::endl;
    std::cout << "canny   : " << std::hex << reg_canny.ReadReg(0) << std::endl;
    std::cout << "imgdma  : " << std::hex << reg_imgdma.ReadReg(0) << std::endl;
    std::cout << "bindiff : " << std::hex << reg_bindiff.ReadReg(0) << std::endl;
    std::cout << "sel     : " << std::hex << reg_sel.ReadReg(0) << std::endl;
    std::cout << "bufmng  : " << std::hex << reg_bufmng.ReadReg(0) << std::endl;
    std::cout << "bufalc  : " << std::hex << reg_bufalc.ReadReg(0) << std::endl;
    std::cout << "vdmaw   : " << std::hex << reg_vdmaw_.ReadReg(0) << std::endl;
    std::cout << "vdmar   : " << std::hex << reg_vdmar_.ReadReg(0) << std::endl;
    std::cout << "vsgen   : " << std::hex << reg_vsgen.ReadReg(0) << std::endl;
#endif

    jelly::VideoDmaControl  vdmaw(reg_vdmaw_, 3, 3, true);
    jelly::VideoDmaControl  vdmar(reg_vdmar_, 3, 3, true);


    // DisplayPort 設定
    std::cout << "\nuio DP open" << std::endl;
    jelly::UioAccessor reg_dp("uio_dp", 0x000010000);
    if ( !reg_dp.IsMapped() ) {
        std::cout << "uio_dp mmap error" << std::endl;
        return 1;
    }
//  auto old_dp_avclk = reg_dp.ReadMem32(AV_BUF_AUD_VID_CLK_SOURCE);
    auto old_dp_avsel = reg_dp.ReadMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT);
    auto old_dp_alpha = reg_dp.ReadMem32(V_BLEND_SET_GLOBAL_ALPHA_REG);
//   reg_dp.WriteMem32(AV_BUF_AUD_VID_CLK_SOURCE,        0x00);
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, 0x54);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     0x101);

//   std::cout << "AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT : 0x" << std::hex << reg_dp.ReadMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT) << std::endl;
//   std::cout << "V_BLEND_SET_GLOBAL_ALPHA_REG     : 0x" << std::hex << reg_dp.ReadMem32(V_BLEND_SET_GLOBAL_ALPHA_REG) << std::endl;
//   std::cout << "AV_BUF_AUD_VID_CLK_SOURCE        : 0x" << std::hex << reg_dp.ReadMem32(AV_BUF_AUD_VID_CLK_SOURCE) << std::endl;

    int dp_polarity = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_POLARITY);
    int dp_hswidth  = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HSWIDTH);
    int dp_vswidth  = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VSWIDTH);
    int dp_hres     = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HRES);
    int dp_vres     = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VRES);
    int dp_hstart   = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HSTART);
    int dp_vstart   = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VSTART);

    int h_start = dp_hstart-dp_hswidth-17;
    int v_start = dp_vstart-dp_vswidth-1;



    // カメラ電源ON
    jelly::GpioAccessor gpio(36);
    gpio.SetDirection(true);
    gpio.SetValue(0);
    usleep(500000);
    gpio.SetValue(1);
    usleep(500000);

    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-4", 0x10) ) {
        std::cout << "I2C open error" << std::endl;
        return 1;
    }
    imx219.Reset();

    std::cout << "Camera Model ID : " << std::hex << std::setfill('0') << std::setw(4) << imx219.GetModelId() << std::endl;

    // camera 設定
    imx219.SetPixelClock(pixel_clock);
    imx219.SetAoi(width, height, aoi_x, aoi_y, binning, binning);
    imx219.Start();

    /*
    int     rec_frame_num = std::min(100, (int)(dmabuf_mem_size / (width * height * 4)));
    int     frame_num     = 1;

    if ( rec_frame_num <= 0 ) {
        std::cout << "udmabuf size error" << std::endl;
    }
    */

    // DMA start
#if 1
    vdmaw.SetBufferAddr(dmabuf_addr);
    vdmaw.SetImageSize(width, height);
    vdmaw.SetImageStep(1920*3);
    vdmaw.Start();
#else
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_ADDR,   dmabuf_addr);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_OFFSET,     0);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_LINE_STEP,  1920*3);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_H_SIZE,     width-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_V_SIZE,     height-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_FRAME_STEP, width*3*height);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_F_SIZE,     1-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_AWLEN_MAX,  64-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_CTL_CONTROL,      0x03);
#endif

    // video format regularizer
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x100);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);


    // DMA start
#if 1
    vdmar.SetBufferAddr(dmabuf_addr);
    vdmar.SetImageSize(1920, 1080);
    vdmar.Start();
#else
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_ADDR,       dmabuf_addr);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_OFFSET,     0);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_LINE_STEP,  1920*3);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_H_SIZE,     1920-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_V_SIZE,     1080-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_FRAME_STEP, 1920*3*1080);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_F_SIZE,     1-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_ARLEN_MAX,  64-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL,      0x03);
#endif

#if 1
    // VSync adjust de
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSIZE, dp_hres-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSIZE, dp_vres-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSTART, v_start);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSTART, dp_vstart-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HPOL,   (dp_polarity & 1) ? 1 : 0);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VPOL,   (dp_polarity & 2) ? 1 : 0);
#else
    // VSync Start
    usleep(100000);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HTOTAL,      2200);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_START,    0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_END,   1920);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_START, 2008);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_END,   2052);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VTOTAL,      1125);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_START,   0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_END,   1080);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_START, 1084);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_END,   1089);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL,          1);
#endif


    cv::imshow("img", img);
    while ( cv::waitKey(10) != 0x1b ) {
        cv::createTrackbar("h", "img", &h_start, 200);
        cv::createTrackbar("v", "img", &v_start, 100);

        cv::createTrackbar("fps",      "img", &frame_rate, 1000);
        cv::createTrackbar("phase",    "img", &bayer_phase, 3);
        cv::createTrackbar("exposure", "img", &exposure, 1000);
        cv::createTrackbar("a_gain",   "img", &a_gain, 20);
        cv::createTrackbar("d_gain",   "img", &d_gain, 24);

        cv::Mat cam_img(height, width, CV_8UC3);
        udmabuf_acc.ReadImage2d<3>(cam_img.data, 0, width, height, 0, 1920*3);
        cv::imshow("cam_img", cam_img);

        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);


        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSTART, h_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSTART, v_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 3);

        reg_demos.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);
    }
    
//    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL, 0x00);
//    while ( reg_vdmar.ReadReg(REG_VDMA_READ_CTL_STATUS) != 0 ) {
//        usleep(100);
//    }    


//    reg_vdmaw.WriteReg(REG_VDMA_WRITE_CTL_CONTROL, 0x00);
//    usleep(1000);

    vdmaw.Stop();
    vdmar.Stop();
    
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 2);

    // 元に戻す
//    reg_dp.WriteMem32(AV_BUF_AUD_VID_CLK_SOURCE,        old_dp_avclk);
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, old_dp_avsel);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     old_dp_alpha);

    return 0;
}

// end of file
