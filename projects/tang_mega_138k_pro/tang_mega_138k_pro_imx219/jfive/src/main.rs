#![no_main]
#![no_std]

#[macro_use]
mod uart;
use uart::*;

//mod i2c_access_imx219;
//mod i2c_imx219;
mod imx219_control;

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
pub unsafe extern "C" fn main() -> ! {
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
    println!("end!");
    loop {}

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
