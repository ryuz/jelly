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
#include "jelly/I2cAccessor.h"
#include "jelly/Imx219Control.h"
#include "jelly/GpioAccessor.h"
#include "jelly/VideoDmaControl.h"

void write_pgm(const char* filename, cv::Mat img, int depth=4095);

static  volatile    bool    g_signal = false;
void signal_handler(int signo) {
    g_signal = true;
}

void          cmd_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data);
std::uint16_t cmd_read(jelly::I2cAccessor &i2c, std::uint16_t addr);
void          spi_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data);
std::uint16_t spi_read(jelly::I2cAccessor &i2c, std::uint16_t addr);
void          spi_change(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data);
void          reg_dump(jelly::I2cAccessor &i2c, const char *fname);
void          load_setting(jelly::I2cAccessor &i2c);
void          print_status(jelly::UioAccessor& uio, jelly::I2cAccessor& i2c);



#define CAMREG_CORE_ID          0x0000
#define CAMREG_CORE_VERSION     0x0001
#define CAMREG_RECV_RESET       0x0010
#define CAMREG_ALIGN_RESET      0x0020
#define CAMREG_ALIGN_PATTERN    0x0022
#define CAMREG_ALIGN_STATUS     0x0028
#define CAMREG_DPHY_CORE_RESET  0x0080
#define CAMREG_DPHY_SYS_RESET   0x0081
#define CAMREG_DPHY_INIT_DONE   0x0088

#define SYSREG_ID               0x0000
#define SYSREG_DPHY_SW_RESET    0x0001
#define SYSREG_CAM_ENABLE       0x0002
#define SYSREG_CSI_DATA_TYPE    0x0003
#define SYSREG_DPHY_INIT_DONE   0x0004
#define SYSREG_FPS_COUNT        0x0006
#define SYSREG_FRAME_COUNT      0x0007
#define SYSREG_IMAGE_WIDTH      0x0008
#define SYSREG_IMAGE_HEIGHT     0x0009
#define SYSREG_BLACK_WIDTH      0x000a
#define SYSREG_BLACK_HEIGHT     0x000b

#define TIMGENREG_CORE_ID               0x00
#define TIMGENREG_CORE_VERSION          0x01
#define TIMGENREG_CTL_CONTROL           0x04
#define TIMGENREG_CTL_STATUS            0x05
#define TIMGENREG_CTL_TIMER             0x08
#define TIMGENREG_PARAM_PERIOD          0x10
#define TIMGENREG_PARAM_TRIG0_START     0x20
#define TIMGENREG_PARAM_TRIG0_END       0x21
#define TIMGENREG_PARAM_TRIG0_POL       0x22


