
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

    // mmap uio
    UioAccess uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio mmap error" << std::endl;
        return 1;
    }

    std::cout << "REG_DMA_STATUS : " << std::hex << uio_acc.ReadReg(REG_DMA_STATUS) << std::endl;
    std::cout << "REG_DMA_WSTART : " << std::hex << uio_acc.ReadReg(REG_DMA_WSTART) << std::endl;
    std::cout << "REG_DMA_RSTART : " << std::hex << uio_acc.ReadReg(REG_DMA_RSTART) << std::endl;
    std::cout << "REG_DMA_ADDR   : " << std::hex << uio_acc.ReadReg(REG_DMA_ADDR)   << std::endl;
    std::cout << "REG_DMA_WDATA0 : " << std::hex << uio_acc.ReadReg(REG_DMA_WDATA0) << std::endl;
    std::cout << "REG_DMA_WDATA1 : " << std::hex << uio_acc.ReadReg(REG_DMA_WDATA1) << std::endl;
    std::cout << "REG_DMA_RDATA0 : " << std::hex << uio_acc.ReadReg(REG_DMA_RDATA0) << std::endl;
    std::cout << "REG_DMA_RDATA1 : " << std::hex << uio_acc.ReadReg(REG_DMA_RDATA1) << std::endl;
    std::cout << "OTHER :          " << std::hex << uio_acc.ReadReg(8) << std::endl;

    uio_acc.WriteReg(REG_DMA_RSTART, 1);
    std::cout << "REG_DMA_STATUS : " << std::hex << uio_acc.ReadReg(REG_DMA_STATUS) << std::endl;
    std::cout << "REG_DMA_WSTART : " << std::hex << uio_acc.ReadReg(REG_DMA_WSTART) << std::endl;
    std::cout << "REG_DMA_RSTART : " << std::hex << uio_acc.ReadReg(REG_DMA_RSTART) << std::endl;
    std::cout << "REG_DMA_ADDR   : " << std::hex << uio_acc.ReadReg(REG_DMA_ADDR)   << std::endl;
    std::cout << "REG_DMA_WDATA0 : " << std::hex << uio_acc.ReadReg(REG_DMA_WDATA0) << std::endl;
    std::cout << "REG_DMA_WDATA1 : " << std::hex << uio_acc.ReadReg(REG_DMA_WDATA1) << std::endl;
    std::cout << "REG_DMA_RDATA0 : " << std::hex << uio_acc.ReadReg(REG_DMA_RDATA0) << std::endl;
    std::cout << "REG_DMA_RDATA1 : " << std::hex << uio_acc.ReadReg(REG_DMA_RDATA1) << std::endl;
    std::cout << "OTHER :          " << std::hex << uio_acc.ReadReg(8) << std::endl;

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