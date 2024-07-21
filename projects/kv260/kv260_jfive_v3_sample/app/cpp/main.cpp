
#include <iostream>
#include <fstream>
#include <string>
#include <unistd.h>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

using namespace jelly;


int main()
{
    std::cout << "Hello JFive (cpp)" << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor32 uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto jfive_ctl = uio_acc.GetAccessor32(0x000000);
    auto jfive_mem = uio_acc.GetAccessor32(0x100000);

    jfive_ctl.WriteReg32(4, 0);

    std::cout << "CORE_ID  : 0x" << std::hex << jfive_ctl.ReadReg32(0x00) << std::endl;
    std::cout << "CORE_VER : 0x" << std::hex << jfive_ctl.ReadReg32(0x01) << std::endl;

    // 16進数のテキストファイルを１行づつ読み込む
    std::ifstream ifs("../../mem.hex");
    std::uint32_t val;
    for ( int i = 0; i < 1024; i++ ) {
        if ( !(ifs >> std::hex >> val) ) {
            std::cout << "size : 0x" << std::hex << i << std::endl;
            break;
        }
        jfive_mem.WriteReg32(i, val);
    }

    jfive_ctl.WriteReg32(4, 1);

    return 0;
}

// end of file
