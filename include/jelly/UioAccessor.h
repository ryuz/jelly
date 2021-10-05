// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__UIO_ACCESSOR_H__
#define	__RYUZ__JELLY__UIO_ACCESSOR_H__


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
class AccessorUioManager : public AccessorMmapManager
{
	using _super = AccessorMmapManager;

protected:
	AccessorUioManager(const char* fname, std::size_t size, off_t offset, int flags) { Mmap(fname, size, offset, flags); }

public:
	~AccessorUioManager() { Munmap(); }
	
	static std::shared_ptr<AccessorUioManager> Create(const char* fname, size_t size, off_t offset=0, int flags=(O_RDWR | O_SYNC))
    {
        return std::shared_ptr<AccessorUioManager>(new AccessorUioManager(fname, size, offset, flags));
    }

    void SetIrqEnable(bool enable)
    {
        unsigned int  irq_en = enable ? 1 : 0;
        auto fd = _super::GetFd();
        write(fd, &irq_en, sizeof(irq_en));
    }
    
    unsigned int WaitIrq(void)
    {
        unsigned int    count = 0;
        auto fd = _super::GetFd();
        read(fd, &count, sizeof(count));
        return count;
    }

protected:
	bool Mmap(const char* fname, std::size_t size, off_t offset, int flags)
	{
		// open
		int	fd;
		if ( (fd = open(fname, flags)) < 0 ) {
			return false;
		}
        
		// mmap
		if ( !_super::Mmap(fd, size, offset) ) {
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
class UioAccessor_ : public MmapAccessor_<DataType, MemAddrType, RegAddrType>
{
protected:
	bool Open(const char* dev_fname, std::size_t size, std::size_t offset)
	{
		auto uio_manager = AccessorUioManager::Create(dev_fname, size);
		if ( uio_manager->IsMapped() ) {
			this->SetMemManager(uio_manager, offset);
			return true;
		}
		return false;
	}

	bool Open(int id, std::size_t size, std::size_t offset)
	{
		char	dev_fname[16];
		snprintf(dev_fname, 16, "/dev/uio%d", id);
		return Open(dev_fname, size, offset);
	}

public:
	UioAccessor_() {}

	UioAccessor_(int id, std::size_t size, std::size_t offset=0) {
		Open(id, size, offset);
	}

	UioAccessor_(const char* name, std::size_t size, std::size_t offset=0) {
		int id = SearchDeviceId(name);
		if ( id >= 0 ) {
			Open(id, size, offset);
		}
	}

	~UioAccessor_()	{}


	
	std::shared_ptr<AccessorUioManager> GetUioManager(void)
	{
		return std::dynamic_pointer_cast<AccessorUioManager>(this->m_mem_manager);
	}

	static int SearchDeviceId(const char* name)
	{
		for ( int i = 0; i < 256; i++ ) {
			// read name
			FILE	*fp;
			char	class_fname[32];
			snprintf(class_fname, 32, "/sys/class/uio/uio%d/name", i);
			if ( (fp = fopen(class_fname, "r")) == NULL ) {
				return -1;
			}
			char	uio_name[64];
			fgets(uio_name, 64, fp);
			fclose(fp);

			// chomp
			int len = strlen(uio_name);
			if ( len > 0 && uio_name[len-1] == '\n' ) {
				uio_name[len-1] = '\0';
			}
			
			// compare
			if ( strcmp(uio_name, name) == 0 ) {
				return i;
			}
		}
		return -1;
	}

    void SetIrqEnable(bool enable)
    {
        GetUioManager()->SetIrqEnable(enable);
    }

    unsigned int WaitIrq()
    {
        return GetUioManager()->WaitIrq();
    }

};


using UioAccessor   = UioAccessor_<>;
using UioAccessor64 = UioAccessor_<std::uint64_t>;
using UioAccessor32 = UioAccessor_<std::uint32_t>;
using UioAccessor16 = UioAccessor_<std::uint16_t>;
using UioAccessor8  = UioAccessor_<std::uint8_t>;

}

#endif	// __RYUZ__JELLY__MMAP_ACCESSOR_H__


// end of file
