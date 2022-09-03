#![allow(dead_code)]

use std::error::Error;
use std::fmt;
use std::thread;
use std::time::Duration;

use jelly_mem_access::*;

use jelly_lib::imx219_control::Imx219Control;
use jelly_lib::linux_i2c::LinuxI2c;
use jelly_pac::video_dma_control::VideoDmaControl;

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

// Demosaic
const REG_IMG_DEMOSAIC_CORE_ID: usize = 0x00;
const REG_IMG_DEMOSAIC_CORE_VERSION: usize = 0x01;
const REG_IMG_DEMOSAIC_CTL_CONTROL: usize = 0x04;
const REG_IMG_DEMOSAIC_CTL_STATUS: usize = 0x05;
const REG_IMG_DEMOSAIC_CTL_INDEX: usize = 0x07;
const REG_IMG_DEMOSAIC_PARAM_PHASE: usize = 0x08;
const REG_IMG_DEMOSAIC_CURRENT_PHASE: usize = 0x18;

pub struct CameraManager {
    opened: bool,

    pixel_clock: f64,
    binning: bool,
    width: i32,
    height: i32,
    aoi_x: i32,
    aoi_y: i32,
    flip_h: bool,
    flip_v: bool,
    frame_rate: f64,
    exposure: f64,
    analog_gain: f64,
    digital_gain: f64,
    bayer_phase: i32,

    udmabuf_acc: UdmabufAccessor<usize>,
    uio_acc: UioAccessor<usize>,
    reg_gid: UioAccessor<usize>,
    reg_fmtr: UioAccessor<usize>,
    reg_demos: UioAccessor<usize>,
    reg_colmat: UioAccessor<usize>,
    reg_wdma: UioAccessor<usize>,

    imx219_ctl: Imx219Control<LinuxI2c>,
    vdmaw: VideoDmaControl<UioAccessor<usize>>,
}

impl Default for CameraManager {
    fn default() -> Self {
        CameraManager::new()
    }
}

#[derive(Debug)]
enum CameraError {
    Msg(String),
}

impl fmt::Display for CameraError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let CameraError::Msg(msg) = self;
        write!(f, "CameraError : {}", msg)
    }
}

impl Error for CameraError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        None
    }
}


impl CameraManager {
    pub fn new() -> Self {
        // mmap udmabuf
        let udmabuf_device_name = "udmabuf-jelly-vram0";
        println!("\nudmabuf open");
        let udmabuf_acc = UdmabufAccessor::<usize>::new(udmabuf_device_name, false)
            .expect("Failed to open udmabuf");
        println!(
            "{} phys addr : 0x{:x}",
            udmabuf_device_name,
            udmabuf_acc.phys_addr()
        );
        println!(
            "{} size      : 0x{:x}",
            udmabuf_device_name,
            udmabuf_acc.size()
        );

        // UIO
        println!("\nuio open");
        let uio_acc =
            UioAccessor::<usize>::new_with_name("uio_pl_peri").expect("Failed to open uio");
        println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
        println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

        let reg_gid = uio_acc.subclone(0x00000000, 0x400);
        let reg_fmtr = uio_acc.subclone(0x00100000, 0x400);
        let reg_demos = uio_acc.subclone(0x00120000, 0x400);
        let reg_colmat = uio_acc.subclone(0x00120800, 0x400);
        let reg_wdma = uio_acc.subclone(0x00210000, 0x400);

        println!("CORE ID");
        unsafe {
            println!("reg_gid    : {:08x}", reg_gid.read_reg(0));
            println!("uio_acc    : {:08x}", uio_acc.read_reg(0));
            println!("reg_fmtr   : {:08x}", reg_fmtr.read_reg(0));
            println!("reg_demos  : {:08x}", reg_demos.read_reg(0));
            println!("reg_colmat : {:08x}", reg_colmat.read_reg(0));
            println!("reg_wdma   : {:08x}", reg_wdma.read_reg(0));
        }

        let vdmaw = VideoDmaControl::new(uio_acc.subclone(0x00210000, 0x400), 4, 4).unwrap();
        let i2c = LinuxI2c::new("/dev/i2c-6", 0x10).unwrap();
        let imx219_ctl = Imx219Control::new(i2c);

        CameraManager {
            opened: false,

            pixel_clock: 91000000.0,
            binning: false,
            width: 1280,
            height: 720,
            aoi_x: -1,
            aoi_y: -1,
            flip_h: false,
            flip_v: false,
            frame_rate: 60.0,
            exposure: 20.0,
            analog_gain: 20.0,
            digital_gain: 0.0,
            bayer_phase: 0,
            udmabuf_acc: udmabuf_acc,
            uio_acc: uio_acc,
            reg_gid: reg_gid,
            reg_fmtr: reg_fmtr,
            reg_demos: reg_demos,
            reg_colmat: reg_colmat,
            reg_wdma: reg_wdma,
            imx219_ctl: imx219_ctl,
            vdmaw: vdmaw,
        }
        
        /*
        CameraManager {
            pixel_clock: 91000000.0,
            binning: false,
            width: 3280,
            height: 2464,
            aoi_x: 0,
            aoi_y: 0,
            flip_h: false,
            flip_v: false,
            frame_rate: 20.0,
            exposure: 33.3,
            a_gain: 20.0,
            d_gain: 0.0,
            bayer_phase: 0,
            view_scale: 4,
            udmabuf_acc: udmabuf_acc,
            uio_acc: uio_acc,
            reg_gid: reg_gid,
            reg_fmtr: reg_fmtr,
            reg_demos: reg_demos,
            reg_colmat: reg_colmat,
            reg_wdma: reg_wdma,
            imx219_ctl: imx219_ctl,
            vdmaw: vdmaw,
        }
        */
    }

