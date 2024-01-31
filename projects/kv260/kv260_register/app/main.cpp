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
    UioAccessor32 uio_acc("uio_pl_peri", 0x10000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto reg0_acc = uio_acc.GetAccessor(0x00000);
    auto reg1_acc = uio_acc.GetAccessor(0x10000);

    std::cout << "REG0[0] : " << std::hex << reg0_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG0[1] : " << std::hex << reg0_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG0[2] : " << std::hex << reg0_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG0[3] : " << std::hex << reg0_acc.ReadReg32(3)  << std::endl;
    std::cout << "REG1[0] : " << std::hex << reg1_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG1[1] : " << std::hex << reg1_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG1[2] : " << std::hex << reg1_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG1[3] : " << std::hex << reg1_acc.ReadReg32(3)  << std::endl;
    std::cout << std::endl;

    reg0_acc.WriteReg32(0, 0x01234567);
    reg0_acc.WriteReg32(1, 0x89abcdef);
    reg0_acc.WriteReg32(2, 0xaa55aa55);
    reg0_acc.WriteReg32(3, 0xff00ff00);

    std::cout << "REG0[0] : " << std::hex << reg0_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG0[1] : " << std::hex << reg0_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG0[2] : " << std::hex << reg0_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG0[3] : " << std::hex << reg0_acc.ReadReg32(3)  << std::endl;
    std::cout << "REG1[0] : " << std::hex << reg1_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG1[1] : " << std::hex << reg1_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG1[2] : " << std::hex << reg1_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG1[3] : " << std::hex << reg1_acc.ReadReg32(3)  << std::endl;
    std::cout << std::endl;

    reg1_acc.WriteReg32(0, 0xfedcba98);
    reg1_acc.WriteReg32(1, 0x76543210);
    reg1_acc.WriteReg32(2, 0x55aa55aa);
    reg1_acc.WriteReg32(3, 0x00ff00ff);

    std::cout << "REG0[0] : " << std::hex << reg0_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG0[1] : " << std::hex << reg0_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG0[2] : " << std::hex << reg0_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG0[3] : " << std::hex << reg0_acc.ReadReg32(3)  << std::endl;
    std::cout << "REG1[0] : " << std::hex << reg1_acc.ReadReg32(0)  << std::endl;
    std::cout << "REG1[1] : " << std::hex << reg1_acc.ReadReg32(1)  << std::endl;
    std::cout << "REG1[2] : " << std::hex << reg1_acc.ReadReg32(2)  << std::endl;
    std::cout << "REG1[3] : " << std::hex << reg1_acc.ReadReg32(3)  << std::endl;
    std::cout << std::endl;

    reg0_acc.WriteReg32(0, 0x1);
    reg0_acc.WriteReg32(1, 0x0);
    reg0_acc.WriteReg32(2, 0x0);
    reg0_acc.WriteReg32(3, 0x0);

    return 0;
}

// end of file
