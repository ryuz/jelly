#include <iostream>
#include <iomanip>
#include <ios>
#include <cstdint>

// #include <opencv2/opencv.hpp>

#include "jelly/UioAccessor.h"
#include "jelly/I2cAccessor.h"
//#include "jelly/UdmabufAccessor.h"
//#include "jelly/JellyRegs.h"

void spi_write(jelly::I2cAccessor &i2c, std::uint16_t addr, std::uint16_t data) {
    addr |= (1 << 14);
    addr <<= 1;
    addr |= 1;
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    buf[0] = ((addr >> 8) & 0xff);
    buf[1] = ((addr >> 0) & 0xff);
    buf[2] = ((data >> 8) & 0xff);
    buf[3] = ((data >> 0) & 0xff);
    i2c.Write(buf, 4);
}

std::uint16_t spi_read(jelly::I2cAccessor &i2c, std::uint16_t addr) {
    addr |= (1 << 14);
    addr <<= 1;
    unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
    buf[0] = ((addr >> 8) & 0xff);
    buf[1] = ((addr >> 0) & 0xff);
    i2c.Write(buf, 4);
    i2c.Read(buf, 2);
    return (std::uint16_t)buf[0] | (std::uint16_t)(buf[1] << 8);
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



int main(int argc, char *argv[])
{
    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }
    auto reg_sys   = uio_acc.GetAccessor(0x00000000);

    std::cout << "ID : " << std::hex << reg_sys.ReadReg(0) << std::endl;

    jelly::I2cAccessor i2c;
    i2c.Open("/dev/i2c-0", 0x10);

    std::cout << "ON" << std::endl;

    reg_sys.WriteReg(2, 1);
    usleep(100000);
//  reg_dump(i2c, "reg_start.txt");

//  spi_change(i2c, 17, 0x1234);

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
//    spi_change(i2c, 129, (1 << 13) | 1); // 8bit mode
    spi_change(i2c, 192, 0x1);
//  spi_change(i2c, 116, 0xa5 << 2); // trainingpattern
    spi_change(i2c, 116, 0x1); // trainingpattern

//    spi_change(i2c, 10, 0x900); // soft_reset_analog
//    spi_change(i2c, 10, 0x000); // soft_reset_analog


    reg_dump(i2c, "reg_end.log");

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

    usleep(1000);
    reg_sys.WriteReg(1, 1); // sw rst
    usleep(1000);
    reg_sys.WriteReg(1, 0);

//  usleep(10000000);
    printf("press anykey\n");
    getchar();
    std::cout << "OFF" << std::endl;
    reg_sys.WriteReg(2, 0);

    return 0;
}

// end of file
