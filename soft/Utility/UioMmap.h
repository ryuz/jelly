// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2020 by Ryuji Fuchikami
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef	__RYUZ__JELLY__UIO_MEMMAP_H__
#define	__RYUZ__JELLY__UIO_MEMMAP_H__


#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <errno.h>


class UioMmap
{
public:
	UioMmap()
	{
		m_fd   = -1;
		m_id   = -1;
		m_addr = MAP_FAILED;
		m_size = 0;
	}
	
	UioMmap(const char* name, size_t size)
	{
		m_fd   = 0;
		m_addr = NULL;
		Map(name, size);
	}
	
	UioMmap(int id, size_t size)
	{
		m_fd   = 0;
		m_addr = NULL;
		Map(id, size);
	}
	
	
	~UioMmap()
	{
		Unmap();
	}
	
	
	bool Map(const char* name, size_t size)
	{
		char	dev_fname[32];
		char	uio_name[64];
		FILE	*fp;
		
		for ( int i = 0; i < 256; i++ ) {
			// read name
			snprintf(dev_fname, 32, "/sys/class/uio/uio%d/name", i);
			if ( (fp = fopen(dev_fname, "r")) == NULL ) {
				return false;
			}
			fgets(uio_name, 64, fp);
			fclose(fp);
			
			// chomp
			int len = strlen(uio_name);
			if ( len > 0 && uio_name[len-1] == '\n' ) {
				uio_name[len-1] = '\0';
			}
			
			// compare
			if ( strcmp(uio_name, name) == 0 ) {
				return Map(i, size);
			}
		}
		
		return false;
	}
	
	
	bool Map(int id, size_t size)
	{
		char	uio_dev_fname[16];
		snprintf(uio_dev_fname, 16, "/dev/uio%d", id);
		if ( (m_fd = open(uio_dev_fname, O_RDWR | O_SYNC)) < 0 ) {
			return false;
		}
		m_id = id;
		
		
		m_addr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
		if ( m_addr == MAP_FAILED ) {
	//		printf("mmap error\n");
			Unmap();
			return false;
		}
		m_size = size;
	    
	    return true;
	}
	
	
	void Unmap(void)
	{
		if ( m_addr != MAP_FAILED ) {
			munmap(m_addr, m_size);
			m_addr = NULL;
			m_size = 0;
		}
		
		if ( m_fd != 0 ) {
			close(m_fd);
			m_fd = -1;
		}
		
		m_id = -1;
	}
	
	
	bool IsMapped(void)
	{
		return (m_addr != NULL);
	}
	
	
	int GetUioId(void)
	{
		return m_id;
	}
	
	void* GetAddress(void)
	{
		return m_addr;
	}
	
	
	void WriteWord32(long addr, uint32_t data)
	{
		*(volatile uint32_t *)GetOffsetAddr(addr) = data;
	}
	
	uint32_t ReadWord32(long addr)
	{
		return *(volatile uint32_t *)GetOffsetAddr(addr);
	}
	
	void WriteWord64(long addr, uint64_t data)
	{
		*(volatile uint64_t *)GetOffsetAddr(addr) = data;
	}
	
	uint64_t ReadWord64(long addr)
	{
		return *(volatile uint64_t *)GetOffsetAddr(addr);
	}
	
	
protected:
	void* GetOffsetAddr(size_t offset)
	{
		return (void *)((uint8_t *)m_addr + offset);
	}
	
	int		m_fd;
	int		m_id;
	void*	m_addr;
	size_t	m_size;
};


#endif	// __RYUZ__JELLY__UIO_MEMMAP_H__


// end of file
