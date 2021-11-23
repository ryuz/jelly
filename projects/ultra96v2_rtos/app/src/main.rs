#![no_std]
#![no_main]
#![feature(asm)]

use core::panic::PanicInfo;
use core::ptr;

use pudding_pac::arm::cpu;
mod bootstrap;
mod rtos;

#[macro_use]
pub mod uart;
use uart::*;

//mod memdump;
mod timer;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

static mut STACK0: [u8; 4096] = [0; 4096];
static mut STACK1: [u8; 4096] = [0; 4096];

fn write_reg(reg: usize, data: u32) {
    let addr: usize = 0x80000000 + reg * 4;
    unsafe {
        ptr::write_volatile(addr as *mut u32, data);
    }
}

pub fn memdump(addr: usize, len: usize) {
    return;
    wait(10000);
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


extern "C" fn task0() -> ! {
    println!("Task0");
    println!("slp_tsk(0)");
    rtos::slp_tsk(-1);
    println!("Task0");
    rtos::slp_tsk(-1);
    loop {}
}

extern "C" fn task1() -> ! {
    println!("Task1");
    println!("slp_tsk(0)");
    rtos::wup_tsk(0);
    println!("slp_tsk(1)");
    rtos::slp_tsk(-1);
    loop {}
}

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000);
    println!("\nJelly-RTOS start");
    wait(10000);

    memdump(0x80000000 + (0x0100 << 2), 4);
    memdump(0x80000000 + (0x0104 << 2), 4);
    memdump(0x80000000 + (0x0110 << 2), 4);

    rtos::initialize();

    memdump(0x80000000 + (0x0100 << 2), 4);
    memdump(0x80000000 + (0x0104 << 2), 4);
    memdump(0x80000000 + (0x0110 << 2), 4);

    rtos::cre_tsk(0, &mut STACK0, task0);
    rtos::cre_tsk(1, &mut STACK1, task1);

//    rtos::test();
    wait(10000);

//  cpu::irq_enable();

//    println!("\nend\n");
//    loop{}

    //    cpu::irq_disable();
    
    memdump(0x80000000 + (0x0100 << 2), 4);
    memdump(0x80000000 + (0x0104 << 2), 4);
    memdump(0x80000000 + (0x0110 << 2), 4);

    println!("wup_tsk(0)");
    rtos::wup_tsk(0);
    cpu::svc0();

    println!("wup_tsk(1)");
    rtos::wup_tsk(1);

    memdump(0x80000000 + (0x0100 << 2), 4);
    memdump(0x80000000 + (0x0104 << 2), 4);
    memdump(0x80000000 + (0x0110 << 2), 4);

//    println!("wup_tsk(0)");
//    rtos::wup_tsk(0);

    memdump(0x80000000 + (0x0100 << 2), 4);
    memdump(0x80000000 + (0x0104 << 2), 4);
    memdump(0x80000000 + (0x0110 << 2), 4);

    println!("\nend");
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
