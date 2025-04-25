#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <iostream>
#include <fstream>
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <sstream>

#include <opencv2/opencv.hpp>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/JellyRegs.h"
#include "jelly/Imx219Control.h"
#include "jelly/GpioAccessor.h"
#include "jelly/VideoDmaControl.h"

void write_pgm(const char* filename, cv::Mat img, int depth=4095);

static  volatile    bool    g_signal = false;
void signal_handler(int signo) {
    g_signal = true;
}

int main(int argc, char *argv[])
{
    double  pixel_clock = 91000000.0;
    bool    binning     = false;
    int     width       = 3280;
    int     height      = 2464;
    int     aoi_x       = 0;
    int     aoi_y       = 0;
    bool    flip_h      = false;
    bool    flip_v      = false;
    int     frame_rate  = 20;
    int     exposure    = 33;
    int     a_gain      = 20;
    int     d_gain      = 0;
    int     gauss_level = 0;
    int     imgsel      = 0;
    int     view_scale  = 4;

    // 1000fps
    pixel_clock = 139200000.0;
    binning     = true;
    width       = 640;
    height      = 130;//2;
    aoi_x       = -1;
    aoi_y       = -1;
    flip_h      = false;
    flip_v      = false;
    frame_rate  = 1000;
    exposure    = 1;
    a_gain      = 20;
    d_gain      = 10;
    view_scale  = 1;

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
            view_scale  = 1;
        }
        else if ( strcmp(argv[i], "vga") == 0 ) {
            pixel_clock = 91000000.0;
            binning     = true;
            width       = 640;
            height      = 480;
            aoi_x       = -1;
            aoi_y       = -1;
            flip_h      = false;
            flip_v      = false;
            frame_rate  = 60;
            exposure    = 20;
            a_gain      = 20;
            d_gain      = 0;
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
        else if ( strcmp(argv[i], "-gauss") == 0 && i+1 < argc) {
            ++i;
            gauss_level = strtol(argv[i], nullptr, 0);
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

    auto reg_gpio    = uio_acc.GetAccessor(0x00000000);
    auto reg_fmtr    = uio_acc.GetAccessor(0x00100000);
    auto reg_gauss   = uio_acc.GetAccessor(0x00401000);
    auto reg_lk      = uio_acc.GetAccessor(0x00410000);
    auto reg_imgsel  = uio_acc.GetAccessor(0x0040f000);
    auto reg_wdma    = uio_acc.GetAccessor(0x00210000);
    auto reg_log_of  = uio_acc.GetAccessor(0x00300000);
    auto reg_log_lk  = uio_acc.GetAccessor(0x00310000);
    auto reg_log_lin = uio_acc.GetAccessor(0x00320000);

#if 1
    std::cout << "CORE ID" << std::endl;
    std::cout << "gpio  : " << std::hex << reg_gpio .ReadReg(0) << std::endl;
    std::cout << "gauss : " << std::hex << reg_gauss.ReadReg(0) << std::endl;
    std::cout << "fmtr  : " << std::hex << reg_fmtr .ReadReg(0) << std::endl;
    std::cout << "wdma  : " << std::hex << reg_wdma .ReadReg(0) << std::endl;
#endif

    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf-jelly-vram0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
    std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
    std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;

    jelly::VideoDmaControl vdmaw(reg_wdma, 2, 2, true);


    // カメラON
    reg_gpio.WriteReg(2, 1);
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

    int     rec_frame_num = std::min(100, (int)(dmabuf_mem_size / (width * height * 2)));
    int     frame_num     = 1;

    if ( rec_frame_num <= 0 ) {
        std::cout << "udmabuf size error" << std::endl;
    }

    // video input start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);

    int     rect_cx = width  / 2;
    int     rect_cy = height / 2;
    int     rect_w  = 64;
    int     rect_h  = 64;
    double  track_x = rect_cx;
    double  track_y = rect_cy;

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
    cv::createTrackbar("gauss" ,   "img", nullptr, 3);
    cv::setTrackbarPos("gauss",    "img", gauss_level);
    cv::createTrackbar("x" ,       "img", nullptr, width);
    cv::setTrackbarPos("x",        "img", rect_cx);
    cv::createTrackbar("y" ,       "img", nullptr, height);
    cv::setTrackbarPos("y",        "img", rect_cy);
    cv::createTrackbar("w" ,       "img", nullptr, width);
    cv::setTrackbarPos("w",        "img", rect_w);
    cv::createTrackbar("h" ,       "img", nullptr, height);
    cv::setTrackbarPos("h",        "img", rect_h);
    cv::createTrackbar("imgsel",   "img", nullptr, 3);
    cv::setTrackbarPos("imgsel",   "img", imgsel);

    vdmaw.SetBufferAddr(dmabuf_phys_adr);
    vdmaw.SetImageSize(width, height);
//  vdmaw.Start();

    // White Balance
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_OFFSET0,    66); // black level R 
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_OFFSET1,    66); // black level G
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_OFFSET2,    66); // black level G
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_OFFSET3,    66); // black level B
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_COEFF0 ,  4620); // white balance R
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_COEFF1 ,  4096); // white balance G
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_COEFF2 ,  4096); // white balance G
//    reg_wb.WriteReg(REG_IMG_BAYER_WB_PARAM_COEFF3 , 10428); // white balance B

    std::vector<double> hist_dx;
    std::vector<double> hist_dy;
    std::vector<double> log_hist_dx;
    std::vector<double> log_hist_dy;

    std::vector<std::uint64_t> log_line_time;
    std::vector<std::uint64_t> log_line_num;

    int     key;
    while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
        if ( g_signal ) { break; }

