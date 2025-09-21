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

void          i2c_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data);
std::uint16_t i2c_read(jelly::I2cAccessor &i2c, std::uint16_t addr);
void          spi_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data);
std::uint16_t spi_read(jelly::I2cAccessor &i2c, std::uint16_t addr);
void          spi_change(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data);
void          reg_dump(jelly::I2cAccessor &i2c, const char *fname);
void          load_setting(jelly::I2cAccessor &i2c);
void          print_status(jelly::UioAccessor& uio, jelly::I2cAccessor& i2c);



#define CAMREG_CORE_ID              0x0000
#define CAMREG_CORE_VERSION         0x0001
#define CAMREG_SENSOR_ENABLE        0x0004
#define CAMREG_SENSOR_READY         0x0008
#define CAMREG_RECV_RESET           0x0010
#define CAMREG_ALIGN_RESET          0x0020
#define CAMREG_ALIGN_PATTERN        0x0022
#define CAMREG_ALIGN_STATUS         0x0028
#define CAMREG_DPHY_CORE_RESET      0x0080
#define CAMREG_DPHY_SYS_RESET       0x0081
#define CAMREG_DPHY_INIT_DONE       0x0088
#define CAMREG_MMCM_CONTROL         0x00a0
#define CAMREG_PLL_CONTROL          0x00a1

#define SYSREG_ID                   0x0000
#define SYSREG_DPHY_SW_RESET        0x0001
#define SYSREG_CAM_ENABLE           0x0002
#define SYSREG_CSI_DATA_TYPE        0x0003
#define SYSREG_DPHY_INIT_DONE       0x0004
#define SYSREG_FPS_COUNT            0x0006
#define SYSREG_FRAME_COUNT          0x0007
#define SYSREG_IMAGE_WIDTH          0x0008
#define SYSREG_IMAGE_HEIGHT         0x0009
#define SYSREG_BLACK_WIDTH          0x000a
#define SYSREG_BLACK_HEIGHT         0x000b

