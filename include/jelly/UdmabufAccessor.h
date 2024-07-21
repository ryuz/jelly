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
#include <cstdio>
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
    std::string     m_device_name;
    std::string     m_module_name;

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


public:
    UdmabufAccessor_() {}

    UdmabufAccessor_(const char* device_name, std::size_t offset=0, int flags=(O_RDWR | O_SYNC)) {
        // size check
        std::size_t size = 0;
        if ( (size = ReadSize(device_name, "u-dma-buf")) > 0 ) {
            m_module_name = "u-dma-buf";
        }
        else if ( (size = ReadSize(device_name, "udmabuf")) > 0 ) {
            m_module_name = "udmabuf";
        }
        else if ( (size = ReadSize(device_name, "uiomem")) > 0 ) {
            m_module_name = "uiomem";
        }

        if ( size > 0 ) {
            m_device_name = device_name;
            m_phys_addr   = ReadPhysAddr(device_name, m_module_name.c_str());
            Open(device_name, size, offset, flags);
        }
    }

    UdmabufAccessor_(const char* device_name, const char* module_name, std::size_t offset=0, int flags=(O_RDWR | O_SYNC)) {
        auto size = ReadSize(device_name, module_name);
        if ( size > 0 ) {
            m_device_name = device_name;
            m_module_name = module_name;
            m_phys_addr = ReadPhysAddr(device_name, module_name);
            Open(device_name, size, offset, flags);
        }
    }


    ~UdmabufAccessor_() {}

    std::shared_ptr<AccessorUdmabufManager> GetUdmabufManager(void)
    {
        return std::dynamic_pointer_cast<AccessorUdmabufManager>(this->m_mem_manager);
    }


    std::uintptr_t GetPhysAddr(void)
    {
        return m_phys_addr;
    }


    std::size_t GetPhysSize(void)
    {
        return ReadSize(m_device_name.c_str(), m_module_name.c_str());
    }

    int GetSyncMode(void)
    {
        return ReadSyncMode(m_device_name.c_str(), m_module_name.c_str());
    }

    std::uintptr_t GetSyncOffset(void)
    {
        return ReadSyncOffset(m_device_name.c_str(), m_module_name.c_str());
    }

    int GetSyncDirection(void)
    {
        return ReadSyncDirection(m_device_name.c_str(), m_module_name.c_str());
    }

    int SetSyncDirection(int sync_direction)
    {
        return WriteSyncDirection(sync_direction, m_device_name.c_str(), m_module_name.c_str());
    }

    int GetDmaCoherent(void)
    {
        return ReadDmaCoherent(m_device_name.c_str(), m_module_name.c_str());
    }

    int GetSyncOwner(void)
    {
        return ReadSyncOwner(m_device_name.c_str(), m_module_name.c_str());
    }

    int SyncForCpu(void)
    {
        return WriteSyncForCpu(m_device_name.c_str(), m_module_name.c_str());
    }

    int SyncForCpu(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_cpu    )
    {
        return WriteSyncForCpu(sync_offset, sync_size, sync_direction, sync_for_cpu, m_device_name.c_str(), m_module_name.c_str());
    }

    int SyncForDevice(void)
    {
        return WriteSyncForDevice(m_device_name.c_str(), m_module_name.c_str());
    }

    int SyncForDevice(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_cpu    )
    {
        return WriteSyncForDevice(sync_offset, sync_size, sync_direction, sync_for_cpu, m_device_name.c_str(), m_module_name.c_str());
    }


    // ------- 後方互換用 -------

    // get phys_addr
    static std::uintptr_t GetPhysAddr(const char* device_name)
    {
        std::uintptr_t addr;
        if ( (addr = ReadPhysAddr(device_name, "u-dma-buf")) > 0 ) { return addr; }
        if ( (addr = ReadPhysAddr(device_name, "udmabuf"  )) > 0 ) { return addr; }
        if ( (addr = ReadPhysAddr(device_name, "uiomem"   )) > 0 ) { return addr; }
        return 0;
    }

    // get phys_size
    static std::size_t GetPhysSize(const char* device_name)
    {
        std::size_t size;
        if ( (size = ReadSize(device_name, "u-dma-buf")) > 0 ) { return size; }
        if ( (size = ReadSize(device_name, "udmabuf"  )) > 0 ) { return size; }
        if ( (size = ReadSize(device_name, "uiomem"   )) > 0 ) { return size; }
        return 0;
    }


    // ------- static API -------
