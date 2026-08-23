#![allow(dead_code)]

use std::error::Error;
use std::thread;
use std::time::Duration;

use jelly_lib::imx219_sensor_driver::Imx219SensorDriver;
use jelly_lib::linux_i2c::LinuxI2c;
use jelly_mem_access::*;
use opencv::core::*;
use opencv::highgui;

const CAM_WIDTH: usize = 640;
const CAM_HEIGHT: usize = 132;
const DVI_WIDTH: usize = 1280;
const DVI_HEIGHT: usize = 720;
const BUF_STRIDE: usize = 2048 * 4;

const REG_WDMA_CTL_CONTROL: usize = 0x04;
const REG_WDMA_CTL_STATUS: usize = 0x05;
const REG_WDMA_PARAM_ADDR: usize = 0x08;
const REG_WDMA_PARAM_STRIDE: usize = 0x09;
const REG_WDMA_PARAM_WIDTH: usize = 0x0a;
const REG_WDMA_PARAM_HEIGHT: usize = 0x0b;
const REG_WDMA_PARAM_SIZE: usize = 0x0c;
const REG_WDMA_PARAM_AWLEN: usize = 0x0f;

const REG_RDMA_CTL_CONTROL: usize = 0x04;
const REG_RDMA_CTL_STATUS: usize = 0x05;
const REG_RDMA_PARAM_ADDR: usize = 0x08;
const REG_RDMA_PARAM_STRIDE: usize = 0x09;
const REG_RDMA_PARAM_WIDTH: usize = 0x0a;
const REG_RDMA_PARAM_HEIGHT: usize = 0x0b;
const REG_RDMA_PARAM_SIZE: usize = 0x0c;
const REG_RDMA_PARAM_ARLEN: usize = 0x0f;

const REG_NORM_CONTROL: usize = 0x00;
const REG_NORM_FRM_TIMER_EN: usize = 0x04;
const REG_NORM_FRM_TIMEOUT: usize = 0x05;
const REG_NORM_PARAM_WIDTH: usize = 0x08;
const REG_NORM_PARAM_HEIGHT: usize = 0x09;
const REG_NORM_PARAM_FILL: usize = 0x0a;
const REG_NORM_PARAM_TIMEOUT: usize = 0x0b;

const REG_RAW2RGB_DEMOSAIC_PHASE: usize = 0x00;

const REG_MCOL_PARAM_MODE: usize = 0x00;
const REG_MCOL_PARAM_TH: usize = 0x01;

const REG_BIN_PARAM_END: usize = 0x04;
const REG_BIN_TBL0: usize = 0x40;

const REG_VSGEN_CTL_CONTROL: usize = 0x04;
const REG_VSGEN_PARAM_HTOTAL: usize = 0x08;
const REG_VSGEN_PARAM_HSYNC_POL: usize = 0x0b;
const REG_VSGEN_PARAM_HDISP_START: usize = 0x0c;
const REG_VSGEN_PARAM_HDISP_END: usize = 0x0d;
const REG_VSGEN_PARAM_HSYNC_START: usize = 0x0e;
const REG_VSGEN_PARAM_HSYNC_END: usize = 0x0f;
const REG_VSGEN_PARAM_VTOTAL: usize = 0x10;
const REG_VSGEN_PARAM_VSYNC_POL: usize = 0x13;
const REG_VSGEN_PARAM_VDISP_START: usize = 0x14;
const REG_VSGEN_PARAM_VDISP_END: usize = 0x15;
const REG_VSGEN_PARAM_VSYNC_START: usize = 0x16;
const REG_VSGEN_PARAM_VSYNC_END: usize = 0x17;

const OLED_REG_RES_N: usize = 0;
const OLED_REG_BS: usize = 1;
const OLED_REG_PWR_EN: usize = 2;
const OLED_REG_VIN_EN: usize = 3;
const OLED_REG_DBUD: usize = 4;

