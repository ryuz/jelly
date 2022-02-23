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
        *ptr = *c as i8;
    }
    loop {}
}

