// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__DEV_MEM_ACCESSOR_H__
#define __RYUZ__JELLY__DEV_MEM_ACCESSOR_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>

#include "MmapAccessor.h"


namespace jelly {

// memory manager
class AccessorDevMemManager : public AccessorMmapManager
{
    using _super = AccessorMmapManager;

protected:
    AccessorDevMemManager(std::uintptr_t addr, std::size_t size) { Mmap(addr, size); }

public:
    ~AccessorDevMemManager() { Munmap(); }
    
    static std::shared_ptr<AccessorDevMemManager> Create(std::uintptr_t addr, size_t size)
    {
        return std::shared_ptr<AccessorDevMemManager>(new AccessorDevMemManager(addr, size));
    }

protected:
    bool Mmap(std::uintptr_t addr, std::size_t size)
    {
        // open
        int fd;
        if ( (fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0 ) {
            return false;
        }

        // mmap
        if ( !_super::Mmap(fd, size, (off_t)addr) ) {
            close(fd);
            return false;
        }
        return true;
    }

    void Munmap(void)
    {
        if ( !_super::IsMapped() ) {
            return;
        }

        int fd = _super::GetFd();
        _super::Munmap();
        close(fd);
    }
};


template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class DevMemAccessor_ : public MmapAccessor_<DataType, MemAddrType, RegAddrType>
{
protected:
    bool Open(std::uintptr_t addr, std::size_t size, std::size_t offset)
    {
        auto uio_manager = AccessorDevMemManager::Create(addr, size);
        if ( uio_manager->IsMapped() ) {
            this->SetMemManager(uio_manager, offset);
            return true;
        }
        return false;
    }

public:
    DevMemAccessor_() {}

    DevMemAccessor_(std::uintptr_t addr, std::size_t size, std::size_t offset=0) {
        Open(addr, size, offset);
    }

    ~DevMemAccessor_()  {}
    

    std::shared_ptr<AccessorDevMemManager> GetDevMemManager(void)
    {
        return std::dynamic_pointer_cast<AccessorDevMemManager>(this->m_mem_manager);
    }
};


using DevMemAccessor   = DevMemAccessor_<>;
using DevMemAccessor64 = DevMemAccessor_<std::uint64_t>;
using DevMemAccessor32 = DevMemAccessor_<std::uint32_t>;
using DevMemAccessor16 = DevMemAccessor_<std::uint16_t>;
using DevMemAccessor8  = DevMemAccessor_<std::uint8_t>;

}

#endif  // __RYUZ__JELLY__DEV_MEM_ACCESSOR_H__


// end of file