const OLED_CMD_DEACTIVESCROLLING: usize = 0x2E;
const OLED_CMD_SETCOLUMNADDRESS: usize = 0x15;
const OLED_CMD_SETROWADDRESS: usize = 0x75;
const OLED_CMD_SETCONTRASTA: usize = 0x81;
const OLED_CMD_SETCONTRASTB: usize = 0x82;
const OLED_CMD_SETCONTRASTC: usize = 0x83;
const OLED_CMD_MASTERCURRENTCONTROL: usize = 0x87;
const OLED_CMD_SETPRECHARGESPEEDA: usize = 0x8A;
const OLED_CMD_SETPRECHARGESPEEDB: usize = 0x8B;
const OLED_CMD_SETPRECHARGESPEEDC: usize = 0x8C;
const OLED_CMD_SETREMAP: usize = 0xA0;
const OLED_CMD_SETDISPLAYSTARTLINE: usize = 0xA1;
const OLED_CMD_SETDISPLAYOFFSET: usize = 0xA2;
const OLED_CMD_NORMALDISPLAY: usize = 0xA4;
const OLED_CMD_SETMULTIPLEXRATIO: usize = 0xA8;
const OLED_CMD_SETMASTERCONFIGURE: usize = 0xAD;
const OLED_CMD_DISPLAYOFF: usize = 0xAE;
const OLED_CMD_DISPLAYON: usize = 0xAF;
const OLED_CMD_POWERSAVEMODE: usize = 0xB0;
const OLED_CMD_PHASEPERIODADJUSTMENT: usize = 0xB1;
const OLED_CMD_DISPLAYCLOCKDIV: usize = 0xB3;
const OLED_CMD_SETGRAYSCALETABLE: usize = 0xB8;
const OLED_CMD_SETPRECHARGEVOLTAGE: usize = 0xBB;
const OLED_CMD_SETVVOLTAGE: usize = 0xBE;
const OLED_CMD_CLEARWINDOW: usize = 0x25;

