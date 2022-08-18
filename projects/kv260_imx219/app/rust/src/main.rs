#![allow(dead_code)]

use std::error::Error;
use std::thread;
use std::time::Duration;

use jelly_mem_access::*;

use opencv::{
    prelude::*,
    core::*,
    imgcodecs::*,
    highgui::*,
};

mod imx219_control;
use imx219_control::*;

use i2cdev::core::*;
use i2cdev::linux::LinuxI2CDevice;

impl I2cAccess for LinuxI2CDevice {
    fn write(&mut self, data: &[u8]) -> Result<(), Box<dyn Error>> {
        match I2CDevice::write(self, data) {
            Ok(f) => Ok(f),
            Err(error) => Err(Box::new(error)),
        }
    }

    fn read(&mut self, buf: &mut [u8]) -> Result<(), Box<dyn Error>> {
        match I2CDevice::read(self, buf) {
            Ok(f) => Ok(f),
            Err(error) => Err(Box::new(error)),
        }
    }
}


/* Video format regularizer */
const REG_VIDEO_FMTREG_CORE_ID           : usize =  0x00;
const REG_VIDEO_FMTREG_CORE_VERSION      : usize =  0x01;
const REG_VIDEO_FMTREG_CTL_CONTROL       : usize =  0x04;
const REG_VIDEO_FMTREG_CTL_STATUS        : usize =  0x05;
const REG_VIDEO_FMTREG_CTL_INDEX         : usize =  0x07;
const REG_VIDEO_FMTREG_CTL_SKIP          : usize =  0x08;
const REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN  : usize =  0x0a;
const REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT   : usize =  0x0b;
const REG_VIDEO_FMTREG_PARAM_WIDTH       : usize =  0x10;
const REG_VIDEO_FMTREG_PARAM_HEIGHT      : usize =  0x11;
const REG_VIDEO_FMTREG_PARAM_FILL        : usize =  0x12;
const REG_VIDEO_FMTREG_PARAM_TIMEOUT     : usize =  0x13;

/* Demosaic */
const REG_IMG_DEMOSAIC_CORE_ID        : usize =         0x00;
const REG_IMG_DEMOSAIC_CORE_VERSION   : usize =         0x01;
const REG_IMG_DEMOSAIC_CTL_CONTROL    : usize =         0x04;
const REG_IMG_DEMOSAIC_CTL_STATUS     : usize =         0x05;
const REG_IMG_DEMOSAIC_CTL_INDEX      : usize =         0x07;
const REG_IMG_DEMOSAIC_PARAM_PHASE    : usize =         0x08;
const REG_IMG_DEMOSAIC_CURRENT_PHASE  : usize =         0x18;

/* Video Write-DMA */
const REG_VIDEO_WDMA_CORE_ID           : usize =       0x00;
const REG_VIDEO_WDMA_VERSION           : usize =       0x01;
const REG_VIDEO_WDMA_CTL_CONTROL       : usize =       0x04;
const REG_VIDEO_WDMA_CTL_STATUS        : usize =       0x05;
const REG_VIDEO_WDMA_CTL_INDEX         : usize =       0x07;
const REG_VIDEO_WDMA_PARAM_ADDR        : usize =       0x08;
const REG_VIDEO_WDMA_PARAM_STRIDE      : usize =       0x09;
const REG_VIDEO_WDMA_PARAM_WIDTH       : usize =       0x0a;
const REG_VIDEO_WDMA_PARAM_HEIGHT      : usize =       0x0b;
const REG_VIDEO_WDMA_PARAM_SIZE        : usize =       0x0c;
const REG_VIDEO_WDMA_PARAM_AWLEN       : usize =       0x0f;
const REG_VIDEO_WDMA_MONITOR_ADDR      : usize =       0x10;
const REG_VIDEO_WDMA_MONITOR_STRIDE    : usize =       0x11;
const REG_VIDEO_WDMA_MONITOR_WIDTH     : usize =       0x12;
const REG_VIDEO_WDMA_MONITOR_HEIGHT    : usize =       0x13;
const REG_VIDEO_WDMA_MONITOR_SIZE      : usize =       0x14;
const REG_VIDEO_WDMA_MONITOR_AWLEN     : usize =       0x17;



