#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <cmath>

#include <opencv2/opencv.hpp>

#include "jelly/JellyRegs.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/Imx219Control.h"


const int stride = 4096*4;


void    capture_start(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_fmtr, std::uintptr_t bufaddr, int width, int height, int x, int y);
void    capture_stop(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_fmtr);
void    vout_start(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen, std::uintptr_t bufaddr);
void    vout_stop(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen);
void    WriteImage(jelly::MemAccessor& mem_acc, const cv::Mat& img);
cv::Mat ReadImage(jelly::UdmabufAccessor& udmabuf_acc, jelly::MemAccessor& reg_bufalc, int width, int height);


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
    int     bayer_phase = 1;
    int     view_scale  = 1;
    int     view_x      = -1;
    int     view_y      = -1;
    bool    colmat_en   = false;
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
            view_scale  = 1;
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

    // 表示位置を画面中央に
    if ( view_x < 0 ) { view_x = (1280 - width)  / 2; }
    if ( view_y < 0 ) { view_y = (720  - height) / 2; }

    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x10000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri : open error or mmap error" << std::endl;
        return 1;
    }

    // PLのコアのアドレスでマップ
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

    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf0 : open error or mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
    std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
    std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;

    if ( (size_t)dmabuf_mem_size < (size_t)(stride * height * 4) ) {
        printf("udmabuf size error\n");
        return 0;
    }

    // バッファ4面確保
    for ( int i = 0; i < 4; ++i ) {
        reg_bufmng.WriteReg(REG_BUF_MANAGER_BUFFER_ADDR(i), dmabuf_phys_adr + i * stride * height);
    }
    for ( int i = 0; i < 4; ++i ) {
        std::cout << std::hex << reg_bufmng.ReadReg(REG_BUF_MANAGER_BUFFER_ADDR(i)) << std::endl;
    }

    // memmeap iamge fifo
    jelly::UdmabufAccessor udmabuf1_acc("udmabuf1");
    if ( !udmabuf1_acc.IsMapped() ) {
        std::cout << "udmabuf1 : open error or mmap error" << std::endl;
        return 1;
    }

    for ( int i = 0; i < 1024*512; ++i ) {
        udmabuf_acc.WriteReg(i , 0xffffffff);
    }

    for ( int i = 0; i < 1024*512; ++i ) {
        udmabuf1_acc.WriteReg(i , 0x77777777);
    }

    reg_imgdma.WriteReg(REG_DAM_FIFO_CTL_CONTROL, 0x0);
    usleep(100);

    auto fifobuf_phys_adr = udmabuf1_acc.GetPhysAddr();
    auto fifobuf_mem_size = udmabuf1_acc.GetSize();
    std::cout << "udmabuf1 phys addr : 0x" << std::hex << fifobuf_phys_adr << std::endl;
    std::cout << "udmabuf1 size      : " << std::dec << fifobuf_mem_size << std::endl;
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_ADDR, fifobuf_phys_adr);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_SIZE, fifobuf_mem_size);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_AWLEN, 0x0f);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_WTIMEOUT, 0xff);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_ARLEN, 0x0f);
    reg_imgdma.WriteReg(REG_DAM_FIFO_PARAM_RTIMEOUT, 0xff);
    reg_imgdma.WriteReg(REG_DAM_FIFO_CTL_CONTROL, 0x3);


    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
        printf("I2C open error\n");
        return 1;
    }

    // back ground
    if ( imgBack.empty() ) {
        imgBack = cv::Mat::zeros(720, 1280, CV_8UC3);
        cv::putText(imgBack, "Jelly ZYBO Z7 IMX219 sample   Copyright by Ryuji Fuchikami",
            cv::Point(10, 710), cv::FONT_HERSHEY_PLAIN, 2, cv::Scalar(255, 255, 255));
    }
    cv::cvtColor(imgBack, imgBack, CV_BGR2BGRA);
    WriteImage(udmabuf_acc, imgBack);
    
    // camera setup
    imx219.SetPixelClock(pixel_clock);
    imx219.SetAoi(width, height, aoi_x, aoi_y, binning, binning);
    imx219.Start();

    // start
    capture_start(reg_vdmaw, reg_fmtr, dmabuf_phys_adr, width, height, view_x, view_y);    
    vout_start(reg_vdmar, reg_vsgen, dmabuf_phys_adr);    

    // 操作
    cv::namedWindow("control");
    cv::resizeWindow("control", 640, 480);
    cv::createTrackbar("scale",     "control", &view_scale, 4);
    cv::createTrackbar("fps",       "control", &frame_rate, 1000);
    cv::createTrackbar("exposure",  "control", &exposure, 1000);
    cv::createTrackbar("a_gain",    "control", &a_gain, 20);
    cv::createTrackbar("d_gain",    "control", &d_gain, 24);
    cv::createTrackbar("bayer" ,    "control", &bayer_phase, 3);
    cv::createTrackbar("gamm" ,     "control", &gamma, 30);
    cv::createTrackbar("gauss" ,    "control", &gauss_level, 3);
    cv::createTrackbar("canny_th" , "control", &canny_th, 255);
    cv::createTrackbar("diff_th" ,  "control", &diff_th, 255);

    int gamma_prev = 0;
    int     key;
    while ( (key = (cv::waitKeyEx(10) & 0xff)) != 0x1b ) {
        auto img = ReadImage(udmabuf_acc, reg_bufalc, width, height);
        cv::imshow("img", img);
        
        // カメラ設定
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);

        // demosaic
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);  // update & enable

        // color matrix
        if ( colmat_en ) {
            // てきとー
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX22, (int)( 1.114257813 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX21, (int)(-0.200195313 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX20, (int)( 0.085937500 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX23, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX12, (int)(-0.050781250 * (1 << 16)));		
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX11, (int)( 1.200195313 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX10, (int)(-0.150390625 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX13, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX02, (int)( 0.068359375 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX01, (int)(-0.219726563 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX00, (int)( 1.151367188 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX03, (int)( 0.000000000 * (1 << 16)));
        }
        else {
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX00, (int)( 1.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX01, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX02, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX03, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX10, (int)( 0.000000000 * (1 << 16)));		
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX11, (int)( 1.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX12, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX13, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX20, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX21, (int)( 0.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX22, (int)( 1.000000000 * (1 << 16)));
            reg_colmat.WriteReg(REG_IMG_COLMAT_PARAM_MATRIX23, (int)( 0.000000000 * (1 << 16)));
        }
        reg_colmat.WriteReg(REG_IMG_COLMAT_CTL_CONTROL, 0x3);

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

        // gauss
        reg_gauss.WriteReg(REG_IMG_GAUSS3X3_PARAM_ENABLE, (1 << gauss_level)-1);
        reg_gauss.WriteReg(REG_IMG_GAUSS3X3_CTL_CONTROL, 0x3);

        // canny
        reg_canny.WriteReg(REG_IMG_CANNY_PARAM_TH, canny_th*canny_th);
        reg_canny.WriteReg(REG_IMG_CANNY_CTL_CONTROL, 0x3);

        // diff binarize
        reg_bindiff.WriteReg(REG_IMG_BINARIZER_PARAM_TH, diff_th);
        reg_bindiff.WriteReg(REG_IMG_BINARIZER_CTL_CONTROL, 0x3);

        // ユーザー操作
        switch ( key ) {
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

        case 'c':   colmat_en = !colmat_en; break;

        case 'd':   // image dump
            cv::Mat imgRgb;
            cv::cvtColor(img, imgRgb, CV_BGRA2BGR);
            cv::imwrite("img_dump.png", imgRgb);
            break;
        }
    }
    
    // close
    capture_stop(reg_vdmaw, reg_fmtr);
    vout_stop(reg_vdmar, reg_vsgen);

    imx219.Stop();
    imx219.Close();
    
    // FIFO停止
    reg_imgdma.WriteReg(REG_DAM_FIFO_CTL_CONTROL, 0x0);

    return 0;
}


void WriteImage(jelly::MemAccessor& mem_acc, const cv::Mat& img)
{
    for ( int i = 0; i < img.rows; i++ )
    {
        mem_acc.MemCopyFrom(i*stride, img.data + img.step*i, img.cols*4);
    }
}

cv::Mat ReadImage(jelly::UdmabufAccessor& udmabuf_acc, jelly::MemAccessor& reg_bufalc, int width, int height)
{
    reg_bufalc.WriteReg(REG_BUF_ALLOC_BUFFER0_REQUEST, 1);
    auto buf_addr = reg_bufalc.ReadReg(REG_BUF_ALLOC_BUFFER0_ADDR);
    buf_addr -= udmabuf_acc.GetPhysAddr();

#if 0
    // 32bitデータ
    cv::Mat img(height, width, CV_8UC4);
    for ( int i = 0; i < img.rows; i++ )
    {
        udmabuf_acc.MemCopyTo(img.data + i*img.step, buf_addr + i*stride, img.cols*4);
    }
#else
    // 24bitデータ
    cv::Mat img(height, width, CV_8UC3);
    for ( int i = 0; i < img.rows; i++ )
    {
        udmabuf_acc.MemCopyTo(img.data + i*img.step, buf_addr + i*stride, img.cols*3);
    }
#endif

    reg_bufalc.WriteReg(REG_BUF_ALLOC_BUFFER0_RELEASE, 1);

    return img;
}


void capture_start(jelly::MemAccessor& reg_vdmaw, jelly::MemAccessor& reg_fmtr, std::uintptr_t bufaddr, int width, int height, int x, int y)
{
    // DMA start
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_ADDR,       bufaddr + stride*y + 4*x);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_LINE_STEP,  stride);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_H_SIZE,     width-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_V_SIZE,     height-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_F_SIZE,     1-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_FRAME_STEP, width*stride);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_AWLEN_MAX,  31);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_CTL_CONTROL,      0x03 | 0x08);

    // normalizer start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,  100000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,      width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,     height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,       0x0ff);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,    0x100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,      0x03);
}

