#![no_main]
#![no_std]


use core::panic::PanicInfo;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}


#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    // シミュレーション用にアクセスパターンテスト
    let mut val_u32: u32 = 0;
    core::ptr::write_volatile(&mut val_u32, 0x44434241);

    let mut buf_u8: [u8; 4] = val_u32.to_le_bytes();
    write_byte(core::ptr::read_volatile(&buf_u8[0]));
    write_byte(core::ptr::read_volatile(&buf_u8[1]));
    write_byte(core::ptr::read_volatile(&buf_u8[2]));
    write_byte(core::ptr::read_volatile(&buf_u8[3]));

    core::ptr::write_volatile(&mut buf_u8[3], 0x48);
    core::ptr::write_volatile(&mut buf_u8[2], 0x47);
    core::ptr::write_volatile(&mut buf_u8[1], 0x46);
    core::ptr::write_volatile(&mut buf_u8[0], 0x45);
    write_byte(core::ptr::read_volatile(&buf_u8[0]));
    write_byte(core::ptr::read_volatile(&buf_u8[1]));
    write_byte(core::ptr::read_volatile(&buf_u8[2]));
    write_byte(core::ptr::read_volatile(&buf_u8[3]));

    // シミュレーション用にprintlnテスト
    println!("\nHello!");
    println!("val : 0x{:x}", val_u32);


    // LEDチカ 開始(実機用)
    let mmio_led0 = 0x10000000  as *mut i32;
    let mmio_led1 = 0x10000004  as *mut i32;

    let mut led0 = 0;
    let mut led1 = 0;
    let mut counter0 = 0;
    let mut counter1 = 0;
    loop {
        counter0 += 1;
        if counter0 > 10000000 {
            counter0 = 0;
            led0 = led0 ^ 1;
        }

        counter1 += 1;
        if counter1 > 30000000 {
            counter1 = 0;
            led1 = led1 ^ 1;
        }

        core::ptr::write_volatile(mmio_led0, led0);
        core::ptr::write_volatile(mmio_led1, led1);
    }
}



fn write_byte(c: u8) {
    let mmio_putc = 0x10000100  as *mut u8;
    unsafe {
        core::ptr::write_volatile(mmio_putc, c);
    }
}

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

