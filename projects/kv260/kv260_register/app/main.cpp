// ---------------------------------------------------------------------------
//  register 読み書きテスト
//                                  Copyright (C) 2015-2024 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <unistd.h>

#include "jelly/UioAccessor.h"

using namespace jelly;


int main()
{
    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor32 uio_acc("uio_pl_peri", 0x00010000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto reg_acc = uio_acc.GetAccessor(0x00000);

    std::cout << "REG[0] : " << std::hex << reg_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG[1] : " << std::hex << reg_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG[2] : " << std::hex << reg_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG[3] : " << std::hex << reg_acc.ReadReg32(3)  << std::endl;

    reg_acc.WriteReg32(0, 0x01234567);
    reg_acc.WriteReg32(1, 0x89abcdef);
    reg_acc.WriteReg32(2, 0xaa55aa55);
    reg_acc.WriteReg32(3, 0xff00ff00);

    std::cout << "REG[0] : " << std::hex << reg_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG[1] : " << std::hex << reg_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG[2] : " << std::hex << reg_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG[3] : " << std::hex << reg_acc.ReadReg32(3)  << std::endl;

    reg_acc.WriteReg32(0, 0x0);
    reg_acc.WriteReg32(1, 0x0);
    reg_acc.WriteReg32(2, 0x0);
    reg_acc.WriteReg32(3, 0x0);

    return 0;
}

// end of file
