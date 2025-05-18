#include <iostream>
#include <iomanip>
#include <ios>
#include <cstdint>

#include <opencv2/opencv.hpp>

#include "jelly/UioAccessor.h"
#include "jelly/I2cAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/VideoDmaControl.h"
#include "jelly/JellyRegs.h"

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

#define REGADR_CORE_ID          0x0000
#define REGADR_CORE_VERSION     0x0001
#define REGADR_ISERDES_RESET    0x0010
#define REGADR_ISERDES_BITSLIP  0x0012
#define REGADR_ALIGN_RESET      0x0020
#define REGADR_ALIGN_PATTERN    0x0022
#define REGADR_CALIB_STATUS     0x0028

int main(int argc, char *argv[])
{
    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }
    auto reg_sys   = uio_acc.GetAccessor(0x00000000);
    auto reg_fmtr  = uio_acc.GetAccessor(0x00010000);  // ビデオサイズ正規化
    auto reg_vdmaw = uio_acc.GetAccessor(0x00021000);  // Write-DMA

    std::cout << "CORE ID" << std::endl;
    std::cout << "ID      : " << std::hex << reg_sys.ReadReg(0) << std::endl;
    std::cout << "fmtr    : " << std::hex << reg_fmtr.ReadReg(0) << std::endl;
    std::cout << "vdmaw   : " << std::hex << reg_vdmaw.ReadReg(0) << std::endl;

    // mmap udmabuf
    jelly::UdmabufAccessor udmabuf_acc("udmabuf-jelly-buffer");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf0 : open error or mmap error" << std::endl;
        return 1;
    }

    auto dmabuf_phys_adr = udmabuf_acc.GetPhysAddr();
    auto dmabuf_mem_size = udmabuf_acc.GetSize();
    std::cout << "udmabuf0 phys addr : 0x" << std::hex << dmabuf_phys_adr << std::endl;
    std::cout << "udmabuf0 size      : " << std::dec << dmabuf_mem_size << std::endl;

    jelly::VideoDmaControl vdmaw(reg_vdmaw, 4, 4, true);


    jelly::I2cAccessor i2c;
    i2c.Open("/dev/i2c-0", 0x10);

    std::cout << "ON" << std::endl;

    reg_sys.WriteReg(2, 1);
    usleep(100000);
//  reg_dump(i2c, "reg_start.txt");

//  spi_change(i2c, 17, 0x1234);

    std::cout << "CORE_ID      : " << std::hex << cmd_read(i2c, REGADR_CORE_ID        ) << std::endl;
    std::cout << "CORE_VERSION : " << std::hex << cmd_read(i2c, REGADR_CORE_VERSION   ) << std::endl;

    spi_change(i2c,  8, 0); // soft_reset_pll
    spi_change(i2c,  9, 0); // soft_reset_cgen
    spi_change(i2c, 10, 0); // soft_reset_analog
    spi_change(i2c, 16, 3); // power_down
//  spi_change(i2c, 32, 0x7 | 0x8); // 8bit
    spi_change(i2c, 32, 0x7);
    spi_change(i2c, 34, 0x1);
    spi_change(i2c, 40, 0x7);
    spi_change(i2c, 48, 0x1);
    spi_change(i2c, 64, 0x1);
    spi_change(i2c, 72, 0x2227);
    spi_change(i2c, 112, 0x7);

    spi_change(i2c, 199, 0x255);    // exposure

    //    spi_change(i2c, 129, (1 << 13) | 1); // 8bit mode

//  spi_change(i2c, 192, 0x1);  // 動作開始

    //  spi_change(i2c, 116, 0xa5 << 2); // trainingpattern
//  spi_change(i2c, 116, 0x200); // trainingpattern

//  spi_change(i2c, 116, 0x1);

//    spi_change(i2c, 10, 0x900); // soft_reset_analog
//    spi_change(i2c, 10, 0x000); // soft_reset_analog

    /*
    FILE* fp = fopen("reg_list.txt", "w");
    {
        int i = 41;
        auto v = spi_read(i2c, i);
        fprintf(fp, "%3d : 0x%04x (%d)\n", i, v, v);
    }
    for ( int i = 0; i < 512; i++ ) {
        auto v = spi_read(i2c, i);
        fprintf(fp, "%3d : 0x%04x (%d)\n", i, v, v);
    }
    fclose(fp);
    */

    /*
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    i2c.Write(buf, 4);
    i2c.Read(buf, 2);
    std::cout << "buf[0] : " << std::hex << (int)buf[0] << std::endl;
    std::cout << "buf[1] : " << std::hex << (int)buf[1] << std::endl;
    */

