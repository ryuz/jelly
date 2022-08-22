#![allow(dead_code)]

use std::cmp::{max, min};
use std::error::Error;
use std::thread;
use std::time::Duration;

use crate::i2c_access::I2cAccess;


// レジスタ定義
const IMX219_MODEL_ID: u16 = 0x0000;
const IMX219_MODEL_ID_0: u16 = 0x0000;
const IMX219_MODEL_ID_1: u16 = 0x0001;
const IMX219_FABRICATION_TOP: u16 = 0x0002;
const IMX219_LOT_ID_TOP_0: u16 = 0x0004;
const IMX219_LOT_ID_TOP_1: u16 = 0x0005;
const IMX219_LOT_ID_TOP_2: u16 = 0x0006;
const IMX219_WAFER_NUM_TOP: u16 = 0x0007;
const IMX219_CHIP_NUMBER_0: u16 = 0x000D;
const IMX219_CHIP_NUMBER_1: u16 = 0x000E;
const IMX219_PROCESS_VERSION: u16 = 0x000F;
const IMX219_ROM_ID: u16 = 0x0011;
const IMX219_FRM_CNT: u16 = 0x0018;
const IMX219_PX_ORDER: u16 = 0x0019;
const IMX219_DT_PEDESTAL_0: u16 = 0x001A;
const IMX219_DT_PEDESTAL_1: u16 = 0x001B;
const IMX219_FRM_FMT_TYPE: u16 = 0x0040;
const IMX219_FRM_FMT_SUBTYPE: u16 = 0x0041;
const IMX219_FRM_FMT_DESC0_0: u16 = 0x0042;
const IMX219_FRM_FMT_DESC0_1: u16 = 0x0043;
const IMX219_FRM_FMT_DESC1_0: u16 = 0x0044;
const IMX219_FRM_FMT_DESC1_1: u16 = 0x0045;
const IMX219_FRM_FMT_DESC2_0: u16 = 0x0046;
const IMX219_FRM_FMT_DESC2_1: u16 = 0x0047;
const IMX219_MODE_SEL: u16 = 0x0100;
const IMX219_SW_RESET: u16 = 0x0103;
const IMX219_CORRUPTED_FRAME_STATUS: u16 = 0x0104;
const IMX219_MASK_CORRUPTED_FRAMES: u16 = 0x0105;
const IMX219_FAST_STANDBY_ENABLE: u16 = 0x0106;
const IMX219_CSI_CH_ID: u16 = 0x0110;
const IMX219_CSI_SIG_MODE: u16 = 0x0111;
const IMX219_CSI_LANE_MODE: u16 = 0x0114;
const IMX219_TCLK_POST_0: u16 = 0x0118;
const IMX219_TCLK_POST_1: u16 = 0x0119;
const IMX219_THS_PREPARE_0: u16 = 0x011A;
const IMX219_THS_PREPARE_1: u16 = 0x011B;
const IMX219_THS_ZERO_MIN_0: u16 = 0x011C;
const IMX219_THS_ZERO_MIN_1: u16 = 0x011D;
const IMX219_THS_TRAIL_0: u16 = 0x011E;
const IMX219_THS_TRAIL_1: u16 = 0x011F;
const IMX219_TCLK_TRAIL_MIN_0: u16 = 0x0120;
const IMX219_TCLK_TRAIL_MIN_1: u16 = 0x0121;
const IMX219_TCLK_PREPARE_0: u16 = 0x0122;
const IMX219_TCLK_PREPARE_1: u16 = 0x0123;
const IMX219_TCLK_ZERO_0: u16 = 0x0124;
const IMX219_TCLK_ZERO_1: u16 = 0x0125;
const IMX219_TLPX_0: u16 = 0x0126;
const IMX219_TLPX_1: u16 = 0x0127;
const IMX219_DPHY_CTRL: u16 = 0x0128;
const IMX219_EXCK_FREQ: u16 = 0x012A;
const IMX219_EXCK_FREQ_0: u16 = 0x012A;
const IMX219_EXCK_FREQ_1: u16 = 0x012B;
const IMX219_TEMPERATURE_EN_VAL: u16 = 0x0140;
const IMX219_READOUT_V_CNT_0: u16 = 0x0142;
const IMX219_READOUT_V_CNT_1: u16 = 0x0143;
const IMX219_FRAME_BANK_ENABLE: u16 = 0x0150;
const IMX219_FRAME_BANK_FRM_CNT: u16 = 0x0151;
const IMX219_FRAME_BANK_FAST_TRACKING: u16 = 0x0152;
const IMX219_FRAME_DURATION_A: u16 = 0x0154;
const IMX219_COMP_ENABLE_A: u16 = 0x0155;
const IMX219_ANA_GAIN_GLOBAL_A: u16 = 0x0157;
const IMX219_DIG_GAIN_GLOBAL_A: u16 = 0x0158;
const IMX219_DIG_GAIN_GLOBAL_A_0: u16 = 0x0158;
const IMX219_DIG_GAIN_GLOBAL_A_1: u16 = 0x0159;
const IMX219_COARSE_INTEGRATION_TIME_A: u16 = 0x015A;
const IMX219_COARSE_INTEGRATION_TIME_A_0: u16 = 0x015A;
const IMX219_COARSE_INTEGRATION_TIME_A_1: u16 = 0x015B;
const IMX219_SENSOR_MODE_A: u16 = 0x015D;
const IMX219_FRM_LENGTH_A: u16 = 0x0160;
const IMX219_FRM_LENGTH_A_0: u16 = 0x0160;
const IMX219_FRM_LENGTH_A_1: u16 = 0x0161;
const IMX219_LINE_LENGTH_A: u16 = 0x0162;
const IMX219_LINE_LENGTH_A_0: u16 = 0x0162;
const IMX219_LINE_LENGTH_A_1: u16 = 0x0163;
const IMX219_X_ADD_STA_A: u16 = 0x0164;
const IMX219_X_ADD_STA_A_0: u16 = 0x0164;
const IMX219_X_ADD_STA_A_1: u16 = 0x0165;
const IMX219_X_ADD_END_A: u16 = 0x0166;
const IMX219_X_ADD_END_A_0: u16 = 0x0166;
const IMX219_X_ADD_END_A_1: u16 = 0x0167;
const IMX219_Y_ADD_STA_A: u16 = 0x0168;
const IMX219_Y_ADD_STA_A_0: u16 = 0x0168;
const IMX219_Y_ADD_STA_A_1: u16 = 0x0169;
const IMX219_Y_ADD_END_A: u16 = 0x016A;
const IMX219_Y_ADD_END_A_0: u16 = 0x016A;
const IMX219_Y_ADD_END_A_1: u16 = 0x016B;
const IMX219_X_OUTPUT_SIZE: u16 = 0x016C;
const IMX219_X_OUTPUT_SIZE_0: u16 = 0x016C;
const IMX219_X_OUTPUT_SIZE_1: u16 = 0x016D;
const IMX219_Y_OUTPUT_SIZE: u16 = 0x016E;
const IMX219_Y_OUTPUT_SIZE_0: u16 = 0x016E;
const IMX219_Y_OUTPUT_SIZE_1: u16 = 0x016F;
const IMX219_X_ODD_INC_A: u16 = 0x0170;
const IMX219_Y_ODD_INC_A: u16 = 0x0171;
const IMX219_IMG_ORIENTATION_A: u16 = 0x0172;
const IMX219_BINNING_MODE_H_A: u16 = 0x0174;
const IMX219_BINNING_MODE_V_A: u16 = 0x0175;
const IMX219_BINNING_CAL_MODE_H_A: u16 = 0x0176;
const IMX219_BINNING_CAL_MODE_V_A: u16 = 0x0177;
const IMX219_RESERVE_0: u16 = 0x0188;
const IMX219_ANA_GAIN_GLOBAL_SHORT_A: u16 = 0x0189;
const IMX219_COARSE_INTEG_TIME_SHORT_0_A: u16 = 0x018A;
const IMX219_COARSE_INTEG_TIME_SHORT_1_A: u16 = 0x018B;
const IMX219_CSI_DATA_FORMAT_A: u16 = 0x018C;
const IMX219_CSI_DATA_FORMAT_0_A: u16 = 0x018C;
const IMX219_CSI_DATA_FORMAT_1_A: u16 = 0x018D;
const IMX219_LSC_ENABLE_A: u16 = 0x0190;
const IMX219_LSC_COLOR_MODE_A: u16 = 0x0191;
const IMX219_LSC_SELECT_TABLE_A: u16 = 0x0192;
const IMX219_LSC_TUNING_ENABLE_A: u16 = 0x0193;
const IMX219_LSC_WHITE_BALANCE_RG_0_A: u16 = 0x0194;
const IMX219_LSC_WHITE_BALANCE_RG_1_A: u16 = 0x0195;
const IMX219_RESERVE_1: u16 = 0x0196;
const IMX219_RESERVE_2: u16 = 0x0197;
const IMX219_LSC_TUNING_COEF_R_A: u16 = 0x0198;
const IMX219_LSC_TUNING_COEF_GR_A: u16 = 0x0199;
const IMX219_LSC_TUNING_COEF_GB_A: u16 = 0x019A;
const IMX219_LSC_TUNING_COEF_B_A: u16 = 0x019B;
const IMX219_LSC_TUNING_R_0_A: u16 = 0x019C;
const IMX219_LSC_TUNING_R_1_A: u16 = 0x019D;
const IMX219_LSC_TUNING_GR_0_A: u16 = 0x019E;
const IMX219_LSC_TUNING_GR_1_A: u16 = 0x019F;
const IMX219_LSC_TUNING_GB_0_A: u16 = 0x01A0;
const IMX219_LSC_TUNING_GB_1_A: u16 = 0x01A1;
const IMX219_LSC_TUNING_B_0_A: u16 = 0x01A2;
const IMX219_LSC_TUNING_B_1_A: u16 = 0x01A3;
const IMX219_LSC_KNOT_POINT_FORMAT_A: u16 = 0x01A4;
const IMX219_VTPXCK_DIV: u16 = 0x0301;
const IMX219_VTSYCK_DIV: u16 = 0x0303;
const IMX219_PREPLLCK_VT_DIV: u16 = 0x0304;
const IMX219_PREPLLCK_OP_DIV: u16 = 0x0305;
const IMX219_PLL_VT_MPY: u16 = 0x0306;
const IMX219_PLL_VT_MPY_0: u16 = 0x0306;
const IMX219_PLL_VT_MPY_1: u16 = 0x0307;
const IMX219_OPPXCK_DIV: u16 = 0x0309;
const IMX219_OPSYCK_DIV: u16 = 0x030B;
const IMX219_PLL_OP_MPY: u16 = 0x030C;
const IMX219_PLL_OP_MPY_0: u16 = 0x030C;
const IMX219_PLL_OP_MPY_1: u16 = 0x030D;
const IMX219_RESERVE_3: u16 = 0x030E;
const IMX219_RESERVE_4: u16 = 0x0318;
const IMX219_RESERVE_5: u16 = 0x0319;
const IMX219_RESERVE_6: u16 = 0x031A;
const IMX219_RESERVE_7: u16 = 0x031B;
const IMX219_RESERVE_8: u16 = 0x031C;
const IMX219_RESERVE_9: u16 = 0x031D;
const IMX219_RESERVE_10: u16 = 0x031E;
const IMX219_RESERVE_11: u16 = 0x031F;
const IMX219_FLASH_STATUS: u16 = 0x0321;