#if 0
        // LK ログ取得
        while ( reg_log_lk.ReadReg(REG_LOGGER_CTL_STATUS) ) {
            auto ey  = (double)(std::int64_t)reg_log_lk.ReadReg(REG_LOGGER_POL_DATA(4));
            auto ex  = (double)(std::int64_t)reg_log_lk.ReadReg(REG_LOGGER_POL_DATA(3));
            auto gxy = (double)(std::int64_t)reg_log_lk.ReadReg(REG_LOGGER_POL_DATA(2));
            auto gy2 = (double)(std::int64_t)reg_log_lk.ReadReg(REG_LOGGER_POL_DATA(1));
            auto gx2 = (double)(std::int64_t)reg_log_lk.ReadReg(REG_LOGGER_READ_DATA);
            auto det = gx2 * gy2 - gxy * gxy;
            auto dx  = 64 * -(gx2 * ex - gxy * ey) / det;
            auto dy  = 64 * -(gy2 * ey - gxy * ex) / det;
//          std::cout << "dx :" << dx << "   dy : " << dy << std::endl;
            hist_dx.push_back(dx);
            hist_dy.push_back(dy);
            if ( hist_dx.size() > 1000 ) {
                hist_dx.erase(hist_dx.begin());
                hist_dy.erase(hist_dy.begin());
            }

            log_hist_dx.push_back(dx);
            log_hist_dy.push_back(dy);
            if ( log_hist_dx.size() > 10000 ) {
                log_hist_dx.erase(log_hist_dx.begin());
                log_hist_dy.erase(log_hist_dy.begin());
            }

//          printf("gx2 : %10.0f gy2 : %10.0f gxy : %10.0f ex : %10.0f ey : %10.0f\n", gx2, gy2, gxy, ex, ey);
//          std::cout << "gx2 : " << gx2 << std::endl;
//          std::cout << "gy2 : " << gy2 << std::endl;
//          std::cout << "gxy : " << gxy << std::endl;
//          std::cout << "ex  : " << ex  << std::endl;
//          std::cout << "ey  : " << ey  << std::endl;
            
            track_x += dx;
            track_y += dy;
            track_x = std::max(0.0,            track_x);
            track_x = std::min((double)width,  track_x);
            track_y = std::max(0.0,            track_y);
            track_y = std::min((double)height, track_y);
        }
#else
        // LK ログ取得
        while ( reg_log_of.ReadReg(REG_LOGGER_CTL_STATUS) ) {
            auto dy = ((double)(std::int64_t)reg_log_of.ReadReg(REG_LOGGER_POL_DATA(1))) / 65536.0;
            auto dx = ((double)(std::int64_t)reg_log_of.ReadReg(REG_LOGGER_READ_DATA)  ) / 65536.0;
//          std::cout << "dx :" << dx << "   dy : " << dy << std::endl;
            hist_dx.push_back(dx);
            hist_dy.push_back(dy);
            if ( hist_dx.size() > 1000 ) {
                hist_dx.erase(hist_dx.begin());
                hist_dy.erase(hist_dy.begin());
            }

            log_hist_dx.push_back(dx);
            log_hist_dy.push_back(dy);
            if ( log_hist_dx.size() > 10000 ) {
                log_hist_dx.erase(log_hist_dx.begin());
                log_hist_dy.erase(log_hist_dy.begin());
            }
            
            track_x += dx;
            track_y += dy;
            track_x = std::max(0.0,            track_x);
            track_x = std::min((double)width,  track_x);
            track_y = std::max(0.0,            track_y);
            track_y = std::min((double)height, track_y);
        }
