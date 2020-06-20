// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuji Fuchikami
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/UioAccess.h"
#include "jelly/UdmabufAccess.h"


int main()
{
    std::cout << "--- udmabuf test ---" << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    jelly::UioAccess uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto gid_acc = uio_acc.GetMemAccess(0x0000);
    std::cout <<  std::hex << gid_acc.ReadReg(0) << std::endl;

//    auto dma1_acc = uio_acc.GetMemAccess(0x0400);
//    auto led_acc  = uio_acc.GetMemAccess(0x4000);
	
	
    return 0;
}

// end of file