pub struct Imx219Control {
    i2c: Box<dyn I2cAccess>,

    running: bool,
    binning_h: bool,
    binning_v: bool,
    aoi_x: i32,
    aoi_y: i32,
    width: i32,
    height: i32,
    framerate: f64,
    exposure: f64,
    gain: f64,
    flip_h: bool,
    flip_v: bool,
    pll_vt_mpy: u16,
    line_length: u16,
    frm_length: u16,
    coarse_integration_time: u16,
    ana_gain_global: u8,
    dig_gain_global: u16,
}

impl Imx219Control {
    pub fn new(i2c: Box<dyn I2cAccess>) -> Self {
        Self {
            i2c: i2c,
            running: false,
            binning_h: true,
            binning_v: true,
            aoi_x: 0,
            aoi_y: 0,
            width: 640,
            height: 132,
            framerate: 1000.0,
            exposure: 1.0,
            gain: 1.0,
            flip_h: false,
            flip_v: false,
            pll_vt_mpy: 87,
            line_length: 3448, // 固定値
            frm_length: 80,
            coarse_integration_time: 80 - 4,
            ana_gain_global: 0xe0,
            dig_gain_global: 0x0fff,
        }
    }

    pub fn i2c_write(&mut self, addr: u16, data: &[u8]) -> Result<(), Box<dyn Error>> {
        let addr = addr.to_be_bytes();
        let mut buf = Vec::<u8>::new();
        buf.push(addr[0]);
        buf.push(addr[1]);
        for v in data {
            buf.push(*v);
        }
        self.i2c.write(&buf)?;
        Ok(())
    }