int main(int argc, char *argv[])
{
    int width  = 256 ;
    int height = 256 ;

    for ( int i = 1; i < argc; ++i ) {
        if ( strcmp(argv[i], "-width") == 0 && i+1 < argc) {
            ++i;
            width = strtol(argv[i], nullptr, 0);
        }
        else if ( strcmp(argv[i], "-height") == 0 && i+1 < argc) {
            ++i;
            height = strtol(argv[i], nullptr, 0);
        }
        else {
            std::cout << "unknown option : " << argv[i] << std::endl;
            return 1;
        }
    }

    width &= ~0xf;
    width  = std::max(width, 16);
    height = std::max(height, 1);


    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    auto reg_sys    = uio_acc.GetAccessor(0x00000000);
    auto reg_timgen = uio_acc.GetAccessor(0x00010000);
    auto reg_fmtr   = uio_acc.GetAccessor(0x00100000);
    auto reg_wdma   = uio_acc.GetAccessor(0x00210000);
    
#if 1
    std::cout << "CORE ID" << std::endl;
    std::cout << std::hex << reg_sys.ReadReg(SYSREG_ID) << std::endl;
    std::cout << std::hex << reg_timgen.ReadReg(TIMGENREG_CORE_ID) << std::endl;
    std::cout << std::hex << reg_fmtr.ReadReg(0) << std::endl;
//  std::cout << std::hex << reg_demos.ReadReg(0) << std::endl;
//  std::cout << std::hex << reg_colmat.ReadReg(0) << std::endl;
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
    std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
    std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;

    int rec_frames = dmabuf_mem_size / (width * height * 4);
    std::cout << "udmabuf0 rec_frames : " << rec_frames << std::endl;

    jelly::I2cAccessor i2c;
    i2c.Open("/dev/i2c-6", 0x10);

    // カメラ基板ID確認
    std::cout << "CORE_ID      : " << std::hex << cmd_read(i2c, CAMREG_CORE_ID        ) << std::endl;
    std::cout << "CORE_VERSION : " << std::hex << cmd_read(i2c, CAMREG_CORE_VERSION   ) << std::endl;


    // 受信側 DPHY リセット
    reg_sys.WriteReg(SYSREG_DPHY_SW_RESET, 1);

    // カメラ基板初期化
    reg_sys.WriteReg(SYSREG_CAM_ENABLE, 0);     // センサー電源OFF
    cmd_write(i2c, CAMREG_DPHY_CORE_RESET, 1);  // 受信側 DPHY リセット
    cmd_write(i2c, CAMREG_DPHY_SYS_RESET , 1);  // 受信側 DPHY リセット
    usleep(100000);

//  std::cout << "Press Enter to continue..." << std::endl;
//  getchar(); // wait for user input

    // 受信側 DPHY 解除 (必ずこちらを先に解除)
    reg_sys.WriteReg(SYSREG_DPHY_SW_RESET, 0);

    // センサー電源ON
    reg_sys.WriteReg(SYSREG_CAM_ENABLE, 1);
    usleep(500000);

    // センサー基板 DPHY-TX リセット解除
    cmd_write(i2c, CAMREG_DPHY_CORE_RESET, 0);
    cmd_write(i2c, CAMREG_DPHY_SYS_RESET , 0);
    usleep(1000);
    auto dphy_tx_init_done = cmd_read(i2c, CAMREG_DPHY_INIT_DONE);
    if ( dphy_tx_init_done == 0 ) {
        std::cout << "!!ERROR!! CAM DPHY TX init_done = 0" << std::endl;
        return 1;
    }

    // ここで RX 側も init_done が来る
    auto dphy_rx_init_done = reg_sys.ReadReg(SYSREG_DPHY_INIT_DONE);
    if ( dphy_rx_init_done == 0 ) {
        std::cout << "!!ERROR!! KV260 DPHY RX init_done = 0" << std::endl;
        return 1;
    }

//    usleep(10000);
//    std::cout << "SYSREG_DPHY_INIT_DONE : " << reg_sys.ReadReg(SYSREG_DPHY_INIT_DONE) << std::endl;


//  int internal_w = 240;//420;
//  int internal_w = 416;
//  int width  = internal_w ;
//  int height = 160; // 416        ;
    reg_sys.WriteReg(SYSREG_IMAGE_WIDTH,  width);
    reg_sys.WriteReg(SYSREG_IMAGE_HEIGHT, height);


//    cmd_write(i2c, CAMREG_TRIM_X_START ,     0);
//    cmd_write(i2c, CAMREG_TRIM_X_END   , internal_w-1);   //   = 11'd255                  ,
////  cmd_write(i2c, CAMREG_CSI_DATA_TYPE,  0x2b); 
//    cmd_write(i2c, CAMREG_CSI_WC       , internal_w*5/4); //    = 16'(256*5/4)             ,

    // 8番地(soft_reset_pll)
    // 9番地(soft_reset_cgen)
    // 10番地(soft_reset_analog)
    // 16番地(power_down)
    // 32番地(config0)

    // センサー起動    
    spi_change(i2c, 16, 0x0003);    // power_down  0:pwd_n, 1:PLL enable, 2: PLL Bypass
    spi_change(i2c, 32, 0x0007);    // config0 (10bit mode) 0: enable_analog, 1: enabale_log, 2: select PLL
    spi_change(i2c,  8, 0x0000);    // pll_soft_reset, pll_lock_soft_reset
    spi_change(i2c,  9, 0x0000);    // cgen_soft_reset
    spi_change(i2c, 34, 0x1);       // config0 Logic General Enable Configuration
    spi_change(i2c, 40, 0x7);       // image_core_config0 
    spi_change(i2c, 48, 0x1);       // AFE Power down for AFE’s
    spi_change(i2c, 64, 0x1);       // Bias Bias Power Down Configuration
    spi_change(i2c, 72, 0x2227);    // Charge Pump
    spi_change(i2c, 112, 0x7);      // Serializers/LVDS/IO 
    spi_change(i2c, 10, 0x0000);    // soft_reset_analog

    //  spi_change(i2c, 199, 0x255*16*8);    // exposure

    //  spi_change(i2c, 256, ((640+32)/2-1)<<8);  // ROI x_start  x_end
//  spi_change(i2c, 256, (20-1)<<8);  // ROI x_start  x_end
//  spi_change(i2c, 256, (128/2-1)<<8);  // ROI x_start  x_end
//  int pix = 640;
    int pix = 256;

    int roi_x = ((672 -  width) / 2) & ~0x0f; // 16の倍数
    int roi_y = ((512 - height) / 2) & ~0x01; // 2の倍数

    int x_start = roi_x / 8;
    int x_end   = x_start + width/8 - 1 ;
    int y_start = roi_y;
    int y_end   = y_start + height - 1;
    spi_change(i2c, 256, (x_end << 8) | x_start);    // y_end
    spi_change(i2c, 257, y_start);    // y_start
    spi_change(i2c, 258, y_end);      // y_end

//  spi_change(i2c, 129, 0x0000);    // auto_blackcal_enable : OFF

    spi_change(i2c, 192, 0x0);  // 動作停止(トレーニングパターン出力状態へ)
    usleep(1000);
    cmd_write(i2c,  CAMREG_RECV_RESET,  1);
    cmd_write(i2c,  CAMREG_ALIGN_RESET, 1);
    usleep(1000);
    cmd_write(i2c,  CAMREG_RECV_RESET,  0);
    usleep(1000);
    cmd_write(i2c,  CAMREG_ALIGN_RESET, 0);
    usleep(1000);
    auto cam_calib_status = cmd_read(i2c,  CAMREG_ALIGN_STATUS);
    if ( cam_calib_status != 0x01 ) {
        std::cout << "!!ERROR!! CAM calibration is not done.  status =" << cam_calib_status << std::endl;
        return 1;
    }

    // 動作開始
    spi_change(i2c, 192, 0x1);


//  jelly::VideoDmaControl vdmaw(reg_wdma, 4, 4, true);
    jelly::VideoDmaControl vdmaw(reg_wdma, 2, 2, true);

    // video input start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);

    int black_level = 0;
    int soft_gain   = 10;
    int timgen_period = 99999;
    int trig0_start   = 10;
    int trig0_end     = 90000;

    cv::imshow("img", cv::Mat::zeros(480, 640, CV_8UC3));
    cv::createTrackbar("bl",   "img", nullptr, 1024);
    cv::setTrackbarPos("bl",   "img", black_level);
    cv::createTrackbar("sg",   "img", nullptr, 100);
    cv::setTrackbarPos("sg",   "img", soft_gain);

    cv::createTrackbar("peri", "img", nullptr, 100000);
    cv::setTrackbarPos("peri", "img", timgen_period);
    cv::createTrackbar("ts",   "img", nullptr,  99999);
    cv::setTrackbarPos("ts",   "img", trig0_start);
    cv::createTrackbar("te",   "img", nullptr,  99999);
    cv::setTrackbarPos("te",   "img", trig0_end);

//  vdmaw.SetBufferAddr(dmabuf_phys_adr);
//  vdmaw.SetImageSize(width, height);
//  vdmaw.Start();

    int     swap = 0;
    int     key;
    while ( (key = (cv::waitKey(10) & 0xff)) != 0x1b ) {
        if ( g_signal ) { break; }

        black_level  = cv::getTrackbarPos("bl", "img");
        soft_gain    = cv::getTrackbarPos("sg", "img");
        timgen_period = cv::getTrackbarPos("peri", "img");
        trig0_start  = cv::getTrackbarPos("ts", "img");
        trig0_end    = cv::getTrackbarPos("te", "img");

        reg_timgen.WriteReg(TIMGENREG_PARAM_PERIOD,      timgen_period);
        reg_timgen.WriteReg(TIMGENREG_PARAM_TRIG0_START, trig0_start);
        reg_timgen.WriteReg(TIMGENREG_PARAM_TRIG0_END,   trig0_end);

        // 画像読み込み
        vdmaw.Oneshot(dmabuf_phys_adr, width, height, 1);
//      cv::Mat img(height, width, CV_32S);
//      udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4);
        cv::Mat img(height, width, CV_16U);
        udmabuf_acc.MemCopyTo(img.data, 0, width * height * 2);
        
        // 並び替えを行う
        cv::Mat img_u16(height, width, CV_16U);
        for ( int y = 0; y < height; y++ ) {
            for ( int x = 0; x < width; x++ ) {
                int xx = x;
                xx = (xx & 0x8) ? (xx ^ 0x7) : xx;
                xx = ((xx & 0xfff8) | ((xx & 0x6) >> 1) | ((xx & 0x1) << 2));
                if ( !swap ) { xx = x; }
                img_u16.at<std::uint16_t>(y, x) = img.at<std::int16_t>(y, xx);
            }
        }
        
        // img_u16 の黒レベル補正
        for ( int y = 0; y < height; y++ ) {
            for ( int x = 0; x < width; x++ ) {
                int val = img_u16.at<std::uint16_t>(y, x);
                if ( val < black_level ) {
                    val = 0;
                } else {
                    val -= black_level;
                }
                val = val * soft_gain / 10;
                if ( val > 1023 ) {
                    val = 1023;
                }
                img_u16.at<std::uint16_t>(y, x) = val;
            }
        }

        // 表示
        cv::imshow("img", img_u16 * (65535.0/1023.0));


        // トラックバー値取得
//      view_scale  = cv::getTrackbarPos("scale",    "img");

//      reg_sys.WriteReg(4, fmtsel);

#if 0
        // キャプチャ
        vdmaw.Oneshot(dmabuf_phys_adr, width, height, 1);

        if ( 1 ) {
            cv::Mat img_raw = cv::Mat(height, width, CV_8UC4);
            udmabuf_acc.MemCopyTo(img_raw.data, 0, width * height * 4);
            std::vector<cv::Mat> planes;
            cv::split(img_raw, planes);
            cv::imshow("plane0", planes[0]);
            cv::imshow("plane1", planes[1]);
            cv::imshow("plane2", planes[2]);
            cv::imshow("plane3", planes[3]);
        }
#endif

        // 表示
//        view_scale = std::max(1, view_scale);
//        cv::Mat view_img;
//        cv::resize(img, view_img, cv::Size(), 1.0/view_scale, 1.0/view_scale);
//        cv::imshow("img", view_img);

        // ユーザー操作
        switch ( key ) {
        case 'p':
            {
                std::cout << "SYSREG_ID           : 0x" << std::hex << reg_sys.ReadReg(SYSREG_ID)  << std::endl;
                std::cout << "SYSREG_IMAGE_WIDTH  : " << std::dec << reg_sys.ReadReg(SYSREG_IMAGE_WIDTH)  << std::endl;
                std::cout << "SYSREG_IMAGE_HEIGHT : " << std::dec << reg_sys.ReadReg(SYSREG_IMAGE_HEIGHT) << std::endl;
                int fps_count   = reg_sys.ReadReg(SYSREG_FPS_COUNT);
                int frame_count = reg_sys.ReadReg(SYSREG_FRAME_COUNT);
                std::cout << "SYSREG_FPS_COUNT   : " << std::dec << fps_count << std::endl;
                std::cout << "SYSREG_FRAME_COUNT : " << std::dec << frame_count << std::endl;
                std::cout << "fps = " << 250000000.0 / (double)fps_count << " [fps]" << std::endl;
            }
            break;
        
        case 'l':
            printf("load setting\n");
            load_setting(i2c);
            break;
            
        case 'd':   // image dump
            cv::imwrite("img_dump.png", img);
            break;

        case 'r':   // record
            // 画像読み込み
            vdmaw.Oneshot(dmabuf_phys_adr, width, height, rec_frames);
            
            for ( int i = 0; i < rec_frames; i++ ) {
                // 画像読み込み
                cv::Mat img(height, width, CV_32S);
                udmabuf_acc.MemCopyTo(img.data, width * height * 4 * i, width * height * 4);
        
                // 並び替えを行う
                cv::Mat img_u16(height, width, CV_16U);
                for ( int y = 0; y < height; y++ ) {
                    for ( int x = 0; x < width; x++ ) {
                        int xx = x;
                        xx = (xx & 0x8) ? (xx ^ 0x7) : xx;
                        xx = ((xx & 0xfff8) | ((xx & 0x6) >> 1) | ((xx & 0x1) << 2));
                        if ( !swap ) { xx = x; }
                        img_u16.at<std::uint16_t>(y, x) = img.at<std::int32_t>(y, xx);
                    }
                }

                // 保存
                char fname[256];
                sprintf(fname, "rec/img_%03d.png", i);
                cv::imwrite(fname, img_u16 * (65535.0/1023.0));
            }
        }
    }

    std::cout << "close device" << std::endl;

    // カメラOFF
    reg_sys.WriteReg(2, 0);
    usleep(100000);

    return 0;
}


