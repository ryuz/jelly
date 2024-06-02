#![no_main]
#![no_std]


use core::panic::PanicInfo;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}


#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    let pi8_0  = 0xf0000000  as *mut i8;
    let pu8_0  = 0xf0000000  as *mut u8;
    let pi8_1  = 0xf0000001  as *mut i8;
    let pu8_1  = 0xf0000001  as *mut u8;
    let pi8_2  = 0xf0000002  as *mut i8;
    let pu8_2  = 0xf0000002  as *mut u8;
    let pi8_3  = 0xf0000003  as *mut i8;
    let pu8_3  = 0xf0000003  as *mut u8;
    let pi16_0 = 0xf0000000  as *mut i16;
    let pu16_0 = 0xf0000000  as *mut u16;
    let pi16_1 = 0xf0000002  as *mut i16;
    let pu16_1 = 0xf0000002  as *mut u16;
    let pi32 = 0xf0000000  as *mut i32;
    let pu32 = 0xf0000000  as *mut u32;
    let pi64 = 0xf0000000  as *mut i64;
    let pu64 = 0xf0000000  as *mut u64;
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

//    let ptr = 0xff000000  as *mut i32;
//    let mut i: i32 = 0;
    loop {
//        core::ptr::write_volatile(ptr, i);
//        i = i+1;
    }
}

