
#include <iostream>
#include "UioMmap.h"
#include "UdmabufMmap.h"
#include "MemAccess.h"
#include "MmapAccess.h"
#include "UioAccess.h"

using namespace jelly;

#define REG_DMA_STATUS  0
#define REG_DMA_WSTART  1
#define REG_DMA_RSTART  2
#define REG_DMA_ADDR    3
#define REG_DMA_WDATA0  4
#define REG_DMA_WDATA1  5
#define REG_DMA_RDATA0  6
#define REG_DMA_RDATA1  7


int main()
{
    std::cout << "Hello" << std::endl;
//    UioAccess("uio_pl_peri", 0x08000000);

    return 0;

#if 0
    UdmabufMmap dmabuf("udmabuf4");
    if ( !dmabuf.IsMapped() ) {
        std::cout << "udmabuf mapped error" << std::endl;
        return 1;
    }
    printf("addr :0x%llx\n", dmabuf.GetPhysicalAddress());
    printf("size :0x%x\n", dmabuf.GetSize());

    UioMmap um("uio_pl_peri", 0x08000000);
    if ( !um.IsMapped() ) {
        std::cout << "uio mapped error" << std::endl;
        return 1;
    }

    auto addr = (unsigned long*)um.GetAddress();
    for ( int i = 0; i < 16; ++i ) {
        printf("%016lx\n", addr[i]);
    }

    um.WriteWord64(ADR_ADDR*8, dmabuf.GetPhysicalAddress());
    std::cout << um.ReadWord64(ADR_ADDR*8) << std::endl;
    std::cout << um.ReadWord64(ADR_RDATA0*8) << std::endl;
    std::cout << um.ReadWord64(ADR_RDATA1*8) << std::endl;
    um.WriteWord64(ADR_RSTART*8, 1);
    std::cout << um.ReadWord64(ADR_RDATA0*8) << std::endl;
    std::cout << um.ReadWord64(ADR_RDATA1*8) << std::endl;
    std::cout << um.ReadWord64(ADR_RDATA0*8) << std::endl;
    std::cout << um.ReadWord64(ADR_RDATA1*8) << std::endl;

    return 0;
#endif
}