#![no_main]
#![no_std]

#[macro_use]
mod uart;
use uart::*;

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}

use core::arch::asm;

#[inline(always)]
pub fn hart_id() -> u32 {
    let hart_id: u32;
    unsafe {
        asm!(
            "csrr {0}, mhartid",
            out(reg) hart_id,
            options(nomem, nostack, preserves_flags)
        );
    }
    hart_id
}


const PRINT_ID : u32 = 2;

#[unsafe(no_mangle)]
pub unsafe extern "C" fn main(id: u32) -> ! {
    if id == PRINT_ID {
        uart_init();
        println!("Hello JFive!");
        println!("hart_id: {}", hart_id());
    }

    let mut f : f32 = 1.0;
    let mut count: u32 = 0;
    loop {
        if id == PRINT_ID {
            count += 1;
            println!("count: {}", count);
            println!("{}", f);
            f *= 1.1;
        }

        let unit : u32 = 10000000;
        write_value(id, 1);
        wait(unit + id*unit);
        write_value(id, 0);
        wait(unit + id*unit);
    }
}

// ループによるウェイト
fn wait(n: u32) {
    let mut v: u32 = 0;
    for i in 1..n {
        unsafe { core::ptr::write_volatile(&mut v, i) };
    }
}

// 値出力
fn write_value(id: u32, value: u32) {
    let mmio = (0xc000_0000 + 4*id) as *mut u32;
    unsafe {
        core::ptr::write_volatile(mmio, value);
    }
}

/*
use core::fmt::{self, Write};

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    ($fmt:expr) => (print!(concat!($fmt, "\n")));
    ($fmt:expr, $($arg:tt)*) => (print!(concat!($fmt, "\n"), $($arg)*));
}

pub fn _print(args: fmt::Arguments) {
    let mut writer = DebugWriter {};
    writer.write_fmt(args).unwrap();
}

struct DebugWriter;

impl Write for DebugWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.bytes() {
            write_byte(c);
        }
        Ok(())
    }
}
*/
