// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__UIO_ACCESS_H__
#define	__RYUZ__JELLY__UIO_ACCESS_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>

#include "MmapAccess.h"


namespace jelly {

// memory manager
class AccessUioManager : public AccessMmapManager
{
	using _super = AccessMmapManager;

protected:
	AccessUioManager(const char* fname, std::size_t size) { Mmap(fname, size); }

public:
	~AccessUioManager() { Munmap(); }
	
	static std::shared_ptr<AccessUioManager> Create(const char* fname, size_t size)
    {
        return std::shared_ptr<AccessUioManager>(new AccessUioManager(fname, size));
    }

protected:
	bool Mmap(const char* fname, std::size_t size)
	{
		// open
		int	fd;
		if ( (fd = open(fname, O_RDWR | O_SYNC)) < 0 ) {
			return false;
		}

		// mmap
		if ( !_super::Mmap(fd, size) ) {
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
class UioAccess_ : public MmapAccess_<DataType, MemAddrType, RegAddrType>
{
protected:
	bool Open(const char* dev_fname, std::size_t size, std::size_t offset)
	{
		auto uio_manager = AccessUioManager::Create(dev_fname, size);
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
	UioAccess_() {}

	UioAccess_(int id, std::size_t size, std::size_t offset=0) {
		Open(id, size, offset);
	}

	UioAccess_(const char* name, std::size_t size, std::size_t offset=0) {
		int id = SearchDeviceId(name);
		if ( id > 0 ) {
			Open(id, size, offset);
		}
	}

	~UioAccess_()	{}


	
	std::shared_ptr<AccessUioManager> GetUioManager(void)
	{
		return std::dynamic_pointer_cast<AccessUioManager>(this->m_mem_manager);
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
};


#if 0
template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class UioAccess_ : public MmapAccess_<DataType, MemAddrType, RegAddrType>
{
	using _super = MmapAccess_<DataType, MemAddrType, RegAddrType>;

public:
	UioAccess_() {}
	UioAccess_(int id, size_t size) { Mmap(id, size);	}
	UioAccess_(const char* name, size_t size) { Mmap(name, size); }
	~UioAccess_()	{ Munmap(); }
	
	int SearchDeviceId(const char* name)
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

	bool Mmap(const char* name, size_t size)
	{
		int id = SearchDeviceId(name);
		if ( id < 0 ) {
			return false;
		}
		return Mmap(id, size);
	}
	
	bool Mmap(int id, size_t size)
	{
		// open
		int		fd;
		char	dev_fname[16];
		snprintf(dev_fname, 16, "/dev/uio%d", id);
		if ( (fd = open(dev_fname, O_RDWR | O_SYNC)) < 0 ) {
			return false;
		}

		// mmap
		if ( !_super::Mmap(fd, size) ) {
			close(fd);
			return false;
		}

		m_id = id;
		
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
		m_id = -1;
	}
};
#endif

using UioAccess   = UioAccess_<>;
using UioAccess64 = UioAccess_<std::uint64_t>;
using UioAccess32 = UioAccess_<std::uint32_t>;
using UioAccess16 = UioAccess_<std::uint16_t>;
using UioAccess8  = UioAccess_<std::uint8_t>;

}

#endif	// __RYUZ__JELLY__MMAP_ACCESS_H__


// end of file
