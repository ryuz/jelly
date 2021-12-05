// ---------------------------------------------------------------------------
//  Jelly  -- the signal processor system
//
//                                 Copyright (C) 2008-2021 by Ryuz
//                                 https://github.com/ryuz/
// ---------------------------------------------------------------------------


#ifndef __RYUZ__JELLY__JELLY_I2C__H__
#define __RYUZ__JELLY__JELLY_I2C__H__


#include <vector>
#include <cstdint>

#include "jelly/UioAccessor.h"
#include "jelly/JellyRegs.h"


namespace jelly {


class JellyI2c {
protected:
    UioAccessor m_uio;
    MemAccessor m_acc;

    void Wait(void) {
        if ( m_uio.IsMapped() ) {
            m_uio.SetIrqEnable(true);
            m_uio.WaitIrq();
        }
        else {
            while ( (m_acc.ReadReg(REG_PERIPHERAL_I2C_STATUS) & 1) != 0 )
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
        m_acc.WriteReg(REG_PERIPHERAL_I2C_DIVIDER, div);
    }

    bool Write(std::uint8_t addr, std::vector<std::uint8_t> data)
    {
        bool nak = false;

        // start
        m_acc.WriteReg(REG_PERIPHERAL_I2C_CONTROL, PERIPHERAL_I2C_CONTROL_START);
        Wait();
        
        // send
        m_acc.WriteReg(REG_PERIPHERAL_I2C_SEND, addr<<1);
        Wait();

        for ( auto c: data ) {
            // ack check
            if ( (m_acc.ReadReg(REG_PERIPHERAL_I2C_STATUS) & 0xf) != 0 ) {
                nak = true;
                break;
            }

            // send
            m_acc.WriteReg(REG_PERIPHERAL_I2C_SEND, c);
            Wait();
        }

        // stop
        m_acc.WriteReg(REG_PERIPHERAL_I2C_CONTROL, PERIPHERAL_I2C_CONTROL_STOP);
        Wait();

        return true;
    }

    std::vector<std::uint8_t> Read(std::uint8_t addr, int len)
    {
        std::vector<std::uint8_t> data;

        // start
        m_acc.WriteReg(REG_PERIPHERAL_I2C_CONTROL, PERIPHERAL_I2C_CONTROL_START);
        Wait();
        
        // send
        m_acc.WriteReg(REG_PERIPHERAL_I2C_SEND, addr<<1|1);
        Wait();

        if ( (m_acc.ReadReg(REG_PERIPHERAL_I2C_STATUS) & 0xf) != 0 ) {
            return data;
        }

        for ( int i = 0; i < len; ++i ) {
            // read
            m_acc.WriteReg(REG_PERIPHERAL_I2C_CONTROL, PERIPHERAL_I2C_CONTROL_RECV);
            Wait();
            data.push_back((std::uint8_t)m_acc.ReadReg(REG_PERIPHERAL_I2C_RECV));

            m_acc.WriteReg(REG_PERIPHERAL_I2C_CONTROL, i+1 < len ? PERIPHERAL_I2C_CONTROL_ACK : PERIPHERAL_I2C_CONTROL_NAK);
            Wait();
        }

        return data;
    }
};

}


#endif  // __RYUZ__JELLY__JELLY_I2C__H__


// end of file
