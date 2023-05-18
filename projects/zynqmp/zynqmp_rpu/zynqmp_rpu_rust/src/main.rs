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

#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    println!("Hello world (Rust)");

    if cfg!(target_arch = "arm") {
        println!("arm arch is enabled.");
    } else {
        println!("arm arch is not enabled.");
    }

    if cfg!(target_feature = "v7") {
        println!("v7 feature is enabled.");
    } else {
        println!("v7 feature is not enabled.");
    }

    if cfg!(target_feature = "vfpv2") {
        println!("vfp2 feature is enabled.");
    } else {
        println!("vfp2 feature is not enabled.");
    }

    if cfg!(target_feature = "vfpv3") {
        println!("vfp3 feature is enabled.");
    } else {
        println!("vfp3 feature is not enabled.");
    }

    if cfg!(target_feature = "vfpv3-d16") {
        println!("vfpv3-d16 feature is enabled.");
    } else {
        println!("vfpv3-d16 feature is not enabled.");
    }

    if cfg!(target_feature = "vfp3-d32") {
        println!("vfp3-d32 feature is enabled.");
    } else {
        println!("vfp3-d32 feature is not enabled.");
    }

    loop {}
}

