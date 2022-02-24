#![no_main]
#![no_std]


use core::panic::PanicInfo;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}


#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    let ptr = 0xf0000000  as *mut i8;
    for c in b"Hello world".iter() {
        core::ptr::write_volatile(ptr, *c as i8);
    }

    let ptr = 0xff000000  as *mut i32;
    let mut i: i32 = 0;
    loop {
        core::ptr::write_volatile(ptr, i);
        i = i+1;
    }
}

