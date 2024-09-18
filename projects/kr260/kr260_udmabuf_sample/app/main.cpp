// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

using namespace jelly;

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

int main()
{
    std::cout << "--- udmabuf test ---" << std::endl;

    // mmap udmabuf
    std::cout << "\nudmabuf open" << std::endl;
    UdmabufAccessor udmabuf_acc("udmabuf-jelly-sample");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf mmap error" << std::endl;
        return 1;
    }
    std::cout << "udmabuf phys addr : " << std::hex << udmabuf_acc.GetPhysAddr() << std::endl;
    std::cout << "udmabuf size      : " << std::hex << udmabuf_acc.GetSize()     << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto dma0_acc = uio_acc.GetAccessor(0x00000);
    auto dma1_acc = uio_acc.GetAccessor(0x00800);
    auto led_acc  = uio_acc.GetAccessor(0x08000);
    auto tim_acc  = uio_acc.GetAccessor(0x10000);

    // メモリアドレスでアクセス
    std::cout << "\n<test MemRead>" << std::endl;
    std::cout << "DMA0_CORE_ID : " << std::hex << uio_acc.ReadMem(0x0040) << std::endl;
    std::cout << "DMA1_CORE_ID : " << std::hex << uio_acc.ReadMem(0x0840) << std::endl;
    
    // レジスタ番号でアクセス
    std::cout << "\n<test RegRead>" << std::endl;
    std::cout << "DMA0_CORE_ID : " << std::hex << dma0_acc.ReadReg(REG_DMA_CORE_ID) << std::endl;
    std::cout << "DMA1_CORE_ID : " << std::hex << dma1_acc.ReadReg(REG_DMA_CORE_ID) << std::endl;
 
    std::cout << "\n<test DMA0 RegRead>" << std::endl;
    std::cout << "DMA0_STATUS  : " << std::hex << dma0_acc.ReadReg(REG_DMA_STATUS)  << std::endl;
    std::cout << "DMA0_WSTART  : " << std::hex << dma0_acc.ReadReg(REG_DMA_WSTART)  << std::endl;
    std::cout << "DMA0_RSTART  : " << std::hex << dma0_acc.ReadReg(REG_DMA_RSTART)  << std::endl;
    std::cout << "DMA0_ADDR    : " << std::hex << dma0_acc.ReadReg(REG_DMA_ADDR)    << std::endl;
    std::cout << "DMA0_WDATA0  : " << std::hex << dma0_acc.ReadReg(REG_DMA_WDATA0)  << std::endl;
    std::cout << "DMA0_WDATA1  : " << std::hex << dma0_acc.ReadReg(REG_DMA_WDATA1)  << std::endl;
    std::cout << "DMA0_RDATA0  : " << std::hex << dma0_acc.ReadReg(REG_DMA_RDATA0)  << std::endl;
    std::cout << "DMA0_RDATA1  : " << std::hex << dma0_acc.ReadReg(REG_DMA_RDATA1)  << std::endl;
    std::cout << "DMA0_CORE_ID : " << std::hex << dma0_acc.ReadReg(REG_DMA_CORE_ID) << std::endl;


    // udma領域アクセス
    std::cout << "\n<test udmabuf access>" << std::endl;
    {
        auto ptr = (std::int32_t *)udmabuf_acc.GetPtr();
        ptr[0] = 0x10101010;
        ptr[1] = 0x20202020;
        ptr[2] = 0x30303030;
        ptr[3] = 0x40404040;
        std::cout << "ptr[0] : " << std::hex << ptr[0] << std::endl;
        std::cout << "ptr[1] : " << std::hex << ptr[1] << std::endl;
        std::cout << "ptr[2] : " << std::hex << ptr[2] << std::endl;
        std::cout << "ptr[3] : " << std::hex << ptr[3] << std::endl;
        // キャッシュフラッシュ不要なのか？
    }


    // DMA0でread
    std::cout << "\n<DMA0 read test>" << std::endl;
    dma0_acc.WriteReg(REG_DMA_ADDR, udmabuf_acc.GetPhysAddr());
    dma0_acc.WriteReg(REG_DMA_RSTART, 1);
    while ( dma0_acc.ReadReg(REG_DMA_STATUS) )
        ;
    std::cout << "REG_DMA0_RDATA0 : " << std::hex << dma0_acc.ReadReg(REG_DMA_RDATA0) << std::endl;
    std::cout << "REG_DMA0_RDATA1 : " << std::hex << dma0_acc.ReadReg(REG_DMA_RDATA1) << std::endl;

    // DMA1でread
    std::cout << "\n<DMA1 read test>" << std::endl;
    dma1_acc.WriteReg(REG_DMA_ADDR, udmabuf_acc.GetPhysAddr());
    dma1_acc.WriteReg(REG_DMA_RSTART, 1);
    while ( dma1_acc.ReadReg(REG_DMA_STATUS) )
        ;
    std::cout << "REG_DMA1_RDATA0 : " << std::hex << dma1_acc.ReadReg(REG_DMA_RDATA0) << std::endl;
    std::cout << "REG_DMA1_RDATA1 : " << std::hex << dma1_acc.ReadReg(REG_DMA_RDATA1) << std::endl;


    // DMA1でwrite
    std::cout << "\n<DMA1 write test>" << std::endl;
    dma1_acc.WriteReg(REG_DMA_ADDR, udmabuf_acc.GetPhysAddr());
    dma1_acc.WriteReg(REG_DMA_WDATA0, 0xfedcba9876543210UL);
    dma1_acc.WriteReg(REG_DMA_WDATA1, 0x0123456789abcdefUL);
    dma1_acc.WriteReg(REG_DMA_WSTART, 1);
    while ( dma1_acc.ReadReg(REG_DMA_STATUS) )
        ;

    // udma領域アクセス
    {
        auto ptr = (std::int32_t *)udmabuf_acc.GetPtr();
        std::cout << "ptr[0] : " << std::hex << ptr[0] << std::endl;
        std::cout << "ptr[1] : " << std::hex << ptr[1] << std::endl;
        std::cout << "ptr[2] : " << std::hex << ptr[2] << std::endl;
        std::cout << "ptr[3] : " << std::hex << ptr[3] << std::endl;
        // キャッシュフラッシュ不要なのか？
    }
    
    // DMA0でread
    std::cout << "\n<DMA0 read test>" << std::endl;
    dma0_acc.WriteReg(REG_DMA_ADDR, udmabuf_acc.GetPhysAddr());
    dma0_acc.WriteReg(REG_DMA_RSTART, 1);
    while ( dma0_acc.ReadReg(REG_DMA_STATUS) )
        ;
    std::cout << "REG_DMA0_RDATA0 : " << std::hex << dma0_acc.ReadReg(REG_DMA_RDATA0) << std::endl;
    std::cout << "REG_DMA0_RDATA1 : " << std::hex << dma0_acc.ReadReg(REG_DMA_RDATA1) << std::endl;

    // タイマ割り込みでLED点滅
    std::cout << "\n<LED test>" << std::endl;
    tim_acc.WriteReg(REG_TIM_COMPARE, 100000000-1);
    tim_acc.WriteReg(REG_TIM_CONTROL, 1);
    for ( int i = 0; i < 5; i++) {
        // LED ON
        std::cout << "LED : ON" << std::endl;
        led_acc.WriteReg(0, 1);

        // 割り込み待ち
        uio_acc.SetIrqEnable(true);
        uio_acc.WaitIrq();
        tim_acc.ReadReg(REG_TIM_CONTROL);   // clear interrupt

        // LED OFF
        std::cout << "LED : OFF" << std::endl;
        led_acc.WriteReg(0, 0);

        // 割り込み待ち
        uio_acc.SetIrqEnable(true);
        uio_acc.WaitIrq();
        tim_acc.ReadReg(REG_TIM_CONTROL);   // clear interrupt
    }
    
    return 0;
}

// end of file
