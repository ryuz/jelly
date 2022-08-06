#![no_std]
#![no_main]
#![feature(asm)]
#![feature(const_fn_trait_bound)]
#![feature(const_fn_fn_ptr_basics)]
#![feature(const_mut_refs)]
#![allow(dead_code)]

use core::panic::PanicInfo;
use pudding_pac::arm::cpu;
mod bootstrap;

//mod rtos;

use jelly_rtos::rtos;
use jelly_mem_access::*;

#[macro_use]
pub mod uart;
use uart::*;
//mod timer;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

static mut STACK: [u8; 8192] = [0; 8192];


const  REG_MOTOTR_CORE_ID      : usize = 0x00;
const  REG_MOTOTR_CORE_VERSION : usize = 0x01;
const  REG_MOTOTR_CORE_CONFIG  : usize = 0x03;
const  REG_MOTOTR_CTL_CONTROL  : usize = 0x04;
const  REG_MOTOTR_IRQ_ENABLE   : usize = 0x08;
const  REG_MOTOTR_IRQ_STATUS   : usize = 0x09;
const  REG_MOTOTR_IRQ_CLR      : usize = 0x0a;
const  REG_MOTOTR_IRQ_SET      : usize = 0x0b;
const  REG_MOTOTR_POSITION     : usize = 0x10;
const  REG_MOTOTR_STEP         : usize = 0x12;
const  REG_MOTOTR_PHASE        : usize = 0x14;

const  REG_LOGGER_CORE_ID      : usize = 0x00;
const  REG_LOGGER_CORE_VERSION : usize = 0x01;
const  REG_LOGGER_CTL_CONTROL  : usize = 0x04;
const  REG_LOGGER_CTL_STATUS   : usize = 0x05;
const  REG_LOGGER_CTL_COUNT    : usize = 0x07;
const  REG_LOGGER_LIMIT_SIZE   : usize = 0x08;
const  REG_LOGGER_READ_DATA    : usize = 0x10;
const  REG_LOGGER_POL_TIMER0   : usize = 0x18;
const  REG_LOGGER_POL_TIMER1   : usize = 0x19;
const  REG_LOGGER_POL_DATA0    : usize = 0x20;


// 制御タスク
extern "C" fn task() -> ! {
    println!("Task start");
    
    let clock_rate = rtos::clock_rate();

    unsafe {
        // 制御レジスタへのアクセサ
        let motor_acc  = PhysAccessor::<u32, 0x8008_0000, 0x100>::new();
        let timer_acc  = PhysAccessor::<u32, 0x8010_0000, 0x100>::new();
        let moment_acc = PhysAccessor::<u32, 0x8020_0000, 0x100>::new();

        println!("core ID");
        println!("{:x}", motor_acc.read_reg(REG_MOTOTR_CORE_ID));
        println!("{:x}", moment_acc.read_reg(REG_LOGGER_CORE_ID));

        // 初期設定
        let motor_step = 2;
        motor_acc.write_reg(REG_MOTOTR_IRQ_ENABLE,  1);
        motor_acc.write_reg(REG_MOTOTR_STEP,        motor_step);
        motor_acc.write_reg(REG_MOTOTR_CTL_CONTROL, 1);
        
        let dt = ((65536 / motor_step) as f32) / (clock_rate  as f32);

//      let mut i = 0;
        let mut theta :f32 = 0.0;
        loop {
            // 制御周期を待つ
            motor_acc.write_reg(REG_MOTOTR_IRQ_CLR, 1);
            rtos::clr_flg(1, !1);
            rtos::wai_flg(1, 1, rtos::WfMode::AndWait);
            
            theta += dt * 3.14;
            let p = (libm::sinf(theta) * 65536.0 * 10.0) as i32;

            // 位置設定
//          println!("{}", i);
            motor_acc.write_reg32(REG_MOTOTR_POSITION, p as u32);
//          i += 256;
//            println!("{}", p);
        }
    }
}


// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    // start
    wait(1000000);
    println!("\nRPU start\n");

//    type MotorAccessor = PhysAccessor<u32, 0x8008_0000, 0x100>;
//    let motor_acc = PhysAccessor::<u32, 0x8008_0000, 0x100>::new();
//    println!("core_id      : {:08x}", motor_acc.read_reg(0));

    // start
    rtos::initialize(0x80000000);
    rtos::ena_extflg(1, 0x1);

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

    // タスク起動
    rtos::cre_tsk(1, &mut STACK, task);
    rtos::wup_tsk(1);

    // アイドルループ
    loop {
        cpu::wfi();
    }
}


// ループによるウェイト
fn wait(n: i32) {
    let mut v: i32 = 0;
    for i in 1..n {
        unsafe { core::ptr::write_volatile(&mut v, i) };
    }
}

// デバッグ用
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

