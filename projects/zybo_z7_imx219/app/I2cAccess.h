

#ifndef	__RYUZ__JELLY__I2C_ACCESS_H__
#define	__RYUZ__JELLY__I2C_ACCESS_H__


#include <sys/ioctl.h>
#include <linux/i2c-dev.h>


class I2cAccess
{
public:
	I2cAccess()
	{
		m_fd = -1;
	}
	
	I2cAccess(const char* fname, unsigned char dev)
	{
		m_fd = -1;
		Open(fname, dev);
	}
	
	~I2cAccess()
	{
		Close();
	}
	
	bool Open(const char* fname, unsigned char dev)
	{
		Close();
		
		m_fd = open(fname, O_RDWR);
		if ( m_fd < 0 ) {
			return false;
		}
		
		ioctl(m_fd, I2C_SLAVE, dev);
		
		return true;
	}
	
	void Close(void)
	{
		if ( m_fd >= 0 ) {
			close(m_fd);
		}
	}
	
	
	bool IsOpend(void)
	{
		return (m_fd >= 0);
	}
	
	
	bool SetDeviceAddress(unsigned char dev)
	{
		if ( !IsOpend() ) { return -1; }
		ioctl(m_fd, I2C_SLAVE, dev);
		return true;
	}
	
	
	ssize_t Write(const void* buf, size_t len)
	{
		if ( !IsOpend() ) { return -1; }
		ssize_t ret = write(m_fd, buf, len);
//		printf("I2C write : %d\n", ret);
		return ret;
	}
	
	ssize_t Read(void* buf, size_t len)
	{
		if ( !IsOpend() ) { return -1; }
		ssize_t ret = read(m_fd, buf, len);
//		printf("I2C read : %d\n", ret);
		return ret;
	}
	
	
	int WriteAddr16(unsigned short addr, const void* data, size_t len)
	{
		unsigned char buf[2+len];
		
		buf[0] = ((addr >> 8) & 0xff);
		buf[1] = ((addr >> 0) & 0xff);
		memcpy(&buf[2], data, len);
		Write(buf, 2+len);
		
		return len;
	}
	
	
	ssize_t ReadAddr16(unsigned short addr, void* buf, size_t len)
	{
		unsigned char addr_buf[2];
		
		addr_buf[0] = ((addr >> 8) & 0xff);
		addr_buf[1] = ((addr >> 0) & 0xff);
		Write(addr_buf, 2);
		Read(buf, len);
		
		return len;
	}
	
	
	ssize_t WriteAddr16Byte(unsigned short addr, unsigned char data)
	{
		return WriteAddr16(addr, &data, 1);
	}
	
	int WriteAddr16Word(unsigned short addr, unsigned short data)
	{
		unsigned char buf[2];
	 	buf[0] = ((data >> 8) & 0xff);
	 	buf[1] = ((data >> 0) & 0xff);
		return WriteAddr16(addr, buf, 2);
	}
	
	
	unsigned char ReadAddr16Byte(unsigned short addr)
	{
		unsigned char buf[1];
		ReadAddr16(addr, buf, 1);
		return buf[0];
	}
	
	
protected:
	int	m_fd;
};



#endif	// __RYUZ__JELLY__I2C_ACCESS_H__

