#![allow(unused)]

use std::error::Error;
use jelly_mem_access::*;
use jelly_pac::video_dma_control::VideoDmaControl;

use crate::rtcl_p3s7_i2c::*;

const BASE_ADDR_SYS      : usize = 0x00000000;
const BASE_ADDR_TIMGEN   : usize = 0x00010000;
const BASE_ADDR_FMTR     : usize = 0x00100000;
const BASE_ADDR_WDMA_IMG : usize = 0x00210000;
const BASE_ADDR_WDMA_BLK : usize = 0x00220000;

const CAMREG_CORE_ID: u16 = 0x0000;
const CAMREG_CORE_VERSION: u16 = 0x0001;
const CAMREG_RECV_RESET: u16 = 0x0010;
const CAMREG_ALIGN_RESET: u16 = 0x0020;
const CAMREG_ALIGN_PATTERN: u16 = 0x0022;
const CAMREG_ALIGN_STATUS: u16 = 0x0028;
const CAMREG_DPHY_CORE_RESET: u16 = 0x0080;
const CAMREG_DPHY_SYS_RESET: u16 = 0x0081;
const CAMREG_DPHY_INIT_DONE: u16 = 0x0088;

const SYSREG_ID: usize = 0x0000;
const SYSREG_DPHY_SW_RESET: usize = 0x0001;
const SYSREG_CAM_ENABLE: usize = 0x0002;
const SYSREG_CSI_DATA_TYPE: usize = 0x0003;
const SYSREG_DPHY_INIT_DONE: usize = 0x0004;
const SYSREG_FPS_COUNT: usize = 0x0006;
const SYSREG_FRAME_COUNT: usize = 0x0007;
const SYSREG_IMAGE_WIDTH: usize = 0x0008;
const SYSREG_IMAGE_HEIGHT: usize = 0x0009;
const SYSREG_BLACK_WIDTH: usize = 0x000a;
const SYSREG_BLACK_HEIGHT: usize = 0x000b;

const TIMGENREG_CORE_ID: usize = 0x0000;
const TIMGENREG_CORE_VERSION: usize = 0x0001;
const TIMGENREG_CTL_CONTROL: usize = 0x0004;
const TIMGENREG_CTL_STATUS: usize = 0x0005;
const TIMGENREG_CTL_TIMER: usize = 0x0008;
const TIMGENREG_PARAM_PERIOD: usize = 0x0010;
const TIMGENREG_PARAM_TRIG0_START: usize = 0x0020;
const TIMGENREG_PARAM_TRIG0_END: usize = 0x0021;
const TIMGENREG_PARAM_TRIG0_POL: usize = 0x0022;

// Video format regularizer
const REG_VIDEO_FMTREG_CORE_ID: usize = 0x00;
const REG_VIDEO_FMTREG_CORE_VERSION: usize = 0x01;
const REG_VIDEO_FMTREG_CTL_CONTROL: usize = 0x04;
const REG_VIDEO_FMTREG_CTL_STATUS: usize = 0x05;
const REG_VIDEO_FMTREG_CTL_INDEX: usize = 0x07;
const REG_VIDEO_FMTREG_CTL_SKIP: usize = 0x08;
const REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN: usize = 0x0a;
const REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT: usize = 0x0b;
const REG_VIDEO_FMTREG_PARAM_WIDTH: usize = 0x10;
const REG_VIDEO_FMTREG_PARAM_HEIGHT: usize = 0x11;
const REG_VIDEO_FMTREG_PARAM_FILL: usize = 0x12;
const REG_VIDEO_FMTREG_PARAM_TIMEOUT: usize = 0x13;

pub struct RtclP3s7Mng {
    uio: UioAccessor::<usize>,
    buf0 : UdmabufAccessor::<usize>,
    buf1 : UdmabufAccessor::<usize>,
    i2c: RtclP3s7I2c,
}

