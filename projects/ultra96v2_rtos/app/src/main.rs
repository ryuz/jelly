#![no_std]
#![no_main]
#![feature(asm)]

use core::panic::PanicInfo;
use pudding_pac::arm::cpu;
mod bootstrap;

//mod rtos;

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
static mut STACK2: [u8; 4096] = [0; 4096];
static mut STACK3: [u8; 4096] = [0; 4096];
static mut STACK4: [u8; 4096] = [0; 4096];
static mut STACK5: [u8; 4096] = [0; 4096];

// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    // start
    wait(1000000);
    println!("\nJelly-RTOS start\n");

    // start
    rtos::initialize(0x80000000);

    println!("core_id      : {:08x}", rtos::core_id());
    println!("core_version : {:08x}", rtos::core_version());
    println!("core_date    : {:08x}", rtos::core_date());
    println!("clock_rate   : {}", rtos::clock_rate());
    println!("max_tskid    : {}", rtos::max_tskid());
    println!("max_semid    : {}", rtos::max_semid());
    println!("max_flgid    : {}", rtos::max_flgid());
    println!("tskpri_width : {}", rtos::tskpri_width());
    println!("semcnt_width : {}", rtos::semcnt_width());
    println!("flgptn_width : {}", rtos::flgptn_width());
    println!("systim_width : {}", rtos::systim_width());
    println!("reltim_width : {}", rtos::reltim_width());
    println!("");

    // 時間単位を us 単位にする
    let pscl:u32 = rtos::clock_rate() / 1000000 - 1;
    println!("set_pscl({})\n", pscl);
    rtos::set_pscl(pscl);

    // フォークを５本置く
    rtos::sig_sem(1);
    rtos::sig_sem(2);
    rtos::sig_sem(3);
    rtos::sig_sem(4);
    rtos::sig_sem(5);

    // 哲学者を5人用意
    rtos::cre_tsk(1, &mut STACK1, task1);
    rtos::cre_tsk(2, &mut STACK2, task2);
    rtos::cre_tsk(3, &mut STACK3, task3);
    rtos::cre_tsk(4, &mut STACK4, task4);
    rtos::cre_tsk(5, &mut STACK5, task5);
    rtos::wup_tsk(1);
    rtos::wup_tsk(2);
    rtos::wup_tsk(3);
    rtos::wup_tsk(4);
    rtos::wup_tsk(5);

    // アイドルループ
    loop {
        cpu::wfi();
    }
}

extern "C" fn task1() -> ! {
    dining_philosopher(1);
}
extern "C" fn task2() -> ! {
    dining_philosopher(2);
}
extern "C" fn task3() -> ! {
    dining_philosopher(3);
}
extern "C" fn task4() -> ! {
    dining_philosopher(4);
}
extern "C" fn task5() -> ! {
    dining_philosopher(5);
}

fn dining_philosopher(id: i32) -> ! {
    let left = id;
    let right = id % 5 + 1;
    println!("[philosopher{}] dining start", id);
    loop {
        println!("[philosopher{}] thinking", id);
        rtos::dly_tsk(rand_time());

        'dining: loop {
            rtos::wai_sem(left);
            {
                if rtos::pol_sem(right) {
                    println!("[philosopher{}] eating", id);
                    rtos::dly_tsk(rand_time());
                    rtos::sig_sem(left);
                    rtos::sig_sem(right);
                    break 'dining;
                } else {
                    rtos::sig_sem(left);
                }
            }
            println!("[philosopher{}] hungry", id);
            rtos::dly_tsk(rand_time());
        }
    }
}

// 乱数
const RAND_MAX: u32 = 0xffff_ffff;
static mut RAND_SEED: u32 = 0x1234;
fn rand() -> u32 {
    unsafe {
        rtos::loc_cpu();
        let x = RAND_SEED as u64;
        let x = ((69069 * x + 1) & RAND_MAX as u64) as u32;
        RAND_SEED = x;
        rtos::unl_cpu();
        x
    }
}

fn rand_time() -> u32 {
    500000 + (rand() % 1000) * 1000
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

