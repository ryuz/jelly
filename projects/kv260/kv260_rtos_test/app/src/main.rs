#![no_std]
#![no_main]

use core::panic::PanicInfo;
use pudding_pac::arm::cpu;
mod bootstrap;

use jelly_rtos::rtos;

#[macro_use]
pub mod uart;
use uart::*;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

static mut STACK1: [u8; 4096] = [0; 4096];
static mut STACK2: [u8; 4096] = [0; 4096];

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
    let pscl: u32 = rtos::clock_rate() / 1000000 - 1;
    println!("set_pscl({})\n", pscl);
    rtos::set_pscl(pscl);

    // タスクを生成
    rtos::cre_tsk(1, &mut STACK1, task1);
    rtos::cre_tsk(2, &mut STACK2, task2);

    // タスクを起動
    rtos::wup_tsk(1);
    rtos::wup_tsk(2);

    // アイドルループ
    loop {
        cpu::wfi();
    }
}

use jelly_mem_access::*;


// タイマレジスタ
const INTERVAL_TIMER_ADR_CONTROL : usize = 0x00;
const INTERVAL_TIMER_ADR_COMPARE : usize = 0x01;


extern "C" fn task1() -> ! {
    let reg_led = PhysAccessor::<u32, 0x8004_0000, 0x100>::new();   // LED(PMOD)
    let reg_tim = PhysAccessor::<u32, 0x8008_0000, 0x100>::new();   // Interval Timer

    unsafe {
        // イベントフラグに繋がるインターバルタイマを 2us周期で設定
        reg_tim.write_reg(INTERVAL_TIMER_ADR_COMPARE, 250*2-1);   // 2us 周期
        reg_tim.write_reg(INTERVAL_TIMER_ADR_CONTROL, 1);
        rtos::ena_extflg(1, 1);     // イベントフラグ外部入力有効化

        loop {
            // イベントフラグを待つ
            rtos::wai_flg(1, 1, rtos::WfMode::AndWait);
            rtos::clr_flg(1, 0);
            
            // LED0 出力反転
            reg_led.write_reg(0, !reg_led.read_reg(0));
        }
    }
}

extern "C" fn task2() -> ! {
    let reg_led = PhysAccessor::<u32, 0x8004_0000, 0x100>::new();
    unsafe {
        loop {
            // 5us 待ち
            rtos::dly_tsk(5);

            // LED1 出力反転
            reg_led.write_reg(1, !reg_led.read_reg(1));
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