#endif

        cv::Mat graph = cv::Mat::zeros(200, 1000, CV_8UC3);
        for ( int i = 0; i < (int)hist_dx.size(); i++ ) {
            int y0 = 100 - (int)(hist_dx[i] * 10.0);
            cv::circle(graph, cv::Point(i, y0), 1, cv::Scalar(0, 255, 0), -1);
            int y1 = 100 - (int)(hist_dy[i] * 10.0);
            cv::circle(graph, cv::Point(i, y1), 1, cv::Scalar(255, 0, 0), -1);
        }
        cv::imshow("graph", graph);

        cv::Mat graph2 = cv::Mat::zeros(200, 200, CV_8UC3);
        for ( int i = 0; i < (int)hist_dx.size(); i++ ) {
            int x = 100 - (int)(hist_dx[i] * 10.0);
            int y = 100 - (int)(hist_dy[i] * 10.0);
            cv::circle(graph2, cv::Point(x, y), 1, cv::Scalar(0, 255, 0), -1);
        }
        cv::imshow("x-y", graph2);


        // トラックバー値取得
        view_scale  = cv::getTrackbarPos("scale",    "img");
        frame_rate  = cv::getTrackbarPos("fps",      "img");
        exposure    = cv::getTrackbarPos("exposure", "img");
        a_gain      = cv::getTrackbarPos("a_gain",   "img");
        d_gain      = cv::getTrackbarPos("d_gain",   "img");
        gauss_level = cv::getTrackbarPos("gauss" ,   "img");
        imgsel      = cv::getTrackbarPos("imgsel",   "img");
        rect_cx     = cv::getTrackbarPos("x",        "img");
        rect_cy     = cv::getTrackbarPos("y",        "img");
        rect_w      = cv::getTrackbarPos("w",        "img");
        rect_h      = cv::getTrackbarPos("h",        "img");
        int x0 = std::max(0,      rect_cx - rect_w/2);
        int x1 = std::min(width,  rect_cx + rect_w/2);
        int y0 = std::max(0,      rect_cy - rect_h/2);
        int y1 = std::min(height, rect_cy + rect_h/2);

        // 設定
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);
//        reg_demos.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
//        reg_demos.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);  // update & enable
        
        reg_gauss.WriteReg(REG_IMG_GAUSS3X3_PARAM_ENABLE, (1 << gauss_level) - 1);
        reg_gauss.WriteReg(REG_IMG_GAUSS3X3_CTL_CONTROL,  3);
        
        reg_lk.WriteReg(REG_IMG_LK_ACC_PARAM_X,          x0);
        reg_lk.WriteReg(REG_IMG_LK_ACC_PARAM_Y,          y0);
        reg_lk.WriteReg(REG_IMG_LK_ACC_PARAM_WIDTH,   x1-x0);
        reg_lk.WriteReg(REG_IMG_LK_ACC_PARAM_HEIGHT,  y1-y0);
        reg_lk.WriteReg(REG_IMG_LK_ACC_CTL_CONTROL,       3);
    

        reg_imgsel.WriteReg(REG_IMG_SELECTOR_CTL_SELECT, imgsel);


        // キャプチャ
        vdmaw.Oneshot(dmabuf_phys_adr, width, height, frame_num);

        if (0) {
            cv::Mat img_raw = cv::Mat(height, width, CV_8UC4);
            udmabuf_acc.MemCopyTo(img_raw.data, 0, width * height * 4);
            std::vector<cv::Mat> planes;
            cv::split(img_raw, planes);
            cv::imshow("plane0", planes[0]);
            cv::imshow("plane1", planes[1]);
            cv::imshow("plane2", planes[2]);
            cv::imshow("plane3", planes[3]);
        }
        
        cv::Mat img;
        img = cv::Mat(height*frame_num, width, CV_16UC1);
        udmabuf_acc.MemCopyTo(img.data, 0, width * height * 2 * frame_num);
        img *= 64;

        // 表示
