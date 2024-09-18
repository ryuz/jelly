// ---------------------------------------------------------------------------
//  自作デバイスドライバテスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>

/*
#define REG_DMA_STATUS  0
#define REG_DMA_WSTART  1
#define REG_DMA_RSTART  2
#define REG_DMA_ADDR    3
#define REG_DMA_WDATA0  4
#define REG_DMA_WDATA1  5
#define REG_DMA_RDATA0  6
#define REG_DMA_RDATA1  7
#define REG_DMA_CORE_ID 8

#define REG_TIM_CONTROL 0
#define REG_TIM_COMPARE 1
#define REG_TIM_COUNTER 3
*/


int main()
{
    std::cout << "--- devdrv test start ---" << std::endl;

    // ドライバオープン
    int fd = open("/dev/jelly-devdrv0", O_RDWR);
    if (fd < 0) {
        std::cout << "open error" << std::endl;
        return 1;
    }

    // ユーザー空間にデータを置いておく
    static unsigned long data[] = {
        0xAA01020304050607,
        0xAA11121314151617,
        0xAA21222324252627,
        0xAA31323334353637,
        0xAA41424344454647,
        0xAA51525354555657,
        0xAA61626364656667,
        0xAA71727374757677,
        0xAA81828384858687,
    };

    // ドライバにデータのポインタを渡す(ユーザー空間の論理アドレス)
    write(fd, data, sizeof(data));

    // ドライバクローズ
    close(fd);

    std::cout << "--- devdrv test end ---" << std::endl;

    return 0;
}

// end of file
