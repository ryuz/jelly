#include <iostream>
#include "UioMmap.h"


int main()
{
    std::cout << "Hello" << std::endl;

    UioMmap um("uio_pl_peri", 0x08000000);
    if ( !um.IsMapped() ) {
        std::cout << "mapped error" << std::endl;
    }

    auto addr = (unsigned long*)um.GetAddress();
    for ( int i = 0; i < 16; ++i ) {
        printf("%016lx\n", addr[i]);
    }

    return 0;
}