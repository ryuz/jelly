// --------------------------------------------------------------------------
//  RaspberryPi Camera V2 (Sony IMX219) ZYBO-Z7 接続時制御クラス
//
//                                     Copyright (C) 2020 by Ryuji Fuchikami
// --------------------------------------------------------------------------


#ifndef __JELLY__IMX219_CONTORL__H__
#define __JELLY__IMX219_CONTORL__H__


#include <algorithm>
#include <cmath>
#include <cstdint>

#include "I2cAccessor.h"

namespace jelly {

// レジスタ定義
#define IMX219_MODEL_ID                    0x0000
#define IMX219_MODEL_ID_0                  0x0000
#define IMX219_MODEL_ID_1                  0x0001
#define IMX219_FABRICATION_TOP             0x0002
#define IMX219_LOT_ID_TOP_0                0x0004
#define IMX219_LOT_ID_TOP_1                0x0005
#define IMX219_LOT_ID_TOP_2                0x0006
#define IMX219_WAFER_NUM_TOP               0x0007
#define IMX219_CHIP_NUMBER_0               0x000D
#define IMX219_CHIP_NUMBER_1               0x000E
#define IMX219_PROCESS_VERSION             0x000F
#define IMX219_ROM_ID                      0x0011
#define IMX219_FRM_CNT                     0x0018
#define IMX219_PX_ORDER                    0x0019
#define IMX219_DT_PEDESTAL_0               0x001A
#define IMX219_DT_PEDESTAL_1               0x001B
#define IMX219_FRM_FMT_TYPE                0x0040
#define IMX219_FRM_FMT_SUBTYPE             0x0041
#define IMX219_FRM_FMT_DESC0_0             0x0042
#define IMX219_FRM_FMT_DESC0_1             0x0043
#define IMX219_FRM_FMT_DESC1_0             0x0044
#define IMX219_FRM_FMT_DESC1_1             0x0045
#define IMX219_FRM_FMT_DESC2_0             0x0046
#define IMX219_FRM_FMT_DESC2_1             0x0047
#define IMX219_MODE_SEL                    0x0100
#define IMX219_SW_RESET                    0x0103
#define IMX219_CORRUPTED_FRAME_STATUS      0x0104
#define IMX219_MASK_CORRUPTED_FRAMES       0x0105
#define IMX219_FAST_STANDBY_ENABLE         0x0106
#define IMX219_CSI_CH_ID                   0x0110
#define IMX219_CSI_SIG_MODE                0x0111
#define IMX219_CSI_LANE_MODE               0x0114
#define IMX219_TCLK_POST_0                 0x0118
#define IMX219_TCLK_POST_1                 0x0119
#define IMX219_THS_PREPARE_0               0x011A
#define IMX219_THS_PREPARE_1               0x011B
#define IMX219_THS_ZERO_MIN_0              0x011C
#define IMX219_THS_ZERO_MIN_1              0x011D
#define IMX219_THS_TRAIL_0                 0x011E
#define IMX219_THS_TRAIL_1                 0x011F
#define IMX219_TCLK_TRAIL_MIN_0            0x0120
#define IMX219_TCLK_TRAIL_MIN_1            0x0121
#define IMX219_TCLK_PREPARE_0              0x0122
#define IMX219_TCLK_PREPARE_1              0x0123
#define IMX219_TCLK_ZERO_0                 0x0124
#define IMX219_TCLK_ZERO_1                 0x0125
#define IMX219_TLPX_0                      0x0126
#define IMX219_TLPX_1                      0x0127
#define IMX219_DPHY_CTRL                   0x0128
#define IMX219_EXCK_FREQ                   0x012A
#define IMX219_EXCK_FREQ_0                 0x012A
#define IMX219_EXCK_FREQ_1                 0x012B
#define IMX219_TEMPERATURE_EN_VAL          0x0140
#define IMX219_READOUT_V_CNT_0             0x0142
#define IMX219_READOUT_V_CNT_1             0x0143
#define IMX219_FRAME_BANK_ENABLE           0x0150
#define IMX219_FRAME_BANK_FRM_CNT          0x0151
#define IMX219_FRAME_BANK_FAST_TRACKING    0x0152
#define IMX219_FRAME_DURATION_A            0x0154
#define IMX219_COMP_ENABLE_A               0x0155
#define IMX219_ANA_GAIN_GLOBAL_A           0x0157
#define IMX219_DIG_GAIN_GLOBAL_A           0x0158
#define IMX219_DIG_GAIN_GLOBAL_A_0         0x0158
#define IMX219_DIG_GAIN_GLOBAL_A_1         0x0159
#define IMX219_COARSE_INTEGRATION_TIME_A   0x015A
#define IMX219_COARSE_INTEGRATION_TIME_A_0 0x015A
#define IMX219_COARSE_INTEGRATION_TIME_A_1 0x015B
#define IMX219_SENSOR_MODE_A               0x015D
#define IMX219_FRM_LENGTH_A                0x0160
#define IMX219_FRM_LENGTH_A_0              0x0160
#define IMX219_FRM_LENGTH_A_1              0x0161
#define IMX219_LINE_LENGTH_A               0x0162
#define IMX219_LINE_LENGTH_A_0             0x0162
#define IMX219_LINE_LENGTH_A_1             0x0163
#define IMX219_X_ADD_STA_A                 0x0164
#define IMX219_X_ADD_STA_A_0               0x0164
#define IMX219_X_ADD_STA_A_1               0x0165
#define IMX219_X_ADD_END_A                 0x0166
#define IMX219_X_ADD_END_A_0               0x0166
#define IMX219_X_ADD_END_A_1               0x0167
#define IMX219_Y_ADD_STA_A                 0x0168
#define IMX219_Y_ADD_STA_A_0               0x0168
#define IMX219_Y_ADD_STA_A_1               0x0169
#define IMX219_Y_ADD_END_A                 0x016A
#define IMX219_Y_ADD_END_A_0               0x016A
#define IMX219_Y_ADD_END_A_1               0x016B
#define IMX219_X_OUTPUT_SIZE               0x016C
#define IMX219_X_OUTPUT_SIZE_0             0x016C
#define IMX219_X_OUTPUT_SIZE_1             0x016D
#define IMX219_Y_OUTPUT_SIZE               0x016E
#define IMX219_Y_OUTPUT_SIZE_0             0x016E
#define IMX219_Y_OUTPUT_SIZE_1             0x016F
#define IMX219_X_ODD_INC_A                 0x0170
#define IMX219_Y_ODD_INC_A                 0x0171
#define IMX219_IMG_ORIENTATION_A           0x0172
#define IMX219_BINNING_MODE_H_A            0x0174
#define IMX219_BINNING_MODE_V_A            0x0175
#define IMX219_BINNING_CAL_MODE_H_A        0x0176
#define IMX219_BINNING_CAL_MODE_V_A        0x0177
#define IMX219_RESERVE_0                   0x0188
#define IMX219_ANA_GAIN_GLOBAL_SHORT_A     0x0189
#define IMX219_COARSE_INTEG_TIME_SHORT_0_A 0x018A
#define IMX219_COARSE_INTEG_TIME_SHORT_1_A 0x018B
#define IMX219_CSI_DATA_FORMAT_A           0x018C
#define IMX219_CSI_DATA_FORMAT_0_A         0x018C
#define IMX219_CSI_DATA_FORMAT_1_A         0x018D
#define IMX219_LSC_ENABLE_A                0x0190
#define IMX219_LSC_COLOR_MODE_A            0x0191
#define IMX219_LSC_SELECT_TABLE_A          0x0192
#define IMX219_LSC_TUNING_ENABLE_A         0x0193
#define IMX219_LSC_WHITE_BALANCE_RG_0_A    0x0194
#define IMX219_LSC_WHITE_BALANCE_RG_1_A    0x0195
#define IMX219_RESERVE_1                   0x0196
#define IMX219_RESERVE_2                   0x0197
#define IMX219_LSC_TUNING_COEF_R_A         0x0198
#define IMX219_LSC_TUNING_COEF_GR_A        0x0199
#define IMX219_LSC_TUNING_COEF_GB_A        0x019A
#define IMX219_LSC_TUNING_COEF_B_A         0x019B
#define IMX219_LSC_TUNING_R_0_A            0x019C
#define IMX219_LSC_TUNING_R_1_A            0x019D
#define IMX219_LSC_TUNING_GR_0_A           0x019E
#define IMX219_LSC_TUNING_GR_1_A           0x019F
#define IMX219_LSC_TUNING_GB_0_A           0x01A0
#define IMX219_LSC_TUNING_GB_1_A           0x01A1
#define IMX219_LSC_TUNING_B_0_A            0x01A2
#define IMX219_LSC_TUNING_B_1_A            0x01A3
#define IMX219_LSC_KNOT_POINT_FORMAT_A     0x01A4
#define IMX219_VTPXCK_DIV                  0x0301
#define IMX219_VTSYCK_DIV                  0x0303
#define IMX219_PREPLLCK_VT_DIV             0x0304
#define IMX219_PREPLLCK_OP_DIV             0x0305
#define IMX219_PLL_VT_MPY                  0x0306
#define IMX219_PLL_VT_MPY_0                0x0306
#define IMX219_PLL_VT_MPY_1                0x0307
#define IMX219_OPPXCK_DIV                  0x0309
#define IMX219_OPSYCK_DIV                  0x030B
#define IMX219_PLL_OP_MPY                  0x030C
#define IMX219_PLL_OP_MPY_0                0x030C
#define IMX219_PLL_OP_MPY_1                0x030D
#define IMX219_RESERVE_3                   0x030E
#define IMX219_RESERVE_4                   0x0318
#define IMX219_RESERVE_5                   0x0319
#define IMX219_RESERVE_6                   0x031A
#define IMX219_RESERVE_7                   0x031B
#define IMX219_RESERVE_8                   0x031C
#define IMX219_RESERVE_9                   0x031D
#define IMX219_RESERVE_10                  0x031E
#define IMX219_RESERVE_11                  0x031F
#define IMX219_FLASH_STATUS                0x0321


class Imx219ControlI2c
{
protected:
    I2cAccessor m_i2c;

