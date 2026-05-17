#![allow(dead_code)]

use core::fmt::{self, Write};

const UART_BASE_ADDR: usize = 0x8000_0000; // UART
const REG_UART_TX      :usize = UART_BASE_ADDR + 0x0 * 4;
const REG_UART_RX      :usize = UART_BASE_ADDR + 0x0 * 4;
const REG_UART_STATUS  :usize = UART_BASE_ADDR + 0x1 * 4;
const REG_UART_DIVIDER :usize = UART_BASE_ADDR + 0x2 * 4;

// レジスタ書き込み
fn wrtie_reg(adr: usize, data: u32) {
    let p = adr as *mut u32;
    unsafe {
        core::ptr::write_volatile(p, data);
    }
}

// レジスタ読み出し
fn read_reg(adr: usize) -> u32 {
    let p = adr as *mut u32;
    unsafe { core::ptr::read_volatile(p) }
}

pub fn uart_init() {
//  wrtie_reg(REG_UART_DIVIDER, 543-1)  // 115200bps @ 500MHz
}

// 1文字出力
pub fn uart_write(c: i32) {
    while (read_reg(REG_UART_STATUS) & 0x2) == 0 {}
    wrtie_reg(REG_UART_TX, c as u32)
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    ($fmt:expr) => (print!(concat!($fmt, "\r\n")));
    ($fmt:expr, $($arg:tt)*) => (print!(concat!($fmt, "\r\n"), $($arg)*));
}

pub fn _print(args: fmt::Arguments) {
    let mut writer = UartWriter {};
    writer.write_fmt(args).unwrap();
}

struct UartWriter;

impl Write for UartWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.bytes() {
            uart_write(c as i32);
        }
        Ok(())
    }
}

// end of file
