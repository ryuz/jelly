#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <iostream>

#include <opencv2/opencv.hpp>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/JellyRegs.h"
#include "jelly/Imx219Control.h"
#include "jelly/GpioAccessor.h"
#include "jelly/VideoDmaControl.h"


#define REG_BIN_PARAM_END           0x04
#define REG_BIN_PARAM_INV           0x05
#define REG_BIN_TBL(x)              (0x40 +(x))

#define REG_LPF_PARAM_ALPHA         0x08



static  volatile    bool    g_signal = false;
void signal_handler(int signo) {
    g_signal = true;
}

int main(int argc, char *argv[])
{
    double  pixel_clock = 91000000.0;
    bool    binning     = false;
    int     width       = 640;
    int     height      = 132;
    int     aoi_x       = -1;
    int     aoi_y       = -1;
    bool    flip_h      = false;
    bool    flip_v      = false;
    int     frame_rate  = 1000;
    int     exposure    = 1;
    int     a_gain      = 20;
    int     d_gain      = 20;
    int     bayer_phase = 0;
    int     lpf         = 200;
    int     bin_th      = 0;
    int     view_scale  = 1;

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
            bayer_phase = 0;
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
            bayer_phase = 0;
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
            bayer_phase = 0;
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
        else {
            std::cout << "unknown option : " << argv[i] << std::endl;
            return 1;
        }
    }
    
    width &= ~0xf;
    width  = std::max(width, 16);
    height = std::max(height, 2);

    // set signal
    signal(SIGINT, signal_handler);

    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    auto reg_gid    = uio_acc.GetAccessor(0x00000000);
    auto reg_fmtr   = uio_acc.GetAccessor(0x00100000);
//  auto reg_prmup  = uio_acc.GetAccessor(0x00011000);
    auto reg_demos  = uio_acc.GetAccessor(0x00120000);
    auto reg_colmat = uio_acc.GetAccessor(0x00120800);
//  auto reg_sel    = uio_acc.GetAccessor(0x00130000);
    auto reg_wdma   = uio_acc.GetAccessor(0x00210000);
    auto reg_bin    = uio_acc.GetAccessor(0x00300000);
    auto reg_lpf    = uio_acc.GetAccessor(0x00320000);

#if 1
    std::cout << "CORE ID" << std::endl;
    std::cout << std::hex << reg_gid.ReadReg(0) << std::endl;
    std::cout << std::hex << uio_acc.ReadReg(0) << std::endl;
    std::cout << std::hex << reg_fmtr.ReadReg(0) << std::endl;
    std::cout << std::hex << reg_demos.ReadReg(0) << std::endl;
    std::cout << std::hex << reg_colmat.ReadReg(0) << std::endl;
    std::cout << std::hex << reg_wdma.ReadReg(0) << std::endl;
#endif
    
    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf-jelly-vram0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
