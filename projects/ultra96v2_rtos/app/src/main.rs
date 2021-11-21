#![no_std]
#![no_main]
#![feature(asm)]

use pudding_pac::arm::cpu;
use pudding_pac::arm::pl390::Pl390;

mod bootstrap;

#[macro_use]
mod uart;
use uart::*;
mod memdump;
mod timer;

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000);
    println!("Hello world!");
    wait(10000);
    memdump::memdump(0x80000000, 4);
    loop {
        wait(1000000);
    }
}

// ループによるウェイト
fn wait(n: i32) {
    let mut v: i32 = 0;
    for i in 1..n {
        unsafe { core::ptr::write_volatile(&mut v, i) };
    }
}

// 割り込みハンドラ
#[no_mangle]
pub unsafe extern "C" fn irq_handler() {
}

