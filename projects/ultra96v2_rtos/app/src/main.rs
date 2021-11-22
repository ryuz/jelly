#![no_std]
#![no_main]
#![feature(asm)]

use pudding_pac::arm::cpu;
//use pudding_pac::arm::pl390::Pl390;

mod bootstrap;

#[macro_use]
mod uart;
use uart::*;
mod memdump;
mod timer;

use core::ptr;

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    println!("\r\n!!!panic!!!");
    loop {}
}

/*
localparam  int                         OPCODE_WIDTH      = 8;
localparam  int                         ID_WIDTH          = 8;
localparam  int                         DECODE_OPCODE_POS = 0;
localparam  int                         DECODE_ID_POS     = DECODE_OPCODE_POS + OPCODE_WIDTH;

localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_REF_INF     = OPCODE_WIDTH'(8'h00);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CFG_CTL     = OPCODE_WIDTH'(8'h01);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CPU_STS     = OPCODE_WIDTH'(8'h02);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WUP_TSK     = OPCODE_WIDTH'(8'h10);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SLP_TSK     = OPCODE_WIDTH'(8'h11);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_DLY_TSK     = OPCODE_WIDTH'(8'h18);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SIG_SEM     = OPCODE_WIDTH'(8'h21);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_SEM     = OPCODE_WIDTH'(8'h22);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_SET_FLG     = OPCODE_WIDTH'(8'h31);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_CLR_FLG     = OPCODE_WIDTH'(8'h32);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_AND = OPCODE_WIDTH'(8'h33);
localparam  bit     [OPCODE_WIDTH-1:0]  OPCODE_WAI_FLG_OR  = OPCODE_WIDTH'(8'h34);

localparam  bit     [ID_WIDTH-1:0]      REF_INF_CORE_ID = 'h00;
localparam  bit     [ID_WIDTH-1:0]      REF_INF_VERSION = 'h01;
localparam  bit     [ID_WIDTH-1:0]      REF_INF_DATE    = 'h04;

localparam  bit     [ID_WIDTH-1:0]      CFG_CTL_IRQ_EN  = 'h00;
localparam  bit     [ID_WIDTH-1:0]      CFG_CTL_IRQ_STS = 'h01;

localparam  bit     [ID_WIDTH-1:0]      CPU_STS_TASKID  = 'h00;
localparam  bit     [ID_WIDTH-1:0]      CPU_STS_VALID   = 'h01;
*/


fn write_reg(reg: usize, data: u32) {
    let addr : usize = 0x80000000 + reg * 4;
    unsafe { ptr::write_volatile(addr as *mut u32, data); }
}


// main
#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    wait(10000);
    println!("Hello world!");
    wait(10000);
    memdump::memdump(0x80000000, 4);
//  memdump::memdump(0x80000400, 4);

    cpu::irq_enable();

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