    pub fn is_opened(&self) -> bool {
        self.opened
    }

    pub fn open(&mut self) -> Result<(), Box<dyn Error>> {
        if self.is_opened() { self.close(); }

        // カメラON
        unsafe {
            self.uio_acc.write_reg(2, 1);
        }
        thread::sleep(Duration::from_millis(500));

        // IMX219 control
        println!("reset");
        self.imx219_ctl.reset()?;

        // カメラID取得
        println!("sensor model ID:{:04x}", self.imx219_ctl.get_model_id().unwrap());

        // camera 設定
        self.imx219_ctl.set_pixel_clock(self.pixel_clock)?;
        self.imx219_ctl.set_aoi(self.width, self.height, self.aoi_x, self.aoi_y, self.binning, self.binning)?;
        self.imx219_ctl.start()?;

        // video input start
        unsafe {
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT, 10000000);
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_WIDTH, self.width as usize);
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_HEIGHT, self.height as usize);
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_FILL, 0x100);
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_TIMEOUT, 1000000);
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x03);
        }
        thread::sleep(Duration::from_millis(100));

        // bayer
        unsafe {
            self.reg_demos.write_reg(REG_IMG_DEMOSAIC_PARAM_PHASE, self.bayer_phase as usize);
            self.reg_demos.write_reg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3); // update & enable
        }

        // 設定
        self.imx219_ctl.set_frame_rate(self.frame_rate)?;
        self.imx219_ctl.set_exposure_time(self.exposure)?;
        self.imx219_ctl.set_gain(self.analog_gain)?;
        self.imx219_ctl.set_digital_gain(self.digital_gain)?;
        self.imx219_ctl.set_flip(self.flip_h, self.flip_v)?;
        
        self.opened = true;

        Ok(())
    }

    pub fn close(&mut self) {
        if !self.is_opened() {
            return;
        }

        self.imx219_ctl.close();

        unsafe {
            self.reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
        }

        self.opened = false;
    }