fn main() -> Result<(), Box<dyn Error>> {
    // start
    println!("start");

//    let img = imread("ryuji.jpg", 1).unwrap();
//    let img = Mat::zeros(640, 480, CV_8UC3).unwrap();
//    opencv::highgui::imshow("img", &img);
//    opencv::highgui::wait_key(0);

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

    // mmap udmabuf
    let udmabuf_device_name = "udmabuf-jelly-vram0";
    println!("\nudmabuf open");
    let udmabuf_acc = UdmabufAccessor::<usize>::new(udmabuf_device_name, false).expect("Failed to open udmabuf");
    println!("{} phys addr : 0x{:x}", udmabuf_device_name, udmabuf_acc.phys_addr());
    println!("{} size      : 0x{:x}", udmabuf_device_name, udmabuf_acc.size());
    

    // UIO
    println!("\nuio open");
    let uio_acc = UioAccessor::<usize>::new_with_name("uio_pl_peri").expect("Failed to open uio");
    println!("uio_pl_peri phys addr : 0x{:x}", uio_acc.phys_addr());
    println!("uio_pl_peri size      : 0x{:x}", uio_acc.size());

    let reg_gid    = uio_acc.subclone(0x00000000, 0x200);
    let reg_fmtr   = uio_acc.subclone(0x00100000, 0x200);
    let reg_demos  = uio_acc.subclone(0x00120000, 0x200);
    let reg_colmat = uio_acc.subclone(0x00120800, 0x200);
    let reg_wdma   = uio_acc.subclone(0x00210000, 0x200);
    
    println!("CORE ID");
    unsafe {
        println!("reg_gid    : {:08x}", reg_gid.read_reg(0)    );
        println!("uio_acc    : {:08x}", uio_acc.read_reg(0)    );
        println!("reg_fmtr   : {:08x}", reg_fmtr.read_reg(0)   );
        println!("reg_demos  : {:08x}", reg_demos.read_reg(0)  );
        println!("reg_colmat : {:08x}", reg_colmat.read_reg(0) );
        println!("reg_wdma   : {:08x}", reg_wdma.read_reg(0)   );
    }


    // カメラON
    unsafe {
        uio_acc.write_reg(2, 1);
    }
    thread::sleep(Duration::from_millis(500));

    // IMX219 control
    let i2c = Box::new(LinuxI2CDevice::new("/dev/i2c-6", 0x10).expect("Failed to open i2c"));
    let mut imx219 = Imx219Control::new(i2c);

    imx219.reset();

    // カメラID取得
    println!("sensor model ID:{:04x}", imx219.get_model_id().unwrap());
//  std::cout << "Model ID : " << std::hex << std::setfill('0') << std::setw(4) << imx219.GetModelId() << std::endl;

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
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width as usize);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height as usize);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_FILL,        0x100);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
        reg_fmtr.write_reg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    }
    thread::sleep(Duration::from_millis(100));

    loop {
        let key = opencv::highgui::wait_key(10).unwrap();
        if key == 0x1b { break; }

        // 設定
        imx219.set_frame_rate(frame_rate as f64);
        imx219.set_exposure_time(exposure as f64 / 1000.0);
        imx219.set_gain(a_gain as f64);
        imx219.set_digital_gain(d_gain as f64);
        imx219.set_flip(flip_h, flip_v);

        unsafe {
            reg_demos.write_regi32(REG_IMG_DEMOSAIC_PARAM_PHASE, bayer_phase);
            reg_demos.write_reg(REG_IMG_DEMOSAIC_CTL_CONTROL, 3);  // update & enable
        }

        // キャプチャ
        // DMA start (one shot)
        unsafe {
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_ADDR,   udmabuf_acc.phys_addr());
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_STRIDE, (width*4) as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_WIDTH,  width as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_HEIGHT, height as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_SIZE,   (width*height*1) as usize);
            reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_AWLEN,  31);
            reg_wdma.write_reg(REG_VIDEO_WDMA_CTL_CONTROL,  0x07);
        }

        // 取り込み完了を待つ
        thread::sleep(Duration::from_millis(10));
        while ( unsafe{reg_wdma.read_reg(REG_VIDEO_WDMA_CTL_STATUS)} != 0 ) {
            thread::sleep(Duration::from_millis(10));
        }
        
        let mut buf = vec![0u8; (width * height * 4) as usize];
        unsafe {
            udmabuf_acc.copy_to(0, buf.as_mut_ptr(), (width * height * 4) as usize);

            let img = Mat::new_rows_cols_with_data(height, width, CV_8UC4, buf.as_mut_ptr(), width*4).unwrap();
            opencv::highgui::imshow("img", &img);
        }


        /*
//      vdmaw.Oneshot(dmabuf_phys_adr, width, height, frame_num);
//      capture_still_image(reg_wdma, reg_fmtr, dmabuf_phys_adr, width, height, frame_num);
        cv::Mat img(height*frame_num, width, CV_8UC4);
        udmabuf_acc.MemCopyTo(img.data, 0, width * height * 4 * frame_num);
        
        // 表示
        cv::Mat view_img;
        cv::resize(img, view_img, cv::Size(), 1.0/view_scale, 1.0/view_scale);

        cv::imshow("img", view_img);
        cv::createTrackbar("scale",    "img", &view_scale, 4);
        cv::createTrackbar("fps",      "img", &frame_rate, 1000);
        cv::createTrackbar("exposure", "img", &exposure, 1000);
        cv::createTrackbar("a_gain",   "img", &a_gain, 20);
        cv::createTrackbar("d_gain",   "img", &d_gain, 24);
        cv::createTrackbar("bayer" ,   "img", &bayer_phase, 3);

        // ユーザー操作
        switch ( key ) {
        case 'p':
            std::cout << "pixel clock   : " << imx219.GetPixelClock()   << " [Hz]"  << std::endl;
            std::cout << "frame rate    : " << imx219.GetFrameRate()    << " [fps]" << std::endl;
            std::cout << "exposure time : " << imx219.GetExposureTime() << " [s]"   << std::endl;
            std::cout << "analog  gain  : " << imx219.GetGain()         << " [db]"  << std::endl;
            std::cout << "digital gain  : " << imx219.GetDigitalGain()  << " [db]"  << std::endl;
            std::cout << "AOI width     : " << imx219.GetAoiWidth()  << std::endl;
            std::cout << "AOI height    : " << imx219.GetAoiHeight() << std::endl;
            std::cout << "AOI x         : " << imx219.GetAoiX() << std::endl;
            std::cout << "AOI y         : " << imx219.GetAoiY() << std::endl;
            std::cout << "flip h        : " << imx219.GetFlipH() << std::endl;
            std::cout << "flip v        : " << imx219.GetFlipV() << std::endl;
            break;
        
        // flip
        case 'h':  flip_h = !flip_h;  break;
        case 'v':  flip_v = !flip_v;  break;
        
        // aoi position
        case 'w':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() - 4);    break;
        case 'z':  imx219.SetAoiPosition(imx219.GetAoiX(), imx219.GetAoiY() + 4);    break;
        case 'a':  imx219.SetAoiPosition(imx219.GetAoiX() - 4, imx219.GetAoiY());    break;
        case 's':  imx219.SetAoiPosition(imx219.GetAoiX() + 4, imx219.GetAoiY());    break;

        case 'd':   // image dump
            {
                cv::Mat imgRgb;
                cv::cvtColor(img, imgRgb, CV_BGRA2BGR);
                cv::imwrite("img_dump.png", imgRgb);
            }
            break;

        case 'r': // image record
            std::cout << "record" << std::endl;
//          capture_still_image(reg_wdma, reg_fmtr, dmabuf_phys_adr, width, height, rec_frame_num);
            vdmaw.Oneshot(dmabuf_phys_adr, width, height, rec_frame_num);
            int offset = 0;
            for ( int i = 0; i < rec_frame_num; i++ ) {
                char fname[64];
                sprintf(fname, "rec_%04d.png", i);
                cv::Mat imgRec(height, width, CV_8UC4);
                udmabuf_acc.MemCopyTo(imgRec.data, offset, width * height * 4);
                offset += width * height * 4;
                cv::Mat imgRgb;
                cv::cvtColor(imgRec, imgRgb, CV_BGRA2BGR);
                cv::imwrite(fname, imgRgb);
            }
            break;
        }
        */
    }

    // close
    imx219.stop();


    println!("Hello, world!");

    Ok(())
}



