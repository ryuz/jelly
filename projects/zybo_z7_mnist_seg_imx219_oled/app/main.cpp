
#include <iostream>
#include <opencv2/opencv.hpp>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/Imx219Control.h"

#include "Ssd1331Control.h"


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

// MNIST color
#define REG_MCOL_PARAM_MODE         0x00
#define REG_MCOL_PARAM_TH           0x01

// Binarizer
#define REG_BIN_PARAM_END           0x04
#define REG_BIN_PARAM_INV           0x05
#define REG_BIN_TBL(x)              (0x40 +(x))

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


// parameter define
const int cam_width  = 640;
const int cam_height = 132;
const int dvi_width  = 1280;
const int dvi_height = 720;
const int buf_stride = 2048*4;

// private functions
void    CaptureStart(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_norm, std::uintptr_t bufaddr);
void    CaptureStop(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_norm);
void    VoutStart(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen, std::uintptr_t bufaddr);
void    VoutStop(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen);
void    WriteImage(jelly::MemAccessor& mem_acc, const cv::Mat& img);
cv::Mat ReadImage(jelly::MemAccessor& mem_acc);


// main
int main()
{
    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf0");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf0 mmap error" << std::endl;
        return 1;
    }
    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
    std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
    std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;


    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }
    auto reg_gid    = uio_acc.GetAccessor(0x00000000);
    auto reg_wdma   = uio_acc.GetAccessor(0x00010000);
    auto reg_norm   = uio_acc.GetAccessor(0x00011000);
    auto reg_rgb    = uio_acc.GetAccessor(0x00012000);
    auto reg_resize = uio_acc.GetAccessor(0x00014000);
    auto reg_mnist  = uio_acc.GetAccessor(0x00015000);
    auto reg_bin    = uio_acc.GetAccessor(0x00018000);
    auto reg_mcol   = uio_acc.GetAccessor(0x00019000);
    auto reg_oled   = uio_acc.GetAccessor(0x00022000);
    auto reg_rdma   = uio_acc.GetAccessor(0x00020000);
    auto reg_vsgen  = uio_acc.GetAccessor(0x00021000);

//  std::cout << "reg_gid  : " << std::hex << reg_gid.ReadReg(0) << std::endl;
//  std::cout << "reg_wdma : " << std::hex << reg_wdma.ReadReg(0) << std::endl;
//  std::cout << "reg_rdma : " << std::hex << reg_rdma.ReadReg(0) << std::endl;

    // IMX219 I2C control
    jelly::Imx219ControlI2c imx219;
    if ( !imx219.Open("/dev/i2c-0", 0x10) ) {
        std::cout << "I2C open error" << std::endl;
        return 1;
    }

    // camera 設定
    imx219.SetPixelClock(139200000);
    imx219.SetAoi(640, 132, (3280/2 - 640)/2, (2464/2 - 132)/2, true, true);
    imx219.Start();

    // OLED初期化
    Ssd1331Control oled(reg_oled);
    oled.Setup();

    // color map
    /*
    reg_mcol.WriteReg(0x040/4, 0x0000000);  // 黒
    reg_mcol.WriteReg(0x044/4, 0x0000080);  // 茶
    reg_mcol.WriteReg(0x048/4, 0x00000ff);  // 赤
    reg_mcol.WriteReg(0x04c/4, 0x04cb7ff);  // 橙
    reg_mcol.WriteReg(0x050/4, 0x000ffff);  // 黄
    reg_mcol.WriteReg(0x054/4, 0x0008000);  // 緑
    reg_mcol.WriteReg(0x058/4, 0x0ff0000);  // 青
    reg_mcol.WriteReg(0x05c/4, 0x0800080);  // 紫
    reg_mcol.WriteReg(0x060/4, 0x0808080);  // 灰
    reg_mcol.WriteReg(0x064/4, 0x0ffffff);  // 白
    */

    // UI
    int bin_th      = 127;   // 2値化閾値
    int col_mode    = 2;     // 色付けモード
    int col_th      = 0;     // 色付け閾値
    int a_gain      = 20;
    int d_gain      = 10;
    int bayer_phase = 1;
    
    // 開始
    CaptureStart(reg_wdma, reg_norm, dmabuf_phys_adr);
    VoutStart(reg_rdma, reg_vsgen, dmabuf_phys_adr);
    
    int     key;
    while ( (key = (cv::waitKeyEx(10) & 0xff)) != 0x1b ) {
        auto img = ReadImage(udmabuf_acc);
        cv::imshow("img", img);
        cv::createTrackbar("bin_th",   "img", &bin_th,   255);
        cv::createTrackbar("col_mode", "img", &col_mode,  15);
        cv::createTrackbar("col_th",   "img", &col_th,    15);
        cv::createTrackbar("a_gain",   "img", &a_gain, 20);
        cv::createTrackbar("d_gain",   "img", &d_gain, 24);
        cv::createTrackbar("bayer" ,   "img", &bayer_phase, 3);

        // パラメータ設定
        reg_mcol.WriteReg(REG_MCOL_PARAM_MODE, col_mode);
        reg_mcol.WriteReg(REG_MCOL_PARAM_TH, col_th);
        
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
            reg_bin.WriteReg(REG_BIN_PARAM_END, 14);      // MNIST_MOD_REG_PARAM_END
        }
        else {
            // 単純2値化(テーブルサイズ=1)
            reg_bin.WriteReg(0x000100/4, bin_th);
            reg_bin.WriteReg(REG_BIN_PARAM_END, 0);       // MNIST_MOD_REG_PARAM_END
        }
        
        // set camera
        imx219.SetGain(a_gain);
        imx219.SetDigitalGain(d_gain);
        reg_rgb.WriteReg(REG_RAW2RGB_DEMOSAIC_PHASE, bayer_phase);

        // ユーザー操作
        switch ( key ) {
        case 'h':  imx219.SetFlip(imx219.GetFlipH(), !imx219.GetFlipV()); break;
        case 'v':  imx219.SetFlip(!imx219.GetFlipH(), imx219.GetFlipV()); break;
        case 'w':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() - 4);    break;
        case 'z':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() + 4);    break;
        case 'a':  imx219.SetAoiPosition(imx219.GetAoiX() - 4, imx219.GetAoiY());    break;
        case 's':  imx219.SetAoiPosition(imx219.GetAoiX() + 4, imx219.GetAoiY());    break;
        }
    }

    CaptureStop(reg_wdma, reg_norm);
    VoutStop(reg_rdma, reg_vsgen);
    oled.Stop();
    imx219.Stop();
    
    return 0;
}


