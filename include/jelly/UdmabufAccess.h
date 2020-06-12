// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__UDMABUF_ACCESS_H__
#define	__RYUZ__JELLY__UDMABUF_ACCESS_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <string>
#include <errno.h>

#include "UioAccess.h"


namespace jelly {

// memory manager
using AccessUdmabufManager = AccessUioManager;


template <typename DataType=std::uintptr_t, typename MemAddrType=std::uintptr_t, typename RegAddrType=std::uintptr_t>
class UdmabufAccess_ : public UioAccess_<DataType, MemAddrType, RegAddrType>
{
protected:
	std::intptr_t	m_phys_addr = 0;

	bool Open(const char* name, std::size_t size, std::size_t offset)
	{
		std::string fname = "/dev/";
		fname += name;
		auto udmabuf_manager = AccessUdmabufManager::Create(fname.c_str(), size);
		if ( udmabuf_manager->IsMapped() ) {
			this->SetMemManager(udmabuf_manager, offset);
			return true;
		}
		return false;
	}

public:
	UdmabufAccess_() {}

	UdmabufAccess_(const char* name, std::size_t offset=0) {
		auto size = GetPhysSize(name);
		if ( size > 0 ) {
			m_phys_addr = GetPhysAddr(name);
			Open(name, size, offset);
		}
	}

	~UdmabufAccess_()	{}

	std::intptr_t GetPhysAddr(void)
	{
		return m_phys_addr;
	}
	
	std::shared_ptr<AccessUdmabufManager> GetUdmabufManager(void)
	{
		return std::dynamic_pointer_cast<AccessUdmabufManager>(this->m_mem_manager);
	}

	// get phys_addr
	static std::uintptr_t GetPhysAddr(const char* name)
	{
		std::string fname = "/sys/class/udmabuf/";
		fname += name;
		fname += "/phys_addr";
		FILE *fp;
		if ( (fp = fopen(fname.c_str(), "r")) == NULL ) {
			return 0;
		}
		char buf[32];
		fgets(buf, 32, fp);
		fclose(fp);
		return static_cast<std::intptr_t>(strtoull(buf, NULL, 16));
	}

	static std::size_t GetPhysSize(const char* name)
	{
		std::string fname = "/sys/class/udmabuf/";
		fname += name;
		fname += "/size";
		FILE *fp;
		if ( (fp = fopen(fname.c_str(), "r")) == NULL ) {
			return 0;
		}
		char buf[32];
		fgets(buf, 32, fp);
		fclose(fp);
		return static_cast<std::size_t>(strtoull(buf, NULL, 0));
	}
};



using UdmabufAccess   = UdmabufAccess_<>;
using UdmabufAccess64 = UdmabufAccess_<std::uint64_t>;
using UdmabufAccess32 = UdmabufAccess_<std::uint32_t>;
using UdmabufAccess16 = UdmabufAccess_<std::uint16_t>;
using UdmabufAccess8  = UdmabufAccess_<std::uint8_t>;

}

#endif	// __RYUZ__JELLY__UDMABUF_ACCESS_H__


// end of file