    pub fn i2c_read(&mut self, addr: u16, buf: &mut [u8]) -> Result<(), Box<dyn Error>> {
        self.i2c.write(&(addr.to_be_bytes()))?;
        self.i2c.read(buf)?;
        Ok(())
    }

    pub fn i2c_write_u8(&mut self, addr: u16, data: u8) -> Result<(), Box<dyn Error>> {
        self.i2c_write(addr, &(data.to_be_bytes()))?;
//      println!("i2c_u8  {:04x} <= {:02x}", addr, data);
        Ok(())
    }

    pub fn i2c_read_u8(&mut self, addr: u16) -> Result<u8, Box<dyn Error>> {
        self.i2c.write(&(addr.to_be_bytes()))?;
        let mut buf: [u8; 1] = [0; 1];
        self.i2c.read(&mut buf)?;
        Ok(u8::from_be_bytes(buf))
    }

    pub fn i2c_write_u16(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        self.i2c_write(addr, &(data.to_be_bytes()))?;
//      println!("i2c_u16 {:04x} <= {:04x}", addr, data);
        Ok(())
    }

    pub fn i2c_read_u16(&mut self, addr: u16) -> Result<u16, Box<dyn Error>> {
        self.i2c.write(&(addr.to_be_bytes()))?;
        let mut buf: [u8; 2] = [0; 2];
        self.i2c.read(&mut buf)?;
        Ok(u16::from_be_bytes(buf))
    }

