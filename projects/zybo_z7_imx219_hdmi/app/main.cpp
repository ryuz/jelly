#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
//#include <sys/mman.h>
//#include <errno.h>
//#include <sys/ioctl.h>
//#include <linux/i2c-dev.h>
#include <opencv2/opencv.hpp>

#include "jelly/UioAccess.h"
#include "jelly/UdmabufAccess.h"
#include "I2cAccess.h"
#include "IMX219Control.h"

using namespace jelly;


// Video Write-DMA
#define REG_WDMA_ID                 0x00
#define REG_WDMA_VERSION            0x01
#define REG_WDMA_CTL_CONTROL        0x04
#define REG_WDMA_CTL_STATUS         0x05
#define REG_WDMA_CTL_INDEX          0x07
#define REG_WDMA_PARAM_ADDR         0x08
#define REG_WDMA_PARAM_STRIDE       0x09
#define REG_WDMA_PARAM_WIDTH        0x0a
#define REG_WDMA_PARAM_HEIGHT       0x0b
#define REG_WDMA_PARAM_SIZE         0x0c
#define REG_WDMA_PARAM_AWLEN        0x0f
#define REG_WDMA_MONITOR_ADDR       0x10
#define REG_WDMA_MONITOR_STRIDE     0x11
#define REG_WDMA_MONITOR_WIDTH      0x12
#define REG_WDMA_MONITOR_HEIGHT     0x13
#define REG_WDMA_MONITOR_SIZE       0x14
#define REG_WDMA_MONITOR_AWLEN      0x17

// Video Read-DMA
#define REG_RDMA_CORE_ID            0x00
#define REG_RDMA_CORE_VERSION       0x01
#define REG_RDMA_CTL_CONTROL        0x04
#define REG_RDMA_CTL_STATUS         0x05
#define REG_RDMA_CTL_INDEX          0x06
#define REG_RDMA_PARAM_ADDR         0x08
#define REG_RDMA_PARAM_STRIDE       0x09
#define REG_RDMA_PARAM_WIDTH        0x0a
#define REG_RDMA_PARAM_HEIGHT       0x0b
#define REG_RDMA_PARAM_SIZE         0x0c
#define REG_RDMA_PARAM_ARLEN        0x0f
#define REG_RDMA_MONITOR_ADDR       0x10
#define REG_RDMA_MONITOR_STRIDE     0x11
#define REG_RDMA_MONITOR_WIDTH      0x12
#define REG_RDMA_MONITOR_HEIGHT     0x13
#define REG_RDMA_MONITOR_SIZE       0x14
#define REG_RDMA_MONITOR_ARLEN      0x17

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

// Raw to RGB
#define REG_RAW2RGB_DEMOSAIC_PHASE  0x00
#define REG_RAW2RGB_DEMOSAIC_BYPASS 0x01

// Video sync generator
#define REG_VSGEN_CORE_ID           0x00
#define REG_VSGEN_CORE_VERSION      0x01
#define REG_VSGEN_CTL_CONTROL       0x04
#define REG_VSGEN_CTL_STATUS        0x05
#define REG_VSGEN_PARAM_HTOTAL      0x08
#define REG_VSGEN_PARAM_HSYNC_POL   0x0B
#define REG_VSGEN_PARAM_HDISP_START 0x0C
#define REG_VSGEN_PARAM_HDISP_END   0x0D
#define REG_VSGEN_PARAM_HSYNC_START 0x0E
#define REG_VSGEN_PARAM_HSYNC_END   0x0F
#define REG_VSGEN_PARAM_VTOTAL      0x10
#define REG_VSGEN_PARAM_VSYNC_POL   0x13
#define REG_VSGEN_PARAM_VDISP_START 0x14
#define REG_VSGEN_PARAM_VDISP_END   0x15
#define REG_VSGEN_PARAM_VSYNC_START 0x16
#define REG_VSGEN_PARAM_VSYNC_END   0x17