//  spi_change(i2c, 256, (20-1)<<8);  // ROI x_start  x_end
//  spi_change(i2c, 256, (128/2-1)<<8);  // ROI x_start  x_end
//  int pix = 640;
    int pix = 256;
//    spi_change(i2c, 256, (pix/8-1)<<8);  // ROI x_start  x_end
    // 16-1 -> 28  32
    // 20-1 -> 36  40
    // 32-1 -> 60  64


    int width  = 128;
    int height = 128;

    usleep(1000);
    reg_sys.WriteReg(1, 1); // sw rst
    usleep(1000);
    reg_sys.WriteReg(1, 0);

    {
        printf("calib\n");
        spi_change(i2c, 192, 0x0);  // 動作停止
        usleep(10000);
        cmd_write(i2c,  REGADR_ISERDES_RESET, 1);
        cmd_write(i2c,  REGADR_ALIGN_RESET  , 1);
        usleep(10000);
        cmd_write(i2c,  REGADR_ISERDES_RESET, 0);
        usleep(10000);
        cmd_write(i2c,  REGADR_ALIGN_RESET  , 0);
        usleep(10000);
        std::cout << "REGADR_CALIB_STATUS : " << cmd_read(i2c,  REGADR_CALIB_STATUS) << std::endl;
    }
    {
        printf("run\n");
        spi_change(i2c, 192, 0x1);  // 動作開始
    }


//  usleep(10000000);
    while (1) {
        printf("$ ");
        int c = getchar();
        if ( c == 'q' ) {
            break;
        } else if ( c == 'b' ) {
            printf("bitslip\n");
            cmd_write(i2c, 0x0012, 0x1f);
        }
        else if ( c == 'r' ) {
            printf("run\n");
            spi_change(i2c, 192, 0x1);  // 動作開始
        }
        else if ( c == 't' ) {
            printf("training\n");
            spi_change(i2c, 192, 0x0);  // 動作停止
        }
        else if ( c == 'c' ) {
            printf("calib\n");
            spi_change(i2c, 192, 0x0);  // 動作停止
            usleep(10000);
            cmd_write(i2c,  REGADR_ISERDES_RESET, 1);
            cmd_write(i2c,  REGADR_ALIGN_RESET  , 1);
            usleep(10000);
            cmd_write(i2c,  REGADR_ISERDES_RESET, 0);
            usleep(10000);
            cmd_write(i2c,  REGADR_ALIGN_RESET  , 0);
            usleep(10000);
            std::cout << "REGADR_CALIB_STATUS : " << cmd_read(i2c,  REGADR_CALIB_STATUS) << std::endl;
        }
        else if ( c == 'p' ) {
            printf("test pattern\n");
            spi_change(i2c, 144, 0x3 + 0x8);  // testパターン
        }
        else if ( c == 'd' ) {
            printf("dump\n");
            /*
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_ADDR,       dmabuf_phys_adr);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_OFFSET,     0);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_LINE_STEP,  width*4);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_H_SIZE,     width-1);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_V_SIZE,     height-1);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_F_SIZE,     1-1);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_FRAME_STEP, height*width*4);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_PARAM_AWLEN_MAX,  31);
            reg_vdmaw.WriteReg(REG_VDMA_WRITE_CTL_CONTROL,      0x03 | 0x08);
            */

            // normalizer start
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,  100000000);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,      width);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,     height);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,       0x000);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,    0x100000);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,      0x03);
            usleep(100000);

            vdmaw.Oneshot(dmabuf_phys_adr, width, height, 1);
            usleep(100000);
            cv::Mat img(height, width, CV_32S);
            udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4);
            cv::Mat img_u16;
            img.convertTo(img_u16, CV_16U, 65535.0/1023.0);
            cv::imwrite("img.png", img_u16);

            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,      0x00);
        }
        else if ( c == 'v' ) {
            // normalizer start
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,  100000000);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,      width);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,     height);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,       0x000);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,    0x100000);
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,      0x03);
            usleep(100000);

            while ( cv::waitKey(10) <= 0 ) {
                vdmaw.Oneshot(dmabuf_phys_adr, width, height, 1);
                usleep(100000);
                cv::Mat img(height, width, CV_32S);
                udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4);
                cv::Mat img_u16;
                img.convertTo(img_u16, CV_16U, 65535.0/1023.0);
                // 最大値に合わせて正規化
                cv::normalize(img_u16, img_u16, 0, 65535, cv::NORM_MINMAX);
                cv::imshow("img", img_u16);
            }
            reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,      0x00);
        }
    }
    reg_dump(i2c, "reg_end.log");


    std::cout << "OFF" << std::endl;
    reg_sys.WriteReg(2, 0);

    return 0;
}

// end of file