fn main() -> Result<(), Box<dyn Error>> {
    println!("start zybo_z7_mnist_seg_imx219_oled");

    let udmabuf_acc = UdmabufAccessor::<usize>::new("udmabuf0", false)?;
    println!("udmabuf0 phys addr : 0x{:x}", udmabuf_acc.phys_addr());
    println!("udmabuf0 size      : 0x{:x}", udmabuf_acc.size());

    let uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri")?;
    println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
    println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

    let reg_wdma = uio_acc.subclone(0x0001_0000, 0x400);
    let reg_norm = uio_acc.subclone(0x0001_1000, 0x400);
    let reg_rgb = uio_acc.subclone(0x0001_2000, 0x400);
    let reg_bin = uio_acc.subclone(0x0001_8000, 0x400);
    let reg_mcol = uio_acc.subclone(0x0001_9000, 0x400);
    let reg_rdma = uio_acc.subclone(0x0002_0000, 0x400);
    let reg_vsgen = uio_acc.subclone(0x0002_1000, 0x400);
    let reg_oled = uio_acc.subclone(0x0002_2000, 0x400);

    let i2c = LinuxI2c::new("/dev/i2c-0", 0x10)?;
    let mut imx219 = Imx219SensorDriver::new(i2c);
    imx219.reset()?;
    imx219.set_pixel_clock(139_200_000.0)?;
    imx219.set_aoi(640, 132, (3280 / 2 - 640) / 2, (2464 / 2 - 132) / 2, true, true)?;
    imx219.start()?;

    oled_setup(&reg_oled);

    capture_start(&reg_wdma, &reg_norm, udmabuf_acc.phys_addr());
    vout_start(&reg_rdma, &reg_vsgen, udmabuf_acc.phys_addr());

    highgui::named_window("img", highgui::WINDOW_AUTOSIZE)?;
    create_cv_trackbar("bin_th", 0, 255, 127)?;
    create_cv_trackbar("col_mode", 0, 15, 2)?;
    create_cv_trackbar("col_th", 0, 15, 0)?;
    create_cv_trackbar("a_gain", 0, 20, 20)?;
    create_cv_trackbar("d_gain", 0, 24, 10)?;
    create_cv_trackbar("bayer", 0, 3, 1)?;

    loop {
        let key = highgui::wait_key(10)?;
        if (key & 0xff) == 0x1b {
            break;
        }

        let bin_th = get_cv_trackbar_pos("bin_th")? as usize;
        let col_mode = get_cv_trackbar_pos("col_mode")? as usize;
        let col_th = get_cv_trackbar_pos("col_th")? as usize;
        let a_gain = get_cv_trackbar_pos("a_gain")? as f64;
        let d_gain = get_cv_trackbar_pos("d_gain")? as f64;
        let bayer_phase = get_cv_trackbar_pos("bayer")? as usize;

        unsafe {
            reg_mcol.write_reg(REG_MCOL_PARAM_MODE, col_mode);
            reg_mcol.write_reg(REG_MCOL_PARAM_TH, col_th);
        }

        if bin_th == 0 {
            unsafe {
                reg_bin.write_reg(REG_BIN_TBL0 + 0, 0x10);
                reg_bin.write_reg(REG_BIN_TBL0 + 1, 0xf0);
                reg_bin.write_reg(REG_BIN_TBL0 + 2, 0x70);
                reg_bin.write_reg(REG_BIN_TBL0 + 3, 0x90);
                reg_bin.write_reg(REG_BIN_TBL0 + 4, 0x30);
                reg_bin.write_reg(REG_BIN_TBL0 + 5, 0xd0);
                reg_bin.write_reg(REG_BIN_TBL0 + 6, 0x50);
                reg_bin.write_reg(REG_BIN_TBL0 + 7, 0xb0);
                reg_bin.write_reg(REG_BIN_TBL0 + 8, 0x20);
                reg_bin.write_reg(REG_BIN_TBL0 + 9, 0xe0);
                reg_bin.write_reg(REG_BIN_TBL0 + 10, 0x60);
                reg_bin.write_reg(REG_BIN_TBL0 + 11, 0xa0);
                reg_bin.write_reg(REG_BIN_TBL0 + 12, 0x40);
                reg_bin.write_reg(REG_BIN_TBL0 + 13, 0xc0);
                reg_bin.write_reg(REG_BIN_TBL0 + 14, 0x80);
                reg_bin.write_reg(REG_BIN_PARAM_END, 14);
            }
        } else {
            unsafe {
                reg_bin.write_reg(REG_BIN_TBL0, bin_th);
                reg_bin.write_reg(REG_BIN_PARAM_END, 0);
            }
        }

        imx219.set_gain(a_gain)?;
        imx219.set_digital_gain(d_gain)?;
        unsafe {
            reg_rgb.write_reg(REG_RAW2RGB_DEMOSAIC_PHASE, bayer_phase);
        }

        let img = read_image(&udmabuf_acc)?;
        highgui::imshow("img", &img)?;

        let ch = (key & 0xff) as u8 as char;
        match ch {
            'h' => {
                imx219.set_flip(imx219.flip_h(), !imx219.flip_v())?;
            }
            'v' => {
                imx219.set_flip(!imx219.flip_h(), imx219.flip_v())?;
            }
            'w' => {
                imx219.set_aoi_position(imx219.aoi_x(), imx219.aoi_y() - 4)?;
            }
            'z' => {
                imx219.set_aoi_position(imx219.aoi_x(), imx219.aoi_y() + 4)?;
            }
            'a' => {
                imx219.set_aoi_position(imx219.aoi_x() - 4, imx219.aoi_y())?;
            }
            's' => {
                imx219.set_aoi_position(imx219.aoi_x() + 4, imx219.aoi_y())?;
            }
            _ => {}
        }
    }

    capture_stop(&reg_wdma, &reg_norm);
    vout_stop(&reg_rdma, &reg_vsgen);
    oled_stop(&reg_oled);
    imx219.stop()?;
    imx219.close();

    Ok(())
}

