#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <iostream>

#include "jelly/UioAccessor.h"


int main(int argc, char *argv[])
{
    // mmap uio
    jelly::UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    unsigned char buf[256];
    for ( int i = 0; i < 256; i++ ) {
        buf[i] = i;
    }
    uio_acc.MemCopyTo(buf, 0, 256);
    uio_acc.MemCopyFrom(0, buf, 256);
    uio_acc.MemCopyTo(buf, 0, 256);

    return 0;
}

// end of file