    pub fn open() -> Result<(), Box<dyn Error>> {
        Ok(())
    }

    pub fn close(&mut self) {
        self.stop().unwrap();
    }

    fn check_open(&self) -> Result<(), Box<dyn Error>> {
        Ok(())
    }

    pub fn get_model_id(&mut self) -> Result<u16, Box<dyn Error>> {
        self.i2c_read_u16(IMX219_MODEL_ID)
    }

    pub fn reset(&mut self) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        // ソフトリセット
        self.i2c_write_u8(IMX219_SW_RESET, 0x01)?;
        thread::sleep(Duration::from_millis(10));

        // 初期設定
        self.i2c_write_u8(IMX219_CSI_LANE_MODE, 0x01)?; // 03: 4Lane, 01: 2Lane
        self.i2c_write_u8(IMX219_DPHY_CTRL, 0x00)?; // MIPI Global timing setting (0: auto mode, 1: manual mode)
        self.i2c_write_u16(IMX219_EXCK_FREQ, 0x1800)?; // INCK frequency [MHz] 24.00MHz

        self.i2c_write_u16(IMX219_CSI_DATA_FORMAT_A, 0x0A0A)?; // CSI-2 data format(0x0808:RAW8, 0x0A0A: RAW10)
        self.i2c_write_u8(IMX219_VTPXCK_DIV, 0x05)?; // vt_pix_clk_div
        self.i2c_write_u8(IMX219_VTSYCK_DIV, 0x01)?; // vt_sys_clk_div
        self.i2c_write_u8(IMX219_PREPLLCK_VT_DIV, 0x03)?; // pre_pll_clk_vt_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        self.i2c_write_u8(IMX219_PREPLLCK_OP_DIV, 0x03)?; // pre_pll_clk_op_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        self.i2c_write_u16(IMX219_PLL_VT_MPY, self.pll_vt_mpy)?; // pll_vt_multiplier
        self.i2c_write_u8(IMX219_OPPXCK_DIV, 0x0A)?; // op_pix_clk_div
        self.i2c_write_u8(IMX219_OPSYCK_DIV, 0x01)?; // op_sys_clk_div
        self.i2c_write_u16(IMX219_PLL_OP_MPY, 0x0072)?; // pll_op_multiplier