    bool        m_auto_stop = true;
    bool        m_running = false;

    bool        m_binning_h = true;
    bool        m_binning_v = true;
    int         m_aoi_x  = 0;
    int         m_aoi_y  = 0;
    int         m_width  = 640;
    int         m_height = 132;

    float       m_framerate = 1000;
    float       m_exposure  = 1;
    float       m_gain = 1;

    bool        m_flip_h = false;
    bool        m_flip_v = false;

    int         m_pll_vt_mpy  = 87;
    int         m_line_length = 3448;   // 固定値 
    int         m_frm_length  = 80;
    int         m_coarse_integration_time = 80-4;
    
    int         m_ana_gain_global = 0xE0;
    int         m_dig_gain_global = 0x0FFF;

public:
    ~Imx219ControlI2c() {}
    Imx219ControlI2c() {}
    Imx219ControlI2c(bool auto_stop) { m_auto_stop = auto_stop; }

    bool Open(const char* fname, unsigned char dev)
    {
        if ( !m_i2c.Open(fname, dev) ) {
            return false;
        }

        return Reset();
    }

    void Close(void)
    {
        // 動かしたまま close も許す
        if ( m_auto_stop ) {
            Stop();
        }

        return m_i2c.Close();
    }

    bool IsOpend(void)
    {
        return m_i2c.IsOpend();
    }

