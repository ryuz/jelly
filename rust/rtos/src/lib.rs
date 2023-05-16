#![no_std]
#![no_main]
//#![feature(asm)]

pub mod rtos;
pub use rtos::*;

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
