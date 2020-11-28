// --------------------------------------------------------------------------
//  Linux 用 I2C アクセス ラッパークラス
//
//                                     Copyright (C) 2020 by Ryuz
// --------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__I2C_ACCESSOR__H__
#define __RYUZ__JELLY__I2C_ACCESSOR__H__

#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

namespace jelly {

class I2cAccessor
{
protected:
    int m_fd;

public:
    I2cAccessor()
    {
        m_fd = -1;
    }
    
    I2cAccessor(const char* fname, unsigned char dev)
    {
        m_fd = -1;
        Open(fname, dev);
    }
    
    ~I2cAccessor()
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
//      printf("I2C write : %d\n", ret);
        return ret;
    }
    
    ssize_t Read(void* buf, size_t len)
    {
        if ( !IsOpend() ) { return -1; }
        ssize_t ret = read(m_fd, buf, len);
//      printf("I2C read : %d\n", ret);
        return ret;
    }
};

}

#endif  // __RYUZ__JELLY__I2C_ACCESSOR__H__

// end of file