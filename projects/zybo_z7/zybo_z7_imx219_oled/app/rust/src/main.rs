use std::error::Error;

use clap::Parser;
use jelly_lib::linux_i2c::LinuxI2c;
use jelly_mem_access::*;

use rtcl_p3s7_shared::camera_driver::*;
use rtcl_p3s7_shared::capture_driver::*;
use rtcl_p3s7_shared::timing_generator_driver::TimingGeneratorDriver;

const ZYBO_DPHY_SPEED_BPS: f64 = 950_000_000.0;
const ZYBO_FPS_COUNTER_CLOCK_HZ: f32 = 200_000_000.0;

const REG_BIN_PARAM_END   : usize =        0x04;
//const REG_BIN_PARAM_INV   : usize =        0x05;
const REG_BIN_TBL0        : usize =        0x40;
const REG_BIN_TBL1        : usize =        0x41;
const REG_BIN_TBL2        : usize =        0x42;
const REG_BIN_TBL3        : usize =        0x43;
const REG_BIN_TBL4        : usize =        0x44;
const REG_BIN_TBL5        : usize =        0x45;
const REG_BIN_TBL6        : usize =        0x46;
const REG_BIN_TBL7        : usize =        0x47;
const REG_BIN_TBL8        : usize =        0x48;
const REG_BIN_TBL9        : usize =        0x49;
const REG_BIN_TBL10       : usize =        0x4a;
const REG_BIN_TBL11       : usize =        0x4b;
const REG_BIN_TBL12       : usize =        0x4c;
const REG_BIN_TBL13       : usize =        0x4d;
const REG_BIN_TBL14       : usize =        0x4e;
//const REG_BIN_TBL15       : usize =        0x4f;
const REG_LPF_PARAM_ALPHA : usize =        0x08;


use opencv::*;
use opencv::core::*;

