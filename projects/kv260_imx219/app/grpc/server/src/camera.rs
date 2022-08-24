#![allow(dead_code)]

use std::error::Error;
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
    pixel_clock: f64,
    binning: bool,
    width: i32,
    height: i32,
    aoi_x: i32,
    aoi_y: i32,
    flip_h: bool,
    flip_v: bool,
    frame_rate: i32,
    exposure: i32,
    a_gain: i32,
    d_gain: i32,
    bayer_phase: i32,
    view_scale: i32,

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
            pixel_clock: 91000000.0,
            binning: false,
            width: 3280,
            height: 2464,
            aoi_x: 0,
            aoi_y: 0,
            flip_h: false,
            flip_v: false,
            frame_rate: 20,
            exposure: 33,
            a_gain: 20,
            d_gain: 0,
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
    }

    pub fn open(&mut self) -> Result<(), Box<dyn Error>> {
        // カメラON
        unsafe {
            self.uio_acc.write_reg(2, 1);
        }
        thread::sleep(Duration::from_millis(500));

        /*
        // IMX219 control
        println!("reset");
        self.imx219_ctl.reset()?;

        // カメラID取得
        println!("sensor model ID:{:04x}", self.imx219_ctl.get_model_id().unwrap());

        // camera 設定
        self.imx219_ctl.set_pixel_clock(self.pixel_clock)?;
        self.imx219_ctl.set_aoi(self.width, self.height, self.aoi_x, self.aoi_y, self.binning, self.binning)?;
        self.imx219_ctl.start()?;

        self.imx219_ctl.stop()?;
        */

        /*

        // video input start
        unsafe {
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT, 10000000);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_WIDTH, width as usize);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_HEIGHT, height as usize);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_FILL, 0x100);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_TIMEOUT, 1000000);
            reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x03);
        }
        thread::sleep(Duration::from_millis(100));

        // 設定
        imx219.set_frame_rate(frame_rate as f64)?;
        imx219.set_exposure_time(exposure as f64 / 1000.0)?;
        imx219.set_gain(a_gain as f64)?;
        imx219.set_digital_gain(d_gain as f64)?;
        imx219.set_flip(flip_h, flip_v)?;
        */

        Ok(())
    }

    pub fn close(&mut self) {
        self.imx219_ctl.close();
    }
}

/*

    let pixel_clock: f64 = 91000000.0;
    let binning: bool = true;
    let width: i32 = 1280;
    let height: i32 = 720;
    let aoi_x: i32 = -1;
    let aoi_y: i32 = -1;
    let flip_h: bool = false;
    let flip_v: bool = false;
    let frame_rate: i32 = 60;
    let exposure: i32 = 20;
    let a_gain: i32 = 20;
    let d_gain: i32 = 0;
    let bayer_phase: i32 = 0;
    //    let view_scale  : i32 = 2;

    // mmap udmabuf
    let udmabuf_device_name = "udmabuf-jelly-vram0";
    println!("\nudmabuf open");
    let udmabuf_acc =
        UdmabufAccessor::<usize>::new(udmabuf_device_name, false).expect("Failed to open udmabuf");
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
    let uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri").expect("Failed to open uio");
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

    let mut vdmaw = VideoDmaControl::new(uio_acc.subclone(0x00210000, 0x400), 4, 4).unwrap();

    // カメラON
    unsafe {
        uio_acc.write_reg(2, 1);
    }
    thread::sleep(Duration::from_millis(500));

    // IMX219 control
    //    let i2c = Box::new(I2cAccessor::new("/dev/i2c-6", 0x10).expect("Failed to open i2c"));
//    let i2c = Box::new(LinuxI2CDevice::new("/dev/i2c-6", 0x10).expect("Failed to open i2c"));
    let i2c = Box::new(LinuxI2c::new("/dev/i2c-6", 0x10).unwrap());
    let mut imx219 = Imx219Control::new(i2c);
    println!("reset");
    imx219.reset()?;

    // カメラID取得
    println!("sensor model ID:{:04x}", imx219.get_model_id().unwrap());

    // camera 設定
    imx219.set_pixel_clock(pixel_clock)?;
    imx219.set_aoi(width, height, aoi_x, aoi_y, binning, binning)?;
    imx219.start()?;

    //    int     rec_frame_num = std::min(100, (int)(dmabuf_mem_size / (width * height * 4)));
    //    int     frame_num     = 1;
    //    if ( rec_frame_num <= 0 ) {
    //        std::cout << "udmabuf size error" << std::endl;
    //    }

    // video input start
    unsafe {
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN, 1);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT, 10000000);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_WIDTH, width as usize);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_HEIGHT, height as usize);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_FILL, 0x100);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_TIMEOUT, 1000000);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x03);
    }
    thread::sleep(Duration::from_millis(100));

    // 設定
    imx219.set_frame_rate(frame_rate as f64)?;
    imx219.set_exposure_time(exposure as f64 / 1000.0)?;
    imx219.set_gain(a_gain as f64)?;
    imx219.set_digital_gain(d_gain as f64)?;
    imx219.set_flip(flip_h, flip_v)?;

    loop {
        let key = wait_key(10).unwrap();
        if key == 0x1b {
            break;
        }

        unsafe {
            reg_demos.write_reg(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase as usize);
            reg_demos.write_reg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3); // update & enable
        }

        // キャプチャ
        // DMA start (one shot)
        /*
        unsafe {
            /*
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_ADDR,   udmabuf_acc.phys_addr());
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_STRIDE, (width*4) as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_WIDTH,  width as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_HEIGHT, height as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_SIZE,   (width*height*1) as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_AWLEN,  31);
            reg_wdma.write_reg(REG_VIDEO_WDMA_CTL_CONTROL,  0x07);
            */

            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_ADDR, udmabuf_acc.phys_addr());
            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_OFFSET, 0);
            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_AWLEN_MAX, 15);
            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_LINE_STEP, (width * 4) as usize);
            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_H_SIZE, (width - 1) as usize);
            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_V_SIZE, (height - 1) as usize);
            reg_wdma.write_reg(
                REG_VDMA_WRITE_PARAM_FRAME_STEP,
                (width * height * 4) as usize,
            );
            reg_wdma.write_reg(REG_VDMA_WRITE_PARAM_F_SIZE, 1 - 1);
            reg_wdma.write_reg(REG_VDMA_WRITE_CTL_CONTROL, 0x7);
        }

        // 取り込み完了を待つ
        thread::sleep(Duration::from_millis(10));
        while (unsafe { reg_wdma.read_reg(REG_VDMA_WRITE_CTL_STATUS) } != 0) {
            thread::sleep(Duration::from_millis(10));
        }
        */

        vdmaw.oneshot(udmabuf_acc.phys_addr(), width, height, 1, 0, 0, 0, 0);


        let mut buf = vec![0u8; (width * height * 4) as usize];
        unsafe {
            udmabuf_acc.copy_to(0, buf.as_mut_ptr(), (width * height * 4) as usize);
            let img = Mat::new_rows_cols_with_data(
                height,
                width,
                CV_8UC4,
                buf.as_mut_ptr() as *mut c_void,
                (width * 4) as usize,
            )
            .unwrap();
            imshow("img", &img)?;
        }
    }

    // close
    imx219.stop()?;

    println!("Hello, world!");

    Ok(())
}
*/