        Ok(())
    }

    pub fn start(&mut self) -> Result<(), Box<dyn Error>> {
        self.check_open()?;
        self.i2c_write_u8(IMX219_MODE_SEL, 0x01)?; // mode_select [4:0] 0: SW standby, 1: Streaming
        self.running = true;
        Ok(())
    }

    pub fn stop(&mut self) -> Result<(), Box<dyn Error>> {
        self.check_open()?;
        self.i2c_write_u8(IMX219_MODE_SEL, 0x00)?; // mode_select [4:0] 0: SW standby, 1: Streaming
        self.running = false;
        Ok(())
    }

    pub fn set_pixel_clock(&mut self, freq: f64) -> Result<(), Box<dyn Error>> {
        self.pll_vt_mpy = if freq <= 91000000.0 { 57 } else { 87 };
        Ok(())
    }

    pub fn get_pixel_clock(&mut self) -> Result<f64, Box<dyn Error>> {
        Ok(8000000.0 * self.pll_vt_mpy as f64 / 5.0)
    }

    pub fn set_gain(&mut self, db: f64) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        let db = if db > 0.0 { db } else { 0.0 };
        let db = if db < 20.57 { db } else { 20.57 };
        let gain = 10f64.powf(db / 20.0);
        self.ana_gain_global = (256.0 * ((gain - 1.0) / gain)) as u8;
        self.i2c_write_u8(IMX219_ANA_GAIN_GLOBAL_A, self.ana_gain_global)?;
        Ok(())
    }

    pub fn get_gain(&mut self) -> Result<f64, Box<dyn Error>> {
        let gain = 256.0 / (256.0 - self.ana_gain_global as f64);
        Ok(20.0 * gain.log10())
    }

    pub fn set_digital_gain(&mut self, db: f64) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        let db = if db > 0.0 { db } else { 0.0 };
        let db = if db < 24.0 { db } else { 24.0 };
        let gain = 10f64.powf(db / 20.0);
        self.dig_gain_global = (gain * 256.0) as u16;
        self.i2c_write_u16(IMX219_DIG_GAIN_GLOBAL_A, self.dig_gain_global)?;
        Ok(())
    }

    pub fn get_digital_gain(&mut self) -> Result<f64, Box<dyn Error>> {
        let gain = self.dig_gain_global as f64 / 256.0;
        Ok(20.0 * gain.log10())
    }

    pub fn set_frame_rate(&mut self, fps: f64) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        let new_frm_length =
            ((2.0 * self.get_pixel_clock()?) / (self.line_length as f64 * fps)) as i32;
        let min_frm_length = if self.binning_v {
            self.height / 2 + 14
        } else {
            self.height + 16
        };
        self.frm_length = max(new_frm_length, min_frm_length) as u16;
        self.coarse_integration_time = min(self.coarse_integration_time, self.frm_length - 4);

        self.i2c_write_u16(IMX219_FRM_LENGTH_A, self.frm_length)?;
        self.i2c_write_u16(
            IMX219_COARSE_INTEGRATION_TIME_A,
            self.coarse_integration_time,
        )?;
        Ok(())
    }

    pub fn get_frame_rate(&mut self) -> Result<f64, Box<dyn Error>> {
        Ok((2.0 * self.get_pixel_clock()?) / (self.frm_length as f64 * self.line_length as f64))
    }

    pub fn set_exposure_time(&mut self, exposure_time: f64) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        let new_coarse_integration_time =
            ((2.0 * self.get_pixel_clock()?) * exposure_time / self.line_length as f64) as u16;
        self.coarse_integration_time = min(new_coarse_integration_time, self.frm_length - 4);

        self.i2c_write_u16(
            IMX219_COARSE_INTEGRATION_TIME_A,
            self.coarse_integration_time,
        )?;
        Ok(())
    }

    pub fn get_exposure_time(&mut self) -> Result<f64, Box<dyn Error>> {
        Ok(
            (self.coarse_integration_time as f64 * self.line_length as f64)
                / (2.0 * self.get_pixel_clock()?),
        )
    }

    pub fn sensor_width(&self) -> i32 {
        if self.binning_h {
            3296 / 2
        } else {
            3296
        }
    }
    pub fn sensor_height(&self) -> i32 {
        if self.binning_v {
            (2480 + 16 + 16 + 8) / 2
        } else {
            2480 + 16 + 16 + 8
        }
    }
    pub fn sensor_center_x(&self) -> i32 {
        if self.binning_h {
            (8 + (3280 / 2)) / 2
        } else {
            8 + (3280 / 2)
        }
    }
    pub fn sensor_center_y(&self) -> i32 {
        if self.binning_v {
            (8 + (2464 / 2)) / 2
        } else {
            8 + (2464 / 2)
        }
    }

    pub fn set_aoi(
        &mut self,
        width: i32,
        height: i32,
        x: i32,
        y: i32,
        binning_h: bool,
        binning_v: bool,
    ) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        self.binning_h = binning_h;
        self.binning_v = binning_v;
        let sensor_width = self.sensor_width();
        let sensor_height = self.sensor_height();
        self.width = min(width, sensor_width);
        self.height = min(height, sensor_height);

        let x = if x < 0 {
            self.sensor_center_x() - (self.width / 2)
        } else {
            x
        };
        let y = if y < 0 {
            self.sensor_center_y() - (self.height / 2)
        } else {
            y
        };

        self.aoi_x = min(sensor_width - self.width, x);
        self.aoi_y = min(sensor_height - self.height, y);

        let min_frm_length = if self.binning_v {
            self.height / 2 + 14
        } else {
            self.height + 16
        };
        self.frm_length = max(self.frm_length, min_frm_length as u16);
        self.coarse_integration_time = min(self.coarse_integration_time, self.frm_length - 4);

        self.setup()?;

        Ok(())
    }

    pub fn set_aoi_size(&mut self, width: i32, height: i32) -> Result<(), Box<dyn Error>> {
        self.set_aoi(
            width,
            height,
            self.aoi_x,
            self.aoi_y,
            self.binning_h,
            self.binning_v,
        )
    }

    pub fn set_aoi_position(&mut self, x: i32, y: i32) -> Result<(), Box<dyn Error>> {
        self.set_aoi(
            self.width,
            self.height,
            x,
            y,
            self.binning_h,
            self.binning_v,
        )
    }

    pub fn aoi_width(&self) -> i32 {
        self.width
    }
    pub fn aoi_height(&self) -> i32 {
        self.height
    }
    pub fn aoi_x(&self) -> i32 {
        self.aoi_x
    }
    pub fn aoi_y(&self) -> i32 {
        self.aoi_y
    }

    pub fn set_flip(&mut self, flip_h: bool, flip_v: bool) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        self.flip_h = flip_h;
        self.flip_v = flip_v;

        let mut flip: u8 = 0;
        if self.flip_h {
            flip |= 0x01;
        }
        if self.flip_v {
            flip |= 0x02;
        }
        self.i2c_write_u8(IMX219_IMG_ORIENTATION_A, flip)?;
        Ok(())
    }

    pub fn flip_h(&self) -> bool {
        self.flip_h
    }
    pub fn flip_v(&self) -> bool {
        self.flip_v
    }

    pub fn setup(&mut self) -> Result<(), Box<dyn Error>> {
        self.check_open()?;

        self.i2c_write_u8(IMX219_MODE_SEL, 0x00)?; // mode_select [4:0]  (0: SW standby, 1: Streaming)

        self.i2c_write_u16(IMX219_CSI_DATA_FORMAT_A, 0x0A0A)?; // CSI-2 data format(0x0808:RAW8, 0x0A0A: RAW10)
        self.i2c_write_u8(IMX219_VTPXCK_DIV, 0x05)?; // vt_pix_clk_div
        self.i2c_write_u8(IMX219_VTSYCK_DIV, 0x01)?; // vt_sys_clk_div
        self.i2c_write_u8(IMX219_PREPLLCK_VT_DIV, 0x03)?; // pre_pll_clk_vt_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        self.i2c_write_u8(IMX219_PREPLLCK_OP_DIV, 0x03)?; // pre_pll_clk_op_div(EXCK_FREQ 0:6-12MHz, 2:12-24MHz, 3:24-27MHz)
        self.i2c_write_u16(IMX219_PLL_VT_MPY, self.pll_vt_mpy)?; // pll_vt_multiplier
        self.i2c_write_u8(IMX219_OPPXCK_DIV, 0x0A)?; // op_pix_clk_div
        self.i2c_write_u8(IMX219_OPSYCK_DIV, 0x01)?; // op_sys_clk_div
        self.i2c_write_u16(IMX219_PLL_OP_MPY, 0x0072)?; // pll_op_multiplier

        let aoi_x = if self.binning_h {
            self.aoi_x * 2
        } else {
            self.aoi_x
        };
        let aoi_y = if self.binning_v {
            self.aoi_y * 2
        } else {
            self.aoi_y
        };
        let aoi_w = if self.binning_h {
            self.width * 2
        } else {
            self.width
        };
        let aoi_h = if self.binning_v {
            self.height * 2
        } else {
            self.height
        };
        self.i2c_write_u16(IMX219_X_ADD_STA_A, aoi_x as u16)?; // x_addr_start  X-address of the top left corner of the visible pixel data Units: Pixels
        self.i2c_write_u16(IMX219_X_ADD_END_A, (aoi_x + aoi_w - 1) as u16)?; //
        self.i2c_write_u16(IMX219_Y_ADD_STA_A, aoi_y as u16)?; //
        self.i2c_write_u16(IMX219_Y_ADD_END_A, (aoi_y + aoi_h - 1) as u16)?; //
        self.i2c_write_u16(IMX219_X_OUTPUT_SIZE, self.width as u16)?; // x_output_size
        self.i2c_write_u16(IMX219_Y_OUTPUT_SIZE, self.height as u16)?; // y_output_size

        self.i2c_write_u8(
            IMX219_BINNING_MODE_H_A,
            if self.binning_h { 0x03 } else { 0x00 },
        )?; // 0:no-binning, 1:x2-binning, 2:x4-binning, 3:x2 analog (special)
        self.i2c_write_u8(
            IMX219_BINNING_MODE_V_A,
            if self.binning_v { 0x03 } else { 0x00 },
        )?; // 0:no-binning, 1:x2-binning, 2:x4-binning, 3:x2 analog (special)

        self.i2c_write_u16(IMX219_LINE_LENGTH_A, 3448)?; // 0x0D78=3448   LINE_LENGTH_A (line_length_pck Units: Pixels)
        self.i2c_write_u16(IMX219_FRM_LENGTH_A, self.frm_length)?;
        self.i2c_write_u16(
            IMX219_COARSE_INTEGRATION_TIME_A,
            self.coarse_integration_time,
        )?;

        // restart
        if self.running {
            self.i2c_write_u8(IMX219_MODE_SEL, 0x01)?; // mode_select [4:0] 0: SW standby, 1: Streaming
        }

        Ok(())
    }
}


impl Drop for Imx219Control {
    fn drop(&mut self) {
        self.close();
    }
}

