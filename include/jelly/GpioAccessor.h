// --------------------------------------------------------------------------
//  Linux 用 GPIO アクセス ラッパークラス
//
//                                     Copyright (C) 2020 by Ryuz
// --------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__GPIO_ACCESSOR__H__
#define __RYUZ__JELLY__GPIO_ACCESSOR__H__

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string>

namespace jelly {


class GpioAccessor
{
protected:
    int     m_gpio;
    bool    m_unexport;

public:
    GpioAccessor(int gpio, bool auto_export=true)
    {
        m_gpio     = gpio;
        m_unexport = false;
        if ( auto_export ) {
            if ( !Exists() ) {
                m_unexport = true;
                Export();   // 存在していなければExport
            }
        }
    }
    
    ~GpioAccessor()
    {
        if ( m_unexport ) {
            Unexport();  // 最初に存在していなければ元に戻す
        }
    }

    bool Exists(void)
    {
        std::string path = "/sys/class/gpio/gpio" + std::to_string(m_gpio) + "/direction";
        int fd = open(path.c_str(), O_RDWR);
        if ( fd < 0 ) {
            return false;
        }
        close(fd);
        return true;
    }

    bool Export(void)
    {
        int fd = open("/sys/class/gpio/export", O_WRONLY);
        if ( fd < 0 ) {
            return false;
        }
        std::string gpio = std::to_string(m_gpio);
        write(fd, gpio.c_str(), gpio.length());
        close(fd);
        return true;
    } 

    bool Unexport(void)
    {
        int fd = open("/sys/class/gpio/unexport", O_WRONLY);
        if ( fd < 0 ) {
            return false;
        }
        std::string gpio = std::to_string(m_gpio);
        write(fd, gpio.c_str(), gpio.length());
        close(fd);
        return true;
    } 

    bool SetDirection(bool dir_output)
    {
        std::string path = "/sys/class/gpio/gpio" + std::to_string(m_gpio) + "/direction";
        int fd = open(path.c_str(), O_RDWR);
        if ( fd < 0 ) {
            return false;
        }
        if ( dir_output ) {
            write(fd, "out", 3);
        }
        else {
            write(fd, "in", 2);
        }
        close(fd);
        return true;
    }
    
    bool SetValue(int value)
    {
        std::string path = "/sys/class/gpio/gpio" + std::to_string(m_gpio) + "/value";
        int fd = open(path.c_str(), O_RDWR);
        if ( fd < 0 ) {
            return false;
        }
        if ( value == 0 ) {
            write(fd, "0", 1);
        }
        else if ( value == 1 ) {
            write(fd, "1", 1);
        }
        close(fd);
        return true;
    }

    int GetValue(void)
    {
        std::string path = "/sys/class/gpio/gpio" + std::to_string(m_gpio) + "/value";
        int fd = open(path.c_str(), O_RDWR);
        if ( fd < 0 ) {
            return -1;
        }
        char buf[1] = {};
        read(fd, buf, 1);
        close(fd);

        if ( buf[0] == '0' ) {
            return 0;
        }
        else if ( buf[0] == '1' ) {
            return 1;
        }
        return -1;
    }
};

}

#endif  // __RYUZ__JELLY__GPIO_ACCESSOR__H__

// end of file
