#![no_std]
#![feature(const_fn_trait_bound)]
#![feature(const_fn_fn_ptr_basics)]

#[cfg(feature = "std")]
extern crate std;

pub mod communication_pipe;
pub mod i2c;
pub mod interval_timer;

pub mod video_dma_control;

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
