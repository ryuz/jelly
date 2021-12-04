// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <vector>
#include <cstdint>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/JellyI2c.h"

using namespace jelly;


#define MPU9250_ADDRESS     0x68    // 7bit address
#define AK8963_ADDRESS      0x0C    // Address of magnetometer


int main()
{
    std::cout << "--- i2c test ---" << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto i2c_acc = uio_acc.GetAccessor(0x080000);
    auto led_acc = uio_acc.GetAccessor(0x100800);

    // I2C
//    i2c_acc.WriteReg(REG_I2C_DIVIDER, 100);

    JellyI2c i2c(i2c_acc, uio_acc);
    i2c.SetDivider(20);
    i2c.Write(MPU9250_ADDRESS, {0x75});
    auto who_am_i = i2c.Read(MPU9250_ADDRESS, 1);
    if ( who_am_i.size() != 1 ) {
        std::cout << "read error : WHO_AM_I" << std::endl;
        return 1;
    }
    printf("WHO_AM_I(exp:0x71):0x%02x\n", who_am_i[0]);
    return 0;

    i2c.Write(MPU9250_ADDRESS, {0x6b});
    i2c.Write(MPU9250_ADDRESS, {0x00});
    i2c.Write(MPU9250_ADDRESS, {0x37});
    i2c.Write(MPU9250_ADDRESS, {0x02});
    return 0;

    // LED点滅
    std::cout << "\n<LED test>" << std::endl;
    for ( int i = 0; i < 3; i++) {
        std::cout << "LED : ON" << std::endl;
        led_acc.WriteReg(0, 1);
        sleep(1);

        std::cout << "LED : OFF" << std::endl;
        led_acc.WriteReg(0, 0);
        sleep(1);
    }

    return 0;
}

// end of file
