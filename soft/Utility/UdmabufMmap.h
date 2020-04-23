// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__UDMABUF_MMAP_H__
#define	__RYUZ__JELLY__UDMABUF_MMAP_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <climits>
#include <cstdint>


#if ((ULONG_MAX) == (UINT_MAX))
#define __32BIT__
#else
#define __64BIT__
#endif


class UdmabufMmap
{
protected:
	int				m_fd = -1;
	void*			m_map_addr  = MAP_FAILED;
	std::size_t		m_size      = 0;
	std::intptr_t	m_phys_addr = 0;

public:
	UdmabufMmap()
	{
	}
	
	UdmabufMmap(const char* name)
	{
		Map(name);
	}
	
	~UdmabufMmap()
	{
		Unmap();
	}
	
	
	bool Map(const char* name)
	{
		char	fname[64];
		char	buf[64];
		FILE	*fp;

		// get phys_addr
		snprintf(fname, 64, "/sys/class/udmabuf/%s/phys_addr", name);
		if ( (fp = fopen(fname, "r")) == NULL ) {
			std::cout << fname << std::endl;
			return false;
		}
		fgets(buf, 64, fp);
		fclose(fp);
		m_phys_addr = (std::intptr_t)strtoull(buf, NULL, 16);
		std::cout << m_phys_addr << std::endl;

		// get size
		snprintf(fname, 64, "/sys/class/udmabuf/%s/size", name);
		if ( (fp = fopen(fname, "r")) == NULL ) {
			return false;
		}
		fgets(buf, 64, fp);
		fclose(fp);
		m_size = (std::size_t)strtoull(buf, NULL, 0);
		
		// open device
		snprintf(fname, 64, "/dev/%s", name);
		if ( (m_fd = open(fname, O_RDWR | O_SYNC)) < 0 ) {
			return false;
		}
		
		// memory map
		m_map_addr = mmap(NULL, m_size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
		if ( m_map_addr == MAP_FAILED ) {
	//		printf("mmap error\n");
			Unmap();
			return false;
		}
	    
	    return true;
	}
	
	
	void Unmap(void)
	{
		if ( m_map_addr != MAP_FAILED ) {
			munmap(m_map_addr, m_size);
			m_map_addr = MAP_FAILED;
			m_size = 0;
			m_phys_addr = 0;
		}
		
		if ( m_fd != 0 ) {
			close(m_fd);
			m_fd = -1;
		}
	}
	
	
	bool IsMapped(void)
	{
		return (m_map_addr != MAP_FAILED);
	}
	
	void* GetAddress(void)
	{
		return m_map_addr;
	}
	
	std::size_t GetSize(void)
	{
		return m_size;
	}
	
	std::intptr_t GetPhysicalAddress(void)
	{
		return m_phys_addr;
	}
	
	/*
	void WriteWord32(std::intptr_t offset, std::uint32_t data)
	{
		*(volatile std::uint32_t *)GetOffsetAddr(offset) = data;
	}
	
	uint32_t ReadWord32(size_t long offset)
	{
		return *(volatile std::uint32_t *)GetOffsetAddr(offset);
	}
	*/
	
protected:
	void* GetOffsetAddr(size_t offset)
	{
		return (void *)((uint8_t *)m_map_addr + offset);
	}
};


#endif	// __RYUZ__JELLY__UDMABUF_MMAP_H__


// end of file