impl RtclP3s7Mng {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        let i2c = RtclP3s7I2c::new("/dev/i2c-6")?;
        let uio = UioAccessor::<usize>::new_with_name("uio_pl_peri")?;
        let buf0 = UdmabufAccessor::<usize>::new("udmabuf-jelly-vram0", false)?;
        let buf1 = UdmabufAccessor::<usize>::new("udmabuf-jelly-vram1", false)?;
        Ok(RtclP3s7Mng {
            uio,
            buf0,
            buf1,
            i2c,
        })
    }

    pub fn write_sys_reg(&mut self, addr: usize, data: usize) -> Result<(), Box<dyn Error>> {
        unsafe{self.uio.write_reg(addr, data)};
        Ok(())
    }

    pub fn read_sys_reg(&mut self, addr : usize) -> Result<usize, Box<dyn Error>> {
        Ok(unsafe{self.uio.read_reg(addr)})
    }

    pub fn write_timgen_reg(&mut self, addr: usize, data: usize) -> Result<(), Box<dyn Error>> {
        let reg_timgen = self.uio.subclone(BASE_ADDR_TIMGEN, 0x400);
        unsafe{reg_timgen.write_reg(addr, data)};
        Ok(())
    }

    pub fn read_timgen_reg(&mut self, addr : usize) -> Result<usize, Box<dyn Error>> {
        let reg_timgen = self.uio.subclone(BASE_ADDR_TIMGEN, 0x400);
        Ok(unsafe{reg_timgen.read_reg(addr)})
    }

    pub fn write_cam_reg(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        self.i2c.write_cam_reg(addr, data)
    }

    pub fn read_cam_reg(&mut self, addr: u16) -> Result<u16, Box<dyn Error>> {
        self.i2c.read_cam_reg(addr)
    }

    pub fn write_sensor_reg(&mut self, addr: u16, data: u16) -> Result<(), Box<dyn Error>> {
        self.i2c.write_sensor_reg(addr, data)
    }

    pub fn read_sensor_reg(&mut self, addr: u16) -> Result<u16, Box<dyn Error>> {
        self.i2c.read_sensor_reg(addr)
    }

    pub fn record_image(&mut self, width: usize, height: usize, frames: usize) -> Result<(), Box<dyn Error>> {
        let reg_fmtr = self.uio.subclone(BASE_ADDR_FMTR, 0x400);
        unsafe {
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT, 10000000);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_WIDTH, width);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_HEIGHT, height);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_FILL, 0x000);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_TIMEOUT, 100000);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x03);
        }
        std::thread::sleep(std::time::Duration::from_micros(1000));

        // 1frame キャプチャ
        let reg_wdma_img = self.uio.subclone(BASE_ADDR_WDMA_IMG, 0x400);
        let mut vdmaw = VideoDmaControl::new(reg_wdma_img, 2, 2, Some(usleep)).unwrap();
        vdmaw.oneshot(
            self.buf0.phys_addr(),
            width as i32,
            height as i32,
            frames as i32,
            0,
            0,
            0,
            0,
            Some(100000),
        )?;
        std::thread::sleep(std::time::Duration::from_micros(1000));

        unsafe {
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x0);
        }
        std::thread::sleep(std::time::Duration::from_micros(1000));

        Ok(())
    }

    pub fn read_image(&mut self, addr: usize, size: usize) -> Result<Vec<u8>, Box<dyn Error>> {
        let mut buf = vec![0u8; size as usize];
        unsafe {
            self.buf0.copy_to_::<u8>(addr, buf.as_mut_ptr(), size);
        }
        Ok(buf)
    }


    pub fn record_black(&mut self, width: usize, height: usize, frames: usize) -> Result<(), Box<dyn Error>> {
        // 1frame キャプチャ
        let reg_wdma_blk = self.uio.subclone(BASE_ADDR_WDMA_BLK, 0x400);
        let mut vdmaw = VideoDmaControl::new(reg_wdma_blk, 2, 2, Some(usleep)).unwrap();
        vdmaw.oneshot(
            self.buf1.phys_addr(),
            width as i32,
            height as i32,
            frames as i32,
            0,
            0,
            0,
            0,
            Some(100000),
        )?;
        std::thread::sleep(std::time::Duration::from_micros(1000));

        Ok(())
    }

    pub fn read_black(&mut self, addr: usize, size: usize) -> Result<Vec<u8>, Box<dyn Error>> {
        let mut buf = vec![0u8; size as usize];
        unsafe {
            self.buf1.copy_to_::<u8>(addr, buf.as_mut_ptr(), size);
        }
        Ok(buf)
    }
}


fn usleep() {
    std::thread::sleep(std::time::Duration::from_micros(1));
}