//  std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
//  std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;

    jelly::VideoDmaControl vdmaw(reg_wdma, 4, 4, true);


    // カメラON
    uio_acc.WriteReg(2, 1);
    usleep(500000);

    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-6", 0x10) ) {
        std::cout << "I2C open error" << std::endl;
        return 1;
    }
    imx219.Reset();

    // カメラID取得
    std::cout << "Model ID : " << std::hex << std::setfill('0') << std::setw(4) << imx219.GetModelId() << std::endl;

    // camera 設定
    imx219.SetPixelClock(pixel_clock);
    imx219.SetAoi(width, height, aoi_x, aoi_y, binning, binning);
    imx219.Start();

    int     rec_frame_num = std::min(100, (int)(dmabuf_mem_size / (width * height * 4)));
    int     frame_num     = 1;

    if ( rec_frame_num <= 0 ) {
        std::cout << "udmabuf size error" << std::endl;
    }


    reg_bin.WriteReg(REG_BIN_PARAM_END, 3);
    reg_bin.WriteReg(REG_BIN_TBL(0), 0x80);
    reg_bin.WriteReg(REG_BIN_TBL(1), 0x80);
    reg_bin.WriteReg(REG_BIN_TBL(2), 0x80);
    reg_bin.WriteReg(REG_BIN_TBL(3), 0x80);

    // video input start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x100);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);

    cv::Scalar colmap[10] = {
        cv::Scalar(0x00, 0x00, 0x00),  // 黒
        cv::Scalar(0x00, 0x00, 0x80),  // 茶
        cv::Scalar(0x00, 0x00, 0xff),  // 赤
        cv::Scalar(0x4c, 0xb7, 0xff),  // 橙
        cv::Scalar(0x00, 0xff, 0xff),  // 黄
        cv::Scalar(0x00, 0x80, 0x00),  // 緑
        cv::Scalar(0xff, 0x00, 0x00),  // 青
        cv::Scalar(0x80, 0x00, 0x80),  // 紫
        cv::Scalar(0x80, 0x80, 0x80),  // 灰
        cv::Scalar(0xff, 0xff, 0xff)   // 白
    };

    cv::imshow("img", cv::Mat::zeros(480, 640, CV_8UC3));
    cv::createTrackbar("scale",    "img", nullptr, 4);
    cv::setTrackbarMin("scale",    "img", 1);
    cv::setTrackbarPos("scale",    "img", view_scale);
    cv::createTrackbar("fps",      "img", nullptr, 1000);
    cv::setTrackbarMin("fps",      "img", 5);
    cv::setTrackbarPos("fps",      "img", frame_rate);
    cv::createTrackbar("exposure", "img", nullptr, 1000);
    cv::setTrackbarMin("exposure", "img", 1);
    cv::setTrackbarPos("exposure", "img", exposure);
    cv::createTrackbar("a_gain",   "img", nullptr, 20);
    cv::setTrackbarPos("a_gain",   "img", a_gain);
    cv::createTrackbar("d_gain",   "img", nullptr, 24);
    cv::setTrackbarPos("d_gain",   "img", d_gain);
    cv::createTrackbar("bayer" ,   "img", nullptr, 3);
    cv::setTrackbarPos("bayer",    "img", bayer_phase);
    cv::createTrackbar("lpf" ,     "img", nullptr, 255);
    cv::setTrackbarPos("lpf",      "img", lpf);
    cv::createTrackbar("bin_th" ,  "img", nullptr, 255);
    cv::setTrackbarPos("bin_th",   "img", bin_th);
    
    int     key;
    while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
        if ( g_signal ) { break; }

        view_scale  = cv::getTrackbarPos("scale",    "img");
        frame_rate  = cv::getTrackbarPos("fps",      "img");
        exposure    = cv::getTrackbarPos("exposure", "img");
        a_gain      = cv::getTrackbarPos("a_gain",   "img");
        d_gain      = cv::getTrackbarPos("d_gain",   "img");
        bayer_phase = cv::getTrackbarPos("bayer" ,   "img");
        lpf         = cv::getTrackbarPos("lpf",      "img");
        bin_th      = cv::getTrackbarPos("bin_th",      "img");

        // 設定
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);  // update & enable
        reg_lpf.WriteReg(REG_LPF_PARAM_ALPHA, lpf);

        if ( bin_th == 0 ) {
            // PWMモード(テーブルサイズ=15)
            reg_bin.WriteReg(REG_BIN_TBL(0),  0x10);
            reg_bin.WriteReg(REG_BIN_TBL(1),  0xf0);
            reg_bin.WriteReg(REG_BIN_TBL(2),  0x70);
            reg_bin.WriteReg(REG_BIN_TBL(3),  0x90);
            reg_bin.WriteReg(REG_BIN_TBL(4),  0x30);
            reg_bin.WriteReg(REG_BIN_TBL(5),  0xd0);
            reg_bin.WriteReg(REG_BIN_TBL(6),  0x50);
            reg_bin.WriteReg(REG_BIN_TBL(7),  0xb0);
            reg_bin.WriteReg(REG_BIN_TBL(8),  0x20);
            reg_bin.WriteReg(REG_BIN_TBL(9),  0xe0);
            reg_bin.WriteReg(REG_BIN_TBL(10), 0x60);
            reg_bin.WriteReg(REG_BIN_TBL(11), 0xa0);
            reg_bin.WriteReg(REG_BIN_TBL(12), 0x40);
            reg_bin.WriteReg(REG_BIN_TBL(13), 0xc0);
            reg_bin.WriteReg(REG_BIN_TBL(14), 0x80);
            reg_bin.WriteReg(REG_BIN_PARAM_END, 14);
        }
        else {
            // 単純2値化(テーブルサイズ=1)
            reg_bin.WriteReg(REG_BIN_TBL(0), bin_th);
            reg_bin.WriteReg(REG_BIN_PARAM_END, 0);
        }


        // キャプチャ
        vdmaw.Oneshot(dmabuf_phys_adr, width, height, frame_num);
        cv::Mat img;
        img = cv::Mat(height*frame_num, width, CV_8UC4);
        udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4 * frame_num);

        // プレーン分解
        std::vector<cv::Mat> planes;
        cv::split(img, planes);
        cv::imshow("planes0", planes[3]);

        cv::Mat view_cls;
        cv::cvtColor(img, view_cls, cv::COLOR_BGRA2BGR);
        cv::Mat cls = planes[3];
        for ( int i = 0; i < 10; ++i ) {
            cv::Mat mask = (cls == i);
//          cv::Mat cls_view = cv::Mat::zeros(cls.size(), CV_8UC1);
//          cls_view.setTo(255, mask);
//          cv::imshow("cls" + std::to_string(i), cls_view);
            view_cls.setTo(colmap[i], mask);
        }
        cv::imshow("view_cls", view_cls);

        // 表示
        view_scale = std::max(1, view_scale);
        cv::Mat view_img;
        cv::resize(img, view_img, cv::Size(), 1.0/view_scale, 1.0/view_scale);
        cv::imshow("img", view_img);

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
        
        // flip
        case 'h':  flip_h = !flip_h;  break;
        case 'v':  flip_v = !flip_v;  break;
        
        // aoi position
        case 'w':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() - 4);    break;
        case 'z':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() + 4);    break;
        case 'a':  imx219.SetAoiPosition(imx219.GetAoiX() - 4, imx219.GetAoiY());    break;
        case 's':  imx219.SetAoiPosition(imx219.GetAoiX() + 4, imx219.GetAoiY());    break;

        case 'd':   // image dump
            {
                cv::Mat imgRgb;
                cv::cvtColor(img, imgRgb, cv::COLOR_BGRA2BGR);
                cv::imwrite("img_dump.png", imgRgb);
            }
            break;

        case 'r': // image record
            std::cout << "record" << std::endl;
            vdmaw.Oneshot(dmabuf_phys_adr, width, height, rec_frame_num);
            int offset = 0;
            for ( int i = 0; i < rec_frame_num; i++ ) {
                char fname[64];
                sprintf(fname, "rec_%04d.png", i);
                cv::Mat imgRec(height, width, CV_8UC4);
                udmabuf_acc.MemCopyTo(imgRec.data, offset, width * height * 4);
                offset += width * height * 4;
                cv::Mat imgRgb;
                cv::cvtColor(imgRec, imgRgb, cv::COLOR_BGRA2BGR);
                cv::imwrite(fname, imgRgb);
            }
            break;
        }
    }

    std::cout << "close device" << std::endl;

    // DMA停止
    vdmaw.Stop();
    
    // 取り込み停止
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
    usleep(100000);

    // close
    imx219.Stop();
    imx219.Close();

    // カメラOFF
    uio_acc.WriteReg(2, 0);

    return 0;
}


// end of file
