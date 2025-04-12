#![no_main]
#![no_std]

#[macro_use]
mod uart;
use uart::*;

//mod i2c_access_imx219;
//mod i2c_imx219;
mod imx219_control;
use imx219_control::Imx219Control;

use jelly_mem_access::*;
use jelly_pac::i2c::*;


use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}



const REG_LED: usize  = 0x10000100;
const REG_GPIO: usize = 0x10000104;

const IMX219_DEVADR: u8 =     0x10;    // 7bit address

#[no_mangle]
pub unsafe extern "C" fn main() -> Result<(), &'static str> {
    println!("start");

    type I2cAccessor = PhysAccessor<u32, 0x10000200, 0x100>;
    let  i2c = JellyI2c::<I2cAccessor>::new(I2cAccessor::new().into(), None);

    cpu_wait();
    wrtie_reg(REG_GPIO, 0);
    cpu_wait();
    wrtie_reg(REG_GPIO, 1);
    cpu_wait();

    
    let mut model_id: [u8; 2] = [0u8; 2];
    i2c.write(IMX219_DEVADR, &[0x00, 0x00]);
    i2c.read(IMX219_DEVADR, &mut model_id);
    println!("model_id: 0x{:02x}{:02x}", model_id[0], model_id[1]);

    ////////////
    let mut imx219 = Imx219Control::new();

        println!("reset");
        imx219.reset()?;

        // カメラID取得
        println!("sensor model ID:{:04x}", imx219.get_model_id().unwrap());

        // camera 設定
        let pixel_clock: f64 = 91000000.0;
        let binning: bool = true;
        let width: i32 = 1280;
        let height: i32 = 720;
        let aoi_x: i32 = -1;
        let aoi_y: i32 = -1;
        imx219.set_pixel_clock(pixel_clock)?;
        imx219.set_aoi(width, height, aoi_x, aoi_y, binning, binning)?;
        imx219.start()?;

        // 設定
        let frame_rate: i32 = 60;
        let exposure: i32 = 20;
        let a_gain: i32 = 20;
        let d_gain: i32 = 0;
        let flip_h: bool = false;
        let flip_v: bool = false;
        imx219.set_frame_rate(frame_rate as f64)?;
        imx219.set_exposure_time(exposure as f64 / 1000.0)?;
        imx219.set_gain(a_gain as f64)?;
        imx219.set_digital_gain(d_gain as f64)?;
        imx219.set_flip(flip_h, flip_v)?;

        let id = imx219.get_model_id()?;
        println!("model_id: 0x{:04x}", id);

        imx219.setup()?;
        println!("end!");
        loop {
        }

    let mut i = 0;
    loop {
        println!("Hello world (Rust) {}", i);
        wrtie_reg(REG_LED, i >> 8);
        i += 1;

        let mut model_id: [u8; 2] = [0u8; 2];
        i2c.write(IMX219_DEVADR, &[0x00, 0x00]);
        cpu_wait();
        i2c.read(IMX219_DEVADR, &mut model_id);
        println!("model_id: 0x{:02x}{:02x}", model_id[0], model_id[1]);
    }
    Ok(())
}


fn cpu_wait() {
    let mut v = 0;
    let p = &mut v as *mut i32;
    for i in 0..100000 {
        unsafe {
            core::ptr::write_volatile(p, i);
        }
    }
}


// レジスタ書き込み
#[allow(dead_code)]
fn wrtie_reg(adr: usize, data: u32) {
    let p = adr as *mut u32;
    unsafe {
        core::ptr::write_volatile(p, data);
    }
}

// レジスタ読み出し
#[allow(dead_code)]
fn read_reg(adr: usize) -> u32 {
    let p = adr as *mut u32;
    unsafe { core::ptr::read_volatile(p) }
}