#define TIMGENREG_CORE_ID           0x00
#define TIMGENREG_CORE_VERSION      0x01
#define TIMGENREG_CTL_CONTROL       0x04
#define TIMGENREG_CTL_STATUS        0x05
#define TIMGENREG_CTL_TIMER         0x08
#define TIMGENREG_PARAM_PERIOD      0x10
#define TIMGENREG_PARAM_TRIG0_START 0x20
#define TIMGENREG_PARAM_TRIG0_END   0x21
#define TIMGENREG_PARAM_TRIG0_POL   0x22


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

    // set signal
    signal(SIGINT, signal_handler);

    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    auto reg_sys    = uio_acc.GetAccessor(0x00000000);
    auto reg_timgen = uio_acc.GetAccessor(0x00010000);
    auto reg_fmtr   = uio_acc.GetAccessor(0x00100000);
    auto reg_wdma0  = uio_acc.GetAccessor(0x00210000);
    auto reg_wdma1  = uio_acc.GetAccessor(0x00220000);
    
    // レジスタ確認
    std::cout << "CORE ID" << std::endl;
    std::cout << std::hex << reg_sys.ReadReg(SYSREG_ID) << std::endl;
    std::cout << std::hex << reg_timgen.ReadReg(TIMGENREG_CORE_ID) << std::endl;
    std::cout << std::hex << reg_fmtr.ReadReg(0) << std::endl;
    std::cout << std::hex << reg_wdma0.ReadReg(0) << std::endl;
    std::cout << std::hex << reg_wdma1.ReadReg(0) << std::endl;

    // mmap udmabuf0
    jelly::UdmabufAccessor udmabuf0_acc("udmabuf-jelly-vram0");
    if ( !udmabuf0_acc.IsMapped() ) {
        std::cout << "udmabuf0 mmap error" << std::endl;
        return 1;
    }
    auto dmabuf0_phys_adr = udmabuf0_acc.GetPhysAddr();
    auto dmabuf0_mem_size = udmabuf0_acc.GetSize();
    std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf0_phys_adr << std::endl;
    std::cout << "udmabuf0 size      : " << std::dec << dmabuf0_mem_size << std::endl;

    int rec_frames = dmabuf0_mem_size / (width * height * 2);
    std::cout << "udmabuf0 rec_frames : " << rec_frames << std::endl;


    // mmap udmabuf1
    jelly::UdmabufAccessor udmabuf1_acc("udmabuf-jelly-vram1");
    if ( !udmabuf1_acc.IsMapped() ) {
        std::cout << "udmabuf mmap error" << std::endl;
        return 1;
    }
    auto dmabuf1_phys_adr = udmabuf1_acc.GetPhysAddr();
    auto dmabuf1_mem_size = udmabuf1_acc.GetSize();
    std::cout << "udmabuf1 phys addr : 0x" << std::hex << dmabuf1_phys_adr << std::endl;
    std::cout << "udmabuf1 size      : " << std::dec << dmabuf1_mem_size << std::endl;


    jelly::I2cAccessor i2c;
    i2c.Open("/dev/i2c-6", 0x10);

    // カメラ基板ID確認
    std::cout << "CORE_ID      : " << std::hex << i2c_read(i2c, CAMREG_CORE_ID        ) << std::endl;
    std::cout << "CORE_VERSION : " << std::hex << i2c_read(i2c, CAMREG_CORE_VERSION   ) << std::endl;

    // カメラモジュールリセット
    reg_sys.WriteReg(SYSREG_CAM_ENABLE, 0);
    usleep(1000);
    reg_sys.WriteReg(SYSREG_CAM_ENABLE, 1);
    usleep(1000);

    // MMCM 読み出し
    i2c_write(i2c, CAMREG_MMCM_CONTROL, 1);
    for ( int i = 0; i <= 0x4F; i++ ) {
        auto v = i2c_read(i2c, 0x1000 + i);
//      std::cout << "MMCM[" << i << "] : 0x" << std::hex << v << std::endl;
        printf("MMCM[0x%02x] : 0x%04x\n", i, v);
    }
    i2c_write(i2c, CAMREG_MMCM_CONTROL, 0);
    usleep(1000);


    // 受信側 DPHY リセット
    reg_sys.WriteReg(SYSREG_DPHY_SW_RESET, 1);

    // カメラ基板初期化
    i2c_write(i2c, CAMREG_SENSOR_ENABLE  , 0);  // センサー電源OFF
    i2c_write(i2c, CAMREG_DPHY_CORE_RESET, 1);  // 受信側 DPHY リセット
    i2c_write(i2c, CAMREG_DPHY_SYS_RESET , 1);  // 受信側 DPHY リセット
    usleep(100000);

    // 受信側 DPHY 解除 (必ずこちらを先に解除)
    reg_sys.WriteReg(SYSREG_DPHY_SW_RESET, 0);

    // センサー電源ON
    i2c_write(i2c, CAMREG_SENSOR_ENABLE, 1);     // センサー電源ON
    usleep(500000);

    // センサー基板 DPHY-TX リセット解除
    i2c_write(i2c, CAMREG_DPHY_CORE_RESET, 0);
    i2c_write(i2c, CAMREG_DPHY_SYS_RESET , 0);
    usleep(1000);
    auto dphy_tx_init_done = i2c_read(i2c, CAMREG_DPHY_INIT_DONE);
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

    // 受信画像サイズ設定
    reg_sys.WriteReg(SYSREG_IMAGE_WIDTH,  width);
    reg_sys.WriteReg(SYSREG_IMAGE_HEIGHT, height);
    reg_sys.WriteReg(SYSREG_BLACK_WIDTH,  1280);
    reg_sys.WriteReg(SYSREG_BLACK_HEIGHT, 1);

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

    int roi_x = ((672 -  width) / 2) & ~0x0f; // 16の倍数
    int roi_y = ((512 - height) / 2) & ~0x01; // 2の倍数
    int x_start = roi_x / 8;
    int x_end   = x_start + width/8 - 1 ;
    int y_start = roi_y;
    int y_end   = y_start + height - 1;
    spi_change(i2c, 256, (x_end << 8) | x_start);    // y_end
    spi_change(i2c, 257, y_start);    // y_start
    spi_change(i2c, 258, y_end);      // y_end

    spi_change(i2c, 192, 0x0);  // 動作停止(トレーニングパターン出力状態へ)
    usleep(1000);
    i2c_write(i2c,  CAMREG_RECV_RESET,  1);
    i2c_write(i2c,  CAMREG_ALIGN_RESET, 1);
    usleep(1000);
    i2c_write(i2c,  CAMREG_RECV_RESET,  0);
    usleep(1000);
    i2c_write(i2c,  CAMREG_ALIGN_RESET, 0);
    usleep(1000);
    auto cam_calib_status = i2c_read(i2c,  CAMREG_ALIGN_STATUS);
    if ( cam_calib_status != 0x01 ) {
        std::cout << "!!ERROR!! CAM calibration is not done.  status =" << cam_calib_status << std::endl;
        return 1;
    }

    // 動作開始
    spi_change(i2c, 192, 0x1);

    // Video DMA ドライバ生成
    jelly::VideoDmaControl vdmaw0(reg_wdma0, 2, 2, true);
    jelly::VideoDmaControl vdmaw1(reg_wdma1, 2, 2, true);

    // video input start
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   20000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     1000000);
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
        vdmaw0.Oneshot(dmabuf0_phys_adr, width, height, 1);
        cv::Mat img(height, width, CV_16U);
        udmabuf0_acc.MemCopyTo(img.data, 0, width * height * 2);
        
        // ソフトウェアで並び替えを行う場合の処理
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
            vdmaw0.Oneshot(dmabuf0_phys_adr, width, height, rec_frames);
            
            for ( int i = 0; i < rec_frames; i++ ) {
                // 画像読み込み
                cv::Mat img(height, width, CV_32S);
                udmabuf0_acc.MemCopyTo(img.data, width * height * 4 * i, width * height * 4);
        
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

// カメラ側 の Spartan-7 へ I2C 経由で書き込み
void i2c_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    addr <<= 1;
    addr |= 1;
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    buf[0] = ((addr >> 8) & 0xff);
    buf[1] = ((addr >> 0) & 0xff);
    buf[2] = ((data >> 8) & 0xff);
    buf[3] = ((data >> 0) & 0xff);
    i2c.Write(buf, 4);
}