public:
    static std::uintptr_t ReadPhysAddr(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<std::size_t>("phys_addr", device_name, module_name);
    }

    static std::size_t ReadSize(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<std::size_t>("size", device_name, module_name);
    }

    static int ReadSyncMode(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<int>("sync_mode", device_name, module_name);
    }

    static std::uintptr_t ReadSyncOffset(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<std::uintptr_t>("sync_offset", device_name, module_name);
    }

    static int ReadSyncDirection(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<int>("sync_direction", device_name, module_name);
    }

    static int WriteSyncDirection(int sync_direction, const char *device_name, const char *module_name = "u-dma-buf")
    {
        return WriteValue<std::uint32_t>(sync_direction, "sync_direction", device_name, module_name);
    }

    static int ReadDmaCoherent(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<int>("dma_coherent", device_name, module_name);
    }

    static int ReadSyncOwner(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return ReadValue<int>("sync_owner", device_name, module_name);
    }

    static int WriteSyncForCpu(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return WriteValue<int>(1, "sync_for_cpu", device_name, module_name);
    }

    static int WriteSyncForCpu(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_cpu    ,
                const char      *device_name    , 
                const char      *module_name = "u-dma-buf")
    {
        return WriteSync(sync_offset, sync_size, sync_direction, sync_for_cpu, "sync_for_cpu", device_name, module_name);
    }

    static int WriteSyncForDevice(const char *device_name, const char *module_name = "u-dma-buf")
    {
        return WriteValue<int>(1, "sync_for_device", device_name, module_name);
    }

    static int WriteSyncForDevice(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_cpu    ,
                const char      *device_name    , 
                const char      *module_name = "u-dma-buf")
    {
        return WriteSync(sync_offset, sync_size, sync_direction, sync_for_cpu, "sync_for_device", device_name, module_name);
    }

private:
    template <typename T>
    static inline T ReadValue(const char *name, const char *device_name, const char *module_name = "u-dma-buf")
    {
        char path[256];
        snprintf(path, sizeof(path), "/sys/class/%s/%s/%s", module_name, device_name, name);
        int fd  = open(path, O_RDONLY);
        if ( fd == -1) { fprintf(stderr, "open error : %s\n", path); return 0; }
        char  buf[64];
        int len = read(fd, buf, sizeof(buf));
        if ( len < 1 ) { fprintf(stderr, "read error : %s\n", path); close(fd); return 0; }
        close(fd);
        buf[len] = '\0';
        return static_cast<T>(strtoull(buf, NULL, 0));
    }

    template <typename T>
    static inline int WriteValue(T value, const char *name, const char *device_name, const char *module_name = "u-dma-buf")
    {
        char path[256];
        snprintf(path, sizeof(path), "/sys/class/%s/%s/%s", module_name, device_name, name);
        int fd  = open(path, O_WRONLY);
        if ( fd == -1) { fprintf(stderr, "open error : %s\n", path); return 0; }
        char  buf[64];
        snprintf(buf, sizeof(buf), "%ld", (std::uint64_t)value);
        int len =  strlen(buf);
        int l;
        if ( (l = write(fd, buf, len)) != len ) { fprintf(stderr, "write error : %s, %d %d\n", path, l, len); close(fd); return 0; }
        close(fd);
        return 1;
    }

    static inline int WriteSync(
                std::uintptr_t  sync_offset     ,
                std::size_t     sync_size       ,
                int             sync_direction  ,
                int             sync_for_x      ,
                const char      *name           ,
                const char      *device_name    ,
                const char      *module_name = "u-dma-buf")
    {
        char path[256];
        snprintf(path, sizeof(path), "/sys/class/%s/%s/%s", module_name, device_name, name);
        int  fd  = open(path, O_RDONLY);
        if ( fd == -1) { return 0; }
        char buf[64];
        int  len = snprintf(buf, sizeof(buf), "0x%08X%08X", (sync_offset & 0xFFFFFFFF), (sync_size & 0xFFFFFFF0) | (sync_direction << 2) | sync_for_x);
        if ( write(fd, buf, len) != len ) { close(fd); return 0; }
        close(fd);
        return 1;
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
