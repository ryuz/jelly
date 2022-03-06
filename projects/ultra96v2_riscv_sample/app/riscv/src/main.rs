#![no_main]
#![no_std]


use core::panic::PanicInfo;


#[panic_handler]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {}
}


#[no_mangle]
pub unsafe extern "C" fn main() -> ! {
    let mmio_led0 = 0xff000000  as *mut i32;
    let mmio_led1 = 0xff000004  as *mut i32;

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

