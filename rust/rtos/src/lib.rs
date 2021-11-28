#![no_std]
#![no_main]
#![feature(asm)]

pub mod rtos;


#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
