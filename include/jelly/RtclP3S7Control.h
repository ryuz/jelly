// --------------------------------------------------------------------------
//  RTC-Lab Rpython300 + Spartan7 MIPI カメラ制御クラス
//
//                                     Copyright (C) 2025 by Ryuji Fuchikami
// --------------------------------------------------------------------------


#ifndef __JELLY__RTCL_P3S7_CONTORL__H__
#define __JELLY__RTCL_P3S7_CONTORL__H__


#include <algorithm>
#include <cmath>
#include <cstdint>
#include <unistd.h>

#include "I2cAccessor.h"

namespace jelly {


#define RTCL_P3S7_MODULE_ID             0x0000
#define RTCL_P3S7_MODULE_VERSION        0x0001
#define RTCL_P3S7_SENSOR_ENABLE         0x0004
#define RTCL_P3S7_SENSOR_READY          0x0008
#define RTCL_P3S7_RECVER_RESET          0x0010
#define RTCL_P3S7_ALIGN_RESET           0x0020
#define RTCL_P3S7_ALIGN_PATTERN         0x0022
#define RTCL_P3S7_ALIGN_STATUS          0x0028
#define RTCL_P3S7_CLIP_ENABLE           0x0040
#define RTCL_P3S7_CSI_MODE              0x0050
#define RTCL_P3S7_CSI_DT                0x0052
#define RTCL_P3S7_CSI_WC                0x0053
#define RTCL_P3S7_DPHY_CORE_RESET       0x0080
#define RTCL_P3S7_DPHY_SYS_RESET        0x0081
#define RTCL_P3S7_DPHY_INIT_DONE        0x0088
#define RTCL_P3S7_MMCM_CONTROL          0x00a0
#define RTCL_P3S7_PLL_CONTROL           0x00a1

#define RTCL_P3S7_MMCM_DRP              0x1000


class RtclP3S7ControlI2c
{
protected:
    I2cAccessor m_i2c;

    int         m_aoi_x    = 0;
    int         m_aoi_y    = 0;
    int         m_raw_bits = 10;
    int         m_width    = 640;
    int         m_height   = 132;

    float       m_framerate = 1000;
    float       m_exposure  = 1;
    float       m_gain = 1;

    bool        m_flip_h = false;
    bool        m_flip_v = false;

public:
    RtclP3S7ControlI2c() {}
    ~RtclP3S7ControlI2c() {
        Close();
    }

    bool Open(const char* fname, unsigned char dev)
    {
        if ( !m_i2c.Open(fname, dev) ) {
            return false;
        }
        return true;
    }

    void Close()
    {
        m_i2c.Close();
    }

    bool IsOpend(void)
    {
        return m_i2c.IsOpend();
    }

    std::uint16_t GetModuleId(void) {
        if ( !IsOpend() ) {
            return 0;
        }
        return i2c_read(RTCL_P3S7_MODULE_ID);
    }

    std::uint16_t GetModuleVersion(void) {
        if ( !IsOpend() ) {
            return 0;
        }
        return i2c_read(RTCL_P3S7_MODULE_VERSION);
    }

    std::uint16_t GetSensorId(void) {
        if ( !IsOpend() ) {
            return 0;
        }
        return spi_read(0);
    }

    // DPHY スピード設定
    bool SetDphySpeed(double speed)
    {
        if ( !IsOpend() ) {
            return false;
        }

        // MMCM set reset
        i2c_write(RTCL_P3S7_MMCM_CONTROL, 1);

        if ( speed >= 1250000000 ) {
            // D-PHY 1250Mbps用設定
            for ( std::size_t i = 0; i < sizeof(m_mmcm_tbl_1250) / sizeof(m_mmcm_tbl_1250[0]); i++ ) {
                i2c_write(RTCL_P3S7_MMCM_DRP + m_mmcm_tbl_1250[i][0], m_mmcm_tbl_1250[i][1]);
            }
        }
        else if ( speed >= 950000000 ) {
            // D-PHY 950Mbps用設定
            for ( std::size_t i = 0; i < sizeof(m_mmcm_tbl_950) / sizeof(m_mmcm_tbl_950[0]); i++ ) {
                i2c_write(RTCL_P3S7_MMCM_DRP + m_mmcm_tbl_950[i][0], m_mmcm_tbl_950[i][1]);
            }
        }
        else {
            return false;
        }

        // MMCM release reset
        i2c_write(RTCL_P3S7_MMCM_CONTROL, 0);
        usleep(100);

        return true;
    }

    bool SetDphyReset(bool reset) {
        if ( !IsOpend() ) {
            return false;
        }
        if ( reset ) {
            i2c_write(RTCL_P3S7_DPHY_SYS_RESET , 1);
            i2c_write(RTCL_P3S7_DPHY_CORE_RESET, 1);
        }
        else {
            i2c_write(RTCL_P3S7_DPHY_CORE_RESET, 0);
            i2c_write(RTCL_P3S7_DPHY_SYS_RESET , 0);
        }
        usleep(100);
        return true;
    }

    bool GetDphyInitDone(void) {
        if ( !IsOpend() ) { return false; }
        auto dphy_init_done = i2c_read(RTCL_P3S7_DPHY_INIT_DONE);
        return (dphy_init_done != 0);
    }

    bool SetSensorPowerEnable(bool enable) {
        if ( !IsOpend() ) { return false; }
        // センサー電源ON/OFF
        i2c_write(RTCL_P3S7_SENSOR_ENABLE, enable ? 1 : 0);
        usleep(50000);
        return true;
    }

