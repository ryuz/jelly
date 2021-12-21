// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

using namespace jelly;


#define REG_HLS_CORE_ID     0
#define REG_HLS_CONTROL     4
#define REG_HLS_STATUS      5
#define REG_HLS_A           8
#define REG_HLS_B           9
#define REG_HLS_C           10

#define REG_LED_GPIO        0


int main()
{
    std::cout << "--- udmabuf test ---" << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto hls_acc = uio_acc.GetAccessor(0x00000);
    auto led_acc = uio_acc.GetAccessor(0x08000);

    // HSL
    std::cout << "\n<test HLS>" << std::endl;
    std::cout << "HLS_CORE_ID : " << std::hex << hls_acc.ReadReg(REG_HLS_CORE_ID) << std::endl;
    hls_acc.WriteReg(REG_HLS_A, 77777);
    hls_acc.WriteReg(REG_HLS_B, 11111);
    hls_acc.WriteReg(REG_HLS_CONTROL, 1);
    usleep(1);
    std::cout << "REG_HLS_A : " << std::hex << hls_acc.ReadReg(REG_HLS_A) << std::endl;
    std::cout << "REG_HLS_B : " << std::hex << hls_acc.ReadReg(REG_HLS_B) << std::endl;
    std::cout << "REG_HLS_C : " << std::hex << hls_acc.ReadReg(REG_HLS_C) << std::endl;

    // LED点滅
    std::cout << "\n<LED test>" << std::endl;
    for ( int i = 0; i < 3; i++) {
        // LED ON
        std::cout << "LED : ON" << std::endl;
        led_acc.WriteReg(REG_LED_GPIO, 1);
        usleep(1000000);

        // LED OFF
        std::cout << "LED : OFF" << std::endl;
        led_acc.WriteReg(REG_LED_GPIO, 0);
        usleep(1000000);
    }
    
    return 0;
}

// end of file
