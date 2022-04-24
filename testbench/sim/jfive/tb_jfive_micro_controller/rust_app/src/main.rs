#![no_main]
#![no_std]


use core::panic::PanicInfo;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}


static mut DATA : i32 = 0;

extern{
    fn foo() -> i32;
}

#[no_mangle]
pub unsafe extern "C" fn main() -> ! {

//    let c = 'a' as i32;
//    for i in 0..4 {
//        write_byte((c + i) as u8);
//    }
    
    //  foo();
    println!("Start!");
    loop{}
    write_byte('S' as u8);
    write_byte('t' as u8);
    write_byte('a' as u8);
    write_byte('r' as u8);
    write_byte('t' as u8);
    write_byte('\n' as u8);
//    loop{}

    /*
    let mmio_putc = 0xf0000100  as *mut u8;
    core::ptr::write_volatile(mmio_putc, 'H' as u8);
    core::ptr::write_volatile(mmio_putc, 'e' as u8);
    core::ptr::write_volatile(mmio_putc, 'l' as u8);
    core::ptr::write_volatile(mmio_putc, 'l' as u8);
    core::ptr::write_volatile(mmio_putc, 'o' as u8);
    core::ptr::write_volatile(mmio_putc, '\n' as u8);
    */

    
    let pi8_0  = 0xff000000  as *mut i8;
    let pu8_0  = 0xff000000  as *mut u8;
    let pi8_1  = 0xff000001  as *mut i8;
    let pu8_1  = 0xff000001  as *mut u8;
    let pi8_2  = 0xff000002  as *mut i8;
    let pu8_2  = 0xff000002  as *mut u8;
    let pi8_3  = 0xff000003  as *mut i8;
    let pu8_3  = 0xff000003  as *mut u8;
    let pi16_0 = 0xff000000  as *mut i16;
    let pu16_0 = 0xff000000  as *mut u16;
    let pi16_1 = 0xff000002  as *mut i16;
    let pu16_1 = 0xff000002  as *mut u16;
    let pi32   = 0xff000000  as *mut i32;
    let pu32   = 0xff000000  as *mut u32;
    let pi64   = 0xff000000  as *mut i64;
    let pu64   = 0xff000000  as *mut u64;

    core::ptr::write_volatile(pi8_0, core::ptr::read_volatile(pi8_0));
    core::ptr::write_volatile(pi8_1, core::ptr::read_volatile(pi8_1));
    core::ptr::write_volatile(pi8_2, core::ptr::read_volatile(pi8_2));
    core::ptr::write_volatile(pi8_3, core::ptr::read_volatile(pi8_3));
    core::ptr::write_volatile(pu8_0, core::ptr::read_volatile(pu8_0));
    core::ptr::write_volatile(pu8_1, core::ptr::read_volatile(pu8_1));
    core::ptr::write_volatile(pu8_2, core::ptr::read_volatile(pu8_2));
    core::ptr::write_volatile(pu8_3, core::ptr::read_volatile(pu8_3));

    core::ptr::write_volatile(pi16_0, core::ptr::read_volatile(pi16_0));
    core::ptr::write_volatile(pi16_1, core::ptr::read_volatile(pi16_1));
    core::ptr::write_volatile(pu16_0, core::ptr::read_volatile(pu16_0));
    core::ptr::write_volatile(pu16_1, core::ptr::read_volatile(pu16_1));

    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pi32));
    core::ptr::write_volatile(pu32, core::ptr::read_volatile(pu32));

    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pi8_0) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pi8_1) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pi8_2) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pi8_3) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pu8_0) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pu8_1) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pu8_2) as i32);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(pu8_3) as i32);

    core::ptr::write_volatile(pi8_0, -1);
    core::ptr::write_volatile(pu8_0,  1);
    core::ptr::write_volatile(pi8_1, -2);
    core::ptr::write_volatile(pu8_1,  2);
    core::ptr::write_volatile(pi8_2, -3);
    core::ptr::write_volatile(pu8_2,  3);
    core::ptr::write_volatile(pi8_3, -4);
    core::ptr::write_volatile(pu8_3,  4);

    core::ptr::write_volatile(pi16_0, -11);
    core::ptr::write_volatile(pu16_0,  11);
    core::ptr::write_volatile(pi16_1, -12);
    core::ptr::write_volatile(pu16_1,  12);

    core::ptr::write_volatile(pi32, -111);
    core::ptr::write_volatile(pu32,  111);

    core::ptr::write_volatile(pi64, -2222);
    core::ptr::write_volatile(pu64,  2222);

    core::ptr::write_volatile(&mut DATA, 0x7654320);
    core::ptr::write_volatile(&mut DATA, core::ptr::read_volatile(&mut DATA) + 1);
    core::ptr::write_volatile(pi32, core::ptr::read_volatile(&mut DATA));

//  println!("Hello!");

//    let ptr = 0xff000000  as *mut i32;
//    let mut i: i32 = 0;
    loop {
//        core::ptr::write_volatile(ptr, i);
//        i = i+1;
    }
}





fn write_byte(c: u8) {
    let mmio_putc = 0xf0000100  as *mut u8;
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

