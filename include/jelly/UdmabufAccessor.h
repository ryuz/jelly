// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__UDMABUF_ACCESSOR_H__
#define __RYUZ__JELLY__UDMABUF_ACCESSOR_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <string>
#include <errno.h>

#include "UioAccessor.h"

namespace jelly {


// memory manager
using AccessorUdmabufManager = AccessorUioManager;


template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class UdmabufAccessor_ : public UioAccessor_<DataType, MemAddrType, RegAddrType>
{
protected:
    std::intptr_t   m_phys_addr = 0;

    bool Open(const char* name, std::size_t size, std::size_t offset, int flags=(O_RDWR | O_SYNC))
    {
        std::string fname = "/dev/";
        fname += name;
        auto udmabuf_manager = AccessorUdmabufManager::Create(fname.c_str(), size, 0, flags);
        if ( udmabuf_manager->IsMapped() ) {
            this->SetMemManager(udmabuf_manager, offset);
            return true;
        }
        return false;
    }

    // ------- static -------

private:
    template <typename T>
    static inline T ReadValue(std::string name, std::string device_name, std::string module_name = "u-dma-buf")
    {
        std::string path = "/sys/class/" + module_name + "/" + device_name + "/" + name;
        int fd  = open(path.c_str(), O_RDONLY);
        if ( fd == -1) { return 0; }
        char  buf[1024];
        int len = read(fd, buf, 1024);
        if ( len < 1 ) { close(fd); return 0; }
        close(fd);
        buf[len] = '\0';
        return static_cast<T>(strtoull(buf, NULL, 0));
    }

    template <typename T>
    static inline int WriteValue(T value, std::string name, std::string device_name, std::string module_name = "u-dma-buf")
    {
        std::string path = "/sys/class/" + module_name + "/" + device_name + "/" + name;
        int fd  = open(path.c_str(), O_RDONLY);
        if ( fd == -1) { return 0; }
        char  buf[1024];
        sprintf(buf, "%ld", (std::uint64_t)value);
        int len =  strlen(buf);
        if ( write(fd, buf, len) != len ) { close(fd); return 0; }
        close(fd);
        return 1;
    }

    static inline int WriteSync(
                std::uintptr_t  sync_offset,
                std::size_t  sync_size     ,
                int          sync_direction,
                int          sync_for_x  ,
                std::string name, std::string device_name, std::string module_name = "u-dma-buf")
    {
        std::string path = "/sys/class/" + module_name + "/" + device_name + "/" + name;
        int fd  = open(path.c_str(), O_RDONLY);
        if ( fd == -1) { return 0; }
        char  buf[1024];
        sprintf(buf, "0x%08X%08X", (sync_offset & 0xFFFFFFFF), (sync_size & 0xFFFFFFF0) | (sync_direction << 2) | sync_for_x);
        int len =  strlen(buf);
        if ( write(fd, buf, len) != len ) { close(fd); return 0; }
        close(fd);
        return 1;
    }

public:
    static std::uintptr_t ReadPhysAddr(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<std::size_t>("phys_addr", device_name, module_name);
    }

    static std::size_t ReadSize(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<std::size_t>("size", device_name, module_name);
    }

    static int ReadSyncMode(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<int>("sync_mode", device_name, module_name);
    }

    static std::uintptr_t ReadSyncOffset(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<std::uintptr_t>("sync_offset", device_name, module_name);
    }

    static int ReadSyncDirection(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<int>("sync_direction", device_name, module_name);
    }

    static int WriteSyncDirection(int sync_direction, std::string device_name, std::string module_name = "u-dma-buf")
    {
        return WriteValue<std::uint32_t>(sync_direction, "sync_direction", device_name, module_name);
    }

    static int ReadDmaCoherent(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<int>("dma_coherent", device_name, module_name);
    }

    static int ReadSyncOwner(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return ReadValue<int>("sync_owner", device_name, module_name);
    }

    static int WriteSyncForCpu(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return WriteValue<int>(1, "sync_for_cpu", device_name, module_name);
    }

    static int WriteSyncForCpu(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_cpu    ,
                std::string     device_name     , 
                std::string     module_name = "u-dma-buf")
    {
        return WriteSync(sync_offset, sync_size, sync_direction, sync_for_cpu, "sync_for_cpu", device_name, module_name);
    }

    static int WriteSyncForDevice(std::string device_name, std::string module_name = "u-dma-buf")
    {
        return WriteValue<int>(1, "sync_for_device", device_name, module_name);
    }

    static int WriteSyncForDevice(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_cpu    ,
                std::string     device_name     , 
                std::string     module_name = "u-dma-buf")
    {
        return WriteSync(sync_offset, sync_size, sync_direction, sync_for_cpu, "sync_for_device", device_name, module_name);
    }



    ///////////////////////////////////

    // get phys_addr
    static std::uintptr_t GetPhysAddr_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/phys_addr";
        FILE *fp;
        if ( (fp = fopen(fname.c_str(), "r")) == NULL ) {
            return 0;
        }
        char buf[32];
        if ( fgets(buf, 32, fp) == NULL ) {
            fclose(fp);
            return 0;
        }
        fclose(fp);
        return static_cast<std::intptr_t>(strtoull(buf, NULL, 16));
    }

    // get phys_size
    static std::size_t GetPhysSize_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/size";
        FILE *fp;
        if ( (fp = fopen(fname.c_str(), "r")) == NULL ) {
            return 0;
        }
        char buf[32];
        if ( fgets(buf, 32, fp) == NULL ) {
            fclose(fp);
            return -1;
        }
        fclose(fp);
        return static_cast<std::size_t>(strtoull(buf, NULL, 0));
    }

public:
    UdmabufAccessor_() {}

    UdmabufAccessor_(const char* name, std::size_t offset=0) {
        auto size = GetPhysSize(name);
        if ( size > 0 ) {
            m_phys_addr = GetPhysAddr(name);
            Open(name, size, offset);
        }
    }

    ~UdmabufAccessor_() {}

    std::uintptr_t GetPhysAddr(void)
    {
        return m_phys_addr;
    }
    
    std::shared_ptr<AccessorUdmabufManager> GetUdmabufManager(void)
    {
        return std::dynamic_pointer_cast<AccessorUdmabufManager>(this->m_mem_manager);
    }

    // get phys_addr
    static std::uintptr_t GetPhysAddr(const char* name)
    {
        std::uintptr_t addr;
        if ( (addr = GetPhysAddr_("/sys/class/u-dma-buf/", name)) > 0 ) { return addr; }
        if ( (addr = GetPhysAddr_("/sys/class/udmabuf/", name)) > 0 ) { return addr; }
        return 0;
    }

    static std::size_t GetPhysSize(const char* name)
    {
        std::size_t size;
        if ( (size = GetPhysSize_("/sys/class/u-dma-buf/", name)) > 0 ) { return size; }
        if ( (size = GetPhysSize_("/sys/class/udmabuf/", name)) > 0 ) { return size; }
        return 0;
    }
};



using UdmabufAccessor   = UdmabufAccessor_<>;
using UdmabufAccessor64 = UdmabufAccessor_<std::uint64_t>;
using UdmabufAccessor32 = UdmabufAccessor_<std::uint32_t>;
using UdmabufAccessor16 = UdmabufAccessor_<std::uint16_t>;
using UdmabufAccessor8  = UdmabufAccessor_<std::uint8_t>;

}

#endif  // __RYUZ__JELLY__UDMABUF_ACCESSOR_H__


// end of file