    int GetModelId()
    {
        return I2cRead16bit(IMX219_MODEL_ID);
    }

    bool Reset(void)
    {
        if ( !IsOpend() ) { return false; }
        
        // ソフトリセット
        I2cWrite8bit(IMX219_SW_RESET, 0x01);
        usleep(100);

        // 初期設定
        I2cWrite8bit(IMX219_CSI_LANE_MODE, 0x01);           // 03: 4Lane, 01: 2Lane
        I2cWrite8bit(IMX219_DPHY_CTRL, 0x00);               // MIPI Global timing setting (0: auto mode, 1: manual mode)
        I2cWrite16bit(IMX219_EXCK_FREQ, 0x1800);            // INCK frequency [MHz] 24.00MHz

        I2cWrite16bit(IMX219_CSI_DATA_FORMAT_A, 0x0A0A);    // CSI-2 data format(0x0808:RAW8, 0x0A0A: RAW10)
        I2cWrite8bit(IMX219_VTPXCK_DIV, 0x05);              // vt_pix_clk_div
        I2cWrite8bit(IMX219_VTSYCK_DIV, 0x01);              // vt_sys_clk_div
        I2cWrite8bit(IMX219_PREPLLCK_VT_DIV, 0x03);         // pre_pll_clk_vt_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        I2cWrite8bit(IMX219_PREPLLCK_OP_DIV, 0x03);         // pre_pll_clk_op_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        I2cWrite16bit(IMX219_PLL_VT_MPY, m_pll_vt_mpy);     // pll_vt_multiplier
        I2cWrite8bit(IMX219_OPPXCK_DIV, 0x0A);              // op_pix_clk_div
        I2cWrite8bit(IMX219_OPSYCK_DIV, 0x01);              // op_sys_clk_div
        I2cWrite16bit(IMX219_PLL_OP_MPY, 0x0072);           // pll_op_multiplier

        return true;
    }
    