    enum CameraMode {
        MODE_HIGH_SPEED = 0,
        MODE_CSI2 = 1,
    };

    bool SetCameraMode(CameraMode mode) {
        if ( !IsOpend() ) { return false; }
        i2c_write(RTCL_P3S7_CSI_MODE, mode);
        return true;
    }

    bool Setup() {
        if ( !IsOpend() ) { return false; }

        // SPI 初期設定
        spi_write(16, 0x0003);    // power_down  0:pwd_n, 1:PLL enable, 2: PLL Bypass
        spi_write(32, 0x0007);    // config0 (10bit mode) 0: enable_analog, 1: enabale_log, 2: select PLL
        spi_write( 8, 0x0000);    // pll_soft_reset, pll_lock_soft_reset
        spi_write( 9, 0x0000);    // cgen_soft_reset
        spi_write(34, 0x1);       // config0 Logic General Enable Configuration
        spi_write(40, 0x7);       // image_core_config0 
        spi_write(48, 0x1);       // AFE Power down for AFE’s
        spi_write(64, 0x1);       // Bias Bias Power Down Configuration
        spi_write(72, 0x2227);    // Charge Pump
        spi_write(112, 0x7);      // Serializers/LVDS/IO 
        spi_write(10, 0x0000);    // soft_reset_analog

        return true;
    }

    bool SetRoi0(int width, int height, int x=-1, int y=-1) {
        if ( !IsOpend() ) { return false; }

        // 正規化
        width  = std::max(width,   16);
        width  = std::min(width,  672);
        width &= ~0x0f;  // 16の倍数 
        height = std::max(width,    2);
        height = std::min(width,  512);
        height &= ~0x01; // 2の倍数

        int roi_x = (x & ~0x0f); // 16の倍数
        int roi_y = (y & ~0x01); // 2の倍数
        if ( x < 0 ) { roi_x = ((672 -  width) / 2) & ~0x0f; }
        if ( y < 0 ) { roi_y = ((512 - height) / 2) & ~0x01; }

        int x_start = roi_x / 8;
        int x_end   = x_start + width/8 - 1 ;
        int y_start = roi_y;
        int y_end   = y_start + height - 1;

        spi_write(256, (x_end << 8) | x_start);
        spi_write(257, y_start);
        spi_write(258, y_end);

        return true;
    }

protected:
    void i2c_write(std::uint16_t addr, std::uint16_t data) {
        addr <<= 1;
        addr |= 1;
        unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
        buf[0] = ((addr >> 8) & 0xff);
        buf[1] = ((addr >> 0) & 0xff);
        buf[2] = ((data >> 8) & 0xff);
        buf[3] = ((data >> 0) & 0xff);
        m_i2c.Write(buf, 4);
    }

    std::uint16_t i2c_read(std::uint16_t addr) {
        addr <<= 1;
        unsigned char buf[4] = {0x00, 0x00, 0x00, 0x00};
        buf[0] = ((addr >> 8) & 0xff);
        buf[1] = ((addr >> 0) & 0xff);
        m_i2c.Write(buf, 4);
        m_i2c.Read(buf, 2);
        return (std::uint16_t)buf[0] | (std::uint16_t)(buf[1] << 8);
    }

    void spi_write(std::uint16_t addr, std::uint16_t data) {
        addr |= (1 << 14);
        i2c_write(addr, data);
    }

    std::uint16_t spi_read(std::uint16_t addr) {
        addr |= (1 << 14);
        return i2c_read(addr);
    }

    // D-PHY 1250Mbps用設定
    static constexpr std::uint16_t m_mmcm_tbl_1250[][2] = {
        {0x06, 0x0041},
        {0x07, 0x0040},
        {0x08, 0x1041},
        {0x09, 0x0000},
        {0x0a, 0x9041},
        {0x0b, 0x0000},
        {0x0c, 0x0041},
        {0x0d, 0x0040},
        {0x0e, 0x0041},
        {0x0f, 0x0040},
        {0x10, 0x0041},
        {0x11, 0x0040},
        {0x12, 0x0041},
        {0x13, 0x0040},
        {0x14, 0x130d},
        {0x15, 0x0080},
        {0x16, 0x1041},
        {0x18, 0x0190},
        {0x19, 0x7c01},
        {0x1a, 0xffe9},
        {0x27, 0x0000},
        {0x28, 0x0100},
        {0x4e, 0x1108},
        {0x4f, 0x9000}
    };

    // D-PHY 950Mbps用設定
    static constexpr std::uint16_t m_mmcm_tbl_950[][2] = {
        {0x06, 0x0041},
        {0x07, 0x0040},
        {0x08, 0x1041},
        {0x09, 0x0000},
        {0x0a, 0x9041},
        {0x0b, 0x0000},
        {0x0c, 0x0041},
        {0x0d, 0x0040},
        {0x0e, 0x0041},
        {0x0f, 0x0040},
        {0x10, 0x0041},
        {0x11, 0x0040},
        {0x12, 0x0041},
        {0x13, 0x0040},
        {0x14, 0x124a},
        {0x15, 0x0080},
        {0x16, 0x1041},
        {0x18, 0x020d},
        {0x19, 0x7c01},
        {0x1a, 0xffe9},
        {0x27, 0x0000},
        {0x28, 0x0100},
        {0x4e, 0x9008},
        {0x4f, 0x0100}
    };
};

}

#endif  // __JELLY__RTCL_P3S7_CONTORL__H__


// end of file
