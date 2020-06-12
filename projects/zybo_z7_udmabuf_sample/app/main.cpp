// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/UioAccess.h"
#include "jelly/UdmabufAccess.h"

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


int main()
{
    std::cout << "--- udmabuf test ---" << std::endl;

    // mmap udmabuf
    std::cout << "\nudmabuf4 open" << std::endl;
    UdmabufAccess udmabuf_acc("udmabuf4");
    if ( !udmabuf_acc.IsMapped() ) {
        std::cout << "udmabuf4 mmap error" << std::endl;
        return 1;
    }
    std::cout << "udmabuf4 phys addr : " << std::hex << udmabuf_acc.GetPhysAddr() << std::endl;
    std::cout << "udmabuf4 size      : " << std::hex << udmabuf_acc.GetSize()     << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccess uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto dma0_acc = uio_acc.GetMemAccess(0x0000);
    auto dma1_acc = uio_acc.GetMemAccess(0x0400);
    auto led_acc  = uio_acc.GetMemAccess(0x4000);


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
    dma1_acc.WriteReg(REG_DMA_WDATA0, 0xfedcba98);
    dma1_acc.WriteReg(REG_DMA_WDATA1, 0x01234567);
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