    bool Start(void)
    {
        if ( !IsOpend() ) { return false; }
        I2cWrite8bit(IMX219_MODE_SEL, 0x01);    // mode_select [4:0] 0: SW standby, 1: Streaming
        m_running = true;
        return true;
    }

    bool Stop(void)
    {
        if ( !IsOpend() ) { return false; }
        I2cWrite8bit(IMX219_MODE_SEL, 0x00);    // mode_select [4:0] 0: SW standby, 1: Streaming
        m_running = false;
        return true;
    }

    bool SetPixelClock(double freq)
    {
        if ( freq <= 91000000 ) {
            m_pll_vt_mpy = 57;
        }
        else {
            m_pll_vt_mpy = 87;
        }
        return true;
    }
    
    double GetPixelClock(void)
    {
        return 8000000.0 * m_pll_vt_mpy / 5.0;
    }

    bool SetGain(double db)
    {
        if ( !IsOpend() ) { return false; }

        db = std::max(db, 0.0);
        db = std::min(db, 20.57);
        double gain = std::pow(10, db/20.0);
        m_ana_gain_global = (int)(256 * ((gain - 1) / gain));
        I2cWrite8bit(IMX219_ANA_GAIN_GLOBAL_A, m_ana_gain_global);

        return true;
    }

    double GetGain(void)
    {
        double gain = 256.0 / (256 - m_ana_gain_global);
        return 20.0 * std::log10(gain);
    }

    bool SetDigitalGain(double db)
    {
        if ( !IsOpend() ) { return false; }

        db = std::max(db, 0.0);
        db = std::min(db, 24.0);
        double gain = std::pow(10, db/20.0);
        m_dig_gain_global = (int)(gain * 256);
        I2cWrite16bit(IMX219_DIG_GAIN_GLOBAL_A, m_dig_gain_global);
        
        return true;
    }

    double GetDigitalGain(void)
    {
        double gain = m_dig_gain_global / 256.0;
        return 20.0 * std::log10(gain);
    }

    bool SetFrameRate(double fps)
    {
        if ( !IsOpend() ) { return false; }

        int new_frm_length = (2.0 * GetPixelClock()) / (m_line_length * fps);
        int min_frm_length = m_binning_v ? m_height / 2 + 14 : m_height + 16;
        m_frm_length = std::max(new_frm_length, min_frm_length);
        m_coarse_integration_time = std::min(m_coarse_integration_time, m_frm_length - 4);

        I2cWrite16bit(IMX219_FRM_LENGTH_A, m_frm_length);
        I2cWrite16bit(IMX219_COARSE_INTEGRATION_TIME_A, m_coarse_integration_time);
        
        return true;
    }
    
    double GetFrameRate(void)
    {
        return (2.0 * GetPixelClock()) / (m_frm_length * m_line_length);
    }

    bool SetExposureTime(double exposure_time)
    {
        if ( !IsOpend() ) { return false; }

        int new_coarse_integration_time = (2.0 * GetPixelClock()) * exposure_time / m_line_length;
        m_coarse_integration_time = std::min(new_coarse_integration_time, m_frm_length - 4);

        I2cWrite16bit(IMX219_COARSE_INTEGRATION_TIME_A, m_coarse_integration_time);
        
        return true;
    }