// カメラ側 の Spartan-7 から I2C 経由で読み込み
std::uint16_t i2c_read(jelly::I2cAccessor &i2c, std::uint16_t addr) {
    addr <<= 1;
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    buf[0] = ((addr >> 8) & 0xff);
    buf[1] = ((addr >> 0) & 0xff);
    i2c.Write(buf, 4);
    i2c.Read(buf, 2);
    return (std::uint16_t)buf[0] | (std::uint16_t)(buf[1] << 8);
}

// PYTHONイメージセンサーの SPI へ I2C 経由で書き込み
void spi_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    addr |= (1 << 14);
    i2c_write(i2c, addr, data);
}


// PYTHONイメージセンサーの SPI から I2C 経由で読み込み
std::uint16_t spi_read(jelly::I2cAccessor &i2c, std::uint16_t addr) {
    addr |= (1 << 14);
    return i2c_read(i2c, addr);
}

// PYTHONイメージセンサーの SPI を 読み出し確認しながら書き換え
void spi_change(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    auto pre = spi_read(i2c, addr);
    spi_write(i2c, addr, data);
    auto post = spi_read(i2c, addr);
    printf("write %3d <= 0x%04x (%04x -> %04x)\n", addr, data, pre, post);
}

// レジスタダンプ
void reg_dump(jelly::I2cAccessor &i2c, const char *fname) {
    FILE* fp = fopen(fname, "w");
    for ( int i = 0; i < 512; i++ ) {
        auto v = spi_read(i2c, i);
        fprintf(fp, "%3d : 0x%04x (%d)\n", i, v, v);
    }
    fclose(fp);
}


// 設定ファイルを読み込む
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