//      view_scale = std::max(1, view_scale);
        cv::Mat view_img;
        cv::cvtColor(img, view_img, cv::COLOR_BayerRG2RGB);
        cv::rectangle(view_img, cv::Point(x0, y0), cv::Point(x1, y1), cv::Scalar(0, 65535, 0), 1);
        cv::circle(view_img, cv::Point(track_x, track_y), 4, cv::Scalar(0, 0, 65535), -1);
//      cv::resize(img, view_img, cv::Size(), 1.0/view_scale, 1.0/view_scale);
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

        case 'a':
            track_x = rect_cx;
            track_y = rect_cy;
            break;
        
        // aoi position
//      case 'w':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() - 4);    break;
//      case 'z':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() + 4);    break;
//      case 'a':  imx219.SetAoiPosition(imx219.GetAoiX() - 4, imx219.GetAoiY());    break;
//      case 's':  imx219.SetAoiPosition(imx219.GetAoiX() + 4, imx219.GetAoiY());    break;

        case 's':   // save data
            {
                std::ofstream ofs("data.csv");
                for ( int i= 0; i < (int)log_hist_dx.size(); i++ ) {
                    ofs << log_hist_dx[i] << "," << log_hist_dy[i] << std::endl;
                }
            }

            {
                log_line_time.clear();
                log_line_num.clear();
                while ( reg_log_lin.ReadReg(REG_LOGGER_CTL_STATUS) ) {
                    reg_log_lin.ReadReg(REG_LOGGER_READ_DATA);
                }
                while ( log_line_time.size() < 1000 ) {
                    if ( reg_log_lin.ReadReg(REG_LOGGER_CTL_STATUS) ) {
                        auto time = reg_log_lin.ReadReg(REG_LOGGER_POL_TIMER0);
                        auto line = reg_log_lin.ReadReg(REG_LOGGER_READ_DATA);
                        log_line_time.push_back(time);
                        log_line_num.push_back(line);
                    }
                }
                std::ofstream ofs("line_time.csv");
                for ( int i= 0; i < (int)log_line_time.size(); i++ ) {
                    ofs << log_line_time[i] << "," << log_line_num[i] << std::endl;
                }
            }

            break;

        case 'd':   // image dump
            cv::imwrite("img_dump.png", img);
            break;
        
        case 'r': // image record
            {
                std::cout << "record" << std::endl;
                vdmaw.Oneshot(dmabuf_phys_adr, width, height, rec_frame_num);
                auto now = std::chrono::system_clock::now();
                auto in_time_t = std::chrono::system_clock::to_time_t(now);
                std::stringstream ss;
                ss << std::put_time(std::localtime(&in_time_t), "record/%Y%m%d-%H%M%S");
                auto rec_dir = ss.str();
                std::filesystem::path dir(rec_dir);
                std::filesystem::create_directories(dir);
                int offset = 0;
                for ( int i = 0; i < rec_frame_num; i++ ) {
                    char fname[64];
                    sprintf(fname, "%s/rec_%04d.png", rec_dir.c_str(), i);
                    cv::Mat imgRec(height, width, CV_16U);
                    udmabuf_acc.MemCopyTo(imgRec.data, offset, width * height * 2);
                    offset += width * height * 2;
                    cv::imwrite(fname, imgRec * 64);
                }
            }
            break;
        }
    }

    std::cout << "close device" << std::endl;

    // DMA 停止
    vdmaw.Stop();

    // 取り込み停止
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
    usleep(100000);

    // close
    imx219.Stop();
    imx219.Close();

    // カメラOFF
    reg_gpio.WriteReg(2, 0);
    usleep(100000);

    return 0;
}


void write_pgm(const char* filename, cv::Mat img, int depth)
{
    FILE* fp = fopen(filename, "wb");
    if ( fp ) {
        fprintf(fp, "P2\n%d %d\n%d\n", img.cols, img.rows, depth);
        for ( int y = 0; y < img.rows; ++y ) {
            for ( int x = 0; x < img.cols; ++x ) {
                fprintf(fp, "%d\n", img.at<uint16_t>(y, x));
            }
        }
        fclose(fp);
    }
}

// end of file
