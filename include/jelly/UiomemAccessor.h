// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2024 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__UIOMEM_ACCESSOR_H__
#define __RYUZ__JELLY__UIOMEM_ACCESSOR_H__


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
using AccessorUiomemManager = AccessorUioManager;


template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class UiomemAccessor_ : public UioAccessor_<DataType, MemAddrType, RegAddrType>
{
protected:
    std::intptr_t   m_phys_addr = 0;
    std::string     m_name;

    bool Open(const char* name, std::size_t size, std::size_t offset, int flags=O_RDWR)
    {
        m_name = name;
        std::string fname = "/dev/";
        fname += name;
        auto udmabuf_manager = AccessorUiomemManager::Create(fname.c_str(), size, 0, flags);
        if ( udmabuf_manager->IsMapped() ) {
            this->SetMemManager(udmabuf_manager, offset);
            return true;
        }
        return false;
    }

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
            return -1;
        }
        fclose(fp);
        return static_cast<std::intptr_t>(strtoull(buf, NULL, 16));
    }

    // get size
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

    /*
    // get sync_offset
    static std::uintptr_t GetSyncOffset_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/sync_offset";
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
        return static_cast<std::uintptr_t>(strtoull(buf, NULL, 0));
    }

    // get sync_size
    static std::size_t GetSyncSize_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/sync_size";
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

    // get sync_direction
    static int GetSyncDirection_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/sync_direction";
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
        return static_cast<int>(strtoull(buf, NULL, 0));
    }

    // set sync_direction
    static int SetSyncDirection_(std::string fname, std::string name, unsigned long  sync_direction)
    {
        fname += name;
        fname += "/sync_direction";
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
        return static_cast<int>(strtoull(buf, NULL, 0));
    }

    // get sync_owner
    static int GetSyncOwner_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/sync_owner";
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
        return static_cast<int>(strtoull(buf, NULL, 0));
    }

    // sync_for_cpu
    static int SyncForCpu_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/sync_for_cpu";
        int fd = open(fname.c_str(), O_WRONLY);
        if ( fd == -1) {
            return 0;
        }
        unsigned char   attr[1024];
        sprintf(attr, "0x%08X%08X", (sync_offset & 0xFFFFFFFF), (sync_size & 0xFFFFFFF0) | (sync_direction << 2) | sync_for_cpu);
        if ( write(fd, "1", 1) == -1 ) {
            close(fd);
            return 0;
        }
        close(fd);
        return
    }

    // sync_for_cpu
    static int SyncForCpu_(std::string fname, std::string name, std::size_t sync_offset, std::size_t sync_size, unsigned int sync_direction, unsigned long  sync_for_cpu)
    {
        fname += name;
        fname += "/sync_for_cpu";
        int fd = open(fname.c_str(), O_WRONLY);
        if ( fd == -1) {
            return 0;
        }
        unsigned char   attr[1024];
        sprintf(attr, "0x%08X%08X", (sync_offset & 0xFFFFFFFF), (sync_size & 0xFFFFFFF0) | (sync_direction << 2) | sync_for_cpu);
        if ( write(fd, attr, strlen(attr)) == -1 ) {
            close(fd);
            return 0;
        }
        close(fd);
        return 1;
    }
    */

    // sync_for_device
    static int SyncForDevice_(std::string fname, std::string name)
    {
        fname += name;
        fname += "/sync_for_cpu";
        int fd  = open(fname.c_str(), O_WRONLY);
        if ( fd == -1) {
            return 0;
        }
        if ( write(fd, "1", 1) != 1 ) {
            close(fd);
            return 0;
        }
        return 1;
    }

    int SyncForDevice_(std::string fname)
    {
        return SyncForDevice_(fname, m_name);
    }

    /*
    // sync_for_device
    static bool SyncForDevice_(std::string fname, std::string name, std::size_t sync_offset, std::size_t sync_size, unsigned int sync_direction, unsigned long  sync_for_cpu)
    {
        fname += name;
        fname += "/sync_for_device";
        if ((fd  = open(fname.c_str(), O_WRONLY)) != -1) {
            sprintf(attr, "0x%08X%08X", (sync_offset & 0xFFFFFFFF), (sync_size & 0xFFFFFFF0) | (sync_direction << 2) | sync_for_cpu);
            write(fd, attr, strlen(attr));
            close(fd);
            return true;
        }
        return false;
    }
    */

public:
    UiomemAccessor_() {}

    UiomemAccessor_(const char* name, std::size_t offset=0) {
        auto size = GetPhysSize(name);
        if ( size > 0 ) {
            m_phys_addr = GetPhysAddr(name);
            Open(name, size, offset);
        }
    }

    ~UiomemAccessor_() {}

    std::uintptr_t GetPhysAddr(void)
    {
        return m_phys_addr;
    }
    
    std::shared_ptr<AccessorUiomemManager> GetUiomemManager(void)
    {
        return std::dynamic_pointer_cast<AccessorUiomemManager>(this->m_mem_manager);
    }

    

    // get phys_addr
    static std::uintptr_t GetPhysAddr(const char* name)
    {
        std::uintptr_t addr;
        if ( (addr = GetPhysAddr_("/sys/class/uiomem/", name)) > 0 ) { return addr; }
        return 0;
    }

    static std::size_t GetPhysSize(const char* name)
    {
        std::size_t size;
        if ( (size = GetPhysSize_("/sys/class/uiomem/", name)) > 0 ) { return size; }
        return 0;
    }

    int SyncForDevice(void)
    {
        return SyncForDevice_("/sys/class/uiomem/");
    }
};



using UiomemAccessor   = UiomemAccessor_<>;
using UiomemAccessor64 = UiomemAccessor_<std::uint64_t>;
using UiomemAccessor32 = UiomemAccessor_<std::uint32_t>;
using UiomemAccessor16 = UiomemAccessor_<std::uint16_t>;
using UiomemAccessor8  = UiomemAccessor_<std::uint8_t>;

}

#endif  // __RYUZ__JELLY__UIOMEM_ACCESSOR_H__


// end of file
