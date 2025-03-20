#![no_main]
#![no_std]

#[macro_use]
mod uart;
use uart::*;

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}



const REG_LED: usize = 0x10000100; // UART


#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    let mut i = 0;
    loop {
        println!("Hello world (Rust) {}", i);
        wrtie_reg(REG_LED, i);
        i += 1;
    }
}



// レジスタ書き込み
fn wrtie_reg(adr: usize, data: u32) {
    let p = adr as *mut u32;
    unsafe {
        core::ptr::write_volatile(p, data);
    }
}

// レジスタ読み出し
fn read_reg(adr: usize) -> u32 {
    let p = adr as *mut u32;
    unsafe { core::ptr::read_volatile(p) }
}