/// ZYBO Z7 RTCL P3S7 High Speed Camera Application
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Image width in pixels
    #[arg(short = 'W', long, default_value_t = 128)]
    width: usize,

    /// Image height in pixels
    #[arg(short = 'H', long, default_value_t = 128)]
    height: usize,

}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();
    
    println!("start zybo_z7_rtcl_p3s7_hs");
    println!("Configuration:");
    println!("  width:  {}", args.width);
    println!("  height: {}", args.height);
    println!("  dphy_speed[bps]: {}", ZYBO_DPHY_SPEED_BPS);
    println!("  fps_counter_clock[Hz]: {}", ZYBO_FPS_COUNTER_CLOCK_HZ);

    let width = args.width;
    let height = args.height;
    
    // Ctrl+C の設定
    let running = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(true));
    let r = running.clone();
    ctrlc::set_handler(move || {
        r.store(false, std::sync::atomic::Ordering::SeqCst);
    })?;

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

    let reg_sys      = uio_acc.subclone(0x0000_0000, 0x400);
    let reg_timgen   = uio_acc.subclone(0x0001_0000, 0x400);
    let reg_fmtr     = uio_acc.subclone(0x0010_0000, 0x400);
    let reg_wdma_img = uio_acc.subclone(0x0021_0000, 0x400);
    let reg_wdma_blk = uio_acc.subclone(0x0022_0000, 0x400);
    let reg_bin      = uio_acc.subclone(0x0030_0000, 0x400);
    let reg_lpf      = uio_acc.subclone(0x0032_0000, 0x400);
    let reg_hub75    = uio_acc.subclone(0x0040_0000, 0x400);

    println!("CORE ID");
    println!("reg_sys      : {:08x}", unsafe { reg_sys.read_reg(0) });
    println!("reg_timgen   : {:08x}", unsafe { reg_timgen.read_reg(0) });
    println!("reg_fmtr     : {:08x}", unsafe { reg_fmtr.read_reg(0) });
    println!("reg_wdma_img : {:08x}", unsafe { reg_wdma_img.read_reg(0) });
    println!("reg_wdma_blk : {:08x}", unsafe { reg_wdma_blk.read_reg(0) });

    unsafe {
        reg_sys.write_reg(0x0f, 1);
        
        reg_hub75.write_reg(0x04, 1); // HUB75 LED ON
        
        // 短すぎるパルスはスイッチが追いつかないので一旦ゼロにする
        reg_hub75.write_reg(0x20, 0);   // 1
        reg_hub75.write_reg(0x21, 0);   // 2
        reg_hub75.write_reg(0x22, 0);   // 4
        reg_hub75.write_reg(0x23, 0);   // 8
        reg_hub75.write_reg(0x24, 16);
        reg_hub75.write_reg(0x25, 32);
        reg_hub75.write_reg(0x26, 64);
        reg_hub75.write_reg(0x27, 128);
    }

    let mut timgen = TimingGeneratorDriver::new(reg_timgen);

    let i2c = LinuxI2c::new("/dev/i2c-0", 0x10)?;
    let mut cam = CameraDriver::new(i2c, reg_sys, reg_fmtr);
    cam.set_sensor_pgood_enable(false);
    cam.set_dphy_speed(ZYBO_DPHY_SPEED_BPS);
    cam.set_fps_counter_clock_hz(ZYBO_FPS_COUNTER_CLOCK_HZ);
    cam.set_image_size(width, height)?;
    cam.set_slave_mode(true)?;
    cam.set_trigger_mode(true)?;
    cam.open()?;
    std::thread::sleep(std::time::Duration::from_millis(1000));

    println!("camera module id      : {:04x}", cam.module_id()?);
    println!("camera module version : {:04x}", cam.module_version()?);
    println!("camera sensor id      : {:04x}", cam.sensor_id()?);

    let mut video_capture = CaptureDriver::new(reg_wdma_img, udmabuf_acc.clone())?;

    // ウィンドウ作成
    highgui::named_window("img", highgui::WINDOW_AUTOSIZE)?;
    highgui::resize_window("img", width as i32 + 64, height as i32 + 256)?;
    highgui::named_window("class", highgui::WINDOW_AUTOSIZE)?;
    highgui::resize_window("class", width as i32 + 64, height as i32 + 256)?;

    // トラックバー生成
    create_cv_trackbar("gain",       0,  200,   10)?;
    create_cv_trackbar("fps",       10, 1000, 1000)?;
    create_cv_trackbar("exposure",  10,  900,  900)?;
    create_cv_trackbar("lpf",       0,   255,  200)?;
    create_cv_trackbar("bin_th",    0,  1023,   64)?;


    // 画像表示ループ
    while running.load(std::sync::atomic::Ordering::SeqCst) {
        // ESC キーで終了
        let key = highgui::wait_key(10).unwrap();
        if key == 0x1b {
            break;
        }

        // トラックバー値取得
        let gain = (get_cv_trackbar_pos("gain")? as f32 - 10.0) / 10.0;
        let fps = get_cv_trackbar_pos("fps")? as f32;
        let exposure = get_cv_trackbar_pos("exposure")? as u16;
        let lpf = get_cv_trackbar_pos("lpf")? as usize;
        let bin_th = get_cv_trackbar_pos("bin_th")? as usize;

        // ゲイン設定
        cam.set_gain(gain)?;

        // us 単位に変換
        let period_us = 1000000.0 / fps;
        let exposure_us = period_us * (exposure as f32 / 1000.0);
        timgen.set_timing(period_us, exposure_us)?;

        // binarize / lpf パラメータ設定
        unsafe {
            reg_lpf.write_reg(REG_LPF_PARAM_ALPHA, lpf);
            let amp = 4;
            reg_bin.write_reg(REG_BIN_TBL0,  bin_th + (0x1*amp));
            reg_bin.write_reg(REG_BIN_TBL1,  bin_th + (0xf*amp));
            reg_bin.write_reg(REG_BIN_TBL2,  bin_th + (0x7*amp));
            reg_bin.write_reg(REG_BIN_TBL3,  bin_th + (0x9*amp));
            reg_bin.write_reg(REG_BIN_TBL4,  bin_th + (0x3*amp));
            reg_bin.write_reg(REG_BIN_TBL5,  bin_th + (0xd*amp));
            reg_bin.write_reg(REG_BIN_TBL6,  bin_th + (0x5*amp));
            reg_bin.write_reg(REG_BIN_TBL7,  bin_th + (0xb*amp));
            reg_bin.write_reg(REG_BIN_TBL8,  bin_th + (0x2*amp));
            reg_bin.write_reg(REG_BIN_TBL9,  bin_th + (0xe*amp));
            reg_bin.write_reg(REG_BIN_TBL10, bin_th + (0x6*amp));
            reg_bin.write_reg(REG_BIN_TBL11, bin_th + (0xa*amp));
            reg_bin.write_reg(REG_BIN_TBL12, bin_th + (0x4*amp));
            reg_bin.write_reg(REG_BIN_TBL13, bin_th + (0xc*amp));
            reg_bin.write_reg(REG_BIN_TBL14, bin_th + (0x8*amp));
            reg_bin.write_reg(REG_BIN_PARAM_END, 14);
//          reg_lpf.write_reg(REG_LPF_PARAM_ALPHA, 200);
        }

        // CaptureDriver で 1frame キャプチャ
        video_capture.record(width, height, 1)?;
        let src_bytes = video_capture.read_image_vec(0)?;
        let mut img_bytes = vec![0u8; height * width];
        let mut cls_bytes = vec![0u8; height * width];
        for y in 0..height {
            for x in 0..width {
                img_bytes[y*width+x] = src_bytes[(y*width+x)*2];
                cls_bytes[y*width+x] = src_bytes[(y*width+x)*2+1];
            }
        }
        let img = Mat::from_slice(&img_bytes)?;
        let img = img.reshape(1, height as i32)?;
        let class = Mat::from_slice(&cls_bytes)?;
        let class = class.reshape(1, height as i32)?;
        let mut cls = Mat::zeros_size(Size::new(width as i32, height as i32), CV_8UC3)?.to_mat()?;
        // クラスごとに色付け
        for y in 0..height as i32 {
            for x in 0..width as i32 {
                let c = *class.at_2d::<u8>(y, x)? as usize;
                let color = match c {
                    0 => [0, 0, 0],         // 黒 (black)
                    1 => [42, 42, 165],     // 茶 (brown)
                    2 => [0, 0, 255],       // 赤 (red)
                    3 => [0, 165, 255],     // 橙 (orange)
                    4 => [0, 255, 255],     // 黄 (yellow)
                    5 => [0, 255, 0],       // 緑 (green)
                    6 => [255, 0, 0],       // 青 (blue)
                    7 => [128, 0, 128],     // 紫 (purple)
                    8 => [192, 192, 192],   // 灰 (gray)
                    9 => [255, 255, 255],   // 白 (white)
                    _ => [64, 64, 64],      // 背景 (background)
                };
                *cls.at_2d_mut::<opencv::core::Vec3b>(y, x)? = opencv::core::Vec3b::from(color);
            }
        }
        
        // 表示
        highgui::imshow("img", &img)?;
        highgui::imshow("class", &cls)?;

        // キーボード操作
        let ch = key as u8 as char;
        match ch {
            'q' => { break; },
            'p' => {
                println!("fps : {:8.3} ({:8.3} ns)", cam.measure_fps(), cam.measure_frame_period());
            },
            'd' => {
                println!("write : dump.png");
                imgcodecs::imwrite("dump.png", &img, &Vector::<i32>::new())?;
            },
            'r' => {  // 動画記録
                // 日時のディレクトリを生成
                let now = chrono::Local::now();
                let _ = std::fs::create_dir("record");
                let dir_name = format!("record/{}", now.format("%Y%m%d-%H%M%S"));
                std::fs::create_dir(&dir_name).expect("Failed to create directory");
                println!("record to {}", dir_name);
                
                // 100フレーム録画
                let frames = 100;
                video_capture.record(width, height, frames)?;
                for f in 0..frames {
                   let img = video_capture.read_image_mat(f)?;
                    let mut view = Mat::default();
                    img.convert_to(&mut view, CV_16U, 64.0, 0.0)?;
                    let file_name = format!("{}/img{:04}.png", dir_name, f);
                    imgcodecs::imwrite(&file_name, &view, &Vector::<i32>::new())?;
                }
                println!("record done");
            },
            _ => {
            }
        }
    }

    unsafe {
        reg_hub75.write_reg(0x04, 0); // HUB75 LED OFF
    }

    cam.close()?;
    println!("done");

    Ok(())
}




fn create_cv_trackbar(trackbarname: &str, minval: i32, maxval: i32, inival: i32) -> opencv::Result<()> {
    let winname = "img";
    highgui::create_trackbar(trackbarname, &winname, None, maxval, None)?;
    highgui::set_trackbar_min(trackbarname, &winname, minval)?;
    highgui::set_trackbar_max(trackbarname, &winname, maxval)?;
    highgui::set_trackbar_pos(trackbarname, &winname, inival)?;
    Ok(())
}

fn get_cv_trackbar_pos(trackbarname: &str) -> opencv::Result<i32> {
    let winname = "img";
    let val = highgui::get_trackbar_pos(trackbarname, &winname)?;
    Ok(val)
}