fn read_image(udmabuf_acc: &impl MemAccess) -> opencv::Result<Mat> {
    let x = (DVI_WIDTH - CAM_WIDTH) / 2;
    let y = (DVI_HEIGHT - CAM_HEIGHT) / 2;

    let mut img_buf = vec![0_u8; CAM_WIDTH * CAM_HEIGHT * 4];
    for i in 0..CAM_HEIGHT {
        let src_ofs = (y + i) * BUF_STRIDE + x * 4;
        let dst_ofs = i * CAM_WIDTH * 4;
        unsafe {
            udmabuf_acc.copy_to_u8(
                src_ofs,
                img_buf.as_mut_ptr().wrapping_add(dst_ofs),
                CAM_WIDTH * 4,
            );
        }
    }
    let img = Mat::from_slice(&img_buf)?;
    let img = img.reshape(4, CAM_HEIGHT as i32)?;
    let mut owned = Mat::default();
    img.copy_to(&mut owned)?;
    Ok(owned)
}

fn capture_start<R: MemAccess, S: MemAccess>(reg_wdma: &R, reg_norm: &S, bufaddr: usize) {
    let x = (DVI_WIDTH - CAM_WIDTH) / 2;
    let y = (DVI_HEIGHT - CAM_HEIGHT) / 2;
    unsafe {
        reg_wdma.write_reg(REG_WDMA_PARAM_ADDR, bufaddr + y * BUF_STRIDE + x * 4);
        reg_wdma.write_reg(REG_WDMA_PARAM_STRIDE, BUF_STRIDE);
        reg_wdma.write_reg(REG_WDMA_PARAM_WIDTH, CAM_WIDTH);
        reg_wdma.write_reg(REG_WDMA_PARAM_HEIGHT, CAM_HEIGHT);
        reg_wdma.write_reg(REG_WDMA_PARAM_SIZE, CAM_WIDTH * CAM_HEIGHT);
        reg_wdma.write_reg(REG_WDMA_PARAM_AWLEN, 7);
        reg_wdma.write_reg(REG_WDMA_CTL_CONTROL, 0x03);

        reg_norm.write_reg(REG_NORM_FRM_TIMER_EN, 1);
        reg_norm.write_reg(REG_NORM_FRM_TIMEOUT, 100_000_000);
        reg_norm.write_reg(REG_NORM_PARAM_WIDTH, CAM_WIDTH);
        reg_norm.write_reg(REG_NORM_PARAM_HEIGHT, CAM_HEIGHT);
        reg_norm.write_reg(REG_NORM_PARAM_FILL, 0x0ff);
        reg_norm.write_reg(REG_NORM_PARAM_TIMEOUT, 0x100000);
        reg_norm.write_reg(REG_NORM_CONTROL, 0x03);
    }
}

fn capture_stop<R: MemAccess, S: MemAccess>(reg_wdma: &R, reg_norm: &S) {
    unsafe {
        reg_wdma.write_reg(REG_WDMA_CTL_CONTROL, 0x00);
        while reg_wdma.read_reg(REG_WDMA_CTL_STATUS) != 0 {
            thread::sleep(Duration::from_micros(100));
        }
        reg_norm.write_reg(REG_NORM_CONTROL, 0x00);
    }
}

