#![allow(dead_code)]

use std::error::Error;
use std::thread;
use std::time::Duration;

use jelly_mem_access::*;

use opencv::{
    core::*,
    highgui::*,
};

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

fn wait_1us() {
    thread::sleep(Duration::from_micros(1));
}

fn usleep(us: u64) {
    thread::sleep(Duration::from_micros(us));
}


fn main() -> Result<(), Box<dyn Error>> {
    // start
    println!("start");

    /*
    let pixel_clock: f64   = 91000000.0;
    let binning    : bool     = false;
    let width      : i32      = 3280;
    let height     : i32      = 2464;
    let aoi_x      : i32      = 0;
    let aoi_y      : i32      = 0;
    let flip_h     : bool     = false;
    let flip_v     : bool     = false;
    let frame_rate : i32      = 20;
    let exposure   : i32      = 33;
    let a_gain     : i32      = 20;
    let d_gain     : i32      = 0;
    let bayer_phase: i32      = 0;
    let view_scale : i32      = 4;
    */

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

    // DMA制御
    let mut vdmaw = VideoDmaControl::new(reg_wdma, 4, 4, Some(wait_1us)).unwrap();

    // カメラON
    unsafe {
        uio_acc.write_reg(2, 1);
    }
    thread::sleep(Duration::from_millis(500));

    // IMX219 control
    //    let i2c = Box::new(I2cAccessor::new("/dev/i2c-6", 0x10).expect("Failed to open i2c"));
    //    let i2c = Box::new(LinuxI2CDevice::new("/dev/i2c-6", 0x10).expect("Failed to open i2c"));
    let i2c = LinuxI2c::new("/dev/i2c-6", 0x10).unwrap();
    let mut imx219 = Imx219Control::new(i2c, usleep);
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

        // 1frame キャプチャ
        vdmaw.oneshot(
            udmabuf_acc.phys_addr(),
            width,
            height,
            1,
            0,
            0,
            0,
            0,
            Some(100000),
        )?;

        let mut buf = vec![VecN::<u8, 4>::new(0, 0, 0, 0); (width * height) as usize];
        unsafe {
            udmabuf_acc.copy_to_::<VecN<u8, 4>>(0, buf.as_mut_ptr(), (width * height) as usize);
            let img = Mat::new_rows_cols_with_data(height, width, &buf).unwrap();
            imshow("img", &img)?;
        }
    }

    vdmaw.wait_for_stop(Some(10000))?;

    // 取り込み停止
    unsafe {
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
    }
    thread::sleep(Duration::from_millis(100));

    // close
    imx219.stop()?;
    imx219.close();

    // カメラOFF
    unsafe {
        uio_acc.write_reg(2, 0);
    }

    println!("close");

    Ok(())
}