    double GetExposureTime(void)
    {
        return (m_coarse_integration_time * m_line_length) / (2.0 * GetPixelClock());
    }

    int GetSensorWidth(void) { return m_binning_h  ? 3296 / 2 : 3296; }
    int GetSensorHeight(void) { return m_binning_v ? (2480+16+16+8) / 2 : (2480+16+16+8); }
    int GetSensorCenterX(void) { return m_binning_h  ? (8 + (3280 / 2)) / 2 : 8 + (3280 / 2); }
    int GetSensorCenterY(void) { return m_binning_v  ? (8 + (2464 / 2)) / 2 : 8 + (2464 / 2); }

    bool SetAoi(int width, int height, int x=-1, int y=-1, bool binning_h=false, bool binning_v=false)
    {
        if ( !IsOpend() ) { return false; }

        m_binning_h = binning_h;
        m_binning_v = binning_v;
        int sensor_width  = GetSensorWidth();
        int sensor_height = GetSensorHeight();
        m_width  = std::min(width,  sensor_width);
        m_height = std::min(height, sensor_height);

        if ( x < 0 ) { x = GetSensorCenterX() - (m_width / 2); }
        if ( y < 0 ) { y = GetSensorCenterY() - (m_height / 2); }

        m_aoi_x = std::min(sensor_width  - m_width, x);
        m_aoi_y = std::min(sensor_height - m_height, y);

        int min_frm_length = m_binning_v ? m_height / 2 + 14 : m_height + 16;
        m_frm_length = std::max(m_frm_length, min_frm_length);
        m_coarse_integration_time = std::min(m_coarse_integration_time, m_frm_length - 4);

        Setup();

        return true;
    }

    bool SetAoiSize(int width, int height)
    {
        return SetAoi(width, height, m_aoi_x, m_aoi_y, m_binning_h, m_binning_v);
    }

    bool SetAoiPosition(int x, int y)
    {
        return SetAoi(m_width, m_height, x, y, m_binning_h, m_binning_v);
    }

    int GetAoiWidth(void) { return m_width; }
    int GetAoiHeight(void) { return m_height; }
    int GetAoiX(void) { return m_aoi_x; }
    int GetAoiY(void) { return m_aoi_y; }

    bool SetFlip(bool flip_h, bool flip_v)
    {
        m_flip_h = flip_h;
        m_flip_v = flip_v;

        int flip = 0;
        if ( m_flip_h ) { flip |= 0x01; }
        if ( m_flip_v ) { flip |= 0x02; }
        I2cWrite8bit(IMX219_IMG_ORIENTATION_A, flip);

        return true;
    }

