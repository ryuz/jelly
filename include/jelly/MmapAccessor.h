// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__MMAP_ACCESSOR_H__
#define	__RYUZ__JELLY__MMAP_ACCESSOR_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>

#include "MemAccessor.h"


namespace jelly {


// memory manager
class AccessorMmapManager : public AccessorMemManager
{
protected:
	bool	m_mapped = false;
	int		m_fd   = 0;

	AccessorMmapManager() {}
	AccessorMmapManager(int fd, size_t size, off_t offset=0) { Mmap(fd, size, offset); }

public:
	~AccessorMmapManager() { Munmap(); }
	
	static std::shared_ptr<AccessorMmapManager> Create(int fd, size_t size = 0)
    {
        return std::shared_ptr<AccessorMmapManager>(new AccessorMmapManager(fd, size));
    }

	bool IsMapped(void) { return m_mapped; }
	int GetFd(void)		{ return m_fd; }

protected:
	bool Mmap(int fd, size_t size, off_t offset=0)
	{
		void* ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, offset);
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
class MmapAccessor_ : public MemAccessor_<DataType, MemAddrType, RegAddrType>
{
public:
	MmapAccessor_() {}
	MmapAccessor_(int fd, std::size_t size, std::size_t offset=0) {
		auto mmap_manager = AccessorMmapManager::Create(fd, size);
		if ( mmap_manager->IsMapped() ) {
			this->SetMemManager(mmap_manager, offset);
		}
	}
	~MmapAccessor_()	{}
	
	std::shared_ptr<AccessorMmapManager> GetMmapManager(void)
	{
		return std::dynamic_pointer_cast<AccessorMmapManager>(this->m_mem_manager);
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

using MmapAccessor   = MmapAccessor_<>;
using MmapAccessor64 = MmapAccessor_<std::uint64_t>;
using MmapAccessor32 = MmapAccessor_<std::uint32_t>;
using MmapAccessor16 = MmapAccessor_<std::uint16_t>;
using MmapAccessor8  = MmapAccessor_<std::uint8_t>;

}

#endif	// __RYUZ__JELLY__MMAP_ACCESSOR_H__


// end of file
