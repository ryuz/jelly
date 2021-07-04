#![no_main]
#![no_std]

mod hw_setup;

#[macro_use]
mod uart;
use uart::*;

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    println!("Hello world");
    loop {}
}