// udmabuf領域へ画像を書き込む
void WriteImage(jelly::MemAccessor& mem_acc, const cv::Mat& img)
{
    // ストライド幅に合わせて1ラインずつ転送
    for ( int i = 0; i < img.rows; i++ )
    {
        mem_acc.MemCopyFrom(i*buf_stride, img.data + img.step*i, img.cols*4);
    }
}

// udmabuf領域から画像を読み出す
cv::Mat ReadImage(jelly::MemAccessor& mem_acc)
{
    int x = (dvi_width  - cam_width) / 2;
    int y = (dvi_height - cam_height) / 2;

    cv::Mat img(cam_height, cam_width, CV_8UC4);
    for ( int i = 0; i < img.rows; i++ )
    {
        mem_acc.MemCopyTo(img.data + i*img.step, (y+i)*buf_stride + x*4, img.cols*4);
    }
    return img;
}

// カメラキャプチャ開始
void CaptureStart(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_norm, std::uintptr_t bufaddr)
{
    int x = (dvi_width  - cam_width) / 2;
    int y = (dvi_height - cam_height) / 2;

    // DMA start
    reg_wdma.WriteReg(REG_WDMA_PARAM_ADDR, bufaddr + y*buf_stride + x*4);
    reg_wdma.WriteReg(REG_WDMA_PARAM_STRIDE, buf_stride);               // stride
    reg_wdma.WriteReg(REG_WDMA_PARAM_WIDTH, cam_width);                 // width
    reg_wdma.WriteReg(REG_WDMA_PARAM_HEIGHT, cam_height);               // height
    reg_wdma.WriteReg(REG_WDMA_PARAM_SIZE, cam_width*cam_height);       // size
    reg_wdma.WriteReg(REG_WDMA_PARAM_AWLEN, 7);                         // awlen
    reg_wdma.WriteReg(REG_WDMA_CTL_CONTROL, 0x03);

    // normalizer start
    reg_norm.WriteReg(REG_NORM_FRM_TIMER_EN, 1);
    reg_norm.WriteReg(REG_NORM_FRM_TIMEOUT, 100000000);
    reg_norm.WriteReg(REG_NORM_PARAM_WIDTH, cam_width);
    reg_norm.WriteReg(REG_NORM_PARAM_HEIGHT, cam_height);
    reg_norm.WriteReg(REG_NORM_PARAM_FILL, 0x0ff);
    reg_norm.WriteReg(REG_NORM_PARAM_TIMEOUT, 0x100000);
    reg_norm.WriteReg(REG_NORM_CONTROL, 0x03);
}

// カメラキャプチャ停止
void CaptureStop(jelly::MemAccessor& reg_wdma, jelly::MemAccessor& reg_norm)
{
    reg_wdma.WriteReg(REG_WDMA_CTL_CONTROL, 0x00);
    while ( reg_wdma.ReadReg(REG_WDMA_CTL_STATUS) != 0 ) {
        usleep(100);
    }

    reg_norm.WriteReg(REG_NORM_CONTROL, 0x00);
}

// DVI出力開始
void VoutStart(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen, std::uintptr_t bufaddr)
{
    // VSync Start
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HTOTAL,      1650);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HDISP_START,    0);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HDISP_END,   dvi_width);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HSYNC_START, 1390);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HSYNC_END,   1430);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_HSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VTOTAL,       750);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VDISP_START,    0);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VDISP_END,    dvi_height);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VSYNC_START,  725);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VSYNC_END,    730);
    reg_vsgen.WriteReg(REG_VSGEN_PARAM_VSYNC_POL,      1);
    reg_vsgen.WriteReg(REG_VSGEN_CTL_CONTROL,          1);

    // DMA start
    reg_rdma.WriteReg(REG_RDMA_PARAM_ADDR, bufaddr);
    reg_rdma.WriteReg(REG_RDMA_PARAM_STRIDE, buf_stride);
    reg_rdma.WriteReg(REG_RDMA_PARAM_WIDTH, dvi_width);
    reg_rdma.WriteReg(REG_RDMA_PARAM_HEIGHT, dvi_height);
    reg_rdma.WriteReg(REG_RDMA_PARAM_SIZE, dvi_width*dvi_height);
    reg_rdma.WriteReg(REG_RDMA_PARAM_ARLEN, 31);
    reg_rdma.WriteReg(REG_RDMA_CTL_CONTROL, 0x03);
}


// DVI出力停止
void VoutStop(jelly::MemAccessor& reg_rdma, jelly::MemAccessor& reg_vsgen)
{
    reg_rdma.WriteReg(REG_RDMA_CTL_CONTROL, 0x00);
    while ( reg_rdma.ReadReg(REG_RDMA_CTL_STATUS) != 0 ) {
        usleep(100);
    }

    reg_vsgen.WriteReg(REG_VSGEN_CTL_CONTROL, 0x00);
}


// end of file
