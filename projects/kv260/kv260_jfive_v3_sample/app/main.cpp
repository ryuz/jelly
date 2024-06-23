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


int main()
{
    std::cout << "Hello" << std::endl;

    /*
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
    */
   
    return 0;
}

// end of file