/*
// 静止画キャプチャ
fn capture_still_image(reg_wdma: MemAccessor, bufaddr: usize, width: i32, height: i32, frame_num: i32)
{
    // DMA start (one shot)
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_ADDR,   bufaddr);
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_STRIDE, width*4);
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_WIDTH,  width);
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_HEIGHT, height);
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_SIZE,   width*height*frame_num);
    reg_wdma.write_reg(REG_VIDEO_WDMA_PARAM_AWLEN,  31);
    reg_wdma.write_reg(REG_VIDEO_WDMA_CTL_CONTROL,  0x07);
    
    // video format regularizer
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMER_EN,  1);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_FRM_TIMEOUT,   10000000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_WIDTH,       width);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_HEIGHT,      height);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_FILL,        0x100);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_PARAM_TIMEOUT,     100000);
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL,       0x03);
    usleep(100000);
    
    // 取り込み完了を待つ
    usleep(10000);
    while ( reg_wdma.ReadReg(REG_VIDEO_WDMA_CTL_STATUS) != 0 ) {
        usleep(10000);
    }
    
    // normalizer stop
    /*
    reg_fmtr.WriteReg(REG_VIDEO_FMTREG_CTL_CONTROL, 0x00);
    usleep(1000);
    while ( reg_wdma.ReadReg(REG_VIDEO_FMTREG_CTL_STATUS) != 0 ) {
        usleep(1000);
    }
    */
}

*/