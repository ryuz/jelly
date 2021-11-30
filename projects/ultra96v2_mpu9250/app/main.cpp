// ---------------------------------------------------------------------------
//  udmabuf テスト
//                                  Copyright (C) 2015-2020 by Ryuz
//                                  https://github.com/ryuz/
// ---------------------------------------------------------------------------


#include <iostream>
#include <vector>
#include <cstdint>

#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"

using namespace jelly;


#define REG_I2C_STATUS      0x0
#define REG_I2C_CONTROL     0x1
#define REG_I2C_SEND        0x2
#define REG_I2C_RECV        0x3
#define REG_I2C_DIVIDER     0x4

#define I2C_CONTROL_START   0x01
#define I2C_CONTROL_STOP    0x02
#define I2C_CONTROL_ACK     0x04
#define I2C_CONTROL_NAK     0x08
#define I2C_CONTROL_RECV    0x10


class JellyI2c {
protected:
    UioAccessor m_uio;
    MemAccessor m_acc;

    void Wait(void) {
        if ( 0 && m_uio.IsMapped() ) {
            m_uio.SetIrqEnable(true);
            m_uio.WaitIrq();
        }
        else {
            while ( (m_acc.ReadReg(REG_I2C_STATUS) & 1) != 0 )
                ;
        }
    }

public:
    JellyI2c(MemAccessor acc, UioAccessor uio)
    {
        m_acc = acc;
        m_uio = uio;
    }

    void SetDivider(int div)
    {
        m_acc.WriteReg(REG_I2C_DIVIDER, div);
    }

    bool Write(std::uint8_t addr, std::vector<std::uint8_t> data)
    {
        bool nak = false;

        // start
        m_acc.WriteReg(REG_I2C_CONTROL, I2C_CONTROL_START);
        Wait();
        
        // send
        m_acc.WriteReg(REG_I2C_SEND, addr<<1);
        Wait();

        for ( auto c: data ) {
            // ack check
            if ( (m_acc.ReadReg(REG_I2C_STATUS) & 0xf) != 0 ) {
                nak = true;
                break;
            }

            // send
            m_acc.WriteReg(REG_I2C_SEND, c);
            Wait();
        }

        // stop
        m_acc.WriteReg(REG_I2C_CONTROL, I2C_CONTROL_STOP);
        Wait();

        return true;
    }

    std::vector<std::uint8_t> Read(std::uint8_t addr, int len)
    {
        std::vector<std::uint8_t> data;

        // start
        m_acc.WriteReg(REG_I2C_CONTROL, I2C_CONTROL_START);
        Wait();
        
        // send
        m_acc.WriteReg(REG_I2C_SEND, addr<<1|1);
        Wait();

        if ( (m_acc.ReadReg(REG_I2C_STATUS) & 0xf) != 0 ) {
            return data;
        }

        for ( int i = 0; i < len; ++i ) {
            // read
            m_acc.WriteReg(REG_I2C_CONTROL, I2C_CONTROL_RECV);
            Wait();
            data.push_back((std::uint8_t)m_acc.ReadReg(REG_I2C_RECV));

            m_acc.WriteReg(REG_I2C_CONTROL, i+1 < len ? I2C_CONTROL_ACK : I2C_CONTROL_NAK);
            Wait();
        }

        return data;
    }

};



#define MPU9250_ADDRESS     0x68    // 7bit address
#define AK8963_ADDRESS      0x0C    // Address of magnetometer


int main()
{
    std::cout << "--- i2c test ---" << std::endl;

    // mmap uio
    std::cout << "\nuio open" << std::endl;
    UioAccessor uio_acc("uio_pl_peri", 0x08000000);
    if ( !uio_acc.IsMapped() ) {
        std::cout << "uio_pl_peri mmap error" << std::endl;
        return 1;
    }

    // UIOの中をさらにコアごとに割り当て
    auto i2c_acc = uio_acc.GetAccessor(0x0000);
    auto led_acc = uio_acc.GetAccessor(0x0800);

    // I2C
//    i2c_acc.WriteReg(REG_I2C_DIVIDER, 100);

    JellyI2c i2c(i2c_acc, uio_acc);
    i2c.SetDivider(20);
    i2c.Write(MPU9250_ADDRESS, {0x75});
    auto who_am_i = i2c.Read(MPU9250_ADDRESS, 1);
    if ( who_am_i.size() != 1 ) {
        std::cout << "read error : WHO_AM_I" << std::endl;
        return 1;
    }
    printf("WHO_AM_I(exp:0x71):0x%02x\n", who_am_i[0]);
    return 0;

    i2c.Write(MPU9250_ADDRESS, {0x6b});
    i2c.Write(MPU9250_ADDRESS, {0x00});
    i2c.Write(MPU9250_ADDRESS, {0x37});
    i2c.Write(MPU9250_ADDRESS, {0x02});
    return 0;


    std::cout << "start" << std::endl;
    i2c_acc.WriteReg(REG_I2C_CONTROL, I2C_CONTROL_START);
    while ( (i2c_acc.ReadReg(REG_I2C_STATUS) & 1) != 0 ) ;
    
    std::cout << "send" << std::endl;
    i2c_acc.WriteReg(REG_I2C_SEND, 0x68<<1);
    while ( (i2c_acc.ReadReg(REG_I2C_STATUS) & 1) != 0 ) ;

//    std::cout << i2c_acc.ReadReg(REG_I2C_STATUS) << std::endl;

    std::cout << "stop" << std::endl;
    i2c_acc.WriteReg(REG_I2C_CONTROL, I2C_CONTROL_STOP);
    while ( (i2c_acc.ReadReg(REG_I2C_STATUS) & 1) != 0 ) ;

    return 0;

    // LED点滅
    std::cout << "\n<LED test>" << std::endl;
    for ( int i = 0; i < 3; i++) {
        std::cout << "LED : ON" << std::endl;
        led_acc.WriteReg(0, 1);
        sleep(1);

        std::cout << "LED : OFF" << std::endl;
        led_acc.WriteReg(0, 0);
        sleep(1);
    }

    return 0;
}

// end of file
