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


#define BUF_FORMAT_SIZE         3
#define BUF_FORMAT_TYPE         (BUF_FORMAT_SIZE == 3 ? CV_8UC3 : CV_8UC4)
#define BUF_STRIDE_SIZE         (4096*4)

#define REG_MCOL_PARAM_MODE     0x00
#define REG_MCOL_PARAM_TH       0x01


void    capture_start(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_fmtr, std::uintptr_t bufaddr, int width, int height, int x, int y);
void    capture_stop(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_fmtr);
void    vout_start(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen, std::uintptr_t bufaddr);
void    vout_stop(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen);
void    WriteImage(jelly::MemAccessor& mem_acc, const cv::Mat& img, int offset=0);
cv::Mat ReadImage(jelly::UdmabufAccessor& udmabuf_acc, jelly::MemAccessor& reg_bufalc, int width, int height, int x, int y);


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
    int     view_scale  = 1;
    int     view_x      = -1;
    int     view_y      = -1;
    int     bayer_phase = 1;
    int     bin_th  = 127;
    int     bin_inv = 0;
    int     mcol_mode = 2;
    int     mcol_th  = 7;
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
    auto reg_colmat  = uio_acc.GetAccessor(0x00200100);  // カラーマトリックス
    auto reg_bin     = uio_acc.GetAccessor(0x00400000);  // 二値化
    auto reg_mcol    = uio_acc.GetAccessor(0x00410000);  // 色付け
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
    std::cout << "bin     : " << std::hex << reg_bin.ReadReg(0) << std::endl;
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

    if ( (size_t)dmabuf_mem_size < (size_t)(BUF_STRIDE_SIZE * height * BUF_FORMAT_SIZE) ) {
        printf("udmabuf size error\n");
        return 0;
    }

    // バッファ4面確保
    for ( int i = 0; i < 4; ++i ) {
        reg_bufmng.WriteReg(REG_BUF_MANAGER_BUFFER_ADDR(i), dmabuf_phys_adr + i * BUF_STRIDE_SIZE * 720);
    }
    
    // memmeap iamge fifo
    jelly::UdmabufAccessor udmabuf1_acc("udmabuf1");
    if ( !udmabuf1_acc.IsMapped() ) {
        std::cout << "udmabuf1 : open error or mmap error" << std::endl;
        return 1;
    }


    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
        printf("I2C open error\n");
        return 1;
    }

    // back ground
    if ( imgBack.empty() ) {
        imgBack = cv::Mat::zeros(720, 1280, CV_8UC3);
        cv::putText(imgBack, "Jelly ZYBO Z7 IMX219 sample   Copyright by Ryuz",
            cv::Point(10, 710), cv::FONT_HERSHEY_PLAIN, 2, cv::Scalar(255, 255, 255));
    }
    if ( BUF_FORMAT_TYPE == CV_8UC4 ) {
        cv::cvtColor(imgBack, imgBack, CV_BGR2BGRA);
    }
    for ( int i = 0; i < 4; ++i ) {
        WriteImage(udmabuf_acc, imgBack, i * BUF_STRIDE_SIZE * 720);
    }

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
    cv::createTrackbar("bin_th" ,   "control", &bin_th, 255);
    cv::createTrackbar("bin_inv" ,  "control", &bin_inv, 1);
    cv::createTrackbar("mcol_mode", "control", &mcol_mode, 3);
    cv::createTrackbar("mcol_th",   "control", &mcol_th, 15);

    int     key;
    while ( (key = (cv::waitKeyEx(10) & 0xff)) != 0x1b ) {
        auto img = ReadImage(udmabuf_acc, reg_bufalc, width, height, view_x, view_y);
        cv::imshow("img", img);
        
        // カメラ設定
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);

        // demosaic
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
        reg_demos.WriteReg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);

        // diff binarize
        reg_bin.WriteReg(REG_VIDEO_BINARIZER_PARAM_TH, bin_th);
        reg_bin.WriteReg(REG_VIDEO_BINARIZER_PARAM_INV, bin_inv);

        // mnist color
        reg_mcol.WriteReg(REG_MCOL_PARAM_MODE, mcol_mode);
        reg_mcol.WriteReg(REG_MCOL_PARAM_TH, mcol_th);

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
    
    return 0;
}


void WriteImage(jelly::MemAccessor& mem_acc, const cv::Mat& img, int offset)
{
    for ( int i = 0; i < img.rows; i++ )
    {
        mem_acc.MemCopyFrom(i*BUF_STRIDE_SIZE+offset, img.data + img.step*i, img.cols*BUF_FORMAT_SIZE);
    }
}

cv::Mat ReadImage(jelly::UdmabufAccessor& udmabuf_acc, jelly::MemAccessor& reg_bufalc, int width, int height, int x, int y)
{
    reg_bufalc.WriteReg(REG_BUF_ALLOC_BUFFER0_REQUEST, 1);
    auto buf_addr = reg_bufalc.ReadReg(REG_BUF_ALLOC_BUFFER0_ADDR);
    buf_addr -= udmabuf_acc.GetPhysAddr();

    cv::Mat img(height, width, BUF_FORMAT_TYPE);
    for ( int i = 0; i < img.rows; i++ )
    {
        udmabuf_acc.MemCopyTo(img.data + i*img.step, buf_addr + (i+y)*BUF_STRIDE_SIZE + x*BUF_FORMAT_SIZE, img.cols*BUF_FORMAT_SIZE);
    }

    reg_bufalc.WriteReg(REG_BUF_ALLOC_BUFFER0_RELEASE, 1);

    return img;
}


void capture_start(jelly::MemAccessor& reg_vdmaw, jelly::MemAccessor& reg_fmtr, std::uintptr_t bufaddr, int width, int height, int x, int y)
{
    // DMA start
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_ADDR,       bufaddr);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_OFFSET,     BUF_STRIDE_SIZE*y + BUF_FORMAT_SIZE*x);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_LINE_STEP,  BUF_STRIDE_SIZE);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_H_SIZE,     width-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_V_SIZE,     height-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_F_SIZE,     1-1);
    reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_FRAME_STEP, height*BUF_STRIDE_SIZE);
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
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_LINE_STEP,  BUF_STRIDE_SIZE);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_H_SIZE,     1280-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_V_SIZE,     720-1);
    reg_vdmar.WriteReg(REG_VDMA_READ_PARAM_FRAME_STEP, BUF_STRIDE_SIZE*720);
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