fn vout_start<R: MemAccess, S: MemAccess>(reg_rdma: &R, reg_vsgen: &S, bufaddr: usize) {
    unsafe {
        reg_vsgen.write_reg(REG_VSGEN_PARAM_HTOTAL, 1650);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_HDISP_START, 0);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_HDISP_END, DVI_WIDTH);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_HSYNC_START, 1390);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_HSYNC_END, 1430);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_HSYNC_POL, 1);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_VTOTAL, 750);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_VDISP_START, 0);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_VDISP_END, DVI_HEIGHT);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_VSYNC_START, 725);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_VSYNC_END, 730);
        reg_vsgen.write_reg(REG_VSGEN_PARAM_VSYNC_POL, 1);
        reg_vsgen.write_reg(REG_VSGEN_CTL_CONTROL, 1);

        reg_rdma.write_reg(REG_RDMA_PARAM_ADDR, bufaddr);
        reg_rdma.write_reg(REG_RDMA_PARAM_STRIDE, BUF_STRIDE);
        reg_rdma.write_reg(REG_RDMA_PARAM_WIDTH, DVI_WIDTH);
        reg_rdma.write_reg(REG_RDMA_PARAM_HEIGHT, DVI_HEIGHT);
        reg_rdma.write_reg(REG_RDMA_PARAM_SIZE, DVI_WIDTH * DVI_HEIGHT);
        reg_rdma.write_reg(REG_RDMA_PARAM_ARLEN, 31);
        reg_rdma.write_reg(REG_RDMA_CTL_CONTROL, 0x03);
    }
}

fn vout_stop<R: MemAccess, S: MemAccess>(reg_rdma: &R, reg_vsgen: &S) {
    unsafe {
        reg_rdma.write_reg(REG_RDMA_CTL_CONTROL, 0x00);
        while reg_rdma.read_reg(REG_RDMA_CTL_STATUS) != 0 {
            thread::sleep(Duration::from_micros(100));
        }
        reg_vsgen.write_reg(REG_VSGEN_CTL_CONTROL, 0x00);
    }
}

fn oled_write_cmd<R: MemAccess>(reg_oled: &R, cmd: usize) {
    unsafe {
        reg_oled.write_reg(OLED_REG_DBUD, (cmd & 0xff) | 0x100);
    }
}

