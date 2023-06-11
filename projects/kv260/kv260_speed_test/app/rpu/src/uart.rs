// UART

use core::fmt::{self, Write};

// const UART_BASE_ADDR   : usize = 0xff000000;    // UART0
const UART_BASE_ADDR: usize = 0xff010000; // UART1
const UART_CHANNEL_STS: usize = UART_BASE_ADDR + 0x0000002C;
const UART_TX_RX_FIFO: usize = UART_BASE_ADDR + 0x00000030;

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

// UARTに負荷をかけるとHostが固まるのでやや強引にウェイトを入れる
fn uart_wait() {
    let mut v = 0;
    let p = &mut v as *mut i32;
    for i in 0..1000 {
        unsafe {
            core::ptr::write_volatile(p, i);
        }
    }
}

// 1文字出力
pub fn uart_write(c: i32) {
    if c == '\n' as i32 {
        uart_write('\r' as i32);
    }

    while (read_reg(UART_CHANNEL_STS) & 0x10) != 0 {
        uart_wait();
    }
    uart_wait();
    wrtie_reg(UART_TX_RX_FIFO, c as u32)
}

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