    bool GetFlipH(void) { return m_flip_h; }
    bool GetFlipV(void) { return m_flip_v; }

protected:
    bool Setup(void)
    {
        if ( !IsOpend() ) {
            return false;
        }

        I2cWrite8bit(IMX219_MODE_SEL, 0x00);   // mode_select [4:0]  (0: SW standby, 1: Streaming)

        I2cWrite16bit(IMX219_CSI_DATA_FORMAT_A, 0x0A0A);    // CSI-2 data format(0x0808:RAW8, 0x0A0A: RAW10)
        I2cWrite8bit(IMX219_VTPXCK_DIV, 0x05);              // vt_pix_clk_div
        I2cWrite8bit(IMX219_VTSYCK_DIV, 0x01);              // vt_sys_clk_div
        I2cWrite8bit(IMX219_PREPLLCK_VT_DIV, 0x03);         // pre_pll_clk_vt_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        I2cWrite8bit(IMX219_PREPLLCK_OP_DIV, 0x03);         // pre_pll_clk_op_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        I2cWrite16bit(IMX219_PLL_VT_MPY, m_pll_vt_mpy);     // pll_vt_multiplier
        I2cWrite8bit(IMX219_OPPXCK_DIV, 0x0A);              // op_pix_clk_div
        I2cWrite8bit(IMX219_OPSYCK_DIV, 0x01);              // op_sys_clk_div
        I2cWrite16bit(IMX219_PLL_OP_MPY, 0x0072);           // pll_op_multiplier

        int aoi_x = m_binning_h ? m_aoi_x  * 2 : m_aoi_x;
        int aoi_y = m_binning_v ? m_aoi_y  * 2 : m_aoi_y;
        int aoi_w = m_binning_h ? m_width  * 2 : m_width;
        int aoi_h = m_binning_v ? m_height * 2 : m_height;
        I2cWrite16bit(IMX219_X_ADD_STA_A, aoi_x);               // x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
        I2cWrite16bit(IMX219_X_ADD_END_A, aoi_x + aoi_w - 1);   // 
        I2cWrite16bit(IMX219_Y_ADD_STA_A, aoi_y);               // 
        I2cWrite16bit(IMX219_Y_ADD_END_A, aoi_y + aoi_h - 1);   // 
        I2cWrite16bit(IMX219_X_OUTPUT_SIZE, m_width);           // x_output_size
        I2cWrite16bit(IMX219_Y_OUTPUT_SIZE, m_height);          // y_output_size

        I2cWrite8bit(IMX219_BINNING_MODE_H_A, m_binning_h ? 0x03 : 0x00);   // 0:no-binning, 1:x2-binning, 2:x4-binning, 3:x2 analog (special)
        I2cWrite8bit(IMX219_BINNING_MODE_V_A, m_binning_v ? 0x03 : 0x00);   // 0:no-binning, 1:x2-binning, 2:x4-binning, 3:x2 analog (special)
        
        I2cWrite16bit(IMX219_LINE_LENGTH_A, 3448);      // 0x0D78=3448   LINE_LENGTH_A (line_length_pck Units: Pixels)
        I2cWrite16bit(IMX219_FRM_LENGTH_A, m_frm_length);
        I2cWrite16bit(IMX219_COARSE_INTEGRATION_TIME_A, m_coarse_integration_time);
        
        // restart
        if ( m_running ) {
            I2cWrite8bit(IMX219_MODE_SEL, 0x01);    // mode_select [4:0] 0: SW standby, 1: Streaming
        }

        return true;
    }


protected:

    int I2cWrite(unsigned short addr, const void* data, int len)
    {
        unsigned char buf[2+len];
        
        buf[0] = ((addr >> 8) & 0xff);
        buf[1] = ((addr >> 0) & 0xff);
        memcpy(&buf[2], data, len);
        m_i2c.Write(buf, 2+len);
        
        return len;
    }
    
    int I2cRead(unsigned short addr, void* buf, int len)
    {
        unsigned char addr_buf[2];
        
        addr_buf[0] = ((addr >> 8) & 0xff);
        addr_buf[1] = ((addr >> 0) & 0xff);
        m_i2c.Write(addr_buf, 2);
        m_i2c.Read(buf, len);
        
        return len;
    }

    void I2cWrite8bit(unsigned short addr, int data)
    {
        std::uint8_t buf[1];
        buf[0] = (data & 0xff);
        I2cWrite(addr, buf, 1);
    }

    void I2cWrite16bit(unsigned short addr, int data)
    {
        std::uint8_t buf[2];
        buf[0] = ((data >> 8) & 0xff);
        buf[1] = ((data >> 0) & 0xff);
        I2cWrite(addr, buf, 2);
    }

    void I2cWrite24bit(unsigned short addr, int data)
    {
        unsigned char buf[3];
        buf[0] = ((data >> 16) & 0xff);
        buf[1] = ((data >> 8) & 0xff);
        buf[2] = ((data >> 0) & 0xff);
        I2cWrite(addr, buf, 3);
    }
    
    unsigned char I2cRead8bit(unsigned short addr)
    {
        unsigned char buf[1];
        I2cRead(addr, buf, 1);
        return buf[0];
    }

    unsigned short I2cRead16bit(unsigned short addr)
    {
        unsigned char buf[2];
        I2cRead(addr, buf, 2);
        return (buf[0] << 8) | buf[1];
    }
};

}

#endif  // __JELLY__IMX219_CONTORL__H__


// end of file
