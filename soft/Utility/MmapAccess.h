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


template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class MmapAccess_ : public MemAccess_<DataType, MemAddrType, RegAddrType>
{
protected:
	bool		m_mapped = false;
	int			m_fd   = 0;
	std::size_t	m_size = 0;

public:
	MmapAccess_() {}
	MmapAccess_(int fd, size_t size) {	Mmap(fd, size);	}
	~MmapAccess_()	{ Munmap(); }
	
	
	bool IsMapped(void) 		{ return m_mapped; }
	int GetFd(void)				{ return m_fd; }
	std::size_t GetSize(void) 	{ return m_size; }
	

	bool Mmap(int fd, size_t size)
	{
		void* ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
		if ( ptr == MAP_FAILED ) {
			return false;
		}

		this->SetBasePtr(ptr);
		m_mapped = true;
		m_fd     = fd;
		m_size   = size;
	    
	    return true;
	}
	
	void Munmap(void)
	{
		if ( m_mapped ) {
			munmap(this->GetBasePtr(), m_size);
			this->SetBasePtr(nullptr);
			m_fd   = 0;
			m_size = 0;
		}
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