//    fn check_opened(&self) -> Result< (), Box<dyn Error> > {
//        if self.is_opened() { Ok(()) } else { Err(Box::new(CameraError::Msg("device is not opened!".to_string()))) }
//    }

    fn check_opened(&self) -> Result< (), CameraError> {
        if self.is_opened() { Ok(()) } else { Err(CameraError::Msg("device is not opened!".to_string())) }
    }

    pub fn get_image(&mut self) -> Result< (i32, i32, Vec<u8>), Box<dyn Error> > {
        self.check_opened()?;
        
        // 1frame 取り込み
        self.vdmaw.oneshot(self.udmabuf_acc.phys_addr(), self.width, self.height, 1, 0, 0, 0, 0);
        let img_size = (self.width * self.height * 4) as usize;
        let mut buf = vec![0u8; img_size];
        unsafe {
            self.udmabuf_acc.copy_to(0, buf.as_mut_ptr(), img_size);
        }
        Ok((self.width, self.height, buf))
    }


    pub fn pixel_clock(&self) ->  f64 {self.pixel_clock } 
    pub fn binning(&self) ->  bool{self.binning }
    pub fn width(&self) -> i32 { self.width }
    pub fn height(&self) -> i32  { self.height }
    pub fn aoi_x(&self) ->  i32{self.aoi_x }
    pub fn aoi_y(&self) ->  i32{self.aoi_y }
    pub fn flip_h(&self) ->  bool{self.flip_h }
    pub fn flip_v(&self) ->  bool{self.flip_v }
    pub fn frame_rate(&self) ->  f64{self.frame_rate }
    pub fn exposure(&self) ->  f64{self.exposure }
    pub fn analog_gain(&self) ->  f64{self.analog_gain }
    pub fn digital_gain(&self) ->  f64{self.digital_gain }
    pub fn bayer_phase(&self) ->  i32{self.bayer_phase }

    pub fn set_aoi_size(&mut self, width: i32, height: i32)  -> Result< (), Box<dyn Error> > {
        let opened = self.is_opened();
        self.close();
        self.width = width;
        self.height = height;
        if opened { self.open() } else { Ok(()) }
    }

    pub fn set_aoi(&mut self, width: i32, height: i32, x: i32, y: i32)  -> Result< (), Box<dyn Error> > {
        let opened = self.is_opened();
        self.close();
        self.width = width;
        self.height = height;
        self.aoi_x = x;
        self.aoi_y = y;
        if opened { self.open() } else { Ok(()) }
    }

    pub fn set_frame_rate(&mut self, frame_rate: f64)  -> Result< (), Box<dyn Error> > {
        let opened = self.is_opened();
        self.close();
        self.frame_rate = frame_rate;
        if opened { self.open() } else { Ok(()) }
    }

    pub fn set_exposure_time(&mut self, exposure: f64)  -> Result< (), Box<dyn Error> > {
        let opened = self.is_opened();
        self.close();
        self.exposure = exposure;
        if opened { self.open() } else { Ok(()) }
    }

    pub fn set_gain(&mut self, gain: f64)  -> Result< (), Box<dyn Error> > {
        self.analog_gain = gain;
        if self.is_opened() {
            self.imx219_ctl.set_gain(self.analog_gain)
        }
        else {
            Ok(())
        }
    }

    pub fn set_digital_gain(&mut self, gain: f64)  -> Result< (), Box<dyn Error> > {
        self.digital_gain = gain;
        if self.is_opened() {
            self.imx219_ctl.set_digital_gain(self.digital_gain)
        }
        else {
            Ok(())
        }
    }

    pub fn set_flip(&mut self, flip_h: bool, flip_v: bool)  -> Result< (), Box<dyn Error> > {
        self.flip_h = flip_h;
        self.flip_v = flip_v;
        if self.is_opened() {
            self.imx219_ctl.set_flip(self.flip_h, self.flip_v)
        }
        else {
            Ok(())
        }
    }

    pub fn set_bayer_phase(&mut self, phase:i32)  -> Result< (), Box<dyn Error> > {
        self.bayer_phase = phase;
        unsafe {
            self.reg_demos.write_reg(REG_IMG_DEMOSAIC_PARAM_PHASE, self.bayer_phase as usize);
            self.reg_demos.write_reg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3); // update & enable
        }
        Ok(())
    }

}