/*
void print_status(jelly::UioAccessor& uio, jelly::I2cAccessor& i2c) {
    usleep(1000);
    std::cout << "=========================================\n"
              << "cam CAMREG_ISERDES_RESET   : " << cmd_read(i2c, CAMREG_ISERDES_RESET)   << "\n"
              << "cam CAMREG_ALIGN_RESET     : " << cmd_read(i2c, CAMREG_ALIGN_RESET  )   << "\n"
              << "cam CAMREG_DPHY_SYS_RESET  : " << cmd_read(i2c, CAMREG_DPHY_SYS_RESET)  << "\n"
              << "cam CAMREG_DPHY_CORE_RESET : " << cmd_read(i2c, CAMREG_DPHY_CORE_RESET) << "\n"
              << "z7  SYSREG_DPHY_SW_RESET   : " << uio.ReadReg(SYSREG_DPHY_SW_RESET)     << "\n"
              << "cam TX DPHY init_done : " << cmd_read(i2c, CAMREG_DPHY_INIT_DONE)    << "\n"
              << "z7  RX DPHY init_done : " << uio.ReadReg(SYSREG_DPHY_INIT_DONE)      << std::endl;
}
*/

void cmd_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    addr <<= 1;
    addr |= 1;
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    buf[0] = ((addr >> 8) & 0xff);
    buf[1] = ((addr >> 0) & 0xff);
    buf[2] = ((data >> 8) & 0xff);
    buf[3] = ((data >> 0) & 0xff);
    i2c.Write(buf, 4);
}