void capture_start(MemAccess& reg_wdma, MemAccess& reg_norm, std::uintptr_t bufaddr, int width, int height, int x, int y);
void capture_stop(MemAccess& reg_wdma, MemAccess& reg_norm);
void vout_start(MemAccess& reg_rdma, MemAccess& reg_vsgen, std::uintptr_t bufaddr);
void vout_stop(MemAccess& reg_rdma, MemAccess& reg_vsgen);

void WriteImage(MemAccess& mem_acc, const cv::Mat& img);

int main(int argc, char *argv[])
{
    double  pixel_clock = 139200000.0;
    bool    binning     = true;
    int     width       = 640;
    int     height      = 132;
    int     aoi_x       = -1;
    int     aoi_y       = -1;
    bool    flip_h      = false;
    bool    flip_v      = false;
    int     frame_rate  = 1000;
    int     exposure    = 10;
    int     a_gain      = 20;
    int     d_gain      = 10;
    int     bayer_phase = 0;
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
//  std::cout << "\nuio open" << std::endl;
    UioAccess uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }
    auto reg_wdma  = uio_acc.GetMemAccess(0x00010000);
    auto reg_norm  = uio_acc.GetMemAccess(0x00011000);
    auto reg_rgb   = uio_acc.GetMemAccess(0x00012000);
    auto reg_rdma  = uio_acc.GetMemAccess(0x00020000);
    auto reg_vsgen = uio_acc.GetMemAccess(0x00021000);
    
    reg_vsgen.WriteReg(REG_VSGEN_CTL_CONTROL, 1);

    // mmap udmabuf
 // std::cout << "\nudmabuf0 open" << std::endl;
    UdmabufAccess udmabuf_acc("udmabuf0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf0 mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
//  auto dmabuf_mem_size = udmabuf_acc.GetSize();
//  std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
//  std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;


    // IMX219 I2C control
    IMX219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
        printf("I2C open error\n");
        return 1;
    }

    imx219.SetPixelClock(pixel_clock);
    imx219.SetAoi(width, height, aoi_x, aoi_y, binning, binning);
    imx219.Start();


    capture_start(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, 0, 0);    
    vout_start(reg_rdma, reg_vsgen, dmabuf_phys_adr);    

    // test
    cv::Mat img = cv::imread("lena.jpg");
    cv::cvtColor(img, img, CV_BGR2BGRA);
    WriteImage(udmabuf_acc, img);
    {
        auto p = (std::uint32_t *)udmabuf_acc.GetPtr();
        for ( int i = 0; i < 1024*16; ++i ) {
            p[i] = 0x12345678;
        }
    }
    return 0;

    int     key;
    while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
        // 設定
        imx219.SetFrameRate(frame_rate);
        imx219.SetExposureTime(exposure / 1000.0);
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        imx219.SetFlip(flip_h, flip_v);
        reg_rgb.WriteReg(REG_RAW2RGB_DEMOSAIC_PHASE, bayer_phase);

        // キャプチャ
//      capture_still_image(reg_wdma, reg_norm, dmabuf_phys_adr, width, height, frame_num);
        cv::Mat img(height, width, CV_8UC4);
//      udmabuf_acc.MemCopyFrom(img.data, 0, width * height * 4);
        
        // 表示
        cv::Mat view_img;
        cv::resize(img, view_img, cv::Size(), 1.0/view_scale, 1.0/view_scale);

        cv::imshow("img", view_img);
        cv::createTrackbar("scale",    "img", &view_scale, 4);
        cv::createTrackbar("fps",      "img", &frame_rate, 1000);
        cv::createTrackbar("exposure", "img", &exposure, 1000);
        cv::createTrackbar("a_gain",   "img", &a_gain, 200);
        cv::createTrackbar("d_gain",   "img", &d_gain, 240);
        cv::createTrackbar("bayer" ,   "img", &bayer_phase, 3);

        // ユーザー操作
        if ( key == 'p' ) {
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
        }
        
        if ( key == 'h' ) {
            flip_h = !flip_h;
        }

        if ( key == 'v' ) {
            flip_v = !flip_v;
        }

        if ( key == 'd' ) {
            // image dump
            cv::Mat imgRgb;
            cv::cvtColor(img, imgRgb, CV_BGRA2BGR);
            cv::imwrite("img_dump.png", imgRgb);
        }
    }

    // close
    capture_stop(reg_wdma, reg_norm);
    vout_stop(reg_rdma, reg_vsgen);

    imx219.Stop();
    imx219.Close();
    
    return 0;
}


