// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__MMAP_ACCESS_H__
#define	__RYUZ__JELLY__MMAP_ACCESS_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>

#include "MemAccess.h"


namespace jelly {


// memory manager
class AccessMmapManager : public AccessMemManager
{
protected:
	bool	m_mapped = false;
	int		m_fd   = 0;

	AccessMmapManager() {}
	AccessMmapManager(int fd, size_t size) { Mmap(fd, size); }

public:
	~AccessMmapManager() { Munmap(); }
	
	static std::shared_ptr<AccessMmapManager> Create(int fd, size_t size = 0)
    {
        return std::shared_ptr<AccessMmapManager>(new AccessMmapManager(fd, size));
    }

	bool IsMapped(void) { return m_mapped; }
	int GetFd(void)		{ return m_fd; }

protected:
	bool Mmap(int fd, size_t size)
	{
		void* ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
		if ( ptr == MAP_FAILED ) {
			return false;
		}

		m_mapped = true;
		m_fd     = fd;
		m_ptr    = ptr;
		m_size   = size;
	    
	    return true;
	}
	
	void Munmap(void)
	{
		if ( m_mapped ) {
			munmap(m_ptr, m_size);
			m_fd   = 0;
			m_size = 0;
			m_ptr  = nullptr;
			m_size = 0;
		}
	}
};


template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class MmapAccess_ : public MemAccess_<DataType, MemAddrType, RegAddrType>
{
public:
	MmapAccess_() {}
	MmapAccess_(int fd, std::size_t size, std::size_t offset=0) {
		auto mmap_manager = AccessMmapManager::Create(fd, size);
		if ( mmap_manager->IsMapped() ) {
			this->SetMemManager(mmap_manager, offset);
		}
	}
	~MmapAccess_()	{}
	
	std::shared_ptr<AccessMmapManager> GetMmapManager(void)
	{
		return std::dynamic_pointer_cast<AccessMmapManager>(this->m_mem_manager);
	}

	bool IsMapped(void) { 
		auto mmap_manager = GetMmapManager();
		if ( !mmap_manager ) {
			return false;
		}
		return mmap_manager->IsMapped();
	}

	int GetFd(void) {
		auto mmap_manager = GetMmapManager();
		if ( !mmap_manager ) {
			return 0;
		}
		return GetMmapManager()->GetFd();
	}
};

using MmapAccess   = MmapAccess_<>;
using MmapAccess64 = MmapAccess_<std::uint64_t>;
using MmapAccess32 = MmapAccess_<std::uint32_t>;
using MmapAccess16 = MmapAccess_<std::uint16_t>;
using MmapAccess8  = MmapAccess_<std::uint8_t>;

}

#endif	// __RYUZ__JELLY__MMAP_ACCESS_H__


// end of file