fn oled_setup<R: MemAccess>(reg_oled: &R) {
    unsafe {
        reg_oled.write_reg(OLED_REG_BS, 0x03);
        reg_oled.write_reg(OLED_REG_PWR_EN, 0x01);
    }
    thread::sleep(Duration::from_micros(10_000));
    unsafe {
        reg_oled.write_reg(OLED_REG_RES_N, 0x00);
    }
    thread::sleep(Duration::from_micros(10_000));
    unsafe {
        reg_oled.write_reg(OLED_REG_RES_N, 0x01);
    }
    thread::sleep(Duration::from_micros(10_000));

    oled_write_cmd(reg_oled, 0xFD);
    oled_write_cmd(reg_oled, 0x12);
    oled_write_cmd(reg_oled, OLED_CMD_DISPLAYOFF);
    oled_write_cmd(reg_oled, OLED_CMD_SETREMAP);
    oled_write_cmd(reg_oled, 0x32);
    oled_write_cmd(reg_oled, OLED_CMD_SETDISPLAYSTARTLINE);
    oled_write_cmd(reg_oled, 0x00);
    oled_write_cmd(reg_oled, OLED_CMD_SETDISPLAYOFFSET);
    oled_write_cmd(reg_oled, 0x00);
    oled_write_cmd(reg_oled, OLED_CMD_NORMALDISPLAY);
    oled_write_cmd(reg_oled, OLED_CMD_SETMULTIPLEXRATIO);
    oled_write_cmd(reg_oled, 0x3F);
    oled_write_cmd(reg_oled, OLED_CMD_SETMASTERCONFIGURE);
    oled_write_cmd(reg_oled, 0x8E);
    oled_write_cmd(reg_oled, OLED_CMD_POWERSAVEMODE);
    oled_write_cmd(reg_oled, 0x0B);
    oled_write_cmd(reg_oled, OLED_CMD_PHASEPERIODADJUSTMENT);
    oled_write_cmd(reg_oled, 0x31);
    oled_write_cmd(reg_oled, OLED_CMD_DISPLAYCLOCKDIV);
    oled_write_cmd(reg_oled, 0xF0);
    oled_write_cmd(reg_oled, OLED_CMD_SETPRECHARGESPEEDA);
    oled_write_cmd(reg_oled, 0x64);
    oled_write_cmd(reg_oled, OLED_CMD_SETPRECHARGESPEEDB);
    oled_write_cmd(reg_oled, 0x78);
    oled_write_cmd(reg_oled, OLED_CMD_SETPRECHARGESPEEDC);
    oled_write_cmd(reg_oled, 0x64);
    oled_write_cmd(reg_oled, OLED_CMD_SETPRECHARGEVOLTAGE);
    oled_write_cmd(reg_oled, 0x3A);
    oled_write_cmd(reg_oled, OLED_CMD_SETVVOLTAGE);
    oled_write_cmd(reg_oled, 0x3E);
    oled_write_cmd(reg_oled, OLED_CMD_MASTERCURRENTCONTROL);
    oled_write_cmd(reg_oled, 0x06);
    oled_write_cmd(reg_oled, OLED_CMD_SETCONTRASTA);
    oled_write_cmd(reg_oled, 0x91);
    oled_write_cmd(reg_oled, OLED_CMD_SETCONTRASTB);
    oled_write_cmd(reg_oled, 0x50);
    oled_write_cmd(reg_oled, OLED_CMD_SETCONTRASTC);
    oled_write_cmd(reg_oled, 0x7D);
    oled_write_cmd(reg_oled, OLED_CMD_DEACTIVESCROLLING);

    oled_write_cmd(reg_oled, OLED_CMD_SETGRAYSCALETABLE);
    for i in 0..32 {
        if i < 20 {
            oled_write_cmd(reg_oled, 0);
        } else {
            oled_write_cmd(reg_oled, 5);
        }
    }

    oled_write_cmd(reg_oled, OLED_CMD_CLEARWINDOW);
    oled_write_cmd(reg_oled, 0x00);
    oled_write_cmd(reg_oled, 0x00);
    oled_write_cmd(reg_oled, 95);
    oled_write_cmd(reg_oled, 63);
    thread::sleep(Duration::from_micros(100_000));

    unsafe {
        reg_oled.write_reg(OLED_REG_PWR_EN, 0x01);
    }
    thread::sleep(Duration::from_micros(10_000));

    oled_write_cmd(reg_oled, OLED_CMD_DISPLAYON);
    thread::sleep(Duration::from_micros(100_000));

    oled_write_cmd(reg_oled, OLED_CMD_SETCOLUMNADDRESS);
    oled_write_cmd(reg_oled, 0);
    oled_write_cmd(reg_oled, 95);
    oled_write_cmd(reg_oled, OLED_CMD_SETROWADDRESS);
    oled_write_cmd(reg_oled, 0);
    oled_write_cmd(reg_oled, 63);

    unsafe {
        reg_oled.write_reg(OLED_REG_VIN_EN, 0x01);
    }
}

fn oled_stop<R: MemAccess>(reg_oled: &R) {
    unsafe {
        reg_oled.write_reg(OLED_REG_VIN_EN, 0x00);
        reg_oled.write_reg(OLED_REG_PWR_EN, 0x00);
    }
}

fn create_cv_trackbar(trackbarname: &str, minval: i32, maxval: i32, inival: i32) -> opencv::Result<()> {
    let winname = "img";
    highgui::create_trackbar(trackbarname, winname, None, maxval, None)?;
    highgui::set_trackbar_min(trackbarname, winname, minval)?;
    highgui::set_trackbar_max(trackbarname, winname, maxval)?;
    highgui::set_trackbar_pos(trackbarname, winname, inival)?;
    Ok(())
}

fn get_cv_trackbar_pos(trackbarname: &str) -> opencv::Result<i32> {
    highgui::get_trackbar_pos(trackbarname, "img")
}
