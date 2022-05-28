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
    int     frame_rate  = 60;
    int     exposure    = 20;
    int     a_gain      = 20;
    int     d_gain      = 1;
    int     bayer_phase = 0;
    int     view_scale  = 2;
//    int     view_x      = -1;
//    int     view_y      = -1;
//    bool    colmat_en   = false;
    int     gamma       = 22;
    int     gauss_level = 0;
    int     canny_th    = 127;
    int     diff_th     = 15;
    cv::Mat imgBack;
    
    for ( int i = 1; i < argc; ++i ) {
        if ( strcmp(argv[i], "1000fps") == 0 ) {
            pixel_clock = 139200000.0;
            binning     = true;
            width       = 640;
            height      = 132;
            aoi_x       = -1;
            aoi_y       = -1;
            flip_h      = false;
            flip_v      = false;
            frame_rate  = 1000;
            exposure    = 1;
            a_gain      = 20;
            d_gain      = 10;
            bayer_phase = 1;
            view_scale  = 1;
        }
        else if ( strcmp(argv[i], "720p") == 0 ) {
            pixel_clock = 91000000.0;
            binning     = true;
            width       = 1280;
            height      = 720;
            aoi_x       = -1;
            aoi_y       = -1;
            flip_h      = false;
            flip_v      = false;
            frame_rate  = 60;
            exposure    = 20;
            a_gain      = 20;
            d_gain      = 0;
            bayer_phase = 1;
            view_scale  = 2;
        }
        else if ( strcmp(argv[i], "1080p") == 0 ) {
            pixel_clock = 91000000.0;
            binning     = false;
            width       = 1920;
            height      = 1080;
            aoi_x       = -1;
            aoi_y       = -1;
            flip_h      = false;
            flip_v      = false;
            frame_rate  = 60;
            exposure    = 20;
            a_gain      = 20;
            d_gain      = 0;
            bayer_phase = 1;
            view_scale  = 2;
        }
        else if ( strcmp(argv[i], "full") == 0 ) {
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
        else if ( strcmp(argv[i], "-back_image") == 0 && i+1 < argc) {
            ++i;
            imgBack = cv::imread(argv[i]);
            cv::resize(imgBack, imgBack, cv::Size(1280, 720));
        }
        else {
            std::cout << "unknown option : " << argv[i] << std::endl;
            return 1;
        }
    }

    width &= ~0xf;
    width  = std::max(width, 16);
    height = std::max(height, 2);




    // udmabuf
    std::cout << "\nudmabuf open" << std::endl;
    jelly::UdmabufAccessor udmabuf_acc("udmabuf-jelly-vram0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf oepn error" << std::endl;
        return 1;
    }
    auto dmabuf_addr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_size = udmabuf_acc.GetSize();

    std::cout << "udmabuf phys addr : 0x" << std::hex << dmabuf_addr << std::endl;
    std::cout << "udmabuf size      : 0x" << std::hex << dmabuf_size << std::endl;

    // PL peripheral bus
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
    auto reg_vdmaw   = uio_acc.GetAccessor(0x00320000);  // Write-DMA
    auto reg_vdmar   = uio_acc.GetAccessor(0x00340000);  // Read-DMA
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
    std::cout << "vdmaw   : " << std::hex << reg_vdmaw.ReadReg(0) << std::endl;
    std::cout << "vdmar   : " << std::hex << reg_vdmar.ReadReg(0) << std::endl;
    std::cout << "vsgen   : " << std::hex << reg_vsgen.ReadReg(0) << std::endl;
#endif

    // DMA
    jelly::VideoDmaControl  vdmaw(reg_vdmaw, 3, 3, true);
    jelly::VideoDmaControl  vdmar(reg_vdmar, 3, 3, true);


    // memmeap iamge fifo
    jelly::UdmabufAccessor udmabuf5_acc("udmabuf-jelly-vram1");
    if ( !udmabuf5_acc.IsMapped() ) {
        std::cout << "udmabuf : open error or mmap error" << std::endl;
        return 1;
    }

    reg_imgdma.WriteReg(REG_DAM_FIFO_CTL_CONTROL, 0x0);
    usleep(100);

    auto fifobuf_phys_adr = udmabuf5_acc.GetPhysAddr();
    auto fifobuf_mem_size = udmabuf5_acc.GetSize();
    std::cout << "udmabuf phys addr : 0x" << std::hex << fifobuf_phys_adr << std::endl;
    std::cout << "udmabuf size      : " << std::dec << fifobuf_mem_size << std::endl;
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_ADDR,     fifobuf_phys_adr);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_SIZE,     fifobuf_mem_size);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_AWLEN,    0x0f);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_WTIMEOUT, 0xff);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_ARLEN,    0x0f);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_RTIMEOUT, 0xff);
    reg_imgdma.WriteReg(REG_DAM_FIFO_CTL_CONTROL,    0x3);


    // DisplayPort 設定
    std::cout << "\nuio DP open" << std::endl;
    jelly::UioAccessor reg_dp("uio_dp", 0x000010000);
    if ( !reg_dp.IsMapped() ) {
        std::cout << "uio_dp mmap error" << std::endl;
        return 1;
    }
    auto old_dp_avsel = reg_dp.ReadMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT);
    auto old_dp_alpha = reg_dp.ReadMem32(V_BLEND_SET_GLOBAL_ALPHA_REG);
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, 0x54);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     0x101);

    int dp_polarity = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_POLARITY);
    int dp_hswidth  = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HSWIDTH);
    int dp_vswidth  = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VSWIDTH);
    int dp_hres     = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HRES);
    int dp_vres     = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VRES);
    int dp_hstart   = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_HSTART);
    int dp_vstart   = (int)reg_dp.ReadMem32(DP_MAIN_STREAM_VSTART);

    int h_start = dp_hstart-dp_hswidth-17;
    int v_start = dp_vstart-dp_vswidth-1;


    // 背景書き込み
    if ( imgBack.empty() ) {
        imgBack = cv::Mat::zeros(360, 640, CV_8UC3);
    }
    cv::Mat imgView;
    cv::resize(imgBack, imgView, cv::Size(dp_hres, dp_vres));
    udmabuf_acc.WriteImage2d(3, dp_hres, dp_vres, imgView.data, 0);


    // カメラ電源ON
    /*
    jelly::GpioAccessor gpio(36);
    gpio.SetDirection(true);
    gpio.SetValue(0);
    usleep(500000);
    gpio.SetValue(1);
    usleep(500000);
    */
    uio_acc.WriteReg(2, 1);
    usleep(500000);

    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-6", 0x10) ) {
        std::cout << "I2C open error" << std::endl;
        return 1;
    }
    imx219.Reset();

    std::cout << "Camera Model ID : " << std::hex << std::setfill('0') << std::setw(4) << imx219.GetModelId() << std::endl;

    // camera 設定
    imx219.SetPixelClock(pixel_clock);
    imx219.SetAoi(width, height, aoi_x, aoi_y, binning, binning);
    imx219.Start();


    // Camera DMA write start
    int offset_x = (dp_hres - width) / 2;
    int offset_y = (dp_vres - height) / 2;
    vdmaw.SetBufferAddr(dmabuf_addr);
    vdmaw.SetImageSize(width, height);
    vdmaw.SetImageStep(dp_hres*3);
    vdmaw.SetOffset(offset_x, offset_y);
    vdmaw.Start();

    // camera video format regularizer
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x100);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);

    // DisplayPort DMA read start
    vdmar.SetBufferAddr(dmabuf_addr);
    vdmar.SetImageSize(dp_hres, dp_vres);
    vdmar.Start();