std::uint16_t cmd_read(jelly::I2cAccessor &i2c, std::uint16_t addr) {
    addr <<= 1;
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    buf[0] = ((addr >> 8) & 0xff);
    buf[1] = ((addr >> 0) & 0xff);
    i2c.Write(buf, 4);
    i2c.Read(buf, 2);
    return (std::uint16_t)buf[0] | (std::uint16_t)(buf[1] << 8);
}

void spi_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    addr |= (1 << 14);
    cmd_write(i2c, addr, data);
}

std::uint16_t spi_read(jelly::I2cAccessor &i2c, std::uint16_t addr) {
    addr |= (1 << 14);
    return cmd_read(i2c, addr);
}

void spi_change(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    auto pre = spi_read(i2c, addr);
    spi_write(i2c, addr, data);
    auto post = spi_read(i2c, addr);
    printf("write %3d <= 0x%04x (%04x -> %04x)\n", addr, data, pre, post);
}


void reg_dump(jelly::I2cAccessor &i2c, const char *fname) {
    FILE* fp = fopen(fname, "w");
    for ( int i = 0; i < 512; i++ ) {
        auto v = spi_read(i2c, i);
        fprintf(fp, "%3d : 0x%04x (%d)\n", i, v, v);
    }
    fclose(fp);
}

void load_setting(jelly::I2cAccessor &i2c) {
    FILE* fp = fopen("reg_list.txt", "r");
    if ( fp == nullptr ) {
        std::cout << "reg_list.txt open error" << std::endl;
        return;
    }
    char line[256];
    while (fgets(line, sizeof(line), fp)) {
        char *p = line;
        // skip leading whitespace
        while (*p == ' ' || *p == '\t') ++p;
        if (*p == '\0' || *p == '#') continue; // skip empty/comment
        unsigned int addr, data;
        int n = sscanf(p, "%i %i", &addr, &data);
        if (n == 2) {
            spi_change(i2c, (std::uint16_t)addr, (std::uint16_t)data);
        } else {
            std::cout << "parse error: " << line;
        }
    }
    fclose(fp);
}



// end of file
