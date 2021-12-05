#![no_std]
#![no_main]
#![feature(asm)]

use pudding_pac::arm::cpu;
use core::panic::PanicInfo;
mod bootstrap;
mod i2c;

use jelly_rtos::rtos;


#[macro_use]
pub mod uart;
use uart::*;
//mod timer;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}


static mut STACK1: [u8; 4096] = [0; 4096];
/*
static mut STACK2: [u8; 4096] = [0; 4096];
static mut STACK3: [u8; 4096] = [0; 4096];
static mut STACK4: [u8; 4096] = [0; 4096];
static mut STACK5: [u8; 4096] = [0; 4096];
*/

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000000);
    println!("\nJelly-RTOS start\n");
    wait(10000);

//  memdump(0x80000000, 16);

    rtos::initialize(0x80000000);

    println!("core_id      : {:08x}", rtos::core_id     ());
    println!("core_version : {:08x}", rtos::core_version());
    println!("core_date    : {:08x}", rtos::core_date   ());
    println!("clock_rate   : {}", rtos::clock_rate  ());
    println!("max_tskid    : {}", rtos::max_tskid   ());
    println!("max_semid    : {}", rtos::max_semid   ());
    println!("max_flgid    : {}", rtos::max_flgid   ());
    println!("tskpri_width : {}", rtos::tskpri_width());
    println!("semcnt_width : {}", rtos::semcnt_width());
    println!("flgptn_width : {}", rtos::flgptn_width());
    println!("systim_width : {}", rtos::systim_width());
    println!("reltim_width : {}", rtos::reltim_width());
    

    // タスクスタート
    rtos::cre_tsk(1, &mut STACK1, task1);
    rtos::wup_tsk(1);
    

    /*
    rtos::cre_tsk(2, &mut STACK2, task2);
    rtos::cre_tsk(3, &mut STACK3, task3);
    rtos::cre_tsk(4, &mut STACK4, task4);
    rtos::cre_tsk(5, &mut STACK5, task5);
    rtos::wup_tsk(1);
    rtos::wup_tsk(2);
    rtos::wup_tsk(3);
    rtos::wup_tsk(4);
    rtos::wup_tsk(5);
    */

    // アイドルループ
    loop {
//        print!(".");
//        wait(10000000);
        cpu::wfi();
    }
}

const MPU9250_ADDRESS: u8 =     0x68;    // 7bit address
//const AK8963_ADDRESS: u8 =      0x0C;    // Address of magnetometer

extern "C" fn task1() -> ! {
    println!("task1 start");
    let i2c = i2c::JellyI2c::new(0x80080000);
    i2c.set_divider(20*2);

    
//    i2c.write1(MPU9250_ADDRESS, 0x77);
//    let hoge = i2c.read1(MPU9250_ADDRESS);
//    println!("hoge:0x{:02x}", hoge);
    
    rtos::set_scratch(0, 1);
    i2c.write1(MPU9250_ADDRESS, 0x75);
    let who_am_i = i2c.read1(MPU9250_ADDRESS);
    rtos::set_scratch(0, 0);
    println!("?WHO_AM_I(exp:0x71):0x{:02x}", who_am_i);

    i2c.write1(MPU9250_ADDRESS, 0x77);
    let hoge = i2c.read1(MPU9250_ADDRESS);
    println!("hoge:0x{:02x}", hoge);

    let array: [u8; 3] = [1, 2, 3]; 
    i2c.write(MPU9250_ADDRESS, &array);
    i2c.write(MPU9250_ADDRESS, &[1, 2, 3]);

    rtos::slp_tsk(-1);

    loop {
        wait(100000);
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