#if 1
    // VSync adjust de
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSIZE,  dp_hres-1);
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSIZE,  dp_vres-1);
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

    cv::imshow("DisplayPort", imgBack);
    cv::createTrackbar("h", "DisplayPort", &h_start, 200);
    cv::createTrackbar("v", "DisplayPort", &v_start, 100);
    
    int key;
    int gamma_prev = 0;
    while ( (key = cv::waitKey(10)) != 0x1b ) {
        cv::Mat img(height, width, CV_8UC3);
        udmabuf_acc.ReadImage2d(3, width, height, img.data, 0, 0, 0, 0, dp_hres*3, offset_x, offset_y);
        cv::Mat imgView;
        cv::resize(img, imgView, cv::Size(), 1.0/view_scale, 1.0/view_scale);
        cv::imshow("Camera", imgView);
        cv::createTrackbar("fps",       "Camera", &frame_rate, 1000);
        cv::createTrackbar("exposure",  "Camera", &exposure, 1000);
        cv::createTrackbar("a_gain",    "Camera", &a_gain, 20);
        cv::createTrackbar("d_gain",    "Camera", &d_gain, 24);
        cv::createTrackbar("bayer",     "Camera", &bayer_phase, 3);
        cv::createTrackbar("gamm" ,     "Camera", &gamma, 30);
        cv::createTrackbar("gauss" ,    "Camera", &gauss_level, 3);
        cv::createTrackbar("canny_th" , "Camera", &canny_th, 255);
        cv::createTrackbar("diff_th" ,  "Camera", &diff_th, 255);

        // imx219
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);

        // demosaic
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);

        // gamma
        gamma = std::max(1, gamma);
        if ( gamma != gamma_prev ) {
            float g = gamma / 10.0f;
            int gamma_tbl_addr  = (int)reg_gamma.ReadReg(REG_IMG_GAMMA_CFG_TBL_ADDR);
            int gamma_tbl_size  = (int)reg_gamma.ReadReg(REG_IMG_GAMMA_CFG_TBL_SIZE);
            int gamma_tbl_width = (int)reg_gamma.ReadReg(REG_IMG_GAMMA_CFG_TBL_WIDTH);
            for ( int i = 0; i < gamma_tbl_size; ++i) {
                int v = (int)(std::pow((float)i / (float)(gamma_tbl_size-1), 1.0f/g)*((1<<gamma_tbl_width)-1));
                for ( int c = 0; c < 3; ++c) {
                    reg_gamma.WriteReg(gamma_tbl_addr*(c+1)+i, v);
                }
            }
            reg_gamma.WriteReg(REG_IMG_GAMMA_PARAM_ENABLE, 0x7);
            reg_gamma.WriteReg(REG_IMG_GAMMA_CTL_CONTROL, 0x3);

            gamma_prev = gamma;
        }

        // canny
        reg_canny.WriteReg(REG_IMG_CANNY_PARAM_TH, canny_th*canny_th);
        reg_canny.WriteReg(REG_IMG_CANNY_CTL_CONTROL, 0x3);

        // diff binarize
        reg_bindiff.WriteReg(REG_IMG_BINARIZER_PARAM_TH, diff_th);
        reg_bindiff.WriteReg(REG_IMG_BINARIZER_CTL_CONTROL, 0x3);
        

        // display port
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_HSTART, h_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_PARAM_VSTART, v_start);
        reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 3);

        switch ( key ) {
        case 'h':   flip_h = !flip_h; bayer_phase ^= 1; break;
        case 'v':   flip_v = !flip_v; bayer_phase ^= 2; break;

        case 'd':   cv::imwrite("dump.png", img); break;

        case 'r':
            for ( int i = 0; i < 100; ++i ) {
                cv::waitKey(10);
                udmabuf_acc.ReadImage2d(3, width, height, img.data, 0, 0, 0, 0, dp_hres*3, offset_x, offset_y);
                char buf[32];
                sprintf(buf, "rec/img_%04d.png", i);
                cv::imwrite(buf, img);
            }
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

        case '+':   view_scale = std::max(view_scale/2, 1); break;
        case '-':   view_scale = std::min(view_scale*2, 8); break;
        }
    }
    
    // FIFO 停止
    reg_imgdma.WriteReg(REG_DAM_FIFO_CTL_CONTROL, 0x0);
    usleep(100);

    // DMA 停止
    vdmaw.Stop();
    vdmar.Stop();
    
    // DisplayPort Sync 停止
    reg_vsgen.WriteReg(REG_VIDEO_ADJDE_CTL_CONTROL, 0);

    // DisplayPort 状態復帰
    reg_dp.WriteMem32(AV_BUF_OUTPUT_AUDIO_VIDEO_SELECT, old_dp_avsel);
    reg_dp.WriteMem32(V_BLEND_SET_GLOBAL_ALPHA_REG,     old_dp_alpha);

    return 0;
}

// end of file
