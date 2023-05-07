#include <iostream>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/JellyRegs.h"



int main(int argc, char *argv[])
{
    std::cout << "LAN8720 Sample" << std::endl;
    
    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x00100000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    auto reg_gid   = uio_acc.GetAccessor(0x00000000);

    return 0;
}


// end of file