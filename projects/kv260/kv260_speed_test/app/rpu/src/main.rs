#![no_std]
#![no_main]

use core::panic::PanicInfo;
//use pudding_pac::arm::cpu;
mod bootstrap;

//mod rtos;

//use jelly_rtos::rtos;

#[macro_use]
pub mod uart;
use uart::*;
//mod timer;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    // start
    wait(1000000);
    println!("\nJelly PL Speed Test\n");

    // アイドルループ
    loop {
        read_write(0x80000000);
        read_test(0x80000000);
        write_test(0x80000000);
        wait(10000);
        read_write(0xa0000000);
        read_test(0xa0000000);
        write_test(0xa0000000);
        wait(10000);
        read_test(0xb0000000);
        write_test(0xb0000000);
        wait(10000);
    }
}

pub fn read_test(addr: usize) {
    unsafe {
        for _i in 0..64 {
            let _ = core::ptr::read_volatile(addr as *mut u32);
        }
    }
}

pub fn write_test(addr: usize) {
    unsafe {
        for i in 0..64 {
            core::ptr::write_volatile(addr as *mut u32, i);
        }
    }
}

pub fn read_write(addr: usize) {
    unsafe {
        for _i in 0..64 {
            let v = core::ptr::read_volatile(addr as *mut u32);
            core::ptr::write_volatile(addr as *mut u32, v);
        }
    }
}

// ループによるウェイト
fn wait(n: i32) {
    let mut v: i32 = 0;
    for i in 1..n {
        unsafe { core::ptr::write_volatile(&mut v, i) };
    }
}

#[allow(dead_code)]
pub fn memdump(addr: usize, len: usize) {
    unsafe {
        for offset in 0..len {
            if offset % 4 == 0 {
                print!("{:08X}:", addr + offset * 4);
            }
            print!(
                " {:08X}",
                core::ptr::read_volatile((addr + offset * 4) as *mut u32)
            );
            if offset % 4 == 3 || offset + 1 == len {
                println!("");
            }
        }
    }
}
