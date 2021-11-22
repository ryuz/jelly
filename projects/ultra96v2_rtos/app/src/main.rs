#![no_std]
#![no_main]
#![feature(asm)]

use core::ptr;
use core::panic::PanicInfo;

use pudding_pac::arm::cpu;
mod bootstrap;
mod rtos;

#[macro_use]
mod uart;
use uart::*;

mod memdump;
mod timer;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}


static mut STACK0: [u8; 4096] = [0; 4096];
static mut STACK1: [u8; 4096] = [0; 4096];


fn write_reg(reg: usize, data: u32) {
    let addr : usize = 0x80000000 + reg * 4;
    unsafe { ptr::write_volatile(addr as *mut u32, data); }
}

extern "C" fn task0() -> !
{
    println!("Task0");
    rtos::slp_tsk(-1);
    loop{}
}

extern "C" fn task1() -> !
{
    println!("Task1");
    rtos::slp_tsk(-1);
    loop{}
}

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000);
    println!("Hello world!");
    wait(10000);

    rtos::initialize();

    rtos::cre_tsk(0, &mut STACK0, task0);
    rtos::cre_tsk(1, &mut STACK1, task1);

    rtos::wup_tsk(1);
    rtos::wup_tsk(0);


    memdump::memdump(0x80000000, 4);
//  memdump::memdump(0x80000400, 4);

    cpu::irq_enable();
    
    /*
    write_reg(0x0104, 0);
    memdump::memdump(0x80000000 + (0x110 << 2), 4);
    memdump::memdump(0x80000000 + (0x100 << 2), 4);

    write_reg(0x0110, 1); // en
    memdump::memdump(0x80000000 + (0x110 << 2), 4);
    memdump::memdump(0x80000000 + (0x100 << 2), 4);

    println!("wup_tsk_start");
    write_reg(0x1001, 0);
    println!("wup_tsk_end");
//  wait(1000000);
    memdump::memdump(0x80000000 + (0x110 << 2), 4);
    memdump::memdump(0x80000000 + (0x100 << 2), 4);

//  write_reg(0x1000, 0);
//  write_reg(0x1100, 0);
    write_reg(0x1101, 0);
    memdump::memdump(0x80000000 + (0x110 << 2), 4);
    memdump::memdump(0x80000000 + (0x100 << 2), 4);
    write_reg(0x0110, 0); // irq dis
    memdump::memdump(0x80000000 + (0x110 << 2), 4);
    memdump::memdump(0x80000000 + (0x100 << 2), 4);
    */

    println!("\n\nend");
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

static mut IRQ_COUNT: i32 = 0;

// 割り込みハンドラ
#[no_mangle]
pub unsafe extern "C" fn irq_handler() {
    write_reg(0x0110, 0); // irq dis
    print!("@");
    wait(10000);
    IRQ_COUNT += 1;
    if IRQ_COUNT > 5 {
        loop {
            wait(100000);
        }
    }
}