void capture_stop(jelly::MemAccessor& reg_vdmaw, jelly::MemAccessor& reg_fmtr)
{
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_CTL_CONTROL, 0x00);
    while ( reg_vdmaw.ReadReg(REG_VIDEO_WDMA_CTL_STATUS) != 0 ) {
        usleep(100);
    }

    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
}


void vout_start(jelly::MemAccessor& reg_vdmar, jelly::MemAccessor& reg_vsgen, std::uintptr_t bufaddr)
{
    // VSync Start
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HTOTAL,      1650);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_START,    0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HDISP_END,   1280);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_START, 1390);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_END,   1430);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_HSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VTOTAL,       750);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_START,    0);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VDISP_END,    720);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_START,  725);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_END,    730);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_PARAM_VSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL,          1);

    // DMA start
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_ADDR,       bufaddr);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_LINE_STEP,  stride);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_H_SIZE,     1280-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_V_SIZE,     720-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_FRAME_STEP, stride*720);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_F_SIZE,     1-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_ARLEN_MAX,  31);
    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL,      0x03 | 0x08);
}


void vout_stop(jelly::MemAccessor& reg_vdmar, jelly::MemAccessor& reg_vsgen)
{
    reg_vdmar.WriteReg(REG_VDMA_READ_CTL_CONTROL, 0x00);
    while ( reg_vdmar.ReadReg(REG_VDMA_READ_CTL_STATUS) != 0 ) {
        usleep(100);
    }

    reg_vsgen.WriteReg(REG_VIDEO_VSGEN_CTL_CONTROL, 0x00);
}


// end of file