const int stride = 4096*4;

void WriteImage(MemAccess& mem_acc, const cv::Mat& img)
{
    for ( int i = 0; i < img.rows; i++ )
    {
        mem_acc.MemCopyFrom(i*stride, img.data + img.step*i, img.cols*4);
    }
}

void capture_start(MemAccess& reg_wdma, MemAccess& reg_norm, std::uintptr_t bufaddr, int width, int height, int x, int y)
{
    // DMA start
    reg_wdma.WriteReg(REG_WDMA_PARAM_ADDR, bufaddr + stride*y + 4*x);
    reg_wdma.WriteReg(REG_WDMA_PARAM_STRIDE, stride);               // stride
    reg_wdma.WriteReg(REG_WDMA_PARAM_WIDTH, width);                 // width
    reg_wdma.WriteReg(REG_WDMA_PARAM_HEIGHT, height);               // height
    reg_wdma.WriteReg(REG_WDMA_PARAM_SIZE, width*height);           // size
    reg_wdma.WriteReg(REG_WDMA_PARAM_AWLEN, 7);                    // awlen
    reg_wdma.WriteReg(REG_WDMA_CTL_CONTROL, 0x03);

    // normalizer start
    reg_norm.WriteReg(REG_NORM_FRM_TIMER_EN, 1);
    reg_norm.WriteReg(REG_NORM_FRM_TIMEOUT, 100000000);
    reg_norm.WriteReg(REG_NORM_PARAM_WIDTH, width);
    reg_norm.WriteReg(REG_NORM_PARAM_HEIGHT, height);
    reg_norm.WriteReg(REG_NORM_PARAM_FILL, 0x0ff);
    reg_norm.WriteReg(REG_NORM_PARAM_TIMEOUT, 0x100000);
    reg_norm.WriteReg(REG_NORM_CONTROL, 0x03);
}

void capture_stop(MemAccess& reg_wdma, MemAccess& reg_norm)
{
    reg_wdma.WriteReg(REG_WDMA_CTL_CONTROL, 0x00);
    while ( reg_wdma.ReadReg(REG_WDMA_CTL_STATUS) != 0 ) {
        usleep(100);
    }

    reg_norm.WriteReg(REG_NORM_CONTROL, 0x00);
}


void vout_start(MemAccess& reg_rdma, MemAccess& reg_vsgen, std::uintptr_t bufaddr)
{
    // VSync Start
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HTOTAL,      1650);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HDISP_START,    0);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HDISP_END,   1280);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HSYNC_START, 1390);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HSYNC_END,   1430);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VTOTAL,       750);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VDISP_START,    0);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VDISP_END,    720);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VSYNC_START,  725);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VSYNC_END,    730);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VSGEN_CTL_CONTROL,          1);

    // DMA start
    reg_rdma.WriteReg(REG_RDMA_PARAM_ADDR, bufaddr);
    reg_rdma.WriteReg(REG_RDMA_PARAM_STRIDE, stride);   // stride
    reg_rdma.WriteReg(REG_RDMA_PARAM_WIDTH, 1280);      // width
    reg_rdma.WriteReg(REG_RDMA_PARAM_HEIGHT, 720);      // height
    reg_rdma.WriteReg(REG_RDMA_PARAM_SIZE, 1280*720);   // size
    reg_rdma.WriteReg(REG_RDMA_PARAM_ARLEN, 31);        // awlen
    reg_rdma.WriteReg(REG_RDMA_CTL_CONTROL, 0x03);
}


void vout_stop(MemAccess& reg_rdma, MemAccess& reg_vsgen)
{
    reg_rdma.WriteReg(REG_RDMA_CTL_CONTROL, 0x00);
    while ( reg_rdma.ReadReg(REG_RDMA_CTL_STATUS) != 0 ) {
        usleep(100);
    }

    reg_vsgen.WriteReg(REG_VSGEN_CTL_CONTROL, 0x00);
}


// end of file